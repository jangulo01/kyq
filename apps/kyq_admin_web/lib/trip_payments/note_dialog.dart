import 'package:flutter/material.dart';

/// Pide un texto obligatorio (motivo, nota) antes de una acción auditada. null si se cancela.
Future<String?> showNoteDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String label,
  required String confirm,
  Key? fieldKey,
  Key? confirmKey,
}) => showDialog<String>(
  context: context,
  builder: (_) =>
      _NoteDialog(title: title, body: body, label: label, confirm: confirm, fieldKey: fieldKey, confirmKey: confirmKey),
);

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.title,
    required this.body,
    required this.label,
    required this.confirm,
    this.fieldKey,
    this.confirmKey,
  });

  final String title;
  final String body;
  final String label;
  final String confirm;
  final Key? fieldKey;
  final Key? confirmKey;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.body),
            const SizedBox(height: 12),
            TextField(
              key: widget.fieldKey,
              controller: _text,
              maxLength: 200,
              decoration: InputDecoration(labelText: widget.label),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: widget.confirmKey,
          onPressed: _text.text.trim().isEmpty ? null : () => Navigator.of(context).pop(_text.text.trim()),
          child: Text(widget.confirm),
        ),
      ],
    );
  }
}
