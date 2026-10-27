import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/offers/offer_cubit.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

void main() {
  late MockApi api;
  late StreamController<RealtimeEvent> events;
  late DateTime clock;

  setUp(() {
    api = MockApi();
    events = StreamController<RealtimeEvent>.broadcast();
    clock = tripNow;
  });

  tearDown(() => events.close());

  OfferCubit build() => OfferCubit(api, events.stream, now: () => clock, tick: const Duration(milliseconds: 5));

  final shown = isA<OfferShown>();

  blocTest<OfferCubit, OfferState>(
    'muestra la oferta con 25 s de cuenta atrás',
    build: build,
    act: (_) => events.add(offerEvent()),
    expect: () => [
      shown
          .having((s) => s.secondsLeft, 'secondsLeft', 25)
          .having((s) => s.offer.passengerName, 'pasajero', 'Ana')
          .having((s) => s.offer.suggestedFareMinor, 'sugerida', 1470000),
    ],
  );

  blocTest<OfferCubit, OfferState>(
    'la cuenta atrás baja y al llegar a 0 cierra la oferta',
    build: build,
    act: (_) async {
      events.add(offerEvent());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      clock = tripNow.add(const Duration(seconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      clock = tripNow.add(const Duration(seconds: 25));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    expect: () => [
      shown.having((s) => s.secondsLeft, 'secondsLeft', 25),
      shown.having((s) => s.secondsLeft, 'secondsLeft', 15),
      isA<OfferIdle>().having((s) => s.notice, 'notice', 'La oferta venció.'),
    ],
  );

  blocTest<OfferCubit, OfferState>(
    'ignora una oferta que ya venció',
    build: build,
    act: (_) => events.add(offerEvent(expiresAt: tripNow.subtract(const Duration(seconds: 1)))),
    expect: () => <OfferState>[],
  );

  blocTest<OfferCubit, OfferState>(
    'aceptar con la tarifa sugerida pasa al viaje',
    setUp: () => when(() => api.acceptTrip('t1')).thenAnswer((_) async => trip()),
    build: build,
    act: (cubit) async {
      events.add(offerEvent());
      await Future<void>.delayed(Duration.zero);
      await cubit.accept();
    },
    expect: () => [
      shown,
      shown.having((s) => s.busy, 'busy', true),
      isA<OfferTaken>().having((s) => s.trip.status, 'status', TripStatus.accepted),
    ],
    verify: (_) => verify(() => api.acceptTrip('t1')).called(1),
  );

  blocTest<OfferCubit, OfferState>(
    'aceptar con otra tarifa envía pesos × 100',
    setUp: () => when(
      () => api.acceptTrip('t1', fareMinor: 1800000),
    ).thenAnswer((_) async => trip(status: TripStatus.farePending)),
    build: build,
    act: (cubit) async {
      events.add(offerEvent());
      await Future<void>.delayed(Duration.zero);
      await cubit.acceptWithFare(18000);
    },
    skip: 2,
    expect: () => [isA<OfferTaken>().having((s) => s.trip.status, 'status', TripStatus.farePending)],
    verify: (_) => verify(() => api.acceptTrip('t1', fareMinor: 1800000)).called(1),
  );

  blocTest<OfferCubit, OfferState>(
    'otra tarifa inválida muestra un error sin llamar a la API',
    build: build,
    act: (cubit) async {
      events.add(offerEvent());
      await Future<void>.delayed(Duration.zero);
      await cubit.acceptWithFare(0);
    },
    skip: 1,
    expect: () => [shown.having((s) => s.error, 'error', 'Escribe una tarifa válida.')],
    verify: (_) => verifyNever(() => api.acceptTrip(any(), fareMinor: any(named: 'fareMinor'))),
  );

  blocTest<OfferCubit, OfferState>(
    'proponer negociar pasa al viaje en NEGOTIATION_PENDING',
    setUp: () => when(
      () => api.requestNegotiation('t1'),
    ).thenAnswer((_) async => trip(status: TripStatus.negotiationPending, agreedFareMinor: null)),
    build: build,
    act: (cubit) async {
      events.add(offerEvent());
      await Future<void>.delayed(Duration.zero);
      await cubit.requestNegotiation();
    },
    skip: 2,
    expect: () => [isA<OfferTaken>().having((s) => s.trip.status, 'status', TripStatus.negotiationPending)],
  );

  blocTest<OfferCubit, OfferState>(
    'rechazar cierra la oferta',
    setUp: () => when(() => api.rejectTrip('t1')).thenAnswer((_) async => trip(status: TripStatus.cancelled)),
    build: build,
    act: (cubit) async {
      events.add(offerEvent());
      await Future<void>.delayed(Duration.zero);
      await cubit.reject();
    },
    skip: 2,
    expect: () => [isA<OfferIdle>().having((s) => s.notice, 'notice', 'Rechazaste el viaje.')],
  );

  blocTest<OfferCubit, OfferState>(
    'trip.offer_closed de esta oferta la oculta',
    build: build,
    act: (_) async {
      events.add(offerEvent());
      await Future<void>.delayed(Duration.zero);
      events.add(TripOfferClosed(tripNow, tripId: 'otro', reason: 'passenger'));
      events.add(TripOfferClosed(tripNow, tripId: 't1', reason: 'passenger'));
    },
    expect: () => [shown, isA<OfferIdle>().having((s) => s.notice, 'notice', 'El pasajero canceló la solicitud.')],
  );

  blocTest<OfferCubit, OfferState>(
    'si la API responde expired se cierra la oferta',
    setUp: () => when(
      () => api.acceptTrip('t1'),
    ).thenThrow(const ApiException(409, 'expired', 'se agotó el tiempo para responder')),
    build: build,
    act: (cubit) async {
      events.add(offerEvent());
      await Future<void>.delayed(Duration.zero);
      await cubit.accept();
    },
    skip: 2,
    expect: () => [isA<OfferIdle>().having((s) => s.notice, 'notice', 'La oferta venció.')],
  );

  blocTest<OfferCubit, OfferState>(
    'si la API responde invalid_transition el viaje ya no está disponible',
    setUp: () => when(
      () => api.requestNegotiation('t1'),
    ).thenThrow(const ApiException(409, 'invalid_transition', 'el viaje ya cambió de estado')),
    build: build,
    act: (cubit) async {
      events.add(offerEvent());
      await Future<void>.delayed(Duration.zero);
      await cubit.requestNegotiation();
    },
    skip: 2,
    expect: () => [isA<OfferIdle>().having((s) => s.notice, 'notice', 'Este viaje ya no está disponible.')],
  );

  blocTest<OfferCubit, OfferState>(
    'un error de red deja la oferta visible con el mensaje',
    setUp: () =>
        when(() => api.acceptTrip('t1')).thenThrow(const ApiException(null, 'network', 'sin conexión con el servidor')),
    build: build,
    act: (cubit) async {
      events.add(offerEvent());
      await Future<void>.delayed(Duration.zero);
      await cubit.accept();
    },
    skip: 2,
    expect: () => [
      shown
          .having((s) => s.busy, 'busy', false)
          .having((s) => s.error, 'error', 'Sin conexión con el servidor. Inténtalo de nuevo.'),
    ],
  );
}
