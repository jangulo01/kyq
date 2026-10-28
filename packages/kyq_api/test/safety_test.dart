import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:test/test.dart';

const _session = {'access_token': 'a1', 'refresh_token': 'r1', 'role': 'passenger'};

Map<String, dynamic> _self({String status = 'open', bool operator = false}) => {
  'id': 'al1',
  'trip_id': 't1',
  'status': status,
  'operator_connected': operator,
  'escalated': false,
  'created_at': '2026-10-27T22:00:00Z',
};

Map<String, dynamic> _summary() => {
  'id': 'al1',
  'trip_id': 't1',
  'raised_role': 'passenger',
  'raised_by_name': 'Ana',
  'status': 'claimed',
  'cancel_without_pin': true,
  'claimed_by': 'op1',
  'claimed_by_name': 'Lucía',
  'outcome': null,
  'escalated': true,
  'has_recording': false,
  'created_at': '2026-10-27T22:00:00Z',
  'claimed_at': '2026-10-27T22:00:30Z',
  'closed_at': null,
  'last_location': {'lat': 4.61, 'lng': -74.07, 'accuracy_m': 8.5, 'at': '2026-10-27T22:00:31Z'},
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late KyqApiClient client;
  late List<Object?> bodies;

  setUp(() async {
    dio = Dio();
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    final store = InMemoryTokenStore();
    await store.write(Tokens.fromJson(_session));
    client = KyqApiClient(baseUrl: 'http://api.test', tokenStore: store, dio: dio);
    bodies = [];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          bodies.add(o.data);
          h.next(o);
        },
      ),
    );
  });

  group('SOS', () {
    test('raiseSos envía la última ubicación conocida y lee voz y needs_pin', () async {
      adapter.onPost(
        '/v1/trips/t1/sos',
        (s) => s.reply(201, {
          'alert': _self(),
          'voice': {'url': 'ws://lk', 'token': 'tok', 'room': 'sos-al1', 'can_publish': true},
          'needs_pin': true,
        }),
        data: Matchers.any,
      );
      final out = await client.raiseSos(
        't1',
        location: SosPoint(lat: 4.61, lng: -74.07, accuracyM: 12, recordedAt: DateTime.utc(2026, 10, 27, 22)),
      );
      expect(out.alert.status, SosStatus.open);
      expect(out.voice?.canPublish, isTrue);
      expect(out.needsPin, isTrue);
      expect(bodies.single, {
        'location': {'lat': 4.61, 'lng': -74.07, 'accuracy_m': 12.0, 'recorded_at': '2026-10-27T22:00:00.000Z'},
      });
    });

    test('sin voz (LiveKit caído) la alerta sigue', () async {
      adapter.onPost(
        '/v1/trips/t1/sos',
        (s) => s.reply(200, {'alert': _self(), 'voice': null, 'needs_pin': false}),
        data: Matchers.any,
      );
      final out = await client.raiseSos('t1');
      expect(out.voice, isNull);
      expect(bodies.single, <String, dynamic>{});
    });

    test('fuera del viaje: 409 sos_unavailable', () async {
      adapter.onPost(
        '/v1/trips/t1/sos',
        (s) => s.reply(409, {'code': 'sos_unavailable', 'message': 'llama al 123'}),
        data: Matchers.any,
      );
      expect(client.raiseSos('t1'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'sos_unavailable')));
    });

    test('lote de ubicaciones y cierre (410) para dejar de enviar', () async {
      adapter.onPost('/v1/sos/al1/locations', (s) => s.reply(200, _self(operator: true)), data: Matchers.any);
      final self = await client.sendSosLocations('al1', [
        SosPoint(lat: 4.6, lng: -74.1, recordedAt: DateTime.utc(2026, 10, 27, 22, 0, 1)),
      ]);
      expect(self.operatorConnected, isTrue);
      expect((bodies.single as Map)['points'], [
        {'lat': 4.6, 'lng': -74.1, 'recorded_at': '2026-10-27T22:00:01.000Z'},
      ]);

      adapter.onPost(
        '/v1/sos/al1/locations',
        (s) => s.reply(410, {'code': 'sos_closed', 'message': 'cerrada'}),
        data: Matchers.any,
      );
      expect(
        client.sendSosLocations('al1', [SosPoint(lat: 4.6, lng: -74.1, recordedAt: DateTime.utc(2026))]),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 410)),
      );
    });

    test('cancelar con PIN incorrecto deja la alerta abierta', () async {
      adapter.onPost(
        '/v1/sos/al1/cancel',
        (s) => s.reply(403, {'code': 'invalid_pin', 'message': 'PIN incorrecto'}),
        data: {'pin': '0000'},
      );
      expect(
        client.cancelSos('al1', '0000'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'invalid_pin')),
      );
    });

    test('alerta activa: 204 es null', () async {
      adapter.onGet('/v1/sos/active', (s) => s.reply(204, null));
      expect(await client.activeSos(), isNull);
    });
  });

  group('viaje compartido, contactos y PIN', () {
    test('shareTrip devuelve la URL pública', () async {
      adapter.onPost('/v1/trips/t1/share', (s) => s.reply(200, {'token': 'abc', 'url': 'https://kyq.test/s/abc'}));
      expect((await client.shareTrip('t1')).url, 'https://kyq.test/s/abc');
    });

    test('contactos de emergencia se leen y reemplazan', () async {
      const mama = {'name': 'Mamá', 'phone_e164': '+573001110001'};
      adapter.onPut(
        '/v1/me/emergency-contacts',
        (s) => s.reply(200, {
          'contacts': [mama],
        }),
        data: Matchers.any,
      );
      final saved = await client.setEmergencyContacts([
        const EmergencyContact(name: 'Mamá', phoneE164: '+573001110001'),
      ]);
      expect(saved.single.phoneE164, '+573001110001');
      expect(bodies.single, {
        'contacts': [mama],
      });
    });

    test('setSafetyPin envía current_pin solo al cambiarlo', () async {
      adapter.onPut('/v1/me/safety-pin', (s) => s.reply(204, null), data: Matchers.any);
      await client.setSafetyPin('2468');
      await client.setSafetyPin('1357', currentPin: '2468');
      expect(bodies, [
        {'pin': '2468'},
        {'pin': '1357', 'current_pin': '2468'},
      ]);
    });
  });

  group('consola', () {
    test('cola, detalle y cierre con desenlace', () async {
      adapter.onGet('/v1/ops/sos', (s) => s.reply(200, [_summary()]));
      final queue = await client.opsOpenAlerts();
      expect(queue.single.cancelWithoutPin, isTrue);
      expect(queue.single.lastLocation?.accuracyM, 8.5);
      expect(queue.single.raisedRole, SosRole.passenger);

      adapter.onGet(
        '/v1/ops/sos/al1',
        (s) => s.reply(200, {
          ..._summary(),
          'outcome': 'escalated_authorities',
          'raised_by_phone_e164': '+573200000002',
          'emergency_contacts': [
            {'name': 'Mamá', 'phone_e164': '+573001110001'},
          ],
          'trip': {
            'status': 'IN_PROGRESS',
            'pickup': {'lat': 4.6, 'lng': -74.08},
            'dropoff': {'lat': 4.65, 'lng': -74.05},
          },
          'passenger': {'user_id': 'p1', 'name': 'Ana'},
          'driver': {
            'user_id': 'd1',
            'name': 'Carlos',
            'vehicle_plate': 'KYQ001',
            'vehicle_description': 'Kia',
            'vehicle_brand': null,
            'vehicle_model': null,
            'vehicle_color': null,
          },
          'track': [
            {'lat': 4.61, 'lng': -74.07, 'accuracy_m': null, 'at': '2026-10-27T22:00:01Z'},
          ],
          'notes': [
            {
              'id': 'n1',
              'operator_id': 'op1',
              'operator_name': 'Lucía',
              'body': 'Llamé',
              'created_at': '2026-10-27T22:01:00Z',
            },
          ],
          'related_alert_ids': ['al2'],
          'recording_url': 'https://s3.test/sos/al1.ogg?X-Amz-Signature=1',
          'raised_by_alerts': 3,
          'raised_by_false_alarms': 1,
        }),
      );
      final d = await client.opsAlert('al1');
      expect(d.outcome, SosOutcome.escalatedAuthorities);
      expect(d.raisedByPhone, '+573200000002');
      expect(d.driver.vehiclePlate, 'KYQ001');
      expect(d.notes.single.body, 'Llamé');
      expect(d.relatedAlertIds, ['al2']);

      adapter.onPost('/v1/ops/sos/al1/close', (s) => s.reply(204, null), data: Matchers.any);
      await client.opsClose('al1', SosOutcome.falseAlarm);
      expect(bodies.last, {'outcome': 'false_alarm'});
    });

    test('historial con filtros de fecha y desenlace', () async {
      Map<String, dynamic>? query;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            query = o.queryParameters;
            h.next(o);
          },
        ),
      );
      adapter.onGet(
        '/v1/ops/sos',
        (s) => s.reply(200, []),
        queryParameters: {'view': 'history', 'from': '2026-10-01', 'to': '2026-10-27', 'outcome': 'no_response'},
      );
      await client.opsAlertHistory(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 27),
        outcome: SosOutcome.noResponse,
      );
      expect(query, {'view': 'history', 'from': '2026-10-01', 'to': '2026-10-27', 'outcome': 'no_response'});
    });

    test('tomada por otro operador: 409 sos_claimed', () async {
      adapter.onPost('/v1/ops/sos/al1/claim', (s) => s.reply(409, {'code': 'sos_claimed', 'message': 'otro'}));
      expect(client.opsClaim('al1'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'sos_claimed')));
    });
  });
}
