import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/billing/billing_cubits.dart';
import 'package:kyq_admin_web/billing/driver_payments_page.dart';
import 'package:kyq_admin_web/billing/subscriptions_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

Payment _payment(String id, PaymentStatus status, {PaymentMethod method = PaymentMethod.bold, String? voidReason}) =>
    Payment(
      id: id,
      amountMinor: 5000000,
      currency: 'COP',
      method: method,
      status: status,
      paymentMethodDetail: method == PaymentMethod.manual ? 'efectivo' : 'PSE',
      manualReference: method == PaymentMethod.manual ? 'R-1' : null,
      coversFrom: status == PaymentStatus.approved ? DateTime.utc(2026, 10, 27, 15) : null,
      coversUntil: status == PaymentStatus.approved ? DateTime.utc(2026, 11, 27, 15) : null,
      voidReason: voidReason,
      createdAt: DateTime.utc(2026, 10, 27, 15),
    );

AdminSubscription _sub(String id, String name, BillingStatus status) => AdminSubscription(
  driverId: id,
  displayName: name,
  status: status,
  paidUntil: DateTime.utc(2026, 10, 20, 15),
  lastPayment: _payment('p-$id', PaymentStatus.approved),
);

void _wide(WidgetTester tester) {
  tester.view.physicalSize = const Size(2400, 2000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  late _MockApi api;

  setUpAll(() => registerFallbackValue(BillingStatus.active));
  setUp(() => api = _MockApi());

  testWidgets('filtra por estado con vencimiento y último pago', (tester) async {
    _wide(tester);
    when(
      () => api.adminSubscriptions(status: null),
    ).thenAnswer((_) async => [_sub('d1', 'Ana', BillingStatus.active), _sub('d2', 'Beto', BillingStatus.suspended)]);
    when(
      () => api.adminSubscriptions(status: BillingStatus.suspended),
    ).thenAnswer((_) async => [_sub('d2', 'Beto', BillingStatus.suspended)]);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => SubscriptionsCubit(api)..load(), child: const SubscriptionsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Beto'), findsOneWidget);

    await tester.tap(find.byKey(const Key('subscriptions.filter.suspended')));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsNothing);
    expect(find.text('Beto'), findsOneWidget);
    expect(find.text('20/10/2026'), findsOneWidget);
    expect(find.text('27/10/2026 · \$ 50.000 · Aprobado'), findsOneWidget);
  });

  testWidgets('precio mensual con fecha de vigencia, en unidades mínimas', (tester) async {
    _wide(tester);
    when(() => api.adminSubscriptions(status: any(named: 'status'))).thenAnswer((_) async => []);
    when(
      () => api.adminSetSubscriptionPrice(
        any(),
        currency: any(named: 'currency'),
        amountMinor: any(named: 'amountMinor'),
        effectiveFrom: any(named: 'effectiveFrom'),
      ),
    ).thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => SubscriptionsCubit(api)..load(), child: const SubscriptionsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('subscriptions.price')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('price.amount')), '50000');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('price.save')));
    await tester.pumpAndSettle();

    verify(
      () => api.adminSetSubscriptionPrice('bogota', currency: 'COP', amountMinor: 5000000, effectiveFrom: null),
    ).called(1);
    expect(find.text('Precio guardado.'), findsOneWidget);
  });

  testWidgets('pago manual y anulación con motivo', (tester) async {
    _wide(tester);
    var payments = <Payment>[];
    when(() => api.adminDriverPayments('d1')).thenAnswer((_) async => payments);
    when(
      () => api.adminManualPayment('d1', methodDetail: 'efectivo', reference: 'R-1'),
    ).thenAnswer((_) async => payments = [_payment('m1', PaymentStatus.approved, method: PaymentMethod.manual)]);
    when(() => api.adminVoidPayment('m1', 'contracargo')).thenAnswer(
      (_) async =>
          payments = [_payment('m1', PaymentStatus.voided, method: PaymentMethod.manual, voidReason: 'contracargo')],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => DriverPaymentsCubit(api, 'd1')..load(),
          child: const DriverPaymentsPage(driverName: 'Carlos'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pagos de Carlos'), findsOneWidget);
    expect(find.text('Este conductor aún no tiene pagos.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('payments.manual')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('manual.reference')), 'R-1');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manual.save')));
    await tester.pumpAndSettle();
    expect(find.text('\$ 50.000 · Aprobado'), findsOneWidget);
    expect(find.textContaining('efectivo · ref. R-1'), findsOneWidget);
    expect(find.textContaining('Cubre del 27/10/2026 al 27/11/2026'), findsOneWidget);

    await tester.tap(find.byKey(const Key('payments.void.m1')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('void.confirm'))).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('void.reason')), 'contracargo');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('void.confirm')));
    await tester.pumpAndSettle();

    verify(() => api.adminVoidPayment('m1', 'contracargo')).called(1);
    expect(find.text('\$ 50.000 · Anulado'), findsOneWidget);
    expect(find.textContaining('Anulado: contracargo'), findsOneWidget);
    expect(find.byKey(const Key('payments.void.m1')), findsNothing);
  });
}
