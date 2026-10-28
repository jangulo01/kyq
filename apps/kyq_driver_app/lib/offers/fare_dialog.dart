import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pide una tarifa en pesos. Devuelve null si se cancela.
Future<int?> askFareInPesos(BuildContext context, {required String title}) {
  return showDialog<int>(
    context: context,
    builder: (context) => _FareDialog(title: title),
  );
}

class _FareDialog extends StatefulWidget {
  const _FareDialog({required this.title});

  final String title;

  @override
  State<_FareDialog> createState() => _FareDialogState();
}

class _FareDialogState extends State<_FareDialog> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final pesos = int.tryParse(_amount.text);
    if (pesos == null || pesos <= 0) return;
    Navigator.of(context).pop(pesos);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('fare.input'),
        controller: _amount,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'Tarifa en pesos', prefixText: '\$ '),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(key: const Key('fare.submit'), onPressed: _submit, child: const Text('Enviar')),
      ],
    );
  }
}
