import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';

@immutable
class RadioSettingsState {
  const RadioSettingsState({this.settings, this.loading = true, this.saving = false, this.error, this.saved = false});

  final RadioSettings? settings;
  final bool loading;
  final bool saving;
  final String? error;
  final bool saved;
}

String radioAdminError(ApiException e) => switch (e.code) {
  'invalid_radio_request' => 'Revisa los valores: la prueba dura de 1 a 90 días y la retención es 7, 30 o 90 días.',
  'bulk_too_large' => 'El archivo tiene más de 2 000 filas. Divídelo en varios.',
  'bulk_state' => 'Esa carga ya se está enviando o no tiene filas por enviar.',
  'network' => 'Sin conexión con el servidor.',
  _ => 'No se pudo completar la acción.',
};

/// Configuración de Radio (011, FR-040): acceso sin suscripción, pasajeros en canales y cuánto
/// tiempo se guardan los mensajes, con su costo estimado. Cada cambio queda en la bitácora.
class RadioSettingsCubit extends Cubit<RadioSettingsState> {
  RadioSettingsCubit(this._api) : super(const RadioSettingsState());

  final KyqApiClient _api;

  Future<void> load() async {
    try {
      final s = await _api.radioSettings();
      if (!isClosed) emit(RadioSettingsState(settings: s, loading: false));
    } on ApiException catch (e) {
      if (!isClosed) emit(RadioSettingsState(loading: false, error: radioAdminError(e)));
    }
  }

  Future<bool> save({
    required String trialPolicy,
    required int trialDays,
    required String passengersInChannels,
    required int retentionDays,
  }) async {
    emit(RadioSettingsState(settings: state.settings, loading: false, saving: true));
    try {
      final s = await _api.updateRadioSettings(
        trialPolicy: trialPolicy,
        trialDays: trialDays,
        passengersInChannels: passengersInChannels,
        retentionDays: retentionDays,
      );
      if (!isClosed) emit(RadioSettingsState(settings: s, loading: false, saved: true));
      return true;
    } on ApiException catch (e) {
      if (!isClosed) emit(RadioSettingsState(settings: state.settings, loading: false, error: radioAdminError(e)));
      return false;
    }
  }
}

String _money(int minor) {
  final s = minor.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '\$$b';
}

const _policies = {
  'trial': ('Prueba gratis', 'Quien no paga usa Radio completa durante los días de prueba desde su registro.'),
  'subscription_only': ('Solo con suscripción', 'Sin suscripción activa no entra a Radio.'),
  'listen_only': ('Solo escucha', 'Sin suscripción oye y lee, pero no transmite.'),
};

const _passengerOptions = {
  'none': 'No: los canales son solo de conductores',
  'listen_only': 'Solo escuchan',
  'all_roles': 'Con cualquier rol que el dueño permita',
};

class RadioSettingsPage extends StatefulWidget {
  const RadioSettingsPage({super.key});

  @override
  State<RadioSettingsPage> createState() => _RadioSettingsPageState();
}

class _RadioSettingsPageState extends State<RadioSettingsPage> {
  String? _policy;
  String? _passengers;
  int? _retention;
  final _days = TextEditingController();

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  void _fill(RadioSettings s) {
    _policy = s.trialPolicy;
    _passengers = s.passengersInChannels;
    _retention = s.retentionDays;
    _days.text = '${s.trialDays}';
  }

  Future<void> _save(RadioSettings current) async {
    final days = int.tryParse(_days.text.trim());
    if (days == null || days < 1 || days > 90) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La prueba dura de 1 a 90 días.')));
      return;
    }
    final retention = _retention ?? current.retentionDays;
    if (retention != current.retentionDays) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cambiar la retención'),
          content: Text(
            'Los mensajes se guardarán $retention días. Todos verán de nuevo el aviso de registro y '
            'deberán aceptarlo para hablar.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              key: const Key('radio.settings.confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await context.read<RadioSettingsCubit>().save(
      trialPolicy: _policy ?? current.trialPolicy,
      trialDays: days,
      passengersInChannels: _passengers ?? current.passengersInChannels,
      retentionDays: retention,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RadioSettingsCubit, RadioSettingsState>(
      listenWhen: (a, b) => a.settings != b.settings || (b.saved && !a.saved) || b.error != a.error,
      listener: (context, s) {
        if (s.settings != null && (_policy == null || s.saved)) setState(() => _fill(s.settings!));
        final messenger = ScaffoldMessenger.of(context);
        if (s.saved) messenger.showSnackBar(const SnackBar(content: Text('Configuración guardada.')));
        if (s.error != null) messenger.showSnackBar(SnackBar(content: Text(s.error!)));
      },
      builder: (context, s) {
        final st = s.settings;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Configuración de Radio'),
            actions: [
              TextButton.icon(
                key: const Key('radio.bulk.open'),
                onPressed: () => context.push('/radio/bulk'),
                icon: const Icon(Icons.upload_file),
                label: const Text('Cargas masivas'),
              ),
            ],
          ),
          body: st == null
              ? Center(child: s.loading ? const CircularProgressIndicator() : Text(s.error ?? ''))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('Conductores sin suscripción', style: Theme.of(context).textTheme.titleMedium),
                    RadioGroup<String>(
                      groupValue: _policy ?? st.trialPolicy,
                      onChanged: (v) => setState(() => _policy = v),
                      child: Column(
                        children: [
                          for (final e in _policies.entries)
                            RadioListTile<String>(
                              key: Key('radio.policy.${e.key}'),
                              value: e.key,
                              title: Text(e.value.$1),
                              subtitle: Text(e.value.$2),
                            ),
                        ],
                      ),
                    ),
                    if ((_policy ?? st.trialPolicy) == 'trial')
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 16),
                        child: SizedBox(
                          width: 200,
                          child: TextField(
                            key: const Key('radio.trialDays'),
                            controller: _days,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Días de prueba', suffixText: 'días'),
                          ),
                        ),
                      ),
                    const Divider(height: 32),
                    Text('Pasajeros en canales', style: Theme.of(context).textTheme.titleMedium),
                    RadioGroup<String>(
                      groupValue: _passengers ?? st.passengersInChannels,
                      onChanged: (v) => setState(() => _passengers = v),
                      child: Column(
                        children: [
                          for (final e in _passengerOptions.entries)
                            RadioListTile<String>(
                              key: Key('radio.passengers.${e.key}'),
                              value: e.key,
                              title: Text(e.value),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    Text('Cuánto tiempo se guardan los mensajes', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final d in const [7, 30, 90])
                          ChoiceChip(
                            key: Key('radio.retention.$d'),
                            selected: (_retention ?? st.retentionDays) == d,
                            onSelected: (_) => setState(() => _retention = d),
                            label: Text('$d días · ${_money(st.estimatedMonthlyCostMinor['$d'] ?? 0)} al mes'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Costo estimado del almacenamiento con lo que Radio guardó en los últimos 30 días. '
                      'Los mensajes que cada usuario guarda se conservan aparte.',
                    ),
                    const SizedBox(height: 24),
                    if (st.updatedAt case final at?)
                      Text(
                        'Último cambio: ${at.toLocal().toString().substring(0, 16)}'
                        '${st.updatedByName.isEmpty ? '' : ' por ${st.updatedByName}'}',
                        key: const Key('radio.settings.updated'),
                      ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        key: const Key('radio.settings.save'),
                        onPressed: s.saving ? null : () => _save(st),
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
