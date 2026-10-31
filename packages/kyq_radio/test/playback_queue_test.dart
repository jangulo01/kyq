import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_radio/src/controller/playback_queue.dart';

/// Efectos falsos: anotan todo y [playRecorded] termina cuando la prueba lo dice.
class FakeEffects implements QueueEffects {
  final calls = <String>[];
  final heardIds = <String>[];
  final _playing = <String, Completer<void>>{};

  void finish(String messageId) => _playing.remove(messageId)?.complete();

  @override
  Future<void> setLive(String conversationId, bool on) async => calls.add('live $conversationId $on');

  @override
  Future<void> duck() async => calls.add('duck');

  @override
  Future<void> releaseFocus() async => calls.add('release');

  @override
  Future<void> playRecorded(String messageId) {
    calls.add('play $messageId');
    return (_playing[messageId] = Completer<void>()).future;
  }

  @override
  Future<void> stopRecorded() async {
    calls.add('stop');
    for (final c in _playing.values) {
      c.complete();
    }
    _playing.clear();
  }

  @override
  void heard(String messageId) => heardIds.add(messageId);

  @override
  void changed() {}
}

void main() {
  late FakeEffects fx;
  late PlaybackQueue q;
  var now = DateTime(2026, 10, 28, 12);

  setUp(() {
    fx = FakeEffects();
    now = DateTime(2026, 10, 28, 12);
    q = PlaybackQueue(fx, now: () => now);
  });

  test('SC-006: tres fuentes a la vez suenan una tras otra, sin mezclarse y en orden', () async {
    await q.floorTaken('norte', 'u1', name: 'Pedro', messageId: 'm1');
    await q.floorTaken('coop', 'u2', name: 'Luz', messageId: 'm2');
    await q.floorTaken('jonathan', 'u3', name: 'Jonathan', messageId: 'm3');
    expect(q.live?.conversationId, 'norte');
    expect(fx.calls, ['live norte true', 'duck', 'live coop false', 'live jonathan false']);
    expect(q.waiting, 2);

    // El tercero termina y su archivo queda listo antes que el segundo: igual espera su turno.
    await q.floorReleased('jonathan', userId: 'u3');
    await q.messageReady('m3');
    expect(fx.calls.where((c) => c.startsWith('play')), isEmpty, reason: 'Pedro sigue en vivo');

    await q.floorReleased('norte', userId: 'u1');
    expect(fx.heardIds, ['m1']);
    expect(fx.calls.where((c) => c.startsWith('play')), isEmpty, reason: 'm2 aún no está listo');

    await q.floorReleased('coop', userId: 'u2');
    unawaited(q.messageReady('m2'));
    await Future<void>.delayed(Duration.zero);
    expect(q.playing?.messageId, 'm2');
    fx.finish('m2');
    await Future<void>.delayed(Duration.zero);
    expect(q.playing?.messageId, 'm3');
    fx.finish('m3');
    await Future<void>.delayed(Duration.zero);
    expect(q.playing, isNull);
    expect(q.waiting, 0);
    expect(fx.heardIds, ['m1', 'm2', 'm3']);
    expect(fx.calls.where((c) => c.startsWith('play')), ['play m2', 'play m3']);
  });

  test('una pulsación que nunca da archivo se descarta y no bloquea la cola', () async {
    await q.floorTaken('norte', 'u1', messageId: 'm1');
    await q.floorTaken('coop', 'u2', messageId: 'm2');
    await q.floorTaken('coop', 'u3', messageId: 'm3');
    await q.floorReleased('coop', userId: 'u2');
    await q.floorReleased('coop', userId: 'u3');
    await q.messageReady('m3');
    await q.floorReleased('norte', userId: 'u1');
    expect(q.playing, isNull, reason: 'm2 encabeza y aún puede llegar');
    now = now.add(const Duration(seconds: 16));
    unawaited(q.tick());
    await Future<void>.delayed(Duration.zero);
    expect(q.playing?.messageId, 'm3');
  });

  test('hablar pausa la cola y lo pendiente queda como nuevo (US7-5)', () async {
    await q.floorTaken('norte', 'u1', messageId: 'm1');
    await q.floorTaken('coop', 'u2', messageId: 'm2');
    await q.setTalking(true);
    expect(q.live, isNull);
    expect(q.waiting, 0);
    expect(fx.calls.last, 'live norte false');
    expect(fx.heardIds, isEmpty, reason: 'nada se marca oído');
    await q.setTalking(false);
    await q.floorTaken('coop', 'u2', messageId: 'm4');
    expect(q.live?.conversationId, 'coop');
  });

  test('el viaje y el SOS suenan primero; la radio espera y luego sigue (US7-4)', () async {
    await q.floorTaken('norte', 'u1', messageId: 'm1');
    await q.setPriority(true);
    expect(q.live, isNull);
    expect(q.waiting, 1, reason: 'el vivo interrumpido pasa a la cola');
    await q.floorTaken('coop', 'u2', messageId: 'm2');
    expect(q.live, isNull);
    await q.floorReleased('norte', userId: 'u1');
    await q.messageReady('m1');
    expect(fx.calls.where((c) => c.startsWith('play')), isEmpty);
    unawaited(q.setPriority(false));
    await Future<void>.delayed(Duration.zero);
    expect(q.playing?.messageId, 'm1');
  });
}
