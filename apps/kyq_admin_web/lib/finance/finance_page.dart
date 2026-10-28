import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

String _message(ApiException e) => switch (e.code) {
  'network' => 'Sin conexión con el servidor.',
  _ => e.message.isEmpty ? 'Algo salió mal (${e.code}).' : e.message,
};

/// Meses que se pueden ver de una vez.
const financeRanges = [3, 6, 12, 24];

class FinanceState {
  const FinanceState({required this.to, this.months = 6, this.report, this.loading = false, this.error});

  /// Último mes mostrado.
  final DateTime to;
  final int months;
  final FinanceReport? report;
  final bool loading;
  final String? error;

  FinanceMonth? get latest => report == null || report!.months.isEmpty ? null : report!.months.last;
}

/// Suscripciones frente a infraestructura por mes (T021, FR-007–FR-009).
class FinanceCubit extends Cubit<FinanceState> {
  FinanceCubit(this._api, {DateTime? now})
    : super(FinanceState(to: DateTime((now ?? DateTime.now()).year, (now ?? DateTime.now()).month)));

  final KyqApiClient _api;

  Future<void> load() async {
    final to = state.to;
    final months = state.months;
    emit(FinanceState(to: to, months: months, report: state.report, loading: true));
    try {
      final report = await _api.adminFinance(to: to, months: months);
      if (state.to == to && state.months == months) emit(FinanceState(to: to, months: months, report: report));
    } on ApiException catch (e) {
      emit(FinanceState(to: to, months: months, report: state.report, error: _message(e)));
    }
  }

  Future<void> shift(int months) {
    emit(FinanceState(to: DateTime(state.to.year, state.to.month + months), months: state.months));
    return load();
  }

  Future<void> setMonths(int months) {
    emit(FinanceState(to: state.to, months: months));
    return load();
  }
}

String _pct(double? v) => v == null ? '—' : '${v.toStringAsFixed(1).replaceAll('.', ',')} %';

DateTime _month(String m) => DateTime(int.parse(m.substring(0, 4)), int.parse(m.substring(5, 7)));

/// Finanzas (T021): tarjetas del último mes, evolución por mes y enlace al detalle por conductor.
class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas: suscripciones frente a infraestructura'),
        actions: [
          TextButton.icon(
            key: const Key('finance.costs'),
            onPressed: () => context.push('/costs'),
            icon: const Icon(Icons.query_stats),
            label: const Text('Costos por conductor'),
          ),
          IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load),
        ],
      ),
      body: BlocBuilder<FinanceCubit, FinanceState>(
        builder: (context, state) {
          final report = state.report;
          final latest = state.latest;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    key: const Key('finance.previous'),
                    tooltip: 'Mes anterior',
                    onPressed: () => cubit.shift(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Hasta ${formatMonth(state.to)}', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    key: const Key('finance.next'),
                    tooltip: 'Mes siguiente',
                    onPressed: () => cubit.shift(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  SegmentedButton<int>(
                    key: const Key('finance.range'),
                    segments: [for (final m in financeRanges) ButtonSegment(value: m, label: Text('$m meses'))],
                    selected: {state.months},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => cubit.setMonths(s.first),
                  ),
                ],
              ),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) Padding(padding: const EdgeInsets.all(8), child: Text(state.error!)),
              if (report != null && latest != null) ...[
                const SizedBox(height: 8),
                if (latest.ratesMissing)
                  Card(
                    key: const Key('finance.ratesMissing'),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: const ListTile(
                      leading: Icon(Icons.warning_amber),
                      title: Text('Faltan tarifas de costo en este mes'),
                      subtitle: Text('El costo de infraestructura se muestra en 0. Configúralas en Costos → Tarifas.'),
                    ),
                  ),
                _Cards(month: latest, currency: report.currency),
                const SizedBox(height: 16),
                Text('Evolución mensual', style: Theme.of(context).textTheme.titleMedium),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _Table(report: report),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total del periodo: ingresos ${formatSignedMoney(report.totals.revenueMinor, report.currency)}, '
                  'costo ${formatSignedMoney(report.totals.infraCostMinor, report.currency)}, '
                  'margen ${formatSignedMoney(report.totals.marginMinor, report.currency)} (${_pct(report.totals.marginPct)}).',
                  key: const Key('finance.totals'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Cards extends StatelessWidget {
  const _Cards({required this.month, required this.currency});

  final FinanceMonth month;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String money(num? v) => v == null ? '—' : formatSignedMoney(v, currency);
    final cards = [
      ('revenue', 'Ingresos por suscripción', money(month.revenueMinor), null),
      ('cost', 'Costo de infraestructura', money(month.infraCostMinor), null),
      (
        'margin',
        'Margen',
        '${money(month.marginMinor)} (${_pct(month.marginPct)})',
        month.marginMinor < 0 ? scheme.error : null,
      ),
      ('costPerDriver', 'Costo por conductor activo', money(month.costPerActiveDriverMinor), null),
      ('revenuePerDriver', 'Ingreso por conductor que paga', money(month.revenuePerPayingDriverMinor), null),
      (
        'drivers',
        'Conductores',
        '${month.activeDrivers} activos · ${month.payingDrivers} pagan · ${month.drivers} en total',
        null,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formatMonth(_month(month.month)), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (key, label, value, color) in cards)
              SizedBox(
                width: 260,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          value,
                          key: Key('finance.card.$key'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (month.negativeMarginDrivers > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${month.negativeMarginDrivers} conductores con margen negativo este mes.',
              key: const Key('finance.negativeDrivers'),
              style: TextStyle(color: scheme.error),
            ),
          ),
      ],
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.report});

  final FinanceReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String money(num? v) => v == null ? '—' : formatSignedMoney(v, report.currency);
    double concept(FinanceMonth m, String c) =>
        m.costByConcept.where((x) => x.concept == c).fold(0, (sum, x) => sum + x.costMinor);
    return DataTable(
      columns: [
        const DataColumn(label: Text('Mes')),
        const DataColumn(label: Text('Ingresos'), numeric: true),
        for (final c in CostConcepts.all) DataColumn(label: Text(costConceptLabel(c)), numeric: true),
        const DataColumn(label: Text('Costo total'), numeric: true),
        const DataColumn(label: Text('Margen'), numeric: true),
        const DataColumn(label: Text('% margen'), numeric: true),
        const DataColumn(label: Text('Activos'), numeric: true),
        const DataColumn(label: Text('Pagan'), numeric: true),
      ],
      rows: [
        for (final m in report.months.reversed)
          DataRow(
            key: ValueKey('finance.row.${m.month}'),
            color: m.marginMinor < 0 ? WidgetStatePropertyAll(scheme.errorContainer) : null,
            cells: [
              DataCell(Text(formatMonth(_month(m.month)))),
              DataCell(Text(money(m.revenueMinor))),
              for (final c in CostConcepts.all) DataCell(Text(money(concept(m, c)))),
              DataCell(Text(money(m.infraCostMinor))),
              DataCell(Text(money(m.marginMinor), key: Key('finance.margin.${m.month}'))),
              DataCell(Text(_pct(m.marginPct))),
              DataCell(Text('${m.activeDrivers}')),
              DataCell(Text('${m.payingDrivers}')),
            ],
          ),
      ],
    );
  }
}
