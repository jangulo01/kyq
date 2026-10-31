import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'costs_cubits.dart';

/// Millonésimas de unidad mínima por peso: 1 peso = 100 centavos × 1 000 000.
const _microPerPeso = 100 * 1000000;

/// Costo unitario en pesos con hasta 4 decimales: el evento en tiempo real cuesta fracciones de
/// centavo.
String formatUnitCost(int unitCostMicro) {
  final pesos = unitCostMicro / _microPerPeso;
  var text = pesos.toStringAsFixed(4);
  text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  return '\$ ${text.replaceAll('.', ',')}';
}

/// Convierte "20,5" o "0.0004" pesos a millonésimas de unidad mínima; null si no es un número.
int? parseUnitCost(String text) {
  final v = double.tryParse(text.trim().replaceAll(',', '.'));
  if (v == null || v < 0) return null;
  return (v * _microPerPeso).round();
}

String _unitLabel(String concept) => switch (concept) {
  CostConcepts.voiceMinute => 'por minuto de voz',
  CostConcepts.realtimeEvent => 'por evento',
  CostConcepts.routeRequest => 'por ruta',
  CostConcepts.fixedMonthly => 'por conductor al mes',
  CostConcepts.radioStorage => 'por GB guardado',
  CostConcepts.smsInvite => 'por SMS',
  _ => '',
};

/// Tarifas de costo vigentes e históricas, y alta de una nueva con fecha de vigencia (FR-024).
class CostRatesPage extends StatelessWidget {
  const CostRatesPage({super.key, this.today});

  /// Para las pruebas; por defecto, hoy.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CostRatesCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tarifas de costo')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('rates.add'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => BlocProvider.value(value: cubit, child: const _RateDialog()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarifa'),
      ),
      body: BlocConsumer<CostRatesCubit, CostRatesState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!))),
        builder: (context, state) {
          if (state.loading && state.rates.isEmpty) return const Center(child: CircularProgressIndicator());
          if (state.rates.isEmpty) return const Center(child: Text('Aún no hay tarifas. Crea la primera.'));
          final current = currentRates(state.rates, today ?? DateTime.now());
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              const Text('Estimaciones que ajusta el administrador; el costo del mes usa la tarifa vigente cada día.'),
              const SizedBox(height: 8),
              for (final r in state.rates)
                ListTile(
                  key: Key('rates.${r.concept}.${formatApiDate(r.effectiveFrom)}'),
                  leading: Icon(current.contains(r) ? Icons.check_circle : Icons.history),
                  title: Text(
                    '${costConceptLabel(r.concept)}: ${formatUnitCost(r.unitCostMicro)} ${_unitLabel(r.concept)}',
                  ),
                  subtitle: Text(
                    '${current.contains(r) ? 'Vigente' : (r.effectiveFrom.isAfter(today ?? DateTime.now()) ? 'Programada' : 'Anterior')}'
                    ' desde el ${formatDate(r.effectiveFrom)} · ${r.currency}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RateDialog extends StatefulWidget {
  const _RateDialog();

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  String _concept = CostConcepts.voiceMinute;
  final _cost = TextEditingController();
  DateTime _from = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _cost.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final micro = parseUnitCost(_cost.text);
    if (micro == null) return;
    setState(() => _saving = true);
    final ok = await context.read<CostRatesCubit>().add(
      CostRate(
        concept: _concept,
        currency: 'COP',
        unitCostMicro: micro,
        effectiveFrom: DateTime(_from.year, _from.month, _from.day),
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva tarifa de costo'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('rate.concept'),
              initialValue: _concept,
              decoration: const InputDecoration(labelText: 'Concepto'),
              items: [for (final c in CostConcepts.all) DropdownMenuItem(value: c, child: Text(costConceptLabel(c)))],
              onChanged: (c) => setState(() => _concept = c!),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('rate.cost'),
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: InputDecoration(
                labelText: 'Costo ${_unitLabel(_concept)}',
                prefixText: '\$ ',
                helperText: 'En pesos; admite decimales (0,0004)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  helpText: 'Vigente desde',
                  initialDate: _from,
                  firstDate: now.subtract(const Duration(days: 365)),
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _from = d);
              },
              icon: const Icon(Icons.event),
              label: Text('Vigente desde el ${formatDate(_from)}'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('rate.save'),
          onPressed: _saving || parseUnitCost(_cost.text) == null ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
