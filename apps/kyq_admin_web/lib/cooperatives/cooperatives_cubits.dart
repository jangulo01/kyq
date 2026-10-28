import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

String cooperativeErrorMessage(ApiException e) => switch (e.code) {
  'network' => 'Sin conexión con el servidor.',
  'cooperative_name_taken' => 'Ya existe una cooperativa con ese nombre.',
  'already_in_cooperative' => 'Ese conductor ya pertenece a una cooperativa o tiene una solicitud en curso.',
  'reason_required' => 'Escribe el motivo del rechazo.',
  'not_pending' => 'Esa solicitud ya fue decidida. Recarga.',
  'not_member' => 'Ese conductor ya no es miembro.',
  _ => e.message.isEmpty ? 'Algo salió mal (${e.code}).' : e.message,
};

class CooperativesState {
  const CooperativesState({this.cooperatives = const [], this.loading = false, this.error});

  final List<Cooperative> cooperatives;
  final bool loading;
  final String? error;
}

/// Lista y alta de cooperativas (006, FR-001, FR-002).
class CooperativesCubit extends Cubit<CooperativesState> {
  CooperativesCubit(this._api) : super(const CooperativesState());

  final KyqApiClient _api;

  Future<void> load() async {
    emit(CooperativesState(cooperatives: state.cooperatives, loading: true));
    try {
      emit(CooperativesState(cooperatives: await _api.adminCooperatives()));
    } on ApiException catch (e) {
      emit(CooperativesState(cooperatives: state.cooperatives, error: cooperativeErrorMessage(e)));
    }
  }

  /// Devuelve null si se creó, o el mensaje de error para el formulario.
  Future<String?> create({required String name, required String cityCode, String? nit}) async {
    try {
      await _api.adminCreateCooperative(name: name.trim(), cityCode: cityCode.trim(), nit: nit);
      await load();
      return null;
    } on ApiException catch (e) {
      return cooperativeErrorMessage(e);
    }
  }
}

class CooperativeDetailState {
  const CooperativeDetailState({
    this.detail,
    this.drivers = const [],
    this.loading = false,
    this.busy = false,
    this.error,
  });

  final CooperativeDetail? detail;

  /// Conductores para agregar directamente (FR-006).
  final List<AdminDriver> drivers;
  final bool loading;
  final bool busy;
  final String? error;

  CooperativeDetailState copyWith({
    CooperativeDetail? detail,
    List<AdminDriver>? drivers,
    bool? loading,
    bool? busy,
    String? Function()? error,
  }) => CooperativeDetailState(
    detail: detail ?? this.detail,
    drivers: drivers ?? this.drivers,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    error: error != null ? error() : this.error,
  );
}

/// Detalle de una cooperativa: solicitudes, miembros, coordinadores, retiro y suspensión
/// (006, FR-001, FR-005, FR-006).
class CooperativeDetailCubit extends Cubit<CooperativeDetailState> {
  CooperativeDetailCubit(this._api, this.cooperativeId) : super(const CooperativeDetailState());

  final KyqApiClient _api;
  final String cooperativeId;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final detail = await _api.adminCooperative(cooperativeId);
      final drivers = await _api.adminListDrivers();
      emit(CooperativeDetailState(detail: detail, drivers: drivers));
    } on ApiException catch (e) {
      emit(state.copyWith(loading: false, error: () => cooperativeErrorMessage(e)));
    }
  }

  Future<bool> decide(String membershipId, {required bool approve, String? reason}) =>
      _act(() => _api.adminDecideMembership(membershipId, approve: approve, reason: reason));

  Future<bool> setRole(String driverId, CooperativeRole role) =>
      _act(() => _api.adminSetCooperativeRole(cooperativeId, driverId, role));

  Future<bool> remove(String driverId) => _act(() => _api.adminRemoveCooperativeMember(cooperativeId, driverId));

  Future<bool> addMember(String driverId) => _act(() => _api.adminAddCooperativeMember(cooperativeId, driverId));

  /// Suspende o reactiva: suspendida no recibe delegaciones ni tiene canal de grupo.
  Future<bool> setStatus(CooperativeStatus status) =>
      _act(() => _api.adminUpdateCooperative(cooperativeId, status: status));

  Future<bool> _act(Future<Object?> Function() action) async {
    if (state.busy) return false;
    emit(state.copyWith(busy: true, error: () => null));
    try {
      await action();
      emit(state.copyWith(detail: await _api.adminCooperative(cooperativeId), busy: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, error: () => cooperativeErrorMessage(e)));
      return false;
    }
  }
}
