import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/subscription/subscription_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

final _now = DateTime.utc(2026, 10, 27, 12);

Payment payment({String id = 'p1', PaymentStatus status = PaymentStatus.created, DateTime? coversUntil}) => Payment(
  id: id,
  amountMinor: 5000000,
  currency: 'COP',
  method: PaymentMethod.bold,
  status: status,
  checkoutUrl: 'https://checkout.bold.co/LNK_$id',
  coversUntil: coversUntil,
  createdAt: _now,
);

SubscriptionView view({BillingStatus status = BillingStatus.suspended, List<Payment> payments = const []}) =>
    SubscriptionView(
      status: status,
      price: const Price(amountMinor: 5000000, currency: 'COP'),
      canPay: true,
      payments: payments,
    );

void main() {
  late MockApi api;
  late FakeCheckout checkout;
  late DateTime clock;
  late int approved;

  setUp(() {
    api = MockApi();
    checkout = FakeCheckout();
    clock = _now;
    approved = 0;
    when(() => api.driverSubscription()).thenAnswer((_) async => view());
  });

  SubscriptionCubit build() => SubscriptionCubit(
    api,
    checkout,
    pollInterval: const Duration(milliseconds: 10),
    pollTimeout: const Duration(seconds: 120),
    onApproved: () => approved++,
    now: () => clock,
  );

  test('Pagar crea el pago y abre el checkout de Bold', () async {
    when(() => api.createPayment()).thenAnswer((_) async => payment());
    when(() => api.refreshPayment('p1')).thenAnswer((_) async => payment());
    final cubit = build();
    await cubit.load();
    await cubit.pay();

    expect(checkout.opened, ['https://checkout.bold.co/LNK_p1']);
    expect(cubit.state.outcome, PaymentOutcome.processing);
    expect(cubit.state.paying, isFalse);
    await cubit.close();
  });

  test('al volver de la Custom Tab pregunta ya y muestra aprobado', () async {
    when(() => api.createPayment()).thenAnswer((_) async => payment());
    final cubit = SubscriptionCubit(
      api,
      checkout,
      pollInterval: const Duration(hours: 1),
      onApproved: () => approved++,
    );
    await cubit.pay();
    when(
      () => api.refreshPayment('p1'),
    ).thenAnswer((_) async => payment(status: PaymentStatus.approved, coversUntil: DateTime.utc(2026, 11, 27)));
    when(() => api.driverSubscription()).thenAnswer((_) async => view(status: BillingStatus.active));

    await cubit.onResumed();

    expect(cubit.state.outcome, PaymentOutcome.approved);
    expect(cubit.state.view?.status, BillingStatus.active);
    expect(approved, 1);
    verify(() => api.refreshPayment('p1')).called(1);
    await cubit.close();
  });

  test('sondea mientras está en proceso y se detiene al rechazarse', () async {
    when(() => api.createPayment()).thenAnswer((_) async => payment());
    var calls = 0;
    when(() => api.refreshPayment('p1')).thenAnswer((_) async {
      calls++;
      return payment(status: calls < 3 ? PaymentStatus.processing : PaymentStatus.rejected);
    });
    final cubit = build();
    await cubit.pay();
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(cubit.state.outcome, PaymentOutcome.rejected);
    expect(calls, 3);
    await cubit.close();
  });

  test('deja de sondear a los 2 minutos y lo explica', () async {
    when(() => api.createPayment()).thenAnswer((_) async => payment());
    var calls = 0;
    when(() => api.refreshPayment('p1')).thenAnswer((_) async {
      calls++;
      return payment(status: PaymentStatus.processing);
    });
    final cubit = build();
    await cubit.pay();
    await Future<void>.delayed(const Duration(milliseconds: 35));
    final before = calls;
    expect(before, greaterThan(0));

    clock = _now.add(const Duration(minutes: 3));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(calls, before);
    expect(cubit.state.outcome, PaymentOutcome.processing);
    expect(cubit.state.message, contains('Bold aún no confirma'));
    await cubit.close();
  });

  test('payment_in_progress retoma el pago en curso', () async {
    when(() => api.createPayment()).thenThrow(const ApiException(409, 'payment_in_progress', ''));
    when(() => api.driverSubscription()).thenAnswer(
      (_) async => view(
        payments: [payment(id: 'p0', status: PaymentStatus.processing)],
      ),
    );
    when(() => api.refreshPayment('p0')).thenAnswer((_) async => payment(id: 'p0', status: PaymentStatus.processing));
    final cubit = build();
    await cubit.pay();

    expect(cubit.state.payment?.id, 'p0');
    expect(checkout.opened, ['https://checkout.bold.co/LNK_p0']);
    await cubit.close();
  });

  test('documentos sin aprobar o Bold caído: mensaje claro', () async {
    final cubit = build();
    when(() => api.createPayment()).thenThrow(const ApiException(409, 'documents_not_ok', ''));
    await cubit.pay();
    expect(cubit.state.message, 'Podrás pagar cuando un administrador apruebe tus documentos.');

    when(() => api.createPayment()).thenThrow(const ApiException(503, 'bold_unavailable', ''));
    await cubit.pay();
    expect(cubit.state.message, contains('no responde'));
    expect(checkout.opened, isEmpty);
    await cubit.close();
  });

  test('al abrir la pantalla con un pago pendiente (PSE) lo sigue esperando', () async {
    when(
      () => api.driverSubscription(),
    ).thenAnswer((_) async => view(payments: [payment(status: PaymentStatus.processing)]));
    when(() => api.refreshPayment('p1')).thenAnswer((_) async => payment(status: PaymentStatus.approved));
    final cubit = build();
    await cubit.load();
    expect(cubit.state.outcome, PaymentOutcome.processing);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(cubit.state.outcome, PaymentOutcome.approved);
    await cubit.close();
  });
}
