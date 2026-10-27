import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

/// Origen de los eventos del canal `user:{driverId}`. Las pruebas lo sustituyen por un falso
/// para no abrir sockets.
abstract interface class DriverEventSource {
  Stream<RealtimeEvent> userEvents(String userId);

  Future<void> close();
}

/// [DriverEventSource] sobre Centrifugo.
class KyqRealtimeEventSource implements DriverEventSource {
  KyqRealtimeEventSource(this._realtime);

  final KyqRealtime _realtime;

  @override
  Stream<RealtimeEvent> userEvents(String userId) async* {
    await _realtime.connect();
    yield* _realtime.subscribe(Channels.user(userId));
  }

  @override
  Future<void> close() => _realtime.disconnect();
}

/// Reparte los eventos del conductor a las pantallas que los necesitan (oferta, viaje).
///
/// Mantiene una sola suscripción y la reintenta si falla.
class DriverEvents {
  DriverEvents(this._source, {this.retryDelay = const Duration(seconds: 5)});

  final DriverEventSource _source;
  final Duration retryDelay;
  final _controller = StreamController<RealtimeEvent>.broadcast();
  StreamSubscription<RealtimeEvent>? _sub;
  Timer? _retry;
  String? _userId;

  Stream<RealtimeEvent> get stream => _controller.stream;

  /// Escucha el canal del usuario [userId]. No hace nada si ya lo escucha.
  void listenTo(String userId) {
    if (_userId == userId && _sub != null) return;
    _cancel();
    _userId = userId;
    _subscribe();
  }

  void _subscribe() {
    final userId = _userId;
    if (userId == null) return;
    _sub = _source
        .userEvents(userId)
        .listen(
          _controller.add,
          onError: (Object e) {
            debugPrint('Tiempo real: $e');
            _scheduleRetry();
          },
          onDone: _scheduleRetry,
        );
  }

  void _scheduleRetry() {
    if (_userId == null || (_retry?.isActive ?? false)) return;
    _sub?.cancel();
    _sub = null;
    _retry = Timer(retryDelay, _subscribe);
  }

  void _cancel() {
    _retry?.cancel();
    _retry = null;
    _sub?.cancel();
    _sub = null;
  }

  /// Deja de escuchar (al cerrar sesión).
  Future<void> stop() async {
    _userId = null;
    _cancel();
    await _source.close();
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
