import 'dart:async';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ptt/testing.dart';

void main() {
  late FakePtt ptt;

  setUp(() => ptt = FakePtt());
  tearDown(() => ptt.controller.close());

  Future<void> started() async {
    await ptt.controller.start();
    expect(ptt.controller.state.status, PttStatus.idle);
  }

  test('al empezar conecta sin micrófono: publicar lo concede el turno', () async {
    await started();
    expect(ptt.room.connects, 1);
    expect(ptt.room.micEnabled, isFalse);
    expect(ptt.focus.log, ['prepare']);
  });

  test('pulsar pide el turno, activa el micrófono, avisa y suena el tono', () async {
    await started();
    await ptt.controller.press();

    expect(ptt.api.floorRequests, 1);
    expect(ptt.room.micEnabled, isTrue);
    expect(ptt.room.sent, [
      {'type': 'floor.taken', 'user_id': 'yo'},
    ]);
    expect(ptt.tones.played, [PttTone.start]);
    expect(ptt.controller.state.status, PttStatus.talking);
  });

  test('soltar silencia el micrófono y libera el turno', () async {
    await started();
    await ptt.controller.press();
    await ptt.controller.release();

    expect(ptt.room.micEnabled, isFalse);
    expect(ptt.room.sent.last, {'type': 'floor.released'});
    expect(ptt.api.floorReleases, 1);
    expect(ptt.tones.played, [PttTone.start, PttTone.end]);
    expect(ptt.controller.state.status, PttStatus.idle);
  });

  test('soltar antes de que llegue el turno no abre el micrófono', () async {
    final grant = Completer<DateTime>();
    ptt.api.onRequestFloor = () => grant.future;
    await started();

    final pressing = ptt.controller.press();
    await Future<void>.delayed(Duration.zero);
    expect(ptt.controller.state.status, PttStatus.requesting);
    await ptt.controller.release();
    grant.complete(DateTime.now().add(const Duration(seconds: 60)));
    await pressing;

    expect(ptt.room.micChanges, isEmpty);
    expect(ptt.api.floorReleases, 1);
    expect(ptt.controller.state.status, PttStatus.idle);
  });

  test('turno denegado muestra ocupado con su tono y vuelve a libre', () {
    fakeAsync((async) {
      ptt.api.onRequestFloor = () async => throw const PttFloorBusy();
      ptt.controller.start();
      async.flushMicrotasks();

      ptt.controller.press();
      async.flushMicrotasks();
      expect(ptt.controller.state.status, PttStatus.busy);
      expect(ptt.room.micChanges, isEmpty);
      expect(ptt.tones.played, [PttTone.busy]);

      async.elapse(ptt.controller.busyFor);
      expect(ptt.controller.state.status, PttStatus.idle);
    });
  });

  test('suelta el turno solo antes de que caduque en el backend', () {
    fakeAsync((async) {
      final now = DateTime.utc(2026, 10, 27, 12);
      ptt = FakePtt();
      final controller = PttController(
        api: ptt.api..onRequestFloor = () async => now.add(const Duration(seconds: 60)),
        room: ptt.room,
        focus: ptt.focus,
        tones: ptt.tones,
        mic: ptt.mic,
        clock: () => now,
      );
      controller.start();
      async.flushMicrotasks();
      controller.press();
      async.flushMicrotasks();
      expect(controller.state.status, PttStatus.talking);

      async.elapse(const Duration(seconds: 54));
      expect(controller.state.status, PttStatus.talking);
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(controller.state.status, PttStatus.idle);
      expect(ptt.api.floorReleases, 1);
      controller.close();
    });
  });

  test('voz entrante pide foco con atenuación y lo libera al terminar', () async {
    await started();

    ptt.room.emit(const VoiceDataReceived({'type': 'floor.taken', 'user_id': 'carlos'}, senderId: 'carlos'));
    expect(ptt.controller.state.status, PttStatus.remoteTalking);
    expect(ptt.controller.state.speakerId, 'carlos');
    expect(ptt.focus.ducked, isTrue);

    ptt.room.emit(const VoiceDataReceived({'type': 'floor.released'}, senderId: 'carlos'));
    expect(ptt.controller.state.status, PttStatus.idle);
    expect(ptt.controller.state.speakerId, isNull);
    expect(ptt.focus.log, ['prepare', 'duck', 'release']);
  });

  test('la actividad de voz remota también atenúa aunque se pierda el mensaje de turno', () async {
    await started();

    ptt.room.emit(const VoiceRemoteSpeaking(true));
    expect(ptt.focus.ducked, isTrue);
    ptt.room.emit(const VoiceRemoteSpeaking(false));
    expect(ptt.focus.ducked, isFalse);
  });

  test('si la otra parte sale de la sala deja de mostrarse hablando', () async {
    await started();
    ptt.room.emit(const VoiceDataReceived({'type': 'floor.taken', 'user_id': 'carlos'}));
    ptt.room.emit(const VoiceRemoteLeft());
    expect(ptt.controller.state.status, PttStatus.idle);
    expect(ptt.focus.ducked, isFalse);
  });

  test('sin permiso de micrófono lo pide y, denegado, lo indica', () async {
    ptt = FakePtt(mic: FakeMicPermission(granted: false, onRequest: MicAccess.permanentlyDenied));
    await started();

    await ptt.controller.press();
    expect(ptt.mic.requests, 1);
    expect(ptt.api.floorRequests, 0);
    expect(ptt.controller.state.status, PttStatus.micDenied);
    expect(ptt.controller.state.micBlocked, isTrue);
  });

  test('token con 410 cierra el canal sin conectar', () async {
    ptt = FakePtt(api: FakePttApi(closed: true));
    await ptt.controller.start();
    expect(ptt.controller.state.status, PttStatus.closed);
    expect(ptt.room.connects, 0);
  });

  test('ptt.closed cierra el canal y desconecta', () async {
    final signals = StreamController<Object?>();
    ptt = FakePtt(closeSignals: signals.stream);
    await started();

    signals.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(ptt.controller.state.status, PttStatus.closed);
    expect(ptt.room.connected, isFalse);
    await signals.close();
  });

  test('closes_at cierra el canal al vencer la ventana de 15 minutos', () {
    fakeAsync((async) {
      final now = DateTime.utc(2026, 10, 27, 12);
      ptt = FakePtt(
        api: FakePttApi(
          credentials: PttCredentials(url: 'u', token: 't', room: 'r', closesAt: now.add(const Duration(minutes: 15))),
        ),
      );
      final controller = PttController(
        api: ptt.api,
        room: ptt.room,
        focus: ptt.focus,
        tones: ptt.tones,
        mic: ptt.mic,
        clock: () => now,
      );
      controller.start();
      async.flushMicrotasks();
      expect(controller.state.status, PttStatus.idle);

      async.elapse(const Duration(minutes: 15));
      expect(controller.state.status, PttStatus.closed);
      controller.close();
    });
  });

  test('si la sala se cae pide un token nuevo y reconecta', () {
    fakeAsync((async) {
      ptt.controller.start();
      async.flushMicrotasks();

      ptt.room.emit(const VoiceConnectionChanged(VoiceConnection.disconnected));
      expect(ptt.controller.state.status, PttStatus.reconnecting);
      async.elapse(ptt.controller.reconnectDelay);
      expect(ptt.api.tokenCalls, 2);
      expect(ptt.room.connects, 2);
      expect(ptt.controller.state.status, PttStatus.idle);
    });
  });

  test('los tonos son WAV PCM de 16 bits', () {
    for (final tone in PttTone.values) {
      final wav = toneWav(tone);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      final header = ByteData.sublistView(wav);
      expect(header.getUint16(34, Endian.little), 16);
      expect(header.getUint32(40, Endian.little), wav.length - 44);
    }
  });
}
