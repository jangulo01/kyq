import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_rider_app/map/trip_map.dart';
import 'package:kyq_rider_app/payments/pending_payments_banner.dart';
import 'package:kyq_rider_app/payments/pending_payments_cubit.dart';
import 'package:kyq_rider_app/trip/checkout_launcher.dart';
import 'package:kyq_rider_app/trip/trip_cubit.dart';
import 'package:kyq_rider_app/trip/trip_page.dart';
import 'package:kyq_rider_app/trip/trip_payment_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

class _FakeCheckout implements CheckoutLauncher {
  final opened = <String>[];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return true;
  }
}

const _trip = Trip(
  id: 't1',
  status: TripStatus.completed,
  passengerId: 'p1',
  driverId: 'd1',
  pickup: GeoPoint(lat: 4.65, lng: -74.05),
  dropoff: GeoPoint(lat: 4.70, lng: -74.04),
  distanceM: 6200,
  durationS: 900,
  currency: 'COP',
  suggestedFareMinor: 1800000,
  agreedFareMinor: 1800000,
);

TripPayment _payment(
  TripPaymentStatus status, {
  TripPaymentMethod? method,
  List<TripPaymentMethod> accepted = const [TripPaymentMethod.bold, TripPaymentMethod.cash],
  String? checkoutUrl,
}) => TripPayment(
  id: 'tp1',
  tripId: 't1',
  driverId: 'd1',
  passengerId: 'p1',
  driverName: 'Carlos',
  amountMinor: 1800000,
  currency: 'COP',
  driverAmountMinor: 1800000,
  status: status,
  method: method,
  acceptedMethods: accepted,
  checkoutUrl: checkoutUrl,
  createdAt: DateTime.utc(2026, 10, 27, 12),
);

/// Desmonta la pantalla y cierra el cubit (para el sondeo) sin esperar dentro del reloj falso.
Future<void> _dispose(WidgetTester tester, Cubit<Object?> cubit) async {
  await tester.pumpWidget(const SizedBox());
  unawaited(cubit.close());
  await tester.pump();
}

Widget _fakeMap(TripMapMarkers markers, ValueChanged<GeoPoint>? onTap) => const ColoredBox(color: Colors.blueGrey);

void main() {
  late MockApi api;
  late _FakeCheckout checkout;
  late FakeRealtime realtime;

  setUp(() {
    api = MockApi();
    checkout = _FakeCheckout();
    realtime = FakeRealtime();
    when(() => api.currentSession()).thenAnswer((_) async => null);
    when(() => api.getTrip('t1')).thenAnswer((_) async => _trip);
  });

  Future<TripPaymentCubit> pump(WidgetTester tester, TripPayment? payment) async {
    when(() => api.tripPayment('t1')).thenAnswer((_) async => payment);
    final paymentCubit = TripPaymentCubit(api: api, tripId: 't1', checkout: checkout, realtime: realtime);
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => TripCubit(api: api, tripId: 't1')..start(),
            ),
            BlocProvider.value(value: paymentCubit..load()),
          ],
          child: const TripPage(driverName: 'Carlos', map: _fakeMap, payments: true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return paymentCubit;
  }

  testWidgets('FR-002: el resumen muestra el total, el 100 % y los medios que acepta el conductor', (tester) async {
    await pump(tester, _payment(TripPaymentStatus.pending));
    expect(find.text('\$ 18.000'), findsOneWidget);
    expect(find.text('Pendiente de pago'), findsOneWidget);
    expect(find.byKey(const Key('payment.bold')), findsOneWidget);
    expect(find.byKey(const Key('payment.cash')), findsOneWidget);
    expect(find.textContaining('Págale directamente'), findsNothing, reason: 'ya no se paga por fuera');
  });

  testWidgets('FR-004: "Pagué en efectivo" pide confirmación y queda esperando al conductor', (tester) async {
    when(
      () => api.reportCashPayment('t1'),
    ).thenAnswer((_) async => _payment(TripPaymentStatus.cashReported, method: TripPaymentMethod.cash));
    await pump(tester, _payment(TripPaymentStatus.pending));

    await tester.tap(find.byKey(const Key('payment.cash')));
    await tester.pumpAndSettle();
    expect(find.textContaining('le entregaste \$ 18.000 a Carlos'), findsOneWidget);
    await tester.tap(find.byKey(const Key('payment.cashConfirm')));
    await tester.pumpAndSettle();

    verify(() => api.reportCashPayment('t1')).called(1);
    expect(find.textContaining('Efectivo reportado'), findsOneWidget);
    expect(find.text('Esperamos que Carlos confirme que recibió el efectivo.'), findsOneWidget);
    expect(find.byKey(const Key('payment.cash')), findsNothing);
  });

  testWidgets('FR-003: Bold abre el checkout y al volver a la app consulta el pago', (tester) async {
    const url = 'https://checkout.bold.co/payment/LNK_1';
    when(() => api.payTripWithBold('t1')).thenAnswer(
      (_) async => _payment(TripPaymentStatus.boldInProgress, method: TripPaymentMethod.bold, checkoutUrl: url),
    );
    when(
      () => api.refreshTripPayment('t1'),
    ).thenAnswer((_) async => _payment(TripPaymentStatus.paid, method: TripPaymentMethod.bold));
    final cubit = await pump(tester, _payment(TripPaymentStatus.pending));

    await tester.tap(find.byKey(const Key('payment.bold')));
    await tester.pump();
    expect(checkout.opened, [url]);
    expect(find.byKey(const Key('payment.boldContinue')), findsOneWidget);

    await cubit.onResumed();
    await tester.pump();
    expect(find.text('Pagado con Bold'), findsOneWidget);
    expect(find.text('¡Gracias! Carlos recibe el 100 %.'), findsOneWidget);
    await _dispose(tester, cubit);
  });

  testWidgets('US2-4: si Bold no completa el pago, se avisa y se puede elegir otra vez', (tester) async {
    when(() => api.refreshTripPayment('t1')).thenAnswer((_) async => _payment(TripPaymentStatus.pending));
    final cubit = await pump(
      tester,
      _payment(TripPaymentStatus.boldInProgress, method: TripPaymentMethod.bold, checkoutUrl: 'https://x'),
    );
    await tester.tap(find.byKey(const Key('payment.refresh')));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('no se completó'), findsOneWidget);
    expect(find.byKey(const Key('payment.bold')), findsOneWidget);
    await _dispose(tester, cubit);
  });

  testWidgets('FR-018: con un conductor que solo acepta efectivo no hay botón de Bold', (tester) async {
    await pump(tester, _payment(TripPaymentStatus.pending, accepted: const [TripPaymentMethod.cash]));
    expect(find.byKey(const Key('payment.bold')), findsNothing);
    expect(find.byKey(const Key('payment.cash')), findsOneWidget);
  });

  testWidgets('FR-007: la confirmación del conductor llega en vivo', (tester) async {
    await pump(tester, _payment(TripPaymentStatus.cashReported, method: TripPaymentMethod.cash));
    when(
      () => api.tripPayment('t1'),
    ).thenAnswer((_) async => _payment(TripPaymentStatus.paid, method: TripPaymentMethod.cash));
    realtime.emit(
      Channels.user('p1'),
      TripPaymentUpdated(DateTime.now(), tripId: 't1', paymentId: 'tp1', status: 'paid', method: 'cash'),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Pagado en efectivo'), findsOneWidget);
  });

  testWidgets('viajes anteriores a 004 sin pago conservan el aviso de pagar directamente', (tester) async {
    await pump(tester, null);
    expect(find.textContaining('Págale directamente a Carlos'), findsOneWidget);
  });

  testWidgets('FR-016: el aviso de viajes sin pagar lleva al pago y se recarga con el recordatorio', (tester) async {
    api.pending = [_payment(TripPaymentStatus.pending)];
    final cubit = PendingPaymentsCubit(api, realtime: realtime);
    when(
      () => api.currentSession(),
    ).thenAnswer((_) async => Tokens(accessToken: fakeAccessToken('p1'), refreshToken: 'r', role: UserRole.passenger));
    String? opened;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: BlocProvider.value(value: cubit, child: const PendingPaymentsBanner()),
          ),
        ),
        GoRoute(
          path: '/trip/:id',
          builder: (_, state) {
            opened = state.uri.toString();
            return const Scaffold(body: Text('viaje'));
          },
        ),
      ],
    );
    await cubit.start();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    expect(find.text('Tienes un viaje sin pagar: \$ 18.000 con Carlos'), findsOneWidget);

    api.pending = [_payment(TripPaymentStatus.pending), _payment(TripPaymentStatus.unpaid)];
    realtime.emit(
      Channels.user('p1'),
      TripPaymentReminder(DateTime.now(), tripId: 't2', paymentId: 'tp2', amountMinor: 1800000, currency: 'COP'),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Tienes 2 viajes sin pagar'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pendingPayments.pay')));
    await tester.pumpAndSettle();
    expect(opened, '/trip/t1?name=Carlos');
    await _dispose(tester, cubit);
  });
}
