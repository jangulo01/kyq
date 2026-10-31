import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../tower/trip_inspection_view.dart';
import 'support_admin_cubits.dart';

const _adminStatusLabels = {
  SupportStatus.open: 'Abierto',
  SupportStatus.inProgress: 'En atención',
  SupportStatus.waitingUser: 'Esperando al usuario',
  SupportStatus.resolved: 'Resuelto',
  SupportStatus.closed: 'Cerrado',
};

String _since(DateTime d) {
  final m = DateTime.now().difference(d).inMinutes;
  if (m < 60) return 'hace $m min';
  if (m < 48 * 60) return 'hace ${m ~/ 60} h';
  return 'hace ${m ~/ (24 * 60)} días';
}

/// Bandeja de soporte (009, US2): filtros por estado, tema, asignado y sin respuesta.
class SupportInboxPage extends StatelessWidget {
  const SupportInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SupportInboxCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte y disputas'),
        actions: [IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load)],
      ),
      body: BlocBuilder<SupportInboxCubit, InboxState>(
        builder: (context, state) {
          final f = state.filter;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      key: const Key('inbox.unanswered'),
                      label: const Text('Sin respuesta'),
                      selected: f.unanswered,
                      onSelected: (v) => cubit.setFilter(f.copyWith(unanswered: v)),
                    ),
                    FilterChip(
                      key: const Key('inbox.mine'),
                      label: const Text('Asignados a mí'),
                      selected: f.mine,
                      onSelected: (v) => cubit.setFilter(f.copyWith(mine: v)),
                    ),
                    DropdownButton<SupportStatus?>(
                      key: const Key('inbox.status'),
                      value: f.status,
                      hint: const Text('Estado'),
                      items: [
                        const DropdownMenuItem<SupportStatus?>(child: Text('Todos los abiertos')),
                        for (final s in SupportStatus.values)
                          DropdownMenuItem<SupportStatus?>(value: s, child: Text(_adminStatusLabels[s]!)),
                      ],
                      onChanged: (s) => cubit.setFilter(f.copyWith(status: () => s)),
                    ),
                    DropdownButton<SupportTopic?>(
                      key: const Key('inbox.topic'),
                      value: f.topic,
                      hint: const Text('Tema'),
                      items: [
                        const DropdownMenuItem<SupportTopic?>(child: Text('Todos los temas')),
                        for (final t in SupportTopic.values)
                          DropdownMenuItem<SupportTopic?>(value: t, child: Text(supportTopicLabel(t))),
                      ],
                      onChanged: (t) => cubit.setFilter(f.copyWith(topic: () => t)),
                    ),
                  ],
                ),
              ),
              if (state.loading) const LinearProgressIndicator(),
              if (state.error != null) Padding(padding: const EdgeInsets.all(12), child: Text(state.error!)),
              Expanded(
                child: state.cases.isEmpty && !state.loading
                    ? const Center(child: Text('No hay casos con estos filtros.'))
                    : ListView.separated(
                        itemCount: state.cases.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = state.cases[i];
                          return ListTile(
                            key: ValueKey('inbox.case.${c.id}'),
                            leading: Icon(
                              c.topic == SupportTopic.payment ? Icons.payments_outlined : Icons.support_agent,
                              color: c.awaitingReply ? Theme.of(context).colorScheme.error : null,
                            ),
                            title: Text(c.subject),
                            subtitle: Text(
                              '${c.user.displayName} (${c.userRole == 'driver' ? 'conductor' : 'pasajero'}) · '
                              '${supportTopicLabel(c.topic)} · ${_adminStatusLabels[c.status]}'
                              '${c.assignedTo == null ? '' : ' · ${c.assignedTo!.displayName}'}',
                            ),
                            trailing: Text(_since(c.lastUserMessageAt ?? c.createdAt)),
                            onTap: () async {
                              await context.push('/support/${c.id}');
                              await cubit.load(quiet: true);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Caso en el panel: conversación con notas internas, estado, asignación y pago de 004.
class SupportAdminCasePage extends StatefulWidget {
  const SupportAdminCasePage({super.key, this.adminId});

  /// Administrador de la sesión, para "Asignarme".
  final String? adminId;

  @override
  State<SupportAdminCasePage> createState() => _SupportAdminCasePageState();
}

class _SupportAdminCasePageState extends State<SupportAdminCasePage> {
  final _text = TextEditingController();
  bool _internal = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (await context.read<SupportAdminCaseCubit>().reply(_text.text, internal: _internal)) _text.clear();
  }

  Future<void> _resolve(bool paid) async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(paid ? 'Marcar como pagado en efectivo' : 'Marcar como no pagado'),
        content: TextField(
          key: const Key('case.paymentNote'),
          controller: note,
          maxLength: 200,
          decoration: const InputDecoration(labelText: 'Nota para el registro'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            key: const Key('case.paymentConfirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await context.read<SupportAdminCaseCubit>().resolvePayment(paid: paid, note: note.text);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SupportAdminCaseCubit>();
    return BlocConsumer<SupportAdminCaseCubit, AdminCaseState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!))),
      builder: (context, state) {
        final d = state.detail;
        final c = d?.supportCase;
        final closed = c?.status == SupportStatus.closed;
        return Scaffold(
          appBar: AppBar(title: Text(c?.subject ?? 'Caso')),
          body: d == null || c == null
              ? Center(child: state.loading ? const CircularProgressIndicator() : const Text('Caso no encontrado.'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${c.user.displayName} (${c.userRole == 'driver' ? 'conductor' : 'pasajero'})'
                            '${c.counterpart == null ? '' : ' y ${c.counterpart!.displayName}'}',
                          ),
                          Chip(label: Text(supportTopicLabel(c.topic))),
                          DropdownButton<SupportStatus>(
                            key: const Key('case.status'),
                            value: c.status,
                            items: [
                              for (final s in SupportStatus.values)
                                DropdownMenuItem(value: s, child: Text(_adminStatusLabels[s]!)),
                            ],
                            onChanged: closed || state.busy ? null : (s) => s == null ? null : cubit.setStatus(s),
                          ),
                          if (c.assignedTo?.id != widget.adminId && widget.adminId != null)
                            OutlinedButton(
                              key: const Key('case.assignMe'),
                              onPressed: state.busy ? null : () => cubit.assign(widget.adminId),
                              child: const Text('Asignarme'),
                            ),
                          if (c.assignedTo != null)
                            InputChip(
                              label: Text('Asignado a ${c.assignedTo!.displayName}'),
                              onDeleted: state.busy ? null : () => cubit.assign(null),
                            ),
                          if (c.tripId != null)
                            TextButton.icon(
                              onPressed: () => showTripInspection(context, c.tripId!, refreshEvery: null),
                              icon: const Icon(Icons.local_taxi_outlined),
                              label: const Text('Ver viaje'),
                            ),
                          if (c.tripPaymentId != null && !closed && c.status != SupportStatus.resolved) ...[
                            FilledButton(
                              key: const Key('case.paid'),
                              onPressed: state.busy ? null : () => _resolve(true),
                              child: const Text('Pagado en efectivo'),
                            ),
                            OutlinedButton(
                              key: const Key('case.unpaid'),
                              onPressed: state.busy ? null : () => _resolve(false),
                              child: const Text('No pagado'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [for (final m in d.messages) SupportBubble(message: m, adminView: true)],
                      ),
                    ),
                    if (!closed)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const Key('case.reply'),
                                  controller: _text,
                                  minLines: 1,
                                  maxLines: 4,
                                  maxLength: 2000,
                                  decoration: InputDecoration(
                                    hintText: _internal ? 'Nota interna (el usuario no la ve)' : 'Respuesta al usuario',
                                    counterText: '',
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Nota'),
                                  Switch(
                                    key: const Key('case.internal'),
                                    value: _internal,
                                    onChanged: (v) => setState(() => _internal = v),
                                  ),
                                ],
                              ),
                              IconButton(
                                key: const Key('case.send'),
                                tooltip: 'Enviar',
                                onPressed: state.busy ? null : _send,
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
