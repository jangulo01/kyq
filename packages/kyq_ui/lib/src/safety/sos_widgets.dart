import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import 'sos_cubit.dart';

/// Rojo de emergencia del botón y la pantalla de alerta.
const sosRed = Color(0xFFC62828);

/// Estados del viaje con SOS: desde ACCEPTED hasta 15 min después de COMPLETED (FR-001, la misma
/// ventana que el canal de voz). Tras COMPLETED el backend decide si aún está en la ventana.
const sosTripStatuses = {TripStatus.accepted, TripStatus.arrived, TripStatus.inProgress, TripStatus.completed};

/// Botón SOS: envía solo tras mantenerlo pulsado [hold] con anillo de progreso y vibración
/// (FR-002). Una pulsación corta llama a [onShortPress] para explicar cómo se usa.
class SosButton extends StatefulWidget {
  const SosButton({
    super.key,
    required this.onTriggered,
    this.onShortPress,
    this.hold = const Duration(seconds: 2),
    this.size = 72,
  });

  final VoidCallback onTriggered;
  final VoidCallback? onShortPress;
  final Duration hold;
  final double size;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this, duration: widget.hold)
    ..addStatusListener(_onStatus);

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    HapticFeedback.heavyImpact();
    widget.onTriggered();
  }

  void _down(PointerDownEvent _) {
    HapticFeedback.selectionClick();
    _progress.forward(from: 0);
  }

  void _up(PointerEvent _) {
    // Al enviar, la pantalla de alerta sustituye al botón aunque el dedo siga apoyado.
    if (!mounted) return;
    if (_progress.isCompleted) {
      _progress.reset();
      return;
    }
    if (_progress.isAnimating || _progress.value > 0) {
      _progress.reset();
      widget.onShortPress?.call();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Botón SOS: mantén pulsado 2 segundos para pedir ayuda',
      child: Listener(
        key: const Key('sos.button'),
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, _) => Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: sosRed,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26, offset: Offset(0, 2))],
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ),
                ),
                CircularProgressIndicator(
                  value: _progress.value,
                  strokeWidth: 6,
                  color: Colors.white,
                  backgroundColor: Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón SOS flotante de la pantalla del viaje. Muestra los avisos del [SosCubit] (pulsación
/// corta, fuera de viaje).
class SosFab extends StatelessWidget {
  const SosFab({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SosCubit>();
    return BlocListener<SosCubit, SosState>(
      listenWhen: (a, b) => b.phase == SosPhase.idle && b.message != null && a.message != b.message,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!))),
      child: SosButton(
        onTriggered: cubit.raise,
        onShortPress: () => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Mantén pulsado para pedir ayuda'))),
      ),
    );
  }
}

/// Pantalla de la alerta en curso: estado del operador y del audio, "Estoy bien" con PIN y
/// llamada al 123 (US1). Ocupa la pantalla del viaje mientras dura la alerta.
class SosActiveView extends StatelessWidget {
  const SosActiveView({super.key, required this.onCallEmergency, this.keepOpenWarning = false, this.onSetupPin});

  /// Abre el marcador con el 123 (línea de emergencias de Colombia).
  final VoidCallback onCallEmergency;

  /// Pasajero: sin servicio en primer plano, la app debe seguir abierta.
  final bool keepOpenWarning;

  /// Lleva a configurar el PIN tras una alerta sin él (US4-3).
  final VoidCallback? onSetupPin;

  Future<void> _askPin(BuildContext context) async {
    final cubit = context.read<SosCubit>();
    final pin = await showDialog<String>(context: context, builder: (_) => const SosPinDialog());
    if (pin != null) await cubit.cancel(pin);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SosCubit, SosState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final closed = state.phase == SosPhase.closed;
        final (title, detail) = switch (state) {
          SosState(phase: SosPhase.closed, cancelledByUser: true) => (
            'Alerta cancelada',
            'Cancelaste la alerta con tu PIN. El operador lo sabe.',
          ),
          SosState(phase: SosPhase.closed) => ('Alerta cerrada', 'El operador de Kyq cerró el caso.'),
          SosState(phase: SosPhase.sending, offline: true) => (
            'Sin conexión',
            'Seguimos intentando enviar la alerta. Si puedes, llama al 123.',
          ),
          SosState(phase: SosPhase.sending) => ('Enviando alerta…', 'No cierres la app.'),
          SosState(operatorConnected: true) => (
            'Ayuda en camino: un operador te escucha',
            'Habla con normalidad; tu voz y tu ubicación le llegan en vivo.',
          ),
          SosState(escalated: true) => (
            'Seguimos intentando conectar con un operador',
            'Tu ubicación se sigue enviando. Si puedes, llama al 123.',
          ),
          _ => ('Alerta enviada', 'Conectando con un operador de Kyq. Tu ubicación se envía cada segundo.'),
        };
        final voice = switch (state.voice) {
          SosVoiceStatus.connected => 'Micrófono abierto: el operador te oye y tú lo oyes en altavoz.',
          SosVoiceStatus.connecting => 'Conectando el audio…',
          SosVoiceStatus.unavailable => 'Sin audio por ahora; seguimos enviando tu ubicación.',
          SosVoiceStatus.none => null,
        };
        return ListView(
          key: const Key('sos.active'),
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              closed ? Icons.verified_user : Icons.sos,
              size: 72,
              color: closed ? theme.colorScheme.primary : sosRed,
            ),
            const SizedBox(height: 16),
            Text(title, key: const Key('sos.title'), textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            if (!closed && voice != null) ...[
              const SizedBox(height: 12),
              Text(voice, key: const Key('sos.voice'), textAlign: TextAlign.center),
            ],
            if (!closed && state.offline && state.phase == SosPhase.active) ...[
              const SizedBox(height: 8),
              const Text('Conexión inestable: reintentando.', textAlign: TextAlign.center),
            ],
            if (!closed && keepOpenWarning) ...[
              const SizedBox(height: 12),
              Card(
                color: theme.colorScheme.errorContainer,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'No cierres la app ni bloquees la pantalla mientras la alerta esté activa: así seguimos '
                    'enviando tu ubicación.',
                    key: Key('sos.keepOpen'),
                  ),
                ),
              ),
            ],
            if (state.message != null && state.phase != SosPhase.idle) ...[
              const SizedBox(height: 12),
              Text(
                state.message!,
                key: const Key('sos.message'),
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            if (!closed) ...[
              FilledButton.icon(
                key: const Key('sos.call123'),
                style: FilledButton.styleFrom(backgroundColor: sosRed),
                icon: const Icon(Icons.call),
                label: const Text('Llamar al 123'),
                onPressed: onCallEmergency,
              ),
              const SizedBox(height: 12),
              if (state.phase == SosPhase.active)
                OutlinedButton(
                  key: const Key('sos.imOk'),
                  onPressed: state.busy ? null : () => _askPin(context),
                  child: const Text('Estoy bien'),
                ),
            ] else ...[
              if (state.needsPin && onSetupPin != null) ...[
                FilledButton(
                  key: const Key('sos.setupPin'),
                  onPressed: onSetupPin,
                  child: const Text('Configura tu PIN de seguridad'),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(
                key: const Key('sos.dismiss'),
                onPressed: context.read<SosCubit>().dismiss,
                child: const Text('Volver al viaje'),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Pide el PIN de 4 dígitos para cancelar la alerta.
class SosPinDialog extends StatefulWidget {
  const SosPinDialog({super.key});

  @override
  State<SosPinDialog> createState() => _SosPinDialogState();
}

class _SosPinDialogState extends State<SosPinDialog> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Estás bien?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Escribe tu PIN de seguridad para cancelar la alerta.'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('sos.pin'),
            controller: _pin,
            autofocus: true,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'PIN'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Seguir con la alerta')),
        FilledButton(
          key: const Key('sos.pin.confirm'),
          onPressed: _pin.text.length == 4 ? () => Navigator.of(context).pop(_pin.text) : null,
          child: const Text('Cancelar alerta'),
        ),
      ],
    );
  }
}
