import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'trip_payment_cubit.dart';

/// Pago del viaje en el resumen del conductor (004). Sin pago registrado (viajes anteriores),
/// conserva el aviso de cobrar directamente.
class TripPaymentCard extends StatelessWidget {
  const TripPaymentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripPaymentCubit, TripPaymentState>(
      listenWhen: (a, b) => b.message != null && a.message != b.message,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!))),
      builder: (context, state) {
        final p = state.payment;
        if (p == null) {
          if (state.loading) return const LinearProgressIndicator();
          return Text(
            'Cobra al pasajero directamente; Kyq no cobra en la app.',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TripPaymentDetails(payment: p, busy: state.busy, onAction: context.read<TripPaymentCubit>().act),
          ),
        );
      },
    );
  }
}

/// Estado del pago con las acciones del conductor que permite (FR-005, FR-006). Pide
/// confirmación antes de cada acción: todas quedan registradas.
class TripPaymentDetails extends StatelessWidget {
  const TripPaymentDetails({super.key, required this.payment, required this.onAction, this.busy = false});

  final TripPayment payment;
  final bool busy;
  final Future<void> Function(DriverPaymentAction action) onAction;

  Future<void> _confirm(BuildContext context, DriverPaymentAction action) async {
    final amount = formatMoney(payment.amountMinor, payment.currency);
    final (title, body, ok) = switch (action) {
      DriverPaymentAction.confirmCash => (
        '¿Recibiste el efectivo?',
        'Confirma que el pasajero te pagó $amount en efectivo.',
        'Sí, lo recibí',
      ),
      DriverPaymentAction.disputeCash => (
        '¿No recibiste el efectivo?',
        'El pasajero dice que te pagó $amount. Kyq revisará el caso con los dos.',
        'No lo recibí',
      ),
      DriverPaymentAction.markUnpaid => (
        '¿El pasajero no te pagó?',
        'El viaje quedará como no pagado y Kyq lo verá. El pasajero aún puede pagarlo.',
        'No me pagó',
      ),
    };
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            key: const Key('payment.actionConfirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(ok),
          ),
        ],
      ),
    );
    if (yes == true) await onAction(action);
  }

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final theme = Theme.of(context);
    final amount = formatMoney(p.amountMinor, p.currency);
    Widget button(DriverPaymentAction action, String label, {bool primary = false}) {
      final onPressed = busy ? null : () => _confirm(context, action);
      final key = Key('payment.${action.name}');
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: primary
            ? FilledButton(key: key, onPressed: onPressed, child: Text(label))
            : OutlinedButton(key: key, onPressed: onPressed, child: Text(label)),
      );
    }

    final (detail, actions) = switch (p.status) {
      TripPaymentStatus.pending => (
        'El pasajero aún no paga ni reporta el pago.',
        [
          button(DriverPaymentAction.confirmCash, 'Recibí el efectivo', primary: true),
          button(DriverPaymentAction.markUnpaid, 'No me pagó'),
        ],
      ),
      TripPaymentStatus.boldInProgress => ('El pasajero está pagando con Bold.', const <Widget>[]),
      TripPaymentStatus.cashReported => (
        'El pasajero dice que te pagó $amount en efectivo.',
        [
          button(DriverPaymentAction.confirmCash, 'Recibí el efectivo', primary: true),
          button(DriverPaymentAction.disputeCash, 'No recibí el efectivo'),
        ],
      ),
      TripPaymentStatus.paid when p.method == TripPaymentMethod.bold => (
        'Kyq recibió el pago y te gira el 100 % ($amount), sin comisión.',
        const <Widget>[],
      ),
      TripPaymentStatus.paid => ('Recibiste $amount en efectivo.', const <Widget>[]),
      TripPaymentStatus.unpaid => (
        'Marcaste este viaje como no pagado. Si el pasajero te paga en efectivo, confírmalo.',
        [button(DriverPaymentAction.confirmCash, 'Recibí el efectivo')],
      ),
      TripPaymentStatus.disputed => (
        'Kyq revisará el caso. Si al final recibiste el efectivo, confírmalo.',
        [button(DriverPaymentAction.confirmCash, 'Recibí el efectivo')],
      ),
      TripPaymentStatus.needsReview || TripPaymentStatus.voided => ('Kyq está revisando este pago.', const <Widget>[]),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tripPaymentStatusLabel(p), key: const Key('payment.status'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(detail),
        ...actions,
      ],
    );
  }
}
