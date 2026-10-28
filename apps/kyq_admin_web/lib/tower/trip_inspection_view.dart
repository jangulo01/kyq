import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'trip_inspection_cubit.dart';

const _statusLabels = {
  'REQUESTED': 'Solicitado',
  'FARE_PENDING': 'Tarifa por confirmar',
  'NEGOTIATION_PENDING': 'Negociación pedida',
  'NEGOTIATING': 'Negociando',
  'ACCEPTED': 'Aceptado',
  'ARRIVED': 'Conductor en el origen',
  'IN_PROGRESS': 'En curso',
  'COMPLETED': 'Completado',
  'CANCELLED': 'Cancelado',
};

const _dispatchLabels = {
  'chosen_driver': 'Conductor Elegido',
  'cooperative': 'Cooperativa',
  'zone_pool': 'Bolsa zonal',
};

String _hhmm(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
}

/// Detalle de un viaje desde la torre (009, US1): pasos, personas sin teléfono, vehículo, ruta,
/// posición en vivo, tarifa, despacho, pago y SOS abierto.
class TripInspectionView extends StatelessWidget {
  const TripInspectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripInspectionCubit, TripInspectionState>(
      builder: (context, state) {
        final t = state.trip;
        if (t == null) {
          return Center(child: state.loading ? const CircularProgressIndicator() : Text(state.error ?? 'Sin datos.'));
        }
        final theme = Theme.of(context);
        final fare = t.agreedFareMinor ?? t.suggestedFareMinor;
        final pos = t.driverPosition;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (t.openSos != null)
              Card(
                key: const Key('inspection.sos'),
                color: theme.colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.sos),
                  title: const Text('SOS abierto en este viaje'),
                  trailing: TextButton(
                    onPressed: () => context.go('/emergencies/${t.openSos!.id}'),
                    child: const Text('Abrir en la consola'),
                  ),
                ),
              ),
            ListTile(
              title: Text(_statusLabels[t.status] ?? t.status, key: const Key('inspection.status')),
              subtitle: Text(
                [
                  _dispatchLabels[t.dispatch] ?? t.dispatch,
                  if (t.cooperativeName != null) t.cooperativeName!,
                  if (t.handoverCount > 0) '${t.handoverCount} traspaso${t.handoverCount == 1 ? '' : 's'}',
                ].join(' · '),
              ),
              trailing: t.active ? const Chip(label: Text('Activo')) : null,
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(t.passenger.displayName, key: const Key('inspection.passenger')),
              subtitle: const Text('Pasajero'),
            ),
            ListTile(
              leading: const Icon(Icons.local_taxi_outlined),
              title: Text(t.driver.displayName, key: const Key('inspection.driver')),
              subtitle: Text('${t.vehiclePlate} · ${t.vehicleDescription}'),
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: Text(
                '${(t.distanceM / 1000).toStringAsFixed(1).replaceAll('.', ',')} km · ${(t.durationS / 60).ceil()} min',
              ),
              subtitle: Text(
                'Recogida ${t.pickup.lat.toStringAsFixed(5)}, ${t.pickup.lng.toStringAsFixed(5)} → '
                'destino ${t.dropoff.lat.toStringAsFixed(5)}, ${t.dropoff.lng.toStringAsFixed(5)}',
              ),
            ),
            if (pos != null)
              ListTile(
                key: const Key('inspection.position'),
                leading: Icon(Icons.my_location, color: pos.stale ? theme.colorScheme.error : null),
                title: Text('${pos.lat.toStringAsFixed(5)}, ${pos.lng.toStringAsFixed(5)}'),
                subtitle: Text(
                  pos.stale
                      ? 'Ubicación desactualizada (${_hhmm(pos.locationAt)})'
                      : 'Ubicación ${_hhmm(pos.locationAt)}',
                ),
              ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(formatMoney(fare, t.currency), key: const Key('inspection.fare')),
              subtitle: Text(
                [
                  if (t.preferentialDiscountPct > 0) 'Tarifa preferencial −${t.preferentialDiscountPct} %',
                  if (t.payment != null)
                    'Pago: ${t.payment!.status}${t.payment!.method == null ? '' : ' (${t.payment!.method})'}',
                ].join(' · '),
              ),
            ),
            const Divider(),
            Text('Pasos', style: theme.textTheme.titleSmall),
            for (final s in t.steps)
              ListTile(dense: true, title: Text(_statusLabels[s.status] ?? s.status), trailing: Text(_hhmm(s.at))),
            if (state.error != null) Text(state.error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        );
      },
    );
  }
}

/// Abre el detalle de [tripId] en un panel; cada apertura queda auditada (FR-004).
Future<void> showTripInspection(
  BuildContext context,
  String tripId, {
  Duration? refreshEvery = const Duration(seconds: 5),
}) {
  final api = context.read<KyqApiClient>();
  return showDialog<void>(
    context: context,
    builder: (context) => BlocProvider(
      create: (_) => TripInspectionCubit(api, tripId, refreshEvery: refreshEvery)..load(),
      child: Dialog(
        child: SizedBox(
          width: 520,
          height: 640,
          child: Column(
            children: [
              AppBar(
                title: const Text('Viaje'),
                automaticallyImplyLeading: false,
                actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))],
              ),
              const Expanded(child: TripInspectionView()),
            ],
          ),
        ),
      ),
    ),
  );
}
