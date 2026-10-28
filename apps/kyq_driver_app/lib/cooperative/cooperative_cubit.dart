import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

class CooperativeState {
  const CooperativeState({this.mine, this.available = const [], this.loading = false, this.busy = false, this.error});

  /// Membresía, compañeros y solicitudes; null hasta la primera carga.
  final DriverCooperative? mine;

  /// Cooperativas activas a las que puede pedir entrar (solo sin membresía en curso).
  final List<Cooperative> available;
  final bool loading;

  /// Hay una acción en curso; los botones se desactivan.
  final bool busy;
  final String? error;

  CooperativeState copyWith({
    DriverCooperative? mine,
    List<Cooperative>? available,
    bool? loading,
    bool? busy,
    String? Function()? error,
  }) => CooperativeState(
    mine: mine ?? this.mine,
    available: available ?? this.available,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    error: error != null ? error() : this.error,
  );
}

/// "Mi cooperativa" (006, FR-004–FR-007): pedir entrar, retirar la solicitud, salir y, como
/// coordinador, decidir solicitudes y retirar miembros. Recarga con `cooperative.membership`.
class CooperativeCubit extends Cubit<CooperativeState> {
  CooperativeCubit(this._api, Stream<RealtimeEvent> events) : super(const CooperativeState(loading: true)) {
    _sub = events.listen((e) {
      if (e is CooperativeMembershipChanged) unawaited(load());
    });
  }

  final KyqApiClient _api;
  late final StreamSubscription<RealtimeEvent> _sub;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final mine = await _api.myCooperative();
      final available = mine.isMember || mine.isPending ? const <Cooperative>[] : await _api.cooperatives();
      if (isClosed) return;
      emit(CooperativeState(mine: mine, available: available));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: () => _message(e)));
    }
  }

  Future<void> join(String cooperativeId) => _act(() => _api.requestToJoinCooperative(cooperativeId));

  Future<void> withdraw() => _act(_api.withdrawCooperativeRequest);

  Future<void> leave() => _act(_api.leaveCooperative);

  /// Coordinador: aprueba o rechaza con [reason] una solicitud.
  Future<void> decide(String membershipId, {required bool approve, String? reason}) =>
      _act(() => _api.decideCooperativeRequest(membershipId, approve: approve, reason: reason));

  /// Coordinador: retira a un miembro que no es coordinador.
  Future<void> remove(String driverId) => _act(() => _api.removeCooperativeMember(driverId));

  Future<void> _act(Future<Object?> Function() action) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, error: () => null));
    try {
      await action();
      if (isClosed) return;
      emit(state.copyWith(busy: false));
      await load();
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(busy: false));
      await load();
      if (!isClosed) emit(state.copyWith(error: () => _message(e)));
    }
  }

  String _message(ApiException e) => switch (e.code) {
    'already_in_cooperative' => 'Ya perteneces a una cooperativa o tienes una solicitud en curso.',
    'not_found' => 'Esa cooperativa o solicitud ya no está disponible.',
    'not_pending' => 'Esa solicitud ya fue decidida.',
    'reason_required' => 'Indica el motivo del rechazo.',
    'forbidden' => 'Solo un coordinador puede hacerlo.',
    'not_member' => 'Ese conductor ya no es miembro.',
    'network' => 'Sin conexión con el servidor. Revisa tu internet.',
    _ => 'No pudimos completar la acción. Inténtalo de nuevo.',
  };

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}

/// Presencia de un compañero en texto.
String presenceLabel(String presence) => switch (presence) {
  'free' => 'Libre',
  'busy' => 'Ocupado',
  _ => 'Desconectado',
};
