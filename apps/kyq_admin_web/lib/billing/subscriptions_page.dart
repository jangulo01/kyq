import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../fares/fare_table_page.dart' show cityCode;
import 'billing_cubits.dart';

/// Suscripciones filtradas por estado (T040).
class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionsCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suscripciones'),
        actions: [
          TextButton.icon(
            key: const Key('subscriptions.price'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BlocProvider.value(value: cubit, child: const _PriceDialog()),
            ),
            icon: const Icon(Icons.sell_outlined),
            label: const Text('Precio mensual'),
          ),
          IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load),
        ],
      ),
      body: BlocConsumer<SubscriptionsCubit, SubscriptionsState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!))),
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final f in <BillingStatus?>[null, ...BillingStatus.values])
                    ChoiceChip(
                      key: Key('subscriptions.filter.${f?.name ?? 'all'}'),
                      label: Text(f == null ? 'Todas' : billingStatusLabel(f)),
                      selected: state.filter == f,
                      onSelected: (_) => cubit.setFilter(f),
                    ),
                ],
              ),
            ),
            if (state.loading) const LinearProgressIndicator(),
            Expanded(
              child: state.items.isEmpty
                  ? Center(child: Text(state.loading ? '' : 'No hay suscripciones con ese estado.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('Conductor')),
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Vence')),
                            DataColumn(label: Text('Último pago')),
                          ],
                          rows: [
                            for (final s in state.items)
                              DataRow(
                                key: ValueKey('subscriptions.row.${s.driverId}'),
                                onSelectChanged: (_) =>
                                    context.push('/billing/drivers/${s.driverId}', extra: s.displayName),
                                cells: [
                                  DataCell(Text([s.displayName, ?s.phoneE164, ?s.vehiclePlate].join('\n'))),
                                  DataCell(Text(billingStatusLabel(s.status))),
                                  DataCell(Text(s.paidUntil == null ? '—' : formatDate(s.paidUntil!))),
                                  DataCell(
                                    Text(
                                      s.lastPayment == null
                                          ? '—'
                                          : '${formatDate(s.lastPayment!.createdAt)} · '
                                                '${formatMoney(s.lastPayment!.amountMinor, s.lastPayment!.currency)} · '
                                                '${paymentStatusLabel(s.lastPayment!.status)}',
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nuevo precio mensual por ciudad con fecha de vigencia (FR-013). Pesos enteros, como las tarifas.
class _PriceDialog extends StatefulWidget {
  const _PriceDialog();

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  final _city = TextEditingController(text: cityCode);
  final _amount = TextEditingController();
  DateTime? _from;
  bool _saving = false;

  @override
  void dispose() {
    _city.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pesos = int.tryParse(_amount.text);
    if (pesos == null || pesos <= 0 || _city.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final from = _from;
    final ok = await context.read<SubscriptionsCubit>().setPrice(
      _city.text.trim(),
      amountMinor: pesos * 100,
      // Desde el inicio del día elegido (hora local); sin fecha, rige desde ya.
      effectiveFrom: from == null ? null : DateTime(from.year, from.month, from.day),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Precio guardado.')));
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Precio mensual'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('price.amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Valor mensual', prefixText: '\$ ', suffixText: 'COP'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  helpText: 'Vigente desde',
                  initialDate: _from ?? now,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _from = d);
              },
              icon: const Icon(Icons.event),
              label: Text(_from == null ? 'Vigente desde hoy' : 'Vigente desde el ${formatDate(_from!)}'),
            ),
            const SizedBox(height: 8),
            const Text('Los pagos ya iniciados conservan el precio con el que empezaron.'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('price.save'),
          onPressed: _saving || (int.tryParse(_amount.text) ?? 0) <= 0 ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
