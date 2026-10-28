import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

String _message(ApiException e) => switch (e.code) {
  'network' => 'Sin conexión con el servidor.',
  _ => e.message.isEmpty ? 'Algo salió mal (${e.code}).' : e.message,
};

/// Periodos rápidos en semanas.
const crmPeriods = [4, 12, 26, 52];

class CrmState {
  const CrmState({required this.to, this.weeks = 12, this.report, this.loading = false, this.error});

  final DateTime to;
  final int weeks;
  final CrmReport? report;
  final bool loading;
  final String? error;

  /// Primer día del periodo: [weeks] semanas completas que terminan en [to].
  DateTime get from => DateTime(to.year, to.month, to.day - weeks * 7 + 1);
}

/// Fidelización (T024, FR-010–FR-013).
class CrmCubit extends Cubit<CrmState> {
  CrmCubit(this._api, {DateTime? now})
    : super(
        CrmState(
          to: DateTime((now ?? DateTime.now()).year, (now ?? DateTime.now()).month, (now ?? DateTime.now()).day),
        ),
      );

  final KyqApiClient _api;

  Future<void> load() async {
    final current = state;
    emit(CrmState(to: current.to, weeks: current.weeks, report: current.report, loading: true));
    try {
      final report = await _api.adminCrm(from: current.from, to: current.to);
      if (state.weeks == current.weeks && state.to == current.to) {
        emit(CrmState(to: current.to, weeks: current.weeks, report: report));
      }
    } on ApiException catch (e) {
      emit(CrmState(to: current.to, weeks: current.weeks, report: current.report, error: _message(e)));
    }
  }

  Future<void> setWeeks(int weeks) {
    emit(CrmState(to: state.to, weeks: weeks));
    return load();
  }
}

String _pct(double? v) => v == null ? '—' : '${(v * 100).toStringAsFixed(1).replaceAll('.', ',')} %';

/// Fidelización: afiliaciones, repetición, SC-008 y conductores elegidos que pierden afiliados.
class CrmPage extends StatelessWidget {
  const CrmPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CrmCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fidelización'),
        actions: [IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load)],
      ),
      body: BlocBuilder<CrmCubit, CrmState>(
        builder: (context, state) {
          final r = state.report;
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SegmentedButton<int>(
                    key: const Key('crm.period'),
                    segments: [for (final w in crmPeriods) ButtonSegment(value: w, label: Text('$w semanas'))],
                    selected: {state.weeks},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => cubit.setWeeks(s.first),
                  ),
                  Text('Del ${formatDate(state.from)} al ${formatDate(state.to)}'),
                ],
              ),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) Padding(padding: const EdgeInsets.all(8), child: Text(state.error!)),
              if (r != null) ...[
                const SizedBox(height: 16),
                _Sc008Card(sc: r.sc008),
                const SizedBox(height: 16),
                Text('Afiliaciones', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Kpi(keyName: 'active', label: 'Activas hoy', value: formatCount(r.affiliations.activeNow)),
                    _Kpi(keyName: 'created', label: 'Nuevas', value: formatCount(r.affiliations.created)),
                    _Kpi(keyName: 'removed', label: 'Bajas', value: formatCount(r.affiliations.removed)),
                    _Kpi(keyName: 'net', label: 'Saldo', value: formatCount(r.affiliations.net)),
                    _Kpi(keyName: 'churn', label: 'Abandono', value: _pct(r.affiliations.churnRate)),
                  ],
                ),
                const SizedBox(height: 12),
                _WeeklyBars(weeks: r.affiliations.weekly),
                const SizedBox(height: 16),
                Text('Viajes repetidos con el mismo conductor', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Kpi(keyName: 'pairs', label: 'Parejas con viajes', value: formatCount(r.repeat.pairs)),
                    _Kpi(keyName: 'repeatPairs', label: 'Repiten (2 o más)', value: formatCount(r.repeat.repeatPairs)),
                    _Kpi(keyName: 'repeatRate', label: 'Tasa de repetición', value: _pct(r.repeat.repeatRate)),
                    _Kpi(
                      keyName: 'avgTrips',
                      label: 'Viajes por pareja',
                      value: r.repeat.avgTripsPerPair?.toStringAsFixed(1).replaceAll('.', ',') ?? '—',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Conductores elegidos que pierden afiliados', style: theme.textTheme.titleMedium),
                if (r.churnedDrivers.isEmpty) const Text('Ninguna baja en el periodo.'),
                for (final d in r.churnedDrivers)
                  ListTile(
                    key: ValueKey('crm.churned.${d.driverId}'),
                    dense: true,
                    leading: const Icon(Icons.trending_down),
                    title: Text(d.displayName),
                    subtitle: Text('${d.removed} bajas · ${d.activeNow} afiliados activos'),
                  ),
                const SizedBox(height: 16),
                Text('Conductores elegidos sin viajes en 30 días', style: theme.textTheme.titleMedium),
                if (r.inactiveChosenDrivers.isEmpty)
                  const Text('Todos los conductores con afiliados tienen viajes recientes.'),
                for (final d in r.inactiveChosenDrivers)
                  ListTile(
                    key: ValueKey('crm.inactive.${d.driverId}'),
                    dense: true,
                    leading: const Icon(Icons.hourglass_bottom),
                    title: Text(d.displayName),
                    subtitle: Text(
                      '${d.activeAffiliations} afiliados · '
                      '${d.lastCompletedAt == null ? 'nunca completó un viaje' : 'último viaje el ${formatDate(d.lastCompletedAt!)}'}',
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Sc008Card extends StatelessWidget {
  const _Sc008Card({required this.sc});

  final Sc008 sc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final met = sc.met;
    final color = met == null
        ? scheme.surfaceContainerHighest
        : met
        ? scheme.primaryContainer
        : scheme.errorContainer;
    final verdict = met == null
        ? 'Aún no hay afiliaciones con 30 días cumplidos'
        : met
        ? 'Cumple la meta del ${_pct(sc.target)}'
        : 'Por debajo de la meta del ${_pct(sc.target)}';
    return Card(
      key: const Key('crm.sc008'),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SC-008: piden viaje a su conductor en 30 días', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(_pct(sc.rate), key: const Key('crm.sc008.rate'), style: Theme.of(context).textTheme.headlineMedium),
            Text(verdict, key: const Key('crm.sc008.verdict')),
            Text(
              '${sc.withRequest30d} de ${sc.matured} afiliaciones con 30 días cumplidos · ${sc.pending} en curso',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.keyName, required this.label, required this.value});

  final String keyName;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 170,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, key: Key('crm.kpi.$keyName'), style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

/// Serie semanal: afiliaciones activas al cierre de cada semana, con nuevas y bajas.
class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.weeks});

  final List<CrmWeek> weeks;

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final maxActive = weeks.map((w) => w.activeEnd).fold(1, math.max);
    return SizedBox(
      height: 160,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final w in weeks)
              Tooltip(
                message:
                    'Semana del ${formatDate(w.weekStart)}: ${w.activeEnd} activas, ${w.created} nuevas, ${w.removed} bajas',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${w.activeEnd}', style: Theme.of(context).textTheme.labelSmall),
                      Container(
                        key: ValueKey('crm.week.${formatDate(w.weekStart)}'),
                        width: 22,
                        height: 100 * w.activeEnd / maxActive + 2,
                        color: scheme.primary,
                      ),
                      Text('${w.weekStart.day}/${w.weekStart.month}', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
