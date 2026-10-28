import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';

import 'cooperative_cubit.dart';

/// Mi cooperativa (006): sin cooperativa, la lista para pedir entrar; con solicitud, su estado;
/// como miembro, los compañeros y el canal de voz; como coordinador, las solicitudes.
class CooperativePage extends StatelessWidget {
  const CooperativePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi cooperativa')),
      body: BlocConsumer<CooperativeCubit, CooperativeState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!))),
        builder: (context, state) {
          final mine = state.mine;
          if (mine == null) {
            return state.loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: TextButton(
                      onPressed: context.read<CooperativeCubit>().load,
                      child: const Text('No pudimos cargar tu cooperativa. Reintentar'),
                    ),
                  );
          }
          return RefreshIndicator(
            onRefresh: context.read<CooperativeCubit>().load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (mine.isMember)
                  ..._member(context, state, mine)
                else if (mine.isPending)
                  ..._pending(context, state, mine.membership!)
                else
                  ..._noCooperative(context, state, mine.membership),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _member(BuildContext context, CooperativeState state, DriverCooperative mine) {
    final cubit = context.read<CooperativeCubit>();
    final membership = mine.membership!;
    final theme = Theme.of(context);
    return [
      Card(
        child: ListTile(
          leading: const Icon(Icons.groups, size: 36),
          title: Text(membership.cooperative.name, key: const Key('coop.name'), style: theme.textTheme.titleLarge),
          subtitle: Text(
            '${mine.isCoordinator ? 'Coordinador' : 'Miembro'} · ${mine.members.length} '
            '${mine.members.length == 1 ? 'miembro' : 'miembros'}',
          ),
        ),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        key: const Key('coop.channel'),
        onPressed: () => context.push('/cooperative/channel', extra: mine.members),
        icon: const Icon(Icons.record_voice_over),
        label: const Text('Canal de voz de la cooperativa'),
      ),
      const SizedBox(height: 8),
      const Text(
        'Si un pasajero de un compañero lo permite, su solicitud puede llegarte cuando él no pueda '
        'atenderla, y tú puedes pasar las tuyas a la cooperativa.',
      ),
      if (mine.isCoordinator) ...[
        const SizedBox(height: 16),
        Text('Solicitudes para entrar', style: theme.textTheme.titleMedium),
        if (mine.requests.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No hay solicitudes pendientes.')),
        for (final r in mine.requests)
          Card(
            child: ListTile(
              key: Key('coop.request.${r.membershipId}'),
              title: Text(r.displayName),
              subtitle: Text('Placa ${r.vehiclePlate}'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Rechazar',
                    icon: const Icon(Icons.close),
                    onPressed: state.busy ? null : () => _reject(context, r),
                  ),
                  IconButton(
                    key: Key('coop.approve.${r.membershipId}'),
                    tooltip: 'Aprobar',
                    icon: const Icon(Icons.check),
                    onPressed: state.busy ? null : () => cubit.decide(r.membershipId, approve: true),
                  ),
                ],
              ),
            ),
          ),
      ],
      const SizedBox(height: 16),
      Text('Compañeros', style: theme.textTheme.titleMedium),
      for (final m in mine.members)
        ListTile(
          key: Key('coop.member.${m.driverId}'),
          leading: Icon(Icons.circle, size: 14, color: _presenceColor(m.presence)),
          title: Text(m.displayName),
          subtitle: Text(
            '${m.vehiclePlate} · ${presenceLabel(m.presence)}'
            '${m.role == CooperativeRole.coordinator ? ' · Coordinador' : ''}',
          ),
          trailing: mine.isCoordinator && m.role != CooperativeRole.coordinator
              ? IconButton(
                  tooltip: 'Retirar de la cooperativa',
                  icon: const Icon(Icons.person_remove_outlined),
                  onPressed: state.busy ? null : () => _confirmRemove(context, m),
                )
              : null,
        ),
      const SizedBox(height: 16),
      TextButton(
        key: const Key('coop.leave'),
        onPressed: state.busy ? null : () => _confirmLeave(context, membership.cooperative.name),
        child: const Text('Salir de la cooperativa'),
      ),
    ];
  }

  List<Widget> _pending(BuildContext context, CooperativeState state, Membership m) => [
    Card(
      child: ListTile(
        leading: const Icon(Icons.hourglass_top, color: Colors.orange, size: 32),
        title: Text('Solicitud enviada a ${m.cooperative.name}', key: const Key('coop.pending')),
        subtitle: const Text('Un coordinador o un administrador la revisará.'),
      ),
    ),
    const SizedBox(height: 8),
    OutlinedButton(
      key: const Key('coop.withdraw'),
      onPressed: state.busy ? null : context.read<CooperativeCubit>().withdraw,
      child: const Text('Retirar solicitud'),
    ),
  ];

  List<Widget> _noCooperative(BuildContext context, CooperativeState state, Membership? last) {
    final cubit = context.read<CooperativeCubit>();
    return [
      if (last?.status == MembershipStatus.rejected)
        Card(
          child: ListTile(
            key: const Key('coop.rejected'),
            leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.error),
            title: Text('${last!.cooperative.name} rechazó tu solicitud'),
            subtitle: Text('Motivo: ${last.rejectReason ?? '—'}'),
          ),
        ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Únete a una cooperativa para atender a los pasajeros de tus compañeros cuando ellos no '
          'puedan, y hablar con todos por el canal de voz del grupo. Solo puedes pertenecer a una.',
        ),
      ),
      if (state.available.isEmpty) const Text('No hay cooperativas disponibles por ahora.'),
      for (final c in state.available)
        Card(
          child: ListTile(
            key: Key('coop.available.${c.id}'),
            title: Text(c.name),
            subtitle: Text('${c.membersCount} ${c.membersCount == 1 ? 'miembro' : 'miembros'}'),
            trailing: FilledButton(
              onPressed: state.busy ? null : () => cubit.join(c.id),
              child: const Text('Pedir entrar'),
            ),
          ),
        ),
    ];
  }

  Color _presenceColor(String presence) => switch (presence) {
    'free' => Colors.green,
    'busy' => Colors.orange,
    _ => Colors.grey,
  };

  Future<void> _reject(BuildContext context, MembershipRequest r) async {
    final cubit = context.read<CooperativeCubit>();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReasonDialog(name: r.displayName),
    );
    if (reason != null && reason.trim().isNotEmpty) {
      await cubit.decide(r.membershipId, approve: false, reason: reason.trim());
    }
  }

  Future<void> _confirmRemove(BuildContext context, CooperativeMember m) async {
    final cubit = context.read<CooperativeCubit>();
    final ok = await _confirm(context, '¿Retirar a ${m.displayName}?', 'Dejará de recibir solicitudes y el canal.');
    if (ok) await cubit.remove(m.driverId);
  }

  Future<void> _confirmLeave(BuildContext context, String name) async {
    final cubit = context.read<CooperativeCubit>();
    final ok = await _confirm(
      context,
      '¿Salir de $name?',
      'Dejarás de recibir solicitudes de tus compañeros y saldrás del canal de voz.',
    );
    if (ok) await cubit.leave();
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

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.name});

  final String name;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Rechazar a ${widget.name}'),
    content: TextField(
      key: const Key('coop.reason'),
      controller: _text,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'Motivo'),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(
        key: const Key('coop.reason.ok'),
        onPressed: () => Navigator.pop(context, _text.text),
        child: const Text('Rechazar'),
      ),
    ],
  );
}
