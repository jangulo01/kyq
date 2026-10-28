import 'package:flutter/material.dart';
import 'package:kyq_api/kyq_api.dart';

/// Texto de cada estado (FR-019).
String presenceLabel(RadioPresence p) => switch (p) {
  RadioPresence.available => 'Disponible',
  RadioPresence.busy => 'Ocupado',
  RadioPresence.listenOnly => 'Solo escucha',
  RadioPresence.offline => 'Desconectado',
};

/// Color y forma de Kyq por estado (US5-7): además del color, cada estado tiene su propio ícono
/// para quien no distingue colores.
(Color, IconData) presenceStyle(RadioPresence p) => switch (p) {
  RadioPresence.available => (const Color(0xFF1E8E5A), Icons.circle),
  RadioPresence.busy => (const Color(0xFFE0A019), Icons.do_not_disturb_on),
  RadioPresence.listenOnly => (const Color(0xFF2F6FB0), Icons.hearing),
  RadioPresence.offline => (const Color(0xFF8A8F98), Icons.radio_button_unchecked),
};

/// Marca de estado junto al nombre de un contacto o miembro.
class PresenceDot extends StatelessWidget {
  const PresenceDot({super.key, required this.presence, this.size = 14});

  final RadioPresence presence;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = presenceStyle(presence);
    return Semantics(
      label: presenceLabel(presence),
      child: Icon(icon, color: color, size: size),
    );
  }
}

/// Selector del estado propio en la barra superior (US5).
class PresenceSelector extends StatelessWidget {
  const PresenceSelector({super.key, required this.status, required this.radioOn, required this.onChanged});

  final RadioPresence status;
  final bool radioOn;
  final ValueChanged<RadioPresence> onChanged;

  @override
  Widget build(BuildContext context) {
    final shown = radioOn ? status : RadioPresence.offline;
    return PopupMenuButton<RadioPresence>(
      key: const Key('radio.status'),
      tooltip: 'Mi estado',
      initialValue: status,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final p in [RadioPresence.available, RadioPresence.busy, RadioPresence.listenOnly])
          PopupMenuItem(
            key: Key('radio.status.${p.name}'),
            value: p,
            child: Row(
              children: [
                PresenceDot(presence: p),
                const SizedBox(width: 12),
                Text(presenceLabel(p)),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PresenceDot(presence: shown),
            const SizedBox(width: 6),
            Text(presenceLabel(shown)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
