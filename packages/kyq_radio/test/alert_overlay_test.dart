import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:kyq_radio/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

RadioCubit _cubit(RadioApi api, String userId, Stream<RealtimeEvent> events) => RadioCubit(
  api: api,
  myUserId: userId,
  events: events,
  rooms: () => FakeListeningRoom(identity: userId),
  tones: FakeTonePlayer(),
  focus: FakeAudioFocus(),
  player: FakeMessagePlayer(),
);

Map<String, dynamic> _message(String kind, {String? body}) => {
  'id': 'm9',
  'conversation_id': 'c1',
  'author_id': 'peer-c1',
  'author_name': 'Jonathan',
  'kind': kind,
  'status': 'ready',
  'body': body,
  'lat': 4.61,
  'lng': -74.07,
  'created_at': '2026-10-28T12:00:00Z',
  'heard': false,
};

void main() {
  testWidgets('una emergencia recibida se ve sobre cualquier pantalla y lleva a la conversación (FR-031)', (
    tester,
  ) async {
    final events = StreamController<RealtimeEvent>.broadcast();
    addTearDown(events.close);
    final mount = RadioMount(
      api: FakeRadioApi(me: fakeMe(radioOn: false), conversations: [fakeContact('c1')]),
      events: (_) => events.stream,
      factory: _cubit,
      newPlayer: FakeMessagePlayer.new,
    );
    addTearDown(mount.dispose);
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => RadioAlertOverlay(mount: mount, open: opened.add, child: child!),
        home: const Scaffold(body: Text('Inicio')),
      ),
    );
    mount.start('me');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('radio.alert.emergency')), findsNothing);

    events.add(
      RadioMessageEvent(DateTime(2026), kind: RadioEventKind.emergency, message: _message('emergency'), silent: false),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Emergencia: Jonathan pidió ayuda'), findsOneWidget);
    expect(find.byKey(const Key('radio.alert.map')), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.alert.open')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(opened, ['/radio/c/c1']);
    expect(find.byKey(const Key('radio.alert.emergency')), findsNothing);

    events.add(
      RadioMessageEvent(
        DateTime(2026),
        kind: RadioEventKind.alert,
        message: _message('alert', body: 'Llámame'),
        silent: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Jonathan te está llamando'), findsOneWidget);
    expect(find.text('Llámame'), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.alert.dismiss')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('radio.alert.call')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    mount.cubit?.cancelTimers();
  });
}
