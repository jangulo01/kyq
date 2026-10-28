import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_rider_app/map/trip_map.dart';
import 'package:kyq_rider_app/request/request_cubit.dart';
import 'package:kyq_rider_app/request/request_page.dart';
import 'package:kyq_rider_app/trip/trip_cubit.dart';
import 'package:kyq_rider_app/trip/trip_page.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

// 006: selector de despacho, consentimiento de delegación y solicitud derivada (RN-KYQ-008).

const _here = GeoPoint(lat: 4.65, lng: -74.05);
const _there = GeoPoint(lat: 4.70, lng: -74.04);
const _quote = FareQuote(distanceM: 6200, durationS: 900, suggestedFareMinor: 1470000, currency: 'COP');
const _andina = CooperativeRef(id: 'c1', name: 'Cooperativa Andina');

Trip _trip({String driverId = 'd2', String? cancelReason, TripStatus status = TripStatus.requested}) => Trip(
  id: 't1',
  status: status,
  passengerId: 'p1',
  driverId: driverId,
  pickup: _here,
  dropoff: _there,
  distanceM: 6200,
  durationS: 900,
  currency: 'COP',
  suggestedFareMinor: 1470000,
  requestedDriverId: 'd1',
  driverName: driverId == 'd1' ? 'Carlos' : 'Beto',
  cooperativeId: 'c1',
  cooperativeName: 'Cooperativa Andina',
  allowDelegation: true,
  handoverCount: driverId == 'd1' ? 0 : 1,
  offerExpiresAt: DateTime.now().add(const Duration(seconds: 25)),
  cancelReason: cancelReason,
);

Widget _fakeMap(TripMapMarkers markers, ValueChanged<GeoPoint>? onTap) => const ColoredBox(color: Colors.blueGrey);

void main() {
  late MockApi api;
  late FakeRealtime realtime;

  setUpAll(() {
    registerFallbackValue(_here);
    registerFallbackValue(TripDispatch.chosenDriver);
  });

  setUp(() {
    api = MockApi();
    realtime = FakeRealtime();
    when(() => api.quote(any(), any())).thenAnswer((_) async => _quote);
  });

  RequestCubit build({CooperativeRef? cooperative = _andina}) => RequestCubit(
    api: api,
    location: FakeLocation(position: _here),
    realtime: realtime,
    driverId: 'd1',
    driverName: 'Carlos',
    cooperative: cooperative,
  );

  blocTest<RequestCubit, RequestState>(
    'con cooperativa el consentimiento viene marcado y se envía; un conductor ocupado no bloquea',
    setUp: () => when(
      () => api.requestTrip(
        driverId: 'd1',
        pickup: _here,
        dropoff: _there,
        dispatch: TripDispatch.chosenDriver,
        allowDelegation: true,
      ),
    ).thenAnswer((_) async => _trip()),
    build: build,
    act: (c) async {
      await c.start();
      realtime.emit(
        Channels.driverPresence('d1'),
        DriverPresenceChanged(DateTime.utc(2026), driverId: 'd1', presence: 'busy'),
      );
      await Future<void>.delayed(Duration.zero);
      await c.setPoint(_there);
      expect(c.state.driverFree, isFalse);
      expect(c.state.canRequest, isTrue, reason: 'FR-011: irá a un compañero');
      await c.request();
    },
    verify: (c) {
      expect(c.state.tripId, 't1');
      expect(c.assignedDriverName, 'Beto');
    },
  );

  blocTest<RequestCubit, RequestState>(
    'pedir a la cooperativa no envía consentimiento aparte',
    setUp: () => when(
      () => api.requestTrip(
        driverId: 'd1',
        pickup: _here,
        dropoff: _there,
        dispatch: TripDispatch.cooperative,
        allowDelegation: false,
      ),
    ).thenAnswer((_) async => _trip()),
    build: build,
    act: (c) async {
      await c.start();
      c.setDispatch(TripDispatch.cooperative);
      await c.setPoint(_there);
      await c.request();
    },
    verify: (c) => expect(c.state.tripId, 't1'),
  );

  blocTest<RequestCubit, RequestState>(
    'sin compañeros libres se explica',
    setUp: () => when(
      () => api.requestTrip(
        driverId: any(named: 'driverId'),
        pickup: any(named: 'pickup'),
        dropoff: any(named: 'dropoff'),
        dispatch: any(named: 'dispatch'),
        allowDelegation: any(named: 'allowDelegation'),
      ),
    ).thenThrow(const ApiException(409, 'no_driver_available', '')),
    build: build,
    act: (c) async {
      await c.start();
      await c.setPoint(_there);
      await c.request();
    },
    verify: (c) => expect(c.state.error, contains('Cooperativa Andina')),
  );

  blocTest<RequestCubit, RequestState>(
    'sin cooperativa no hay consentimiento ni opción de cooperativa (como en 001)',
    build: () => build(cooperative: null),
    act: (c) {
      c.setDispatch(TripDispatch.cooperative);
      c.setAllowDelegation(true);
    },
    verify: (c) {
      expect(c.state.dispatch, TripDispatch.chosenDriver);
      expect(c.state.allowDelegation, isFalse);
    },
  );

  testWidgets('selector triple: mi conductor, su cooperativa y la opción 3 deshabilitada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kyqTheme(),
        home: BlocProvider(
          create: (_) => build()..start(),
          child: const RequestPage(map: _fakeMap),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('request.dispatch.chosen')), findsOneWidget);
    expect(find.byKey(const Key('request.dispatch.cooperative')), findsOneWidget);
    expect(find.text('Próximamente'), findsOneWidget);
    expect(tester.widget<ListTile>(find.byKey(const Key('request.dispatch.nearest'))).enabled, isFalse);
    expect(tester.widget<CheckboxListTile>(find.byKey(const Key('request.allowDelegation'))).value, isTrue);

    await tester.tap(find.byKey(const Key('request.dispatch.cooperative')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('request.allowDelegation')), findsNothing);
    expect(find.text('Pedir a Cooperativa Andina'), findsOneWidget);
  });

  testWidgets('el pasajero ve la derivación y el nombre del compañero', (tester) async {
    when(() => api.currentSession()).thenAnswer((_) async => null);
    when(() => api.getTrip('t1')).thenAnswer((_) async => _trip());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => TripCubit(api: api, tripId: 't1')..start(),
          child: const TripPage(driverName: 'Carlos', map: _fakeMap),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Tu solicitud pasó a un compañero de Cooperativa Andina'), findsOneWidget);
    expect(find.text('Esperando a Beto…'), findsOneWidget);
  });

  testWidgets('sin compañeros libres: motivo propio al cancelar', (tester) async {
    when(() => api.currentSession()).thenAnswer((_) async => null);
    when(
      () => api.getTrip('t1'),
    ).thenAnswer((_) async => _trip(driverId: 'd1', status: TripStatus.cancelled, cancelReason: 'no_driver_available'));
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => TripCubit(api: api, tripId: 't1')..start(),
          child: const TripPage(driverName: 'Carlos', map: _fakeMap),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('No había compañeros libres'), findsOneWidget);
  });
}
