import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'fare_dialog.dart';
import 'offer.dart';
import 'offer_cubit.dart';

/// Oferta exclusiva con cuenta atrás de 25 s (T057, FR-010a, FR-010c, FR-011).
class OfferPage extends StatelessWidget {
  const OfferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo viaje'), automaticallyImplyLeading: false),
      body: BlocBuilder<OfferCubit, OfferState>(
        builder: (context, state) => switch (state) {
          OfferShown() => _OfferCard(state: state),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.state});

  final OfferShown state;

  static const _offerSeconds = 25;

  Future<void> _otherFare(BuildContext context) async {
    final cubit = context.read<OfferCubit>();
    final pesos = await askFareInPesos(context, title: 'Aceptar con otra tarifa');
    if (pesos != null) await cubit.acceptWithFare(pesos);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offer = state.offer;
    final cubit = context.read<OfferCubit>();
    final fare = formatMoney(offer.suggestedFareMinor, offer.currency);
    final busy = state.busy;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LinearProgressIndicator(value: state.secondsLeft / _offerSeconds),
        const SizedBox(height: 8),
        Text(
          'Responde en ${state.secondsLeft} s',
          key: const Key('offer.countdown'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.passengerName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 12),
                _Row(icon: Icons.trip_origin, label: 'Recogida', value: formatPoint(offer.pickup)),
                _Row(icon: Icons.place, label: 'Destino', value: formatPoint(offer.dropoff)),
                _Row(
                  icon: Icons.route,
                  label: 'Recorrido',
                  value: formatDistanceDuration(offer.distanceM, offer.durationS),
                ),
                const Divider(height: 24),
                Text('Tarifa sugerida', style: theme.textTheme.labelLarge),
                Text(fare, key: const Key('offer.fare'), style: theme.textTheme.headlineMedium),
              ],
            ),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 8),
          Text(state.error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('offer.accept'),
          onPressed: busy ? null : cubit.accept,
          child: Text('Aceptar $fare'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('offer.otherFare'),
          onPressed: busy ? null : () => _otherFare(context),
          child: const Text('Aceptar con otra tarifa'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('offer.negotiate'),
          onPressed: busy ? null : cubit.requestNegotiation,
          child: const Text('Proponer negociar'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('offer.reject'),
          onPressed: busy ? null : cubit.reject,
          child: const Text('Rechazar'),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.labelLarge),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
