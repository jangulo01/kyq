import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_rider_app/trip/trip_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

final _at = DateTime(2026, 10, 27, 12);

FareProposal _proposal(ProposalParty by, int amount, {String id = 'pr1'}) => FareProposal(
  id: id,
  proposedBy: by,
  amountMinor: amount,
  status: ProposalStatus.open,
  expiresAt: _at.add(const Duration(seconds: 30)),
);

Trip _trip(TripStatus status, {FareProposal? proposal, int? agreed, String? cancelReason}) => Trip(
  id: 't1',
  status: status,
  passengerId: 'p1',
  driverId: 'd1',
  pickup: const GeoPoint(lat: 4.65, lng: -74.05),
  dropoff: const GeoPoint(lat: 4.70, lng: -74.04),
  distanceM: 6200,
  durationS: 900,
  currency: 'COP',
  suggestedFareMinor: 1470000,
  agreedFareMinor: agreed,
  openProposal: proposal,
  offerExpiresAt: _at.add(const Duration(seconds: 25)),
  cancelReason: cancelReason,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late MockApi api;
  late FakeRealtime realtime;

  setUp(() {
    api = MockApi();
    realtime = FakeRealtime();
    when(
      () => api.currentSession(),
    ).thenAnswer((_) async => Tokens(accessToken: fakeAccessToken('p1'), refreshToken: 'r', role: UserRole.passenger));
  });

  TripCubit build() => TripCubit(api: api, realtime: realtime, tripId: 't1');

  group('eventos en vivo', () {
    blocTest<TripCubit, TripState>(
      'trip.status del viaje vuelve a leer el viaje y empieza a seguir al conductor',
      setUp: () {
        var calls = 0;
        when(() => api.getTrip('t1')).thenAnswer(
          (_) async => ++calls == 1 ? _trip(TripStatus.requested) : _trip(TripStatus.accepted, agreed: 1470000),
        );
      },
      build: build,
      act: (c) async {
        await c.start();
        expect(realtime.isSubscribed(Channels.user('p1')), isTrue);
        expect(realtime.isSubscribed(Channels.trip('t1')), isFalse);
        realtime.emit(Channels.user('p1'), TripStatusChanged(_at, tripId: 't1', status: 'ACCEPTED'));
        await _settle();
        realtime.emit(Channels.trip('t1'), DriverLocation(_at, lat: 4.66, lng: -74.06));
        await _settle();
      },
      verify: (c) {
        expect(c.state.trip!.status, TripStatus.accepted);
        expect(c.state.driverPosition, const GeoPoint(lat: 4.66, lng: -74.06));
        verify(() => api.getTrip('t1')).called(2);
      },
    );

    blocTest<TripCubit, TripState>(
      'trip.fare_proposal y trip.negotiation_requested refrescan; eventos de otro viaje se ignoran',
      setUp: () {
        var calls = 0;
        when(() => api.getTrip('t1')).thenAnswer(
          (_) async => switch (++calls) {
            1 => _trip(TripStatus.requested),
            2 => _trip(TripStatus.farePending, proposal: _proposal(ProposalParty.driver, 1800000)),
            _ => _trip(TripStatus.negotiationPending),
          },
        );
      },
      build: build,
      act: (c) async {
        await c.start();
        realtime.emit(Channels.user('p1'), TripStatusChanged(_at, tripId: 'otro', status: 'ACCEPTED'));
        await _settle();
        realtime.emit(
          Channels.user('p1'),
          FareProposed(
            _at,
            tripId: 't1',
            proposalId: 'pr1',
            proposedBy: 'driver',
            amountMinor: 1800000,
            expiresAt: _at,
          ),
        );
        await _settle();
        expect(c.state.trip!.status, TripStatus.farePending);
        realtime.emit(Channels.user('p1'), NegotiationRequested(_at, tripId: 't1', expiresAt: _at));
        await _settle();
      },
      verify: (c) {
        expect(c.state.trip!.status, TripStatus.negotiationPending);
        verify(() => api.getTrip('t1')).called(3);
      },
    );

    blocTest<TripCubit, TripState>(
      'al terminar el viaje deja de seguir la posición del conductor',
      setUp: () {
        var calls = 0;
        when(() => api.getTrip('t1')).thenAnswer(
          (_) async => ++calls == 1 ? _trip(TripStatus.inProgress) : _trip(TripStatus.completed, agreed: 1470000),
        );
      },
      build: build,
      act: (c) async {
        await c.start();
        expect(realtime.isSubscribed(Channels.trip('t1')), isTrue);
        realtime.emit(Channels.user('p1'), TripStatusChanged(_at, tripId: 't1', status: 'COMPLETED'));
        await _settle();
        expect(realtime.isSubscribed(Channels.trip('t1')), isFalse);
      },
      verify: (c) => expect(c.state.trip!.status, TripStatus.completed),
    );
  });

  group('confirmación de tarifa (FR-010a)', () {
    setUp(() {
      when(
        () => api.getTrip('t1'),
      ).thenAnswer((_) async => _trip(TripStatus.farePending, proposal: _proposal(ProposalParty.driver, 1800000)));
    });

    blocTest<TripCubit, TripState>(
      'aceptar la nueva tarifa',
      setUp: () => when(
        () => api.decideProposal('t1', 'pr1', accept: true),
      ).thenAnswer((_) async => _trip(TripStatus.accepted, agreed: 1800000)),
      build: build,
      act: (c) async {
        await c.start();
        await c.confirmFare(accept: true);
      },
      verify: (c) {
        expect(c.state.trip!.status, TripStatus.accepted);
        expect(c.state.trip!.agreedFareMinor, 1800000);
        expect(c.state.busy, isFalse);
      },
    );

    blocTest<TripCubit, TripState>(
      'rechazar la nueva tarifa cancela sin cargo',
      setUp: () => when(
        () => api.decideProposal('t1', 'pr1', accept: false),
      ).thenAnswer((_) async => _trip(TripStatus.cancelled, cancelReason: 'fare_rejected')),
      build: build,
      act: (c) async {
        await c.start();
        await c.confirmFare(accept: false);
      },
      verify: (c) {
        expect(c.state.trip!.status, TripStatus.cancelled);
        expect(c.state.trip!.cancelReason, 'fare_rejected');
      },
    );

    blocTest<TripCubit, TripState>(
      'si la propuesta ya venció (409) avisa y muestra el estado actual',
      setUp: () {
        when(
          () => api.decideProposal('t1', 'pr1', accept: true),
        ).thenThrow(const ApiException(409, 'invalid_state', 'expired'));
      },
      build: build,
      act: (c) async {
        await c.start();
        when(
          () => api.getTrip('t1'),
        ).thenAnswer((_) async => _trip(TripStatus.cancelled, cancelReason: 'fare_rejected'));
        await c.confirmFare(accept: true);
      },
      verify: (c) {
        expect(c.state.error, contains('El viaje cambió'));
        expect(c.state.trip!.status, TripStatus.cancelled);
      },
    );
  });

  group('negociación (FR-010c)', () {
    blocTest<TripCubit, TripState>(
      'aceptar negociar pasa a NEGOTIATING',
      setUp: () {
        when(() => api.getTrip('t1')).thenAnswer((_) async => _trip(TripStatus.negotiationPending));
        when(() => api.respondNegotiation('t1', accept: true)).thenAnswer((_) async => _trip(TripStatus.negotiating));
      },
      build: build,
      act: (c) async {
        await c.start();
        await c.respondNegotiation(accept: true);
      },
      verify: (c) => expect(c.state.trip!.status, TripStatus.negotiating),
    );

    blocTest<TripCubit, TripState>(
      'mantener la tarifa sugerida vuelve a REQUESTED',
      setUp: () {
        when(() => api.getTrip('t1')).thenAnswer((_) async => _trip(TripStatus.negotiationPending));
        when(() => api.respondNegotiation('t1', accept: false)).thenAnswer((_) async => _trip(TripStatus.requested));
      },
      build: build,
      act: (c) async {
        await c.start();
        await c.respondNegotiation(accept: false);
      },
      verify: (c) => expect(c.state.trip!.status, TripStatus.requested),
    );

    blocTest<TripCubit, TripState>(
      'contrapropuesta del pasajero queda como propuesta abierta propia',
      setUp: () {
        when(
          () => api.getTrip('t1'),
        ).thenAnswer((_) async => _trip(TripStatus.negotiating, proposal: _proposal(ProposalParty.driver, 2000000)));
        when(
          () => api.propose('t1', 1600000),
        ).thenAnswer((_) async => _proposal(ProposalParty.passenger, 1600000, id: 'pr2'));
      },
      build: build,
      act: (c) async {
        await c.start();
        await c.propose(1600000);
      },
      verify: (c) {
        expect(c.state.trip!.openProposal!.id, 'pr2');
        expect(c.state.trip!.openProposal!.proposedBy, ProposalParty.passenger);
      },
    );

    blocTest<TripCubit, TripState>(
      'aceptar la propuesta del conductor cierra el acuerdo',
      setUp: () {
        when(
          () => api.getTrip('t1'),
        ).thenAnswer((_) async => _trip(TripStatus.negotiating, proposal: _proposal(ProposalParty.driver, 1700000)));
        when(
          () => api.decideProposal('t1', 'pr1', accept: true),
        ).thenAnswer((_) async => _trip(TripStatus.accepted, agreed: 1700000));
      },
      build: build,
      act: (c) async {
        await c.start();
        await c.decideOpenProposal(accept: true);
        // Se comprueba aquí: tras close() las suscripciones ya están canceladas.
        expect(realtime.isSubscribed(Channels.trip('t1')), isTrue);
      },
      verify: (c) => expect(c.state.trip!.status, TripStatus.accepted),
    );
  });

  blocTest<TripCubit, TripState>(
    'cancelar la solicitud',
    setUp: () {
      when(() => api.getTrip('t1')).thenAnswer((_) async => _trip(TripStatus.requested));
      when(() => api.cancelTrip('t1')).thenAnswer((_) async => _trip(TripStatus.cancelled, cancelReason: 'passenger'));
    },
    build: build,
    act: (c) async {
      await c.start();
      await c.cancel();
    },
    verify: (c) => expect(c.state.trip!.cancelReason, 'passenger'),
  );
}
