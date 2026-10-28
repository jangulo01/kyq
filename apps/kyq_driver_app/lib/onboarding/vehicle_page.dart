import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'onboarding_cubit.dart';

/// Placa colombiana de vehículo particular o de servicio: tres letras y tres caracteres
/// (`ABC123`, `ABC12D`), como valida el backend.
final plateRegExp = RegExp(r'^[A-Z]{3}[0-9]{2}[0-9A-Z]$');

/// Datos del vehículo, obligatorios antes de enviar documentos (FR-002).
class VehiclePage extends StatefulWidget {
  const VehiclePage({super.key});

  @override
  State<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  final _form = GlobalKey<FormState>();
  late final Vehicle? _initial = context.read<OnboardingCubit>().state.onboarding?.vehicle;
  late final _plate = TextEditingController(text: _initial?.plate ?? '');
  late final _brand = TextEditingController(text: _initial?.brand ?? '');
  late final _model = TextEditingController(text: _initial?.model ?? '');
  late final _color = TextEditingController(text: _initial?.color ?? '');
  late final _year = TextEditingController(text: _initial?.year?.toString() ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_plate, _brand, _model, _color, _year]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final onboarding = context.read<OnboardingCubit>();
    try {
      await context.read<KyqApiClient>().setVehicle(
        plate: _plate.text.trim().toUpperCase(),
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        color: _color.text.trim(),
        year: int.parse(_year.text),
      );
      await onboarding.load();
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/onboarding/documents');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.code == 'network'
              ? 'Sin conexión. Revisa tu internet.'
              : (e.message.isEmpty ? 'Revisa los datos del vehículo.' : e.message);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxYear = DateTime.now().year + 1;
    String? required(String? v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu vehículo'),
        actions: [
          if (!context.canPop())
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthCubit>().signOut(),
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Con estos datos tus pasajeros reconocen tu carro. Después te pediremos tus documentos.'),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('vehicle.plate'),
              controller: _plate,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                TextInputFormatter.withFunction((_, v) => v.copyWith(text: v.text.toUpperCase())),
              ],
              decoration: const InputDecoration(labelText: 'Placa', hintText: 'ABC123', counterText: ''),
              validator: (v) => plateRegExp.hasMatch(v?.trim() ?? '') ? null : 'Escribe la placa así: ABC123',
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('vehicle.brand'),
              controller: _brand,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Marca', hintText: 'Chevrolet'),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('vehicle.model'),
              controller: _model,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Modelo', hintText: 'Spark GT'),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('vehicle.color'),
              controller: _color,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Color'),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('vehicle.year'),
              controller: _year,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Año', counterText: ''),
              validator: (v) {
                final y = int.tryParse(v ?? '');
                return y == null || y < 1990 || y > maxYear ? 'Entre 1990 y $maxYear' : null;
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('vehicle.save'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar y seguir'),
            ),
          ],
        ),
      ),
    );
  }
}
