import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:url_launcher/url_launcher.dart';

String _message(ApiException e) => switch (e.code) {
  'network' => 'Sin conexión con el servidor: el backend no responde.',
  _ => e.message.isEmpty ? 'Algo salió mal (${e.code}).' : e.message,
};

const dependencyLabels = {
  'database': 'Base de datos',
  'centrifugo': 'Tiempo real (Centrifugo)',
  'livekit': 'Voz PTT (LiveKit)',
  'osrm': 'Rutas (OSRM)',
  'storage': 'Documentos (almacenamiento S3)',
  'bold': 'Pagos (Bold)',
};

const statusLabels = {
  HealthStatus.ok: 'Disponible',
  HealthStatus.down: 'Caído',
  HealthStatus.disabled: 'Desactivado',
  HealthStatus.degraded: 'Degradado',
};

const overallLabels = {
  HealthStatus.ok: 'Operativo',
  HealthStatus.degraded: 'Degradado',
  HealthStatus.down: 'Caído',
  HealthStatus.disabled: 'Desactivado',
};

class HealthState {
  const HealthState({this.report, this.loading = false, this.error, this.sessions});

  final HealthReport? report;
  final bool loading;
  final String? error;

  /// 009: sesiones sin fallos por app; null si no se pudo leer.
  final SessionsReport? sessions;
}

/// Salud de las dependencias (T031, FR-018–FR-020); se refresca cada [refreshEvery].
class HealthCubit extends Cubit<HealthState> {
  HealthCubit(this._api, {this.refreshEvery = const Duration(seconds: 30)}) : super(const HealthState());

  final KyqApiClient _api;
  final Duration refreshEvery;
  Timer? _timer;

  Future<void> start() {
    _timer = Timer.periodic(refreshEvery, (_) => load());
    return load();
  }

  Future<void> load() async {
    if (state.loading) return;
    emit(HealthState(report: state.report, loading: true, sessions: state.sessions));
    final sessions = _sessions();
    try {
      final report = await _api.adminHealth();
      final s = await sessions;
      if (!isClosed) emit(HealthState(report: report, sessions: s ?? state.sessions));
    } on ApiException catch (e) {
      final s = await sessions;
      if (!isClosed) emit(HealthState(report: state.report, error: _message(e), sessions: s ?? state.sessions));
    }
  }

  /// Las sesiones nunca rompen la página (009, FR-018).
  Future<SessionsReport?> _sessions() async {
    try {
      return await _api.healthSessions();
    } on Object {
      return null;
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

Color statusColor(ColorScheme scheme, HealthStatus s) => switch (s) {
  HealthStatus.ok => const Color(0xFF2E7D32),
  HealthStatus.degraded => const Color(0xFFEF6C00),
  HealthStatus.down => scheme.error,
  HealthStatus.disabled => scheme.outline,
};

IconData _icon(HealthStatus s) => switch (s) {
  HealthStatus.ok => Icons.check_circle,
  HealthStatus.degraded => Icons.warning_amber,
  HealthStatus.down => Icons.error,
  HealthStatus.disabled => Icons.remove_circle_outline,
};

String _time(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
}

/// Healthline: estado global y una tarjeta por dependencia con su latencia.
class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HealthCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salud de la plataforma'),
        actions: [IconButton(tooltip: 'Comprobar ahora', icon: const Icon(Icons.refresh), onPressed: cubit.load)],
      ),
      body: BlocBuilder<HealthCubit, HealthState>(
        builder: (context, state) {
          final r = state.report;
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null)
                Card(
                  color: scheme.errorContainer,
                  child: ListTile(leading: const Icon(Icons.cloud_off), title: Text(state.error!)),
                ),
              if (r != null) ...[
                Card(
                  child: ListTile(
                    leading: Icon(_icon(r.status), color: statusColor(scheme, r.status), size: 36),
                    title: Text(
                      overallLabels[r.status]!,
                      key: const Key('health.overall'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: statusColor(scheme, r.status)),
                    ),
                    subtitle: Text('Comprobado a las ${_time(r.checkedAt)} · se actualiza cada 30 s'),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in r.checks)
                      SizedBox(
                        width: 320,
                        child: Card(
                          key: ValueKey('health.check.${c.name}'),
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: Icon(_icon(c.status), color: statusColor(scheme, c.status)),
                            title: Text(dependencyLabels[c.name] ?? c.name),
                            subtitle: Text('${statusLabels[c.status]} · ${c.detail}'),
                            trailing: Text(
                              c.latencyMs == null ? '—' : '${c.latencyMs} ms',
                              key: Key('health.latency.${c.name}'),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (state.sessions != null) ...[const SizedBox(height: 16), _SessionsCard(report: state.sessions!)],
            ],
          );
        },
      ),
    );
  }
}

const _appLabels = {'driver': 'Kyq Conductor', 'rider': 'Kyq Pasajero', 'admin': 'Panel'};

String _pct(double? v) => v == null ? '—' : '${(v * 100).toStringAsFixed(2).replaceAll('.', ',')} %';

/// 009: porcentaje de sesiones sin fallos por app (FR-017), con "no configurado" o "no
/// disponible" cuando la herramienta de errores no responde (FR-018).
class _SessionsCard extends StatelessWidget {
  const _SessionsCard({required this.report});

  final SessionsReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final target = _pct(report.target);
    return Card(
      key: const Key('health.sessions'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sesiones sin fallos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            switch (report.status) {
              'not_configured' => const Text(
                'No configurado: el backend no tiene acceso de lectura a la herramienta de errores.',
                key: Key('health.sessions.status'),
              ),
              'unavailable' => const Text(
                'No disponible: la herramienta de errores no respondió. Se reintenta en la próxima comprobación.',
                key: Key('health.sessions.status'),
              ),
              _ => Text('Meta: $target o más · últimas 24 horas y 7 días', style: theme.textTheme.bodySmall),
            },
            for (final a in report.apps)
              ListTile(
                key: ValueKey('health.sessions.${a.app}'),
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  a.belowTarget ? Icons.warning_amber : Icons.check_circle,
                  color: a.belowTarget ? scheme.error : const Color(0xFF2E7D32),
                ),
                title: Text(_appLabels[a.app] ?? a.app),
                subtitle: Text(
                  '24 h: ${_pct(a.crashFree24h)} · 7 días: ${_pct(a.crashFree7d)}'
                  '${a.topRelease == null ? '' : ' · versión más usada ${a.topRelease}'}',
                  style: a.belowTarget ? TextStyle(color: scheme.error, fontWeight: FontWeight.w600) : null,
                ),
                trailing: a.link.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Ver en la herramienta de errores',
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => launchUrl(Uri.parse(a.link), webOnlyWindowName: '_blank'),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
