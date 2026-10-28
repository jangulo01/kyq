import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';

import '../controller/conversation_cubit.dart';
import '../controller/radio_cubit.dart';
import '../deps.dart';
import 'history.dart';
import 'status.dart';
import 'talk_button.dart';

/// Abre una conversación con su propio [ConversationCubit].
class ConversationScreen extends StatelessWidget {
  const ConversationScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final deps = context.read<RadioDeps>();
    return BlocProvider(
      create: (context) => ConversationCubit(
        api: deps.api,
        conversationId: conversationId,
        myUserId: deps.myUserId,
        events: deps.events,
        player: deps.newPlayer(),
        radio: context.read<RadioCubit>(),
      )..load(),
      child: ConversationPage(conversationId: conversationId),
    );
  }
}

/// Conversación (FR-009, phva.md §1.3): arriba el nombre, el estado y la duración; en el centro
/// el botón grande; debajo el historial; al fondo, escribir, foto, ubicación y alerta.
class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    // La seleccionada es la que habla con la burbuja y el botón Bluetooth (FR-028).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RadioCubit>().select(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _sendText(ConversationCubit cubit) async {
    if (await cubit.sendText(_text.text)) _text.clear();
  }

  Future<void> _attach(BuildContext context, ConversationCubit cubit) async {
    final deps = context.read<RadioDeps>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              key: const Key('radio.attach.camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              key: const Key('radio.attach.gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (deps.location != null)
              ListTile(
                key: const Key('radio.attach.location'),
                leading: const Icon(Icons.my_location),
                title: const Text('Enviar mi ubicación'),
                onTap: () => Navigator.pop(context, 'location'),
              ),
            ListTile(
              key: const Key('radio.attach.alert'),
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Enviar alerta de llamada'),
              subtitle: const Text('Suena hasta que la abran, también en Ocupado'),
              onTap: () => Navigator.pop(context, 'alert'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case 'camera' || 'gallery':
        final jpeg = await deps.photos.pick(camera: choice == 'camera');
        if (jpeg != null) await cubit.sendPhoto(jpeg);
      case 'location':
        final here = await deps.location!.current();
        if (here == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('No pudimos obtener tu ubicación. Revisa el permiso.')));
          }
          return;
        }
        await cubit.sendLocation(here);
      case 'alert':
        final ctl = TextEditingController();
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Alerta de llamada'),
            content: TextField(
              key: const Key('radio.alert.text'),
              controller: ctl,
              maxLength: 80,
              decoration: const InputDecoration(hintText: 'Ej.: llámame cuando puedas (opcional)'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              FilledButton(
                key: const Key('radio.alert.send'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enviar alerta'),
              ),
            ],
          ),
        );
        if (ok == true) await cubit.sendAlert(text: ctl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = context.read<RadioDeps>();
    return BlocListener<ConversationCubit, ConversationState>(
      listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
      listener: (context, s) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.notice!)));
        context.read<ConversationCubit>().clearNotice();
      },
      child: BlocBuilder<RadioCubit, RadioState>(
        builder: (context, radio) {
          final conv = radio.byId(widget.conversationId);
          final cubit = context.read<ConversationCubit>();
          return BlocBuilder<ConversationCubit, ConversationState>(
            builder: (context, s) {
              final c = conv ?? s.detail?.conversation;
              if (c == null) {
                return Scaffold(
                  appBar: AppBar(),
                  body: Center(
                    child: s.loading ? const CircularProgressIndicator() : const Text('Conversación no disponible'),
                  ),
                );
              }
              final status = c.isChannel
                  ? '${c.onlineCount ?? 0} conectados${c.suspended ? ' · suspendido' : ''}'
                  : presenceLabel(c.peerStatus ?? RadioPresence.offline);
              return Scaffold(
                appBar: AppBar(
                  titleSpacing: 0,
                  title: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: c.isChannel
                        ? Icon(c.kind == RadioConversationKind.cooperative ? Icons.groups_2 : Icons.groups)
                        : PresenceDot(presence: c.peerStatus ?? RadioPresence.offline, size: 18),
                    title: Text(c.title, key: const Key('radio.conversation.title'), overflow: TextOverflow.ellipsis),
                    subtitle: Text(status, key: const Key('radio.conversation.status')),
                    onTap: c.isChannel ? () => context.push(RadioRoutes.channel(c.id)) : null,
                  ),
                  actions: [
                    IconButton(
                      key: const Key('radio.speed'),
                      tooltip: 'Velocidad de reproducción',
                      onPressed: cubit.cycleSpeed,
                      icon: Text('${s.speed.toString().replaceAll('.0', '').replaceAll('.', ',')}x'),
                    ),
                    IconButton(
                      key: const Key('radio.output'),
                      tooltip: radio.speakerOn ? 'Altavoz' : 'Auricular',
                      onPressed: () => context.read<RadioCubit>().setSpeaker(!radio.speakerOn),
                      icon: Icon(radio.speakerOn ? Icons.volume_up : Icons.phone_in_talk),
                    ),
                    if (deps.onEmergency != null) _EmergencyButton(onTriggered: () => deps.onEmergency!(context, c)),
                  ],
                ),
                body: Column(
                  children: [
                    if (c.pending)
                      const MaterialBanner(
                        content: Text('Tu solicitud de entrada espera que un moderador la apruebe.'),
                        actions: [SizedBox.shrink()],
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: TalkButton(conversation: c),
                    ),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('radio.repeat'),
                          onPressed: s.lastVoice == null ? null : cubit.repeatLast,
                          icon: const Icon(Icons.replay),
                          label: const Text('Repetir último'),
                        ),
                        if (s.unheard.isNotEmpty)
                          FilledButton.tonalIcon(
                            key: const Key('radio.playNew'),
                            onPressed: cubit.playNew,
                            icon: const Icon(Icons.playlist_play),
                            label: Text('Reproducir nuevos (${s.unheard.length})'),
                          ),
                        if (deps.onRequestTrip != null && c.kind == RadioConversationKind.client)
                          FilledButton.icon(
                            key: const Key('radio.requestTrip'),
                            onPressed: () => deps.onRequestTrip!(context, c),
                            icon: const Icon(Icons.local_taxi),
                            label: const Text('Pedir viaje'),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: s.loading
                          ? const Center(child: CircularProgressIndicator())
                          : s.messages.isEmpty
                          ? const Center(child: Text('Aún no hay mensajes. Mantén pulsado para hablar.'))
                          : NotificationListener<ScrollEndNotification>(
                              onNotification: (n) {
                                if (n.metrics.extentAfter < 200) unawaited(cubit.loadMore());
                                return false;
                              },
                              child: ListView.builder(
                                key: const Key('radio.history'),
                                itemCount: s.messages.length,
                                itemBuilder: (context, i) {
                                  final m = s.messages[i];
                                  return MessageTile(
                                    message: m,
                                    mine: m.authorId == deps.myUserId,
                                    playing: s.playingId == m.id,
                                  );
                                },
                              ),
                            ),
                    ),
                    if (c.canTalk && !c.suspended)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                          child: Row(
                            children: [
                              IconButton(
                                key: const Key('radio.attach'),
                                tooltip: 'Foto, ubicación o alerta',
                                onPressed: s.sending ? null : () => _attach(context, cubit),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              Expanded(
                                child: TextField(
                                  key: const Key('radio.text'),
                                  controller: _text,
                                  maxLength: 500,
                                  minLines: 1,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: 'Escribe un mensaje',
                                    counterText: '',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _sendText(cubit),
                                ),
                              ),
                              IconButton(
                                key: const Key('radio.send'),
                                tooltip: 'Enviar',
                                onPressed: s.sending ? null : () => _sendText(cubit),
                                icon: const Icon(Icons.send),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Emergencia: mantener pulsado 2 s, para no activarla por error (US9-2).
class _EmergencyButton extends StatefulWidget {
  const _EmergencyButton({required this.onTriggered});

  final Future<void> Function() onTriggered;

  @override
  State<_EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<_EmergencyButton> {
  Timer? _hold;

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Emergencia: mantén pulsado 2 segundos',
      child: Listener(
        key: const Key('radio.emergency'),
        onPointerDown: (_) => _hold = Timer(const Duration(seconds: 2), () => unawaited(widget.onTriggered())),
        onPointerUp: (_) {
          final early = _hold?.isActive ?? false;
          _hold?.cancel();
          if (early) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Para la emergencia, mantén pulsado el botón 2 segundos.')));
          }
        },
        onPointerCancel: (_) => _hold?.cancel(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.emergency, color: scheme.error),
        ),
      ),
    );
  }
}
