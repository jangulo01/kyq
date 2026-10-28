import 'dart:async';

import 'package:kyq_realtime/kyq_realtime.dart';

/// Fuente de eventos en vivo. Las pantallas dependen de esta interfaz y no de [KyqRealtime]
/// para que las pruebas de widgets nunca abran sockets.
abstract interface class RealtimeEvents {
  /// Eventos de [channel]. Cancelar la suscripción al stream la elimina del servidor.
  Stream<RealtimeEvent> subscribe(String channel);
}

/// Sin tiempo real: no emite nada. Valor por defecto de la app en pruebas.
class NoRealtimeEvents implements RealtimeEvents {
  const NoRealtimeEvents();

  @override
  Stream<RealtimeEvent> subscribe(String channel) => const Stream.empty();
}

/// Adaptador sobre [KyqRealtime]. Crea el cliente y conecta solo con la primera suscripción.
class CentrifugoRealtimeEvents implements RealtimeEvents {
  CentrifugoRealtimeEvents(this._create);

  final KyqRealtime Function() _create;
  KyqRealtime? _client;
  Future<void>? _connecting;

  @override
  Stream<RealtimeEvent> subscribe(String channel) async* {
    final client = _client ??= _create();
    try {
      await (_connecting ??= client.connect());
    } on Object {
      // Se reintenta en la próxima suscripción; el cliente también reconecta solo.
      _connecting = null;
    }
    yield* client.subscribe(channel);
  }

  Future<void> dispose() async => _client?.disconnect();
}
