import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';

import '../controller/radio_cubit.dart';
import '../deps.dart';
import 'add_contact.dart';
import 'status.dart';

/// Nombre de cada rol en un canal (FR-016).
String roleLabel(RadioRole r) => switch (r) {
  RadioRole.owner => 'Dueño',
  RadioRole.moderator => 'Moderador',
  RadioRole.member => 'Miembro',
  RadioRole.listener => 'Solo escucha',
};

/// Rol máximo de los pasajeros que el dueño admite (FR-017); null no los admite.
String passengerLabel(RadioRole? r) => switch (r) {
  null => 'No admite pasajeros',
  RadioRole.listener => 'Pasajeros solo escuchan',
  RadioRole.member => 'Pasajeros como miembros',
  _ => 'Pasajeros hasta moderador',
};

/// Crear canal (US4-1): nombre único, descripción, cómo se entra y si admite pasajeros.
class NewChannelPage extends StatefulWidget {
  const NewChannelPage({super.key});

  @override
  State<NewChannelPage> createState() => _NewChannelPageState();
}

class _NewChannelPageState extends State<NewChannelPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _joinMode = 'approval';
  RadioRole? _passengers;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.length < 3 || name.length > 40) {
      setState(() => _error = 'El nombre debe tener entre 3 y 40 letras.');
      return;
    }
    final deps = context.read<RadioDeps>();
    final cubit = context.read<RadioCubit>();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final c = await deps.api.createRadioChannel(
        name: name,
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        joinMode: _joinMode,
        passengerRoleMax: _passengers,
      );
      await cubit.load();
      if (mounted) context.pushReplacement(RadioRoutes.channel(c.id));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = radioErrorText(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear canal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('radio.channel.name'),
            controller: _name,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nombre del canal', hintText: 'Taxistas Norte'),
          ),
          TextField(
            key: const Key('radio.channel.description'),
            controller: _description,
            maxLength: 200,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
          ),
          const SizedBox(height: 8),
          Text('¿Cómo se entra?', style: Theme.of(context).textTheme.titleSmall),
          RadioGroup<String>(
            groupValue: _joinMode,
            onChanged: (v) => setState(() => _joinMode = v ?? _joinMode),
            child: const Column(
              children: [
                RadioListTile(
                  key: Key('radio.channel.approval'),
                  value: 'approval',
                  title: Text('Con aprobación'),
                  subtitle: Text('Tú o un moderador aceptan cada solicitud'),
                ),
                RadioListTile(
                  key: Key('radio.channel.openLink'),
                  value: 'open_link',
                  title: Text('Con el enlace'),
                  subtitle: Text('Quien tenga el enlace o el QR entra directo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<RadioRole?>(
            key: const Key('radio.channel.passengers'),
            initialValue: _passengers,
            decoration: const InputDecoration(labelText: 'Pasajeros en el canal'),
            items: [
              for (final r in const [null, RadioRole.listener, RadioRole.member, RadioRole.moderator])
                DropdownMenuItem(value: r, child: Text(passengerLabel(r))),
            ],
            onChanged: (v) => setState(() => _passengers = v),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                key: const Key('radio.channel.error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('radio.channel.create'),
            onPressed: _saving ? null : _create,
            child: const Text('Crear canal'),
          ),
        ],
      ),
    );
  }
}

/// Detalle de un canal o de la cooperativa (US4): miembros con su estado, solicitudes para quien
/// modera, menú de moderación según el rol, invitar, editar, salir y borrar.
class ChannelPage extends StatefulWidget {
  const ChannelPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  RadioConversationDetail? _detail;
  String? _error;

  RadioDeps get _deps => context.read<RadioDeps>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _deps.api.radioConversation(widget.conversationId);
      if (mounted) {
        setState(() {
          _detail = d;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = radioErrorText(e));
    }
  }

  /// Ejecuta [action] y recarga; los errores se muestran abajo.
  Future<void> _run(Future<void> Function() action, {String? done}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
      await _load();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(radioErrorText(e))));
    }
  }

  Future<void> _moderate(RadioMember m, {String? action, RadioRole? role}) =>
      _run(() => _deps.api.moderateRadioMember(widget.conversationId, m.userId, action: action, role: role));

  Future<bool> _confirm(String title, String body, String ok) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            key: const Key('radio.channel.confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(ok),
          ),
        ],
      ),
    );
    return yes ?? false;
  }

  Future<void> _invite() async {
    final deps = _deps;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Invitar al canal')),
          body: FutureBuilder<RadioInvite>(
            future: deps.api.radioChannelInvite(widget.conversationId),
            builder: (context, snap) => switch (snap) {
              AsyncSnapshot(:final ApiException error) => Center(child: Text(radioErrorText(error))),
              AsyncSnapshot(:final RadioInvite data) => InviteShareView(
                invite: data,
                deps: deps,
                hint: 'Compártelo con tus compañeros: con Kyq Conductor escanean el QR o abren el enlace.',
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ),
      ),
    );
  }

  Future<void> _edit(RadioConversationDetail d) async {
    final name = TextEditingController(text: d.conversation.title);
    var mode = d.joinMode ?? 'approval';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar canal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('radio.channel.editName'),
                controller: name,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              SwitchListTile(
                key: const Key('radio.channel.editApproval'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Pedir aprobación para entrar'),
                value: mode == 'approval',
                onChanged: (v) => setState(() => mode = v ? 'approval' : 'open_link'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              key: const Key('radio.channel.save'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;
    final cubit = context.read<RadioCubit>();
    await _run(() async {
      await _deps.api.updateRadioChannel(widget.conversationId, name: name.text.trim(), joinMode: mode);
      await cubit.load();
    });
  }

  Future<void> _leave(RadioConversationDetail d) async {
    final owner = d.conversation.myRole == RadioRole.owner;
    if (!await _confirm(
      'Salir del canal',
      owner
          ? 'El canal pasa al moderador o miembro más antiguo. Si no queda nadie, se borra.'
          : 'Dejarás de oír y de ver los mensajes de ${d.conversation.title}.',
      'Salir',
    )) {
      return;
    }
    if (!mounted) return;
    await _leaveWith(() => _deps.api.leaveRadioChannel(widget.conversationId));
  }

  Future<void> _delete(RadioConversationDetail d) async {
    if (!await _confirm(
      'Borrar canal',
      'Se borran el canal y su historial para todos los miembros. No se puede deshacer.',
      'Borrar',
    )) {
      return;
    }
    if (!mounted) return;
    await _leaveWith(() => _deps.api.deleteRadioConversation(widget.conversationId));
  }

  Future<void> _leaveWith(Future<void> Function() action) async {
    final cubit = context.read<RadioCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      await cubit.load();
      if (mounted) context.go(RadioRoutes.list);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(radioErrorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    if (d == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Canal')),
        body: Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!)),
      );
    }
    final c = d.conversation;
    final cooperative = c.kind == RadioConversationKind.cooperative;
    final myRole = c.myRole ?? RadioRole.member;
    final pending = d.members.where((m) => m.status == RadioMemberStatus.pending).toList();
    final blocked = d.members.where((m) => m.status == RadioMemberStatus.blocked).toList();
    final members = d.members
        .where((m) => m.status == RadioMemberStatus.active || m.status == RadioMemberStatus.muted)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(c.title, key: const Key('radio.channel.title')),
        actions: [
          if (c.moderates && !cooperative)
            IconButton(
              key: const Key('radio.channel.invite'),
              tooltip: 'Invitar',
              onPressed: _invite,
              icon: const Icon(Icons.person_add_alt_1),
            ),
          if (myRole == RadioRole.owner && !cooperative)
            IconButton(
              key: const Key('radio.channel.edit'),
              tooltip: 'Editar',
              onPressed: () => _edit(d),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            if (d.description case final text? when text.isNotEmpty)
              Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Text(text)),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                cooperative
                    ? 'Canal de tu cooperativa: los miembros los maneja la cooperativa.'
                    : d.joinMode == 'open_link'
                    ? 'Entra quien tenga el enlace o el QR'
                    : 'Entrar necesita aprobación',
              ),
              subtitle: cooperative ? null : Text(passengerLabel(d.passengerRoleMax)),
            ),
            if (c.suspended)
              const ListTile(
                leading: Icon(Icons.block),
                title: Text('Suspendido por Kyq: nadie puede hablar hasta que lo revisen.'),
              ),
            if (c.moderates && pending.isNotEmpty) ...[
              _Section('Solicitudes (${pending.length})'),
              for (final m in pending)
                ListTile(
                  key: Key('radio.request.${m.userId}'),
                  leading: const Icon(Icons.person_outline),
                  title: Text(m.displayName),
                  subtitle: Text(m.isPassenger ? 'Pasajero' : 'Conductor'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('radio.request.reject.${m.userId}'),
                        tooltip: 'Rechazar',
                        onPressed: () => _moderate(m, action: 'reject'),
                        icon: const Icon(Icons.close),
                      ),
                      IconButton(
                        key: Key('radio.request.approve.${m.userId}'),
                        tooltip: 'Aceptar',
                        onPressed: () => _moderate(m, action: 'approve'),
                        icon: const Icon(Icons.check),
                      ),
                    ],
                  ),
                ),
            ],
            _Section('Miembros (${members.length})'),
            for (final m in members)
              ListTile(
                key: Key('radio.member.${m.userId}'),
                leading: PresenceDot(presence: m.presence, size: 18),
                title: Text(m.displayName + (m.userId == _deps.myUserId ? ' (tú)' : '')),
                subtitle: Text(
                  [
                    roleLabel(m.role),
                    presenceLabel(m.presence),
                    if (m.status == RadioMemberStatus.muted) 'Silenciado',
                    if (m.isPassenger) 'Pasajero',
                  ].join(' · '),
                ),
                trailing: cooperative || m.userId == _deps.myUserId
                    ? null
                    : _ModerationMenu(member: m, myRole: myRole, onAction: _onAction),
              ),
            if (c.moderates && blocked.isNotEmpty) ...[
              _Section('Bloqueados (${blocked.length})'),
              for (final m in blocked)
                ListTile(
                  key: Key('radio.blocked.${m.userId}'),
                  leading: const Icon(Icons.block),
                  title: Text(m.displayName),
                  trailing: TextButton(
                    onPressed: () => _moderate(m, action: 'unblock'),
                    child: const Text('Desbloquear'),
                  ),
                ),
            ],
            if (!cooperative) ...[
              const Divider(),
              ListTile(
                key: const Key('radio.channel.leave'),
                leading: const Icon(Icons.logout),
                title: const Text('Salir del canal'),
                onTap: () => _leave(d),
              ),
              if (myRole == RadioRole.owner)
                ListTile(
                  key: const Key('radio.channel.delete'),
                  leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  title: Text('Borrar canal', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () => _delete(d),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(RadioMember m, _Act act) async {
    switch (act) {
      case _Act.mute:
        await _moderate(m, action: 'mute');
      case _Act.unmute:
        await _moderate(m, action: 'unmute');
      case _Act.listener:
        await _moderate(m, role: RadioRole.listener);
      case _Act.member:
        await _moderate(m, role: RadioRole.member);
      case _Act.moderator:
        await _moderate(m, role: RadioRole.moderator);
      case _Act.owner:
        if (await _confirm(
          'Pasar el canal',
          '${m.displayName} será el dueño del canal y tú quedarás como moderador.',
          'Pasar el canal',
        )) {
          await _moderate(m, role: RadioRole.owner);
        }
      case _Act.remove:
        if (await _confirm(
          'Sacar del canal',
          '${m.displayName} sale del canal. Puede volver a pedir entrada.',
          'Sacar',
        )) {
          await _moderate(m, action: 'remove');
        }
      case _Act.block:
        if (await _confirm('Bloquear', '${m.displayName} sale del canal y no podrá volver a entrar.', 'Bloquear')) {
          await _moderate(m, action: 'block');
        }
    }
  }
}

enum _Act { mute, unmute, listener, member, moderator, owner, remove, block }

/// Lo que [myRole] puede hacer con [member] (FR-016): el dueño todo; un moderador solo con
/// miembros y oyentes; nadie toca al dueño.
class _ModerationMenu extends StatelessWidget {
  const _ModerationMenu({required this.member, required this.myRole, required this.onAction});

  final RadioMember member;
  final RadioRole myRole;
  final Future<void> Function(RadioMember, _Act) onAction;

  @override
  Widget build(BuildContext context) {
    final m = member;
    final owner = myRole == RadioRole.owner;
    final canAct =
        m.role != RadioRole.owner && (owner || (myRole == RadioRole.moderator && m.role != RadioRole.moderator));
    if (!canAct) return const SizedBox.shrink();
    final muted = m.status == RadioMemberStatus.muted;
    return PopupMenuButton<_Act>(
      key: Key('radio.member.menu.${m.userId}'),
      tooltip: 'Moderar',
      onSelected: (a) => onAction(m, a),
      itemBuilder: (_) => [
        muted
            ? const PopupMenuItem(value: _Act.unmute, child: Text('Quitar silencio'))
            : const PopupMenuItem(key: Key('radio.act.mute'), value: _Act.mute, child: Text('Silenciar')),
        if (m.role == RadioRole.listener)
          const PopupMenuItem(value: _Act.member, child: Text('Dejar hablar'))
        else if (m.role == RadioRole.member)
          const PopupMenuItem(key: Key('radio.act.listener'), value: _Act.listener, child: Text('Solo escucha')),
        if (owner && m.role != RadioRole.moderator && !m.isPassenger)
          const PopupMenuItem(key: Key('radio.act.moderator'), value: _Act.moderator, child: Text('Hacer moderador')),
        if (owner && m.role == RadioRole.moderator)
          const PopupMenuItem(value: _Act.member, child: Text('Quitar moderador')),
        if (owner && !m.isPassenger)
          const PopupMenuItem(key: Key('radio.act.owner'), value: _Act.owner, child: Text('Pasarle el canal')),
        const PopupMenuItem(key: Key('radio.act.remove'), value: _Act.remove, child: Text('Sacar del canal')),
        const PopupMenuItem(key: Key('radio.act.block'), value: _Act.block, child: Text('Bloquear')),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );
}
