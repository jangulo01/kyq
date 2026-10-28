import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'billing_cubits.dart';

/// Pagos de un conductor: historial, pago manual y anulación con motivo (T040, FR-021).
class DriverPaymentsPage extends StatelessWidget {
  const DriverPaymentsPage({super.key, this.driverName});

  final String? driverName;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DriverPaymentsCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(driverName == null ? 'Pagos' : 'Pagos de $driverName'),
        actions: [IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('payments.manual'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => BlocProvider.value(value: cubit, child: const _ManualPaymentDialog()),
        ),
        icon: const Icon(Icons.point_of_sale),
        label: const Text('Registrar pago manual'),
      ),
      body: BlocConsumer<DriverPaymentsCubit, DriverPaymentsState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!))),
        builder: (context, state) {
          if (state.loading && state.payments.isEmpty) return const Center(child: CircularProgressIndicator());
          if (state.payments.isEmpty) return const Center(child: Text('Este conductor aún no tiene pagos.'));
          return Column(
            children: [
              if (state.loading) const LinearProgressIndicator(),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: state.payments.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _PaymentTile(payment: state.payments[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final review = p.status == PaymentStatus.needsReview;
    return ListTile(
      key: Key('payments.${p.id}'),
      leading: Icon(
        p.method == PaymentMethod.manual ? Icons.point_of_sale : Icons.credit_card,
        color: review ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text('${formatMoney(p.amountMinor, p.currency)} · ${paymentStatusLabel(p.status)}'),
      subtitle: Text(
        [
          '${formatDate(p.createdAt)} · ${paymentMethodLabel(p)}${p.manualReference == null ? '' : ' · ref. ${p.manualReference}'}',
          if (p.coversFrom != null && p.coversUntil != null)
            'Cubre del ${formatDate(p.coversFrom!)} al ${formatDate(p.coversUntil!)}',
          if (p.voidReason != null) 'Anulado: ${p.voidReason}',
          if (review) p.reviewNote ?? 'El pago quedó en revisión: no se aplicó a la suscripción.',
        ].join('\n'),
      ),
      isThreeLine: p.coversUntil != null || p.voidReason != null || review,
      trailing: p.status == PaymentStatus.approved
          ? TextButton(
              key: Key('payments.void.${p.id}'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<DriverPaymentsCubit>(),
                  child: _VoidDialog(payment: p),
                ),
              ),
              child: const Text('Anular'),
            )
          : null,
    );
  }
}

class _ManualPaymentDialog extends StatefulWidget {
  const _ManualPaymentDialog();

  @override
  State<_ManualPaymentDialog> createState() => _ManualPaymentDialogState();
}

class _ManualPaymentDialogState extends State<_ManualPaymentDialog> {
  final _method = TextEditingController(text: 'efectivo');
  final _reference = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _method.dispose();
    _reference.dispose();
    super.dispose();
  }

  bool get _valid => _method.text.trim().isNotEmpty && _reference.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context.read<DriverPaymentsCubit>().manual(
      methodDetail: _method.text.trim(),
      reference: _reference.text.trim(),
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
      title: const Text('Registrar pago manual'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Extiende la suscripción un mes al precio vigente, igual que un pago con Bold.'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('manual.method'),
              controller: _method,
              decoration: const InputDecoration(labelText: 'Medio (efectivo, transferencia…)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('manual.reference'),
              controller: _reference,
              decoration: const InputDecoration(labelText: 'Referencia o recibo'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('manual.save'),
          onPressed: _saving || !_valid ? null : _save,
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}

class _VoidDialog extends StatefulWidget {
  const _VoidDialog({required this.payment});

  final Payment payment;

  @override
  State<_VoidDialog> createState() => _VoidDialogState();
}

class _VoidDialogState extends State<_VoidDialog> {
  final _reason = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context.read<DriverPaymentsCubit>().voidPayment(widget.payment.id, _reason.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    return AlertDialog(
      title: const Text('Anular pago'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Se restará el periodo que cubría (${formatMoney(p.amountMinor, p.currency)} del '
              '${formatDate(p.createdAt)}). El conductor verá el motivo.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('void.reason'),
              controller: _reason,
              decoration: const InputDecoration(labelText: 'Motivo', hintText: 'contracargo, pago duplicado…'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('void.confirm'),
          onPressed: _saving || _reason.text.trim().isEmpty ? null : _save,
          child: const Text('Anular'),
        ),
      ],
    );
  }
}
