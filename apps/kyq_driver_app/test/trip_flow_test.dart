import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/app/app.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

import 'support/fakes.dart';

const _session = Tokens(accessToken: 'a', refreshToken: 'r', role: UserRole.driver);

const _me = DriverMe(
  driverId: 'd1',
  qrToken: 'q3T9xZk2LmN8pR4sV7wY1a',
  presence: DriverPresence.offline,
  subscriptionStatus: SubscriptionStatus.active,
  canGoOnline: true,
);

class _Harness {
  final api = MockApi();
  final events = FakeEventSource();
  final permissions = FakePermissions();
  final service = FakeOnlineService();
  final ptts = <FakePtt>[];

  Future<void> pump(WidgetTester tester) async {
    when(() => api.currentSession()).thenAnswer((_) async => _session);
    stubOnboardingDefaults(api);
    when(() => api.driverMe()).thenAnswer((_) async => _me);
    final auth = AuthCubit(api, allowedRoles: {UserRole.driver}, wrongRoleMessage: '')..start();
    await tester.pumpWidget(
      KyqDriverApp(
        api: api,
        auth: auth,
        services: fakeServices(events: events, permissions: permissions, service: service, ptt: fakePttFactory(ptts)),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('se suscribe al canal del conductor al iniciar sesión', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    expect(h.events.subscribedUsers, ['d1']);
  });

  testWidgets('ONLINE arranca el servicio en primer plano', (tester) async {
    final h = _Harness();
    when(() => h.api.setOnline(true)).thenAnswer((_) async => DriverPresence.free);
    when(() => h.api.setOnline(false)).thenAnswer((_) async => DriverPresence.offline);
    await h.pump(tester);
    expect(find.text('OFFLINE'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home.online')));
    await tester.pumpAndSettle();
    expect(find.text('ONLINE'), findsOneWidget);
    expect(h.service.running, isTrue);

    await tester.tap(find.byKey(const Key('home.online')));
    await tester.pumpAndSettle();
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(h.service.running, isFalse);
  });

  testWidgets('pide los permisos explicando por qué antes de conectarse', (tester) async {
    final h = _Harness()..permissions.granted = false;
    when(() => h.api.setOnline(true)).thenAnswer((_) async => DriverPresence.free);
    await h.pump(tester);

    await tester.tap(find.byKey(const Key('home.online')));
    await tester.pumpAndSettle();
    expect(find.text('Antes de conectarte'), findsOneWidget);
    expect(find.textContaining('todo el tiempo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('permissions.continue')));
    await tester.pumpAndSettle();
    expect(h.permissions.requests, 1);
    expect(find.text('ONLINE'), findsOneWidget);
  });

  testWidgets('muestra el motivo si el backend bloquea el ONLINE', (tester) async {
    final h = _Harness();
    when(
      () => h.api.setOnline(true),
    ).thenThrow(const ApiException(403, 'subscription_suspended', 'suscripción suspendida'));
    await h.pump(tester);

    await tester.tap(find.byKey(const Key('home.online')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tu suscripción está suspendida'), findsOneWidget);
    expect(find.text('OFFLINE'), findsOneWidget);
  });

  testWidgets('una oferta abre la tarjeta y al aceptar pasa al viaje', (tester) async {
    final h = _Harness();
    when(() => h.api.acceptTrip('t1')).thenAnswer((_) async => trip());
    when(() => h.api.getTrip('t1')).thenAnswer((_) async => trip());
    when(() => h.api.arrive('t1')).thenAnswer((_) async => trip(status: TripStatus.arrived));
    await h.pump(tester);

    h.events.push(offerEvent(expiresAt: DateTime.now().add(const Duration(seconds: 25))));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('\$ 14.700'), findsOneWidget);
    expect(find.text('4,2 km · 12 min'), findsOneWidget);
    expect(find.byKey(const Key('offer.countdown')), findsOneWidget);

    await tester.tap(find.byKey(const Key('offer.accept')));
    await tester.pumpAndSettle();
    expect(find.text('Ve a recoger al pasajero'), findsOneWidget);
    expect(find.text('Abrir en Waze'), findsOneWidget);
    expect(find.text('Abrir en Google Maps'), findsOneWidget);

    await tester.tap(find.byKey(const Key('trip.arrive')));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar viaje'), findsOneWidget);
  });

  testWidgets('trip.offer_closed vuelve al inicio con el aviso', (tester) async {
    final h = _Harness();
    await h.pump(tester);

    h.events.push(offerEvent(expiresAt: DateTime.now().add(const Duration(seconds: 25))));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo viaje'), findsOneWidget);

    h.events.push(TripOfferClosed(tripNow, tripId: 't1', reason: 'passenger'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo viaje'), findsNothing);
    expect(find.text('El pasajero canceló la solicitud.'), findsOneWidget);
  });

  testWidgets('proponer negociar espera al pasajero y luego muestra el panel', (tester) async {
    final h = _Harness();
    final pending = trip(status: TripStatus.negotiationPending, agreedFareMinor: null);
    final negotiating = trip(
      status: TripStatus.negotiating,
      agreedFareMinor: null,
      negotiationExpiresAt: DateTime.now().add(const Duration(minutes: 3)),
      openProposal: FareProposal(
        id: 'pr1',
        proposedBy: ProposalParty.passenger,
        amountMinor: 1600000,
        status: ProposalStatus.open,
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
      ),
    );
    var current = pending;
    when(() => h.api.requestNegotiation('t1')).thenAnswer((_) async => pending);
    when(() => h.api.getTrip('t1')).thenAnswer((_) async => current);
    when(() => h.api.decideProposal('t1', 'pr1', accept: true)).thenAnswer((_) async => trip(agreedFareMinor: 1600000));
    await h.pump(tester);

    h.events.push(offerEvent(expiresAt: DateTime.now().add(const Duration(seconds: 25))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('offer.negotiate')));
    await tester.pumpAndSettle();
    expect(find.text('Esperando al pasajero'), findsOneWidget);

    current = negotiating;
    h.events.push(TripStatusChanged(tripNow, tripId: 't1', status: 'NEGOTIATING'));
    await tester.pumpAndSettle();
    expect(find.byType(NegotiationPanel), findsOneWidget);
    expect(find.text('Te proponen'), findsOneWidget);

    await tester.tap(find.byKey(const Key('negotiation.accept')));
    await tester.pumpAndSettle();
    expect(find.text('Ve a recoger al pasajero'), findsOneWidget);
    expect(find.text('Tarifa: \$ 16.000'), findsOneWidget);
  });

  testWidgets('al completar muestra el resumen con comisión 0', (tester) async {
    final h = _Harness();
    when(() => h.api.acceptTrip('t1')).thenAnswer((_) async => trip(status: TripStatus.inProgress));
    when(() => h.api.getTrip('t1')).thenAnswer((_) async => trip(status: TripStatus.inProgress));
    when(() => h.api.completeTrip('t1')).thenAnswer((_) async => trip(status: TripStatus.completed));
    await h.pump(tester);

    h.events.push(offerEvent(expiresAt: DateTime.now().add(const Duration(seconds: 25))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('offer.accept')));
    await tester.pumpAndSettle();
    expect(find.text('Destino'), findsOneWidget);
    expect(find.byKey(const Key('trip.cancel')), findsNothing);

    await tester.tap(find.byKey(const Key('trip.complete')));
    await tester.pumpAndSettle();
    expect(find.text('Recibes el 100 %: \$ 14.700'), findsOneWidget);
    expect(find.text('Comisión Kyq: \$ 0'), findsOneWidget);
  });

  testWidgets('el walkie-talkie aparece al aceptar, sigue en el resumen y se oculta con ptt.closed', (tester) async {
    final h = _Harness();
    when(() => h.api.acceptTrip('t1')).thenAnswer((_) async => trip(status: TripStatus.inProgress));
    when(() => h.api.getTrip('t1')).thenAnswer((_) async => trip(status: TripStatus.inProgress));
    when(() => h.api.completeTrip('t1')).thenAnswer((_) async => trip(status: TripStatus.completed));
    await h.pump(tester);

    h.events.push(offerEvent(expiresAt: DateTime.now().add(const Duration(seconds: 25))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('offer.accept')));
    await tester.pumpAndSettle();
    expect(find.byType(PttButton), findsOneWidget);
    expect(find.text('Mantén pulsado para hablar'), findsOneWidget);
    final ptt = h.ptts.single;
    expect(ptt.room.connects, 1);

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('ptt.button'))));
    await tester.pump();
    expect(ptt.room.micEnabled, isTrue);
    await gesture.up();
    await tester.pump();
    expect(ptt.api.floorReleases, 1);

    await tester.tap(find.byKey(const Key('trip.complete')));
    await tester.pumpAndSettle();
    expect(find.text('Viaje terminado'), findsOneWidget);
    expect(find.byType(PttButton), findsOneWidget);

    h.events.push(PttClosed(tripNow, tripId: 'otro'));
    await tester.pumpAndSettle();
    expect(find.byType(PttButton), findsOneWidget);
    h.events.push(PttClosed(tripNow, tripId: 't1'));
    await tester.pumpAndSettle();
    expect(find.byType(PttButton), findsNothing);
  });

  testWidgets('cancelar antes de iniciar pide confirmación', (tester) async {
    final h = _Harness();
    when(() => h.api.acceptTrip('t1')).thenAnswer((_) async => trip());
    when(() => h.api.getTrip('t1')).thenAnswer((_) async => trip());
    when(
      () => h.api.cancelTrip('t1'),
    ).thenAnswer((_) async => trip(status: TripStatus.cancelled, cancelReason: 'driver'));
    await h.pump(tester);

    h.events.push(offerEvent(expiresAt: DateTime.now().add(const Duration(seconds: 25))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('offer.accept')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('trip.cancel')));
    await tester.pumpAndSettle();
    expect(find.text('¿Cancelar el viaje?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('trip.cancel.confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Cancelaste el viaje.'), findsOneWidget);
  });
}
