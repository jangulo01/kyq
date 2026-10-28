import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../trip/trip_route.dart';
import 'pending_payments_cubit.dart';

/// "Tienes un viaje sin pagar" en la pantalla principal, con acceso directo al pago (004, FR-016).
class PendingPaymentsBanner extends StatelessWidget {
  const PendingPaymentsBanner({super.key});

  Future<void> _open(BuildContext context, TripPayment p) async {
    final cubit = context.read<PendingPaymentsCubit>();
    await context.push(tripLocation(p.tripId, p.driverName));
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PendingPaymentsCubit, List<TripPayment>>(
      builder: (context, pending) {
        if (pending.isEmpty) return const SizedBox.shrink();
        final first = pending.first;
        final title = pending.length == 1
            ? 'Tienes un viaje sin pagar: ${formatMoney(first.amountMinor, first.currency)} con ${first.driverName}'
            : 'Tienes ${pending.length} viajes sin pagar';
        return Card(
          key: const Key('pendingPayments.banner'),
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(title),
            subtitle: first.status == TripPaymentStatus.boldInProgress
                ? const Text('Tienes un pago con Bold en proceso.')
                : const Text('Paga con Bold o reporta que pagaste en efectivo.'),
            trailing: TextButton(
              key: const Key('pendingPayments.pay'),
              onPressed: () => _open(context, first),
              child: const Text('Pagar'),
            ),
          ),
        );
      },
    );
  }
}
