import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:test/test.dart';

// Cliente de 006: despacho con delegación, cooperativas y canal de grupo.

const _session = {'access_token': 'a1', 'refresh_token': 'r1', 'role': 'driver'};

Map<String, dynamic> _trip({String driverId = 'd2', String requested = 'd1'}) => {
  'id': 't1',
  'status': 'REQUESTED',
  'passenger_id': 'p1',
  'driver_id': driverId,
  'pickup': {'lat': 4.6, 'lng': -74.08},
  'dropoff': {'lat': 4.65, 'lng': -74.05},
  'distance_m': 5200,
  'duration_s': 900,
  'currency': 'COP',
  'suggested_fare_minor': 1470000,
  'platform_commission_minor': 0,
  'dispatch': 'chosen_driver',
  'requested_driver_id': requested,
  'driver_name': 'Beto',
  'cooperative_id': 'c1',
  'cooperative_name': 'Cooperativa Andina',
  'allow_delegation': true,
  'handover_count': 1,
  'can_delegate': true,
};

void main() {
  late DioAdapter adapter;
  late KyqApiClient client;

  setUp(() async {
    final dio = Dio();
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    final store = InMemoryTokenStore();
    await store.write(Tokens.fromJson(_session));
    client = KyqApiClient(baseUrl: 'http://api.test', tokenStore: store, dio: dio);
  });

  test('requestTrip envía el despacho y el consentimiento de delegación', () async {
    Object? sent;
    adapter.onPost('/v1/trips', (s) => s.reply(201, _trip()), data: Matchers.any);
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          sent = o.data;
          h.next(o);
        },
      ),
    );

    final trip = await client.requestTrip(
      driverId: 'd1',
      pickup: const GeoPoint(lat: 4.6, lng: -74.08),
      dropoff: const GeoPoint(lat: 4.65, lng: -74.05),
      allowDelegation: true,
    );

    expect((sent! as Map)['allow_delegation'], isTrue);
    expect((sent! as Map).containsKey('dispatch'), isFalse, reason: 'chosen_driver es el valor por defecto');
    expect(trip.isDelegated, isTrue);
    expect(trip.driverName, 'Beto');
    expect(trip.cooperativeName, 'Cooperativa Andina');
    expect(trip.handoverCount, 1);
    expect(trip.canDelegate, isTrue);
    expect(trip.platformCommissionMinor, 0, reason: 'RN-KYQ-001');

    await client.requestTrip(
      driverId: 'd1',
      pickup: const GeoPoint(lat: 4.6, lng: -74.08),
      dropoff: const GeoPoint(lat: 4.65, lng: -74.05),
      dispatch: TripDispatch.cooperative,
    );
    expect((sent! as Map)['dispatch'], 'cooperative');
  });

  test('un viaje de 001 sin campos nuevos no es derivado', () {
    final json = _trip()
      ..remove('requested_driver_id')
      ..remove('dispatch')
      ..remove('driver_name');
    final trip = Trip.fromJson(json);
    expect(trip.dispatch, TripDispatch.chosenDriver);
    expect(trip.isDelegated, isFalse);
  });

  test('delegateTrip y errores de despacho', () async {
    adapter
      ..onPost('/v1/trips/t1/delegate', (s) => s.reply(200, _trip(driverId: 'd3')))
      ..onPost('/v1/trips/t2/delegate', (s) => s.reply(409, {'code': 'delegation_not_allowed', 'message': 'no'}));

    expect((await client.delegateTrip('t1')).driverId, 'd3');
    expect(
      client.delegateTrip('t2'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'delegation_not_allowed')),
    );
  });

  test('mi cooperativa: coordinador con compañeros y solicitudes', () async {
    adapter.onGet(
      '/v1/driver/cooperative',
      (s) => s.reply(200, {
        'membership': {
          'id': 'm1',
          'cooperative': {'id': 'c1', 'name': 'Cooperativa Andina'},
          'cooperative_status': 'active',
          'role': 'coordinator',
          'status': 'active',
          'reject_reason': null,
          'requested_at': '2026-10-27T12:00:00Z',
          'decided_at': '2026-10-27T12:05:00Z',
        },
        'members': [
          {
            'membership_id': 'm1',
            'driver_id': 'd1',
            'display_name': 'Carlos',
            'vehicle_plate': 'KYQ001',
            'role': 'coordinator',
            'presence': 'free',
            'since': '2026-10-27T12:05:00Z',
          },
        ],
        'requests': [
          {
            'membership_id': 'm2',
            'driver_id': 'd2',
            'display_name': 'Beto',
            'vehicle_plate': 'KYQ002',
            'requested_at': '2026-10-27T12:10:00Z',
          },
        ],
      }),
    );

    final mine = await client.myCooperative();
    expect(mine.isMember, isTrue);
    expect(mine.isCoordinator, isTrue);
    expect(mine.members.single.presence, 'free');
    expect(mine.requests.single.displayName, 'Beto');
  });

  test('sin cooperativa y solicitud rechazada', () async {
    adapter
      ..onGet('/v1/driver/cooperative', (s) => s.reply(200, {'membership': null, 'members': [], 'requests': []}))
      ..onPost(
        '/v1/driver/cooperative/requests',
        (s) => s.reply(409, {'code': 'already_in_cooperative', 'message': 'ya'}),
        data: {'cooperative_id': 'c1'},
      );
    final mine = await client.myCooperative();
    expect(mine.membership, isNull);
    expect(mine.isMember, isFalse);
    expect(
      client.requestToJoinCooperative('c1'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'already_in_cooperative')),
    );
  });

  test('admin: lista, alta y detalle', () async {
    final coop = {
      'id': 'c1',
      'name': 'Cooperativa Andina',
      'city_code': 'bogota',
      'nit': null,
      'status': 'active',
      'members_count': 2,
      'pending_count': 1,
      'created_at': '2026-10-27T12:00:00Z',
    };
    adapter.onGet(
      '/v1/admin/cooperatives',
      (s) => s.reply(200, {
        'cooperatives': [coop],
      }),
    );
    expect((await client.adminCooperatives()).single.pendingCount, 1);
    adapter.onPost(
      '/v1/admin/cooperatives',
      (s) => s.reply(201, coop),
      data: {'name': 'Cooperativa Andina', 'city_code': 'bogota'},
    );
    expect((await client.adminCreateCooperative(name: 'Cooperativa Andina', cityCode: 'bogota', nit: ' ')).id, 'c1');
    adapter.onGet(
      '/v1/admin/cooperatives/c1',
      (s) => s.reply(200, {'cooperative': coop, 'members': [], 'requests': []}),
    );
    expect((await client.adminCooperative('c1')).cooperative.status, CooperativeStatus.active);
  });

  test('canal de grupo: token y turno', () async {
    adapter
      ..onPost(
        '/v1/driver/cooperative/ptt/token',
        (s) => s.reply(200, {'url': 'ws://voice', 'token': 'tk', 'room': 'coop-c1', 'closes_at': null}),
      )
      ..onPost('/v1/driver/cooperative/ptt/floor', (s) => s.reply(200, {'expires_at': '2026-10-27T12:01:00Z'}));
    expect((await client.cooperativePttToken()).room, 'coop-c1');
    expect(await client.requestCooperativeFloor(), DateTime.utc(2026, 10, 27, 12, 1));
  });
}
