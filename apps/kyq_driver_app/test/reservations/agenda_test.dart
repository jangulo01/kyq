import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/offers/offer.dart';
import 'package:kyq_driver_app/onboarding/client_card_page.dart';
import 'package:kyq_driver_app/reservations/agenda_cubit.dart';
import 'package:kyq_driver_app/reservations/agenda_page.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

Reservation _reservation(String id, ReservationStatus status, {bool overlaps = false}) => Reservation(
  id: id,
  passenger: const PersonRef(id: 'p1', displayName: 'Ana'),
  driver: const PersonRef(id: 'd1', displayName: 'Carlos'),
  pickup: const GeoPoint(lat: 4.6, lng: -74.08),
  dropoff: const GeoPoint(lat: 4.65, lng: -74.05),
  dropoffLabel: 'Andino',
  scheduledAt: DateTime(2026, 10, 28, 14),
  distanceM: 5200,
  durationS: 900,
  currency: 'COP',
  fareMinor: 1320000,
  listFareMinor: 1470000,
  preferentialDiscountPct: 10,
  status: status,
  overlaps: overlaps,
);

void main() {
  late MockApi api;
  late StreamController<RealtimeEvent> events;

  setUp(() {
    api = MockApi();
    events = StreamController<RealtimeEvent>.broadcast();
  });

  tearDown(() => events.close());

  group('agenda (010, US1)', () {
    test('carga, recarga con reservation.updated y acepta', () async {
      var calls = 0;
      when(() => api.driverAgenda()).thenAnswer((_) async {
        calls++;
        return [_reservation('r1', calls > 2 ? ReservationStatus.confirmed : ReservationStatus.pending)];
      });
      when(() => api.acceptReservation('r1')).thenAnswer((_) async => _reservation('r1', ReservationStatus.confirmed));
      final cubit = AgendaCubit(api, events.stream);
      await cubit.load();
      expect(cubit.state.pending.single.id, 'r1');

      events.add(ReservationUpdated(DateTime(2026), reservationId: 'r1', status: 'pending'));
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2);

      await cubit.accept(cubit.state.pending.single);
      verify(() => api.acceptReservation('r1')).called(1);
      expect(cubit.state.confirmed.single.id, 'r1');
      expect(cubit.state.busyId, isNull);
      await cubit.close();
    });

    test('reserva ya cambiada: avisa y recarga', () async {
      when(() => api.driverAgenda()).thenAnswer((_) async => [_reservation('r1', ReservationStatus.pending)]);
      when(() => api.rejectReservation('r1')).thenThrow(const ApiException(409, 'invalid_state', ''));
      final cubit = AgendaCubit(api, events.stream);
      await cubit.load();
      final states = <AgendaState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.reject(cubit.state.pending.single);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(states.map((s) => s.error), contains('La reserva ya cambió; actualizamos tu agenda.'));
      await cubit.close();
    });

    testWidgets('pantalla: solape marcado y botones por estado', (tester) async {
      when(() => api.driverAgenda()).thenAnswer(
        (_) async => [
          _reservation('r1', ReservationStatus.pending, overlaps: true),
          _reservation('r2', ReservationStatus.confirmed),
        ],
      );
      when(() => api.acceptReservation('r1')).thenAnswer((_) async => _reservation('r1', ReservationStatus.confirmed));
      final cubit = AgendaCubit(api, events.stream)..load();
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: cubit, child: const AgendaPage()),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('agenda.overlap.r1')), findsOneWidget);
      expect(find.byKey(const ValueKey('agenda.overlap.r2')), findsNothing);
      expect(find.byKey(const ValueKey('agenda.cancel.r2')), findsOneWidget);
      expect(find.byKey(const ValueKey('agenda.accept.r2')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('agenda.accept.r1')));
      await tester.pump();
      await tester.pump();
      verify(() => api.acceptReservation('r1')).called(1);
      // Cerrar el cubit dentro de la zona de testWidgets no termina; lo libera el tearDown.
      addTearDown(cubit.close);
    });
  });

  group('ficha del cliente (010, US2)', () {
    ClientCard card({String? note}) => ClientCard(
      passengerId: 'p1',
      displayName: 'Ana',
      affiliatedAt: DateTime(2026, 9),
      tripsTogether: 7,
      lastTripAt: DateTime(2026, 10, 20, 8, 30),
      note: note,
      upcomingReservations: [
        UpcomingReservation(id: 'r1', scheduledAt: DateTime(2026, 10, 30, 7), status: ReservationStatus.confirmed),
      ],
    );

    testWidgets('muestra viajes y reservas; guarda la nota', (tester) async {
      when(() => api.clientCard('p1')).thenAnswer((_) async => card(note: 'Portería 2'));
      when(
        () => api.setClientNote('p1', any()),
      ).thenAnswer((i) async => card(note: i.positionalArguments[1] as String));
      await tester.pumpWidget(
        RepositoryProvider<KyqApiClient>.value(
          value: api,
          child: const MaterialApp(home: ClientCardPage(passengerId: 'p1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('7 viajes juntos'), findsOneWidget);
      expect(find.text('Portería 2'), findsOneWidget);
      expect(find.text('30/10 07:00'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('client.note')), '  Prefiere aire acondicionado ');
      await tester.tap(find.byKey(const Key('client.saveNote')));
      await tester.pumpAndSettle();
      verify(() => api.setClientNote('p1', 'Prefiere aire acondicionado')).called(1);
      expect(find.text('Nota guardada. Solo tú la ves.'), findsOneWidget);
    });

    testWidgets('cliente que ya no está en la cartera', (tester) async {
      when(() => api.clientCard('p1')).thenThrow(const ApiException(404, 'client_not_found', ''));
      await tester.pumpWidget(
        RepositoryProvider<KyqApiClient>.value(
          value: api,
          child: const MaterialApp(home: ClientCardPage(passengerId: 'p1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Este pasajero ya no está en tu cartera.'), findsOneWidget);
    });
  });

  group('oferta (010)', () {
    TripOffered offered({bool reservation = false, String? note}) => TripOffered(
      DateTime(2026),
      tripId: 't1',
      passengerName: 'Ana',
      pickup: (lat: 4.6, lng: -74.05),
      dropoff: (lat: 4.7, lng: -74.1),
      distanceM: 4200,
      durationS: 720,
      suggestedFareMinor: 1320000,
      currency: 'COP',
      expiresAt: DateTime(2026),
      loyalClient: true,
      tripsTogether: 7,
      reservation: reservation,
      clientNote: note,
    );

    test('la reserva lleva su etiqueta y la nota llega al conductor', () {
      final o = Offer.fromEvent(offered(reservation: true, note: 'Portería 2'));
      expect(o.label, '📅 Reserva de tu agenda');
      expect(o.clientNote, 'Portería 2');
      expect(Offer.fromEvent(offered()).label, isNot('📅 Reserva de tu agenda'));
    });
  });
}
