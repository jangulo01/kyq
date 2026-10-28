import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

String _message(ApiException e) => switch (e.code) {
  'network' => 'Sin conexión con el servidor.',
  _ => e.message.isEmpty ? 'Algo salió mal (${e.code}).' : e.message,
};

class CostsState {
  const CostsState({required this.month, this.rows = const [], this.loading = false, this.error});

  final DateTime month;

  /// Peor margen primero: lo que hay que mirar está arriba.
  final List<CostBreakdown> rows;
  final bool loading;
  final String? error;

  int get negative => rows.where((r) => r.negativeMargin ?? r.marginMinor < 0).length;
}

/// Costos por conductor y mes con su margen (T037, FR-026, RN-KYQ-004).
class CostsCubit extends Cubit<CostsState> {
  CostsCubit(this._api, {DateTime? now})
    : super(CostsState(month: DateTime((now ?? DateTime.now()).year, (now ?? DateTime.now()).month)));

  final KyqApiClient _api;

  Future<void> load() async {
    final month = state.month;
    emit(CostsState(month: month, rows: state.rows, loading: true));
    try {
      final rows = await _api.adminCosts(month);
      rows.sort((a, b) => a.marginMinor.compareTo(b.marginMinor));
      if (state.month == month) emit(CostsState(month: month, rows: rows));
    } on ApiException catch (e) {
      emit(CostsState(month: month, rows: state.rows, error: _message(e)));
    }
  }

  Future<void> shift(int months) {
    emit(CostsState(month: DateTime(state.month.year, state.month.month + months)));
    return load();
  }
}

class CostRatesState {
  const CostRatesState({this.rates = const [], this.loading = false, this.error});

  final List<CostRate> rates;
  final bool loading;
  final String? error;
}

/// Tarifas de costo por concepto con fecha de vigencia (T037, FR-024).
class CostRatesCubit extends Cubit<CostRatesState> {
  CostRatesCubit(this._api) : super(const CostRatesState());

  final KyqApiClient _api;

  Future<void> load() => _run(() async {});

  Future<bool> add(CostRate rate) => _run(() => _api.adminSetCostRate(rate));

  Future<bool> _run(Future<void> Function() action) async {
    emit(CostRatesState(rates: state.rates, loading: true));
    try {
      await action();
      final rates = await _api.adminCostRates();
      rates.sort((a, b) {
        final c = CostConcepts.all.indexOf(a.concept).compareTo(CostConcepts.all.indexOf(b.concept));
        return c != 0 ? c : b.effectiveFrom.compareTo(a.effectiveFrom);
      });
      emit(CostRatesState(rates: rates));
      return true;
    } on ApiException catch (e) {
      emit(CostRatesState(rates: state.rates, error: _message(e)));
      return false;
    }
  }
}

/// Tarifa vigente de cada concepto en [day]: la de vigencia más reciente que no sea futura.
Set<CostRate> currentRates(List<CostRate> rates, DateTime day) {
  final current = <String, CostRate>{};
  for (final r in rates) {
    if (r.effectiveFrom.isAfter(day)) continue;
    final key = '${r.concept}/${r.currency}';
    final best = current[key];
    if (best == null || r.effectiveFrom.isAfter(best.effectiveFrom)) current[key] = r;
  }
  return current.values.toSet();
}
