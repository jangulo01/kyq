import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:kyq_radio/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

class _Harness {
  _Harness(this.api);

  final FakeRadioApi api;
  final events = StreamController<RealtimeEvent>.broadcast();
  final player = FakeMessagePlayer();
  final tones = FakeTonePlayer();
  late RadioCubit cubit;

  Future<void> pump(WidgetTester tester, {String initial = '/radio'}) async {
    cubit = RadioCubit(
      api: api,
      myUserId: 'me',
      events: events.stream,
      rooms: () => FakeListeningRoom(identity: 'me'),
      tones: tones,
      focus: FakeAudioFocus(),
      player: FakeMessagePlayer(),
    );
    addTearDown(events.close);
    addTearDown(cubit.close);
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox(), routes: [radioRoute()]),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepositoryProvider(
        create: (_) => RadioDeps(api: api, myUserId: 'me', events: events.stream, newPlayer: () => player),
        child: BlocProvider.value(
          value: cubit..load(),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Cierra el cubit dentro de la prueba: sus temporizadores (latido) no deben quedar vivos.
  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    cubit.cancelTimers();
  }
}

void main() {
  testWidgets('lista única con estado, nuevos y "Escuchar" (FR-001)', (tester) async {
    final h = _Harness(FakeRadioApi(conversations: [fakeContact('c1', unread: 3), fakeChannel('c2')]));
    await h.pump(tester);
    expect(find.text('Jonathan'), findsOneWidget);
    expect(find.text('Disponible'), findsWidgets);
    expect(find.text('Taxistas Norte'), findsOneWidget);
    expect(find.text('3 conectados'), findsOneWidget);
    expect(find.byKey(const Key('radio.unread.c1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.listen.c2')));
    await tester.pumpAndSettle();
    expect(h.api.calls, contains('listening c2 false'));
    await h.done(tester);
  });

  testWidgets('aviso de registro antes del primer uso (FR-013)', (tester) async {
    final h = _Harness(FakeRadioApi(me: fakeMe(consentRequired: true), conversations: [fakeContact('c1')]));
    await h.pump(tester);
    expect(find.textContaining('durante 30 días'), findsOneWidget);
    expect(find.textContaining('nunca se graban'), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.consent.accept')));
    await tester.pumpAndSettle();
    expect(h.api.calls, contains('consent'));
    await h.done(tester);
  });

  testWidgets('sin acceso explica qué falta; en prueba muestra los días (FR-005)', (tester) async {
    final h = _Harness(
      FakeRadioApi(
        me: fakeMe(access: RadioAccess.none).copyWith(accessReason: 'trial_ended'),
      ),
    );
    await h.pump(tester);
    expect(find.textContaining('Terminó tu prueba'), findsOneWidget);
    expect(find.byKey(const Key('radio.add')), findsNothing);

    final h2 = _Harness(FakeRadioApi(me: fakeMe().copyWith(trialDaysLeft: 9), conversations: [fakeContact('c1')]));
    await h2.pump(tester);
    expect(find.text('Prueba de Radio: te quedan 9 días'), findsOneWidget);
    await h2.done(tester);
    await h.done(tester);
  });

  testWidgets('conversación: botón grande, nuevos en cola, repetir y velocidad (US2)', (tester) async {
    final api = FakeRadioApi(conversations: [fakeContact('c1')]);
    api.messages['c1'] = [
      fakeVoice('m3', 'c1', minute: 3),
      fakeVoice('m2', 'c1', minute: 2),
      fakeVoice('m1', 'c1', minute: 1, heard: true),
    ];
    final h = _Harness(api);
    await h.pump(tester, initial: '/radio/c/c1');
    expect(find.byKey(const Key('radio.conversation.title')), findsOneWidget);
    expect(find.text('Mantén pulsado para hablar'), findsOneWidget);
    expect(find.byKey(const Key('radio.message.new.m3')), findsOneWidget);
    expect(find.byKey(const Key('radio.message.new.m1')), findsNothing);

    await tester.tap(find.byKey(const Key('radio.playNew')));
    await tester.pumpAndSettle();
    expect(h.player.played, [
      'https://objects.test/m2.ogg',
      'https://objects.test/m3.ogg',
    ], reason: 'en orden de llegada');
    expect(api.calls, containsAll(['receipt m2 heard', 'receipt m3 heard']));
    expect(find.byKey(const Key('radio.playNew')), findsNothing);

    await tester.tap(find.byKey(const Key('radio.speed')));
    await tester.pumpAndSettle();
    expect(find.text('1,5x'), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.repeat')));
    await tester.pumpAndSettle();
    expect(h.player.played.last, 'https://objects.test/m3.ogg');
    expect(h.player.speeds.last, 1.5, reason: 'sin cambiar el tono: lo hace el reproductor (R4)');
    await h.done(tester);
  });

  testWidgets('enviar texto y ver el turno ocupado (US1-4, US6-1)', (tester) async {
    final api = FakeRadioApi(conversations: [fakeContact('c1')])
      ..floorError = const ApiException(409, 'floor_busy', 'Jonathan está hablando');
    final h = _Harness(api);
    await h.pump(tester, initial: '/radio/c/c1');
    await tester.enterText(find.byKey(const Key('radio.text')), 'voy tarde 10 min');
    await tester.tap(find.byKey(const Key('radio.send')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('send text voy tarde 10 min'));
    expect(find.text('voy tarde 10 min'), findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('radio.talk'))));
    await tester.pumpAndSettle();
    expect(find.text('Jonathan está hablando'), findsOneWidget);
    expect(h.tones.played.last.name, 'busy');
    await gesture.up();
    await tester.pumpAndSettle();
    await h.done(tester);
  });

  testWidgets('solo escucha: el botón no transmite y no hay caja de texto (US4-4)', (tester) async {
    final h = _Harness(FakeRadioApi(conversations: [fakeChannel('c2', role: RadioRole.listener)]));
    await h.pump(tester, initial: '/radio/c/c2');
    expect(find.text('Aquí solo puedes escuchar'), findsOneWidget);
    expect(find.byKey(const Key('radio.text')), findsNothing);
    await h.done(tester);
  });

  testWidgets('invitación por enlace: quién invita y aceptar (FR-032)', (tester) async {
    final api = FakeRadioApi(conversations: [fakeContact('c1', title: 'Carlos')]);
    final h = _Harness(api);
    await h.pump(tester, initial: '/radio/invite/ABCDEFGHIJ');
    expect(find.text('Carlos quiere agregarte a su Radio'), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.invite.accept')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('accept ABCDEFGHIJ'));
    expect(find.byKey(const Key('radio.conversation.title')), findsOneWidget);
    await h.done(tester);
  });

  test('códigos de invitación desde enlaces y QR', () {
    expect(radioInviteCode('https://kyq.test/r/ABCDEFGHIJ'), 'ABCDEFGHIJ');
    expect(radioInviteCode('kyq://radio/ABCDEFGHIJ'), 'ABCDEFGHIJ');
    expect(radioInviteCode(' ABCDEFGHIJ '), 'ABCDEFGHIJ');
    expect(radioInviteCode('https://otra.app/x/ABCDEFGHIJ'), isNull);
    expect(radioDeepLinkRedirect(Uri.parse('kyq://radio/ABCDEFGHIJ')), '/radio/invite/ABCDEFGHIJ');
    expect(radioDeepLinkRedirect(Uri.parse('https://kyq.test/r/ABCDEFGHIJ')), '/radio/invite/ABCDEFGHIJ');
  });
}
