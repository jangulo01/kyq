import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';

import 'support_cubits.dart';
import 'support_labels.dart';

/// "Ayuda": casos del usuario (009, US2). Con [suspended] es lo único que ve la cuenta.
class SupportListPage extends StatelessWidget {
  const SupportListPage({super.key, this.suspended = false, this.onSignOut});

  final bool suspended;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SupportListCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda'),
        automaticallyImplyLeading: !suspended,
        actions: [
          if (onSignOut != null)
            IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: onSignOut),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('support.new'),
        onPressed: () async {
          await context.push('/support/new');
          await cubit.load(quiet: true);
        },
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Nuevo caso'),
      ),
      body: BlocBuilder<SupportListCubit, SupportListState>(
        builder: (context, state) {
          if (state.loading && state.cases.isEmpty) return const Center(child: CircularProgressIndicator());
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                if (suspended)
                  const Card(
                    key: Key('support.suspended'),
                    margin: EdgeInsets.all(12),
                    child: ListTile(
                      leading: Icon(Icons.block),
                      title: Text('Tu cuenta está suspendida'),
                      subtitle: Text('Puedes escribirnos aquí para revisar la decisión o resolver tus casos.'),
                    ),
                  ),
                if (state.error != null) Padding(padding: const EdgeInsets.all(16), child: Text(state.error!)),
                if (state.cases.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No tienes casos. ¿Necesitas ayuda con un viaje, un pago, un objeto olvidado o tu cuenta?',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final c in state.cases) _CaseTile(c: c),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CaseTile extends StatelessWidget {
  const _CaseTile({required this.c});

  final SupportCase c;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waiting = c.status == SupportStatus.waitingUser;
    return ListTile(
      key: ValueKey('support.case.${c.id}'),
      leading: Icon(c.topic == SupportTopic.payment ? Icons.payments_outlined : Icons.support_agent),
      title: Text(c.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${supportTopicLabel(c.topic)} · ${supportStatusLabel(c.status)}'),
      trailing: waiting ? Icon(Icons.mark_chat_unread, color: theme.colorScheme.primary) : null,
      onTap: () async {
        await context.push('/support/${c.id}');
        if (context.mounted) await context.read<SupportListCubit>().load(quiet: true);
      },
    );
  }
}

/// Nuevo caso: tema, viaje opcional y descripción (009 FR-005).
class NewSupportCasePage extends StatefulWidget {
  const NewSupportCasePage({super.key});

  @override
  State<NewSupportCasePage> createState() => _NewSupportCasePageState();
}

class _NewSupportCasePageState extends State<NewSupportCasePage> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewCaseCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo caso')),
      body: BlocConsumer<NewCaseCubit, NewCaseState>(
        listenWhen: (a, b) => (b.createdId != null && a.createdId == null) || (b.error != null && a.error != b.error),
        listener: (context, state) {
          final id = state.createdId;
          if (id != null) {
            context.pushReplacement('/support/$id');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('¿Con qué necesitas ayuda?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in SupportTopic.values)
                  ChoiceChip(
                    key: Key('support.topic.${t.name}'),
                    label: Text(supportTopicLabel(t)),
                    selected: state.topic == t,
                    onSelected: (_) => cubit.setTopic(t),
                  ),
              ],
            ),
            if (state.trips.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                key: const Key('support.trip'),
                initialValue: state.tripId,
                decoration: const InputDecoration(labelText: 'Viaje (opcional)'),
                items: [
                  const DropdownMenuItem<String?>(child: Text('Ninguno')),
                  for (final t in state.trips) DropdownMenuItem<String?>(value: t.id, child: Text(_tripLabel(t))),
                ],
                onChanged: cubit.setTrip,
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              key: const Key('support.description'),
              controller: _text,
              minLines: 4,
              maxLines: 8,
              maxLength: 2000,
              decoration: const InputDecoration(labelText: 'Cuéntanos qué pasó', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('support.submit'),
              onPressed: state.topic == null || state.sending ? null : () => cubit.submit(_text.text),
              child: state.sending
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  static String _tripLabel(SupportTripRef t) {
    final d = t.createdAt.toLocal();
    return '${d.day}/${d.month} · ${t.otherParty}';
  }
}

/// Conversación de un caso; un caso cerrado ofrece abrir otro (009 FR-007).
class SupportCasePage extends StatefulWidget {
  const SupportCasePage({super.key});

  @override
  State<SupportCasePage> createState() => _SupportCasePageState();
}

class _SupportCasePageState extends State<SupportCasePage> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (await context.read<SupportCaseCubit>().reply(_text.text)) _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupportCaseCubit, SupportCaseState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) {
        final detail = state.detail;
        return Scaffold(
          appBar: AppBar(title: Text(detail?.supportCase.subject ?? 'Caso')),
          body: detail == null
              ? Center(
                  child: state.loading ? const CircularProgressIndicator() : const Text('No pudimos cargar el caso.'),
                )
              : Column(
                  children: [
                    ListTile(
                      dense: true,
                      title: Text(supportTopicLabel(detail.supportCase.topic)),
                      trailing: Chip(
                        key: const Key('support.status'),
                        label: Text(supportStatusLabel(detail.supportCase.status)),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [for (final m in detail.messages) SupportBubble(message: m)],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: state.closed
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Este caso está cerrado.', key: Key('support.closed')),
                                  TextButton(
                                    onPressed: () => context.pushReplacement('/support/new'),
                                    child: const Text('Abrir un caso nuevo'),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      key: const Key('support.reply'),
                                      controller: _text,
                                      minLines: 1,
                                      maxLines: 4,
                                      maxLength: 2000,
                                      decoration: const InputDecoration(
                                        hintText: 'Escribe tu respuesta',
                                        counterText: '',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    key: const Key('support.send'),
                                    tooltip: 'Enviar',
                                    onPressed: state.sending ? null : _send,
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
  }
}

/// Un mensaje del caso: los propios a la derecha, los del soporte a la izquierda y los del
/// sistema centrados. Las notas internas solo llegan al panel.
class SupportBubble extends StatelessWidget {
  const SupportBubble({super.key, required this.message, this.adminView = false});

  final SupportMessage message;

  /// En el panel, "propio" es lo del soporte y las notas internas se marcan.
  final bool adminView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = message;
    if (m.authorKind == SupportAuthor.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          m.body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }
    final right = adminView ? m.authorKind == SupportAuthor.admin : m.mine;
    final who = switch (m.authorKind) {
      SupportAuthor.admin => adminView ? (m.authorName ?? 'Soporte') : 'Soporte Kyq',
      _ => m.mine ? 'Tú' : (m.authorName ?? 'Usuario'),
    };
    final color = m.internal
        ? theme.colorScheme.tertiaryContainer
        : right
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final d = m.createdAt.toLocal();
    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.internal ? '$who · nota interna' : who, style: theme.textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(m.body),
            const SizedBox(height: 2),
            Text(
              '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
