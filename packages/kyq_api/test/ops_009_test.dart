import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:test/test.dart';

// Cliente de 009: sesión de solo soporte, soporte, megáfono y dominios espejo firmados.

const _api = KyqDomain(apiUrl: 'https://api.kyq.test', realtimeUrl: 'wss://rt.kyq.test/connection/websocket');
const _mirror = KyqDomain(apiUrl: 'https://espejo.kyq.test', realtimeUrl: 'wss://rt2.kyq.test/connection/websocket');

Future<SignedDomainList> _sign(SimpleKeyPair key, int version, List<KyqDomain> domains) async {
  final payload = jsonEncode({
    'version': version,
    'issued_at': '2026-10-28T12:00:00Z',
    'domains': [
      for (final d in domains) {'api_url': d.apiUrl, 'realtime_url': d.realtimeUrl},
    ],
  });
  final sig = await Ed25519().sign(utf8.encode(payload), keyPair: key);
  return SignedDomainList(payload: payload, signature: base64.encode(sig.bytes));
}

Future<(SimpleKeyPair, String)> _key(int seed) async {
  final key = await Ed25519().newKeyPairFromSeed(List.filled(32, seed));
  final pub = await key.extractPublicKey();
  return (key, base64.encode(pub.bytes));
}

/// Responde según el dominio: los de [down] fallan sin respuesta, como un bloqueo.
class _Network implements HttpClientAdapter {
  _Network(this.down);

  final Set<String> down;
  final hosts = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    hosts.add(options.uri.host);
    if (down.contains(options.uri.host)) {
      throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
    }
    return ResponseBody.fromString(
      jsonEncode([]),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('DomainRotator (FR-020–FR-022, SC-006)', () {
    test('lista inicial firmada, actualización más nueva y listas inválidas', () async {
      final (kyq, pub) = await _key(1);
      final (other, _) = await _key(2);
      final store = InMemoryDomainStore();
      final r = DomainRotator(
        publicKey: pub,
        fallback: _api,
        bootstrap: await _sign(kyq, 0, [_api, _mirror]),
        store: store,
      );
      await r.init();
      expect(r.domains, [_api, _mirror]);
      expect(r.version, 0);

      expect(await r.accept(await _sign(other, 5, [_mirror])), isFalse, reason: 'firma de otra clave');
      final tampered = await _sign(kyq, 6, [_api]);
      expect(
        await r.accept(
          SignedDomainList(payload: tampered.payload.replaceAll('api.kyq', 'evil'), signature: tampered.signature),
        ),
        isFalse,
        reason: 'contenido cambiado',
      );
      expect(await r.accept(await _sign(kyq, 7, [])), isFalse, reason: 'vacía');
      expect(r.current, _api);

      expect(await r.accept(await _sign(kyq, 8, [_mirror, _api])), isTrue);
      expect(r.current, _api, reason: 'conserva el dominio en uso');
      expect(await r.accept(await _sign(kyq, 8, [_mirror])), isFalse, reason: 'no más nueva');

      // Lo guardado gana a la lista inicial en el siguiente arranque.
      final again = DomainRotator(publicKey: pub, fallback: _api, bootstrap: await _sign(kyq, 0, [_api]), store: store);
      await again.init();
      expect(again.version, 8);
      expect(again.domains, [_mirror, _api]);
      expect(again.current, _api);
    });

    test('rota tras 3 fallos seguidos y lo recuerda', () async {
      final (kyq, pub) = await _key(3);
      final store = InMemoryDomainStore();
      final r = DomainRotator(
        publicKey: pub,
        fallback: _api,
        bootstrap: await _sign(kyq, 1, [_api, _mirror]),
        store: store,
      );
      await r.init();
      final changes = <KyqDomain>[];
      r.changes.listen(changes.add);
      expect(await r.reportFailure(), isFalse);
      r.reportSuccess();
      expect(await r.reportFailure(), isFalse);
      expect(await r.reportFailure(), isFalse);
      expect(await r.reportFailure(), isTrue);
      expect(r.current, _mirror);
      await Future<void>.delayed(Duration.zero);
      expect(changes, [_mirror]);

      final again = DomainRotator(publicKey: pub, fallback: _api, store: store);
      await again.init();
      expect(again.current, _mirror, reason: 'recuerda el dominio que funciona');
    });

    test('sin lista válida usa el dominio de la app', () async {
      final (_, pub) = await _key(4);
      final r = DomainRotator(publicKey: pub, fallback: _api);
      await r.init();
      expect(r.current, _api);
      expect(await r.reportFailure(), isFalse);
    });
  });

  test('el cliente pasa al espejo cuando el dominio no responde y conserva la sesión (SC-005)', () async {
    final (kyq, pub) = await _key(5);
    final rotator = DomainRotator(publicKey: pub, fallback: _api, bootstrap: await _sign(kyq, 1, [_api, _mirror]));
    await rotator.init();
    final network = _Network({'api.kyq.test'});
    final dio = Dio()..httpClientAdapter = network;
    final store = InMemoryTokenStore();
    await store.write(const Tokens(accessToken: 'a1', refreshToken: 'r1', role: UserRole.passenger));
    final client = KyqApiClient(baseUrl: 'http://ignorado', tokenStore: store, dio: dio)..useDomains(rotator);

    for (var i = 0; i < 2; i++) {
      await expectLater(client.supportCases(), throwsA(isA<ApiException>()));
    }
    expect(await client.supportCases(), isEmpty, reason: 'al tercer fallo rota y repite');
    expect(rotator.current, _mirror);
    expect(network.hosts.last, 'espejo.kyq.test');
    expect(await client.currentSession(), isNotNull);
  });

  group('API de 009', () {
    late DioAdapter adapter;
    late KyqApiClient client;
    late InMemoryTokenStore store;
    final sent = <String, Object?>{};

    setUp(() {
      final dio = Dio();
      adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      store = InMemoryTokenStore();
      client = KyqApiClient(baseUrl: 'http://api.test', tokenStore: store, dio: dio);
      sent.clear();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            sent['${o.method} ${o.path}'] = o.data ?? o.queryParameters;
            h.next(o);
          },
        ),
      );
    });

    test('una cuenta suspendida entra con la sesión de solo soporte (FR-011)', () async {
      adapter.onPost(
        '/v1/auth/otp/verify',
        (s) => s.reply(403, {
          'code': 'account_suspended',
          'message': 'suspendida',
          'support_session': {'access_token': 'sa', 'refresh_token': 'sr', 'role': 'passenger', 'scope': 'support'},
        }),
        data: Matchers.any,
      );
      final tokens = await client.verifyOtp('+573001234567', '123456');
      expect(tokens.supportOnly, isTrue);
      expect((await store.read())!.accessToken, 'sa');

      adapter.onPost(
        '/v1/auth/otp/verify',
        (s) => s.reply(403, {'code': 'account_suspended', 'message': 'suspendida'}),
        data: Matchers.any,
      );
      await expectLater(
        client.verifyOtp('+573001234567', '123456'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'account_suspended')),
      );
    });

    test('casos de soporte del usuario y del panel', () async {
      final caseJson = {
        'id': 'c1',
        'topic': 'lost_item',
        'subject': 'Sombrilla',
        'status': 'waiting_user',
        'user': {'id': 'p1', 'display_name': 'Ana'},
        'user_role': 'passenger',
        'counterpart': null,
        'assigned_to': {'id': 'a1', 'display_name': 'Admin'},
        'created_at': '2026-10-28T12:00:00Z',
        'last_message_at': '2026-10-28T12:05:00Z',
        'awaiting_reply': false,
        'messages': [
          {
            'id': 'm1',
            'author_kind': 'system',
            'author_name': null,
            'mine': false,
            'body': 'Hola',
            'internal': false,
            'created_at': '2026-10-28T12:00:00Z',
          },
        ],
      };
      adapter
        ..onPost('/v1/support/cases', (s) => s.reply(201, caseJson), data: Matchers.any)
        ..onGet('/v1/admin/support/cases', (s) => s.reply(200, [caseJson]))
        ..onPost('/v1/admin/support/cases/c1/messages', (s) => s.reply(200, caseJson), data: Matchers.any)
        ..onPost('/v1/admin/support/cases/c1/resolve-payment', (s) => s.reply(200, caseJson), data: Matchers.any);

      final d = await client.openSupportCase(SupportTopic.lostItem, 'Dejé mi sombrilla roja', tripId: 't1');
      expect(sent['POST /v1/support/cases'], {
        'topic': 'lost_item',
        'description': 'Dejé mi sombrilla roja',
        'trip_id': 't1',
      });
      expect(d.supportCase.status, SupportStatus.waitingUser);
      expect(d.messages.single.authorKind, SupportAuthor.system);

      await client.adminSupportCases(status: SupportStatus.inProgress, assignedToMe: true, unanswered: true);
      expect(sent['GET /v1/admin/support/cases'], {'status': 'in_progress', 'assigned_to': 'me', 'unanswered': 'true'});
      await client.adminReplySupportCase('c1', 'Nota', internal: true);
      expect(sent['POST /v1/admin/support/cases/c1/messages'], {'body': 'Nota', 'internal': true});
      await client.resolveSupportPayment('c1', paid: true, note: 'Encontró el billete');
      expect(sent['POST /v1/admin/support/cases/c1/resolve-payment'], {
        'outcome': 'paid',
        'note': 'Encontró el billete',
      });
    });

    test('megáfono, sesiones, dominios e inspección', () async {
      adapter
        ..onPost(
          '/v1/admin/megaphone',
          (s) => s.reply(201, {
            'broadcast_id': 'b1',
            'url': 'wss://lk',
            'token': 'tk',
            'ends_at': '2026-10-28T12:01:00Z',
            'recipients': 3,
          }),
          data: Matchers.any,
        )
        ..onGet(
          '/v1/admin/health/sessions',
          (s) => s.reply(200, {
            'status': 'not_configured',
            'checked_at': '2026-10-28T12:00:00Z',
            'target': 0.99,
            'apps': [],
          }),
        )
        ..onPut(
          '/v1/admin/domains/d1',
          (s) => s.reply(409, {'code': 'last_active_domain', 'message': 'x'}),
          data: Matchers.any,
        )
        ..onGet(
          '/v1/admin/trips/t1',
          (s) => s.reply(200, {
            'trip_id': 't1',
            'status': 'ACCEPTED',
            'active': true,
            'dispatch': 'zone_pool',
            'passenger': {'id': 'p1', 'display_name': 'Ana'},
            'driver': {'id': 'd1', 'display_name': 'Carlos'},
            'vehicle_plate': 'KYQ001',
            'pickup': {'lat': 4.6, 'lng': -74.08},
            'dropoff': {'lat': 4.65, 'lng': -74.05},
            'distance_m': 5200,
            'duration_s': 900,
            'currency': 'COP',
            'list_fare_minor': 1470000,
            'suggested_fare_minor': 1470000,
            'steps': [
              {'status': 'REQUESTED', 'at': '2026-10-28T12:00:00Z'},
            ],
            'driver_position': {'lat': 4.61, 'lng': -74.07, 'location_at': '2026-10-28T12:00:30Z', 'stale': false},
            'payment': null,
            'open_sos': {'id': 's1', 'status': 'open'},
            'generated_at': '2026-10-28T12:01:00Z',
          }),
        );

      final onAir = await client.startMegaphone(['8866e42b9bfffff']);
      expect(sent['POST /v1/admin/megaphone'], {
        'cells': ['8866e42b9bfffff'],
      });
      expect(onAir.recipients, 3);
      expect((await client.healthSessions()).status, 'not_configured');
      await expectLater(
        client.updateMirrorDomain('d1', apiUrl: 'https://a', realtimeUrl: 'wss://a', active: false),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'last_active_domain')),
      );
      final t = await client.inspectTrip('t1');
      expect(t.driverPosition!.lat, 4.61);
      expect(t.openSos!.id, 's1');
      expect(t.passenger.displayName, 'Ana');
    });
  });
}
