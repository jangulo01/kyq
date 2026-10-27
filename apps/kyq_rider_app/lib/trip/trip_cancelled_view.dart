import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';

/// Viaje cancelado, con el motivo en palabras del pasajero.
class TripCancelledView extends StatelessWidget {
  const TripCancelledView({super.key, required this.trip, required this.driverName});

  final Trip trip;
  final String driverName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.cancel_outlined, size: 64),
        const SizedBox(height: 16),
        Text('Viaje cancelado', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          cancelReasonMessage(trip.cancelReason, driverName),
          key: const Key('trip.cancelReason'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text('No se hizo ningún cobro.', textAlign: TextAlign.center),
        const SizedBox(height: 32),
        FilledButton(onPressed: () => context.go('/'), child: const Text('Volver a mis conductores')),
      ],
    );
  }
}

/// Texto para cada `cancel_reason` del data model.
String cancelReasonMessage(String? reason, String driverName) => switch (reason) {
  'offer_expired' => '$driverName no respondió a tiempo.',
  'offer_rejected' => '$driverName no puede tomar el viaje ahora.',
  'fare_rejected' => 'La nueva tarifa no se confirmó.',
  'negotiation_failed' => 'No llegaron a un acuerdo sobre la tarifa.',
  'driver' => '$driverName canceló el viaje.',
  'passenger' => 'Cancelaste el viaje.',
  _ => 'El viaje se canceló.',
};
