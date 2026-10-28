import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import '../controller/radio_cubit.dart';

/// Etiqueta del botón grande según el turno (FR-006, FR-007).
String talkLabel(RadioState s, RadioConversation c) {
  final holder = s.holders[c.id];
  final hold = (s.me?.pushMode ?? RadioPushMode.hold) == RadioPushMode.hold;
  if (c.suspended) return 'Conversación suspendida';
  if (!c.canTalk) return 'Aquí solo puedes escuchar';
  return switch (s.talk) {
    TalkStatus.requesting when s.talkingIn == c.id => 'Pidiendo el turno…',
    TalkStatus.talking when s.talkingIn == c.id =>
      hold ? 'Hablando… suelta para terminar' : 'Hablando… toca para terminar',
    TalkStatus.busy => '${s.busyHolder ?? 'Alguien'} está hablando',
    TalkStatus.listenOnly => 'Estás en Solo escucha: cambia a Disponible para hablar',
    TalkStatus.denied => 'No puedes hablar aquí',
    TalkStatus.error => 'No se pudo tomar el turno. Inténtalo de nuevo',
    _ when holder != null => '$holder está hablando',
    _ => hold ? 'Mantén pulsado para hablar' : 'Toca para hablar',
  };
}

/// Botón redondo grande del centro de la conversación (FR-007): "Mantener para hablar" (por
/// defecto) o "Tocar para hablar". [size] permite el botón gigante del modo auto.
class TalkButton extends StatefulWidget {
  const TalkButton({super.key, required this.conversation, this.size = 168, this.highContrast = false});

  final RadioConversation conversation;
  final double size;
  final bool highContrast;

  @override
  State<TalkButton> createState() => _TalkButtonState();
}

class _TalkButtonState extends State<TalkButton> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker(bool talking) {
    if (talking && _ticker == null) {
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => setState(() {}));
    } else if (!talking && _ticker != null) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RadioCubit, RadioState>(
      builder: (context, s) {
        final cubit = context.read<RadioCubit>();
        final c = widget.conversation;
        final mine = s.talkingIn == c.id;
        final talking = mine && s.talk == TalkStatus.talking;
        _syncTicker(talking);
        final scheme = Theme.of(context).colorScheme;
        final holder = s.holders[c.id];
        final enabled = c.canTalk && !c.suspended;
        final (Color color, IconData icon) = switch (s) {
          _ when talking => (scheme.error, Icons.mic),
          _ when holder != null => (const Color(0xFF1E8E5A), Icons.graphic_eq),
          _ when s.talk == TalkStatus.busy => (const Color(0xFFE0A019), Icons.front_hand),
          _ when !enabled => (scheme.outline, Icons.hearing),
          _ => (widget.highContrast ? Colors.white : scheme.primary, Icons.mic_none),
        };
        final hold = (s.me?.pushMode ?? RadioPushMode.hold) == RadioPushMode.hold;
        final elapsed = talking && s.talkStartedAt != null ? DateTime.now().difference(s.talkStartedAt!) : null;
        final iconColor = widget.highContrast && !talking && holder == null && enabled ? Colors.black : Colors.white;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              elapsed == null ? ' ' : _clock(elapsed),
              key: const Key('radio.talk.timer'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              enabled: enabled,
              label: talkLabel(s, c),
              child: Listener(
                key: const Key('radio.talk'),
                onPointerDown: !enabled || !hold ? null : (_) => cubit.press(c.id),
                onPointerUp: !enabled || !hold ? null : (_) => cubit.release(),
                onPointerCancel: !enabled || !hold ? null : (_) => cubit.release(),
                child: GestureDetector(
                  onTap: !enabled || hold ? null : () => cubit.toggle(c.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: talking ? widget.size * 1.08 : widget.size,
                    height: talking ? widget.size * 1.08 : widget.size,
                    decoration: BoxDecoration(
                      color: enabled ? color : color.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                      border: widget.highContrast ? Border.all(color: Colors.white, width: 4) : null,
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: talking ? 24 : 8)],
                    ),
                    child: Icon(icon, color: iconColor, size: widget.size * 0.42),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              talkLabel(s, c),
              key: const Key('radio.talk.label'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        );
      },
    );
  }
}

String _clock(Duration d) =>
    '${d.inMinutes.toString().padLeft(1, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
