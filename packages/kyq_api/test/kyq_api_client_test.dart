import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:test/test.dart';

const _session = {'access_token': 'a1', 'refresh_token': 'r1', 'role': 'passenger'};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late InMemoryTokenStore store;
  late KyqApiClient client;
  var expired = 0;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    store = InMemoryTokenStore();
    expired = 0;
    client = KyqApiClient(baseUrl: 'http://api.test', tokenStore: store, dio: dio, onSessionExpired: () => expired++);
  });

  test('verifyOtp guarda la sesión', () async {
    adapter.onPost('/v1/auth/otp/verify', (s) => s.reply(200, _session));

    final tokens = await client.verifyOtp('+573001234567', '123456', displayName: 'Ana');

    expect(tokens.role, UserRole.passenger);
    expect((await store.read())?.accessToken, 'a1');
  });

  test('convierte el cuerpo Error en ApiException', () async {
    adapter.onPost(
      '/v1/auth/otp/verify',
      (s) => s.reply(401, {'code': 'invalid_code', 'message': 'código incorrecto'}),
    );

    expect(
      client.verifyOtp('+573001234567', '000000'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'invalid_code').having((e) => e.statusCode, 'status', 401),
      ),
    );
  });

  test('añade el token de acceso a las rutas protegidas', () async {
    await store.write(Tokens.fromJson(_session));
    adapter.onPost('/v1/realtime/token', (s) => s.reply(200, {'token': 'rt'}), headers: {'Authorization': 'Bearer a1'});

    expect(await client.realtimeToken(), 'rt');
  });

  test('ante 401 refresca una vez y reintenta con el token nuevo', () async {
    await store.write(Tokens.fromJson(_session));
    // Dio propio: el de setUp ya tiene el interceptor del cliente de setUp.
    final retryDio = Dio()
      ..httpClientAdapter = _ByTokenAdapter({
        'Bearer a1': (401, '{"code":"unauthorized","message":""}'),
        'Bearer a2': (200, '{"token":"rt2"}'),
      });
    final refreshDio = _RefreshServer(reply: const {'access_token': 'a2', 'refresh_token': 'r2', 'role': 'passenger'});
    client = KyqApiClient(baseUrl: 'http://api.test', tokenStore: store, dio: retryDio, refreshDio: refreshDio.dio);

    expect(await client.realtimeToken(), 'rt2');
    expect((await store.read())?.refreshToken, 'r2');
    expect(refreshDio.calls, 1);
  });

  test('si el refresco falla borra la sesión y avisa', () async {
    await store.write(Tokens.fromJson(_session));
    final expiredDio = Dio()
      ..httpClientAdapter = _ByTokenAdapter({'Bearer a1': (401, '{"code":"unauthorized","message":""}')});
    final refreshDio = _RefreshServer(status: 401);
    client = KyqApiClient(
      baseUrl: 'http://api.test',
      tokenStore: store,
      dio: expiredDio,
      refreshDio: refreshDio.dio,
      onSessionExpired: () => expired++,
    );

    await expectLater(client.realtimeToken(), throwsA(isA<ApiException>()));
    expect(await store.read(), isNull);
    expect(expired, 1);
  });

  test('pttToken devuelve las credenciales de la sala', () async {
    adapter.onPost(
      '/v1/trips/t1/ptt/token',
      (s) => s.reply(200, {
        'url': 'wss://voice.kyq.test',
        'token': 'lk',
        'room': 'trip-t1',
        'closes_at': '2026-10-27T12:15:00Z',
      }),
    );

    final c = await client.pttToken('t1');
    expect(c.url, 'wss://voice.kyq.test');
    expect(c.room, 'trip-t1');
    expect(c.closesAt, DateTime.utc(2026, 10, 27, 12, 15));
  });

  test('pttToken de un canal cerrado lanza 410', () async {
    adapter.onPost('/v1/trips/t1/ptt/token', (s) => s.reply(410, {'code': 'ptt_closed', 'message': 'cerrado'}));

    expect(client.pttToken('t1'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 410)));
  });

  test('requestFloor devuelve la caducidad del turno y 409 si está ocupado', () async {
    adapter.onPost('/v1/trips/t1/ptt/floor', (s) => s.reply(200, {'expires_at': '2026-10-27T12:01:00Z'}));
    expect(await client.requestFloor('t1'), DateTime.utc(2026, 10, 27, 12, 1));

    adapter.onPost('/v1/trips/t1/ptt/floor', (s) => s.reply(409, {'code': 'floor_busy', 'message': 'ocupado'}));
    expect(client.requestFloor('t1'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)));
  });

  test('activeTrip devuelve el viaje en curso o null si no hay', () async {
    adapter.onGet(
      '/v1/trips/active',
      (s) => s.reply(200, {
        'id': 't1',
        'status': 'ACCEPTED',
        'passenger_id': 'p1',
        'driver_id': 'd1',
        'pickup': {'lat': 4.6, 'lng': -74.08},
        'dropoff': {'lat': 4.65, 'lng': -74.05},
        'distance_m': 5200,
        'duration_s': 900,
        'currency': 'COP',
        'suggested_fare_minor': 1470000,
      }),
    );
    final trip = await client.activeTrip();
    expect(trip?.id, 't1');
    expect(trip?.status, TripStatus.accepted);

    adapter.onGet('/v1/trips/active', (s) => s.reply(204, null));
    expect(await client.activeTrip(), isNull);
  });

  test('releaseFloor libera el turno', () async {
    adapter.onDelete('/v1/trips/t1/ptt/floor', (s) => s.reply(204, null));

    await client.releaseFloor('t1');
  });

  test('AdminDriver interpreta la respuesta del backend', () {
    final d = AdminDriver.fromJson({
      'driver_id': 'd1',
      'phone_e164': '+573001112233',
      'display_name': 'Carlos',
      'qr_token': 'qr',
      'vehicle_plate': 'ABC123',
      'vehicle_description': 'Kia',
      'presence': 'offline',
      'paid_until': '2026-11-26T12:00:00Z',
      'subscription_status': 'grace_period',
      'can_go_online': false,
      'block_reason': 'kyc_expired',
      'documents': [
        {'doc_type': 'mandatory_insurance', 'expires_at': '2027-06-30', 'approved': true},
      ],
    });
    expect(d.subscriptionStatus, SubscriptionStatus.gracePeriod);
    expect(d.documents.single.docType, DocType.mandatoryInsurance);
  });
}

/// Responde según la cabecera Authorization, para simular un token caducado y uno nuevo.
class _ByTokenAdapter implements HttpClientAdapter {
  _ByTokenAdapter(this.replies);

  final Map<String, (int, String)> replies;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, body) = replies[options.headers['Authorization']] ?? (500, '{}');
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RefreshServer {
  _RefreshServer({Map<String, dynamic>? reply, int status = 200}) {
    final adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    adapter.onPost('/v1/auth/refresh', (s) {
      calls++;
      return s.reply(status, reply ?? {'code': 'invalid_refresh_token', 'message': ''});
    });
  }

  final Dio dio = Dio(BaseOptions(baseUrl: 'http://api.test'));
  int calls = 0;
}
