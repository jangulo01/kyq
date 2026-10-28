import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';

/// Posición del teléfono durante una alerta. Cada app la implementa con `geolocator` (conductor:
/// con su servicio en primer plano; pasajero: con la pantalla del viaje abierta).
abstract interface class SosLocationSource {
  /// Última posición conocida, o null si el GPS aún no dio ninguna.
  Future<SosPoint?> current();

  /// Libera el GPS al terminar la alerta.
  Future<void> stop();
}

enum SosPhase {
  /// Sin alerta: se muestra el botón SOS.
  idle,

  /// Enviando la alerta (o reintentando sin datos móviles).
  sending,

  /// Alerta abierta: ubicación cada segundo y canal de voz con el operador.
  active,

  /// El operador cerró el caso o la persona canceló con su PIN.
  closed,
}

enum SosVoiceStatus { none, connecting, connected, unavailable }

@immutable
class SosState {
  const SosState({
    this.phase = SosPhase.idle,
    this.alert,
    this.voice = SosVoiceStatus.none,
    this.needsPin = false,
    this.offline = false,
    this.cancelledByUser = false,
    this.busy = false,
    this.message,
  });

  final SosPhase phase;
  final SosAlertSelf? alert;
  final SosVoiceStatus voice;

  /// La persona no tiene PIN: al terminar se le pide configurarlo (US4-3).
  final bool needsPin;

  /// Sin conexión con el servidor: se reintenta y se ofrece llamar al 123.
  final bool offline;
  final bool cancelledByUser;
  final bool busy;

  /// Aviso para la persona (PIN incorrecto, fuera de viaje...).
  final String? message;

  bool get operatorConnected => alert?.operatorConnected ?? false;
  bool get escalated => alert?.escalated ?? false;

  SosState copyWith({
    SosPhase? phase,
    SosAlertSelf? alert,
    SosVoiceStatus? voice,
    bool? needsPin,
    bool? offline,
    bool? cancelledByUser,
    bool? busy,
    String? message,
    bool clearMessage = false,
  }) => SosState(
    phase: phase ?? this.phase,
    alert: alert ?? this.alert,
    voice: voice ?? this.voice,
    needsPin: needsPin ?? this.needsPin,
    offline: offline ?? this.offline,
    cancelledByUser: cancelledByUser ?? this.cancelledByUser,
    busy: busy ?? this.busy,
    message: clearMessage ? null : message ?? this.message,
  );
}

/// Botón SOS de un viaje (RN-KYQ-015): crea la alerta, envía la ubicación cada [interval] hasta
/// que el operador cierre el caso y abre el micrófono en la sala con los operadores, sin pasos
/// extra. Cancelar exige el PIN de seguridad (FR-005).
class SosCubit extends Cubit<SosState> {
  SosCubit({
    required this._api,
    required this.tripId,
    required this._location,
    VoiceRoom Function()? voice,
    MicPermission? mic,
    this.interval = const Duration(seconds: 1),
    this.retryEvery = const Duration(seconds: 5),
  }) : _newVoice = voice ?? LiveKitVoiceRoom.new,
       _mic = mic ?? const PlatformMicPermission(),
       super(const SosState());

  final SafetyApi _api;
  final SosLocationSource _location;
  final VoiceRoom Function() _newVoice;
  final MicPermission _mic;
  final String tripId;
  final Duration interval;
  final Duration retryEvery;

  /// Lotes de 1 a 5 puntos (contrato): sin red se guardan los más recientes.
  static const maxBatch = 5;

  Timer? _ticker;
  Timer? _retry;
  VoiceRoom? _room;
  StreamSubscription<VoiceRoomEvent>? _roomEvents;
  final List<SosPoint> _pending = [];
  DateTime? _lastSent;
  bool _sendingFixes = false;

  String? get _alertId => state.alert?.id;

  /// Retoma una alerta abierta de este viaje (la app se cerró o se reabrió la pantalla).
  Future<void> resume() async {
    try {
      final alert = await _api.activeSos();
      if (alert == null || alert.tripId != tripId || isClosed) return;
      emit(state.copyWith(phase: SosPhase.active, alert: alert));
      _start(null);
    } on ApiException {
      // Sin red: el botón sigue disponible.
    }
  }

  /// Envía la alerta tras la pulsación larga.
  Future<void> raise() async {
    if (state.phase == SosPhase.sending || state.phase == SosPhase.active) return;
    emit(SosState(phase: SosPhase.sending, needsPin: state.needsPin));
    await _attemptRaise();
  }

  Future<void> _attemptRaise() async {
    _retry?.cancel();
    SosPoint? fix;
    try {
      fix = await _location.current();
    } on Object {
      fix = null; // sin GPS se envía igual; el operador verá la ubicación cuando llegue
    }
    try {
      final out = await _api.raiseSos(tripId, location: fix);
      if (isClosed) return;
      if (fix != null) _lastSent = fix.recordedAt;
      emit(
        state.copyWith(
          phase: SosPhase.active,
          alert: out.alert,
          needsPin: out.needsPin,
          offline: false,
          clearMessage: true,
        ),
      );
      _start(out.voice);
    } on ApiException catch (e) {
      if (isClosed) return;
      if (e.code == 'sos_unavailable') {
        emit(const SosState(message: 'El SOS funciona durante un viaje. Si estás en peligro, llama al 123.'));
        return;
      }
      if (_retriable(e)) {
        emit(state.copyWith(offline: true, message: 'Sin conexión. Seguimos intentando enviar la alerta.'));
        _retry = Timer(retryEvery, () => unawaited(_attemptRaise()));
        return;
      }
      emit(SosState(message: e.message));
    }
  }

  static bool _retriable(ApiException e) => e.statusCode == null || e.statusCode! >= 500;

  void _start(SosVoice? voice) {
    _ticker?.cancel();
    _ticker = Timer.periodic(interval, (_) => unawaited(sendLocation()));
    unawaited(_connectVoice(voice));
  }

  /// Envía la ubicación actual (y las pendientes). Lo llama el temporizador cada [interval].
  @visibleForTesting
  Future<void> sendLocation() async {
    final id = _alertId;
    if (id == null || _sendingFixes || state.phase != SosPhase.active) return;
    _sendingFixes = true;
    try {
      SosPoint? fix;
      try {
        fix = await _location.current();
      } on Object {
        fix = null;
      }
      if (fix != null && fix.recordedAt != _lastSent && !_pending.any((p) => p.recordedAt == fix!.recordedAt)) {
        _pending.add(fix);
        if (_pending.length > maxBatch) _pending.removeRange(0, _pending.length - maxBatch);
      }
      // Sin punto nuevo se reenvía el último: la respuesta trae si ya hay operador.
      final batch = _pending.isNotEmpty ? List<SosPoint>.of(_pending) : [?fix];
      if (batch.isEmpty) return;
      final alert = await _api.sendSosLocations(id, batch);
      _pending.clear();
      _lastSent = batch.last.recordedAt;
      if (!isClosed && state.phase == SosPhase.active) emit(state.copyWith(alert: alert, offline: false));
    } on ApiException catch (e) {
      if (e.statusCode == 410) {
        await _finish(cancelled: false);
      } else if (!isClosed && _retriable(e) && !state.offline) {
        emit(state.copyWith(offline: true));
      }
    } finally {
      _sendingFixes = false;
    }
  }

  Future<void> _connectVoice(SosVoice? creds) async {
    final id = _alertId;
    if (id == null || isClosed) return;
    emit(state.copyWith(voice: SosVoiceStatus.connecting));
    try {
      if (!await _mic.isGranted() && await _mic.request() != MicAccess.granted) {
        // Sin micrófono el operador no oye a la persona, pero ella sí oye al operador.
        debugPrint('SOS: sin permiso de micrófono');
      }
      creds ??= await _api.sosToken(id);
      final room = _room ??= _newVoice();
      unawaited(_roomEvents?.cancel());
      _roomEvents = room.events.listen(_onRoomEvent);
      await room.connect(creds.url, creds.token);
      if (creds.canPublish && await _mic.isGranted()) await room.setMicrophoneEnabled(true);
      if (!isClosed && state.phase == SosPhase.active) emit(state.copyWith(voice: SosVoiceStatus.connected));
    } on Object catch (e) {
      debugPrint('SOS voz: $e');
      if (e is ApiException && e.statusCode == 410) {
        await _finish(cancelled: false);
        return;
      }
      if (isClosed || state.phase != SosPhase.active) return;
      emit(state.copyWith(voice: SosVoiceStatus.unavailable));
      _retry?.cancel();
      _retry = Timer(retryEvery, () => unawaited(_connectVoice(null)));
    }
  }

  void _onRoomEvent(VoiceRoomEvent e) {
    if (e is! VoiceConnectionChanged || isClosed || state.phase != SosPhase.active) return;
    switch (e.connection) {
      case VoiceConnection.connected:
        emit(state.copyWith(voice: SosVoiceStatus.connected));
      case VoiceConnection.reconnecting:
        emit(state.copyWith(voice: SosVoiceStatus.connecting));
      case VoiceConnection.disconnected:
        emit(state.copyWith(voice: SosVoiceStatus.unavailable));
        _retry?.cancel();
        _retry = Timer(retryEvery, () => unawaited(_connectVoice(null)));
    }
  }

  /// "Estoy bien": solo cancela con el PIN correcto. Un PIN incorrecto deja la alerta abierta y
  /// el operador lo ve como posible coacción.
  Future<void> cancel(String pin) async {
    final id = _alertId;
    if (id == null || state.busy) return;
    emit(state.copyWith(busy: true, clearMessage: true));
    try {
      await _api.cancelSos(id, pin);
      await _finish(cancelled: true);
    } on ApiException catch (e) {
      if (e.statusCode == 410) {
        await _finish(cancelled: false);
        return;
      }
      if (isClosed) return;
      emit(
        state.copyWith(
          busy: false,
          message: switch (e.code) {
            'invalid_pin' => 'PIN incorrecto. La alerta sigue activa.',
            'no_pin' => 'No tienes PIN de seguridad. La alerta sigue activa hasta que el operador la cierre.',
            'pin_locked' => 'Demasiados intentos. La alerta sigue activa hasta que el operador la cierre.',
            _ => 'No pudimos cancelar la alerta. Sigue activa.',
          },
        ),
      );
    }
  }

  Future<void> _finish({required bool cancelled}) async {
    _ticker?.cancel();
    _retry?.cancel();
    _ticker = _retry = null;
    _pending.clear();
    unawaited(_roomEvents?.cancel());
    _roomEvents = null;
    final room = _room;
    _room = null;
    await room?.disconnect();
    await _location.stop();
    if (!isClosed) {
      emit(state.copyWith(phase: SosPhase.closed, voice: SosVoiceStatus.none, busy: false, cancelledByUser: cancelled));
    }
  }

  /// Vuelve al botón tras ver el cierre.
  void dismiss() {
    if (state.phase == SosPhase.closed || state.phase == SosPhase.idle) {
      emit(SosState(needsPin: state.needsPin && !state.cancelledByUser));
    }
  }

  /// El PIN ya se configuró.
  void pinConfigured() => emit(state.copyWith(needsPin: false));

  @override
  Future<void> close() async {
    _ticker?.cancel();
    _retry?.cancel();
    unawaited(_roomEvents?.cancel());
    await _room?.disconnect();
    await _location.stop();
    return super.close();
  }
}
