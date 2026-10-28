import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:test/test.dart';

const _session = {'access_token': 'a1', 'refresh_token': 'r1', 'role': 'passenger'};

Map<String, dynamic> tripPaymentJson({String status = 'pending', String? method, String? checkoutUrl}) => {
  'id': 'tp1',
  'trip_id': 't1',
  'driver_id': 'd1',
  'passenger_id': 'p1',
  'driver_name': 'Carlos',
  'passenger_name': 'Ana',
  'amount_minor': 1800000,
  'currency': 'COP',
  'driver_amount_minor': 1800000,
  'platform_commission_minor': 0,
  'status': status,
  'method': method,
  'accepted_methods': ['bold', 'cash'],
  'checkout_url': checkoutUrl,
  'payment_method_detail': null,
  'cash_reported_at': null,
  'cash_confirmed_at': null,
  'disputed_at': null,
  'unpaid_marked_at': null,
  'paid_at': null,
  'voided_at': null,
  'created_at': '2026-10-27T12:00:00Z',
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late KyqApiClient client;

  setUp(() async {
    dio = Dio();
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    final store = InMemoryTokenStore();
    await store.write(Tokens.fromJson(_session));
    client = KyqApiClient(baseUrl: 'http://api.test', tokenStore: store, dio: dio);
  });

  test('TripPayment lee el contrato: 100 % al conductor, comisión 0 y medios aceptados', () {
    final p = TripPayment.fromJson({
      ...tripPaymentJson(status: 'cash_reported', method: 'cash'),
      'cash_reported_at': '2026-10-27T12:05:00Z',
      'review_note': null,
    });
    expect(p.status, TripPaymentStatus.cashReported);
    expect(p.method, TripPaymentMethod.cash);
    expect(p.driverAmountMinor, p.amountMinor);
    expect(p.platformCommissionMinor, 0);
    expect(p.acceptedMethods, [TripPaymentMethod.bold, TripPaymentMethod.cash]);
    expect(p.cashReportedAt, DateTime.utc(2026, 10, 27, 12, 5));
    expect(TripPaymentStatus.boldInProgress.open, isTrue);
    expect(TripPaymentStatus.disputed.issue, isTrue);
    expect(TripPaymentStatus.paid.open || TripPaymentStatus.paid.issue, isFalse);
  });

  test('tripPayment devuelve null si el viaje no tiene pago', () async {
    adapter.onGet('/v1/trips/t1/payment', (s) => s.reply(404, {'code': 'not_found', 'message': 'pago no encontrado'}));
    expect(await client.tripPayment('t1'), isNull);
  });

  test('acciones del pago usan su ruta y devuelven el pago', () async {
    final routes = {
      '/v1/trips/t1/payment/bold': () => client.payTripWithBold('t1'),
      '/v1/trips/t1/payment/refresh': () => client.refreshTripPayment('t1'),
      '/v1/trips/t1/payment/cash': () => client.reportCashPayment('t1'),
      '/v1/trips/t1/payment/cash-received': () => client.confirmCashReceived('t1'),
      '/v1/trips/t1/payment/cash-dispute': () => client.disputeCash('t1'),
      '/v1/trips/t1/payment/unpaid': () => client.markTripUnpaid('t1'),
    };
    for (final MapEntry(key: path, value: call) in routes.entries) {
      adapter.onPost(path, (s) => s.reply(200, tripPaymentJson(status: 'paid', method: 'cash')));
      expect((await call()).status, TripPaymentStatus.paid, reason: path);
    }
  });

  test('un 409 llega como ApiException con su código', () async {
    adapter.onPost('/v1/trips/t1/payment/cash', (s) => s.reply(409, {'code': 'bold_in_progress', 'message': 'espera'}));
    expect(
      client.reportCashPayment('t1'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'bold_in_progress')),
    );
  });

  test('pendientes, medios, libro y liquidaciones', () async {
    adapter
      ..onGet('/v1/trip-payments/pending', (s) => s.reply(200, [tripPaymentJson()]))
      ..onGet('/v1/driver/payment-methods', (s) => s.reply(200, {'accepts_cash': true, 'accepts_bold': false}))
      ..onGet(
        '/v1/driver/settlement',
        (s) => s.reply(200, {
          'balances': [
            {
              'currency': 'COP',
              'credited_minor': 1800000,
              'debited_minor': 0,
              'paid_out_minor': 0,
              'balance_minor': 1800000,
            },
          ],
          'entries': [
            {
              'id': 'e1',
              'kind': 'trip_credit',
              'amount_minor': 1800000,
              'currency': 'COP',
              'trip_payment_id': 'tp1',
              'trip_id': 't1',
              'payout_id': null,
              'reference': null,
              'created_at': '2026-10-27T12:00:00Z',
            },
          ],
          'payments': [tripPaymentJson(status: 'paid', method: 'bold')],
        }),
      )
      ..onGet(
        '/v1/admin/settlements',
        (s) => s.reply(200, [
          {
            'driver_id': 'd1',
            'display_name': 'Carlos',
            'phone_e164': '+573100000001',
            'vehicle_plate': 'KYQ001',
            'currency': 'COP',
            'credited_minor': 1800000,
            'debited_minor': 0,
            'paid_out_minor': 0,
            'balance_minor': 1800000,
            'last_payout_at': null,
          },
        ]),
      );

    expect((await client.pendingTripPayments()).single.driverName, 'Carlos');
    expect((await client.driverPaymentMethods()).boldAvailable, isFalse);
    adapter.onPut(
      '/v1/driver/payment-methods',
      (s) => s.reply(200, {'accepts_cash': false, 'accepts_bold': true, 'bold_available': true}),
      data: {'accepts_cash': false, 'accepts_bold': true},
    );
    expect((await client.setDriverPaymentMethods(cash: false, bold: true)).acceptsBold, isTrue);
    final s = await client.driverSettlement();
    expect(s.balances.single.balanceMinor, 1800000);
    expect(s.entries.single.kind, LedgerKinds.tripCredit);
    expect(s.payments.single.method, TripPaymentMethod.bold);
    expect((await client.adminSettlements()).single.balanceMinor, 1800000);
  });

  test('panel: resolver, anular y registrar giro envían el cuerpo del contrato', () async {
    final bodies = <String, Object?>{};
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          bodies[o.path] = o.data;
          h.next(o);
        },
      ),
    );
    adapter
      ..onPost('/v1/admin/trip-payments/tp1/resolve', (s) => s.reply(200, {}), data: Matchers.any)
      ..onPost('/v1/admin/trip-payments/tp1/void', (s) => s.reply(200, {}), data: Matchers.any)
      ..onPost('/v1/admin/drivers/d1/payouts', (s) => s.reply(201, {}), data: Matchers.any)
      ..onGet('/v1/admin/trip-payments', (s) => s.reply(200, [tripPaymentJson(status: 'disputed')]));

    await client.adminResolveTripPayment('tp1', paid: true, note: 'Aclarado');
    await client.adminVoidTripPayment('tp1', 'Reembolsado');
    await client.adminRegisterPayout('d1', amountMinor: 1800000, currency: 'COP', reference: 'TR-1', note: ' ');
    expect((await client.adminTripPayments(status: 'issues')).single.status, TripPaymentStatus.disputed);

    expect(bodies['/v1/admin/trip-payments/tp1/resolve'], {'outcome': 'paid', 'note': 'Aclarado'});
    expect(bodies['/v1/admin/trip-payments/tp1/void'], {'reason': 'Reembolsado'});
    expect(bodies['/v1/admin/drivers/d1/payouts'], {'amount_minor': 1800000, 'currency': 'COP', 'reference': 'TR-1'});
  });
}
