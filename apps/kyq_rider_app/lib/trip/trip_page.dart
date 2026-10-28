import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../map/trip_map.dart';
import '../request/awaiting_driver_view.dart';
import 'trip_cancelled_view.dart';
import 'trip_cubit.dart';
import 'trip_payment_section.dart';
import 'trip_summary_view.dart';
import 'trip_tracking_view.dart';

/// Pantalla única del viaje: muestra la vista que corresponde al estado actual.
///
/// Con [ptt], el walkie-talkie queda abajo desde ACCEPTED hasta que cierra el canal (T075). Con
/// [safety], el botón SOS y "Compartir viaje" (003). Con [payments] (004), el resumen muestra el
/// pago del viaje; necesita un `TripPaymentCubit` arriba.
class TripPage extends StatelessWidget {
  const TripPage({
    super.key,
    required this.driverName,
    this.map = maplibreTripMap,
    this.ptt,
    this.safety,
    this.payments = false,
  });

  final String driverName;
  final TripMapBuilder map;
  final PttController? ptt;
  final TripSafety? safety;
  final bool payments;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripCubit, TripState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) {
        final trip = state.trip;
        // 006: si la solicitud pasó a un compañero, se muestra su nombre y no el del elegido.
        final driverName = switch (trip?.driverName) {
          final name? when name.isNotEmpty => name,
          _ => this.driverName,
        };
        final title = switch (trip?.status) {
          TripStatus.completed => 'Resumen del viaje',
          TripStatus.cancelled => 'Viaje cancelado',
          final s? when trackingStatuses.contains(s) => 'Tu viaje',
          _ => 'Solicitud de viaje',
        };
        final body = switch (trip) {
          null when state.loading => const Center(child: CircularProgressIndicator()),
          null => Center(
            child: TextButton(
              onPressed: context.read<TripCubit>().refresh,
              child: const Text('No pudimos cargar el viaje. Reintentar'),
            ),
          ),
          Trip(status: TripStatus.completed) => TripSummaryView(
            trip: trip,
            driverName: driverName,
            payment: payments ? TripPaymentSection(driverName: driverName) : null,
          ),
          Trip(status: TripStatus.cancelled) => TripCancelledView(trip: trip, driverName: driverName),
          Trip(:final status) when trackingStatuses.contains(status) => TripTrackingView(
            trip: trip,
            driverName: driverName,
            map: map,
            driverPosition: state.driverPosition,
            busy: state.busy,
          ),
          _ => AwaitingDriverView(trip: trip, driverName: driverName, busy: state.busy),
        };
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              ?switch ((trip, safety)) {
                (final trip?, final safety?) => safety.shareAction(trip.status),
                _ => null,
              },
            ],
          ),
          body: switch ((trip, safety)) {
            (final trip?, final safety?) => TripSafetyLayer(
              safety: safety,
              status: trip.status,
              keepOpenWarning: true,
              child: body,
            ),
            _ => body,
          },
          bottomNavigationBar: switch ((trip, ptt)) {
            (final trip?, final ptt?) => TripPttBar(controller: ptt, status: trip.status, remoteName: driverName),
            _ => null,
          },
        );
      },
    );
  }
}
