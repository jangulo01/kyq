import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

/// Ciudad del piloto; coincide con KYQ_CITY_CODE del backend.
const cityCode = String.fromEnvironment('KYQ_CITY_CODE', defaultValue: 'bogota');

/// Tabla de tarifas de la ciudad (FR-010b). Los importes se escriben en pesos y se envían en
/// unidades mínimas (×100).
class FareTablePage extends StatefulWidget {
  const FareTablePage({super.key});

  @override
  State<FareTablePage> createState() => _FareTablePageState();
}

class _FareTablePageState extends State<FareTablePage> {
  final _form = GlobalKey<FormState>();
  final _fields = {
    'base': TextEditingController(text: '4000'),
    'km': TextEditingController(text: '1200'),
    'minute': TextEditingController(text: '300'),
    'minimum': TextEditingController(text: '7000'),
    'rounding': TextEditingController(text: '100'),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _minor(String key) => int.parse(_fields[key]!.text) * 100;

  /// Ejemplo de 5 km y 15 min con la tabla escrita, para que el admin vea el efecto.
  String _example() {
    try {
      final raw = _minor('base') + _minor('km') * 5 + _minor('minute') * 15;
      final fare = raw < _minor('minimum') ? _minor('minimum') : raw;
      final r = _minor('rounding');
      return formatMoney((fare + r ~/ 2) ~/ r * r, 'COP');
    } on Object {
      return '—';
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<KyqApiClient>().adminSetFareTable(
        cityCode,
        FareTableInput(
          currency: 'COP',
          baseMinor: _minor('base'),
          perKmMinor: _minor('km'),
          perMinuteMinor: _minor('minute'),
          minimumMinor: _minor('minimum'),
          roundingMinor: _minor('rounding'),
        ),
      );
      messenger.showSnackBar(const SnackBar(content: Text('Tabla de tarifas guardada.')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo guardar: ${e.message}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String key, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: Key('fares.$key'),
        controller: _fields[key],
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label, prefixText: '\$ '),
        onChanged: (_) => setState(() {}),
        validator: (v) {
          final n = int.tryParse(v ?? '');
          if (n == null) return 'Obligatorio';
          if (key == 'rounding' && n < 1) return 'Mínimo 1';
          return null;
        },
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text('Tarifas · $cityCode')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                field('base', 'Tarifa base'),
                field('km', 'Por kilómetro'),
                field('minute', 'Por minuto'),
                field('minimum', 'Tarifa mínima'),
                field('rounding', 'Redondear a múltiplos de'),
                Text('Ejemplo, 5 km y 15 min: ${_example()}', key: const Key('fares.example')),
                const SizedBox(height: 24),
                FilledButton(onPressed: _saving ? null : _save, child: const Text('Guardar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
