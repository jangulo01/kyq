import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'megaphone_cubit.dart';
import 'tower_cubit.dart';
import 'tower_map.dart';
import 'trip_inspection_view.dart';

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
          final taps = TowerMapTaps(
            selected: state.selected,
            onDriver: (id) => openDriverTrip(context, state, id),
            onCell: (cell) => showCellSheet(context, cell),
          );
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
                          Expanded(child: map(snapshot, taps)),
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
                  SizedBox(height: constraints.maxHeight * 0.5, child: map(snapshot, taps)),
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
            onTap: () => showCellSheet(context, c.cell),
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
            // 009: un clic en un conductor ocupado abre su viaje (FR-001).
            trailing: d.activeTripId == null ? null : const Icon(Icons.open_in_new, size: 18),
            onTap: d.activeTripId == null ? null : () => showTripInspection(context, d.activeTripId!),
            subtitle: Text(
              '${d.presence == DriverPresence.busy ? 'Ocupado' : 'Libre'} · '
              '${d.stale ? 'ubicación desactualizada (${_time(d.locationAt)})' : 'ubicación ${_time(d.locationAt)}'}',
            ),
          ),
        const SizedBox(height: 16),
        _MegaphoneSection(state: state),
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

/// 009: un clic en un conductor abre su viaje activo; libre, se avisa.
void openDriverTrip(BuildContext context, TowerState state, String driverId) {
  final driver = state.snapshot?.drivers.where((d) => d.driverId == driverId).firstOrNull;
  final trip = driver?.activeTripId;
  if (trip != null) {
    showTripInspection(context, trip);
  } else if (driver != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${driver.displayName} no tiene un viaje activo.')));
  }
}

/// 009: viajes activos de un hexágono y su selección para el megáfono (FR-001, FR-013).
Future<void> showCellSheet(BuildContext context, String cellId) {
  final tower = context.read<TowerCubit>();
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => BlocProvider.value(
      value: tower,
      child: BlocBuilder<TowerCubit, TowerState>(
        builder: (context, state) {
          final cell = state.snapshot?.cells.where((c) => c.cell == cellId).firstOrNull;
          final trips = cell?.tripIds ?? const <String>[];
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Text('Hexágono ${_shortCell(cellId)}', style: Theme.of(context).textTheme.titleMedium),
              CheckboxListTile(
                key: const Key('tower.sheet.select'),
                value: state.selected.contains(cellId),
                onChanged: (_) => tower.toggleCell(cellId),
                title: const Text('Elegido para el megáfono'),
              ),
              if (trips.isEmpty) const ListTile(title: Text('Sin viajes activos en este hexágono.')),
              for (final (i, id) in trips.indexed)
                ListTile(
                  key: ValueKey('tower.sheet.trip.$id'),
                  leading: const Icon(Icons.local_taxi),
                  title: Text('Viaje ${i + 1}'),
                  subtitle: Text(id.length > 8 ? id.substring(0, 8) : id),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showTripInspection(context, id);
                  },
                ),
            ],
          );
        },
      ),
    ),
  );
}

String _shortCell(String cell) => cell.length > 6 ? '…${cell.substring(cell.length - 6)}' : cell;

/// 009: megáfono: hexágonos con conductores, selección y botón de mantener pulsado (US3).
class _MegaphoneSection extends StatelessWidget {
  const _MegaphoneSection({required this.state});

  final TowerState state;

  @override
  Widget build(BuildContext context) {
    final tower = context.read<TowerCubit>();
    final theme = Theme.of(context);
    final cells = state.driverCells;
    final drivers = [
      for (final c in cells)
        if (state.selected.contains(c.cell)) c.freeDrivers + c.busyDrivers,
    ].fold<int>(0, (a, b) => a + b);
    return BlocBuilder<AdminMegaphoneCubit, AdminMegaphoneState>(
      builder: (context, mega) {
        final cubit = context.read<AdminMegaphoneCubit>();
        final onAir = mega.onAir != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Megáfono', style: theme.textTheme.titleMedium)),
                TextButton(
                  key: const Key('megaphone.log'),
                  onPressed: () => _showLog(context, cubit),
                  child: const Text('Registro'),
                ),
              ],
            ),
            if (cells.isEmpty)
              const Text('No hay conductores conectados con ubicación.')
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in cells)
                    FilterChip(
                      key: ValueKey('megaphone.cell.${c.cell}'),
                      label: Text('${_shortCell(c.cell)} · ${c.freeDrivers + c.busyDrivers}'),
                      selected: state.selected.contains(c.cell),
                      onSelected: onAir ? null : (_) => tower.toggleCell(c.cell),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              state.selected.isEmpty
                  ? 'Elige los hexágonos que oirán el comunicado.'
                  : '${state.selected.length} hexágono${state.selected.length == 1 ? '' : 's'} · $drivers conductor${drivers == 1 ? '' : 'es'} ahora',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Listener(
              onPointerDown: state.selected.isEmpty ? null : (_) => cubit.press(state.selected),
              onPointerUp: (_) => cubit.release(),
              onPointerCancel: (_) => cubit.release(),
              child: FilledButton.icon(
                key: const Key('megaphone.talk'),
                style: FilledButton.styleFrom(backgroundColor: onAir ? theme.colorScheme.error : null),
                onPressed: state.selected.isEmpty ? null : () {},
                icon: Icon(onAir ? Icons.mic : Icons.campaign),
                label: Text(
                  onAir
                      ? 'Hablando a ${mega.onAir!.recipients} conductor${mega.onAir!.recipients == 1 ? '' : 'es'}…'
                      : mega.starting
                      ? 'Abriendo…'
                      : 'Mantén pulsado para hablar',
                ),
              ),
            ),
            if (mega.message != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(mega.message!, key: const Key('megaphone.message'), style: theme.textTheme.bodySmall),
              ),
          ],
        );
      },
    );
  }

  static Future<void> _showLog(BuildContext context, AdminMegaphoneCubit cubit) async {
    await cubit.loadLog();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comunicados'),
        content: SizedBox(
          width: 480,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (cubit.state.log.isEmpty) const Text('Aún no hay comunicados.'),
              for (final b in cubit.state.log)
                ListTile(
                  dense: true,
                  title: Text('${b.adminName} · ${_time(b.startedAt)}'),
                  subtitle: Text(
                    '${b.cells.length} hexágono${b.cells.length == 1 ? '' : 's'} · ${b.recipients} conductor${b.recipients == 1 ? '' : 'es'}'
                    '${b.durationS == null ? ' · en curso' : ' · ${b.durationS} s'}',
                  ),
                ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }
}
