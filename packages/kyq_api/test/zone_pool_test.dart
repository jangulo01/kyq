import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:test/test.dart';

// Cliente de 008: bolsa zonal, tarifa preferencial, preferencias de despacho y afiliación por origen.

const _session = {'access_token': 'a1', 'refresh_token': 'r1', 'role': 'passenger'};
const _pickup = GeoPoint(lat: 4.6, lng: -74.08);
const _dropoff = GeoPoint(lat: 4.65, lng: -74.05);

Map<String, dynamic> _trip() => {
  'id': 't1',
  'status': 'REQUESTED',
  'passenger_id': 'p1',
  'driver_id': 'd9',
  'pickup': {'lat': 4.6, 'lng': -74.08},
  'dropoff': {'lat': 4.65, 'lng': -74.05},
  'distance_m': 5200,
  'duration_s': 900,
  'currency': 'COP',
  'suggested_fare_minor': 1470000,
  'list_fare_minor': 1470000,
  'preferential_discount_pct': 0,
  'platform_commission_minor': 0,
  'dispatch': 'zone_pool',
  'requested_driver_id': 'd9',
  'driver_name': 'Beto',
};

const _chosen = {'driver_id': 'd9', 'display_name': 'Beto', 'vehicle_description': 'Kia', 'presence': 'free'};

void main() {
  late DioAdapter adapter;
  late KyqApiClient client;
  final sent = <String, Object?>{};

  setUp(() async {
    final dio = Dio();
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    final store = InMemoryTokenStore();
    await store.write(Tokens.fromJson(_session));
    client = KyqApiClient(baseUrl: 'http://api.test', tokenStore: store, dio: dio);
    sent.clear();
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          sent['${o.method} ${o.path}'] = o.data;
          h.next(o);
        },
      ),
    );
  });

  test('requestTrip a la bolsa zonal no envía driver_id', () async {
    adapter.onPost('/v1/trips', (s) => s.reply(201, _trip()), data: Matchers.any);

    final trip = await client.requestTrip(pickup: _pickup, dropoff: _dropoff, dispatch: TripDispatch.zonePool);

    expect(sent['POST /v1/trips'], {
      'pickup': {'lat': 4.6, 'lng': -74.08},
      'dropoff': {'lat': 4.65, 'lng': -74.05},
      'dispatch': 'zone_pool',
    });
    expect(trip.dispatch, TripDispatch.zonePool);
    expect(trip.listFareMinor, 1470000);
    expect(tripDispatchToApi(TripDispatch.zonePool), 'zone_pool');
  });

  test('quote con conductor devuelve la tarifa preferencial', () async {
    adapter.onPost(
      '/v1/fares/quote',
      (s) => s.reply(200, {
        'distance_m': 5200,
        'duration_s': 900,
        'suggested_fare_minor': 1320000,
        'list_fare_minor': 1470000,
        'preferential_discount_pct': 10,
        'currency': 'COP',
      }),
      data: Matchers.any,
    );

    final q = await client.quote(_pickup, _dropoff, driverId: 'd9');

    expect((sent['POST /v1/fares/quote']! as Map)['driver_id'], 'd9');
    expect(q.preferentialDiscountPct, 10);
    expect(q.listFareMinor, 1470000);
    expect(q.suggestedFareMinor, 1320000);

    await client.quote(_pickup, _dropoff);
    expect((sent['POST /v1/fares/quote']! as Map).containsKey('driver_id'), isFalse);
  });

  test('preferencias de despacho del conductor', () async {
    const body = {
      'accepts_zone_pool': true,
      'preferential_discount_pct': 15,
      'affiliate_link': 'https://kyq.test/a/qr1',
    };
    adapter
      ..onGet('/v1/driver/dispatch-settings', (s) => s.reply(200, body))
      ..onPut('/v1/driver/dispatch-settings', (s) => s.reply(200, body), data: Matchers.any);

    final got = await client.dispatchSettings();
    expect(
      got,
      const DispatchSettings(
        acceptsZonePool: true,
        preferentialDiscountPct: 15,
        affiliateLink: 'https://kyq.test/a/qr1',
      ),
    );

    await client.setDispatchSettings(acceptsZonePool: true, preferentialDiscountPct: 15);
    expect(sent['PUT /v1/driver/dispatch-settings'], {'accepts_zone_pool': true, 'preferential_discount_pct': 15});
  });

  test('afiliación por enlace y después del viaje', () async {
    adapter.onPost('/v1/affiliations', (s) => s.reply(201, _chosen), data: Matchers.any);

    final byLink = await client.affiliate('qr1', source: AffiliationSource.link);
    expect(sent['POST /v1/affiliations'], {'qr_token': 'qr1', 'source': 'link'});
    expect(byLink.created, isTrue);

    await client.affiliate('qr1');
    expect(sent['POST /v1/affiliations'], {'qr_token': 'qr1'});

    final afterTrip = await client.affiliateAfterTrip('t1');
    expect(sent['POST /v1/affiliations'], {'trip_id': 't1'});
    expect(afterTrip.driver.displayName, 'Beto');
  });

  test('origen de los clientes y altas por origen del CRM', () {
    final c = DriverClient.fromJson({
      'passenger_id': 'p1',
      'display_name': 'Ana',
      'affiliated_at': '2026-10-01T10:00:00Z',
      'source': 'post_trip',
    });
    expect(c.source, AffiliationSource.postTrip);
    final legacy = DriverClient.fromJson({
      'passenger_id': 'p1',
      'display_name': 'Ana',
      'affiliated_at': '2026-10-01T10:00:00Z',
    });
    expect(legacy.source, AffiliationSource.qrScan);

    final a = CrmAffiliations.fromJson({
      'created': 3,
      'created_by_source': {'qr_scan': 1, 'post_trip': 1, 'link': 1},
    });
    expect(a.createdBySource, {'qr_scan': 1, 'post_trip': 1, 'link': 1});
  });
}
