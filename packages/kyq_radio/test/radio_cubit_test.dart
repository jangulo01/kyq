import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:kyq_radio/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRadioApi api;
  late StreamController<RealtimeEvent> events;
  late Map<String, FakeListeningRoom> rooms;
  late List<FakeListeningRoom> created;
  late FakeTonePlayer tones;
  late FakeAudioFocus focus;
  late FakeMessagePlayer player;

  setUp(() {
    api = FakeRadioApi(
      conversations: [
        fakeContact('c1'),
        fakeChannel('c2'),
        fakeContact('c3', title: 'Pedro', listening: false),
      ],
    );
    events = StreamController<RealtimeEvent>.broadcast();
    created = [];
    rooms = {};
    tones = FakeTonePlayer();
    focus = FakeAudioFocus();
    player = FakeMessagePlayer(instant: false);
  });

  tearDown(() => events.close());

  Future<RadioCubit> build() async {
    final cubit = RadioCubit(
      api: api,
      myUserId: 'me',
      events: events.stream,
      rooms: () {
        final r = FakeListeningRoom(identity: 'me');
        created.add(r);
        return r;
      },
      tones: tones,
      focus: focus,
      player: player,
    );
    await cubit.load();
    for (final call in api.calls.where((c) => c.startsWith('token '))) {
      rooms[call.substring(6)] = created[rooms.length];
    }
    return cubit;
  }

  test('conecta solo para escuchar las conversaciones con "Escuchar" (FR-024, R2)', () async {
    final cubit = await build();
    expect(rooms.keys, ['c1', 'c2']);
    expect(rooms['c1']!.connected, isTrue);
    expect(rooms['c1']!.remoteAudioEnabled, isFalse, reason: 'nada suena hasta que alguien habla');
    await cubit.setListening('c1', false);
    expect(rooms['c1']!.connected, isFalse);
    await cubit.close();
  });

  test('hablar: turno, tonos, micrófono y aviso en la sala; soltar lo deshace (FR-006)', () async {
    final cubit = await build();
    cubit.select('c1');
    await cubit.press();
    expect(cubit.state.talk, TalkStatus.talking);
    expect(tones.played, [PttTone.start]);
    expect(rooms['c1']!.micEnabled, isTrue);
    expect(rooms['c1']!.sent.last['type'], 'floor.taken');
    await cubit.release();
    expect(cubit.state.talk, TalkStatus.idle);
    expect(rooms['c1']!.micEnabled, isFalse);
    expect(rooms['c1']!.sent.last['type'], 'floor.released');
    expect(api.calls, contains('release c1'));
    expect(tones.played, [PttTone.start, PttTone.end]);
    await cubit.close();
  });

  test('turno ocupado: tono de ocupado y quién habla (US1-4)', () async {
    api.floorError = const ApiException(409, 'floor_busy', 'Jonathan está hablando');
    final cubit = await build();
    await cubit.press('c1');
    expect(cubit.state.talk, TalkStatus.busy);
    expect(cubit.state.busyHolder, 'Jonathan');
    expect(tones.played, [PttTone.busy]);
    expect(rooms['c1']!.micEnabled, isFalse);
    await cubit.close();
  });

  test('dos voces a la vez: una en vivo y la otra desde el registro al terminar (FR-025)', () async {
    final cubit = await build();
    rooms['c1']!.emit(
      const VoiceDataReceived({'type': 'floor.taken', 'user_id': 'u1', 'message_id': 'm1'}, senderName: 'Jonathan'),
    );
    await Future<void>.delayed(Duration.zero);
    rooms['c2']!.emit(
      const VoiceDataReceived({'type': 'floor.taken', 'user_id': 'u2', 'message_id': 'm2'}, senderName: 'Luz'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.live?.conversationId, 'c1');
    expect(cubit.state.holders, {'c1': 'Jonathan', 'c2': 'Luz'});
    expect(rooms['c1']!.remoteAudioEnabled, isTrue);
    expect(rooms['c2']!.remoteAudioEnabled, isFalse);
    expect(focus.ducked, isTrue, reason: 'la navegación baja (RN-KYQ-011)');

    rooms['c2']!.emit(const VoiceDataReceived({'type': 'floor.released', 'user_id': 'u2'}));
    events.add(
      RadioMessageEvent(
        DateTime(2026),
        kind: RadioEventKind.message,
        message: {
          'id': 'm2',
          'conversation_id': 'c2',
          'kind': 'voice',
          'created_at': '2026-10-28T12:00:00Z',
          'has_media': true,
        },
        silent: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(player.played, isEmpty, reason: 'Jonathan sigue hablando');
    rooms['c1']!.emit(const VoiceDataReceived({'type': 'floor.released', 'user_id': 'u1'}));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(player.played, ['https://objects.test/m2.ogg']);
    player.finish();
    await Future<void>.delayed(Duration.zero);
    expect(api.calls, containsAll(['receipt m1 heard', 'receipt m2 heard']));
    await cubit.close();
  });

  test('en Ocupado la voz no suena en vivo (FR-020)', () async {
    api.me = fakeMe(status: RadioPresence.busy);
    final cubit = await build();
    rooms['c1']!.emit(const VoiceDataReceived({'type': 'floor.taken', 'user_id': 'u1', 'message_id': 'm1'}));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.live, isNull);
    expect(rooms['c1']!.remoteAudioEnabled, isFalse);
    await cubit.close();
  });

  test('una alerta suena hasta abrirla; la sala rotada se reconecta (FR-022, R1)', () async {
    final cubit = await build();
    events.add(
      RadioMessageEvent(
        DateTime(2026),
        kind: RadioEventKind.alert,
        message: {
          'id': 'a1',
          'conversation_id': 'c1',
          'kind': 'alert',
          'body': 'llámame',
          'created_at': '2026-10-28T12:00:00Z',
        },
        silent: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.alert?.message.body, 'llámame');
    expect(cubit.ringer.ringing, isTrue);
    expect(tones.played, contains(PttTone.alert));
    cubit.dismissAlert();
    expect(cubit.ringer.ringing, isFalse);

    final tokens = api.calls.where((c) => c == 'token c1').length;
    events.add(RadioMemberChanged(DateTime(2026), conversationId: 'c1', userId: 'me', change: 'room_rotated'));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(api.calls.where((c) => c == 'token c1').length, tokens + 1);
    await cubit.close();
  });

  test('máximo 10 conversaciones escuchadas (FR-024)', () async {
    api.conversations = [for (var i = 0; i < 10; i++) fakeContact('l$i'), fakeContact('x', listening: false)];
    final cubit = await build();
    await cubit.setListening('x', true);
    expect(cubit.state.notice, contains('10 conversaciones'));
    expect(api.calls, isNot(contains('listening x true')));
    await cubit.close();
  });

  test('Solo escucha no transmite y el latido corre con la radio encendida', () async {
    api.me = fakeMe(status: RadioPresence.listenOnly);
    final cubit = RadioCubit(
      api: api,
      myUserId: 'me',
      events: events.stream,
      rooms: () => FakeListeningRoom(),
      tones: tones,
      focus: focus,
      player: player,
      heartbeatEvery: const Duration(milliseconds: 10),
    );
    await cubit.load();
    await cubit.press('c1');
    expect(cubit.state.talk, TalkStatus.listenOnly);
    expect(api.calls, isNot(contains('floor c1')));
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(api.calls, contains('heartbeat'));
    await cubit.close();
  });
}
