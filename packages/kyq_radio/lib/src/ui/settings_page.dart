import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import '../controller/radio_cubit.dart';
import '../deps.dart';
import 'quiet_hours.dart';

/// Ajustes de Radio: cómo se usa el botón grande (FR-007) y, en Kyq Conductor, "Radio con mis
/// clientes" con los clientes silenciados o bloqueados (FR-003).
class RadioSettingsPage extends StatelessWidget {
  const RadioSettingsPage({super.key, this.extra = const []});

  /// Secciones que añade cada app o fase (horarios de silencio, modo auto).
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final deps = context.read<RadioDeps>();
    return BlocBuilder<RadioCubit, RadioState>(
      builder: (context, s) {
        final cubit = context.read<RadioCubit>();
        final me = s.me;
        final clients = s.conversations.where((c) => c.kind == RadioConversationKind.client).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Ajustes de Radio')),
          body: me == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    const _Header('Botón para hablar'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SegmentedButton<RadioPushMode>(
                        key: const Key('radio.settings.pushMode'),
                        segments: const [
                          ButtonSegment(
                            value: RadioPushMode.hold,
                            icon: Icon(Icons.touch_app),
                            label: Text('Mantener'),
                          ),
                          ButtonSegment(value: RadioPushMode.toggle, icon: Icon(Icons.ads_click), label: Text('Tocar')),
                        ],
                        selected: {me.pushMode},
                        onSelectionChanged: (v) => cubit.setPushMode(v.first),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        me.pushMode == RadioPushMode.hold
                            ? 'Mantén pulsado mientras hablas y suelta para terminar.'
                            : 'Toca una vez para empezar a hablar y otra para terminar.',
                      ),
                    ),
                    if (deps.isDriver) ...[
                      const _Header('Clientes'),
                      SwitchListTile(
                        key: const Key('radio.settings.clients'),
                        title: const Text('Radio con mis clientes'),
                        subtitle: const Text(
                          'Tus pasajeros guardados te ven en su Radio y pueden hablarte. '
                          'Ellos nunca ven tu teléfono.',
                        ),
                        value: me.clientsEnabled ?? false,
                        onChanged: me.access == RadioAccess.full ? (v) => _setClients(context, v) : null,
                      ),
                      if ((me.clientsEnabled ?? false) && clients.isNotEmpty)
                        for (final c in clients) _ClientTile(conversation: c),
                      if ((me.clientsEnabled ?? false) && clients.isEmpty)
                        const ListTile(title: Text('Aún no tienes clientes que te hayan guardado.')),
                    ],
                    const QuietHoursSection(),
                    ...extra,
                  ],
                ),
        );
      },
    );
  }

  Future<void> _setClients(BuildContext context, bool enabled) async {
    final deps = context.read<RadioDeps>();
    final cubit = context.read<RadioCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await deps.api.setRadioClients(enabled);
      await cubit.load();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(radioErrorText(e))));
    }
  }
}

/// Un cliente con silenciar (sus mensajes llegan sin sonar) y bloquear (no puede enviar).
class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.conversation});

  final RadioConversation conversation;

  Future<void> _set(BuildContext context, {bool? muted, bool? blocked}) async {
    final deps = context.read<RadioDeps>();
    final cubit = context.read<RadioCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final peer = conversation.peerId;
    if (peer == null) return;
    try {
      await deps.api.setRadioClient(peer, muted: muted, blocked: blocked);
      await cubit.load();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(radioErrorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    return ListTile(
      key: Key('radio.client.${c.id}'),
      leading: CircleAvatar(child: Text(c.title.isEmpty ? '?' : c.title.characters.first.toUpperCase())),
      title: Text(c.title),
      subtitle: Text(
        c.peerBlocked
            ? 'Bloqueado: no puede enviarte mensajes'
            : c.peerMuted
            ? 'Silenciado: sus mensajes llegan sin sonar'
            : 'Puede hablarte',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('radio.client.mute.${c.id}'),
            tooltip: c.peerMuted ? 'Quitar silencio' : 'Silenciar',
            isSelected: c.peerMuted,
            icon: const Icon(Icons.volume_up),
            selectedIcon: const Icon(Icons.volume_off),
            onPressed: () => _set(context, muted: !c.peerMuted),
          ),
          IconButton(
            key: Key('radio.client.block.${c.id}'),
            tooltip: c.peerBlocked ? 'Desbloquear' : 'Bloquear',
            isSelected: c.peerBlocked,
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.block),
            onPressed: () => _set(context, blocked: !c.peerBlocked),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );
}
