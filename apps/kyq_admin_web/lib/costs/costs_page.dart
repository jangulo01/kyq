import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'costs_cubits.dart';

/// El backend lo marca (`negative_margin`); si no viene, se deduce del margen.
bool _negative(CostBreakdown r) => r.negativeMargin ?? r.marginMinor < 0;

double _cost(CostBreakdown r, String concept) =>
    r.items.where((i) => i.concept == concept).fold(0, (sum, i) => sum + i.costMinor);

/// Costos por conductor del mes: cobrado, costo por concepto, total y margen; los de margen
/// negativo, destacados (T037, FR-026).
class CostsPage extends StatelessWidget {
  const CostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CostsCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Costos por conductor'),
        actions: [
          TextButton.icon(
            key: const Key('costs.rates'),
            onPressed: () => context.push('/costs/rates'),
            icon: const Icon(Icons.tune),
            label: const Text('Tarifas de costo'),
          ),
          IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load),
        ],
      ),
      body: BlocBuilder<CostsCubit, CostsState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('costs.previous'),
                      tooltip: 'Mes anterior',
                      onPressed: () => cubit.shift(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(formatMonth(state.month), style: theme.textTheme.titleMedium),
                    IconButton(
                      key: const Key('costs.next'),
                      tooltip: 'Mes siguiente',
                      onPressed: () => cubit.shift(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                    const Spacer(),
                    if (state.negative > 0)
                      Text(
                        '${state.negative} con margen negativo',
                        key: const Key('costs.negativeCount'),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                  ],
                ),
              ),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) Padding(padding: const EdgeInsets.all(16), child: Text(state.error!)),
              Expanded(
                child: state.rows.isEmpty
                    ? Center(child: Text(state.loading ? '' : 'Sin datos de uso en este mes.'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: _table(context, state)),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _table(BuildContext context, CostsState state) {
    final scheme = Theme.of(context).colorScheme;
    String money(num v, String c) => formatSignedMoney(v, c);
    return DataTable(
      columns: [
        const DataColumn(label: Text('Conductor')),
        const DataColumn(label: Text('Cobrado'), numeric: true),
        for (final c in CostConcepts.all) DataColumn(label: Text(costConceptLabel(c)), numeric: true),
        const DataColumn(label: Text('Costo total'), numeric: true),
        const DataColumn(label: Text('Margen'), numeric: true),
      ],
      rows: [
        for (final r in state.rows)
          DataRow(
            key: ValueKey('costs.row.${r.driverId}'),
            color: _negative(r) ? WidgetStatePropertyAll(scheme.errorContainer) : null,
            cells: [
              DataCell(Text(r.displayName ?? r.driverId ?? '—')),
              DataCell(Text(money(r.paidMinor, r.currency))),
              for (final c in CostConcepts.all) DataCell(Text(money(_cost(r, c), r.currency))),
              DataCell(Text(money(r.totalCostMinor, r.currency))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_negative(r)) Icon(Icons.warning_amber, size: 16, color: scheme.error),
                    Text(
                      money(r.marginMinor, r.currency),
                      key: Key('costs.margin.${r.driverId}'),
                      style: _negative(r) ? TextStyle(color: scheme.error, fontWeight: FontWeight.bold) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
