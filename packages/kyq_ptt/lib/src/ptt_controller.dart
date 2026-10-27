import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import 'audio_focus.dart';
import 'livekit_voice_room.dart';
import 'mic_permission.dart';
import 'ptt_api.dart';
import 'tones.dart';
import 'voice_room.dart';

enum PttStatus {
  /// Aún no se ha pedido la sala (viaje antes de ACCEPTED).
  inactive,
  connecting,
  reconnecting,

  /// Conectado y libre: se puede pulsar.
  idle,

  /// Pidiendo el turno al backend.
  requesting,
  talking,
  remoteTalking,

  /// Se pulsó con la otra parte hablando (409).
  busy,
  micDenied,

  /// No se pudo tomar el turno o abrir el micrófono; se puede volver a pulsar.
  error,

  /// Canal cerrado (FR-020): el botón desaparece.
  closed,
}

@immutable
class PttState {
  const PttState({this.status = PttStatus.inactive, this.speakerId, this.closesAt, this.micBlocked = false});

  final PttStatus status;

  /// Identidad de la otra parte mientras habla.
  final String? speakerId;

  /// Cierre del canal según el backend (15 min tras COMPLETED).
  final DateTime? closesAt;

  /// El micrófono se denegó para siempre: solo queda abrir los ajustes.
  final bool micBlocked;

  bool get canPress => switch (status) {
    PttStatus.idle || PttStatus.remoteTalking || PttStatus.busy || PttStatus.micDenied || PttStatus.error => true,
    _ => false,
  };

  PttState copyWith({PttStatus? status, String? Function()? speakerId, DateTime? closesAt, bool? micBlocked}) =>
      PttState(
        status: status ?? this.status,
        speakerId: speakerId != null ? speakerId() : this.speakerId,
        closesAt: closesAt ?? this.closesAt,
        micBlocked: micBlocked ?? this.micBlocked,
      );

  @override
  bool operator ==(Object other) =>
      other is PttState &&
      other.status == status &&
      other.speakerId == speakerId &&
      other.closesAt == closesAt &&
      other.micBlocked == micBlocked;

  @override
  int get hashCode => Object.hash(status, speakerId, closesAt, micBlocked);

  @override
  String toString() => 'PttState($status, speaker: $speakerId)';
}

/// Crea el controlador PTT de un viaje. [closeSignals] emite cuando llega `ptt.closed`.
typedef PttControllerFactory = PttController Function(KyqApiClient api, String tripId, Stream<Object?> closeSignals);

/// Controlador del walkie-talkie de un viaje (T070, FR-016–FR-019).
///
/// Se conecta a la sala con el micrófono publicado y silenciado. Pulsar pide el turno al backend
/// (R2) y, concedido, activa el micrófono y avisa a la otra parte con `floor.taken`; soltar lo
/// silencia, envía `floor.released` y libera el turno. La voz entrante pide foco transitorio con
/// atenuación para bajar la navegación mientras suena.
class PttController extends Cubit<PttState> {
  PttController({
    required this._api,
    required this._room,
    required this._focus,
    required this._tones,
    required this._mic,
    Stream<Object?>? closeSignals,
    this.floorMargin = const Duration(seconds: 5),
    this.busyFor = const Duration(seconds: 3),
    this.remoteTimeout = const Duration(seconds: 65),
    this.reconnectDelay = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const PttState()) {
    _closeSub = closeSignals?.listen((_) => unawaited(closeChannel()));
  }

  /// Controlador con LiveKit, `audio_session`, `audioplayers` y `permission_handler`.
  factory PttController.live(KyqApiClient api, String tripId, Stream<Object?> closeSignals) => PttController(
    api: KyqPttApi(api, tripId),
    room: LiveKitVoiceRoom(),
    focus: AudioSessionFocus(),
    tones: AudioplayersTonePlayer(),
    mic: const PlatformMicPermission(),
    closeSignals: closeSignals,
  );

  final PttApi _api;
  final VoiceRoom _room;
  final AudioFocus _focus;
  final TonePlayer _tones;
  final MicPermission _mic;
  final DateTime Function() _clock;

  /// Se suelta el turno este tiempo antes de que caduque en el backend.
  final Duration floorMargin;

  /// Tiempo que se muestra "ocupado" si no llega `floor.taken` de la otra parte.
  final Duration busyFor;

  /// Si la otra parte no envía `floor.released` (se cortó), se da por terminada su voz.
  final Duration remoteTimeout;
  final Duration reconnectDelay;

  StreamSubscription<VoiceRoomEvent>? _roomSub;
  StreamSubscription<Object?>? _closeSub;
  Timer? _autoRelease;
  Timer? _busyTimer;
  Timer? _closeTimer;
  Timer? _remoteTimer;
  Timer? _reconnect;
  bool _started = false;
  bool _channelClosed = false;
  bool _pressed = false;
  bool _incomingFloor = false;
  bool _incomingAudio = false;
  bool _focused = false;

  /// Conecta a la sala. Idempotente: se llama al ver el viaje en ACCEPTED o después.
  Future<void> start() async {
    if (_started || _channelClosed || isClosed) return;
    _started = true;
    _roomSub = _room.events.listen(_onRoomEvent);
    try {
      await _focus.prepare();
    } on Object catch (e) {
      debugPrint('PTT: foco de audio: $e');
    }
    await _connect();
  }

  Future<void> _connect() async {
    if (_channelClosed || isClosed) return;
    _emit(state.copyWith(status: PttStatus.connecting));
    try {
      final creds = await _api.token();
      if (_channelClosed || isClosed) return;
      _scheduleClose(creds.closesAt);
      if (_channelClosed) return;
      if (creds.closesAt != null) _emit(state.copyWith(closesAt: creds.closesAt));
      await _room.connect(creds.url, creds.token, publishMicrophone: await _mic.isGranted());
      if (state.status == PttStatus.connecting) _emit(state.copyWith(status: PttStatus.idle));
    } on PttChannelClosed {
      await closeChannel();
    } on Object catch (e) {
      debugPrint('PTT: no se pudo conectar: $e');
      _emit(state.copyWith(status: PttStatus.reconnecting));
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_channelClosed || isClosed || (_reconnect?.isActive ?? false)) return;
    _reconnect = Timer(reconnectDelay, () => unawaited(_connect()));
  }

  void _scheduleClose(DateTime? closesAt) {
    _closeTimer?.cancel();
    if (closesAt == null) return;
    final left = closesAt.difference(_clock());
    if (left <= Duration.zero) {
      unawaited(closeChannel());
    } else {
      _closeTimer = Timer(left, () => unawaited(closeChannel()));
    }
  }

  /// Mantener pulsado: pide el turno y abre el micrófono.
  Future<void> press() async {
    if (!state.canPress || isClosed) return;
    _pressed = true;
    _busyTimer?.cancel();
    if (!await _mic.isGranted()) {
      final access = await _mic.request();
      if (isClosed) return;
      if (access != MicAccess.granted) {
        _pressed = false;
        _emit(state.copyWith(status: PttStatus.micDenied, micBlocked: access == MicAccess.permanentlyDenied));
        return;
      }
      _emit(state.copyWith(micBlocked: false));
    }
    // El diálogo de permiso interrumpe la pulsación: hay que volver a pulsar.
    if (!_pressed) {
      _emit(state.copyWith(status: _incomingFloor ? PttStatus.remoteTalking : PttStatus.idle));
      return;
    }
    _emit(state.copyWith(status: PttStatus.requesting));
    final DateTime expiresAt;
    try {
      expiresAt = await _api.requestFloor();
    } on PttFloorBusy {
      _pressed = false;
      if (isClosed) return;
      _emit(state.copyWith(status: PttStatus.busy));
      _busyTimer = Timer(busyFor, () {
        if (state.status == PttStatus.busy) {
          _emit(state.copyWith(status: _incomingFloor ? PttStatus.remoteTalking : PttStatus.idle));
        }
      });
      unawaited(_play(PttTone.busy));
      return;
    } on PttChannelClosed {
      await closeChannel();
      return;
    } on Object catch (e) {
      debugPrint('PTT: turno: $e');
      _pressed = false;
      if (!isClosed && state.status == PttStatus.requesting) _emit(state.copyWith(status: PttStatus.error));
      return;
    }
    if (isClosed || _channelClosed) return;
    if (!_pressed) {
      // Soltó mientras llegaba el turno.
      _emit(state.copyWith(status: _incomingFloor ? PttStatus.remoteTalking : PttStatus.idle));
      await _releaseFloorQuietly();
      return;
    }
    try {
      await _room.setMicrophoneEnabled(true);
    } on Object catch (e) {
      debugPrint('PTT: micrófono: $e');
      _pressed = false;
      _emit(state.copyWith(status: PttStatus.error));
      await _releaseFloorQuietly();
      return;
    }
    if (isClosed) return;
    _emit(state.copyWith(status: PttStatus.talking, speakerId: () => null));
    unawaited(_play(PttTone.start));
    unawaited(_send({'type': 'floor.taken', 'user_id': _room.localIdentity}));
    final max = expiresAt.difference(_clock()) - floorMargin;
    _autoRelease = Timer(max < const Duration(seconds: 1) ? const Duration(seconds: 1) : max, release);
    if (!_pressed) await release();
  }

  /// Soltar: silencia el micrófono y libera el turno.
  Future<void> release() async {
    _pressed = false;
    if (state.status != PttStatus.talking || isClosed) return;
    _autoRelease?.cancel();
    _emit(state.copyWith(status: PttStatus.idle));
    try {
      await _room.setMicrophoneEnabled(false);
    } on Object catch (e) {
      debugPrint('PTT: micrófono: $e');
    }
    unawaited(_send({'type': 'floor.released'}));
    unawaited(_play(PttTone.end));
    await _releaseFloorQuietly();
  }

  /// Abre los ajustes del sistema cuando el micrófono quedó denegado para siempre.
  Future<void> openMicSettings() => _mic.openSettings();

  /// Cierra el canal: `ptt.closed`, viaje cancelado, `closes_at` vencido o 410.
  Future<void> closeChannel() async {
    if (_channelClosed || isClosed) return;
    _channelClosed = true;
    final wasTalking = state.status == PttStatus.talking;
    _stopTimers();
    _incomingFloor = false;
    _incomingAudio = false;
    _syncFocus();
    _emit(state.copyWith(status: PttStatus.closed, speakerId: () => null));
    if (wasTalking) await _releaseFloorQuietly();
    try {
      await _room.disconnect();
    } on Object catch (e) {
      debugPrint('PTT: desconexión: $e');
    }
  }

  void _onRoomEvent(VoiceRoomEvent e) {
    if (isClosed || _channelClosed) return;
    switch (e) {
      case VoiceDataReceived(:final message, :final senderId):
        switch (message['type']) {
          case 'floor.taken':
            final speaker = message['user_id'] as String? ?? senderId;
            if (speaker != null && speaker == _room.localIdentity) return;
            _incomingFloor = true;
            _remoteTimer?.cancel();
            _remoteTimer = Timer(remoteTimeout, _endIncoming);
            if (state.status != PttStatus.talking) {
              _emit(state.copyWith(status: PttStatus.remoteTalking, speakerId: () => speaker));
            }
            _syncFocus();
          case 'floor.released':
            _endIncoming();
        }
      case VoiceRemoteSpeaking(:final speaking):
        _incomingAudio = speaking;
        _syncFocus();
      case VoiceRemoteLeft():
        _endIncoming();
      case VoiceConnectionChanged(:final connection):
        switch (connection) {
          case VoiceConnection.reconnecting:
            unawaited(release());
            _endIncoming();
            _emit(state.copyWith(status: PttStatus.reconnecting));
          case VoiceConnection.connected:
            if (state.status == PttStatus.reconnecting || state.status == PttStatus.connecting) {
              _emit(state.copyWith(status: PttStatus.idle));
            }
          case VoiceConnection.disconnected:
            unawaited(release());
            _endIncoming();
            _emit(state.copyWith(status: PttStatus.reconnecting));
            // LiveKit se rindió: se pide un token nuevo, que además dice si el canal cerró.
            _scheduleReconnect();
        }
    }
  }

  void _endIncoming() {
    _remoteTimer?.cancel();
    _incomingFloor = false;
    _incomingAudio = false;
    if (state.status == PttStatus.remoteTalking || state.status == PttStatus.busy) {
      _busyTimer?.cancel();
      _emit(state.copyWith(status: PttStatus.idle, speakerId: () => null));
    }
    _syncFocus();
  }

  void _syncFocus() {
    final want = !_channelClosed && (_incomingFloor || _incomingAudio);
    if (want == _focused) return;
    _focused = want;
    unawaited((want ? _focus.duck() : _focus.release()).catchError((Object e) => debugPrint('PTT: foco de audio: $e')));
  }

  Future<void> _send(Map<String, Object?> message) async {
    try {
      await _room.sendData(message);
    } on Object catch (e) {
      debugPrint('PTT: mensaje de turno: $e');
    }
  }

  Future<void> _play(PttTone tone) async {
    try {
      await _tones.play(tone);
    } on Object catch (e) {
      debugPrint('PTT: tono: $e');
    }
  }

  Future<void> _releaseFloorQuietly() async {
    try {
      await _api.releaseFloor();
    } on Object catch (e) {
      // El turno caduca solo a los 60 s si no llega a liberarse.
      debugPrint('PTT: liberar turno: $e');
    }
  }

  void _emit(PttState s) {
    if (!isClosed) emit(s);
  }

  void _stopTimers() {
    _autoRelease?.cancel();
    _busyTimer?.cancel();
    _closeTimer?.cancel();
    _remoteTimer?.cancel();
    _reconnect?.cancel();
  }

  @override
  Future<void> close() async {
    final wasTalking = state.status == PttStatus.talking;
    _stopTimers();
    _incomingFloor = false;
    _incomingAudio = false;
    _syncFocus();
    await _closeSub?.cancel();
    await _roomSub?.cancel();
    if (wasTalking) unawaited(_releaseFloorQuietly());
    try {
      await _room.disconnect();
      await _tones.dispose();
    } on Object catch (e) {
      debugPrint('PTT: cierre: $e');
    }
    return super.close();
  }
}
