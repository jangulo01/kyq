import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/trip/trip_summary_page.dart';

import '../support/fakes.dart';

Future<void> _pump(WidgetTester tester, Trip t) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: TripSummaryView(trip: t, onDone: () {}),
      ),
    ),
  ),
);

void main() {
  testWidgets('el resumen muestra el 100 % para el conductor y comisión 0', (tester) async {
    await _pump(tester, trip(status: TripStatus.completed, agreedFareMinor: 1800000));
    expect(find.text('Viaje terminado'), findsOneWidget);
    expect(find.text('\$ 18.000'), findsOneWidget);
    expect(find.text('Recibes el 100 %: \$ 18.000'), findsOneWidget);
    expect(find.text('Comisión Kyq: \$ 0'), findsOneWidget);
  });

  testWidgets('el resumen de un viaje cancelado explica el motivo', (tester) async {
    await _pump(tester, trip(status: TripStatus.cancelled, cancelReason: 'fare_rejected'));
    expect(find.text('Viaje cancelado'), findsOneWidget);
    expect(find.text('El pasajero no aceptó la nueva tarifa.'), findsOneWidget);
    expect(find.textContaining('Comisión'), findsNothing);
  });
}
