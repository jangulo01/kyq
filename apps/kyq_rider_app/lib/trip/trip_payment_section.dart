import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'trip_payment_cubit.dart';

/// Pago del viaje en el resumen del pasajero (004, FR-002–FR-004, FR-007).
class TripPaymentSection extends StatefulWidget {
  const TripPaymentSection({super.key, required this.driverName});

  final String driverName;

  @override
  State<TripPaymentSection> createState() => _TripPaymentSectionState();
}

class _TripPaymentSectionState extends State<TripPaymentSection> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al cerrar la Custom Tab de Bold la app vuelve a primer plano: se consulta el pago.
    if (state == AppLifecycleState.resumed) context.read<TripPaymentCubit>().onResumed();
  }

  Future<void> _confirmCash(BuildContext context, TripPayment p) async {
    final cubit = context.read<TripPaymentCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Ya pagaste en efectivo?'),
        content: Text(
          'Confirma que le entregaste ${formatMoney(p.amountMinor, p.currency)} a ${widget.driverName}. '
          'Le pediremos que confirme que lo recibió.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Todavía no')),
          FilledButton(
            key: const Key('payment.cashConfirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, ya pagué'),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.reportCash();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripPaymentCubit, TripPaymentState>(
      listenWhen: (a, b) => b.message != null && a.message != b.message,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!))),
      builder: (context, state) {
        final p = state.payment;
        if (p == null) {
          if (state.loading) return const Center(child: CircularProgressIndicator());
          // Viajes anteriores al pago en la app (001): se paga directamente.
          return Text(
            'Págale directamente a ${widget.driverName}, en efectivo o por transferencia.',
            textAlign: TextAlign.center,
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(_icon(p.status), color: _color(context, p.status)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tripPaymentStatusLabel(p),
                        key: const Key('payment.status'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._body(context, state, p),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _body(BuildContext context, TripPaymentState state, TripPayment p) {
    final cubit = context.read<TripPaymentCubit>();
    final name = widget.driverName;
    final bold = p.acceptedMethods.contains(TripPaymentMethod.bold);
    final cash = p.acceptedMethods.contains(TripPaymentMethod.cash);
    switch (p.status) {
      case TripPaymentStatus.pending || TripPaymentStatus.unpaid:
        return [
          if (p.status == TripPaymentStatus.unpaid)
            Text('$name marcó este viaje como no pagado. Puedes pagarlo ahora.')
          else
            const Text('¿Cómo vas a pagar?'),
          const SizedBox(height: 12),
          if (bold)
            FilledButton.icon(
              key: const Key('payment.bold'),
              onPressed: state.busy ? null : cubit.payWithBold,
              icon: const Icon(Icons.credit_card),
              label: const Text('Pagar con Bold (tarjeta, PSE, Nequi)'),
            ),
          if (bold && cash) const SizedBox(height: 8),
          if (cash)
            OutlinedButton.icon(
              key: const Key('payment.cash'),
              onPressed: state.busy ? null : () => _confirmCash(context, p),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Pagué en efectivo'),
            ),
          if (!bold && !cash) Text('Págale directamente a $name.'),
        ];
      case TripPaymentStatus.boldInProgress:
        return [
          const Text('Completa el pago en la página de Bold. Si ya pagaste, actualiza el estado.'),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('payment.boldContinue'),
            onPressed: state.busy ? null : cubit.continueBold,
            child: const Text('Continuar el pago'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('payment.refresh'),
            onPressed: state.busy ? null : cubit.refresh,
            child: const Text('Ya pagué: actualizar'),
          ),
        ];
      case TripPaymentStatus.cashReported:
        return [Text('Esperamos que $name confirme que recibió el efectivo.')];
      case TripPaymentStatus.paid:
        return [Text('¡Gracias! $name recibe el 100 %.')];
      case TripPaymentStatus.disputed:
        return [Text('$name dice que no recibió el efectivo. Kyq revisará el caso y te contactará.')];
      case TripPaymentStatus.needsReview || TripPaymentStatus.voided:
        return const [Text('Kyq está revisando este pago.')];
    }
  }

  static IconData _icon(TripPaymentStatus s) => switch (s) {
    TripPaymentStatus.paid => Icons.check_circle,
    TripPaymentStatus.disputed || TripPaymentStatus.unpaid || TripPaymentStatus.needsReview => Icons.error_outline,
    _ => Icons.schedule,
  };

  static Color? _color(BuildContext context, TripPaymentStatus s) => switch (s) {
    TripPaymentStatus.paid => Colors.green,
    TripPaymentStatus.disputed || TripPaymentStatus.unpaid => Theme.of(context).colorScheme.error,
    _ => null,
  };
}
