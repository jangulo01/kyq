import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';

import '../controller/radio_cubit.dart';
import '../deps.dart';
import 'add_contact.dart';
import 'status.dart';

/// Por qué no hay acceso a Radio y qué falta (FR-005).
String accessText(RadioMe me) => switch (me.accessReason) {
  'suspended' => 'Tu cuenta está suspendida. Escribe a soporte desde Ayuda.',
  'trial_ended' => 'Terminó tu prueba de Radio. Activa tu suscripción para seguir usándola.',
  'no_subscription' when me.access == RadioAccess.listen =>
    'Sin suscripción puedes escuchar y leer, pero no transmitir. Activa tu suscripción para hablar.',
  'no_subscription' => 'Radio es para conductores con suscripción activa. Actívala para usarla.',
  _ => 'Radio no está disponible para tu cuenta.',
};

/// Aviso y aceptación del registro antes del primer uso (FR-013).
Future<bool> showRadioConsent(BuildContext context, int retentionDays) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Tus mensajes de Radio quedan guardados'),
      content: Text(
        'Para que nadie pierda un mensaje, Kyq guarda la voz, los textos, las fotos y las ubicaciones '
        'de Radio durante $retentionDays días; después se borran, salvo los que tú guardes. '
        'Kyq solo revisa un mensaje si alguien lo reporta o en una emergencia. '
        'La voz del viaje y la consulta previa nunca se graban.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ahora no')),
        FilledButton(
          key: const Key('radio.consent.accept'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Entendido, acepto'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Pestaña Radio (FR-001, phva.md §1.3): una sola lista con contactos, clientes, canales y la
/// cooperativa, cada uno con su estado o conectados, mensajes nuevos y "Escuchar".
class RadioPage extends StatefulWidget {
  const RadioPage({super.key});

  @override
  State<RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends State<RadioPage> {
  bool _askedConsent = false;

  @override
  void initState() {
    super.initState();
    // El estado pudo llegar antes de montar la pantalla: el listener no lo vería.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeConsent(context.read<RadioCubit>().state);
    });
  }

  Future<void> _maybeConsent(RadioState s) async {
    final me = s.me;
    if (me == null || !me.consentRequired || _askedConsent || me.access == RadioAccess.none) return;
    _askedConsent = true;
    final cubit = context.read<RadioCubit>();
    if (await showRadioConsent(context, me.retentionDays)) await cubit.acceptConsent();
  }

  @override
  Widget build(BuildContext context) {
    final deps = context.read<RadioDeps>();
    return BlocConsumer<RadioCubit, RadioState>(
      listenWhen: (a, b) => (b.notice != null && a.notice != b.notice) || a.me != b.me,
      listener: (context, s) {
        if (s.notice != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.notice!)));
          context.read<RadioCubit>().clearNotice();
        }
        _maybeConsent(s);
      },
      builder: (context, s) {
        final cubit = context.read<RadioCubit>();
        final me = s.me;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Radio'),
            actions: [
              if (me != null && me.access != RadioAccess.none) ...[
                PresenceSelector(status: me.status, radioOn: me.radioOn, onChanged: cubit.setStatus),
                IconButton(
                  key: const Key('radio.power'),
                  tooltip: me.radioOn ? 'Apagar radio' : 'Encender radio',
                  onPressed: () => cubit.setRadioOn(!me.radioOn),
                  icon: Icon(me.radioOn ? Icons.radio : Icons.radio_outlined),
                ),
                IconButton(
                  key: const Key('radio.autoMode'),
                  tooltip: 'Modo auto',
                  onPressed: () => context.push(RadioRoutes.auto),
                  icon: const Icon(Icons.directions_car),
                ),
                IconButton(
                  key: const Key('radio.settings'),
                  tooltip: 'Ajustes de Radio',
                  onPressed: () => context.push(RadioRoutes.settings),
                  icon: const Icon(Icons.tune),
                ),
              ],
            ],
          ),
          floatingActionButton: deps.isDriver && me != null && me.access == RadioAccess.full
              ? FloatingActionButton.extended(
                  key: const Key('radio.add'),
                  onPressed: () => showRadioAddMenu(context),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Agregar'),
                )
              : null,
          body: s.loading && s.conversations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: cubit.load,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      if (me != null && me.access != RadioAccess.full)
                        Card(
                          key: const Key('radio.access'),
                          margin: const EdgeInsets.all(12),
                          child: ListTile(leading: const Icon(Icons.info_outline), title: Text(accessText(me))),
                        ),
                      if (me?.trialDaysLeft case final days?)
                        Card(
                          key: const Key('radio.trial'),
                          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: ListTile(
                            leading: const Icon(Icons.hourglass_bottom),
                            title: Text('Prueba de Radio: te ${days == 1 ? 'queda 1 día' : 'quedan $days días'}'),
                            subtitle: const Text('Activa tu suscripción para seguir usándola después.'),
                          ),
                        ),
                      if (me != null && !me.radioOn && me.access != RadioAccess.none)
                        ListTile(
                          key: const Key('radio.off'),
                          leading: const Icon(Icons.radio_outlined),
                          title: const Text('Radio apagada'),
                          subtitle: const Text('Los mensajes llegan al historial. Enciéndela para oírlos en vivo.'),
                          trailing: FilledButton(
                            onPressed: () => cubit.setRadioOn(true),
                            child: const Text('Encender'),
                          ),
                        ),
                      if (s.error != null) Padding(padding: const EdgeInsets.all(16), child: Text(s.error!)),
                      if (s.conversations.isEmpty && me?.access != RadioAccess.none && !s.loading)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            deps.isDriver
                                ? 'Agrega a tus compañeros con su QR o crea un canal para tu grupo.'
                                : 'Aquí aparecen tus conductores cuando activan "Radio con mis clientes".',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final c in s.conversations) _ConversationTile(conversation: c, holder: s.holders[c.id]),
                      // R9: sin Google Play la invitación entra pegando el enlace.
                      if (me != null && me.access != RadioAccess.none && !s.loading)
                        ListTile(
                          key: const Key('radio.haveLink'),
                          leading: const Icon(Icons.link),
                          title: const Text('¿Tienes un enlace de invitación?'),
                          subtitle: const Text('Cópialo y tócalo aquí: lo tomamos del portapapeles.'),
                          onTap: () => pasteRadioInviteLink(context),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, this.holder});

  final RadioConversation conversation;
  final String? holder;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final cubit = context.read<RadioCubit>();
    final subtitle = switch (c) {
      _ when holder != null => '$holder está hablando',
      _ when c.pending => 'Solicitud pendiente',
      _ when c.suspended => 'Suspendido por Kyq',
      _ when c.isChannel => '${c.onlineCount ?? 0} conectados',
      _ => presenceLabel(c.peerStatus ?? RadioPresence.offline),
    };
    final leading = switch (c.kind) {
      RadioConversationKind.cooperative => const CircleAvatar(child: Icon(Icons.groups_2)),
      RadioConversationKind.channel => const CircleAvatar(child: Icon(Icons.groups)),
      _ => Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(child: Text(c.title.isEmpty ? '?' : c.title.characters.first.toUpperCase())),
          Positioned(right: -2, bottom: -2, child: PresenceDot(presence: c.peerStatus ?? RadioPresence.offline)),
        ],
      ),
    };
    return ListTile(
      key: Key('radio.conversation.${c.id}'),
      leading: leading,
      title: Text(c.title, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle),
      onTap: () => context.push(RadioRoutes.conversation(c.id)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c.unreadCount > 0)
            Badge(key: Key('radio.unread.${c.id}'), label: Text('${c.unreadCount}'), largeSize: 22),
          Tooltip(
            message: 'Escuchar',
            child: Switch(
              key: Key('radio.listen.${c.id}'),
              value: c.listening,
              onChanged: c.pending ? null : (v) => cubit.setListening(c.id, v),
            ),
          ),
        ],
      ),
    );
  }
}
