import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

/// Máximo de contactos de emergencia (FR-016).
const maxEmergencyContacts = 3;

/// Normaliza un teléfono escrito por la persona a E.164. Un celular colombiano de 10 dígitos
/// recibe el prefijo +57. Devuelve null si no es válido.
String? normalizePhone(String input) {
  final digits = input.replaceAll(RegExp(r'[\s\-().]'), '');
  final e164 = RegExp(r'^\+[1-9][0-9]{6,14}$');
  if (e164.hasMatch(digits)) return digits;
  if (RegExp(r'^3[0-9]{9}$').hasMatch(digits)) return '+57$digits';
  return null;
}

@immutable
class SafetyState {
  const SafetyState({
    this.contacts = const [],
    this.hasPin = false,
    this.loading = true,
    this.saving = false,
    this.error,
    this.notice,
  });

  final List<EmergencyContact> contacts;
  final bool hasPin;
  final bool loading;
  final bool saving;
  final String? error;
  final String? notice;

  SafetyState copyWith({
    List<EmergencyContact>? contacts,
    bool? hasPin,
    bool? loading,
    bool? saving,
    String? error,
    String? notice,
  }) => SafetyState(
    contacts: contacts ?? this.contacts,
    hasPin: hasPin ?? this.hasPin,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    error: error,
    notice: notice,
  );
}

/// Contactos de emergencia y PIN de seguridad (US4).
class SafetyCubit extends Cubit<SafetyState> {
  SafetyCubit(this._api) : super(const SafetyState());

  final SafetyApi _api;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final (contacts, hasPin) = await (_api.emergencyContacts(), _api.hasSafetyPin()).wait;
      emit(SafetyState(contacts: contacts, hasPin: hasPin, loading: false));
    } on Object {
      emit(state.copyWith(loading: false, error: 'No pudimos cargar tu perfil de seguridad. Desliza para reintentar.'));
    }
  }

  Future<bool> addContact(String name, String phone) async {
    final normalized = normalizePhone(phone);
    if (name.trim().length < 2 || normalized == null) {
      emit(state.copyWith(error: 'Escribe un nombre y un celular válido (por ejemplo 300 123 4567).'));
      return false;
    }
    if (state.contacts.length >= maxEmergencyContacts) {
      emit(state.copyWith(error: 'Puedes registrar hasta $maxEmergencyContacts contactos.'));
      return false;
    }
    return _save([...state.contacts, EmergencyContact(name: name.trim(), phoneE164: normalized)]);
  }

  Future<bool> removeContact(EmergencyContact contact) => _save([
    for (final c in state.contacts)
      if (c != contact) c,
  ]);

  Future<bool> _save(List<EmergencyContact> contacts) async {
    emit(state.copyWith(saving: true));
    try {
      final saved = await _api.setEmergencyContacts(contacts);
      emit(state.copyWith(contacts: saved, saving: false, notice: 'Contactos guardados'));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(saving: false, error: _message(e)));
      return false;
    }
  }

  /// Fija o cambia el PIN. Cambiarlo pide el actual.
  Future<bool> setPin(String pin, {String? current}) async {
    if (!RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
      emit(state.copyWith(error: 'El PIN debe tener 4 dígitos.'));
      return false;
    }
    emit(state.copyWith(saving: true));
    try {
      await _api.setSafetyPin(pin, currentPin: current);
      emit(state.copyWith(hasPin: true, saving: false, notice: 'PIN guardado'));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(saving: false, error: _message(e)));
      return false;
    }
  }

  static String _message(ApiException e) => switch (e.code) {
    'invalid_contact' => 'Revisa el nombre y el teléfono de cada contacto.',
    'too_many_contacts' => 'Puedes registrar hasta $maxEmergencyContacts contactos.',
    'wrong_current_pin' => 'El PIN actual no coincide.',
    'sos_active' => 'No puedes cambiar el PIN con una alerta abierta.',
    'invalid_pin_format' => 'El PIN debe tener 4 dígitos.',
    'network' => 'Sin conexión. Inténtalo de nuevo.',
    _ => e.message,
  };
}

/// Pantalla "Seguridad": hasta 3 contactos de emergencia, que reciben un SMS con el viaje en vivo
/// al activar el SOS, y el PIN que cancela una alerta (US4). Se abre desde ambas apps.
class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  Future<void> _addContact(BuildContext context) async {
    final cubit = context.read<SafetyCubit>();
    final result = await showDialog<(String, String)>(context: context, builder: (_) => const _ContactDialog());
    if (result != null) await cubit.addContact(result.$1, result.$2);
  }

  Future<void> _setPin(BuildContext context, bool hasPin) async {
    final cubit = context.read<SafetyCubit>();
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (_) => _PinDialog(askCurrent: hasPin),
    );
    if (result != null) await cubit.setPin(result.$1, current: result.$2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: BlocConsumer<SafetyCubit, SafetyState>(
        listenWhen: (a, b) => (b.error != null && b.error != a.error) || (b.notice != null && b.notice != a.notice),
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error ?? state.notice!))),
        builder: (context, state) {
          if (state.loading && state.contacts.isEmpty) return const Center(child: CircularProgressIndicator());
          final theme = Theme.of(context);
          return RefreshIndicator(
            onRefresh: context.read<SafetyCubit>().load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Contactos de emergencia', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  'Si activas el SOS durante un viaje, les enviamos un SMS con tu nombre y el enlace para seguir '
                  'el viaje en vivo.',
                ),
                const SizedBox(height: 8),
                for (final c in state.contacts)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.contact_phone),
                      title: Text(c.name),
                      subtitle: Text(c.phoneE164),
                      trailing: IconButton(
                        tooltip: 'Quitar',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: state.saving ? null : () => context.read<SafetyCubit>().removeContact(c),
                      ),
                    ),
                  ),
                if (state.contacts.length < maxEmergencyContacts)
                  OutlinedButton.icon(
                    key: const Key('safety.addContact'),
                    icon: const Icon(Icons.person_add_alt),
                    label: Text('Añadir contacto (${state.contacts.length}/$maxEmergencyContacts)'),
                    onPressed: state.saving ? null : () => _addContact(context),
                  ),
                const Divider(height: 32),
                Text('PIN de seguridad', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  state.hasPin
                      ? 'Tienes un PIN. Solo con él se cancela una alerta SOS; sin él la alerta sigue abierta.'
                      : 'Aún no tienes PIN. Sin PIN no puedes cancelar una alerta: solo el operador la cierra.',
                  key: const Key('safety.pinStatus'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('safety.setPin'),
                  onPressed: state.saving ? null : () => _setPin(context, state.hasPin),
                  child: Text(state.hasPin ? 'Cambiar PIN' : 'Configurar PIN'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog();

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _name.text.trim().length >= 2 && normalizePhone(_phone.text) != null;
    return AlertDialog(
      title: const Text('Contacto de emergencia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('safety.contactName'),
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('safety.contactPhone'),
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Celular', hintText: '300 123 4567'),
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('safety.contactSave'),
          onPressed: valid ? () => Navigator.of(context).pop((_name.text, _phone.text)) : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.askCurrent});

  final bool askCurrent;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _current = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Widget _field(String key, String label, TextEditingController controller) => TextField(
    key: Key(key),
    controller: controller,
    obscureText: true,
    maxLength: 4,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
    onChanged: (_) => setState(() {}),
  );

  @override
  Widget build(BuildContext context) {
    final valid =
        _pin.text.length == 4 && _pin.text == _confirm.text && (!widget.askCurrent || _current.text.length == 4);
    return AlertDialog(
      title: Text(widget.askCurrent ? 'Cambiar PIN' : 'Configurar PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.askCurrent) _field('safety.pinCurrent', 'PIN actual', _current),
          _field('safety.pinNew', 'PIN nuevo (4 dígitos)', _pin),
          _field('safety.pinConfirm', 'Repite el PIN', _confirm),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('safety.pinSave'),
          onPressed: valid
              ? () => Navigator.of(context).pop((_pin.text, widget.askCurrent ? _current.text : null))
              : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Botón "Compartir viaje" (US3): pide el enlace en vivo y abre el menú del sistema con
/// [share] (WhatsApp, SMS u otra app).
class ShareTripButton extends StatefulWidget {
  const ShareTripButton({super.key, required this.api, required this.tripId, required this.share});

  final SafetyApi api;
  final String tripId;
  final Future<void> Function(String text) share;

  @override
  State<ShareTripButton> createState() => _ShareTripButtonState();
}

class _ShareTripButtonState extends State<ShareTripButton> {
  bool _busy = false;

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final link = await widget.api.shareTrip(widget.tripId);
      await widget.share('Sigue mi viaje en Kyq en vivo: ${link.url}');
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'share_unavailable' ? 'Solo puedes compartir un viaje aceptado y sin terminar.' : e.message,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('trip.share'),
      tooltip: 'Compartir viaje',
      icon: const Icon(Icons.share),
      onPressed: _busy ? null : _share,
    );
  }
}
