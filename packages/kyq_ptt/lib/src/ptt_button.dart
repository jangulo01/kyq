import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ptt_controller.dart';

/// Botón del walkie-talkie: mantener pulsado para hablar (T073, FR-017).
///
/// Muestra quién habla, el turno ocupado y el micrófono denegado.
class PttButton extends StatelessWidget {
  const PttButton({super.key, required this.controller, this.remoteName = 'la otra parte'});

  final PttController controller;

  /// Nombre de la otra parte para "Habla Carlos".
  final String remoteName;

  String _label(PttState s) => switch (s.status) {
    PttStatus.inactive || PttStatus.connecting => 'Conectando el walkie-talkie…',
    PttStatus.reconnecting => 'Reconectando la voz…',
    PttStatus.idle => 'Mantén pulsado para hablar',
    PttStatus.requesting => 'Pidiendo el turno…',
    PttStatus.talking => 'Hablando… suelta para terminar',
    PttStatus.remoteTalking => 'Habla $remoteName',
    PttStatus.busy => '$remoteName está hablando. Espera a que termine.',
    PttStatus.micDenied when s.micBlocked => 'Activa el micrófono en los ajustes para hablar.',
    PttStatus.micDenied => 'Necesitamos el micrófono para hablar. Pulsa de nuevo para permitirlo.',
    PttStatus.error => 'No se pudo tomar el turno. Inténtalo de nuevo.',
    PttStatus.closed => '',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PttController, PttState>(
      bloc: controller,
      builder: (context, state) {
        if (state.status == PttStatus.closed) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final (color, icon) = switch (state.status) {
          PttStatus.talking => (scheme.error, Icons.mic),
          PttStatus.remoteTalking => (Colors.green.shade700, Icons.volume_up),
          PttStatus.busy => (Colors.orange.shade800, Icons.front_hand),
          PttStatus.micDenied => (scheme.outline, Icons.mic_off),
          PttStatus.idle || PttStatus.requesting || PttStatus.error => (scheme.primary, Icons.mic_none),
          _ => (scheme.outline, Icons.wifi_tethering),
        };
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label(state),
              key: const Key('ptt.label'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Mantén pulsado para hablar',
              child: Listener(
                key: const Key('ptt.button'),
                onPointerDown: (_) => controller.press(),
                onPointerUp: (_) => controller.release(),
                onPointerCancel: (_) => controller.release(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: state.status == PttStatus.talking ? 96 : 84,
                  height: state.status == PttStatus.talking ? 96 : 84,
                  decoration: BoxDecoration(
                    color: state.canPress || state.status == PttStatus.talking ? color : color.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 40),
                ),
              ),
            ),
            if (state.status == PttStatus.micDenied && state.micBlocked)
              TextButton(
                key: const Key('ptt.settings'),
                onPressed: controller.openMicSettings,
                child: const Text('Abrir ajustes'),
              ),
          ],
        );
      },
    );
  }
}
