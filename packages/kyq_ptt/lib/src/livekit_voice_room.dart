// La configuración de la sesión de audio de LiveKit está marcada como experimental, pero es la
// única forma de que no pida foco de audio permanente en Android.
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:convert';

import 'package:livekit_client/livekit_client.dart';

import 'voice_room.dart';

/// [VoiceRoom] sobre LiveKit (R1); también sirve de [ListeningRoom] para Radio (011).
class LiveKitVoiceRoom implements ListeningRoom {
  final _events = StreamController<VoiceRoomEvent>.broadcast();
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _leaving = false;
  bool _remoteAudio = true;

  static Future<void>? _initialized;

  /// WebRTC lee esta configuración al crear su módulo de audio: debe ir antes de la primera sala.
  /// LiveKit no gestiona el foco de Android; lo pide `AudioSessionFocus` solo mientras suena voz
  /// entrante, para atenuar la navegación en vez de silenciarla todo el viaje (FR-019).
  static Future<void> _initialize() => _initialized ??= LiveKitClient.initialize(
    initialAudioSessionOptions: const AudioSessionOptions.communication(
      android: AndroidAudioSessionConfiguration(
        audioMode: AndroidAudioMode.inCommunication,
        manageAudioFocus: false,
        streamType: AndroidAudioStreamType.voiceCall,
        usageType: AndroidAudioAttributesUsageType.voiceCommunication,
        contentType: AndroidAudioAttributesContentType.speech,
      ),
    ),
  );

  @override
  Stream<VoiceRoomEvent> get events => _events.stream;

  @override
  String? get localIdentity => _room?.localParticipant?.identity;

  @override
  Future<void> connect(String url, String token) async {
    await _initialize();
    await disconnect();
    _leaving = false;
    final room = Room(roomOptions: const RoomOptions(defaultAudioOutputOptions: AudioOutputOptions(speakerOn: true)));
    _listener = room.createListener()
      ..on<DataReceivedEvent>(_onData)
      ..on<ActiveSpeakersChangedEvent>(
        (e) => _events.add(VoiceRemoteSpeaking(e.speakers.any((p) => p is RemoteParticipant))),
      )
      ..on<ParticipantDisconnectedEvent>((_) => _events.add(const VoiceRemoteLeft()))
      // 011: una pista que llega con la voz entrante apagada empieza en silencio.
      ..on<TrackSubscribedEvent>((e) {
        if (!_remoteAudio && e.track is RemoteAudioTrack) unawaited(e.track.disable());
      })
      ..on<RoomReconnectingEvent>((_) => _events.add(const VoiceConnectionChanged(VoiceConnection.reconnecting)))
      ..on<RoomReconnectedEvent>((_) => _events.add(const VoiceConnectionChanged(VoiceConnection.connected)))
      ..on<RoomDisconnectedEvent>((_) {
        if (!_leaving) _events.add(const VoiceConnectionChanged(VoiceConnection.disconnected));
      });
    _room = room;
    await room.connect(url, token);
    // Altavoz por defecto: el teléfono va en el soporte del carro, no en la oreja.
    await AudioManager.instance.setSpeakerOutputPreferred(true);
    _events.add(const VoiceConnectionChanged(VoiceConnection.connected));
  }

  /// El backend concede publicar antes de responder al turno, pero el aviso llega a la sala por
  /// la señalización de LiveKit y puede ir unos milisegundos detrás.
  static const _grantWait = Duration(seconds: 3);

  Future<void> _awaitPublishGrant(Room room) async {
    final local = room.localParticipant;
    if (local == null || local.permissions.canPublish) return;
    final granted = Completer<void>();
    final listener = room.createListener()
      ..on<ParticipantPermissionsUpdatedEvent>((e) {
        if (e.participant == local && e.permissions.canPublish && !granted.isCompleted) granted.complete();
      });
    try {
      if (!local.permissions.canPublish) await granted.future.timeout(_grantWait);
    } finally {
      await listener.dispose();
    }
  }

  void _onData(DataReceivedEvent e) {
    try {
      final message = jsonDecode(utf8.decode(e.data));
      if (message is Map<String, dynamic>) {
        _events.add(VoiceDataReceived(message, senderId: e.participant?.identity, senderName: e.participant?.name));
      }
    } on FormatException {
      // Mensajes ajenos al protocolo de turno: se ignoran.
    }
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    final room = _room;
    if (room == null) return;
    // Al soltar, el backend retira el permiso y LiveKit despublica la pista; al pulsar de nuevo
    // se publica otra.
    if (enabled) await _awaitPublishGrant(room);
    await room.localParticipant?.setMicrophoneEnabled(enabled);
  }

  @override
  Future<void> setRemoteAudioEnabled(bool enabled) async {
    _remoteAudio = enabled;
    final room = _room;
    if (room == null) return;
    for (final p in room.remoteParticipants.values) {
      for (final pub in p.audioTrackPublications) {
        final track = pub.track;
        if (track == null) continue;
        await (enabled ? track.enable() : track.disable());
      }
    }
  }

  @override
  Future<void> sendData(Map<String, Object?> message) async {
    await _room?.localParticipant?.publishData(utf8.encode(jsonEncode(message)), reliable: true);
  }

  @override
  Future<void> disconnect() async {
    final room = _room;
    if (room == null) return;
    _leaving = true;
    _room = null;
    await _listener?.dispose();
    _listener = null;
    await room.disconnect();
    await room.dispose();
  }
}

/// Altavoz o auricular para todas las salas (011, salida de audio de Radio, FR-009).
Future<void> setLiveKitSpeakerOutput(bool speaker) => AudioManager.instance.setSpeakerOutputPreferred(speaker);
