// La configuración de la sesión de audio de LiveKit está marcada como experimental, pero es la
// única forma de que no pida foco de audio permanente en Android.
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:convert';

import 'package:livekit_client/livekit_client.dart';

import 'voice_room.dart';

/// [VoiceRoom] sobre LiveKit (R1).
class LiveKitVoiceRoom implements VoiceRoom {
  final _events = StreamController<VoiceRoomEvent>.broadcast();
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _leaving = false;

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
  Future<void> connect(String url, String token, {required bool publishMicrophone}) async {
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
      ..on<RoomReconnectingEvent>((_) => _events.add(const VoiceConnectionChanged(VoiceConnection.reconnecting)))
      ..on<RoomReconnectedEvent>((_) => _events.add(const VoiceConnectionChanged(VoiceConnection.connected)))
      ..on<RoomDisconnectedEvent>((_) {
        if (!_leaving) _events.add(const VoiceConnectionChanged(VoiceConnection.disconnected));
      });
    _room = room;
    await room.connect(url, token);
    // Altavoz por defecto: el teléfono va en el soporte del carro, no en la oreja.
    await AudioManager.instance.setSpeakerOutputPreferred(true);
    if (publishMicrophone) await _publishMuted(room);
    _events.add(const VoiceConnectionChanged(VoiceConnection.connected));
  }

  Future<void> _publishMuted(Room room) async {
    final track = await LocalAudioTrack.create(room.roomOptions.defaultAudioCaptureOptions);
    // Deshabilitada antes de publicar para no enviar ni un instante de audio.
    await track.disable();
    await room.localParticipant!.publishAudioTrack(track);
    await room.localParticipant!.setMicrophoneEnabled(false);
  }

  void _onData(DataReceivedEvent e) {
    try {
      final message = jsonDecode(utf8.decode(e.data));
      if (message is Map<String, dynamic>) {
        _events.add(VoiceDataReceived(message, senderId: e.participant?.identity));
      }
    } on FormatException {
      // Mensajes ajenos al protocolo de turno: se ignoran.
    }
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    await _room?.localParticipant?.setMicrophoneEnabled(enabled);
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
