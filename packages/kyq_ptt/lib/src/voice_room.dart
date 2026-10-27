/// Estado de la conexión con la sala de voz.
enum VoiceConnection { connected, reconnecting, disconnected }

/// Lo que ocurre en la sala de voz, sin tipos de LiveKit para poder probar el controlador.
sealed class VoiceRoomEvent {
  const VoiceRoomEvent();
}

/// Mensaje de datos de la otra parte, p. ej. `{"type":"floor.taken","user_id":"..."}`.
final class VoiceDataReceived extends VoiceRoomEvent {
  const VoiceDataReceived(this.message, {this.senderId});

  final Map<String, dynamic> message;
  final String? senderId;
}

/// La otra parte emite audio (detección de actividad de voz de la sala).
final class VoiceRemoteSpeaking extends VoiceRoomEvent {
  const VoiceRemoteSpeaking(this.speaking);

  final bool speaking;
}

/// La otra parte salió de la sala.
final class VoiceRemoteLeft extends VoiceRoomEvent {
  const VoiceRemoteLeft();
}

final class VoiceConnectionChanged extends VoiceRoomEvent {
  const VoiceConnectionChanged(this.connection);

  final VoiceConnection connection;
}

/// Sala de voz del viaje.
abstract interface class VoiceRoom {
  Stream<VoiceRoomEvent> get events;

  /// Identidad propia en la sala (el id de usuario que pone el backend en el token).
  String? get localIdentity;

  /// Conecta. Con [publishMicrophone] publica el micrófono ya silenciado, así pulsar solo
  /// tiene que activarlo (SC-005).
  Future<void> connect(String url, String token, {required bool publishMicrophone});

  Future<void> setMicrophoneEnabled(bool enabled);

  Future<void> sendData(Map<String, Object?> message);

  Future<void> disconnect();
}
