import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/trip_payments/driver_ledger_page.dart';
import 'package:kyq_admin_web/trip_payments/settlements_page.dart';
import 'package:kyq_admin_web/trip_payments/trip_payments_cubits.dart';
import 'package:kyq_admin_web/trip_payments/trip_payments_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

TripPayment _payment(String id, TripPaymentStatus status, {TripPaymentMethod? method}) => TripPayment(
  id: id,
  tripId: 't-$id',
  driverId: 'd1',
  passengerId: 'p1',
  driverName: 'Carlos',
  passengerName: 'Ana',
  amountMinor: 1800000,
  currency: 'COP',
  driverAmountMinor: 1800000,
  status: status,
  method: method,
  cashReportedAt: status == TripPaymentStatus.disputed ? DateTime.utc(2026, 10, 27, 15) : null,
  disputedAt: status == TripPaymentStatus.disputed ? DateTime.utc(2026, 10, 27, 15, 5) : null,
  createdAt: DateTime.utc(2026, 10, 27, 15),
);

void _wide(WidgetTester tester) {
  tester.view.physicalSize = const Size(2400, 2000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  late _MockApi api;

  setUp(() => api = _MockApi());

  testWidgets('FR-017: las incidencias salen primero y se resuelven con nota', (tester) async {
    _wide(tester);
    when(
      () => api.adminTripPayments(status: issuesFilter),
    ).thenAnswer((_) async => [_payment('tp1', TripPaymentStatus.disputed)]);
    when(() => api.adminResolveTripPayment('tp1', paid: true, note: 'Se aclaró con los dos')).thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => TripPaymentsCubit(api)..load(), child: const TripPaymentsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('En disputa'), findsOneWidget);
    expect(find.textContaining('Conductor: Carlos · Pasajero: Ana'), findsOneWidget);
    expect(find.textContaining('El conductor lo disputó'), findsOneWidget);
    expect(find.byKey(const Key('tripPayments.void.tp1')), findsNothing, reason: 'el efectivo no se anula');

    await tester.tap(find.byKey(const Key('tripPayments.resolve.tp1')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('resolve.confirm'))).onPressed,
      isNull,
      reason: 'nota obligatoria',
    );
    await tester.enterText(find.byKey(const Key('resolve.note')), 'Se aclaró con los dos');
    await tester.pump();
    await tester.tap(find.byKey(const Key('resolve.confirm')));
    await tester.pumpAndSettle();

    verify(() => api.adminResolveTripPayment('tp1', paid: true, note: 'Se aclaró con los dos')).called(1);
    verify(() => api.adminTripPayments(status: issuesFilter)).called(2);
  });

  testWidgets('FR-014: un pago con Bold pagado se anula con motivo', (tester) async {
    _wide(tester);
    when(() => api.adminTripPayments(status: issuesFilter)).thenAnswer((_) async => []);
    when(
      () => api.adminTripPayments(status: 'paid'),
    ).thenAnswer((_) async => [_payment('tp2', TripPaymentStatus.paid, method: TripPaymentMethod.bold)]);
    when(() => api.adminVoidTripPayment('tp2', 'Reembolsado en Bold')).thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => TripPaymentsCubit(api)..load(), child: const TripPaymentsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No hay pagos de viajes con ese estado.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tripPayments.filter.paid')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pagado con Bold'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tripPayments.void.tp2')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('tripVoid.reason')), 'Reembolsado en Bold');
    await tester.pump();
    await tester.tap(find.byKey(const Key('tripVoid.confirm')));
    await tester.pumpAndSettle();
    verify(() => api.adminVoidTripPayment('tp2', 'Reembolsado en Bold')).called(1);
  });

  testWidgets('FR-012: liquidaciones muestran el saldo por girar de cada conductor', (tester) async {
    _wide(tester);
    when(() => api.adminSettlements()).thenAnswer(
      (_) async => [
        const SettlementRow(
          driverId: 'd1',
          displayName: 'Carlos',
          vehiclePlate: 'KYQ001',
          currency: 'COP',
          creditedMinor: 3000000,
          balanceMinor: 3000000,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => SettlementsCubit(api)..load(), child: const SettlementsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Carlos · KYQ001'), findsOneWidget);
    expect(find.text('\$ 30.000'), findsNWidgets(2));
  });

  testWidgets('FR-012: el giro no supera el saldo y queda con su referencia', (tester) async {
    _wide(tester);
    const settlement = DriverSettlement(
      balances: [SettlementBalance(currency: 'COP', creditedMinor: 3000000, balanceMinor: 3000000)],
    );
    when(() => api.adminDriverSettlement('d1')).thenAnswer((_) async => settlement);
    when(
      () =>
          api.adminRegisterPayout('d1', amountMinor: 3000000, currency: 'COP', reference: 'Bancolombia 123', note: ''),
    ).thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => DriverLedgerCubit(api, 'd1')..load(),
          child: const DriverLedgerPage(driverName: 'Carlos'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Por girar: \$ 30.000'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ledger.payout.COP')));
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('payout.save'));
    await tester.enterText(find.byKey(const Key('payout.reference')), 'Bancolombia 123');
    await tester.enterText(find.byKey(const Key('payout.amount')), '40000');
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNull, reason: 'más que el saldo');
    await tester.enterText(find.byKey(const Key('payout.amount')), '30000');
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    verify(
      () =>
          api.adminRegisterPayout('d1', amountMinor: 3000000, currency: 'COP', reference: 'Bancolombia 123', note: ''),
    ).called(1);
    verify(() => api.adminDriverSettlement('d1')).called(2);
  });
}
