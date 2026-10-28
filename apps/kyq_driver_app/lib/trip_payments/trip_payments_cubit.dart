import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import 'trip_payment_cubit.dart';

class TripPaymentsState {
  const TripPaymentsState({this.settlement, this.methods, this.loading = false, this.busy = false, this.message});

  final DriverSettlement? settlement;
  final PaymentMethods? methods;
  final bool loading;
  final bool busy;
  final String? message;

  TripPaymentsState copyWith({
    DriverSettlement? settlement,
    PaymentMethods? methods,
    bool? loading,
    bool? busy,
    String? message,
  }) => TripPaymentsState(
    settlement: settlement ?? this.settlement,
    methods: methods ?? this.methods,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    message: message,
  );
}

/// "Pagos de viajes" del conductor (004): medios aceptados, saldo por girar, libro y pagos
/// recientes con sus acciones (FR-005, FR-006, FR-013, FR-018).
class TripPaymentsCubit extends Cubit<TripPaymentsState> {
  TripPaymentsCubit(this._api) : super(const TripPaymentsState(loading: true));

  final KyqApiClient _api;

  Future<void> load() async {
    emit(state.copyWith(loading: true, message: state.message));
    try {
      final settlement = await _api.driverSettlement();
      final methods = await _api.driverPaymentMethods();
      if (!isClosed) emit(state.copyWith(settlement: settlement, methods: methods, loading: false));
    } on ApiException {
      if (isClosed) return;
      emit(state.copyWith(loading: false, message: 'No pudimos cargar tus pagos. Desliza para reintentar.'));
    }
  }

  /// Cambia los medios aceptados; al menos uno (el backend lo exige también).
  Future<void> setMethods({required bool cash, required bool bold}) async {
    if (!cash && !bold) {
      emit(state.copyWith(message: 'Debes aceptar al menos un medio de pago.'));
      return;
    }
    emit(state.copyWith(busy: true));
    try {
      final methods = await _api.setDriverPaymentMethods(cash: cash, bold: bold);
      if (!isClosed) emit(state.copyWith(methods: methods, busy: false, message: 'Medios de pago guardados.'));
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false, message: driverPaymentError(e)));
    }
  }

  Future<void> act(String tripId, DriverPaymentAction action) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    String? message;
    try {
      await runDriverPaymentAction(_api, tripId, action);
    } on ApiException catch (e) {
      message = driverPaymentError(e);
    }
    if (isClosed) return;
    emit(state.copyWith(busy: false, message: message));
    await load();
  }
}
