import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_rider_app/places/saved_places.dart';
import 'package:kyq_rider_app/reservations/booking_cubit.dart';
import 'package:kyq_rider_app/reservations/booking_page.dart';
import 'package:kyq_rider_app/reservations/reservations_cubit.dart';
import 'package:kyq_rider_app/reservations/reservations_page.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

final _now = DateTime(2026, 10, 28, 12);
const _here = GeoPoint(lat: 4.65, lng: -74.05);
const _andino = Place(label: 'Centro Comercial Andino', lat: 4.667, lng: -74.053);
const _quote = FareQuote(
  distanceM: 5200,
  durationS: 900,
  suggestedFareMinor: 1320000,
  currency: 'COP',
  preferentialDiscountPct: 10,
  listFareMinor: 1470000,
);

Reservation _reservation(String id, ReservationStatus status, DateTime at) => Reservation(
  id: id,
  passenger: const PersonRef(id: 'p1', displayName: 'Ana'),
  driver: const PersonRef(id: 'd1', displayName: 'Carlos'),
  pickup: _here,
  dropoff: _andino.point,
  dropoffLabel: _andino.label,
  scheduledAt: at,
  distanceM: 5200,
  durationS: 900,
  currency: 'COP',
  fareMinor: 1320000,
  listFareMinor: 1470000,
  status: status,
);

void main() {
  late MockApi api;

  setUpAll(() {
    registerFallbackValue(_here);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    api = MockApi();
    when(() => api.quote(any(), any(), driverId: any(named: 'driverId'))).thenAnswer((_) async => _quote);
  });

  BookingCubit booking() =>
      BookingCubit(api: api, location: FakeLocation(), driverId: 'd1', driverName: 'Carlos', now: () => _now);

  group('reservar (US1)', () {
    test('recogida en la ubicación, destino buscado y tarifa con la preferencial del conductor', () async {
      final c = booking();
      await c.start();
      expect(c.state.pickup, _here);
      await c.setDropoff(_andino);
      verify(() => api.quote(_here, _andino.point, driverId: 'd1')).called(1);
      expect(c.state.quote, _quote);
      expect(c.state.canSubmit, isFalse, reason: 'falta la hora');
    });

    test('hora fuera de 30 minutos a 7 días: avisa y no envía', () async {
      final c = booking();
      await c.start();
      await c.setDropoff(_andino);
      c.setScheduledAt(_now.add(const Duration(minutes: 20)));
      expect(c.state.error, 'Reserva con al menos 30 minutos de anticipación.');
      c.setScheduledAt(_now.add(const Duration(days: 8)));
      expect(c.state.error, 'Solo se puede reservar hasta 7 días antes.');
      await c.submit();
      verifyNever(
        () => api.createReservation(
          driverId: any(named: 'driverId'),
          pickup: any(named: 'pickup'),
          dropoff: any(named: 'dropoff'),
          scheduledAt: any(named: 'scheduledAt'),
          pickupLabel: any(named: 'pickupLabel'),
          dropoffLabel: any(named: 'dropoffLabel'),
        ),
      );
    });

    test('envía con las direcciones y explica el máximo de 3', () async {
      final at = _now.add(const Duration(hours: 2));
      var calls = 0;
      when(
        () => api.createReservation(
          driverId: 'd1',
          pickup: _here,
          dropoff: _andino.point,
          scheduledAt: at,
          pickupLabel: 'Mi ubicación actual',
          dropoffLabel: _andino.label,
        ),
      ).thenAnswer((_) async {
        if (++calls == 1) throw const ApiException(409, 'too_many_reservations', '');
        return _reservation('r1', ReservationStatus.pending, at);
      });
      final c = booking();
      await c.start();
      await c.setDropoff(_andino);
      c.setScheduledAt(at);
      await c.submit();
      expect(c.state.error, 'Ya tienes 3 reservas activas. Cancela una para hacer otra.');
      await c.submit();
      expect(c.state.booked?.id, 'r1');
    });

    testWidgets('pantalla: elige destino y hora y reserva', (tester) async {
      final at = DateTime.now().add(const Duration(hours: 3));
      when(
        () => api.createReservation(
          driverId: any(named: 'driverId'),
          pickup: any(named: 'pickup'),
          dropoff: any(named: 'dropoff'),
          scheduledAt: any(named: 'scheduledAt'),
          pickupLabel: any(named: 'pickupLabel'),
          dropoffLabel: any(named: 'dropoffLabel'),
        ),
      ).thenAnswer((_) async => _reservation('r1', ReservationStatus.pending, at));
      when(() => api.searchPlaces(any())).thenAnswer((_) async => [_andino]);
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<KyqApiClient>.value(value: api),
            RepositoryProvider<SavedPlacesStore>.value(value: MemorySavedPlaces()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider(
                        create: (_) =>
                            BookingCubit(api: api, location: FakeLocation(), driverId: 'd1', driverName: 'Carlos')
                              ..start(),
                        child: BookingPage(pickDateTime: (_, _) async => at),
                      ),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Mi ubicación actual'), findsOneWidget);
      await tester.tap(find.byKey(const Key('booking.dropoff')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('places.query')), 'Andino');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('places.result.0')));
      await tester.pumpAndSettle();
      expect(find.text('Tarifa preferencial −10 %'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('booking.submit'))).onPressed, isNull);
      await tester.tap(find.byKey(const Key('booking.when')));
      await tester.pumpAndSettle();
      expect(find.text(formatSlot(at)), findsOneWidget);
      await tester.tap(find.byKey(const Key('booking.submit')));
      await tester.pumpAndSettle();
      expect(find.text('Reserva enviada. Carlos debe confirmarla.'), findsOneWidget);
      expect(find.text('abrir'), findsOneWidget);
    });
  });

  group('mis reservas (US1)', () {
    late FakeRealtime realtime;

    setUp(() {
      realtime = FakeRealtime();
      when(() => api.currentSession()).thenAnswer(
        (_) async => Tokens(accessToken: fakeAccessToken('p1'), refreshToken: 'r', role: UserRole.passenger),
      );
    });

    test('se recarga con los eventos y guarda el aviso', () async {
      final at = _now.add(const Duration(hours: 2));
      api.reservationList = [_reservation('r1', ReservationStatus.pending, at)];
      final c = ReservationsCubit(api, realtime: realtime);
      await c.start();
      expect(c.state.next?.id, 'r1');
      api.reservationList = [_reservation('r1', ReservationStatus.missed, at)];
      final notice = ReservationNotice(
        _now,
        reservationId: 'r1',
        status: 'missed',
        message: 'Tu conductor no está disponible para la reserva.',
      );
      realtime.emit('user:p1', notice);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.notice, notice);
      expect(c.state.next, isNull);
      await c.close();
    });

    testWidgets('cancelar pide confirmación', (tester) async {
      final at = DateTime.now().add(const Duration(hours: 2));
      api.reservationList = [
        _reservation('r1', ReservationStatus.confirmed, at),
        _reservation('r0', ReservationStatus.expired, at.subtract(const Duration(days: 1))),
      ];
      when(() => api.cancelReservation('r1')).thenAnswer((_) async {
        api.reservationList = [_reservation('r1', ReservationStatus.cancelled, at)];
        return api.reservationList.first;
      });
      final cubit = ReservationsCubit(api, realtime: realtime)..start();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: cubit, child: const ReservationsPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Confirmada'), findsOneWidget);
      expect(find.byKey(const ValueKey('reservations.cancel.r0')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('reservations.cancel.r1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reservations.confirmCancel')));
      await tester.pumpAndSettle();
      verify(() => api.cancelReservation('r1')).called(1);
      expect(find.textContaining('La cancelaste'), findsNothing);
      expect(find.textContaining('Cancelada'), findsOneWidget);
    });
  });
}
