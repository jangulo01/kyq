import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:test/test.dart';

// Cliente de 010: reservas, ficha y nota del cliente, direcciones, zona y precisión del GPS.

Map<String, dynamic> _reservation({String status = 'pending'}) => {
  'id': 'r1',
  'passenger': {'id': 'p1', 'display_name': 'Ana'},
  'driver': {'id': 'd1', 'display_name': 'Carlos'},
  'pickup': {'lat': 4.6, 'lng': -74.08},
  'dropoff': {'lat': 4.65, 'lng': -74.05},
  'pickup_label': null,
  'dropoff_label': 'Centro Comercial Andino',
  'scheduled_at': '2026-10-28T14:00:00Z',
  'distance_m': 5200,
  'duration_s': 900,
  'currency': 'COP',
  'fare_minor': 1320000,
  'list_fare_minor': 1470000,
  'preferential_discount_pct': 10,
  'status': status,
  'cancelled_by_me': false,
  'trip_id': null,
  'overlaps': true,
};

void main() {
  late DioAdapter adapter;
  late KyqApiClient client;
  final sent = <String, Object?>{};

  setUp(() async {
    final dio = Dio();
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    final store = InMemoryTokenStore();
    await store.write(const Tokens(accessToken: 'a', refreshToken: 'r', role: UserRole.passenger));
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

  test('reservar, agenda y decisiones', () async {
    adapter
      ..onPost('/v1/reservations', (s) => s.reply(201, _reservation()), data: Matchers.any)
      ..onGet('/v1/driver/reservations', (s) => s.reply(200, [_reservation()]))
      ..onPost('/v1/driver/reservations/r1/accept', (s) => s.reply(200, _reservation(status: 'confirmed')))
      ..onPost('/v1/reservations/r1/cancel', (s) => s.reply(409, {'code': 'invalid_state', 'message': 'x'}));

    final r = await client.createReservation(
      driverId: 'd1',
      pickup: const GeoPoint(lat: 4.6, lng: -74.08),
      dropoff: const GeoPoint(lat: 4.65, lng: -74.05),
      scheduledAt: DateTime.utc(2026, 10, 28, 14),
      dropoffLabel: 'Centro Comercial Andino',
    );
    expect(sent['POST /v1/reservations'], {
      'driver_id': 'd1',
      'pickup': {'lat': 4.6, 'lng': -74.08},
      'dropoff': {'lat': 4.65, 'lng': -74.05},
      'scheduled_at': '2026-10-28T14:00:00.000Z',
      'dropoff_label': 'Centro Comercial Andino',
    });
    expect(r.status, ReservationStatus.pending);
    expect(r.open, isTrue);
    expect(r.fareMinor, 1320000);
    expect((await client.driverAgenda()).single.overlaps, isTrue);
    expect((await client.acceptReservation('r1')).status, ReservationStatus.confirmed);
    await expectLater(
      client.cancelReservation('r1'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'invalid_state')),
    );
  });

  test('ficha del cliente y nota', () async {
    final card = {
      'passenger_id': 'p1',
      'display_name': 'Ana',
      'affiliated_at': '2026-10-01T10:00:00Z',
      'source': 'link',
      'trips_together': 4,
      'last_trip_at': '2026-10-20T10:00:00Z',
      'note': 'Portería 2',
      'upcoming_reservations': [
        {'id': 'r1', 'scheduled_at': '2026-10-28T14:00:00Z', 'status': 'confirmed'},
      ],
    };
    adapter.onPut('/v1/driver/clients/p1/note', (s) => s.reply(200, card), data: Matchers.any);
    final c = await client.setClientNote('p1', 'Portería 2');
    expect(sent['PUT /v1/driver/clients/p1/note'], {'body': 'Portería 2'});
    expect(c.tripsTogether, 4);
    expect(c.source, AffiliationSource.link);
    expect(c.upcomingReservations.single.status, ReservationStatus.confirmed);
  });

  test('direcciones, zona y precisión del GPS', () async {
    adapter
      ..onGet(
        '/v1/places',
        (s) => s.reply(200, [
          {'label': 'Centro Comercial Andino', 'detail': 'Bogotá', 'lat': 4.666, 'lng': -74.053},
        ]),
      )
      ..onPost('/v1/driver/location', (s) => s.reply(204, null), data: Matchers.any);
    final places = await client.searchPlaces('Andino');
    expect(sent['GET /v1/places'], {'q': 'Andino'});
    expect(places.single.point, const GeoPoint(lat: 4.666, lng: -74.053));

    await client.sendLocation(const GeoPoint(lat: 4.6, lng: -74.08), accuracyM: 8);
    expect((sent['POST /v1/driver/location']! as Map)['accuracy_m'], 8);

    final d = ChosenDriver.fromJson({
      'driver_id': 'd1',
      'display_name': 'Carlos',
      'vehicle_description': 'Kia',
      'presence': 'free',
      'zone': {'cell': '8866e42b9bfffff', 'lat': 4.61, 'lng': -74.07},
    });
    expect(d.zone!.lat, 4.61);
  });
}
