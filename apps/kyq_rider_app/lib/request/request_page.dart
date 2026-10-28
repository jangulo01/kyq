import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../map/trip_map.dart';
import '../trip/trip_route.dart';
import 'request_cubit.dart';

/// Origen, destino, tarifa sugerida y botón para pedir el viaje (FR-009, FR-010).
class RequestPage extends StatelessWidget {
  const RequestPage({super.key, this.map = maplibreTripMap});

  final TripMapBuilder map;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RequestCubit>();
    return Scaffold(
      appBar: AppBar(title: Text('Viaje con ${cubit.driverName}')),
      body: BlocConsumer<RequestCubit, RequestState>(
        listenWhen: (a, b) => (b.error != null && a.error != b.error) || (b.tripId != null && a.tripId == null),
        listener: (context, state) {
          final tripId = state.tripId;
          if (tripId != null) {
            final assigned = cubit.assignedDriverName;
            context.go(tripLocation(tripId, assigned == null || assigned.isEmpty ? cubit.driverName : assigned));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) => Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: map(TripMapMarkers(pickup: state.pickup, dropoff: state.dropoff), cubit.setPoint),
                  ),
                  Positioned(top: 12, left: 12, right: 12, child: _PointSelector(state: state)),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _RequestPanel(state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointSelector extends StatelessWidget {
  const _PointSelector({required this.state});

  final RequestState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RequestCubit>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<RequestPoint>(
              segments: const [
                ButtonSegment(value: RequestPoint.pickup, icon: Icon(Icons.trip_origin), label: Text('Origen')),
                ButtonSegment(value: RequestPoint.dropoff, icon: Icon(Icons.place), label: Text('Destino')),
              ],
              selected: {state.editing},
              onSelectionChanged: (s) => cubit.edit(s.first),
            ),
            const SizedBox(height: 4),
            Text(
              state.editing == RequestPoint.pickup
                  ? 'Toca el mapa donde te recogen.'
                  : state.dropoff == null
                  ? 'Toca el mapa para marcar tu destino.'
                  : 'Toca el mapa para cambiar el destino.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestPanel extends StatelessWidget {
  const _RequestPanel({required this.state});

  final RequestState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RequestCubit>();
    final theme = Theme.of(context);
    final quote = state.quote;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.needsLocationPermission) ...[
          const Text(
            'Usamos tu ubicación solo para marcar dónde te recoge tu conductor. '
            'También puedes marcar el origen tocando el mapa.',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: cubit.locate,
            icon: const Icon(Icons.my_location),
            label: const Text('Usar mi ubicación'),
          ),
          const SizedBox(height: 12),
        ] else if (state.locating) ...[
          const Text('Buscando tu ubicación…'),
          const SizedBox(height: 12),
        ],
        if (cubit.cooperative != null) ...[_DispatchSelector(state: state), const SizedBox(height: 12)],
        if (!state.driverFree) ...[
          Text(
            state.coversBusyDriver
                ? '${cubit.driverName} no está libre ahora: la solicitud irá a un compañero de su cooperativa.'
                : '${cubit.driverName} no está libre ahora. No enviaremos la solicitud.',
            key: const Key('request.driverBusy'),
            style: TextStyle(color: state.coversBusyDriver ? null : theme.colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        if (state.quoting)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (quote != null) ...[
          Text('Tarifa sugerida', style: theme.textTheme.labelLarge),
          Text(
            formatMoney(quote.suggestedFareMinor, quote.currency),
            key: const Key('request.fare'),
            style: theme.textTheme.headlineMedium,
          ),
          Text('${_km(quote.distanceM)} · ${_minutes(quote.durationS)}', key: const Key('request.route')),
          const SizedBox(height: 12),
        ] else if (state.pickup != null && state.dropoff == null) ...[
          const Text('Marca tu destino en el mapa para ver la tarifa.'),
          const SizedBox(height: 12),
        ],
        FilledButton(
          key: const Key('request.submit'),
          onPressed: state.canRequest ? cubit.request : null,
          child: state.requesting
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(
                  state.dispatch == TripDispatch.cooperative
                      ? 'Pedir a ${cubit.cooperative?.name ?? 'la cooperativa'}'
                      : 'Pedir a ${cubit.driverName}',
                ),
        ),
      ],
    );
  }
}

/// Selector triple de despacho (FR-009): mi conductor, su cooperativa y, deshabilitada, la
/// opción "autónomo libre más cercano", que llega en una etapa posterior.
class _DispatchSelector extends StatelessWidget {
  const _DispatchSelector({required this.state});

  final RequestState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RequestCubit>();
    final coop = cubit.cooperative!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<TripDispatch>(
          segments: [
            ButtonSegment(
              value: TripDispatch.chosenDriver,
              icon: const Icon(Icons.person),
              label: Text('Mi conductor', key: const Key('request.dispatch.chosen')),
            ),
            ButtonSegment(
              value: TripDispatch.cooperative,
              icon: const Icon(Icons.groups),
              label: Text('Su cooperativa', key: const Key('request.dispatch.cooperative')),
            ),
          ],
          selected: {state.dispatch},
          onSelectionChanged: (s) => cubit.setDispatch(s.first),
        ),
        const SizedBox(height: 4),
        Text(
          state.dispatch == TripDispatch.cooperative
              ? 'Irá al compañero libre más cercano de ${coop.name}.'
              : 'Irá a ${cubit.driverName}.',
          textAlign: TextAlign.center,
        ),
        const ListTile(
          key: Key('request.dispatch.nearest'),
          dense: true,
          enabled: false,
          leading: Icon(Icons.near_me_outlined),
          title: Text('Autónomo libre más cercano'),
          trailing: Text('Próximamente'),
        ),
        if (state.dispatch == TripDispatch.chosenDriver)
          CheckboxListTile(
            key: const Key('request.allowDelegation'),
            dense: true,
            value: state.allowDelegation,
            onChanged: (v) => cubit.setAllowDelegation(v ?? false),
            title: Text('Si ${cubit.driverName} no puede, que me atienda un compañero de ${coop.name}'),
          ),
      ],
    );
  }
}

String _km(int meters) {
  final km = meters / 1000;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0).replaceAll('.', ',')} km';
}

String _minutes(int seconds) => '${(seconds / 60).ceil()} min';

/// Ruta del mapa de solicitud para [driver].
String requestLocation(ChosenDriver driver) => Uri(
  path: '/request/${driver.driverId}',
  queryParameters: {
    'name': driver.displayName,
    if (driver.cooperative != null) 'coopId': driver.cooperative!.id,
    if (driver.cooperative != null) 'coop': driver.cooperative!.name,
  },
).toString();
