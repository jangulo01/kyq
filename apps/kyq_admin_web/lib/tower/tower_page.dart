import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'tower_cubit.dart';
import 'tower_map.dart';

const levelLabels = {
  PressureLevel.noSupply: 'Sin oferta',
  PressureLevel.high: 'Presión alta',
  PressureLevel.balanced: 'Equilibrado',
  PressureLevel.none: 'Sin demanda',
};

String _time(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
}

/// Torre de control (T017): mapa de hexágonos H3 con conductores, viajes y solicitudes, totales y
/// zonas con presión; se actualiza sola.
class TowerPage extends StatelessWidget {
  const TowerPage({super.key, this.map = maplibreTowerMap});

  final TowerMapBuilder map;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TowerCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torre de control'),
        actions: [
          BlocBuilder<TowerCubit, TowerState>(
            buildWhen: (a, b) => a.live != b.live,
            builder: (context, state) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                key: const Key('tower.live'),
                avatar: Icon(state.live ? Icons.sensors : Icons.schedule, size: 18),
                label: Text(state.live ? 'En vivo' : 'Actualización periódica'),
              ),
            ),
          ),
          IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load),
        ],
      ),
      body: BlocBuilder<TowerCubit, TowerState>(
        builder: (context, state) {
          final snapshot = state.snapshot;
          final header = _Header(state: state);
          if (snapshot == null) {
            return Column(
              children: [
                header,
                Expanded(
                  child: Center(child: state.error != null ? Text(state.error!) : const CircularProgressIndicator()),
                ),
              ],
            );
          }
          final panel = _SidePanel(state: state);
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 1000) {
                return Column(
                  children: [
                    header,
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: map(snapshot)),
                          SizedBox(width: 380, child: panel),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  header,
                  SizedBox(height: constraints.maxHeight * 0.5, child: map(snapshot)),
                  Expanded(child: panel),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final TowerState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TowerCubit>();
    final snapshot = state.snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Tamaño del hexágono'),
              SegmentedButton<int>(
                key: const Key('tower.resolution'),
                segments: [
                  for (final r in towerResolutions)
                    ButtonSegment(value: r, label: Text('Res. $r'), tooltip: _resolutionHint(r)),
                ],
                selected: {state.resolution},
                showSelectedIcon: false,
                onSelectionChanged: (s) => cubit.setResolution(s.first),
              ),
              if (snapshot != null)
                Text(
                  'Actualizado ${_time(snapshot.generatedAt)} · solicitudes de los últimos ${snapshot.windowMinutes} min',
                  key: const Key('tower.updated'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        if (state.loading) const LinearProgressIndicator() else const SizedBox(height: 4),
        if (state.error != null && snapshot != null)
          MaterialBanner(
            content: Text(state.error!),
            actions: [TextButton(onPressed: cubit.load, child: const Text('Reintentar'))],
          ),
      ],
    );
  }

  static String _resolutionHint(int r) => switch (r) {
    6 => 'Zonas grandes (~36 km²)',
    7 => 'Barrios (~5 km²)',
    8 => 'Sectores (~0,7 km²)',
    _ => 'Manzanas (~0,1 km²)',
  };
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.state});

  final TowerState state;

  @override
  Widget build(BuildContext context) {
    final t = state.snapshot!.totals;
    final theme = Theme.of(context);
    final cells = state.pressureCells;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Stat(keyName: 'online', label: 'ONLINE', value: t.online),
            _Stat(keyName: 'free', label: 'Libres', value: t.free, color: freeColor),
            _Stat(keyName: 'busy', label: 'Ocupados', value: t.busy, color: busyColor),
            _Stat(keyName: 'trips', label: 'Viajes activos', value: t.activeTrips),
            _Stat(keyName: 'requests', label: 'Solicitudes (1 h)', value: t.requests),
            _Stat(
              keyName: 'unserved',
              label: 'No atendidas',
              value: t.unservedRequests,
              color: t.unservedRequests > 0 ? theme.colorScheme.error : null,
            ),
          ],
        ),
        if (t.withoutLocation > 0 || t.stale > 0) ...[
          const SizedBox(height: 8),
          Text(
            [
              if (t.withoutLocation > 0) '${t.withoutLocation} sin ubicación',
              if (t.stale > 0) '${t.stale} con ubicación desactualizada',
            ].join(' · '),
            key: const Key('tower.locationWarning'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final e in levelLabels.entries) _Legend(color: levelColors[e.key]!, label: e.value),
            const _Legend(color: freeColor, label: 'Libre', dot: true),
            const _Legend(color: busyColor, label: 'Ocupado', dot: true),
          ],
        ),
        const SizedBox(height: 16),
        Text('Zonas con demanda', style: theme.textTheme.titleMedium),
        if (cells.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Sin solicitudes en la última hora.')),
        for (final c in cells)
          ListTile(
            key: ValueKey('tower.cell.${c.cell}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.hexagon, color: levelColors[c.level]),
            title: Text(levelLabels[c.level]!),
            subtitle: Text(
              '${c.requests} solicitudes (${c.unservedRequests} no atendidas) · '
              '${c.freeDrivers} libres · ${c.busyDrivers} ocupados · ${c.activeTrips} viajes',
            ),
            trailing: c.pressure == null ? null : Text('×${c.pressure!.toStringAsFixed(1)}'),
          ),
        const SizedBox(height: 16),
        Text('Conductores ONLINE', style: theme.textTheme.titleMedium),
        for (final d in state.snapshot!.drivers)
          ListTile(
            key: ValueKey('tower.driver.${d.driverId}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.circle, size: 14, color: d.presence == DriverPresence.busy ? busyColor : freeColor),
            title: Text(d.displayName),
            subtitle: Text(
              '${d.presence == DriverPresence.busy ? 'Ocupado' : 'Libre'} · '
              '${d.stale ? 'ubicación desactualizada (${_time(d.locationAt)})' : 'ubicación ${_time(d.locationAt)}'}',
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.keyName, required this.label, required this.value, this.color});

  final String keyName;
  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 108,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatCount(value),
                key: Key('tower.total.$keyName'),
                style: theme.textTheme.headlineSmall?.copyWith(color: color),
              ),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.dot = false});

  final Color color;
  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(dot ? Icons.circle : Icons.hexagon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
