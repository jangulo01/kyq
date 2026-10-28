import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

@immutable
class AgendaState {
  const AgendaState({this.items = const [], this.loading = true, this.busyId, this.error});

  final List<Reservation> items;
  final bool loading;

  /// Reserva con una acción en curso.
  final String? busyId;
  final String? error;

  List<Reservation> get pending => [
    for (final r in items)
      if (r.status == ReservationStatus.pending) r,
  ];
  List<Reservation> get confirmed => [
    for (final r in items)
      if (r.status == ReservationStatus.confirmed) r,
  ];
}

String _agendaError(ApiException e) => switch (e.code) {
  'invalid_state' => 'La reserva ya cambió; actualizamos tu agenda.',
  'network' => 'Sin conexión. Inténtalo de nuevo.',
  _ => 'No pudimos completar la acción.',
};

/// Agenda del conductor (010, US1): reservas pendientes y confirmadas; se actualiza en vivo.
class AgendaCubit extends Cubit<AgendaState> {
  AgendaCubit(this._api, Stream<RealtimeEvent> events) : super(const AgendaState()) {
    _sub = events.listen((e) {
      if (e is ReservationUpdated) load();
    }, onError: (Object _) {});
  }

  final KyqApiClient _api;
  late final StreamSubscription<RealtimeEvent> _sub;

  Future<void> load() async {
    try {
      final items = await _api.driverAgenda();
      if (!isClosed) emit(AgendaState(items: items, loading: false));
    } on ApiException catch (e) {
      if (!isClosed) emit(AgendaState(items: state.items, loading: false, error: _agendaError(e)));
    }
  }

  Future<void> accept(Reservation r) => _act(r, () => _api.acceptReservation(r.id));

  Future<void> reject(Reservation r) => _act(r, () => _api.rejectReservation(r.id));

  Future<void> cancel(Reservation r) => _act(r, () => _api.driverCancelReservation(r.id));

  Future<void> _act(Reservation r, Future<Reservation> Function() action) async {
    if (state.busyId != null) return;
    emit(AgendaState(items: state.items, loading: false, busyId: r.id));
    try {
      await action();
      await load();
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(AgendaState(items: state.items, loading: false, error: _agendaError(e)));
      await load();
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
