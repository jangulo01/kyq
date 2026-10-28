import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'emergency_cubits.dart';

String sosOutcomeLabel(SosOutcome o) => switch (o) {
  SosOutcome.falseAlarm => 'Falsa alarma',
  SosOutcome.resolved => 'Resuelto',
  SosOutcome.escalatedAuthorities => 'Derivado a autoridades',
  SosOutcome.noResponse => 'Sin respuesta',
};

String sosStatusLabel(SosAlertSummary a) => switch (a.status) {
  SosStatus.open => 'Sin tomar',
  SosStatus.claimed => 'Tomada por ${a.claimedByName ?? 'un operador'}',
  SosStatus.closed => 'Cerrada',
  SosStatus.cancelledByUser => 'Cancelada por el usuario',
};

String sosRoleLabel(SosRole r) => r == SosRole.driver ? 'Conductor' : 'Pasajero';

/// Tiempo transcurrido como `mm:ss` o `h:mm:ss`.
String formatElapsed(Duration d) {
  final s = d.inSeconds.abs();
  final mm = ((s ~/ 60) % 60).toString().padLeft(2, '0');
  final ss = (s % 60).toString().padLeft(2, '0');
  return s >= 3600 ? '${s ~/ 3600}:$mm:$ss' : '$mm:$ss';
}

/// Tiempo de espera que avanza cada segundo.
class ElapsedText extends StatefulWidget {
  const ElapsedText({super.key, required this.since, this.style});

  final DateTime since;
  final TextStyle? style;

  @override
  State<ElapsedText> createState() => _ElapsedTextState();
}

class _ElapsedTextState extends State<ElapsedText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text(formatElapsed(DateTime.now().difference(widget.since)), style: widget.style);
}

/// Consola de emergencias (US2): cola en vivo de alertas abiertas e historial de cerradas.
class EmergenciesPage extends StatelessWidget {
  const EmergenciesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Emergencias'),
          actions: [
            BlocBuilder<SosQueueCubit, SosQueueState>(
              buildWhen: (a, b) => a.onDuty != b.onDuty,
              builder: (context, state) => Row(
                children: [
                  const Text('De guardia'),
                  Switch(
                    key: const Key('ops.duty'),
                    value: state.onDuty ?? false,
                    onChanged: state.onDuty == null ? null : context.read<SosQueueCubit>().setOnDuty,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Recargar',
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<SosQueueCubit>().load(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('ops.tab.queue'), text: 'Alertas abiertas'),
              Tab(key: Key('ops.tab.history'), text: 'Historial'),
            ],
          ),
        ),
        body: const TabBarView(children: [_Queue(), _History()]),
      ),
    );
  }
}

class _Queue extends StatelessWidget {
  const _Queue();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SosQueueCubit, SosQueueState>(
      builder: (context, state) {
        if (state.loading && state.alerts.isEmpty) return const Center(child: CircularProgressIndicator());
        if (state.error != null && state.alerts.isEmpty) return Center(child: Text(state.error!));
        if (state.alerts.isEmpty) return const Center(child: Text('No hay alertas abiertas.'));
        // La más reciente arriba (US2-1); el tiempo de espera dice cuál lleva más.
        final alerts = [...state.alerts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) => AlertCard(alert: alerts[i]),
        );
      },
    );
  }
}

/// Fila de una alerta en la cola.
class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert});

  final SosAlertSummary alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = alert.status == SosStatus.open;
    return Card(
      key: Key('ops.alert.${alert.id}'),
      color: open ? theme.colorScheme.errorContainer : null,
      child: ListTile(
        leading: Icon(Icons.sos, color: open ? sosRed : theme.colorScheme.primary, size: 36),
        title: Text('${sosRoleLabel(alert.raisedRole)}: ${alert.raisedByName}'),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(sosStatusLabel(alert)),
            if (alert.cancelWithoutPin)
              const Chip(
                key: Key('ops.alert.noPin'),
                avatar: Icon(Icons.warning_amber, size: 18),
                label: Text('Cancelación sin PIN'),
              ),
            if (alert.escalated) const Chip(label: Text('Avisada a la guardia por SMS')),
            if (alert.lastLocation == null) const Chip(label: Text('Sin ubicación aún')),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Esperando'),
            ElapsedText(since: alert.createdAt, style: theme.textTheme.titleMedium),
          ],
        ),
        onTap: () async {
          final queue = context.read<SosQueueCubit>();
          await context.push('/emergencies/${alert.id}');
          await queue.load();
        },
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History();

  Future<void> _pickRange(BuildContext context) async {
    final cubit = context.read<SosHistoryCubit>();
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: switch ((cubit.state.from, cubit.state.to)) {
        (final from?, final to?) => DateTimeRange(start: from, end: to),
        _ => null,
      },
    );
    if (range != null) await cubit.load(from: range.start, to: range.end);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SosHistoryCubit>();
    return BlocBuilder<SosHistoryCubit, SosHistoryState>(
      builder: (context, state) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<SosOutcome?>(
                  key: const Key('ops.history.outcome'),
                  value: state.outcome,
                  hint: const Text('Todos los desenlaces'),
                  items: [
                    const DropdownMenuItem(child: Text('Todos los desenlaces')),
                    for (final o in SosOutcome.values) DropdownMenuItem(value: o, child: Text(sosOutcomeLabel(o))),
                  ],
                  onChanged: (o) => cubit.load(outcome: o, from: state.from, to: state.to, keepFilters: false),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    state.from == null ? 'Últimos 30 días' : '${formatDate(state.from!)} – ${formatDate(state.to!)}',
                  ),
                  onPressed: () => _pickRange(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (state) {
              SosHistoryState(loading: true, alerts: []) => const Center(child: CircularProgressIndicator()),
              SosHistoryState(:final error?, alerts: []) => Center(child: Text(error)),
              SosHistoryState(alerts: []) => const Center(child: Text('Sin alertas en ese periodo.')),
              _ => ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.alerts.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final a = state.alerts[i];
                  return ListTile(
                    key: Key('ops.history.${a.id}'),
                    leading: Icon(a.hasRecording ? Icons.graphic_eq : Icons.sos),
                    title: Text('${sosRoleLabel(a.raisedRole)}: ${a.raisedByName}'),
                    subtitle: Text(
                      [
                        formatDate(a.createdAt.toLocal()),
                        a.outcome == null ? sosStatusLabel(a) : sosOutcomeLabel(a.outcome!),
                        if (a.claimedByName != null) 'atendió ${a.claimedByName}',
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/emergencies/${a.id}'),
                  );
                },
              ),
            },
          ),
        ],
      ),
    );
  }
}
