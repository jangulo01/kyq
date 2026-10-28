import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_ptt/kyq_ptt.dart';

import 'preconsult_cubit.dart';

/// Ruta de la consulta de voz con un conductor.
String preconsultLocation(String driverId, String driverName) =>
    Uri(path: '/preconsult/$driverId', queryParameters: {'name': driverName}).toString();

/// Preguntar por voz al conductor antes de pedir el viaje (RN-KYQ-010).
class PreconsultPage extends StatelessWidget {
  const PreconsultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PreconsultCubit>();
    // Volver atrás termina la consulta; "Pedir viaje" la deja abierta debajo.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(cubit.end());
      },
      child: _scaffold(cubit),
    );
  }

  Widget _scaffold(PreconsultCubit cubit) {
    return Scaffold(
      appBar: AppBar(title: Text('Preguntar a ${cubit.driverName}')),
      body: BlocBuilder<PreconsultCubit, PreconsultViewState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final (icon, title, detail) = switch (state.phase) {
            PreconsultPhase.opening => (Icons.hourglass_top, 'Abriendo la consulta…', null),
            PreconsultPhase.waiting => (
              Icons.ring_volume,
              'Llamando a ${cubit.driverName}…',
              'Podrás hablar en cuanto su app se conecte.',
            ),
            PreconsultPhase.ready => (
              Icons.hearing,
              '${cubit.driverName} te escucha',
              'Mantén pulsado para hablar, máximo 15 s por turno. Por ejemplo: "¿estás cerca de Unicentro?"',
            ),
            PreconsultPhase.closed => (Icons.check_circle_outline, state.message ?? 'La consulta terminó.', null),
            PreconsultPhase.failed => (Icons.info_outline, state.message ?? 'No pudimos abrir la consulta.', null),
          };
          final open = state.phase == PreconsultPhase.waiting || state.phase == PreconsultPhase.ready;
          final closesAt = state.preconsult?.closesAt;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(icon, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                key: const Key('preconsult.title'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (detail != null) ...[const SizedBox(height: 8), Text(detail, textAlign: TextAlign.center)],
              if (open && closesAt != null) ...[const SizedBox(height: 8), _Countdown(until: closesAt)],
              const SizedBox(height: 24),
              if (state.phase == PreconsultPhase.ready && state.ptt != null)
                PttButton(controller: state.ptt!, remoteName: cubit.driverName),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('preconsult.request'),
                icon: const Icon(Icons.local_taxi),
                label: const Text('Pedir viaje'),
                onPressed: () => context.push(
                  Uri(path: '/request/${cubit.driverId}', queryParameters: {'name': cubit.driverName}).toString(),
                ),
              ),
              if (open)
                TextButton(
                  key: const Key('preconsult.end'),
                  onPressed: cubit.end,
                  child: const Text('Terminar consulta'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Countdown extends StatefulWidget {
  const _Countdown({required this.until});

  final DateTime until;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late final Timer _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.until.difference(DateTime.now());
    final s = left.isNegative ? 0 : left.inSeconds;
    return Text(
      'La consulta se cierra en ${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}',
      key: const Key('preconsult.countdown'),
      textAlign: TextAlign.center,
    );
  }
}
