import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

String _message(ApiException e) => switch (e.code) {
  'network' => 'Sin conexión con el servidor.',
  'invalid_state' => 'El pago ya cambió de estado. Recarga la lista.',
  'exceeds_balance' => 'El giro supera el saldo por girar del conductor.',
  _ => e.message.isEmpty ? 'Algo salió mal (${e.code}).' : e.message,
};

/// Filtro de incidencias: no pagado, en disputa y en revisión (FR-017).
const issuesFilter = 'issues';

class TripPaymentsState {
  const TripPaymentsState({this.items = const [], this.filter = issuesFilter, this.loading = false, this.error});

  final List<TripPayment> items;

  /// Estado del pago (`pending`, `paid`…), [issuesFilter] o null (todos).
  final String? filter;
  final bool loading;
  final String? error;
}

/// Pagos de viajes por estado, con resolución de incidencias y anulación (004, FR-014, FR-017).
class TripPaymentsCubit extends Cubit<TripPaymentsState> {
  TripPaymentsCubit(this._api) : super(const TripPaymentsState());

  final KyqApiClient _api;

  Future<void> load() async {
    final filter = state.filter;
    emit(TripPaymentsState(items: state.items, filter: filter, loading: true));
    try {
      final items = await _api.adminTripPayments(status: filter);
      emit(TripPaymentsState(items: items, filter: filter));
    } on ApiException catch (e) {
      emit(TripPaymentsState(items: state.items, filter: filter, error: _message(e)));
    }
  }

  Future<void> setFilter(String? filter) {
    emit(TripPaymentsState(filter: filter));
    return load();
  }

  /// Cierra una disputa o un no pagado: [paid] true = pagado en efectivo.
  Future<bool> resolve(String id, {required bool paid, required String note}) =>
      _run(() => _api.adminResolveTripPayment(id, paid: paid, note: note));

  Future<bool> voidPayment(String id, String reason) => _run(() => _api.adminVoidTripPayment(id, reason));

  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      await load();
      return true;
    } on ApiException catch (e) {
      emit(TripPaymentsState(items: state.items, filter: state.filter, error: _message(e)));
      return false;
    }
  }
}

class SettlementsState {
  const SettlementsState({this.rows = const [], this.loading = false, this.error});

  final List<SettlementRow> rows;
  final bool loading;
  final String? error;
}

/// Saldo por girar de cada conductor (004, FR-012).
class SettlementsCubit extends Cubit<SettlementsState> {
  SettlementsCubit(this._api) : super(const SettlementsState());

  final KyqApiClient _api;

  Future<void> load() async {
    emit(SettlementsState(rows: state.rows, loading: true));
    try {
      emit(SettlementsState(rows: await _api.adminSettlements()));
    } on ApiException catch (e) {
      emit(SettlementsState(rows: state.rows, error: _message(e)));
    }
  }
}

class DriverLedgerState {
  const DriverLedgerState({this.settlement, this.loading = false, this.error});

  final DriverSettlement? settlement;
  final bool loading;
  final String? error;
}

/// Libro de un conductor y registro de giros hechos por fuera (004, FR-012, FR-013).
class DriverLedgerCubit extends Cubit<DriverLedgerState> {
  DriverLedgerCubit(this._api, this.driverId) : super(const DriverLedgerState());

  final KyqApiClient _api;
  final String driverId;

  Future<void> load() async {
    emit(DriverLedgerState(settlement: state.settlement, loading: true));
    try {
      emit(DriverLedgerState(settlement: await _api.adminDriverSettlement(driverId)));
    } on ApiException catch (e) {
      emit(DriverLedgerState(settlement: state.settlement, error: _message(e)));
    }
  }

  /// Registra un giro; no puede superar el saldo (el backend lo rechaza con 409).
  Future<bool> payout({
    required int amountMinor,
    required String currency,
    required String reference,
    String? note,
  }) async {
    try {
      await _api.adminRegisterPayout(
        driverId,
        amountMinor: amountMinor,
        currency: currency,
        reference: reference,
        note: note,
      );
      await load();
      return true;
    } on ApiException catch (e) {
      emit(DriverLedgerState(settlement: state.settlement, error: _message(e)));
      return false;
    }
  }
}
