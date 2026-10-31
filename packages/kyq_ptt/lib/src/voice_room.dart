/// Estado de la conexión con la sala de voz.
enum VoiceConnection { connected, reconnecting, disconnected }

/// Lo que ocurre en la sala de voz, sin tipos de LiveKit para poder probar el controlador.
sealed class VoiceRoomEvent {
  const VoiceRoomEvent();
}

/// Mensaje de datos de la otra parte, p. ej. `{"type":"floor.taken","user_id":"..."}`.
final class VoiceDataReceived extends VoiceRoomEvent {
  const VoiceDataReceived(this.message, {this.senderId, this.senderName});

  final Map<String, dynamic> message;
  final String? senderId;

  /// Nombre con el que el backend firmó el token del emisor (011: "Carlos está hablando").
  final String? senderName;
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

  /// Conecta para escuchar y enviar mensajes de datos. El token no deja publicar audio.
  Future<void> connect(String url, String token);

  /// Activar publica el micrófono; solo funciona con el turno concedido, porque entonces el
  /// backend da permiso de publicar en la sala (FR-017).
  Future<void> setMicrophoneEnabled(bool enabled);

  Future<void> sendData(Map<String, Object?> message);

  Future<void> disconnect();
}

/// Sala de Radio Kyq (011, R2): una por conversación encendida, conectada solo para escuchar. La
/// app puede dejar de reproducir la voz que llega sin salir de la sala (la cola la reproduce luego
/// desde el registro) y publica el micrófono solo con el turno, como [VoiceRoom].
abstract interface class ListeningRoom implements VoiceRoom {
  /// Apagado, la voz que llega no suena; la sala sigue conectada y los mensajes de datos llegan.
  Future<void> setRemoteAudioEnabled(bool enabled);
}
