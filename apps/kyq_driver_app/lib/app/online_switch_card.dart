import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import '../presence/presence_cubit.dart';

/// Interruptor ONLINE/OFFLINE con el motivo de bloqueo y el asistente de permisos (T056).
class OnlineSwitchCard extends StatelessWidget {
  const OnlineSwitchCard({super.key, required this.state});

  final PresenceState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<PresenceCubit>();
    final me = state.me!;
    final (title, subtitle) = switch (state.presence) {
      DriverPresence.offline => ('OFFLINE', 'No recibes viajes.'),
      DriverPresence.free => ('ONLINE', 'Tus clientes pueden pedirte viajes.'),
      DriverPresence.busy => ('ONLINE · En un viaje', 'No recibirás ofertas hasta terminarlo.'),
    };
    // Bloqueado solo impide conectarse: nunca se interrumpe un viaje ni se impide desconectarse (FR-003).
    final canToggle = !state.busy && (state.online || me.canGoOnline);
    return BlocListener<PresenceCubit, PresenceState>(
      listenWhen: (a, b) => !a.needsPermissions && b.needsPermissions,
      listener: (context, _) => _explainPermissions(context),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              key: const Key('home.online'),
              secondary: Icon(
                state.online ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                color: state.online ? Colors.green : null,
              ),
              title: Text(title, style: theme.textTheme.titleMedium),
              subtitle: Text(subtitle),
              value: state.online,
              onChanged: canToggle ? cubit.setOnline : null,
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  state.error!,
                  key: const Key('home.error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _explainPermissions(BuildContext context) async {
    final cubit = context.read<PresenceCubit>();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Antes de conectarte'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para recibir viajes, Kyq necesita:'),
            SizedBox(height: 12),
            _PermissionLine(
              icon: Icons.location_on,
              text: 'Ubicación "todo el tiempo": tu pasajero te ve llegar aunque uses Waze o la pantalla esté apagada.',
            ),
            _PermissionLine(
              icon: Icons.notifications,
              text: 'Notificaciones: un aviso fijo te recuerda que estás ONLINE.',
            ),
            _PermissionLine(icon: Icons.mic, text: 'Micrófono: para hablar con tu pasajero por walkie-talkie.'),
            _PermissionLine(
              icon: Icons.battery_charging_full,
              text: 'Sin ahorro de batería para Kyq: así el sistema no corta la conexión.',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Ahora no')),
          FilledButton(
            key: const Key('permissions.continue'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await cubit.grantPermissionsAndGoOnline();
    } else {
      cubit.dismissPermissions();
    }
  }
}

class _PermissionLine extends StatelessWidget {
  const _PermissionLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
