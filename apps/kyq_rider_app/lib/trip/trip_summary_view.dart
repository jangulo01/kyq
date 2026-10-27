import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

/// Resumen final con la tarifa acordada, 100 % para el conductor (RN-KYQ-001, FR-015).
class TripSummaryView extends StatelessWidget {
  const TripSummaryView({super.key, required this.trip, required this.driverName});

  final Trip trip;
  final String driverName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fare = trip.agreedFareMinor ?? trip.suggestedFareMinor;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.check_circle, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        Text('Viaje completado', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Text('Tarifa acordada', style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
        Text(
          formatMoney(fare, trip.currency),
          key: const Key('trip.summaryFare'),
          style: theme.textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text('El 100 % es para tu conductor. Kyq no cobra comisión.', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Págale directamente a $driverName, en efectivo o por transferencia. La app no hace cobros.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(onPressed: () => context.go('/'), child: const Text('Volver a mis conductores')),
      ],
    );
  }
}
