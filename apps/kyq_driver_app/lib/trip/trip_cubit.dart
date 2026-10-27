import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import 'trip_texts.dart';

class TripState {
  const TripState({this.trip, this.loading = false, this.busy = false, this.error});

  final Trip? trip;
  final bool loading;

  /// Hay una acción en curso.
  final bool busy;
  final String? error;

  TripState copyWith({Trip? trip, bool? loading, bool? busy, String? error}) =>
      TripState(trip: trip ?? this.trip, loading: loading ?? this.loading, busy: busy ?? this.busy, error: error);
}

/// Un viaje del conductor desde que responde la oferta hasta el resumen (T058, T059, T060).
///
/// Recarga el viaje con `getTrip` en cada `trip.status` o `trip.fare_proposal` de este viaje.
class TripCubit extends Cubit<TripState> {
  TripCubit(this._api, Stream<RealtimeEvent> events, this.tripId, {Trip? initial})
    : super(TripState(trip: initial, loading: initial == null)) {
    _sub = events.listen(_onEvent);
  }

  final KyqApiClient _api;
  final String tripId;
  late final StreamSubscription<RealtimeEvent> _sub;

  void _onEvent(RealtimeEvent e) {
    final id = switch (e) {
      TripStatusChanged(:final tripId) => tripId,
      FareProposed(:final tripId) => tripId,
      TripOfferClosed(:final tripId) => tripId,
      _ => null,
    };
    if (id == tripId) unawaited(refresh());
  }

  Future<void> refresh() async {
    try {
      final trip = await _api.getTrip(tripId);
      if (!isClosed) emit(state.copyWith(trip: trip, loading: false, error: state.error));
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(loading: false, error: tripErrorMessage(e)));
    }
  }

  // Oferta de vuelta (el pasajero rechazó negociar): se acepta con la sugerida o se rechaza.

  Future<void> accept() => _run(() => _api.acceptTrip(tripId));

  Future<void> acceptWithFare(int pesos) => _run(() => _api.acceptTrip(tripId, fareMinor: pesos * 100));

  Future<void> reject() => _run(() => _api.rejectTrip(tripId));

  // Negociación (FR-010c).

  Future<void> propose(int amountMinor) => _run(() async {
    await _api.propose(tripId, amountMinor);
    return _api.getTrip(tripId);
  });

  Future<void> acceptProposal() async {
    final proposal = state.trip?.openProposal;
    if (proposal == null) return;
    await _run(() => _api.decideProposal(tripId, proposal.id, accept: true));
  }

  Future<void> abandon() => cancel();

  // Ciclo del viaje (FR-013).

  Future<void> arrive() => _run(() => _api.arrive(tripId));

  Future<void> start() => _run(() => _api.startTrip(tripId));

  Future<void> complete() => _run(() => _api.completeTrip(tripId));

  Future<void> cancel() => _run(() => _api.cancelTrip(tripId));

  Future<void> _run(Future<Trip> Function() action) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      final trip = await action();
      emit(state.copyWith(trip: trip, busy: false));
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, error: tripErrorMessage(e)));
      // El estado cambió en el servidor: mostramos el actual.
      if (e.code != 'network') await refresh();
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
