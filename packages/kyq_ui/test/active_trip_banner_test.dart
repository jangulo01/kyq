import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

const _trip = Trip(
  id: 't1',
  status: TripStatus.accepted,
  passengerId: 'p1',
  driverId: 'd1',
  pickup: GeoPoint(lat: 4.6, lng: -74.08),
  dropoff: GeoPoint(lat: 4.65, lng: -74.05),
  distanceM: 5200,
  durationS: 900,
  currency: 'COP',
  suggestedFareMinor: 1470000,
);

void main() {
  Widget host({required Future<Trip?> Function() load, required void Function(Trip) onOpen, Object? key}) =>
      MaterialApp(
        home: Scaffold(
          body: ActiveTripBanner(load: load, onOpen: onOpen, refreshKey: key),
        ),
      );

  testWidgets('con un viaje en curso muestra el aviso y lo abre', (tester) async {
    Trip? opened;
    await tester.pumpWidget(host(load: () async => _trip, onOpen: (t) => opened = t));
    await tester.pump();

    expect(find.text('Tienes un viaje en curso'), findsOneWidget);
    await tester.tap(find.byKey(const Key('activeTrip.open')));
    expect(opened?.id, 't1');
  });

  testWidgets('sin viaje no muestra nada y vuelve a consultar al cambiar refreshKey', (tester) async {
    Trip? next;
    var loads = 0;
    Future<Trip?> load() async {
      loads++;
      return next;
    }

    await tester.pumpWidget(host(load: load, onOpen: (_) {}, key: 'free'));
    await tester.pump();
    expect(find.text('Tienes un viaje en curso'), findsNothing);

    next = _trip;
    await tester.pumpWidget(host(load: load, onOpen: (_) {}, key: 'busy'));
    await tester.pump();
    expect(loads, 2);
    expect(find.text('Tienes un viaje en curso'), findsOneWidget);
  });

  testWidgets('un fallo de red no rompe la pantalla', (tester) async {
    await tester.pumpWidget(
      host(load: () async => throw const ApiException(null, 'network', 'sin red'), onOpen: (_) {}),
    );
    await tester.pump();
    expect(find.byType(ActiveTripBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
