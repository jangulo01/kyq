import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'emergencies_page.dart';
import 'emergency_cubits.dart';
import 'sos_map.dart';

/// Texto para la policía: coordenadas y enlace de mapa de la última ubicación (US2-3).
String locationForAuthorities(SosLocation l) {
  final lat = l.lat.toStringAsFixed(6);
  final lng = l.lng.toStringAsFixed(6);
  return 'Ubicación: $lat, $lng — https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=18/$lat/$lng';
}

/// Detalle de una alerta (FR-009): mapa en vivo con el recorrido, escuchar y hablar, tomar y
/// liberar, datos del viaje, notas y cierre con desenlace.
class AlertDetailPage extends StatelessWidget {
  const AlertDetailPage({super.key, this.map = maplibreSosMap, required this.openUrl});

  final SosMapBuilder map;

  /// Abre la grabación en otra pestaña.
  final Future<void> Function(String url) openUrl;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SosDetailCubit, SosDetailState>(
      listenWhen: (a, b) => (b.error != null && a.error != b.error) || (b.notice != null && a.notice != b.notice),
      listener: (context, state) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error ?? state.notice!))),
      builder: (context, state) {
        final alert = state.alert;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              alert == null
                  ? 'Alerta SOS'
                  : 'SOS de ${sosRoleLabel(alert.raisedRole).toLowerCase()}: ${alert.raisedByName}',
            ),
          ),
          body: switch (alert) {
            null when state.loading => const Center(child: CircularProgressIndicator()),
            null => Center(child: Text(state.error ?? 'No pudimos cargar la alerta.')),
            _ => LayoutBuilder(
              builder: (context, box) {
                final panel = _Panel(alert: alert, state: state, openUrl: openUrl);
                if (box.maxWidth < 900) {
                  return ListView(
                    children: [
                      SizedBox(height: 320, child: map(alert)),
                      panel,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: map(alert)),
                    SizedBox(width: 460, child: SingleChildScrollView(child: panel)),
                  ],
                );
              },
            ),
          },
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.alert, required this.state, required this.openUrl});

  final SosAlertDetail alert;
  final SosDetailState state;
  final Future<void> Function(String url) openUrl;

  bool get _closed => alert.status == SosStatus.closed || alert.status == SosStatus.cancelledByUser;

  Future<void> _close(BuildContext context) async {
    final cubit = context.read<SosDetailCubit>();
    final outcome = await showDialog<SosOutcome>(context: context, builder: (_) => const _OutcomeDialog());
    if (outcome != null) await cubit.closeCase(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<SosDetailCubit>();
    final mine = cubit.mine;
    final last = alert.lastLocation;
    final summary = SosAlertSummary(
      id: alert.id,
      tripId: alert.tripId,
      raisedRole: alert.raisedRole,
      raisedByName: alert.raisedByName,
      status: alert.status,
      claimedByName: alert.claimedByName,
      createdAt: alert.createdAt,
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(sosStatusLabel(summary), key: const Key('ops.detail.status'), style: theme.textTheme.titleLarge),
          if (alert.outcome != null) Text('Desenlace: ${sosOutcomeLabel(alert.outcome!)}'),
          if (!_closed)
            Row(
              children: [
                const Text('Abierta hace '),
                ElapsedText(since: alert.createdAt),
              ],
            ),
          if (alert.cancelWithoutPin)
            Card(
              color: theme.colorScheme.errorContainer,
              child: const ListTile(
                key: Key('ops.detail.noPin'),
                leading: Icon(Icons.warning_amber),
                title: Text('Intentó cancelar sin el PIN correcto'),
                subtitle: Text('Puede estar bajo coacción: la alerta sigue abierta.'),
              ),
            ),
          if (alert.escalated && !_closed) const Text('Se avisó por SMS a los operadores de guardia.'),
          const SizedBox(height: 12),
          if (!_closed) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (state.voice == OpsVoice.off || state.voice == OpsVoice.unavailable)
                  OutlinedButton.icon(
                    key: const Key('ops.listen'),
                    icon: const Icon(Icons.headphones),
                    label: const Text('Escuchar'),
                    onPressed: cubit.listen,
                  )
                else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.call_end),
                    label: Text(state.voice == OpsVoice.connecting ? 'Conectando…' : 'Dejar de escuchar'),
                    onPressed: cubit.hangUp,
                  ),
                if (alert.status == SosStatus.open)
                  FilledButton.icon(
                    key: const Key('ops.claim'),
                    icon: const Icon(Icons.pan_tool),
                    label: const Text('Tomar alerta'),
                    onPressed: state.busy ? null : cubit.claim,
                  ),
                if (mine) ...[
                  if (state.voice == OpsVoice.listening || state.voice == OpsVoice.talking)
                    FilledButton.icon(
                      key: const Key('ops.talk'),
                      icon: Icon(state.voice == OpsVoice.talking ? Icons.mic : Icons.mic_off),
                      label: Text(state.voice == OpsVoice.talking ? 'Micrófono abierto' : 'Hablar'),
                      onPressed: () => cubit.setTalking(state.voice != OpsVoice.talking),
                    ),
                  OutlinedButton(
                    key: const Key('ops.release'),
                    onPressed: state.busy ? null : cubit.release,
                    child: const Text('Liberar'),
                  ),
                  FilledButton(
                    key: const Key('ops.close'),
                    style: FilledButton.styleFrom(backgroundColor: sosRed),
                    onPressed: state.busy ? null : () => _close(context),
                    child: const Text('Cerrar caso'),
                  ),
                ],
              ],
            ),
            if (!mine && alert.status == SosStatus.claimed)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Puedes escuchar; solo quien tomó la alerta habla.'),
              ),
          ],
          const Divider(height: 32),
          Text('Ubicación', style: theme.textTheme.titleMedium),
          if (last == null)
            const Text('Aún sin ubicación.')
          else ...[
            Text(
              '${last.lat.toStringAsFixed(6)}, ${last.lng.toStringAsFixed(6)}',
              key: const Key('ops.detail.location'),
            ),
            if (last.at != null)
              Text(
                'Hace ${formatElapsed(DateTime.now().difference(last.at!))} · ${alert.track.length} puntos desde el SOS'
                '${last.accuracyM == null ? '' : ' · precisión ${last.accuracyM!.round()} m'}',
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('ops.copyLocation'),
                icon: const Icon(Icons.copy),
                label: const Text('Copiar ubicación para la policía'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: locationForAuthorities(last)));
                  messenger.showSnackBar(const SnackBar(content: Text('Ubicación copiada')));
                },
              ),
            ),
          ],
          const Divider(height: 32),
          Text('Viaje', style: theme.textTheme.titleMedium),
          Text('Pasajero: ${alert.passenger.name}'),
          Text(
            'Conductor: ${alert.driver.name} · Placa ${alert.driver.vehiclePlate}',
            key: const Key('ops.detail.driver'),
          ),
          Text(
            'Vehículo: ${[alert.driver.vehicleBrand, alert.driver.vehicleModel, alert.driver.vehicleColor].nonNulls.join(' ').ifEmpty(alert.driver.vehicleDescription)}',
          ),
          Text('Estado del viaje: ${alert.trip.status}'),
          if (alert.relatedAlertIds.isNotEmpty)
            Text(
              'Hay ${alert.relatedAlertIds.length} alerta(s) más en este viaje.',
              key: const Key('ops.detail.related'),
            ),
          const Divider(height: 32),
          Text('Contacto', style: theme.textTheme.titleMedium),
          SelectableText('${alert.raisedByName}: ${alert.raisedByPhone}'),
          for (final c in alert.emergencyContacts) SelectableText('Contacto de emergencia ${c.name}: ${c.phoneE164}'),
          Text(
            '${alert.raisedByAlerts} alerta(s) de esta persona, ${alert.raisedByFalseAlarms} falsa(s) alarma(s).',
            style: theme.textTheme.bodySmall,
          ),
          if (alert.recordingUrl != null) ...[
            const Divider(height: 32),
            OutlinedButton.icon(
              key: const Key('ops.recording'),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Escuchar la grabación'),
              onPressed: () => openUrl(alert.recordingUrl!),
            ),
          ],
          const Divider(height: 32),
          Text('Notas', style: theme.textTheme.titleMedium),
          for (final n in alert.notes)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(n.body),
              subtitle: Text('${n.operatorName} · ${formatDateTime(n.createdAt.toLocal())}'),
            ),
          _NoteField(enabled: !state.busy),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

String formatDateTime(DateTime d) =>
    '${formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class _NoteField extends StatefulWidget {
  const _NoteField({required this.enabled});

  final bool enabled;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final body = _text.text;
    if (body.trim().isEmpty) return;
    await context.read<SosDetailCubit>().addNote(body);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('ops.note'),
            controller: _text,
            maxLength: 2000,
            decoration: const InputDecoration(hintText: 'Llamé a la policía, contacté a la familia…'),
            onSubmitted: (_) => _save(),
          ),
        ),
        IconButton(
          key: const Key('ops.note.save'),
          tooltip: 'Guardar nota',
          icon: const Icon(Icons.send),
          onPressed: widget.enabled ? _save : null,
        ),
      ],
    );
  }
}

class _OutcomeDialog extends StatefulWidget {
  const _OutcomeDialog();

  @override
  State<_OutcomeDialog> createState() => _OutcomeDialogState();
}

class _OutcomeDialogState extends State<_OutcomeDialog> {
  SosOutcome? _outcome;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cerrar caso'),
      content: RadioGroup<SosOutcome>(
        groupValue: _outcome,
        onChanged: (o) => setState(() => _outcome = o),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Elige el desenlace. La persona dejará de enviar su ubicación.'),
            for (final o in SosOutcome.values)
              RadioListTile<SosOutcome>(key: Key('ops.outcome.${o.name}'), value: o, title: Text(sosOutcomeLabel(o))),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('ops.close.confirm'),
          onPressed: _outcome == null ? null : () => Navigator.of(context).pop(_outcome),
          child: const Text('Cerrar caso'),
        ),
      ],
    );
  }
}
