import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import '../map/trip_map.dart';
import '../request/awaiting_driver_view.dart';
import 'trip_cancelled_view.dart';
import 'trip_cubit.dart';
import 'trip_summary_view.dart';
import 'trip_tracking_view.dart';

/// Pantalla única del viaje: muestra la vista que corresponde al estado actual.
class TripPage extends StatelessWidget {
  const TripPage({super.key, required this.driverName, this.map = maplibreTripMap});

  final String driverName;
  final TripMapBuilder map;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripCubit, TripState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) {
        final trip = state.trip;
        final title = switch (trip?.status) {
          TripStatus.completed => 'Resumen del viaje',
          TripStatus.cancelled => 'Viaje cancelado',
          final s? when trackingStatuses.contains(s) => 'Tu viaje',
          _ => 'Solicitud de viaje',
        };
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: switch (trip) {
            null when state.loading => const Center(child: CircularProgressIndicator()),
            null => Center(
              child: TextButton(
                onPressed: context.read<TripCubit>().refresh,
                child: const Text('No pudimos cargar el viaje. Reintentar'),
              ),
            ),
            Trip(status: TripStatus.completed) => TripSummaryView(trip: trip, driverName: driverName),
            Trip(status: TripStatus.cancelled) => TripCancelledView(trip: trip, driverName: driverName),
            Trip(:final status) when trackingStatuses.contains(status) => TripTrackingView(
              trip: trip,
              driverName: driverName,
              map: map,
              driverPosition: state.driverPosition,
              busy: state.busy,
            ),
            _ => AwaitingDriverView(trip: trip, driverName: driverName, busy: state.busy),
          },
        );
      },
    );
  }
}
