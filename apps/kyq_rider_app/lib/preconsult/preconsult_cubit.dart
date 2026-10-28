import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import '../app/session_user.dart';
import '../realtime/realtime_events.dart';

enum PreconsultPhase {
  /// Abriendo la consulta.
  opening,

  /// Abierta; la app del conductor aún no se conectó.
  waiting,

  /// El conductor escucha: se puede hablar.
  ready,

  /// Cerrada (ver [PreconsultViewState.message]).
  closed,

  /// No se pudo abrir (ver [PreconsultViewState.message]).
  failed,
}

@immutable
class PreconsultViewState {
  const PreconsultViewState({this.phase = PreconsultPhase.opening, this.preconsult, this.ptt, this.message});

  final PreconsultPhase phase;
  final Preconsult? preconsult;
  final PttController? ptt;
  final String? message;

  PreconsultViewState copyWith({PreconsultPhase? phase, Preconsult? preconsult, PttController? ptt, String? message}) =>
      PreconsultViewState(
        phase: phase ?? this.phase,
        preconsult: preconsult ?? this.preconsult,
        ptt: ptt ?? this.ptt,
        message: message ?? this.message,
      );
}

/// Consulta de voz del pasajero a su Conductor Elegido antes de pedir el viaje (RN-KYQ-010).
///
/// Abre la consulta, se conecta a la sala y habilita hablar cuando llega `preconsult.joined`;
/// se cierra con `preconsult.closed`, al vencer o al terminarla. Un sondeo cada [refreshEvery]
/// cubre eventos perdidos.
class PreconsultCubit extends Cubit<PreconsultViewState> {
  PreconsultCubit({
    required this._api,
    required this.driverId,
    required this.driverName,
    required this._ptt,
    this._realtime = const NoRealtimeEvents(),
    this.refreshEvery,
  }) : super(const PreconsultViewState());

  final KyqApiClient _api;
  final RealtimeEvents _realtime;
  final PttControllerFactory _ptt;
  final String driverId;
  final String driverName;
  final Duration? refreshEvery;
  final _closed = StreamController<void>.broadcast();
  StreamSubscription<RealtimeEvent>? _events;
  StreamSubscription<PttState>? _pttSub;
  Timer? _poll;

  Future<void> start() async {
    final Preconsult pre;
    try {
      pre = await _api.openPreconsult(driverId);
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(phase: PreconsultPhase.failed, message: openErrorText(e, driverName)));
      return;
    }
    if (isClosed) return;
    final ptt = _ptt(_api, pre.id, _closed.stream);
    emit(state.copyWith(preconsult: pre, ptt: ptt));
    _pttSub = ptt.stream.listen((s) {
      if (s.status == PttStatus.closed) unawaited(_refresh());
    });
    _apply(pre);
    final session = await _api.currentSession();
    final myId = (session == null ? null : userIdFromAccessToken(session.accessToken)) ?? pre.passengerId;
    if (isClosed) return;
    _events = _realtime.subscribe(Channels.user(myId)).listen(_onEvent, onError: (Object _) {});
    unawaited(ptt.start());
    final every = refreshEvery;
    if (every != null) _poll = Timer.periodic(every, (_) => _refresh());
  }

  void _onEvent(RealtimeEvent e) {
    final id = state.preconsult?.id;
    switch (e) {
      case PreconsultJoined(:final preconsultId) when preconsultId == id:
        if (state.phase == PreconsultPhase.waiting) emit(state.copyWith(phase: PreconsultPhase.ready));
      case PreconsultClosed(:final preconsultId, :final reason) when preconsultId == id:
        _close(closeText(preconsultCloseReasonFromApi(reason), driverName));
      default:
        break;
    }
  }

  Future<void> _refresh() async {
    final id = state.preconsult?.id;
    if (id == null || state.phase == PreconsultPhase.closed) return;
    try {
      final pre = await _api.getPreconsult(id);
      if (!isClosed) _apply(pre);
    } on Object catch (e) {
      debugPrint('Consulta: $e');
    }
  }

  void _apply(Preconsult pre) {
    if (state.phase == PreconsultPhase.closed) return;
    if (!pre.isOpen) {
      emit(state.copyWith(preconsult: pre));
      _close(closeText(pre.closeReason ?? PreconsultCloseReason.expired, driverName));
      return;
    }
    emit(
      state.copyWith(
        preconsult: pre,
        phase: pre.joinedAt != null || state.phase == PreconsultPhase.ready
            ? PreconsultPhase.ready
            : PreconsultPhase.waiting,
      ),
    );
  }

  void _close(String message) {
    if (isClosed || state.phase == PreconsultPhase.closed) return;
    _poll?.cancel();
    _closed.add(null);
    emit(state.copyWith(phase: PreconsultPhase.closed, message: message));
  }

  /// Termina la consulta (FR-006).
  Future<void> end() async {
    final id = state.preconsult?.id;
    if (id == null || state.phase == PreconsultPhase.closed) return;
    try {
      await _api.endPreconsult(id);
    } on ApiException catch (e) {
      debugPrint('Consulta: $e');
    }
    _close('Terminaste la consulta.');
  }

  static String openErrorText(ApiException e, String name) => switch (e.code) {
    'preconsults_disabled' => '$name no recibe consultas de voz ahora.',
    'driver_unavailable' => '$name no está libre ahora.',
    'preconsult_busy' => '$name está atendiendo otra consulta. Inténtalo en un momento.',
    'preconsult_in_progress' => 'Ya tienes una consulta abierta con otro conductor. Termínala primero.',
    'rate_limited' => 'Has hecho varias consultas seguidas. Inténtalo más tarde o pide el viaje.',
    'not_found' => '$name ya no está en tu lista.',
    'network' => 'Sin conexión con el servidor. Inténtalo de nuevo.',
    _ => 'No pudimos abrir la consulta. Inténtalo de nuevo.',
  };

  static String closeText(PreconsultCloseReason reason, String name) => switch (reason) {
    PreconsultCloseReason.missed => '$name no respondió. Puedes pedir el viaje igualmente.',
    PreconsultCloseReason.endedByDriver => '$name terminó la consulta.',
    PreconsultCloseReason.endedByPassenger => 'Terminaste la consulta.',
    PreconsultCloseReason.driverUnavailable => '$name ya no está disponible.',
    PreconsultCloseReason.disabled => '$name ya no recibe consultas de voz.',
    _ => 'La consulta terminó.',
  };

  @override
  Future<void> close() async {
    _poll?.cancel();
    await _events?.cancel();
    await _pttSub?.cancel();
    await state.ptt?.close();
    await _closed.close();
    return super.close();
  }
}
