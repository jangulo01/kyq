import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import 'alert_sound.dart';
import 'session_user.dart';

/// Tiempo real de la consola: `ops:sos` y `sos:{alertId}` (solo operadores, 003).
abstract interface class OpsRealtime {
  Stream<RealtimeEvent> subscribe(String channel);
}

/// [OpsRealtime] con Centrifugo; conecta al primer uso.
class CentrifugoOpsRealtime implements OpsRealtime {
  CentrifugoOpsRealtime(this._create);

  final KyqRealtime Function() _create;
  KyqRealtime? _client;

  @override
  Stream<RealtimeEvent> subscribe(String channel) {
    final client = _client ??= _create()..connect().ignore();
    return client.subscribe(channel);
  }
}

/// Sin tiempo real (pruebas): la cola se refresca por sondeo.
class NoOpsRealtime implements OpsRealtime {
  const NoOpsRealtime();

  @override
  Stream<RealtimeEvent> subscribe(String channel) => const Stream.empty();
}

String opsErrorMessage(ApiException e) => switch (e.code) {
  'network' => 'Sin conexión con el servidor.',
  'not_emergency_operator' => 'Tu cuenta no tiene el permiso de operador de emergencias.',
  'sos_claimed' => 'Otro operador ya atiende esta alerta.',
  'sos_not_claimed' => 'Toma la alerta antes de hacer esto.',
  'sos_closed' => 'La alerta ya está cerrada.',
  'sos_voice_unavailable' => 'El servidor de voz no responde. Inténtalo de nuevo.',
  _ => e.message.isEmpty ? 'Algo salió mal (${e.code}).' : e.message,
};

@immutable
class SosQueueState {
  const SosQueueState({this.alerts = const [], this.loading = false, this.error, this.onDuty});

  final List<SosAlertSummary> alerts;
  final bool loading;
  final String? error;

  /// null mientras no se sabe (o sin permiso).
  final bool? onDuty;
}

/// Cola en vivo de alertas abiertas (FR-007): se recarga con cada evento de `ops:sos`, suena un
/// aviso con cada alerta nueva y, por si el tiempo real cae, se consulta cada [poll].
class SosQueueCubit extends Cubit<SosQueueState> {
  SosQueueCubit(this._api, OpsRealtime realtime, this._sound, {Duration poll = const Duration(seconds: 10)})
    : super(const SosQueueState()) {
    _events = realtime.subscribe(Channels.opsSos).listen(_onEvent, onError: (Object e) => debugPrint('ops:sos: $e'));
    _poll = Timer.periodic(poll, (_) => unawaited(load()));
  }

  final KyqApiClient _api;
  final AlertSound _sound;
  late final StreamSubscription<RealtimeEvent> _events;
  late final Timer _poll;
  Set<String>? _known;

  Future<void> load() async {
    if (isClosed) return;
    emit(SosQueueState(alerts: state.alerts, loading: true, onDuty: state.onDuty));
    try {
      final alerts = await _api.opsOpenAlerts();
      final onDuty = state.onDuty ?? await _api.opsOnDuty();
      if (isClosed) return;
      final known = _known;
      // Aviso sonoro con cada alerta que no estaba (también si llegó por sondeo).
      if (known != null && alerts.any((a) => !known.contains(a.id))) unawaited(_sound.play());
      _known = {for (final a in alerts) a.id};
      emit(SosQueueState(alerts: alerts, onDuty: onDuty));
    } on ApiException catch (e) {
      if (!isClosed) emit(SosQueueState(alerts: state.alerts, error: opsErrorMessage(e), onDuty: state.onDuty));
    }
  }

  void _onEvent(RealtimeEvent e) {
    switch (e) {
      case SosCreated() || SosClaimed() || SosReleased() || SosClosed() || SosCancelAttempt() || SosEscalated():
        unawaited(load());
      default:
        break;
    }
  }

  /// Entra o sale de guardia (SMS de escalada a los 60 s, FR-011).
  Future<void> setOnDuty(bool onDuty) async {
    try {
      final now = await _api.opsSetOnDuty(onDuty);
      if (!isClosed) emit(SosQueueState(alerts: state.alerts, onDuty: now));
    } on ApiException catch (e) {
      if (!isClosed) emit(SosQueueState(alerts: state.alerts, error: opsErrorMessage(e), onDuty: state.onDuty));
    }
  }

  @override
  Future<void> close() async {
    _poll.cancel();
    unawaited(_events.cancel());
    return super.close();
  }
}

enum OpsVoice { off, connecting, listening, talking, unavailable }

@immutable
class SosDetailState {
  const SosDetailState({
    this.alert,
    this.loading = false,
    this.busy = false,
    this.voice = OpsVoice.off,
    this.error,
    this.notice,
  });

  final SosAlertDetail? alert;
  final bool loading;
  final bool busy;
  final OpsVoice voice;
  final String? error;
  final String? notice;

  SosDetailState copyWith({
    SosAlertDetail? alert,
    bool? loading,
    bool? busy,
    OpsVoice? voice,
    String? error,
    String? notice,
  }) => SosDetailState(
    alert: alert ?? this.alert,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    voice: voice ?? this.voice,
    error: error,
    notice: notice,
  );
}

/// Detalle de una alerta para el operador (FR-008..FR-010): ubicación en vivo, escuchar y hablar
/// en la sala, tomar y liberar, notas y cierre con desenlace.
class SosDetailCubit extends Cubit<SosDetailState> {
  SosDetailCubit(
    this._api,
    this.alertId, {
    this.operatorId,
    OpsRealtime realtime = const NoOpsRealtime(),
    VoiceRoom Function()? voice,
  }) : _newVoice = voice ?? LiveKitVoiceRoom.new,
       super(const SosDetailState()) {
    _subs = [
      realtime.subscribe(Channels.sos(alertId)).listen(_onEvent, onError: (Object e) => debugPrint('sos: $e')),
      realtime.subscribe(Channels.opsSos).listen(_onEvent, onError: (Object e) => debugPrint('ops:sos: $e')),
    ];
  }

  final KyqApiClient _api;
  final String alertId;

  /// Operador actual: decide si "Tomar" o "Liberar" y si puede hablar. Sin valor se lee del token.
  String? operatorId;
  final VoiceRoom Function() _newVoice;
  late final List<StreamSubscription<RealtimeEvent>> _subs;
  VoiceRoom? _room;

  bool get mine => state.alert?.claimedBy != null && state.alert?.claimedBy == operatorId;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      if (operatorId == null) {
        final session = await _api.currentSession();
        operatorId = session == null ? null : userIdFromAccessToken(session.accessToken);
      }
      final alert = await _api.opsAlert(alertId);
      if (!isClosed) emit(state.copyWith(alert: alert, loading: false));
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(loading: false, error: opsErrorMessage(e)));
    }
  }

  void _onEvent(RealtimeEvent e) {
    final alert = state.alert;
    switch (e) {
      case SosLocationUpdate(:final lat, :final lng, :final accuracyM, :final at) when alert != null:
        final point = SosLocation(lat: lat, lng: lng, accuracyM: accuracyM, at: at);
        emit(
          state.copyWith(
            alert: alert.copyWith(track: [...alert.track, point], lastLocation: point),
          ),
        );
      case SosClaimed(:final alertId) ||
              SosReleased(:final alertId) ||
              SosClosed(:final alertId) ||
              SosCancelAttempt(:final alertId) ||
              SosEscalated(:final alertId)
          when alertId == this.alertId:
        unawaited(load());
      default:
        break;
    }
  }

  Future<void> _act(Future<void> Function() action, {String? notice}) async {
    emit(state.copyWith(busy: true));
    try {
      await action();
      await load();
      if (!isClosed) emit(state.copyWith(busy: false, notice: notice));
    } on ApiException catch (e) {
      await load();
      if (!isClosed) emit(state.copyWith(busy: false, error: opsErrorMessage(e)));
    }
  }

  /// Escucha la sala (todos los operadores pueden, FR-008).
  Future<void> listen() async {
    if (state.voice == OpsVoice.listening || state.voice == OpsVoice.talking) return;
    emit(state.copyWith(voice: OpsVoice.connecting));
    try {
      final creds = await _api.opsVoiceToken(alertId);
      final room = _room ??= _newVoice();
      await room.connect(creds.url, creds.token);
      if (!isClosed) emit(state.copyWith(voice: OpsVoice.listening));
      // Si ya la tenía tomada, se vuelve a pedir la voz ahora que está en la sala.
      if (mine) await _api.opsClaim(alertId);
    } on Object catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(voice: OpsVoice.unavailable, error: e is ApiException ? opsErrorMessage(e) : 'Sin audio: $e'),
        );
      }
    }
  }

  /// Toma la alerta: el backend concede hablar en la sala.
  Future<void> claim() => _act(() async {
    await _api.opsClaim(alertId);
    if (_room != null && state.voice == OpsVoice.listening) {
      // El permiso llega por la señalización de LiveKit; setMicrophoneEnabled lo espera.
      await _room!.setMicrophoneEnabled(true);
      if (!isClosed) emit(state.copyWith(voice: OpsVoice.talking));
    }
  }, notice: 'Alerta tomada');

  /// Activa o silencia el micrófono del operador que tiene la alerta.
  Future<void> setTalking(bool talking) async {
    final room = _room;
    if (room == null || !mine) return;
    try {
      await room.setMicrophoneEnabled(talking);
      if (!isClosed) emit(state.copyWith(voice: talking ? OpsVoice.talking : OpsVoice.listening));
    } on Object catch (e) {
      if (!isClosed) emit(state.copyWith(error: 'No se pudo activar el micrófono: $e'));
    }
  }

  Future<void> release() => _act(() async {
    await _room?.setMicrophoneEnabled(false);
    if (state.voice == OpsVoice.talking) emit(state.copyWith(voice: OpsVoice.listening));
    await _api.opsRelease(alertId);
  }, notice: 'Alerta liberada');

  Future<void> addNote(String body) async {
    if (body.trim().isEmpty) return;
    await _act(() => _api.opsAddNote(alertId, body.trim()), notice: 'Nota guardada');
  }

  /// Cierra el caso: la app deja de enviar la ubicación y la sala se borra (FR-010).
  Future<void> closeCase(SosOutcome outcome) => _act(() async {
    await _api.opsClose(alertId, outcome);
    await _hangUp();
  }, notice: 'Caso cerrado');

  Future<void> _hangUp() async {
    final room = _room;
    _room = null;
    await room?.disconnect();
    if (!isClosed) emit(state.copyWith(voice: OpsVoice.off));
  }

  /// Deja de escuchar sin cambiar la alerta.
  Future<void> hangUp() => _hangUp();

  @override
  Future<void> close() async {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    await _room?.disconnect();
    return super.close();
  }
}

@immutable
class SosHistoryState {
  const SosHistoryState({this.alerts = const [], this.loading = false, this.error, this.outcome, this.from, this.to});

  final List<SosAlertSummary> alerts;
  final bool loading;
  final String? error;
  final SosOutcome? outcome;
  final DateTime? from;
  final DateTime? to;
}

/// Historial de alertas cerradas filtrable por fecha y desenlace (FR-007).
class SosHistoryCubit extends Cubit<SosHistoryState> {
  SosHistoryCubit(this._api) : super(const SosHistoryState());

  final KyqApiClient _api;

  Future<void> load({SosOutcome? outcome, DateTime? from, DateTime? to, bool keepFilters = true}) async {
    final o = keepFilters ? (outcome ?? state.outcome) : outcome;
    final f = keepFilters ? (from ?? state.from) : from;
    final t = keepFilters ? (to ?? state.to) : to;
    emit(SosHistoryState(alerts: state.alerts, loading: true, outcome: o, from: f, to: t));
    try {
      final alerts = await _api.opsAlertHistory(from: f, to: t, outcome: o);
      if (!isClosed) emit(SosHistoryState(alerts: alerts, outcome: o, from: f, to: t));
    } on ApiException catch (e) {
      if (!isClosed) emit(SosHistoryState(alerts: state.alerts, error: opsErrorMessage(e), outcome: o, from: f, to: t));
    }
  }
}
