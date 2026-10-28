import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_rider_app/chosen_drivers/chosen_drivers_cubit.dart';
import 'package:kyq_rider_app/chosen_drivers/chosen_drivers_page.dart';
import 'package:kyq_rider_app/map/driver_motion.dart';
import 'package:kyq_rider_app/map/trip_map.dart';
import 'package:kyq_rider_app/payments/pending_payments_cubit.dart';
import 'package:kyq_rider_app/reservations/reservations_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

const _a = GeoPoint(lat: 4.60, lng: -74.08);
const _north = GeoPoint(lat: 4.61, lng: -74.08);
const _east = GeoPoint(lat: 4.60, lng: -74.07);

void main() {
  group('rumbo e interpolación (R6)', () {
    test('rumbo hacia el norte y hacia el este', () {
      expect(bearing(_a, _north), closeTo(0, 0.5));
      expect(bearing(_a, _east), closeTo(90, 0.5));
      expect(bearing(_north, _a), closeTo(180, 0.5));
    });

    test('el giro va por el camino corto', () {
      expect(lerpAngle(350, 10, 0.5), closeTo(0, 1e-9));
      expect(lerpAngle(10, 350, 0.25), closeTo(5, 1e-9));
      expect(lerpAngle(90, 180, 0.5), closeTo(135, 1e-9));
    });

    test('punto intermedio', () {
      final mid = lerpPoint(_a, _north, 0.5);
      expect(mid.lat, closeTo(4.605, 1e-9));
      expect(mid.lng, closeTo(-74.08, 1e-9));
    });
  });

  testWidgets('el vehículo se desplaza entre ubicaciones y gira según el movimiento (FR-017)', (tester) async {
    final seen = <TripMapMarkers>[];
    var clock = DateTime(2026, 10, 28, 12);
    Widget motion(GeoPoint driver, {double? heading}) => MaterialApp(
      home: DriverMotion(
        markers: TripMapMarkers(pickup: _a, driver: driver),
        heading: heading,
        now: () => clock,
        builder: (m) {
          seen.add(m);
          return const SizedBox();
        },
      ),
    );

    await tester.pumpWidget(motion(_a));
    expect(seen.last.driver, _a);

    // Ubicaciones cada 3 s: la animación dura lo mismo.
    clock = clock.add(const Duration(seconds: 3));
    await tester.pumpWidget(motion(_north));
    await tester.pump(const Duration(milliseconds: 1500));
    final mid = seen.last.driver!;
    expect(mid.lat, greaterThan(_a.lat));
    expect(mid.lat, lessThan(_north.lat));
    expect(seen.last.driverHeading, closeTo(0, 0.5));

    await tester.pumpAndSettle();
    expect(seen.last.driver, _north);

    // Con rumbo del GPS, gana el rumbo enviado.
    clock = clock.add(const Duration(seconds: 3));
    await tester.pumpWidget(motion(_a, heading: 200));
    await tester.pumpAndSettle();
    expect(seen.last.driverHeading, closeTo(200, 1e-6));
    expect(seen.last.driver, _a);
  });

  testWidgets('inicio: pines dorados solo de los libres con zona (FR-018)', (tester) async {
    final api = MockApi();
    when(() => api.chosenDrivers()).thenAnswer(
      (_) async => [
        const ChosenDriver(
          driverId: 'd1',
          displayName: 'Carlos',
          vehicleDescription: 'Kia',
          presence: DriverPresence.free,
          zone: DriverZone(cell: '88abc', lat: 4.61, lng: -74.07),
        ),
        const ChosenDriver(
          driverId: 'd2',
          displayName: 'Beto',
          vehicleDescription: 'Renault',
          presence: DriverPresence.busy,
        ),
      ],
    );
    TripMapMarkers? shown;
    await tester.pumpWidget(
      RepositoryProvider<KyqApiClient>.value(
        value: api,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ChosenDriversCubit(api)..load()),
            BlocProvider(create: (_) => PendingPaymentsCubit(api)),
            BlocProvider(create: (_) => ReservationsCubit(api)..load()),
          ],
          child: MaterialApp(
            home: ChosenDriversPage(
              map: (m, _) {
                shown = m;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home.goldenMap')), findsOneWidget);
    expect(shown!.golden, [const GeoPoint(lat: 4.61, lng: -74.07)]);
    expect(find.byKey(const Key('chosen.book.d1')), findsOneWidget);
    expect(find.byKey(const Key('chosen.book.d2')), findsOneWidget, reason: 'se reserva aunque esté ocupado');
  });
}
