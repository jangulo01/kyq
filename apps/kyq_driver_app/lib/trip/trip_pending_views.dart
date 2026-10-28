import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../offers/countdown_text.dart';
import '../offers/fare_dialog.dart';
import 'trip_cubit.dart';

/// Espera de la respuesta del pasajero (FARE_PENDING, NEGOTIATION_PENDING).
class WaitingView extends StatelessWidget {
  const WaitingView({super.key, required this.title, required this.detail, this.until, this.onCancel});

  final String title;
  final String detail;
  final DateTime? until;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.hourglass_top, size: 48),
        const SizedBox(height: 24),
        Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(detail, textAlign: TextAlign.center),
        if (until != null) ...[
          const SizedBox(height: 8),
          Center(
            child: CountdownText(until: until!, style: theme.textTheme.titleMedium),
          ),
        ],
        const SizedBox(height: 24),
        TextButton(onPressed: onCancel, child: const Text('Cancelar viaje')),
      ],
    );
  }
}

/// El pasajero no quiso negociar: la oferta vuelve con la tarifa sugerida y el conductor decide
/// si la acepta (FR-010c).
class SuggestedFareBackView extends StatelessWidget {
  const SuggestedFareBackView({super.key, required this.trip, required this.busy});

  final Trip trip;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<TripCubit>();
    final fare = formatMoney(trip.suggestedFareMinor, trip.currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('El pasajero prefiere la tarifa sugerida', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(fare, style: theme.textTheme.headlineMedium),
        if (trip.offerExpiresAt != null)
          Row(
            children: [
              const Text('Responde en '),
              CountdownText(until: trip.offerExpiresAt!),
            ],
          ),
        const SizedBox(height: 16),
        FilledButton(onPressed: busy ? null : cubit.accept, child: Text('Aceptar $fare')),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: busy
              ? null
              : () async {
                  final pesos = await askFareInPesos(context, title: 'Aceptar con otra tarifa');
                  if (pesos != null) await cubit.acceptWithFare(pesos);
                },
          child: const Text('Aceptar con otra tarifa'),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: busy ? null : cubit.reject, child: const Text('Rechazar')),
      ],
    );
  }
}
