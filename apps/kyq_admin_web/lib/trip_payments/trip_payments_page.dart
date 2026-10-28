import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'note_dialog.dart';
import 'trip_payments_cubits.dart';

const _filters = <(String?, String)>[
  (issuesFilter, 'Incidencias'),
  (null, 'Todos'),
  ('pending', 'Pendientes'),
  ('cash_reported', 'Efectivo reportado'),
  ('bold_in_progress', 'Bold en proceso'),
  ('paid', 'Pagados'),
  ('voided', 'Anulados'),
];

/// Pagos de viajes por estado; incidencias primero (004, T029, FR-014, FR-017).
class TripPaymentsPage extends StatelessWidget {
  const TripPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripPaymentsCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos de viajes'),
        actions: [
          TextButton.icon(
            key: const Key('tripPayments.settlements'),
            onPressed: () => context.push('/trip-payments/settlements'),
            icon: const Icon(Icons.account_balance_outlined),
            label: const Text('Liquidaciones'),
          ),
          IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load),
        ],
      ),
      body: BlocConsumer<TripPaymentsCubit, TripPaymentsState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!))),
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (value, label) in _filters)
                    ChoiceChip(
                      key: Key('tripPayments.filter.${value ?? 'all'}'),
                      label: Text(label),
                      selected: state.filter == value,
                      onSelected: (_) => cubit.setFilter(value),
                    ),
                ],
              ),
            ),
            if (state.loading) const LinearProgressIndicator(),
            Expanded(
              child: state.items.isEmpty
                  ? Center(child: Text(state.loading ? '' : 'No hay pagos de viajes con ese estado.'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) => _PaymentTile(payment: state.items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final TripPayment payment;

  Future<void> _resolve(BuildContext context) async {
    final cubit = context.read<TripPaymentsCubit>();
    final answer = await showDialog<({bool paid, String note})>(
      context: context,
      builder: (_) => _ResolveDialog(payment: payment),
    );
    if (answer != null) await cubit.resolve(payment.id, paid: answer.paid, note: answer.note);
  }

  Future<void> _void(BuildContext context) async {
    final cubit = context.read<TripPaymentsCubit>();
    final reason = await showNoteDialog(
      context,
      title: 'Anular pago con Bold',
      body:
          'Haz primero el reembolso en el panel de Bold. Se debitará ${formatMoney(payment.amountMinor, payment.currency)} '
          'del saldo de ${payment.driverName} y verá el motivo.',
      label: 'Motivo',
      confirm: 'Anular',
      fieldKey: const Key('tripVoid.reason'),
      confirmKey: const Key('tripVoid.confirm'),
    );
    if (reason != null) await cubit.voidPayment(payment.id, reason);
  }

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final theme = Theme.of(context);
    final canResolve = p.status == TripPaymentStatus.disputed || p.status == TripPaymentStatus.unpaid;
    final canVoid =
        p.status == TripPaymentStatus.needsReview ||
        (p.status == TripPaymentStatus.paid && p.method == TripPaymentMethod.bold);
    final lines = [
      '${formatDate(p.createdAt)} · Conductor: ${p.driverName} · Pasajero: ${p.passengerName}',
      if (p.cashReportedAt != null) 'El pasajero reportó efectivo el ${formatDate(p.cashReportedAt!)}',
      if (p.disputedAt != null) 'El conductor lo disputó el ${formatDate(p.disputedAt!)}',
      if (p.unpaidMarkedAt != null) 'El conductor lo marcó no pagado el ${formatDate(p.unpaidMarkedAt!)}',
      if (p.reviewNote != null) 'Revisión: ${p.reviewNote}',
      if (p.resolutionNote != null) 'Resolución: ${p.resolutionNote}',
      if (p.voidReason != null) 'Anulado: ${p.voidReason}',
    ];
    return ListTile(
      key: Key('tripPayments.${p.id}'),
      leading: Icon(
        p.status.issue || p.reviewNote != null ? Icons.error_outline : Icons.receipt_outlined,
        color: p.status.issue || p.reviewNote != null ? theme.colorScheme.error : null,
      ),
      title: Text('${formatMoney(p.amountMinor, p.currency)} · ${tripPaymentStatusLabel(p)}'),
      subtitle: Text(lines.join('\n')),
      isThreeLine: lines.length > 1,
      trailing: Wrap(
        spacing: 8,
        children: [
          if (canResolve)
            FilledButton.tonal(
              key: Key('tripPayments.resolve.${p.id}'),
              onPressed: () => _resolve(context),
              child: const Text('Resolver'),
            ),
          if (canVoid)
            TextButton(
              key: Key('tripPayments.void.${p.id}'),
              onPressed: () => _void(context),
              child: const Text('Anular'),
            ),
        ],
      ),
    );
  }
}

/// Resolución de una disputa o un no pagado tras hablar con las dos partes.
class _ResolveDialog extends StatefulWidget {
  const _ResolveDialog({required this.payment});

  final TripPayment payment;

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final _note = TextEditingController();
  bool _paid = true;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    return AlertDialog(
      title: const Text('Resolver pago del viaje'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${formatMoney(p.amountMinor, p.currency)} · ${p.passengerName} → ${p.driverName}'),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Pagado en efectivo')),
                ButtonSegment(value: false, label: Text('No pagado')),
              ],
              selected: {_paid},
              onSelectionChanged: (v) => setState(() => _paid = v.first),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('resolve.note'),
              controller: _note,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Nota (qué se aclaró y con quién)'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('resolve.confirm'),
          onPressed: _note.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop((paid: _paid, note: _note.text.trim())),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
