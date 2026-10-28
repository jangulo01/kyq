import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/subscription/costs_view.dart';
import 'package:kyq_driver_app/subscription/subscription_cubit.dart';
import 'package:kyq_driver_app/subscription/subscription_page.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

final _at = DateTime.utc(2026, 10, 27, 15);
final _october = DateTime(2026, 10, 27);

Payment _payment(
  String id,
  PaymentStatus status, {
  String? detail,
  PaymentMethod method = PaymentMethod.bold,
  String? voidReason,
}) => Payment(
  id: id,
  amountMinor: 5000000,
  currency: 'COP',
  method: method,
  status: status,
  checkoutUrl: 'https://checkout.bold.co/LNK_$id',
  paymentMethodDetail: detail,
  coversFrom: status == PaymentStatus.approved ? DateTime.utc(2026, 9, 27, 15) : null,
  coversUntil: status == PaymentStatus.approved ? DateTime.utc(2026, 10, 27, 15) : null,
  voidReason: voidReason,
  createdAt: _at,
);

CostBreakdown _costs({double margin = 3697600}) => CostBreakdown(
  month: '2026-10',
  currency: 'COP',
  paidMinor: 5000000,
  items: const [
    CostItem(concept: CostConcepts.voiceMinute, usage: 120, costMinor: 240000),
    CostItem(concept: CostConcepts.realtimeEvent, usage: 3000, costMinor: 12400),
    CostItem(concept: CostConcepts.routeRequest, usage: 200, costMinor: 50000),
    CostItem(concept: CostConcepts.fixedMonthly, usage: 1, costMinor: 1000000),
  ],
  totalCostMinor: 1302400,
  marginMinor: margin,
);

Future<(MockApi, FakeCheckout)> _pump(WidgetTester tester, {required SubscriptionView view}) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final api = MockApi();
  final checkout = FakeCheckout();
  when(() => api.driverSubscription()).thenAnswer((_) async => view);
  when(() => api.driverCosts(month: any(named: 'month'))).thenAnswer((_) async => _costs());
  await tester.pumpWidget(
    MaterialApp(
      home: RepositoryProvider<KyqApiClient>.value(
        value: api,
        child: BlocProvider(
          create: (_) => SubscriptionCubit(api, checkout, pollInterval: const Duration(hours: 1))..load(),
          child: SubscriptionPage(costsNow: _october),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (api, checkout);
}

void main() {
  testWidgets('estado, precio, historial con medio, estado y periodo cubierto', (tester) async {
    await _pump(
      tester,
      view: SubscriptionView(
        status: BillingStatus.grace,
        paidUntil: DateTime.utc(2026, 10, 25, 15),
        graceUntil: DateTime.utc(2026, 10, 28, 15),
        price: const Price(amountMinor: 5000000, currency: 'COP'),
        canPay: true,
        payments: [
          _payment('p2', PaymentStatus.rejected, detail: 'PSE'),
          _payment('p1', PaymentStatus.approved, detail: 'NEQUI'),
          _payment('p0', PaymentStatus.voided, method: PaymentMethod.manual, voidReason: 'contracargo'),
        ],
      ),
    );

    expect(find.text('Suscripción: en gracia'), findsOneWidget);
    expect(find.textContaining('Tienes hasta el 28/10/2026'), findsOneWidget);
    expect(find.text('Precio del mes: \$ 50.000'), findsOneWidget);
    expect(find.text('Pagar \$ 50.000'), findsOneWidget);
    expect(find.text('Mis pagos'), findsOneWidget);
    expect(find.text('\$ 50.000 · Aprobado'), findsOneWidget);
    expect(find.text('\$ 50.000 · Rechazado'), findsOneWidget);
    expect(find.textContaining('27/10/2026 · Nequi'), findsOneWidget);
    expect(find.textContaining('27/10/2026 · PSE'), findsOneWidget);
    expect(find.textContaining('Cubre del 27/09/2026 al 27/10/2026'), findsOneWidget);
    expect(find.textContaining('Anulado: contracargo'), findsOneWidget);
  });

  testWidgets('Pagar abre Bold; al volver a la app muestra "Pago aprobado"', (tester) async {
    final (api, checkout) = await _pump(
      tester,
      view: const SubscriptionView(
        status: BillingStatus.suspended,
        price: Price(amountMinor: 5000000, currency: 'COP'),
        canPay: true,
      ),
    );
    when(() => api.createPayment()).thenAnswer((_) async => _payment('p9', PaymentStatus.created));

    await tester.tap(find.byKey(const Key('subscription.pay')));
    // "Pago en proceso" lleva un indicador animado: no se asienta.
    await tester.pump();
    await tester.pump();
    expect(checkout.opened, ['https://checkout.bold.co/LNK_p9']);
    expect(find.text('Pago en proceso'), findsOneWidget);
    expect(find.text('Continuar el pago'), findsOneWidget);

    when(() => api.refreshPayment('p9')).thenAnswer((_) async => _payment('p9', PaymentStatus.approved));
    when(() => api.driverSubscription()).thenAnswer(
      (_) async => SubscriptionView(
        status: BillingStatus.active,
        paidUntil: DateTime.utc(2026, 11, 27, 15),
        price: const Price(amountMinor: 5000000, currency: 'COP'),
        canPay: true,
        payments: [_payment('p9', PaymentStatus.approved)],
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Pago aprobado'), findsOneWidget);
    expect(find.text('Suscripción: activa'), findsOneWidget);
    expect(find.text('Pagada hasta el 27/11/2026.'), findsOneWidget);
  });

  testWidgets('pago rechazado: lo dice y deja intentar otra vez', (tester) async {
    final (api, checkout) = await _pump(
      tester,
      view: const SubscriptionView(
        status: BillingStatus.unpaid,
        price: Price(amountMinor: 5000000, currency: 'COP'),
        canPay: true,
      ),
    );
    when(() => api.createPayment()).thenAnswer((_) async => _payment('p9', PaymentStatus.created));
    await tester.tap(find.byKey(const Key('subscription.pay')));
    // "Pago en proceso" lleva un indicador animado: no se asienta.
    await tester.pump();
    await tester.pump();

    when(() => api.refreshPayment('p9')).thenAnswer((_) async => _payment('p9', PaymentStatus.rejected));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Pago rechazado'), findsOneWidget);
    expect(find.text('Intentar otra vez'), findsOneWidget);
    when(() => api.createPayment()).thenAnswer((_) async => _payment('p10', PaymentStatus.created));
    await tester.tap(find.text('Intentar otra vez'));
    await tester.pump();
    await tester.pump();
    expect(checkout.opened.last, 'https://checkout.bold.co/LNK_p10');
  });

  testWidgets('sin precio definido o sin documentos no deja pagar y explica por qué', (tester) async {
    await _pump(tester, view: const SubscriptionView(status: BillingStatus.unpaid));
    expect(find.text('Precio del mes no disponible'), findsOneWidget);
    expect(find.text('El precio del mes aún no está definido.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('subscription.pay'))).onPressed, isNull);
  });

  testWidgets('price_not_set al pagar: mensaje claro', (tester) async {
    final (api, checkout) = await _pump(
      tester,
      view: const SubscriptionView(
        status: BillingStatus.unpaid,
        price: Price(amountMinor: 5000000, currency: 'COP'),
        canPay: true,
      ),
    );
    when(() => api.createPayment()).thenThrow(const ApiException(409, 'price_not_set', ''));
    await tester.tap(find.byKey(const Key('subscription.pay')));
    await tester.pumpAndSettle();
    expect(find.textContaining('El precio de la suscripción aún no está definido'), findsOneWidget);
    expect(checkout.opened, isEmpty);
  });

  group('CostsView', () {
    Future<MockApi> pumpCosts(WidgetTester tester, CostBreakdown costs) async {
      final api = MockApi();
      when(() => api.driverCosts(month: any(named: 'month'))).thenAnswer((_) async => costs);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RepositoryProvider<KyqApiClient>.value(
                value: api,
                child: CostsView(now: _october),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('desglose por concepto frente a lo pagado (RN-KYQ-004)', (tester) async {
      final api = await pumpCosts(tester, _costs());

      expect(find.text('octubre de 2026'), findsOneWidget);
      expect(find.text('Voz del walkie-talkie'), findsOneWidget);
      expect(find.text('120 minutos'), findsOneWidget);
      expect(find.text('3.000 eventos'), findsOneWidget);
      expect(find.text('200 rutas'), findsOneWidget);
      expect(find.text('Mapa base y mantenimiento'), findsOneWidget);
      Text value(String key) => tester.widget<Text>(find.byKey(Key(key)));
      expect(value('costs.item.voice_minute').data, '\$ 2.400');
      expect(value('costs.total').data, '\$ 13.024');
      expect(value('costs.paid').data, '\$ 50.000');
      expect(value('costs.margin').data, '\$ 36.976');
      expect(find.text('Mantenimiento y mejoras de Kyq'), findsOneWidget);
      verify(() => api.driverCosts(month: DateTime(2026, 10))).called(1);

      // El mes en curso es el último; se puede ir a los anteriores.
      expect(tester.widget<IconButton>(find.byKey(const Key('costs.next'))).onPressed, isNull);
      await tester.tap(find.byKey(const Key('costs.previous')));
      await tester.pumpAndSettle();
      expect(find.text('septiembre de 2026'), findsOneWidget);
      verify(() => api.driverCosts(month: DateTime(2026, 9))).called(1);
    });

    testWidgets('margen negativo: Kyq cubre la diferencia', (tester) async {
      await pumpCosts(tester, _costs(margin: -150000));
      expect(find.text('Kyq cubre la diferencia'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('costs.margin'))).data, '\$ 1.500');
    });
  });
}
