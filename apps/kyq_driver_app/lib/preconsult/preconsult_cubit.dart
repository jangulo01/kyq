import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

/// Consulta de voz en curso con su walkie-talkie.
@immutable
class ActivePreconsult {
  const ActivePreconsult({
    required this.id,
    required this.passengerName,
    required this.closesAt,
    required this.controller,
  });

  final String id;
  final String passengerName;
  final DateTime closesAt;
  final PttController controller;
}

@immutable
class PreconsultState {
  const PreconsultState({this.active, this.inbox = const [], this.loading = false, this.notice});

  final ActivePreconsult? active;

  /// Consultas de las últimas 24 h (FR-010).
  final List<Preconsult> inbox;
  final bool loading;

  /// Último aviso, p. ej. "La consulta de Ana terminó"; la app lo muestra cuando cambia.
  final String? notice;

  PreconsultState copyWith({
    ActivePreconsult? Function()? active,
    List<Preconsult>? inbox,
    bool? loading,
    String? notice,
  }) => PreconsultState(
    active: active != null ? active() : this.active,
    inbox: inbox ?? this.inbox,
    loading: loading ?? this.loading,
    notice: notice ?? this.notice,
  );
}

/// Pre-consultas de voz del conductor (RN-KYQ-010): al llegar `preconsult.opened` se une sola a
/// la sala con un tono de aviso, la ofrece al botón físico y la burbuja, y la cierra con
/// `preconsult.closed`, al vencer o al terminarla.
class PreconsultCubit extends Cubit<PreconsultState> {
  PreconsultCubit({
    required this._api,
    required Stream<RealtimeEvent> events,
    required this._ptt,
    required this._handsFree,
  }) : super(const PreconsultState()) {
    _events = events.listen(_onEvent);
  }

  final KyqApiClient _api;
  final PttControllerFactory _ptt;
  final HandsFreePtt _handsFree;
  late final StreamSubscription<RealtimeEvent> _events;
  final _closed = StreamController<String>.broadcast();
  StreamSubscription<PttState>? _activeSub;

  /// Carga la bandeja y retoma una consulta abierta (p. ej. tras reabrir la app).
  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final inbox = await _api.driverPreconsults();
      if (isClosed) return;
      emit(state.copyWith(inbox: inbox, loading: false));
      final open = inbox.where((p) => p.isOpen).firstOrNull;
      if (open != null && state.active == null) _join(open.id, open.passengerName, open.closesAt, announce: false);
    } on Object catch (e) {
      debugPrint('Consultas: $e');
      if (!isClosed) emit(state.copyWith(loading: false));
    }
  }

  void _onEvent(RealtimeEvent e) {
    switch (e) {
      case PreconsultOpened(:final preconsultId, :final passengerName, :final closesAt):
        _join(preconsultId, passengerName, closesAt, announce: true);
        unawaited(load());
      case PreconsultClosed(:final preconsultId, :final reason):
        // Primero el aviso con el motivo; luego el cierre del canal, que ya no lo pisa.
        if (state.active?.id == preconsultId) unawaited(_finish(reasonText(reason, state.active!.passengerName)));
        _closed.add(preconsultId);
        unawaited(load());
      default:
        break;
    }
  }

  void _join(String id, String passengerName, DateTime closesAt, {required bool announce}) {
    if (isClosed || state.active?.id == id) return;
    final previous = state.active;
    if (previous != null) unawaited(_dispose(previous));
    final controller = _ptt(_api, id, _closed.stream.where((closed) => closed == id));
    emit(
      state.copyWith(
        active: () =>
            ActivePreconsult(id: id, passengerName: passengerName, closesAt: closesAt, controller: controller),
      ),
    );
    _activeSub = controller.stream.listen((s) {
      if (s.status == PttStatus.closed && state.active?.controller == controller) {
        unawaited(_finish('La consulta de $passengerName terminó.'));
      }
    });
    _handsFree.attach(controller);
    unawaited(controller.start());
    if (announce) unawaited(controller.playTone(PttTone.incoming));
  }

  /// Termina la consulta activa (FR-006).
  Future<void> end() async {
    final active = state.active;
    if (active == null) return;
    try {
      await _api.endPreconsult(active.id);
    } on ApiException catch (e) {
      debugPrint('Consultas: $e');
    }
    await _finish(null);
    unawaited(load());
  }

  Future<void> _finish(String? notice) async {
    final active = state.active;
    if (active == null || isClosed) return;
    emit(state.copyWith(active: () => null, notice: notice));
    await _dispose(active);
  }

  Future<void> _dispose(ActivePreconsult active) async {
    await _activeSub?.cancel();
    _activeSub = null;
    _handsFree.detach(active.controller);
    await active.controller.close();
  }

  static String reasonText(String reason, String name) => switch (reason) {
    'ended_by_passenger' => '$name terminó la consulta.',
    'ended_by_driver' => 'Terminaste la consulta con $name.',
    'missed' => 'No alcanzaste a conectarte a la consulta de $name.',
    'driver_unavailable' => 'La consulta de $name se cerró porque ya no estás libre.',
    'disabled' => 'La consulta de $name se cerró: desactivaste las consultas.',
    _ => 'La consulta de $name terminó.',
  };

  @override
  Future<void> close() async {
    await _events.cancel();
    final active = state.active;
    if (active != null) await _dispose(active);
    await _closed.close();
    return super.close();
  }
}

/// Texto de la bandeja para el estado de una consulta.
String preconsultStatusText(PreconsultStatus status) => switch (status) {
  PreconsultStatus.open => 'En curso',
  PreconsultStatus.answered => 'Respondida',
  PreconsultStatus.unanswered => 'Escuchada sin respuesta',
  PreconsultStatus.missed => 'Perdida',
  PreconsultStatus.unknown => '',
};
