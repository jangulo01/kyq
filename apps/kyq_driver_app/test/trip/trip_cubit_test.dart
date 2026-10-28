import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/trip/navigation.dart';
import 'package:kyq_driver_app/trip/trip_cubit.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

void main() {
  late MockApi api;
  late StreamController<RealtimeEvent> events;

  setUp(() {
    api = MockApi();
    events = StreamController<RealtimeEvent>.broadcast();
  });

  tearDown(() => events.close());

  TripCubit build({Trip? initial}) => TripCubit(api, events.stream, 't1', initial: initial);

  blocTest<TripCubit, TripState>(
    'recarga el viaje con cada trip.status de ese viaje',
    setUp: () => when(() => api.getTrip('t1')).thenAnswer((_) async => trip(status: TripStatus.negotiating)),
    build: () => build(initial: trip(status: TripStatus.negotiationPending)),
    act: (_) async {
      events.add(TripStatusChanged(tripNow, tripId: 'otro', status: 'ACCEPTED'));
      events.add(TripStatusChanged(tripNow, tripId: 't1', status: 'NEGOTIATING'));
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [isA<TripState>().having((s) => s.trip!.status, 'status', TripStatus.negotiating)],
    verify: (_) => verify(() => api.getTrip('t1')).called(1),
  );

  blocTest<TripCubit, TripState>(
    'aceptar la propuesta abierta del pasajero',
    setUp: () => when(() => api.decideProposal('t1', 'pr1', accept: true)).thenAnswer((_) async => trip()),
    build: () => build(
      initial: trip(
        status: TripStatus.negotiating,
        openProposal: FareProposal(
          id: 'pr1',
          proposedBy: ProposalParty.passenger,
          amountMinor: 1600000,
          status: ProposalStatus.open,
          expiresAt: tripNow,
        ),
      ),
    ),
    act: (cubit) => cubit.acceptProposal(),
    expect: () => [
      isA<TripState>().having((s) => s.busy, 'busy', true),
      isA<TripState>().having((s) => s.trip!.status, 'status', TripStatus.accepted),
    ],
  );

  blocTest<TripCubit, TripState>(
    'Llegué pasa a ARRIVED',
    setUp: () => when(() => api.arrive('t1')).thenAnswer((_) async => trip(status: TripStatus.arrived)),
    build: () => build(initial: trip()),
    act: (cubit) => cubit.arrive(),
    skip: 1,
    expect: () => [isA<TripState>().having((s) => s.trip!.status, 'status', TripStatus.arrived)],
  );

  blocTest<TripCubit, TripState>(
    'invalid_transition muestra el error y recarga el estado real',
    setUp: () {
      when(() => api.startTrip('t1')).thenThrow(const ApiException(409, 'invalid_transition', 'x'));
      when(
        () => api.getTrip('t1'),
      ).thenAnswer((_) async => trip(status: TripStatus.cancelled, cancelReason: 'passenger'));
    },
    build: () => build(initial: trip(status: TripStatus.arrived)),
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<TripState>().having((s) => s.error, 'error', 'El viaje ya cambió de estado.'),
      isA<TripState>().having((s) => s.trip!.status, 'status', TripStatus.cancelled),
    ],
  );

  test('la ruta prueba la app pedida y luego geo:', () async {
    const p = GeoPoint(lat: 4.6, lng: -74.05);
    expect(navigationUris(NavigationApp.waze, p).map((u) => u.toString()), [
      'waze://?ll=4.6,-74.05&navigate=yes',
      'geo:4.6,-74.05?q=4.6,-74.05',
    ]);
    expect(navigationUris(NavigationApp.googleMaps, p).first.toString(), 'google.navigation:q=4.6,-74.05');

    final tried = <String>[];
    final opened = await openNavigation(
      NavigationApp.waze,
      p,
      launcher: (uri) async {
        tried.add(uri.scheme);
        return uri.scheme == 'geo';
      },
    );
    expect(opened, isTrue);
    expect(tried, ['waze', 'geo']);
  });
}
