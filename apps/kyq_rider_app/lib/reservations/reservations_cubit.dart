import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import '../app/session_user.dart';
import '../realtime/realtime_events.dart';

@immutable
class ReservationsState {
  const ReservationsState({this.items = const [], this.loading = true, this.busyId, this.error, this.notice});

  /// Reservas del pasajero, próximas primero.
  final List<Reservation> items;
  final bool loading;
  final String? busyId;
  final String? error;

  /// Último aviso del backend (recordatorio, vencida, conductor no disponible).
  final ReservationNotice? notice;

  List<Reservation> get open => [
    for (final r in items)
      if (r.open) r,
  ];

  /// La próxima reserva abierta, para el aviso del inicio.
  Reservation? get next => open.isEmpty ? null : open.reduce((a, b) => a.scheduledAt.isBefore(b.scheduledAt) ? a : b);

  ReservationsState copyWith({
    List<Reservation>? items,
    bool? loading,
    String? Function()? busyId,
    String? Function()? error,
    ReservationNotice? notice,
  }) => ReservationsState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    busyId: busyId != null ? busyId() : this.busyId,
    error: error != null ? error() : this.error,
    notice: notice ?? this.notice,
  );
}

/// Reservas del pasajero (010, US1): lista, cancelar y avisos en vivo por su canal.
class ReservationsCubit extends Cubit<ReservationsState> {
  ReservationsCubit(this._api, {this._realtime = const NoRealtimeEvents()}) : super(const ReservationsState());

  final KyqApiClient _api;
  final RealtimeEvents _realtime;
  StreamSubscription<RealtimeEvent>? _events;

  Future<void> start() async {
    await load();
    final session = await _api.currentSession();
    final myId = session == null ? null : userIdFromAccessToken(session.accessToken);
    if (isClosed || myId == null) return;
    _events = _realtime.subscribe(Channels.user(myId)).listen((e) {
      if (e is ReservationNotice && !isClosed) emit(state.copyWith(notice: e));
      if (e is ReservationUpdated || e is ReservationNotice) unawaited(load());
    }, onError: (Object _) {});
  }

  Future<void> load() async {
    try {
      final items = await _api.reservations();
      if (!isClosed) emit(state.copyWith(items: items, loading: false));
    } on ApiException {
      if (!isClosed) emit(state.copyWith(loading: false, error: () => 'No pudimos cargar tus reservas.'));
    }
  }

  Future<void> cancel(Reservation r) async {
    if (state.busyId != null) return;
    emit(state.copyWith(busyId: () => r.id, error: () => null));
    try {
      await _api.cancelReservation(r.id);
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            error: () => e.code == 'invalid_state'
                ? 'La reserva ya cambió; la actualizamos.'
                : 'No pudimos cancelar la reserva.',
          ),
        );
      }
    }
    if (isClosed) return;
    emit(state.copyWith(busyId: () => null));
    await load();
  }

  @override
  Future<void> close() async {
    await _events?.cancel();
    return super.close();
  }
}
