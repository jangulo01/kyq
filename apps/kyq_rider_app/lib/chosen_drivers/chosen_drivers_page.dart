import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../payments/pending_payments_banner.dart';
import '../payments/pending_payments_cubit.dart';
import '../preconsult/preconsult_page.dart';
import '../request/request_page.dart';
import '../trip/trip_route.dart';
import 'chosen_drivers_cubit.dart';

/// Pantalla principal del pasajero: sus Conductores Elegidos primero (RN-KYQ-006).
class ChosenDriversPage extends StatelessWidget {
  const ChosenDriversPage({super.key});

  Future<void> _scan(BuildContext context) async {
    final saved = await context.push<bool>('/scan');
    if (saved == true && context.mounted) await context.read<ChosenDriversCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Conductores Elegidos'),
        actions: [
          IconButton(
            key: const Key('home.safety'),
            tooltip: 'Seguridad',
            icon: const Icon(Icons.health_and_safety_outlined),
            onPressed: () => context.push('/safety'),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scan(context),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear QR'),
      ),
      body: Column(
        children: [
          BlocListener<ChosenDriversCubit, ChosenDriversState>(
            // Un conductor que vuelve a estar libre suele significar un viaje recién terminado.
            listenWhen: (a, b) => _presenceKey(a) != _presenceKey(b),
            listener: (context, _) => context.read<PendingPaymentsCubit>().load(),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: PendingPaymentsBanner()),
          ),
          BlocBuilder<ChosenDriversCubit, ChosenDriversState>(
            builder: (context, state) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ActiveTripBanner(
                load: context.read<KyqApiClient>().activeTrip,
                onOpen: (trip) => context.push(tripLocation(trip.id, _driverName(state, trip.driverId))),
                // El conductor pasa a ocupado al pedirle y a libre al terminar: ahí cambia el aviso.
                refreshKey: _presenceKey(state),
              ),
            ),
          ),
          // 008: la bolsa zonal también sirve a quien aún no tiene Conductores Elegidos (FR-001).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              key: const Key('home.nearby'),
              onPressed: () => context.push(nearbyRequestLocation),
              icon: const Icon(Icons.near_me),
              label: const Text('Pedir un viaje a un conductor cercano'),
            ),
          ),
          Expanded(child: _driverList()),
        ],
      ),
    );
  }

  static String _presenceKey(ChosenDriversState state) =>
      state.drivers.map((d) => '${d.driverId}:${d.presence.name}').join(',');

  static String _driverName(ChosenDriversState state, String driverId) =>
      state.drivers.where((d) => d.driverId == driverId).firstOrNull?.displayName ?? '';

  Widget _driverList() {
    return BlocConsumer<ChosenDriversCubit, ChosenDriversState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) {
        if (state.loading && state.drivers.isEmpty) return const Center(child: CircularProgressIndicator());
        return RefreshIndicator(
          onRefresh: context.read<ChosenDriversCubit>().load,
          child: state.drivers.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(32),
                  children: const [
                    Icon(Icons.local_taxi, size: 56),
                    SizedBox(height: 16),
                    Text(
                      'Aún no tienes conductores guardados. Escanea el código QR de tu conductor de confianza '
                      'o pide un viaje a un conductor cercano.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: state.drivers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _DriverTile(driver: state.drivers[i], canAskByVoice: state.canAskByVoice(state.drivers[i])),
                ),
        );
      },
    );
  }
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.driver, this.canAskByVoice = false});

  final ChosenDriver driver;

  /// Acepta consultas de voz y está libre (005, RN-KYQ-010).
  final bool canAskByVoice;

  Future<void> _confirmRemove(BuildContext context) async {
    final cubit = context.read<ChosenDriversCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Quitar a ${driver.displayName}?'),
        content: const Text('Dejarás de verlo aquí y de poder pedirle viajes directos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (ok == true) await cubit.remove(driver.driverId);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(driver.displayName.characters.first.toUpperCase())),
      title: Text(driver.displayName),
      // El estado va bajo el vehículo: a la derecha robaba ancho y partía el nombre en dos líneas.
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(driver.vehicleDescription),
          const SizedBox(height: 4),
          Row(
            children: [
              PresenceChip(presence: driver.presence, busyUntil: driver.busyUntilEstimate),
              const Spacer(),
              if (canAskByVoice)
                IconButton(
                  key: Key('chosen.voice.${driver.driverId}'),
                  tooltip: 'Preguntar por voz',
                  icon: const Icon(Icons.record_voice_over),
                  onPressed: () => context.push(preconsultLocation(driver.driverId, driver.displayName)),
                ),
              // Solo se pide viaje a conductores libres (FR-009, FR-012).
              if (driver.presence == DriverPresence.free)
                FilledButton.tonal(
                  key: Key('chosen.request.${driver.driverId}'),
                  // El tema da ancho completo a los botones; aquí va junto al chip.
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                  onPressed: () => context.push(requestLocation(driver)),
                  child: const Text('Pedir viaje'),
                ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
      trailing: IconButton(
        tooltip: 'Quitar de mi lista',
        icon: const Icon(Icons.more_vert),
        onPressed: () => _confirmRemove(context),
      ),
    );
  }
}

/// Libre / Ocupado (+ minutos para liberarse) / Desconectado.
class PresenceChip extends StatelessWidget {
  const PresenceChip({super.key, required this.presence, this.busyUntil, this.now});

  final DriverPresence presence;
  final DateTime? busyUntil;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (presence) {
      DriverPresence.free => ('Libre', Colors.green),
      DriverPresence.busy => (_busyLabel(), Colors.purple),
      DriverPresence.offline => ('Desconectado', Colors.grey),
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: CircleAvatar(backgroundColor: color, radius: 5),
      label: Text(label),
    );
  }

  String _busyLabel() {
    final until = busyUntil;
    if (until == null) return 'Ocupado';
    final minutes = until.difference(now ?? DateTime.now()).inMinutes;
    return minutes <= 1 ? 'Se libera ya' : 'Ocupado · $minutes min';
  }
}
