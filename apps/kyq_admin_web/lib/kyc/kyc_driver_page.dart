import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'kyc_cubits.dart';

/// Motivos de rechazo frecuentes (FR-008); "Otro" permite escribirlo.
const rejectReasons = [
  'Foto borrosa o ilegible',
  'Los datos no coinciden con el documento',
  'Documento vencido',
  'El documento es de otra persona',
];

String _statusLabel(KycDocument d) => switch (d.status) {
  DocumentStatus.uploading => 'Subida sin terminar',
  DocumentStatus.submitted => 'En revisión',
  DocumentStatus.approved =>
    d.expired ? 'Aprobado · vencido' : (d.legacy ? 'Aprobado · de 001, sin fotos' : 'Aprobado'),
  DocumentStatus.rejected => 'Rechazado',
  DocumentStatus.superseded => 'Reemplazado',
};

/// Expediente del conductor: fotos junto a lo declarado, aprobar o rechazar cada documento (T023).
class KycDriverPage extends StatelessWidget {
  const KycDriverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<KycDriverCubit>();
    return BlocConsumer<KycDriverCubit, KycDriverState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) {
        final file = state.file;
        return Scaffold(
          appBar: AppBar(
            title: Text(file == null ? 'Expediente' : 'Expediente de ${file.displayName}'),
            actions: [IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load)],
          ),
          body: file == null
              ? Center(child: state.loading ? const CircularProgressIndicator() : Text(state.error ?? ''))
              : Column(
                  children: [
                    if (state.busy || state.loading) const LinearProgressIndicator(),
                    Expanded(
                      child: _FileView(file: file, busy: state.busy),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _FileView extends StatelessWidget {
  const _FileView({required this.file, required this.busy});

  final KycDriverFile file;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final v = file.vehicle;
    final error = TextStyle(color: Theme.of(context).colorScheme.error);
    final slots = {for (final s in file.documents) s.docType: s};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text([file.displayName, ?file.phoneE164].join(' · ')),
            subtitle: Text(
              v == null
                  ? 'Sin vehículo registrado'
                  : [v.plate, v.brand, v.model, v.color, v.year?.toString()].nonNulls.join(' · '),
            ),
          ),
        ),
        if (file.blockedDocuments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No puede trabajar: ${file.blockedDocuments.map((b) => '${docTypeLabel(b.docType)} ${b.problem == BlockedDocumentProblem.expired ? 'vencido' : 'sin aprobar'}').join(', ')}.',
              key: const Key('kyc.blocked'),
              style: error,
            ),
          ),
        for (final type in DocType.values) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(slots[type]?.label ?? docTypeLabel(type), style: Theme.of(context).textTheme.titleMedium),
          ),
          ..._slot(slots[type], error),
        ],
      ],
    );
  }

  /// El envío en revisión (o el último) arriba y el aprobado vigente debajo.
  List<Widget> _slot(OnboardingDocument? slot, TextStyle error) {
    final docs = [?slot?.latest, ?slot?.current];
    return [
      if (docs.isEmpty) const Padding(padding: EdgeInsets.only(left: 4), child: Text('No ha enviado este documento.')),
      if (slot != null && slot.suggestSupport)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Rechazado ${slot.rejectedCount} veces: conviene llamar al conductor.', style: error),
        ),
      for (final doc in docs) _DocumentCard(doc: doc, busy: busy),
    ];
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc, required this.busy});

  final KycDocument doc;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = doc.status == DocumentStatus.submitted;
    final facts = <String>[
      'Número: ${doc.number ?? '—'}',
      if (doc.docType.expires) 'Vence: ${doc.expiresAt == null ? '—' : formatDate(doc.expiresAt!)}',
      if (doc.exemptUntil != null) 'No aplica hasta: ${formatDate(doc.exemptUntil!)}',
      if (doc.submittedAt != null) 'Enviado: ${formatDate(doc.submittedAt!)}',
      if (doc.reviewedAt != null) 'Revisado: ${formatDate(doc.reviewedAt!)}',
      if (doc.rejectReason != null) 'Motivo del rechazo: ${doc.rejectReason}',
    ];
    return Card(
      key: Key('kyc.doc.${doc.id}'),
      color: pending ? theme.colorScheme.secondaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(label: Text(_statusLabel(doc)), visualDensity: VisualDensity.compact),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final p in doc.photos) _PhotoThumb(photo: p, title: docTypeLabel(doc.docType)),
                if (doc.photos.isEmpty) const Text('Sin fotos'),
              ],
            ),
            const SizedBox(height: 8),
            Text(facts.join('\n')),
            if (pending) ...[
              const SizedBox(height: 8),
              OverflowBar(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: Key('kyc.reject.${doc.id}'),
                    onPressed: busy ? null : () => _reject(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                  ),
                  FilledButton.icon(
                    key: Key('kyc.approve.${doc.id}'),
                    onPressed: busy ? null : () => _approve(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Aprobar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<KycDriverCubit>(),
      child: _ApproveDialog(doc: doc),
    ),
  );

  Future<void> _reject(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<KycDriverCubit>(),
      child: _RejectDialog(doc: doc),
    ),
  );
}

/// Miniatura de una foto (URL firmada de 5 min); al tocarla se abre ampliable.
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo, required this.title});

  final DocumentPhoto photo;
  final String title;

  @override
  Widget build(BuildContext context) {
    final side = photo.side == DocSide.front ? 'Frente' : 'Reverso';
    return InkWell(
      key: Key('kyc.photo.${photo.side.name}'),
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(title: Text('$title · $side')),
            body: InteractiveViewer(maxScale: 6, child: Center(child: _networkImage(photo.url, BoxFit.contain))),
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(width: 220, height: 140, child: _networkImage(photo.url, BoxFit.cover)),
          Text(side),
        ],
      ),
    );
  }

  static Widget _networkImage(String url, BoxFit fit) => Image.network(
    url,
    fit: fit,
    errorBuilder: (_, _, _) =>
        const Center(child: Text('No se pudo cargar la foto.\nRecarga el expediente.', textAlign: TextAlign.center)),
  );
}

class _ApproveDialog extends StatefulWidget {
  const _ApproveDialog({required this.doc});

  final KycDocument doc;

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  late final _number = TextEditingController(text: widget.doc.number ?? '');
  late DateTime? _expiresAt = widget.doc.expiresAt;
  late DateTime? _exemptUntil = widget.doc.exemptUntil;
  bool _saving = false;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime? initial, String help) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      helpText: help,
      initialDate: initial ?? now.add(const Duration(days: 365)),
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365 * 15)),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context.read<KycDriverCubit>().approve(
      widget.doc,
      number: _number.text,
      expiresAt: _expiresAt,
      exemptUntil: _exemptUntil == widget.doc.exemptUntil ? null : _exemptUntil,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    return AlertDialog(
      title: Text('Aprobar ${docTypeLabel(doc.docType)}'),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Corrige lo declarado si no coincide con la foto.'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('approve.number'),
              controller: _number,
              decoration: const InputDecoration(labelText: 'Número'),
            ),
            if (doc.docType.expires) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('approve.expiry'),
                onPressed: () async {
                  final d = await _pick(_expiresAt, 'Vence el');
                  if (d != null) setState(() => _expiresAt = d);
                },
                icon: const Icon(Icons.event),
                label: Text(_expiresAt == null ? 'Fecha de vencimiento' : 'Vence el ${formatDate(_expiresAt!)}'),
              ),
            ],
            if (doc.docType == DocType.technicalInspection) ...[
              const SizedBox(height: 12),
              const Text('Vehículo nuevo: la revisión no aplica hasta una fecha.'),
              OutlinedButton.icon(
                key: const Key('approve.exempt'),
                onPressed: () async {
                  final d = await _pick(_exemptUntil, 'No aplica hasta');
                  if (d != null) setState(() => _exemptUntil = d);
                },
                icon: const Icon(Icons.event_available),
                label: Text(_exemptUntil == null ? 'No aplica hasta…' : 'No aplica hasta ${formatDate(_exemptUntil!)}'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('approve.confirm'),
          onPressed: _saving || (doc.docType.expires && _expiresAt == null && _exemptUntil == null) ? null : _save,
          child: const Text('Aprobar'),
        ),
      ],
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.doc});

  final KycDocument doc;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _other = TextEditingController();
  String? _reason;
  bool _saving = false;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  String get _text => _reason ?? _other.text.trim();

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context.read<KycDriverCubit>().reject(widget.doc, _text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rechazar ${docTypeLabel(widget.doc.docType)}'),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('El conductor verá este motivo en la app.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in rejectReasons)
                  ChoiceChip(
                    label: Text(r),
                    selected: _reason == r,
                    onSelected: (v) => setState(() => _reason = v ? r : null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('reject.other'),
              controller: _other,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Otro motivo'),
              onChanged: (_) => setState(() => _reason = null),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('reject.confirm'),
          onPressed: _saving || _text.isEmpty ? null : _save,
          child: const Text('Rechazar'),
        ),
      ],
    );
  }
}
