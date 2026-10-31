import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_rider_app/map/trip_map.dart';
import 'package:kyq_rider_app/request/request_cubit.dart';
import 'package:kyq_rider_app/request/request_page.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

const _there = GeoPoint(lat: 4.70, lng: -74.04);

void main() {
  setUpAll(() => registerFallbackValue(_there));

  testWidgets('toca el mapa para el destino y muestra distancia, minutos y tarifa sugerida', (tester) async {
    final api = MockApi();
    when(() => api.quote(any(), any(), driverId: any(named: 'driverId'))).thenAnswer(
      (_) async => const FareQuote(distanceM: 6200, durationS: 900, suggestedFareMinor: 1470000, currency: 'COP'),
    );
    ValueChanged<GeoPoint>? tap;
    Widget fakeMap(TripMapMarkers markers, ValueChanged<GeoPoint>? onTap) {
      tap = onTap;
      return const ColoredBox(color: Colors.blueGrey);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: kyqTheme(),
        home: BlocProvider(
          create: (_) =>
              RequestCubit(api: api, location: FakeLocation(), driverId: 'd1', driverName: 'Carlos')..start(),
          child: RequestPage(map: fakeMap),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Marca tu destino en el mapa para ver la tarifa.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('request.submit'))).onPressed, isNull);

    tap!(_there);
    await tester.pumpAndSettle();

    expect(find.text('\$ 14.700'), findsOneWidget);
    expect(find.text('6,2 km · 15 min'), findsOneWidget);
    expect(find.text('Pedir a Carlos'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('request.submit'))).onPressed, isNotNull);
  });
}
