import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'document_capture_cubit.dart';
import 'photo_source.dart';

String _numberLabel(DocType type) => switch (type) {
  DocType.nationalId => 'Número de cédula',
  DocType.license => 'Número de licencia',
  DocType.mandatoryInsurance => 'Número de póliza',
  DocType.technicalInspection => 'Número del certificado',
  DocType.vehicleRegistration => 'Número de la tarjeta de propiedad',
};

/// Fotos, número y vencimiento de un documento (T017). [rejectReason] es el motivo del rechazo
/// anterior, para que el conductor sepa qué corregir.
class DocumentCapturePage extends StatefulWidget {
  const DocumentCapturePage({super.key, this.rejectReason});

  final String? rejectReason;

  @override
  State<DocumentCapturePage> createState() => _DocumentCapturePageState();
}

class _DocumentCapturePageState extends State<DocumentCapturePage> {
  final _number = TextEditingController();

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DocumentCaptureCubit cubit) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      helpText: 'Vence el',
      initialDate: cubit.state.expiresAt ?? now.add(const Duration(days: 365)),
      // Un documento ya vencido no sirve; se acepta desde hoy.
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 15)),
    );
    if (picked != null) cubit.setExpiresAt(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocumentCaptureCubit>();
    final type = cubit.state.docType;
    return BlocConsumer<DocumentCaptureCubit, DocumentCaptureState>(
      listenWhen: (a, b) => a.phase != b.phase && b.phase == CapturePhase.done,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${docTypeLabel(type)} enviado. Queda en revisión.')));
        context.pop();
      },
      builder: (context, state) {
        final sending = state.phase != CapturePhase.editing;
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(docTypeLabel(type))),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.rejectReason != null)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: ListTile(
                    leading: Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                    title: const Text('Lo rechazamos la vez anterior'),
                    subtitle: Text(widget.rejectReason!),
                  ),
                ),
              const Text('Toma la foto sobre una superficie oscura, con buena luz y sin reflejos. Que se lea todo.'),
              const SizedBox(height: 12),
              for (final side in type.sides)
                _PhotoSlot(
                  side: side,
                  title: type.hasBack ? (side == DocSide.front ? 'Frente' : 'Reverso') : 'Foto del documento',
                  photo: state.photos[side],
                  enabled: !sending,
                ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('capture.number'),
                controller: _number,
                enabled: !sending,
                decoration: InputDecoration(labelText: _numberLabel(type)),
              ),
              if (type.expires) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('capture.expiry'),
                  onPressed: sending ? null : () => _pickDate(cubit),
                  icon: const Icon(Icons.event),
                  label: Text(
                    state.expiresAt == null ? 'Fecha de vencimiento' : 'Vence el ${formatDate(state.expiresAt!)}',
                  ),
                ),
              ],
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    state.error!,
                    key: const Key('capture.error'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('capture.submit'),
                onPressed: sending ? null : () => cubit.submit(number: _number.text),
                child: sending
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Flexible(child: Text(state.progress ?? 'Enviando…')),
                        ],
                      )
                    : const Text('Enviar'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.side, required this.title, required this.photo, required this.enabled});

  final DocSide side;
  final String title;
  final Uint8List? photo;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocumentCaptureCubit>();
    final bytes = photo;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(title: Text(title), trailing: bytes == null ? null : const Icon(Icons.check_circle)),
          AspectRatio(
            aspectRatio: 1.6,
            child: bytes == null
                ? ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.badge_outlined, size: 48),
                  )
                : Image.memory(
                    bytes,
                    key: Key('capture.preview.${side.name}'),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(child: Text('Vista previa no disponible')),
                  ),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                key: Key('capture.gallery.${side.name}'),
                onPressed: enabled ? () => cubit.pick(side, PhotoOrigin.gallery) : null,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
              TextButton.icon(
                key: Key('capture.camera.${side.name}'),
                onPressed: enabled ? () => cubit.pick(side, PhotoOrigin.camera) : null,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(bytes == null ? 'Tomar foto' : 'Repetir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
