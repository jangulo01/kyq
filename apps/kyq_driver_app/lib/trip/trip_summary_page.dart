import 'package:flutter/material.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'trip_texts.dart';

/// Resumen del viaje terminado o cancelado (T060, FR-015, RN-KYQ-001).
class TripSummaryView extends StatelessWidget {
  const TripSummaryView({super.key, required this.trip, required this.onDone});

  final Trip trip;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = trip.status == TripStatus.completed;
    final fare = trip.agreedFareMinor ?? trip.suggestedFareMinor;
    final payout = trip.driverPayoutMinor ?? fare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.cancel,
          size: 64,
          color: completed ? Colors.green : theme.colorScheme.error,
        ),
        const SizedBox(height: 8),
        Text(
          completed ? 'Viaje terminado' : 'Viaje cancelado',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (completed)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tarifa acordada', style: theme.textTheme.labelLarge),
                  Text(formatMoney(fare, trip.currency), style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  Text(
                    'Recibes el 100 %: ${formatMoney(payout, trip.currency)}',
                    key: const Key('summary.payout'),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    'Comisión Kyq: ${formatMoney(trip.platformCommissionMinor, trip.currency)}',
                    key: const Key('summary.commission'),
                  ),
                  const SizedBox(height: 12),
                  Text('Cobra al pasajero directamente; Kyq no cobra en la app.', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          )
        else
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(cancelReasonMessage(trip.cancelReason), key: const Key('summary.cancelReason')),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(onPressed: onDone, child: const Text('Volver al inicio')),
      ],
    );
  }
}
