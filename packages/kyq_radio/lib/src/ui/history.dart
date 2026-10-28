import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/conversation_cubit.dart';

String _time(DateTime d) {
  final l = d.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

String _seconds(int? ms) =>
    ms == null ? '' : '${(ms / 1000).toStringAsFixed(ms < 10000 ? 1 : 0).replaceAll('.', ',')} s';

/// Abre una ubicación en Waze o Google Maps (FR-023).
Future<void> openInNavigation(double lat, double lng, {required bool waze}) => launchUrl(
  waze
      ? Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes')
      : Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
  mode: LaunchMode.externalApplication,
);

/// Una entrada del historial: voz, texto, foto, ubicación, alerta o emergencia (FR-011).
class MessageTile extends StatelessWidget {
  const MessageTile({super.key, required this.message, required this.mine, required this.playing});

  final RadioMessage message;
  final bool mine;
  final bool playing;

  Future<void> _menu(BuildContext context) async {
    final cubit = context.read<ConversationCubit>();
    final m = message;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              key: const Key('radio.message.save'),
              leading: Icon(m.saved ? Icons.bookmark_remove : Icons.bookmark_add),
              title: Text(m.saved ? 'Quitar de guardados' : 'Guardar'),
              subtitle: m.saved ? null : const Text('No se borra con la retención (hasta 1 año)'),
              onTap: () => Navigator.pop(context, 'save'),
            ),
            if (!mine)
              ListTile(
                key: const Key('radio.message.report'),
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Reportar mensaje'),
                onTap: () => Navigator.pop(context, 'report'),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'save':
        await cubit.setSaved(m, !m.saved);
      case 'report':
        final reason = await _askReason(context);
        if (reason != null) await cubit.report(m, reason);
    }
  }

  Future<String?> _askReason(BuildContext context) {
    final ctl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar mensaje'),
        content: TextField(
          key: const Key('radio.report.reason'),
          controller: ctl,
          maxLength: 200,
          decoration: const InputDecoration(hintText: '¿Qué pasó? (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, ctl.text.trim()), child: const Text('Reportar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = message;
    final theme = Theme.of(context);
    final cubit = context.read<ConversationCubit>();
    final author = mine ? 'Tú' : (m.authorName.isEmpty ? 'Usuario eliminado' : m.authorName);
    final subtitle = '$author · ${_time(m.createdAt)}';
    final newDot = !m.heard && !mine
        ? Container(
            key: Key('radio.message.new.${m.id}'),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
          )
        : null;
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [if (m.saved) const Icon(Icons.bookmark, size: 18), ?newDot],
    );
    final tile = switch (m.kind) {
      RadioMessageKind.voice => ListTile(
        key: Key('radio.message.${m.id}'),
        leading: IconButton.filledTonal(
          key: Key('radio.message.play.${m.id}'),
          tooltip: playing ? 'Detener' : 'Reproducir',
          icon: Icon(playing ? Icons.stop : Icons.play_arrow),
          onPressed: !m.hasMedia ? null : () => playing ? cubit.stop() : cubit.play(m),
        ),
        title: Text(m.hasMedia ? 'Mensaje de voz · ${_seconds(m.durationMs)}' : 'Mensaje de voz sin audio'),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: !m.hasMedia ? null : () => playing ? cubit.stop() : cubit.play(m),
      ),
      RadioMessageKind.text => ListTile(
        key: Key('radio.message.${m.id}'),
        leading: const Icon(Icons.chat_bubble_outline),
        title: Text(m.body ?? ''),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
      RadioMessageKind.photo => ListTile(
        key: Key('radio.message.${m.id}'),
        leading: const Icon(Icons.photo_outlined),
        title: _PhotoThumb(message: m),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
      RadioMessageKind.location => ListTile(
        key: Key('radio.message.${m.id}'),
        leading: const Icon(Icons.place_outlined),
        title: Text(m.body ?? 'Ubicación compartida'),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: m.lat == null ? null : () => _openPlace(context, m.lat!, m.lng!),
      ),
      RadioMessageKind.alert => ListTile(
        key: Key('radio.message.${m.id}'),
        leading: Icon(Icons.notifications_active_outlined, color: theme.colorScheme.tertiary),
        title: Text(m.body == null ? 'Alerta de llamada' : 'Alerta: ${m.body}'),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
      RadioMessageKind.emergency => ListTile(
        key: Key('radio.message.${m.id}'),
        tileColor: theme.colorScheme.errorContainer,
        leading: Icon(Icons.emergency, color: theme.colorScheme.error),
        title: Text('Emergencia de $author'),
        subtitle: Text('${_time(m.createdAt)} · toca para ver dónde'),
        onTap: m.lat == null ? null : () => _openPlace(context, m.lat!, m.lng!),
      ),
    };
    return GestureDetector(onLongPress: () => _menu(context), child: tile);
  }

  Future<void> _openPlace(BuildContext context, double lat, double lng) async {
    final waze = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              key: const Key('radio.place.waze'),
              leading: const Icon(Icons.navigation_outlined),
              title: const Text('Abrir en Waze'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              key: const Key('radio.place.maps'),
              leading: const Icon(Icons.map_outlined),
              title: const Text('Abrir en Google Maps'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (waze != null) await openInNavigation(lat, lng, waze: waze);
  }
}

/// Miniatura de una foto; tocarla la abre a pantalla completa (US6-2).
class _PhotoThumb extends StatefulWidget {
  const _PhotoThumb({required this.message});

  final RadioMessage message;

  @override
  State<_PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends State<_PhotoThumb> {
  Future<String>? _url;

  @override
  void initState() {
    super.initState();
    if (widget.message.hasMedia) _url = context.read<ConversationCubit>().api.radioMediaUrl(widget.message.id);
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null) return const Text('Foto no disponible');
    return FutureBuilder<String>(
      future: url,
      builder: (context, snap) {
        final u = snap.data;
        if (u == null) return const SizedBox(height: 96, child: Center(child: CircularProgressIndicator()));
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
                body: Center(child: InteractiveViewer(child: Image.network(u))),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              u,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Text('Foto no disponible'),
            ),
          ),
        );
      },
    );
  }
}
