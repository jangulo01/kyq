import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/trip/trip_summary_page.dart';
import 'package:kyq_driver_app/trip_payments/trip_payment_card.dart';
import 'package:kyq_driver_app/trip_payments/trip_payment_cubit.dart';
import 'package:kyq_driver_app/trip_payments/trip_payments_cubit.dart';
import 'package:kyq_driver_app/trip_payments/trip_payments_page.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

TripPayment _payment(TripPaymentStatus status, {TripPaymentMethod? method, String id = 'tp1', String tripId = 't1'}) =>
    TripPayment(
      id: id,
      tripId: tripId,
      driverId: 'd1',
      passengerId: 'p1',
      driverName: 'Carlos',
      passengerName: 'Ana',
      amountMinor: 1470000,
      currency: 'COP',
      driverAmountMinor: 1470000,
      status: status,
      method: method,
      createdAt: DateTime.utc(2026, 10, 27, 12),
    );

void main() {
  late MockApi api;
  late StreamController<RealtimeEvent> events;

  setUp(() {
    api = MockApi();
    events = StreamController<RealtimeEvent>.broadcast();
  });

  tearDown(() => events.close());

  Future<void> pumpSummary(WidgetTester tester, TripPayment? payment) async {
    api.payment = payment;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider(
            create: (_) => TripPaymentCubit(api, events.stream, 't1')..load(),
            child: SingleChildScrollView(
              child: TripSummaryView(
                trip: trip(status: TripStatus.completed),
                onDone: () {},
                payment: const TripPaymentCard(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapAndConfirm(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payment.actionConfirm')));
    await tester.pumpAndSettle();
  }

  testWidgets('FR-005: ante el reporte del pasajero, el conductor confirma "Recibí el efectivo"', (tester) async {
    when(
      () => api.confirmCashReceived('t1'),
    ).thenAnswer((_) async => _payment(TripPaymentStatus.paid, method: TripPaymentMethod.cash));
    await pumpSummary(tester, _payment(TripPaymentStatus.cashReported, method: TripPaymentMethod.cash));
    expect(find.text('Recibes el 100 %: \$ 14.700'), findsOneWidget);
    expect(find.text('El pasajero dice que te pagó \$ 14.700 en efectivo.'), findsOneWidget);
    expect(find.textContaining('Cobra al pasajero directamente'), findsNothing);

    await tapAndConfirm(tester, 'payment.confirmCash');
    verify(() => api.confirmCashReceived('t1')).called(1);
    expect(find.text('Pagado en efectivo'), findsOneWidget);
  });

  testWidgets('FR-005: "No recibí el efectivo" deja el pago en disputa', (tester) async {
    when(() => api.disputeCash('t1')).thenAnswer((_) async => _payment(TripPaymentStatus.disputed));
    await pumpSummary(tester, _payment(TripPaymentStatus.cashReported, method: TripPaymentMethod.cash));
    await tapAndConfirm(tester, 'payment.disputeCash');
    verify(() => api.disputeCash('t1')).called(1);
    expect(find.textContaining('En disputa'), findsOneWidget);
  });

  testWidgets('FR-006: sin reporte, el conductor puede marcar "No me pagó"', (tester) async {
    when(() => api.markTripUnpaid('t1')).thenAnswer((_) async => _payment(TripPaymentStatus.unpaid));
    await pumpSummary(tester, _payment(TripPaymentStatus.pending));
    expect(find.byKey(const Key('payment.disputeCash')), findsNothing);
    await tapAndConfirm(tester, 'payment.markUnpaid');
    verify(() => api.markTripUnpaid('t1')).called(1);
    expect(find.text('No pagado'), findsOneWidget);
    expect(find.byKey(const Key('payment.confirmCash')), findsOneWidget, reason: 'aún puede confirmar si le pagan');
  });

  testWidgets('FR-007: el reporte del pasajero llega en vivo; Bold se gira al 100 %', (tester) async {
    await pumpSummary(tester, _payment(TripPaymentStatus.pending));
    api.payment = _payment(TripPaymentStatus.paid, method: TripPaymentMethod.bold);
    events.add(TripPaymentUpdated(DateTime.now(), tripId: 't1', paymentId: 'tp1', status: 'paid', method: 'bold'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Pagado con Bold'), findsOneWidget);
    expect(find.textContaining('te gira el 100 %'), findsOneWidget);
  });

  testWidgets('viajes sin pago registrado conservan el aviso de cobrar directamente', (tester) async {
    await pumpSummary(tester, null);
    expect(find.textContaining('Cobra al pasajero directamente'), findsOneWidget);
  });

  group('Pagos de viajes', () {
    const methods = PaymentMethods(acceptsCash: true, acceptsBold: true, boldAvailable: true);
    final settlement = DriverSettlement(
      balances: const [SettlementBalance(currency: 'COP', creditedMinor: 1470000, balanceMinor: 1470000)],
      entries: [
        LedgerEntry(
          id: 'e1',
          kind: LedgerKinds.tripCredit,
          amountMinor: 1470000,
          currency: 'COP',
          tripId: 't2',
          createdAt: DateTime.utc(2026, 10, 27, 12),
        ),
      ],
      payments: [
        _payment(TripPaymentStatus.paid, method: TripPaymentMethod.bold, id: 'tp2', tripId: 't2'),
        _payment(TripPaymentStatus.cashReported, method: TripPaymentMethod.cash),
      ],
    );

    Future<void> pumpPage(WidgetTester tester) async {
      // Pantalla alta: la lista entera cabe y los botones se pueden tocar sin desplazarse.
      tester.view.physicalSize = const Size(1080, 4000);
      addTearDown(tester.view.reset);
      when(() => api.driverSettlement()).thenAnswer((_) async => settlement);
      when(() => api.driverPaymentMethods()).thenAnswer((_) async => methods);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(create: (_) => TripPaymentsCubit(api)..load(), child: const TripPaymentsPage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('FR-013: saldo por girar, libro y pagos recientes', (tester) async {
      await pumpPage(tester);
      expect(find.text('\$ 14.700'), findsWidgets);
      expect(find.byKey(const Key('tripPayments.balance')), findsOneWidget);
      expect(find.text('Pagado con Bold'), findsOneWidget);
      expect(find.text('Pago con Bold'), findsOneWidget);
    });

    testWidgets('FR-018: cambia los medios aceptados, pero nunca deja ninguno', (tester) async {
      when(
        () => api.setDriverPaymentMethods(cash: false, bold: true),
      ).thenAnswer((_) async => const PaymentMethods(acceptsCash: false, acceptsBold: true, boldAvailable: true));
      await pumpPage(tester);

      await tester.tap(find.byKey(const Key('tripPayments.cash')));
      await tester.pumpAndSettle();
      verify(() => api.setDriverPaymentMethods(cash: false, bold: true)).called(1);

      await tester.tap(find.byKey(const Key('tripPayments.bold')));
      // El aviso anterior ("guardados") ocupa la barra hasta que se cierra.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Debes aceptar al menos un medio de pago.'), findsOneWidget);
      verifyNever(() => api.setDriverPaymentMethods(cash: false, bold: false));
    });

    testWidgets('FR-005: confirma el efectivo desde la lista y recarga', (tester) async {
      when(
        () => api.confirmCashReceived('t1'),
      ).thenAnswer((_) async => _payment(TripPaymentStatus.paid, method: TripPaymentMethod.cash));
      await pumpPage(tester);
      await tapAndConfirm(tester, 'payment.confirmCash');
      verify(() => api.confirmCashReceived('t1')).called(1);
      verify(() => api.driverSettlement()).called(2);
    });
  });
}
