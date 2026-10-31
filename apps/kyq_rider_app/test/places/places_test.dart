import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_rider_app/map/trip_map.dart';
import 'package:kyq_rider_app/places/place_search_page.dart';
import 'package:kyq_rider_app/places/saved_places.dart';
import 'package:kyq_rider_app/request/request_cubit.dart';
import 'package:kyq_rider_app/request/request_page.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

const _andino = Place(label: 'Centro Comercial Andino', detail: 'Carrera 11 # 82, Bogotá', lat: 4.667, lng: -74.053);
const _casa = Place(label: 'Calle 72 # 10', detail: 'Chapinero', lat: 4.657, lng: -74.061);

Place _p(int i) => Place(label: 'Lugar $i', lat: 4.6 + i / 100, lng: -74.0);

void main() {
  setUpAll(() => registerFallbackValue(const GeoPoint(lat: 0, lng: 0)));

  group('recientes (FR-015)', () {
    test('el último va primero, sin duplicados y como mucho 10', () async {
      final store = MemorySavedPlaces();
      for (var i = 0; i < 12; i++) {
        await store.addRecent(_p(i));
      }
      await store.addRecent(_p(5));
      final recents = (await store.load()).recents;
      expect(recents, hasLength(maxRecents));
      expect(recents.first, _p(5));
      expect(recents.where((p) => p == _p(5)), hasLength(1));
      expect(recents, isNot(contains(_p(0))));
    });
  });

  group('buscador (US5)', () {
    late MockApi api;
    late MemorySavedPlaces store;
    Place? chosen;

    Future<void> open(WidgetTester tester) async {
      chosen = null;
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<KyqApiClient>.value(value: api),
            RepositoryProvider<SavedPlacesStore>.value(value: store),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async => chosen = await showPlaceSearch(context, title: '¿A dónde vas?'),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    setUp(() {
      api = MockApi();
      store = MemorySavedPlaces(SavedPlaces(home: _casa, recents: [_p(1)]));
    });

    testWidgets('antes de escribir: Casa y recientes; con 3 letras busca una vez tras la pausa', (tester) async {
      when(() => api.searchPlaces(any())).thenAnswer((_) async => [_andino]);
      await open(tester);
      expect(find.byKey(const Key('places.home')), findsOneWidget);
      expect(find.text('Casa'), findsOneWidget);
      expect(find.byKey(const Key('places.recent.0')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('places.query')), 'An');
      await tester.pump(placeSearchDebounce);
      verifyNever(() => api.searchPlaces(any()));

      await tester.enterText(find.byKey(const Key('places.query')), 'And');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byKey(const Key('places.query')), 'Andino');
      await tester.pump(placeSearchDebounce);
      await tester.pumpAndSettle();
      verify(() => api.searchPlaces('Andino')).called(1);

      await tester.tap(find.byKey(const Key('places.result.0')));
      await tester.pumpAndSettle();
      expect(chosen, _andino);
      expect((await store.load()).recents.first, _andino);
    });

    testWidgets('guardar como Trabajo', (tester) async {
      await open(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('places.recent.0')),
          matching: find.byType(PopupMenuButton<SavedSlot>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar como Trabajo'));
      await tester.pumpAndSettle();
      expect((await store.load()).work, _p(1));
      expect(find.byKey(const Key('places.work')), findsOneWidget);
    });

    testWidgets('sin buscador: lo explica y deja marcar en el mapa (FR-016)', (tester) async {
      when(() => api.searchPlaces(any())).thenThrow(const ApiException(503, 'places_unavailable', ''));
      await open(tester);
      await tester.enterText(find.byKey(const Key('places.query')), 'Andino');
      await tester.pump(placeSearchDebounce);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('places.error')), findsOneWidget);
      await tester.tap(find.byKey(const Key('places.useMap')));
      await tester.pumpAndSettle();
      expect(chosen, isNull);
      expect(find.text('abrir'), findsOneWidget);
    });

    testWidgets('en la solicitud: el destino elegido se cotiza como con el mapa', (tester) async {
      when(() => api.quote(any(), any(), driverId: any(named: 'driverId'))).thenAnswer(
        (_) async => const FareQuote(distanceM: 6200, durationS: 900, suggestedFareMinor: 1470000, currency: 'COP'),
      );
      when(() => api.searchPlaces(any())).thenAnswer((_) async => [_andino]);
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<KyqApiClient>.value(value: api),
            RepositoryProvider<SavedPlacesStore>.value(value: store),
          ],
          child: MaterialApp(
            theme: kyqTheme(),
            home: BlocProvider(
              create: (_) =>
                  RequestCubit(api: api, location: FakeLocation(), driverId: 'd1', driverName: 'Carlos')..start(),
              child: RequestPage(map: (TripMapMarkers m, _) => const ColoredBox(color: Colors.blueGrey)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('request.search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('places.query')), 'Andino');
      await tester.pump(placeSearchDebounce);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('places.result.0')));
      await tester.pumpAndSettle();

      verify(() => api.quote(const GeoPoint(lat: 4.65, lng: -74.05), _andino.point, driverId: 'd1')).called(1);
      expect(find.text('\$ 14.700'), findsOneWidget);
      expect(find.text('Centro Comercial Andino'), findsOneWidget);
    });
  });
}
