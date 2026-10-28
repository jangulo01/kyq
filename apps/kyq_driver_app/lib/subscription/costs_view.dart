import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

/// "En qué se va tu suscripción" (T036, RN-KYQ-004): lo que costó en el mes lo que el conductor
/// usó (voz, tiempo real, rutas) más el fijo, frente a lo que pagó.
class CostsView extends StatefulWidget {
  const CostsView({super.key, this.now});

  /// Para las pruebas; por defecto, la fecha actual.
  final DateTime? now;

  @override
  State<CostsView> createState() => _CostsViewState();
}

class _CostsViewState extends State<CostsView> {
  late final DateTime _thisMonth = () {
    final now = widget.now ?? DateTime.now();
    return DateTime(now.year, now.month);
  }();
  late DateTime _month = _thisMonth;
  late Future<CostBreakdown> _costs = _load();

  Future<CostBreakdown> _load() => context.read<KyqApiClient>().driverCosts(month: _month);

  void _shift(int months) => setState(() {
    _month = DateTime(_month.year, _month.month + months);
    _costs = _load();
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('En qué se va tu suscripción', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Kyq no cobra comisión por viaje. Tu suscripción paga lo que usas de la plataforma, medido con tu propio uso:',
            ),
            Row(
              children: [
                IconButton(
                  key: const Key('costs.previous'),
                  tooltip: 'Mes anterior',
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(formatMonth(_month), textAlign: TextAlign.center, key: const Key('costs.month')),
                ),
                IconButton(
                  key: const Key('costs.next'),
                  tooltip: 'Mes siguiente',
                  onPressed: _month.isBefore(_thisMonth) ? () => _shift(1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            FutureBuilder<CostBreakdown>(
              future: _costs,
              builder: (context, snap) {
                if (snap.hasError) return const Text('No pudimos cargar tus costos de este mes.');
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _Breakdown(costs: snap.data!);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.costs});

  final CostBreakdown costs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = costs.currency;
    final bold = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);
    Widget row(String label, String value, {String? detail, TextStyle? style, Key? key}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: style),
                if (detail != null) Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(value, key: key, style: style),
        ],
      ),
    );
    final margin = costs.marginMinor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in costs.items)
          row(
            costConceptLabel(item.concept),
            formatSignedMoney(item.costMinor, currency),
            detail: costUsageUnit(item.concept).isEmpty
                ? null
                : '${formatCount(item.usage)} ${costUsageUnit(item.concept)}',
            key: Key('costs.item.${item.concept}'),
          ),
        const Divider(),
        row(
          'Costo total',
          formatSignedMoney(costs.totalCostMinor, currency),
          style: bold,
          key: const Key('costs.total'),
        ),
        row('Pagaste', formatSignedMoney(costs.paidMinor, currency), key: const Key('costs.paid')),
        row(
          margin >= 0 ? 'Mantenimiento y mejoras de Kyq' : 'Kyq cubre la diferencia',
          formatSignedMoney(margin.abs(), currency),
          detail: margin >= 0 ? 'Lo que queda tras los costos medidos' : 'Este mes usaste más de lo que pagaste',
          key: const Key('costs.margin'),
        ),
      ],
    );
  }
}
