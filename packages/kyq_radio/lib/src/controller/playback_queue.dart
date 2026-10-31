import 'dart:async';

/// Lo que la cola hace con el audio. [RadioCubit] lo implementa sobre las salas y el reproductor.
abstract interface class QueueEffects {
  /// Deja sonar en vivo (o silencia) la sala de una conversación.
  Future<void> setLive(String conversationId, bool on);

  /// Pide foco con atenuación: la navegación baja mientras suena la radio (RN-KYQ-011).
  Future<void> duck();

  /// Devuelve el foco.
  Future<void> releaseFocus();

  /// Reproduce un mensaje del registro y termina cuando acaba.
  Future<void> playRecorded(String messageId);

  Future<void> stopRecorded();

  /// El mensaje se oyó entero.
  void heard(String messageId);

  /// Algo cambió en la cola (quién suena, cuántos esperan).
  void changed();
}

/// Quien suena en vivo ahora.
typedef LiveSpeaker = ({String conversationId, String userId, String? name, String? messageId});

/// Un mensaje que llegó mientras sonaba otro: se reproduce del registro cuando le toca.
class Queued {
  Queued({required this.conversationId, required this.messageId, required this.userId, this.name, required this.at});

  final String conversationId;
  final String messageId;
  final String userId;
  final String? name;
  final DateTime at;

  /// Su archivo ya está listo en el registro (`radio.message`).
  bool ready = false;

  /// El emisor soltó el turno: si el archivo no llega en [PlaybackQueue.readyWait], se descarta
  /// (pulsación corta o sin audio).
  DateTime? releasedAt;
}

/// Cola de Radio (R2, FR-025): suena en vivo un solo emisor a la vez, el primero que empezó; los
/// que hablan mientras tanto se silencian en su sala y su mensaje se reproduce **desde el
/// registro** cuando termina el actual, en orden de llegada y sin mezclar. El viaje y el SOS
/// tienen prioridad y hablar pausa la cola: lo que no se alcanzó a oír queda como nuevo.
class PlaybackQueue {
  PlaybackQueue(this._fx, {DateTime Function()? now, this.readyWait = const Duration(seconds: 15)})
    : _now = now ?? DateTime.now;

  final QueueEffects _fx;
  final DateTime Function() _now;
  final Duration readyWait;

  LiveSpeaker? _live;
  Queued? _playing;
  final _queue = <Queued>[];
  bool _talking = false;
  bool _priority = false;

  LiveSpeaker? get live => _live;

  /// El mensaje del registro que suena ahora, si hay.
  Queued? get playing => _playing;

  int get waiting => _queue.length;

  bool get _blocked => _talking || _priority;

  /// `floor.taken` en una sala que suena: en vivo si nada suena, si no a la cola.
  Future<void> floorTaken(String conversationId, String userId, {String? name, String? messageId}) async {
    if (_live?.conversationId == conversationId && _live?.userId == userId) return;
    if (!_blocked && _live == null && _playing == null) {
      _live = (conversationId: conversationId, userId: userId, name: name, messageId: messageId);
      await _fx.setLive(conversationId, true);
      await _fx.duck();
      _fx.changed();
      return;
    }
    await _fx.setLive(conversationId, false);
    if (messageId != null && !_queue.any((q) => q.messageId == messageId)) {
      _queue.add(Queued(conversationId: conversationId, messageId: messageId, userId: userId, name: name, at: _now()));
    }
    _fx.changed();
  }

  /// `floor.released`: termina el vivo de esa sala y sigue la cola.
  Future<void> floorReleased(String conversationId, {String? userId}) async {
    for (final q in _queue) {
      if (q.conversationId == conversationId && (userId == null || q.userId == userId)) q.releasedAt ??= _now();
    }
    final live = _live;
    if (live != null && live.conversationId == conversationId && (userId == null || live.userId == userId)) {
      _live = null;
      if (live.messageId != null) _fx.heard(live.messageId!);
      await _fx.releaseFocus();
      _fx.changed();
    }
    await _drain();
  }

  /// Un mensaje quedó listo en el registro (`radio.message`).
  Future<void> messageReady(String messageId) async {
    for (final q in _queue) {
      if (q.messageId == messageId) q.ready = true;
    }
    await _drain();
  }

  /// El usuario habla: la cola se pausa y lo pendiente queda como nuevo (US7-5).
  Future<void> setTalking(bool talking) async {
    _talking = talking;
    if (talking) await _clear();
  }

  /// Viaje o SOS sonando (US7-4): la radio espera.
  Future<void> setPriority(bool priority) async {
    _priority = priority;
    if (priority) {
      final live = _live;
      if (live != null) {
        await _fx.setLive(live.conversationId, false);
        _live = null;
        if (live.messageId != null) {
          _queue.insert(
            0,
            Queued(
              conversationId: live.conversationId,
              messageId: live.messageId!,
              userId: live.userId,
              name: live.name,
              at: _now(),
            ),
          );
        }
      }
      if (_playing != null) await _fx.stopRecorded();
      _fx.changed();
      return;
    }
    await _drain();
  }

  /// Un minuto de sondeo: descarta los que nunca recibirán su archivo.
  Future<void> tick() => _drain();

  Future<void> _clear() async {
    _queue.clear();
    final live = _live;
    _live = null;
    if (live != null) await _fx.setLive(live.conversationId, false);
    if (_playing != null) await _fx.stopRecorded();
    _fx.changed();
  }

  bool _draining = false;

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (!_blocked && _live == null && _playing == null && _queue.isNotEmpty) {
        final head = _queue.first;
        if (!head.ready) {
          final released = head.releasedAt;
          if (released != null && _now().difference(released) >= readyWait) {
            _queue.removeAt(0);
            _fx.changed();
            continue;
          }
          break;
        }
        _queue.removeAt(0);
        _playing = head;
        _fx.changed();
        await _fx.duck();
        try {
          await _fx.playRecorded(head.messageId);
          if (!_blocked) _fx.heard(head.messageId);
        } on Object {
          // Sin el audio (red, vencido): se salta; sigue en el historial como nuevo.
        }
        _playing = null;
        await _fx.releaseFocus();
        _fx.changed();
      }
    } finally {
      _draining = false;
    }
  }
}
