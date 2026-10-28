import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';

import 'preconsult_cubit.dart';

/// Consulta de voz en curso: quién consulta, cuánto le queda, botón para responder y terminar.
/// No ocupa espacio si no hay consulta.
class ActivePreconsultCard extends StatelessWidget {
  const ActivePreconsultCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreconsultCubit, PreconsultState>(
      buildWhen: (a, b) => a.active != b.active,
      builder: (context, state) {
        final active = state.active;
        if (active == null) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Card(
          key: const Key('preconsult.active'),
          color: theme.colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.record_voice_over),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Consulta de voz de ${active.passengerName}', style: theme.textTheme.titleMedium),
                    ),
                    _Countdown(until: active.closesAt),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Responde con el botón, el de tu auricular o la burbuja. Máximo 15 s por turno.'),
                const SizedBox(height: 12),
                PttButton(controller: active.controller, remoteName: active.passengerName),
                TextButton(
                  key: const Key('preconsult.end'),
                  onPressed: () => context.read<PreconsultCubit>().end(),
                  child: const Text('Terminar consulta'),
                ),
              ],
            ),
          ),
        );
      },
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
    return Text('${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}', key: const Key('preconsult.countdown'));
  }
}

/// Bandeja de consultas de voz de las últimas 24 h (FR-010).
class PreconsultPage extends StatelessWidget {
  const PreconsultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultas de voz'),
        actions: [
          IconButton(
            key: const Key('preconsult.settings'),
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/preconsults/settings'),
          ),
        ],
      ),
      body: BlocBuilder<PreconsultCubit, PreconsultState>(
        builder: (context, state) => RefreshIndicator(
          onRefresh: context.read<PreconsultCubit>().load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const ActivePreconsultCard(),
              if (state.inbox.isEmpty && !state.loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aquí verás las consultas de voz de tus clientes de las últimas 24 horas. '
                    'Actívalas en Ajustes para que puedan preguntarte antes de pedir el viaje.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final p in state.inbox) _InboxTile(preconsult: p),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.preconsult});

  final Preconsult preconsult;

  @override
  Widget build(BuildContext context) {
    final at = preconsult.openedAt.toLocal();
    final hour = '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final (icon, color) = switch (preconsult.status) {
      PreconsultStatus.open => (Icons.graphic_eq, Colors.green),
      PreconsultStatus.answered => (Icons.check_circle_outline, Colors.green),
      PreconsultStatus.unanswered => (Icons.hearing, Colors.orange),
      PreconsultStatus.missed => (Icons.phone_missed, Theme.of(context).colorScheme.error),
      PreconsultStatus.unknown => (Icons.help_outline, Colors.grey),
    };
    return ListTile(
      key: Key('preconsult.inbox.${preconsult.id}'),
      leading: Icon(icon, color: color),
      title: Text(preconsult.passengerName),
      subtitle: Text('$hour · ${preconsultStatusText(preconsult.status)}'),
    );
  }
}
