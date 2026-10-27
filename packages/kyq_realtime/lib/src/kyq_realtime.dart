import 'dart:async';
import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;

import 'events.dart';

/// Conexión de tiempo real con Centrifugo. Los tokens los emite el backend
/// (`/v1/realtime/token` y `/v1/realtime/subscription-token`).
class KyqRealtime {
  KyqRealtime({
    required String url,
    required Future<String> Function() connectionToken,
    required this.subscriptionToken,
  }) : _client = centrifuge.createClient(url, centrifuge.ClientConfig(getToken: (_) => connectionToken()));

  final centrifuge.Client _client;

  /// Pide al backend el token de suscripción de un canal.
  final Future<String> Function(String channel) subscriptionToken;

  /// Estado actual de la conexión, para mostrar "reconectando" en la UI.
  centrifuge.State get state => _client.state;

  Future<void> connect() => _client.connect();

  Future<void> disconnect() => _client.disconnect();

  /// Suscribe a [channel]. Cancelar el stream elimina la suscripción. Tras reconectar, el
  /// servidor reenvía los eventos perdidos del historial del canal.
  Stream<RealtimeEvent> subscribe(String channel) {
    late final StreamController<RealtimeEvent> controller;
    centrifuge.Subscription? sub;
    StreamSubscription<centrifuge.PublicationEvent>? pubs;

    controller = StreamController<RealtimeEvent>(
      onListen: () async {
        try {
          sub =
              _client.getSubscription(channel) ??
              _client.newSubscription(
                channel,
                centrifuge.SubscriptionConfig(getToken: (_) => subscriptionToken(channel)),
              );
          pubs = sub!.publication.listen((e) {
            try {
              final json = jsonDecode(utf8.decode(e.data)) as Map<String, dynamic>;
              controller.add(RealtimeEvent.fromEnvelope(json));
            } on Object catch (err, st) {
              controller.addError(FormatException('evento inválido en $channel: $err'), st);
            }
          });
          await sub!.subscribe();
        } on Object catch (err, st) {
          controller.addError(err, st);
        }
      },
      onCancel: () async {
        await pubs?.cancel();
        final s = sub;
        if (s != null) {
          await s.unsubscribe();
          await _client.removeSubscription(s);
        }
      },
    );
    return controller.stream;
  }
}
