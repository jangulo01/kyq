import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../offers/offer.dart';
import 'navigation.dart';
import 'trip_cubit.dart';

/// Viaje aceptado: ruta en app externa y botones Llegué / Iniciar viaje / Finalizar (T059).
class TripActiveView extends StatelessWidget {
  const TripActiveView({super.key, required this.trip, required this.busy});

  final Trip trip;
  final bool busy;

  Future<void> _navigate(BuildContext context, NavigationApp app, GeoPoint target) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await openNavigation(app, target)) {
      messenger.showSnackBar(const SnackBar(content: Text('No hay ninguna app de mapas instalada.')));
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<TripCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar el viaje?'),
        content: const Text('El pasajero recibirá el aviso de inmediato.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          FilledButton(
            key: const Key('trip.cancel.confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok ?? false) await cubit.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<TripCubit>();
    final inProgress = trip.status == TripStatus.inProgress;
    final target = inProgress ? trip.dropoff : trip.pickup;
    final (label, action, key) = switch (trip.status) {
      TripStatus.accepted => ('Llegué', cubit.arrive, 'trip.arrive'),
      TripStatus.arrived => ('Iniciar viaje', cubit.start, 'trip.start'),
      _ => ('Finalizar', cubit.complete, 'trip.complete'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: Icon(inProgress ? Icons.place : Icons.trip_origin),
            title: Text(inProgress ? 'Destino' : 'Recogida'),
            subtitle: Text(formatPoint(target)),
          ),
        ),
        Text(
          'Tarifa: ${formatMoney(trip.agreedFareMinor ?? trip.suggestedFareMinor, trip.currency)}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.navigation),
                label: const Text('Abrir en Waze'),
                onPressed: () => _navigate(context, NavigationApp.waze, target),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Abrir en Google Maps'),
                onPressed: () => _navigate(context, NavigationApp.googleMaps, target),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton(key: Key(key), onPressed: busy ? null : action, child: Text(label)),
        if (!inProgress) ...[
          const SizedBox(height: 8),
          TextButton(
            key: const Key('trip.cancel'),
            onPressed: busy ? null : () => _confirmCancel(context),
            child: const Text('Cancelar viaje'),
          ),
        ],
      ],
    );
  }
}
