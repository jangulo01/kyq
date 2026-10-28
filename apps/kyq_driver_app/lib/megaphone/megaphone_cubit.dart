import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

@immutable
class MegaphoneState {
  const MegaphoneState({this.playing = false, this.waiting = 0, this.lastAt});

  /// Suena un comunicado de Kyq.
  final bool playing;

  /// Comunicados en cola (esperando el turno del viaje u otro comunicado).
  final int waiting;

  /// Hora del último comunicado oído, para el aviso al volver a la app.
  final DateTime? lastAt;
}

/// Comunicados de Kyq por zona (009, US3): uno a la vez, solo escucha, y esperando a que
/// termine la voz del viaje (FR-015). Sin grabación: se oyen en vivo o no se oyen.
class MegaphoneCubit extends Cubit<MegaphoneState> {
  MegaphoneCubit(Stream<RealtimeEvent> events, {required this._room, PttActivity? activity, DateTime Function()? now})
    : _activity = activity ?? PttActivity.instance,
      _now = now ?? DateTime.now,
      super(const MegaphoneState()) {
    _sub = events.listen(_onEvent, onError: (Object _) {});
    _activity.addListener(_pump);
  }

  final VoiceRoom Function() _room;
  final PttActivity _activity;
  final DateTime Function() _now;
  late final StreamSubscription<RealtimeEvent> _sub;
  final _queue = Queue<MegaphoneStarted>();
  MegaphoneStarted? _current;
  VoiceRoom? _voice;
  Timer? _cut;

  void _onEvent(RealtimeEvent e) {
    switch (e) {
      case MegaphoneStarted():
        if (!e.endsAt.isAfter(_now())) return;
        _queue.add(e);
        _emit();
        _pump();
      case MegaphoneEnded(:final broadcastId):
        _queue.removeWhere((b) => b.broadcastId == broadcastId);
        if (_current?.broadcastId == broadcastId) {
          unawaited(_stop());
        } else {
          _emit();
        }
      default:
        break;
    }
  }

  void _pump() {
    if (isClosed || _current != null || _activity.busy) return;
    while (_queue.isNotEmpty) {
      final next = _queue.removeFirst();
      if (next.endsAt.isAfter(_now())) {
        unawaited(_play(next));
        return;
      }
    }
    _emit();
  }

  Future<void> _play(MegaphoneStarted b) async {
    _current = b;
    _emit();
    final voice = _room();
    _voice = voice;
    _cut = Timer(b.endsAt.difference(_now()) + const Duration(seconds: 2), () => unawaited(_stop()));
    try {
      await voice.connect(b.url, b.token);
    } on Object catch (e) {
      debugPrint('Megáfono: $e');
      await _stop();
    }
  }

  Future<void> _stop() async {
    final voice = _voice;
    final played = _current != null;
    _cut?.cancel();
    _cut = null;
    _voice = null;
    _current = null;
    if (voice != null) {
      try {
        await voice.disconnect();
      } on Object {
        // La sala ya se cerró en el servidor.
      }
    }
    if (isClosed) return;
    if (played) emit(MegaphoneState(waiting: _queue.length, lastAt: _now()));
    _pump();
  }

  void _emit() {
    if (isClosed) return;
    emit(MegaphoneState(playing: _current != null, waiting: _queue.length, lastAt: state.lastAt));
  }

  /// El conductor vio el aviso.
  void dismiss() => emit(MegaphoneState(playing: state.playing, waiting: state.waiting));

  @override
  Future<void> close() async {
    _activity.removeListener(_pump);
    await _sub.cancel();
    _queue.clear();
    _cut?.cancel();
    await _voice?.disconnect();
    return super.close();
  }
}
