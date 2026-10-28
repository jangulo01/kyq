import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'trip_payments_cubits.dart';

/// Libro de un conductor: saldo por girar, movimientos, pagos de viajes y registro de giros
/// (004, T029, FR-012, FR-013).
class DriverLedgerPage extends StatelessWidget {
  const DriverLedgerPage({super.key, this.driverName});

  final String? driverName;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DriverLedgerCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(driverName == null ? 'Libro del conductor' : 'Libro de $driverName'),
        actions: [IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load)],
      ),
      body: BlocConsumer<DriverLedgerCubit, DriverLedgerState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!))),
        builder: (context, state) {
          final s = state.settlement;
          if (s == null) {
            return Center(child: state.loading ? const CircularProgressIndicator() : const Text('Sin datos.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.loading) const LinearProgressIndicator(),
              if (s.balances.isEmpty) const Text('Este conductor aún no tiene pagos con Bold.'),
              for (final b in s.balances)
                Card(
                  child: ListTile(
                    title: Text(
                      'Por girar: ${formatSignedMoney(b.balanceMinor, b.currency)}',
                      key: Key('ledger.balance.${b.currency}'),
                    ),
                    subtitle: Text(
                      'Recaudado ${formatSignedMoney(b.creditedMinor, b.currency)} · '
                      'Anulado ${formatSignedMoney(b.debitedMinor, b.currency)} · '
                      'Girado ${formatSignedMoney(b.paidOutMinor, b.currency)}',
                    ),
                    trailing: FilledButton(
                      key: Key('ledger.payout.${b.currency}'),
                      onPressed: b.balanceMinor <= 0
                          ? null
                          : () => showDialog<void>(
                              context: context,
                              builder: (_) => BlocProvider.value(
                                value: cubit,
                                child: _PayoutDialog(balance: b),
                              ),
                            ),
                      child: const Text('Registrar giro'),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Movimientos', style: Theme.of(context).textTheme.titleMedium),
              if (s.entries.isEmpty) const Text('Sin movimientos.'),
              for (final e in s.entries)
                ListTile(
                  key: Key('ledger.entry.${e.id}'),
                  title: Text(ledgerKindLabel(e.kind)),
                  subtitle: Text([formatDate(e.createdAt), if (e.reference != null) 'ref. ${e.reference}'].join(' · ')),
                  trailing: Text(formatSignedMoney(e.amountMinor, e.currency)),
                ),
              const SizedBox(height: 16),
              Text('Pagos de viajes recientes', style: Theme.of(context).textTheme.titleMedium),
              for (final p in s.payments)
                ListTile(
                  title: Text('${formatMoney(p.amountMinor, p.currency)} · ${tripPaymentStatusLabel(p)}'),
                  subtitle: Text('${formatDate(p.createdAt)} · ${p.passengerName}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Giro hecho por transferencia; por defecto, todo el saldo. Pesos enteros, como las tarifas.
class _PayoutDialog extends StatefulWidget {
  const _PayoutDialog({required this.balance});

  final SettlementBalance balance;

  @override
  State<_PayoutDialog> createState() => _PayoutDialogState();
}

class _PayoutDialogState extends State<_PayoutDialog> {
  late final _amount = TextEditingController(text: '${widget.balance.balanceMinor ~/ 100}');
  final _reference = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _amountMinor {
    final pesos = int.tryParse(_amount.text);
    if (pesos == null || pesos <= 0) return null;
    final minor = pesos * 100;
    return minor > widget.balance.balanceMinor ? null : minor;
  }

  Future<void> _save() async {
    final amount = _amountMinor;
    if (amount == null) return;
    setState(() => _saving = true);
    final ok = await context.read<DriverLedgerCubit>().payout(
      amountMinor: amount,
      currency: widget.balance.currency,
      reference: _reference.text.trim(),
      note: _note.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giro registrado.')));
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.balance;
    final valid = _amountMinor != null && _reference.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('Registrar giro al conductor'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Saldo por girar: ${formatSignedMoney(b.balanceMinor, b.currency)}. Registra el giro después de hacer la '
              'transferencia; el conductor lo verá con su referencia.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('payout.amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: 'Valor girado', prefixText: '\$ ', suffixText: b.currency),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('payout.reference'),
              controller: _reference,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Referencia de la transferencia'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              key: const Key('payout.note'),
              controller: _note,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('payout.save'),
          onPressed: _saving || !valid ? null : _save,
          child: const Text('Registrar giro'),
        ),
      ],
    );
  }
}
