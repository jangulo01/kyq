import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

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
  const HealthState({this.report, this.loading = false, this.error});

  final HealthReport? report;
  final bool loading;
  final String? error;
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
    emit(HealthState(report: state.report, loading: true));
    try {
      final report = await _api.adminHealth();
      if (!isClosed) emit(HealthState(report: report));
    } on ApiException catch (e) {
      if (!isClosed) emit(HealthState(report: state.report, error: _message(e)));
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
            ],
          );
        },
      ),
    );
  }
}
