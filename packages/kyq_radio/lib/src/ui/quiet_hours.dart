import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import '../controller/radio_cubit.dart';
import '../deps.dart';

const _dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const _dayLong = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

/// "Lunes a viernes", "Sábado y domingo" o la lista de días.
String quietDaysText(List<int> days) {
  final d = [...days]..sort();
  String cap(String s) => s[0].toUpperCase() + s.substring(1);
  if (d.length == 7) return 'Todos los días';
  if (d.join() == '12345') return 'Lunes a viernes';
  if (d.join() == '67') return 'Sábado y domingo';
  final names = [for (final x in d) _dayLong[x - 1]];
  if (names.length == 1) return cap(names.first);
  return cap('${names.sublist(0, names.length - 1).join(', ')} y ${names.last}');
}

/// Horarios de silencio (FR-021): a la hora indicada la radio pasa sola a Ocupado y al terminar
/// vuelve al estado que tenía.
class QuietHoursSection extends StatefulWidget {
  const QuietHoursSection({super.key});

  @override
  State<QuietHoursSection> createState() => _QuietHoursSectionState();
}

class _QuietHoursSectionState extends State<QuietHoursSection> {
  List<RadioQuietHours>? _rules;

  RadioApi get _api => context.read<RadioDeps>().api;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rules = await _api.radioQuietHours();
      if (mounted) setState(() => _rules = rules);
    } on ApiException {
      if (mounted) setState(() => _rules = const []);
    }
  }

  Future<void> _save(List<RadioQuietHours> rules) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.setRadioQuietHours(rules);
      if (mounted) setState(() => _rules = rules);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(radioErrorText(e))));
    }
  }

  Future<void> _edit([int? index]) async {
    final rules = _rules ?? const [];
    final current = index == null
        ? const RadioQuietHours(weekdays: [1, 2, 3, 4, 5], starts: '22:00', ends: '06:00')
        : rules[index];
    final rule = await showDialog<RadioQuietHours>(
      context: context,
      builder: (_) => _QuietHoursDialog(initial: current),
    );
    if (rule == null) return;
    final next = [...rules];
    if (index == null) {
      next.add(rule);
    } else {
      next[index] = rule;
    }
    await _save(next);
  }

  @override
  Widget build(BuildContext context) {
    final rules = _rules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text('Horarios de silencio', style: Theme.of(context).textTheme.titleSmall),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Pasas a Ocupado sola la radio y vuelves a tu estado al terminar. Las alertas sí suenan.'),
        ),
        if (rules == null) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
        for (final (i, r) in (rules ?? const <RadioQuietHours>[]).indexed)
          ListTile(
            key: Key('radio.quiet.$i'),
            leading: const Icon(Icons.bedtime_outlined),
            title: Text('${r.starts} a ${r.ends}'),
            subtitle: Text(quietDaysText(r.weekdays)),
            onTap: () => _edit(i),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  key: Key('radio.quiet.enabled.$i'),
                  value: r.enabled,
                  onChanged: (v) => _save([...rules!]..[i] = r.copyWith(enabled: v)),
                ),
                IconButton(
                  key: Key('radio.quiet.delete.$i'),
                  tooltip: 'Quitar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _save([...rules!]..removeAt(i)),
                ),
              ],
            ),
          ),
        if (rules != null && rules.length < 10)
          ListTile(
            key: const Key('radio.quiet.add'),
            leading: const Icon(Icons.add),
            title: const Text('Agregar horario'),
            onTap: _edit,
          ),
      ],
    );
  }
}

class _QuietHoursDialog extends StatefulWidget {
  const _QuietHoursDialog({required this.initial});

  final RadioQuietHours initial;

  @override
  State<_QuietHoursDialog> createState() => _QuietHoursDialogState();
}

class _QuietHoursDialogState extends State<_QuietHoursDialog> {
  late Set<int> _days = widget.initial.weekdays.toSet();
  late String _starts = widget.initial.starts;
  late String _ends = widget.initial.ends;

  TimeOfDay _parse(String v) {
    final p = v.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool start) async {
    final t = await showTimePicker(context: context, initialTime: _parse(start ? _starts : _ends));
    if (t == null) return;
    setState(() => start ? _starts = _fmt(t) : _ends = _fmt(t));
  }

  @override
  Widget build(BuildContext context) {
    final valid = _days.isNotEmpty && _starts != _ends;
    return AlertDialog(
      title: const Text('Horario de silencio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  key: Key('radio.quiet.day.$d'),
                  label: Text(_dayNames[d - 1]),
                  tooltip: _dayLong[d - 1],
                  selected: _days.contains(d),
                  onSelected: (on) => setState(() => _days = on ? ({..._days, d}) : ({..._days}..remove(d))),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            key: const Key('radio.quiet.starts'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Desde'),
            trailing: Text(_starts, style: Theme.of(context).textTheme.titleMedium),
            onTap: () => _pick(true),
          ),
          ListTile(
            key: const Key('radio.quiet.ends'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Hasta'),
            trailing: Text(_ends, style: Theme.of(context).textTheme.titleMedium),
            onTap: () => _pick(false),
          ),
          if (_starts.compareTo(_ends) > 0) const Text('Termina al día siguiente.', key: Key('radio.quiet.overnight')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('radio.quiet.save'),
          onPressed: valid
              ? () => Navigator.pop(
                  context,
                  widget.initial.copyWith(weekdays: [..._days]..sort(), starts: _starts, ends: _ends),
                )
              : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
