import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:test/test.dart';

// Respuestas tal como las emite el backend de 007 (contracts/api.yaml).
const towerJson = {
  'generated_at': '2026-10-27T12:00:00Z',
  'resolution': 8,
  'window_minutes': 60,
  'stale_after_seconds': 120,
  'totals': {
    'online': 2,
    'free': 1,
    'busy': 1,
    'without_location': 0,
    'stale': 1,
    'active_trips': 1,
    'requests': 3,
    'unserved_requests': 1,
  },
  'cells': [
    {
      'cell': '8866e42b9bfffff',
      'center': {'lat': 4.7, 'lng': -74.03},
      'boundary': [
        {'lat': 4.701, 'lng': -74.031},
        {'lat': 4.702, 'lng': -74.03},
        {'lat': 4.701, 'lng': -74.029},
        {'lat': 4.699, 'lng': -74.029},
        {'lat': 4.698, 'lng': -74.03},
        {'lat': 4.699, 'lng': -74.031},
      ],
      'free_drivers': 0,
      'busy_drivers': 1,
      'active_trips': 1,
      'requests': 3,
      'unserved_requests': 1,
      'pressure': null,
      'level': 'no_supply',
    },
  ],
  'drivers': [
    {
      'driver_id': 'd1',
      'display_name': 'Carlos',
      'presence': 'busy',
      'lat': 4.7,
      'lng': -74.03,
      'location_at': '2026-10-27T11:55:00Z',
      'stale': true,
      'cell': '8866e42b9bfffff',
    },
  ],
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late KyqApiClient client;

  setUp(() async {
    dio = Dio();
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    final store = InMemoryTokenStore();
    await store.write(Tokens.fromJson({'access_token': 'a1', 'refresh_token': 'r1', 'role': 'admin'}));
    client = KyqApiClient(baseUrl: 'http://api.test', tokenStore: store, dio: dio);
  });

  test('torre: hexágonos, nivel de presión y conductores', () async {
    adapter.onGet('/v1/admin/tower', (s) => s.reply(200, towerJson), queryParameters: {'res': 7});
    final t = await client.adminTower(resolution: 7);
    expect(t.totals.online, 2);
    expect(t.totals.unservedRequests, 1);
    final cell = t.cells.single;
    expect(cell.level, PressureLevel.noSupply);
    expect(cell.pressure, isNull);
    expect(cell.boundary, hasLength(6));
    expect(cell.center.lat, 4.7);
    final d = t.drivers.single;
    expect(d.presence, DriverPresence.busy);
    expect(d.stale, isTrue);
    expect(d.locationAt, DateTime.utc(2026, 10, 27, 11, 55));
  });

  test('finanzas: meses con nulos y totales', () async {
    adapter.onGet(
      '/v1/admin/finance',
      (s) => s.reply(200, {
        'currency': 'COP',
        'months': [
          {
            'month': '2026-10',
            'revenue_minor': 5000000,
            'infra_cost_minor': 1806400.5,
            'margin_minor': 3193599.5,
            'margin_pct': 63.87,
            'drivers': 2,
            'active_drivers': 1,
            'paying_drivers': 1,
            'negative_margin_drivers': 1,
            'cost_per_active_driver_minor': 1806400.5,
            'revenue_per_paying_driver_minor': 5000000,
            'cost_by_concept': [
              {'concept': 'fixed_monthly', 'cost_minor': 1600000},
            ],
            'rates_missing': false,
          },
          {
            'month': '2026-11',
            'revenue_minor': 0,
            'infra_cost_minor': 0,
            'margin_minor': 0,
            'margin_pct': null,
            'drivers': 0,
            'active_drivers': 0,
            'paying_drivers': 0,
            'negative_margin_drivers': 0,
            'cost_per_active_driver_minor': null,
            'revenue_per_paying_driver_minor': null,
            'cost_by_concept': [],
            'rates_missing': true,
          },
        ],
        'totals': {
          'revenue_minor': 5000000,
          'infra_cost_minor': 1806400.5,
          'margin_minor': 3193599.5,
          'margin_pct': 63.87,
        },
      }),
      queryParameters: {'months': 2, 'to': '2026-11'},
    );
    final f = await client.adminFinance(to: DateTime(2026, 11, 20), months: 2);
    expect(f.months.first.revenuePerPayingDriverMinor, 5000000.0);
    expect(f.months.first.costByConcept.single.costMinor, 1600000.0);
    expect(f.months.last.marginPct, isNull);
    expect(f.months.last.ratesMissing, isTrue);
    expect(f.totals.marginMinor, 3193599.5);
  });

  test('fidelización y SC-008', () async {
    adapter.onGet(
      '/v1/admin/crm',
      (s) => s.reply(200, {
        'from': '2026-08-01',
        'to': '2026-10-27',
        'affiliations': {
          'active_now': 6,
          'active_at_start': 1,
          'created': 6,
          'removed': 1,
          'net': 5,
          'churn_rate': 0.1429,
          'weekly': [
            {'week_start': '2026-07-27', 'created': 0, 'removed': 0, 'active_end': 1},
          ],
        },
        'repeat': {'pairs': 2, 'repeat_pairs': 1, 'repeat_rate': 0.5, 'completed_trips': 4, 'avg_trips_per_pair': 2},
        'sc008': {'matured': 5, 'with_request_30d': 4, 'rate': 0.8, 'target': 0.8, 'met': true, 'pending': 1},
        'churned_drivers': [
          {'driver_id': 'd2', 'display_name': 'Diana', 'removed': 1, 'active_now': 0},
        ],
        'inactive_chosen_drivers': [
          {'driver_id': 'd1', 'display_name': 'Carlos', 'active_affiliations': 6, 'last_completed_at': null},
        ],
      }),
      queryParameters: {'from': '2026-08-01', 'to': '2026-10-27'},
    );
    final r = await client.adminCrm(from: DateTime(2026, 8, 1), to: DateTime(2026, 10, 27));
    expect(r.sc008.withRequest30d, 4);
    expect(r.sc008.met, isTrue);
    expect(r.repeat.avgTripsPerPair, 2.0);
    expect(r.affiliations.weekly.single.weekStart, DateTime(2026, 7, 27));
    expect(r.inactiveChosenDrivers.single.lastCompletedAt, isNull);
    expect(r.churnedDrivers.single.displayName, 'Diana');
  });

  test('moderación: búsqueda, suspensión, reactivación e historial', () async {
    final user = {
      'user_id': 'u1',
      'display_name': 'Ana',
      'phone_e164': '+573200000001',
      'role': 'passenger',
      'created_at': '2026-10-01T00:00:00Z',
      'suspended_at': '2026-10-27T12:00:00Z',
      'suspension_reason': 'fraude',
    };
    adapter
      ..onGet(
        '/v1/admin/users',
        (s) => s.reply(200, [user]),
        queryParameters: {'q': 'ana', 'role': 'passenger', 'status': 'suspended'},
      )
      ..onPost('/v1/admin/users/u1/suspend', (s) => s.reply(200, user), data: {'reason': 'fraude'})
      ..onPost(
        '/v1/admin/users/u1/reactivate',
        (s) => s.reply(200, {...user, 'suspended_at': null, 'suspension_reason': null}),
        data: {'reason': 'aclarado'},
      )
      ..onGet(
        '/v1/admin/users/u1/moderation',
        (s) => s.reply(200, [
          {
            'id': 'm1',
            'action': 'suspend',
            'reason': 'fraude',
            'actor_id': 'a1',
            'actor_name': 'Admin',
            'created_at': '2026-10-27T12:00:00Z',
          },
        ]),
      )
      ..onPost(
        '/v1/admin/users/u2/suspend',
        (s) => s.reply(409, {'code': 'cannot_moderate_admin', 'message': 'no se puede suspender a un administrador'}),
        data: {'reason': 'x'},
      );

    final found = await client.adminUsers(query: ' ana ', role: UserRole.passenger, suspended: true);
    expect(found.single.suspended, isTrue);
    expect((await client.adminSuspendUser('u1', 'fraude')).suspensionReason, 'fraude');
    expect((await client.adminReactivateUser('u1', 'aclarado')).suspended, isFalse);
    final history = await client.adminModerationHistory('u1');
    expect(history.single.action, ModerationKind.suspend);
    await expectLater(
      client.adminSuspendUser('u2', 'x'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'cannot_moderate_admin')),
    );
  });

  test('salud: estados conocidos y desconocidos', () async {
    adapter.onGet(
      '/v1/admin/health',
      (s) => s.reply(200, {
        'status': 'degraded',
        'checked_at': '2026-10-27T12:00:00Z',
        'checks': [
          {'name': 'database', 'status': 'ok', 'latency_ms': 3, 'detail': 'disponible'},
          {'name': 'bold', 'status': 'disabled', 'latency_ms': null, 'detail': 'pagos con Bold desactivados'},
          {'name': 'osrm', 'status': 'raro', 'latency_ms': 3000, 'detail': 'sin respuesta en 3 s'},
        ],
      }),
    );
    final h = await client.adminHealth();
    expect(h.status, HealthStatus.degraded);
    expect(h.checks[1].latencyMs, isNull);
    expect(h.checks[2].status, HealthStatus.down, reason: 'un estado nuevo se trata como caído');
  });
}
