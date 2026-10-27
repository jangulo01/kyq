import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../map/trip_map.dart';
import 'trip_cubit.dart';

/// Seguimiento: estado, posición del conductor en el mapa y cancelar antes de IN_PROGRESS (FR-013, FR-014).
class TripTrackingView extends StatelessWidget {
  const TripTrackingView({
    super.key,
    required this.trip,
    required this.driverName,
    required this.map,
    this.driverPosition,
    this.busy = false,
  });

  final Trip trip;
  final String driverName;
  final TripMapBuilder map;
  final GeoPoint? driverPosition;
  final bool busy;

  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<TripCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar el viaje?'),
        content: Text('Avisaremos a $driverName. No se hace ningún cobro.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancelar viaje')),
        ],
      ),
    );
    if (ok == true) await cubit.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = switch (trip.status) {
      TripStatus.arrived => 'Tu conductor llegó',
      TripStatus.inProgress => 'En viaje',
      _ => 'Tu conductor va en camino',
    };
    final fare = trip.agreedFareMinor ?? trip.suggestedFareMinor;
    return Column(
      children: [
        Expanded(
          child: map(TripMapMarkers(pickup: trip.pickup, dropoff: trip.dropoff, driver: driverPosition), null),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(status, key: const Key('trip.status'), style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('$driverName · Tarifa ${formatMoney(fare, trip.currency)}'),
                if (driverPosition == null && trip.status == TripStatus.accepted)
                  Text('Esperando la ubicación del conductor…', style: theme.textTheme.bodySmall),
                if (trip.status != TripStatus.inProgress) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('trip.cancel'),
                    onPressed: busy ? null : () => _confirmCancel(context),
                    child: const Text('Cancelar viaje'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
