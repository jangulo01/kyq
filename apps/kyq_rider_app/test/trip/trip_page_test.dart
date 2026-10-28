import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_rider_app/map/trip_map.dart';
import 'package:kyq_rider_app/trip/trip_cubit.dart';
import 'package:kyq_rider_app/trip/trip_page.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

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
  offerExpiresAt: DateTime.now().add(const Duration(seconds: 25)),
  cancelReason: cancelReason,
);

Widget _fakeMap(TripMapMarkers markers, ValueChanged<GeoPoint>? onTap) => const ColoredBox(color: Colors.blueGrey);

void main() {
  late MockApi api;

  setUp(() {
    api = MockApi();
    when(() => api.currentSession()).thenAnswer((_) async => null);
  });

  Future<void> pump(WidgetTester tester, Trip trip) async {
    when(() => api.getTrip('t1')).thenAnswer((_) async => trip);
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
  }

  testWidgets('REQUESTED espera al conductor con cuenta atrás', (tester) async {
    await pump(tester, _trip(TripStatus.requested));
    expect(find.text('Esperando a Carlos…'), findsOneWidget);
    expect(find.byKey(const Key('trip.offerCountdown')), findsOneWidget);
    expect(find.text('Cancelar solicitud'), findsOneWidget);
  });

  testWidgets('FARE_PENDING pide confirmar la tarifa del conductor', (tester) async {
    final proposal = FareProposal(
      id: 'pr1',
      proposedBy: ProposalParty.driver,
      amountMinor: 1800000,
      status: ProposalStatus.open,
      expiresAt: DateTime.now().add(const Duration(seconds: 30)),
    );
    when(
      () => api.decideProposal('t1', 'pr1', accept: true),
    ).thenAnswer((_) async => _trip(TripStatus.accepted, agreed: 1800000));
    await pump(tester, _trip(TripStatus.farePending, proposal: proposal));

    expect(find.text('Tu conductor propone \$ 18.000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('trip.fareAccept')));
    await tester.pump();

    verify(() => api.decideProposal('t1', 'pr1', accept: true)).called(1);
    expect(find.text('Tu conductor va en camino'), findsOneWidget);
  });

  testWidgets('NEGOTIATION_PENDING ofrece negociar o mantener la sugerida', (tester) async {
    await pump(tester, _trip(TripStatus.negotiationPending));
    expect(find.text('Tu conductor quiere negociar la tarifa'), findsOneWidget);
    expect(find.text('Aceptar negociar'), findsOneWidget);
    expect(find.text('Mantener tarifa sugerida'), findsOneWidget);
  });

  testWidgets('cancelar tras ACCEPTED pide confirmación', (tester) async {
    when(() => api.cancelTrip('t1')).thenAnswer((_) async => _trip(TripStatus.cancelled, cancelReason: 'passenger'));
    await pump(tester, _trip(TripStatus.accepted, agreed: 1470000));

    await tester.tap(find.byKey(const Key('trip.cancel')));
    await tester.pumpAndSettle();
    expect(find.text('¿Cancelar el viaje?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Cancelar viaje'));
    await tester.pumpAndSettle();

    verify(() => api.cancelTrip('t1')).called(1);
    expect(find.text('Cancelaste el viaje.'), findsOneWidget);
  });

  testWidgets('IN_PROGRESS ya no permite cancelar', (tester) async {
    await pump(tester, _trip(TripStatus.inProgress, agreed: 1470000));
    expect(find.text('En viaje'), findsOneWidget);
    expect(find.byKey(const Key('trip.cancel')), findsNothing);
  });

  testWidgets('COMPLETED muestra la tarifa acordada, 100 % para el conductor y pago fuera de la app', (tester) async {
    await pump(tester, _trip(TripStatus.completed, agreed: 1600000));
    expect(find.text('\$ 16.000'), findsOneWidget);
    expect(find.textContaining('El 100 % es para tu conductor'), findsOneWidget);
    expect(find.textContaining('en efectivo o por transferencia'), findsOneWidget);
  });

  testWidgets('CANCELLED por vencimiento explica el motivo', (tester) async {
    await pump(tester, _trip(TripStatus.cancelled, cancelReason: 'offer_expired'));
    expect(find.text('Carlos no respondió a tiempo.'), findsOneWidget);
    expect(find.text('Volver a mis conductores'), findsOneWidget);
  });

  group('walkie-talkie', () {
    Future<FakePtt> pumpWithPtt(WidgetTester tester, Trip trip, FakeRealtime realtime) async {
      when(() => api.getTrip('t1')).thenAnswer((_) async => trip);
      late FakePtt ptt;
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => TripCubit(api: api, tripId: 't1', realtime: realtime)..start(),
              ),
              BlocProvider(
                create: (context) => (ptt = FakePtt(closeSignals: context.read<TripCubit>().pttClosed)).controller,
              ),
            ],
            child: Builder(
              builder: (context) => TripPage(driverName: 'Carlos', map: _fakeMap, ptt: context.read<PttController>()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      return ptt;
    }

    testWidgets('ACCEPTED muestra el botón y quién habla', (tester) async {
      final realtime = FakeRealtime();
      final ptt = await pumpWithPtt(tester, _trip(TripStatus.accepted, agreed: 1470000), realtime);
      expect(find.byType(PttButton), findsOneWidget);
      expect(ptt.room.connects, 1);

      ptt.room.emit(const VoiceDataReceived({'type': 'floor.taken', 'user_id': 'd1'}));
      await tester.pump();
      expect(find.text('Habla Carlos'), findsOneWidget);
      expect(ptt.focus.ducked, isTrue);
      ptt.room.emit(const VoiceDataReceived({'type': 'floor.released'}));
      await tester.pump();
    });

    testWidgets('antes de ACCEPTED no hay botón', (tester) async {
      final ptt = await pumpWithPtt(tester, _trip(TripStatus.requested), FakeRealtime());
      expect(find.byType(PttButton), findsNothing);
      expect(ptt.api.tokenCalls, 0);
    });

    testWidgets('en el resumen sigue hasta que llega ptt.closed', (tester) async {
      final realtime = FakeRealtime();
      await pumpWithPtt(tester, _trip(TripStatus.completed, agreed: 1470000), realtime);
      expect(find.text('Viaje completado'), findsOneWidget);
      expect(find.byType(PttButton), findsOneWidget);

      realtime.emit(Channels.user('p1'), PttClosed(DateTime.utc(2026, 10, 27), tripId: 't1'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(PttButton), findsNothing);
    });
  });
}
