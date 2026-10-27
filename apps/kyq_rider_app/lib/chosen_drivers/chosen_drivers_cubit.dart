import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

class ChosenDriversState {
  const ChosenDriversState({this.drivers = const [], this.loading = false, this.error});

  final List<ChosenDriver> drivers;
  final bool loading;
  final String? error;
}

/// Lista "Mis Conductores Elegidos" (FR-006, FR-008). La presencia en vivo llega con US2.
class ChosenDriversCubit extends Cubit<ChosenDriversState> {
  ChosenDriversCubit(this._api) : super(const ChosenDriversState(loading: true));

  final KyqApiClient _api;

  Future<void> load() async {
    emit(ChosenDriversState(drivers: state.drivers, loading: true));
    try {
      emit(ChosenDriversState(drivers: await _api.chosenDrivers()));
    } on ApiException {
      emit(ChosenDriversState(drivers: state.drivers, error: 'No pudimos cargar tus conductores.'));
    }
  }

  Future<void> remove(String driverId) async {
    final before = state.drivers;
    emit(ChosenDriversState(drivers: before.where((d) => d.driverId != driverId).toList()));
    try {
      await _api.removeChosenDriver(driverId);
    } on ApiException catch (e) {
      // 404: ya no estaba en la lista; la vista ya es correcta.
      if (e.statusCode != 404) {
        emit(ChosenDriversState(drivers: before, error: 'No pudimos eliminar al conductor.'));
      }
    }
  }
}
