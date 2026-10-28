import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../controller/radio_cubit.dart';
import 'status.dart';
import 'talk_button.dart';

/// Modo auto (FR-029): para usar con el teléfono en el soporte. Botones de al menos un tercio
/// del ancho, alto contraste, flechas para cambiar de conversación y nada que escribir.
class RadioAutoPage extends StatelessWidget {
  const RadioAutoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(primary: Colors.white, surface: Colors.black, error: Color(0xFFFF5A4F)),
        scaffoldBackgroundColor: Colors.black,
      ),
      child: BlocBuilder<RadioCubit, RadioState>(
        builder: (context, s) {
          final cubit = context.read<RadioCubit>();
          final c = s.selected ?? s.conversations.firstOrNull;
          if (s.selected == null && c != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => cubit.select(c.id));
          }
          final holder = c == null ? null : s.holders[c.id];
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text('Modo auto'),
              actions: [
                IconButton(
                  key: const Key('radio.auto.speaker'),
                  tooltip: s.speakerOn ? 'Altavoz' : 'Auricular',
                  iconSize: 32,
                  onPressed: () => cubit.setSpeaker(!s.speakerOn),
                  icon: Icon(s.speakerOn ? Icons.volume_up : Icons.hearing),
                ),
              ],
            ),
            body: c == null
                ? const Center(
                    child: Text(
                      'Agrega un contacto o un canal para usar el modo auto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22),
                    ),
                  )
                : SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (c.peerStatus case final p?) ...[
                              PresenceDot(presence: p, size: 28),
                              const SizedBox(width: 12),
                            ],
                            Flexible(
                              child: Text(
                                c.title,
                                key: const Key('radio.auto.title'),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          holder != null
                              ? '$holder está hablando'
                              : c.unreadCount > 0
                              ? '${c.unreadCount} ${c.unreadCount == 1 ? 'mensaje nuevo' : 'mensajes nuevos'}'
                              : ' ',
                          style: const TextStyle(fontSize: 22, color: Colors.white70),
                        ),
                        Expanded(child: LayoutBuilder(builder: (context, box) => _controls(cubit, c.id, s, box))),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  /// Vertical: flechas de un tercio del ancho debajo del botón. Horizontal: a los lados, para
  /// que todo quepa con el teléfono en el soporte.
  Widget _controls(RadioCubit cubit, String id, RadioState s, BoxConstraints box) {
    final c = s.byId(id)!;
    final landscape = box.maxWidth > box.maxHeight;
    final side = landscape ? box.maxWidth / 5 : box.maxWidth / 3;
    final arrowHeight = landscape ? box.maxHeight * 0.5 : (side * 0.7).clamp(64.0, box.maxHeight / 3);
    final room = landscape
        ? Size(box.maxWidth - 2 * side - 48, box.maxHeight)
        : Size(box.maxWidth, box.maxHeight - arrowHeight - 24);
    // El botón con su temporizador y su texto (unos 110 px).
    final size = (room.width * 0.62).clamp(72.0, (room.height - 110).clamp(72.0, double.infinity));
    final talk = TalkButton(conversation: c, size: size, highContrast: true);
    final prev = _BigButton(
      key: const Key('radio.auto.prev'),
      width: side,
      height: arrowHeight,
      icon: Icons.arrow_back,
      label: 'Anterior',
      onTap: () => cubit.selectNext(step: -1),
    );
    final next = _BigButton(
      key: const Key('radio.auto.next'),
      width: side,
      height: arrowHeight,
      icon: Icons.arrow_forward,
      label: 'Siguiente',
      onTap: cubit.selectNext,
    );
    if (landscape) {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [prev, talk, next]);
    }
    return Column(
      children: [
        Expanded(child: Center(child: talk)),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [prev, next]),
        ),
      ],
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    super.key,
    required this.width,
    required this.height,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double width;
  final double height;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onTap,
        child: Icon(icon, size: (height * 0.5).clamp(24.0, 96.0)),
      ),
    ),
  );
}
