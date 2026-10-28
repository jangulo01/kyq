import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_rider_app/chosen_drivers/affiliate_link_page.dart';
import 'package:kyq_rider_app/chosen_drivers/scan_cubit.dart';
import 'package:kyq_rider_app/map/trip_map.dart';
import 'package:kyq_rider_app/request/request_cubit.dart';
import 'package:kyq_rider_app/request/request_page.dart';
import 'package:kyq_rider_app/trip/trip_cubit.dart';
import 'package:kyq_rider_app/trip/trip_page.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

// 008: bolsa zonal (opción 3 y desde el inicio), tarifa preferencial y afiliación por origen.

const _here = GeoPoint(lat: 4.65, lng: -74.05);
const _there = GeoPoint(lat: 4.70, lng: -74.04);
const _list = FareQuote(distanceM: 6200, durationS: 900, suggestedFareMinor: 1470000, currency: 'COP');
const _preferential = FareQuote(
  distanceM: 6200,
  durationS: 900,
  suggestedFareMinor: 1320000,
  listFareMinor: 1470000,
  preferentialDiscountPct: 10,
  currency: 'COP',
);

Trip _trip({TripStatus status = TripStatus.requested, TripDispatch dispatch = TripDispatch.zonePool}) => Trip(
  id: 't1',
  status: status,
  passengerId: 'p1',
  driverId: 'd9',
  pickup: _here,
  dropoff: _there,
  distanceM: 6200,
  durationS: 900,
  currency: 'COP',
  suggestedFareMinor: 1470000,
  dispatch: dispatch,
  requestedDriverId: 'd8',
  driverName: 'Beto',
  offerExpiresAt: DateTime.now().add(const Duration(seconds: 25)),
);

Widget _fakeMap(TripMapMarkers markers, ValueChanged<GeoPoint>? onTap) => const ColoredBox(color: Colors.blueGrey);

const _chosen = ChosenDriver(
  driverId: 'd9',
  displayName: 'Beto',
  vehicleDescription: 'Kia',
  presence: DriverPresence.free,
);

void main() {
  late MockApi api;
  late FakeRealtime realtime;

  setUpAll(() {
    registerFallbackValue(_here);
    registerFallbackValue(TripDispatch.chosenDriver);
    registerFallbackValue(AffiliationSource.qrScan);
  });

  setUp(() {
    api = MockApi();
    realtime = FakeRealtime();
    when(() => api.quote(any(), any())).thenAnswer((_) async => _list);
    when(() => api.quote(any(), any(), driverId: 'd1')).thenAnswer((_) async => _preferential);
  });

  RequestCubit chosen() => RequestCubit(
    api: api,
    location: FakeLocation(position: _here),
    realtime: realtime,
    driverId: 'd1',
    driverName: 'Carlos',
  );

  blocTest<RequestCubit, RequestState>(
    'sin Conductor Elegido pide a la bolsa zonal sin driver_id (FR-001)',
    setUp: () => when(
      () => api.requestTrip(pickup: _here, dropoff: _there, dispatch: TripDispatch.zonePool),
    ).thenAnswer((_) async => _trip()),
    build: () => RequestCubit(
      api: api,
      location: FakeLocation(position: _here),
      realtime: realtime,
    ),
    act: (c) async {
      await c.start();
      await c.setPoint(_there);
      await c.request();
    },
    verify: (c) {
      expect(c.nearbyOnly, isTrue);
      expect(c.state.dispatch, TripDispatch.zonePool);
      expect(c.state.tripId, 't1');
      expect(c.assignedDriverName, 'Beto');
    },
  );

  blocTest<RequestCubit, RequestState>(
    'opción 3: un Conductor Elegido ocupado no bloquea y la cotización pierde el descuento',
    setUp: () => when(
      () => api.requestTrip(pickup: _here, dropoff: _there, dispatch: TripDispatch.zonePool),
    ).thenAnswer((_) async => _trip()),
    build: chosen,
    act: (c) async {
      await c.start();
      await c.setPoint(_there);
      expect(c.state.quote, _preferential, reason: 'RN-KYQ-013: le pide a él');
      realtime.emit(
        Channels.driverPresence('d1'),
        DriverPresenceChanged(DateTime.utc(2026), driverId: 'd1', presence: 'busy'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(c.state.canRequest, isFalse);
      await c.setDispatch(TripDispatch.zonePool);
      expect(c.state.quote, _list, reason: 'la bolsa cotiza la tarifa de lista');
      expect(c.state.canRequest, isTrue);
      await c.request();
    },
    verify: (c) => expect(c.state.tripId, 't1'),
  );

  blocTest<RequestCubit, RequestState>(
    'sin conductores en la bolsa se explica',
    setUp: () => when(
      () => api.requestTrip(pickup: _here, dropoff: _there, dispatch: TripDispatch.zonePool),
    ).thenThrow(const ApiException(409, 'no_driver_available', '')),
    build: () => RequestCubit(
      api: api,
      location: FakeLocation(position: _here),
      realtime: realtime,
    ),
    act: (c) async {
      await c.start();
      await c.setPoint(_there);
      await c.request();
    },
    verify: (c) => expect(c.state.error, contains('No hay conductores libres cerca')),
  );

  testWidgets('la cotización muestra la tarifa preferencial y la de lista tachada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kyqTheme(),
        home: BlocProvider(
          create: (_) => chosen()..start(),
          child: const RequestPage(map: _fakeMap),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.element(find.byType(RequestPage)).read<RequestCubit>().setPoint(_there);
    await tester.pumpAndSettle();
    expect(find.text('Tarifa preferencial −10 %'), findsOneWidget);
    expect(find.byKey(const Key('request.listFare')), findsOneWidget);
    expect(find.text('Pedir a Carlos'), findsOneWidget);

    await tester.tap(find.byKey(const Key('request.dispatch.nearest')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('request.preferential')), findsNothing);
    expect(find.text('Pedir al conductor más cercano'), findsOneWidget);
  });

  testWidgets('desde el inicio: sin selector y con la explicación de la bolsa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => RequestCubit(
            api: api,
            location: FakeLocation(position: _here),
          )..start(),
          child: const RequestPage(map: _fakeMap),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Viaje con un conductor cercano'), findsOneWidget);
    expect(find.byKey(const Key('request.nearbyInfo')), findsOneWidget);
    expect(find.byKey(const Key('request.dispatch.nearest')), findsNothing);
  });

  testWidgets('pasar al siguiente de la bolsa no se muestra como delegación', (tester) async {
    when(() => api.currentSession()).thenAnswer((_) async => null);
    when(() => api.getTrip('t1')).thenAnswer((_) async => _trip());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => TripCubit(api: api, tripId: 't1')..start(),
          child: const TripPage(driverName: 'Ana', map: _fakeMap),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('trip.delegated')), findsNothing);
    expect(find.text('Buscando un conductor cercano'), findsOneWidget);
    expect(find.text('Esperando a Beto…'), findsOneWidget);
  });

  testWidgets('al terminar, guarda al conductor de la bolsa como Conductor Elegido (FR-014)', (tester) async {
    when(() => api.currentSession()).thenAnswer((_) async => null);
    when(() => api.getTrip('t1')).thenAnswer((_) async => _trip(status: TripStatus.completed));
    when(() => api.affiliateAfterTrip('t1')).thenAnswer((_) async => (driver: _chosen, created: true));
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => TripCubit(api: api, tripId: 't1')..start(),
          child: const TripPage(driverName: 'Beto', map: _fakeMap),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('trip.saveDriver')));
    await tester.tap(find.byKey(const Key('trip.saveDriver')));
    await tester.pumpAndSettle();
    expect(find.text('Beto quedó en tus Conductores Elegidos.'), findsOneWidget);
    verify(() => api.affiliateAfterTrip('t1')).called(1);
  });

  testWidgets('un viaje con su propio Conductor Elegido no ofrece guardarlo', (tester) async {
    when(() => api.currentSession()).thenAnswer((_) async => null);
    when(() => api.getTrip('t1')).thenAnswer(
      (_) async =>
          _trip(status: TripStatus.completed, dispatch: TripDispatch.chosenDriver).copyWith(requestedDriverId: 'd9'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => TripCubit(api: api, tripId: 't1')..start(),
          child: const TripPage(driverName: 'Beto', map: _fakeMap),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('trip.saveDriver')), findsNothing);
  });

  group('enlace del conductor (FR-015)', () {
    test('kyq://affiliate/{token} y la página pública van a su ruta', () {
      const token = 'abcdefghijklmnop';
      expect(affiliateLinkRedirect(Uri.parse('kyq://affiliate/$token')), '/affiliate/$token');
      expect(affiliateLinkRedirect(Uri.parse('https://kyq.co/a/$token')), '/affiliate/$token');
      expect(affiliateLinkRedirect(Uri.parse('kyq://affiliate/corto')), '/');
      expect(affiliateLinkRedirect(Uri.parse('/request/d1')), isNull);
    });

    blocTest<ScanCubit, ScanState>(
      'afilia con origen link',
      setUp: () => when(
        () => api.affiliate('abcdefghijklmnop', source: AffiliationSource.link),
      ).thenAnswer((_) async => (driver: _chosen, created: true)),
      build: () => ScanCubit(api),
      act: (c) => c.fromLink('abcdefghijklmnop'),
      expect: () => [isA<ScanProcessing>(), isA<ScanSucceeded>()],
    );

    blocTest<ScanCubit, ScanState>(
      'el escáner también acepta el enlace como código',
      setUp: () => when(
        () => api.affiliate('abcdefghijklmnop', source: AffiliationSource.qrScan),
      ).thenAnswer((_) async => (driver: _chosen, created: false)),
      build: () => ScanCubit(api),
      act: (c) => c.onCode('https://kyq.co/a/abcdefghijklmnop'),
      expect: () => [isA<ScanProcessing>(), isA<ScanSucceeded>()],
    );
  });
}
