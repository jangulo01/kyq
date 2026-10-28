import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

@immutable
class TripInspectionState {
  const TripInspectionState({this.trip, this.loading = true, this.error});

  final TripInspection? trip;
  final bool loading;
  final String? error;
}

/// Detalle de un viaje desde la torre (009, US1). Mientras el viaje está activo se vuelve a
/// pedir cada [refreshEvery] para seguir la posición (FR-003: < 10 s); al terminar, se detiene.
class TripInspectionCubit extends Cubit<TripInspectionState> {
  TripInspectionCubit(this._api, this.tripId, {this.refreshEvery = const Duration(seconds: 5)})
    : super(const TripInspectionState());

  final KyqApiClient _api;
  final String tripId;
  final Duration? refreshEvery;
  Timer? _timer;

  Future<void> load() async {
    try {
      final trip = await _api.inspectTrip(tripId);
      if (isClosed) return;
      emit(TripInspectionState(trip: trip, loading: false));
      final every = refreshEvery;
      if (trip.active && every != null) {
        _timer ??= Timer.periodic(every, (_) => load());
      } else {
        _timer?.cancel();
        _timer = null;
      }
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        TripInspectionState(
          trip: state.trip,
          loading: false,
          error: e.code == 'trip_not_found' ? 'Viaje no encontrado.' : 'No pudimos cargar el viaje.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
