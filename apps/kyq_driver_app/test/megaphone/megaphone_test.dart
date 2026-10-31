import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_driver_app/megaphone/megaphone_banner.dart';
import 'package:kyq_driver_app/megaphone/megaphone_cubit.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

// 009 (US3): comunicados de Kyq de uno en uno, solo escucha, esperando la voz del viaje.

class _Room implements VoiceRoom {
  _Room(this.log);

  final List<String> log;

  @override
  Stream<VoiceRoomEvent> get events => const Stream.empty();

  @override
  String? get localIdentity => 'd1';

  @override
  Future<void> connect(String url, String token) async => log.add('connect $token');

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async => log.add('mic $enabled');

  @override
  Future<void> sendData(Map<String, Object?> message) async {}

  @override
  Future<void> disconnect() async => log.add('disconnect');
}

void main() {
  final now = DateTime.utc(2026, 10, 28, 12);
  MegaphoneStarted started(String id) => MegaphoneStarted(
    now,
    broadcastId: id,
    url: 'wss://lk',
    token: 'tk-$id',
    endsAt: now.add(const Duration(seconds: 60)),
  );

  late StreamController<RealtimeEvent> events;
  late PttActivity activity;
  late List<String> log;
  late MegaphoneCubit cubit;

  setUp(() {
    events = StreamController<RealtimeEvent>.broadcast();
    activity = PttActivity();
    log = [];
    cubit = MegaphoneCubit(events.stream, room: () => _Room(log), activity: activity, now: () => now);
  });

  tearDown(() async {
    await cubit.close();
    await events.close();
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('suena, termina con megaphone.ended y pasa al siguiente', () async {
    events
      ..add(started('b1'))
      ..add(started('b2'));
    await flush();
    expect(log, ['connect tk-b1'], reason: 'uno a la vez, nunca superpuestos');
    expect(cubit.state.playing, isTrue);
    expect(cubit.state.waiting, 1);
    expect(log.where((l) => l.startsWith('mic')), isEmpty, reason: 'FR-015: no puede hablar');

    events.add(MegaphoneEnded(now, broadcastId: 'b1'));
    await flush();
    await flush();
    expect(log, ['connect tk-b1', 'disconnect', 'connect tk-b2']);
    events.add(MegaphoneEnded(now, broadcastId: 'b2'));
    await flush();
    await flush();
    expect(cubit.state.playing, isFalse);
    expect(cubit.state.lastAt, now, reason: 'aviso al volver a la app');
  });

  test('espera a que termine el turno del viaje', () async {
    final trip = Object();
    activity.report(trip, busy: true);
    events.add(started('b1'));
    await flush();
    expect(log, isEmpty);
    expect(cubit.state.waiting, 1);
    activity.report(trip, busy: false);
    await flush();
    expect(log, ['connect tk-b1']);
  });

  test('uno vencido o terminado en cola no suena', () async {
    events.add(
      MegaphoneStarted(
        now,
        broadcastId: 'old',
        url: 'wss://lk',
        token: 'tk',
        endsAt: now.subtract(const Duration(seconds: 1)),
      ),
    );
    activity.report(log, busy: true);
    events
      ..add(started('b1'))
      ..add(MegaphoneEnded(now, broadcastId: 'b1'));
    await flush();
    activity.report(log, busy: false);
    await flush();
    expect(log, isEmpty);
  });

  testWidgets('aviso "Comunicado de Kyq" mientras suena', (tester) async {
    // Creado dentro de la prueba para que sus eventos corran en el reloj falso.
    final events = StreamController<RealtimeEvent>.broadcast();
    final cubit = MegaphoneCubit(events.stream, room: () => _Room([]), activity: PttActivity(), now: () => now);
    addTearDown(() async {
      await cubit.close();
      await events.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const MegaphoneBanner(child: Scaffold(body: Text('Inicio'))),
        ),
      ),
    );
    events.add(started('b1'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Comunicado de Kyq en curso'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);

    events.add(MegaphoneEnded(now, broadcastId: 'b1'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Comunicado de Kyq a las'), findsOneWidget);
    await tester.tap(find.byKey(const Key('megaphone.dismiss')));
    await tester.pump();
    expect(find.byKey(const Key('megaphone.banner')), findsNothing);
  });
}
