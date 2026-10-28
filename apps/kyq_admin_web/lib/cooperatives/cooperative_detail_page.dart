import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'cooperatives_cubits.dart';

/// Detalle de una cooperativa (006): solicitudes pendientes por antigüedad, miembros con rol y
/// presencia, coordinadores, retiro, alta directa y suspensión (FR-001, FR-002, FR-005, FR-006).
class CooperativeDetailPage extends StatelessWidget {
  const CooperativeDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CooperativeDetailCubit>();
    return BlocConsumer<CooperativeDetailCubit, CooperativeDetailState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error && b.detail != null,
      listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!))),
      builder: (context, state) {
        final detail = state.detail;
        final coop = detail?.cooperative;
        final suspended = coop?.status == CooperativeStatus.suspended;
        return Scaffold(
          appBar: AppBar(
            title: Text(coop?.name ?? 'Cooperativa'),
            actions: [
              if (coop != null)
                TextButton.icon(
                  key: const Key('coop.status'),
                  onPressed: state.busy
                      ? null
                      : () =>
                            _toggleStatus(context, suspended ? CooperativeStatus.active : CooperativeStatus.suspended),
                  icon: Icon(suspended ? Icons.play_arrow : Icons.pause),
                  label: Text(suspended ? 'Reactivar' : 'Suspender'),
                ),
              IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load),
            ],
          ),
          body: detail == null
              ? Center(child: state.loading ? const CircularProgressIndicator() : Text(state.error ?? 'Sin datos.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (suspended)
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.pause_circle_outline),
                          title: Text('Suspendida'),
                          subtitle: Text('No recibe solicitudes derivadas y su canal de voz está cerrado.'),
                        ),
                      ),
                    Text('Solicitudes pendientes (${detail.requests.length})', style: _title(context)),
                    if (detail.requests.isEmpty)
                      const Padding(padding: EdgeInsets.all(8), child: Text('No hay solicitudes pendientes.')),
                    for (final r in detail.requests)
                      ListTile(
                        key: Key('coop.request.${r.membershipId}'),
                        title: Text('${r.displayName} · ${r.vehiclePlate}'),
                        subtitle: Text('Pidió entrar el ${formatDate(r.requestedAt)}'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              key: Key('coop.reject.${r.membershipId}'),
                              onPressed: state.busy ? null : () => _reject(context, r),
                              child: const Text('Rechazar'),
                            ),
                            FilledButton(
                              key: Key('coop.approve.${r.membershipId}'),
                              onPressed: state.busy ? null : () => cubit.decide(r.membershipId, approve: true),
                              child: const Text('Aprobar'),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        Expanded(child: Text('Miembros (${detail.members.length})', style: _title(context))),
                        TextButton.icon(
                          key: const Key('coop.add'),
                          onPressed: state.busy ? null : () => _add(context, state),
                          icon: const Icon(Icons.person_add_alt),
                          label: const Text('Agregar conductor'),
                        ),
                      ],
                    ),
                    for (final m in detail.members)
                      ListTile(
                        key: Key('coop.member.${m.driverId}'),
                        leading: Icon(Icons.circle, size: 14, color: _presenceColor(m.presence)),
                        title: Text('${m.displayName} · ${m.vehiclePlate}'),
                        subtitle: Text(m.role == CooperativeRole.coordinator ? 'Coordinador' : 'Miembro'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              key: Key('coop.role.${m.driverId}'),
                              onPressed: state.busy
                                  ? null
                                  : () => cubit.setRole(
                                      m.driverId,
                                      m.role == CooperativeRole.coordinator
                                          ? CooperativeRole.member
                                          : CooperativeRole.coordinator,
                                    ),
                              child: Text(
                                m.role == CooperativeRole.coordinator ? 'Quitar coordinador' : 'Nombrar coordinador',
                              ),
                            ),
                            IconButton(
                              key: Key('coop.remove.${m.driverId}'),
                              tooltip: 'Retirar',
                              icon: const Icon(Icons.person_remove_outlined),
                              onPressed: state.busy ? null : () => _remove(context, m),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  TextStyle? _title(BuildContext context) => Theme.of(context).textTheme.titleMedium;

  Color _presenceColor(String presence) => switch (presence) {
    'free' => Colors.green,
    'busy' => Colors.orange,
    _ => Colors.grey,
  };

  Future<void> _toggleStatus(BuildContext context, CooperativeStatus status) async {
    final cubit = context.read<CooperativeDetailCubit>();
    if (status == CooperativeStatus.suspended) {
      final ok = await _confirm(
        context,
        '¿Suspender la cooperativa?',
        'Dejará de recibir solicitudes derivadas y se cerrará su canal de voz. Los miembros siguen siéndolo.',
      );
      if (!ok) return;
    }
    await cubit.setStatus(status);
  }

  Future<void> _remove(BuildContext context, CooperativeMember m) async {
    final cubit = context.read<CooperativeDetailCubit>();
    final ok = await _confirm(
      context,
      '¿Retirar a ${m.displayName}?',
      'Saldrá de la cooperativa y de su canal de voz.',
    );
    if (ok) await cubit.remove(m.driverId);
  }

  Future<void> _reject(BuildContext context, MembershipRequest r) async {
    final cubit = context.read<CooperativeDetailCubit>();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(title: 'Rechazar a ${r.displayName}', label: 'Motivo', action: 'Rechazar'),
    );
    if (reason != null && reason.trim().isNotEmpty) {
      await cubit.decide(r.membershipId, approve: false, reason: reason.trim());
    }
  }

  Future<void> _add(BuildContext context, CooperativeDetailState state) async {
    final cubit = context.read<CooperativeDetailCubit>();
    final members = {for (final m in state.detail!.members) m.driverId};
    final candidates = state.drivers.where((d) => !members.contains(d.driverId)).toList();
    final driverId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Agregar conductor'),
        children: [
          if (candidates.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No hay conductores para agregar.')),
          for (final d in candidates)
            SimpleDialogOption(
              key: Key('coop.add.${d.driverId}'),
              onPressed: () => Navigator.pop(context, d.driverId),
              child: Text('${d.displayName} · ${d.vehiclePlate}'),
            ),
        ],
      ),
    );
    if (driverId != null) await cubit.addMember(driverId);
  }

  Future<bool> _confirm(BuildContext context, String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              key: const Key('coop.confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title, required this.label, required this.action});

  final String title;
  final String label;
  final String action;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const Key('coop.dialog.text'),
      controller: _text,
      autofocus: true,
      decoration: InputDecoration(labelText: widget.label),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(
        key: const Key('coop.dialog.ok'),
        onPressed: () => Navigator.pop(context, _text.text),
        child: Text(widget.action),
      ),
    ],
  );
}
