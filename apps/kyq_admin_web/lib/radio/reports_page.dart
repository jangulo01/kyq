import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'radio_settings_page.dart';

/// Reproduce el audio de un mensaje reportado; las pruebas pasan uno falso.
abstract interface class ReportPlayer {
  Future<void> play(String url);

  Future<void> stop();
}

class AudioplayersReportPlayer implements ReportPlayer {
  AudioPlayer? _player;

  @override
  Future<void> play(String url) async {
    final p = _player ??= AudioPlayer();
    await p.stop();
    await p.play(UrlSource(url));
  }

  @override
  Future<void> stop() async => _player?.stop();
}

const _kindLabels = {
  'voice': 'Mensaje de voz',
  'text': 'Texto',
  'photo': 'Foto',
  'location': 'Ubicación',
  'alert': 'Alerta de llamada',
  'emergency': 'Emergencia',
};

const _decisions = {
  'dismissed': ('Descartar', 'No incumple las reglas.'),
  'message_deleted': ('Borrar el mensaje', 'Se borra para todos con su audio o foto.'),
  'channel_suspended': ('Suspender el canal', 'Nadie habla en el canal hasta reactivarlo.'),
  'user_suspended': ('Suspender al autor', 'Su cuenta queda suspendida como en Usuarios.'),
};

@immutable
class RadioReportsState {
  const RadioReportsState({this.reports = const [], this.loading = true, this.error});

  final List<RadioReport> reports;
  final bool loading;
  final String? error;
}

/// Cola de reportes de Radio (011, FR-036): solo de qué se trata; el contenido se ve al abrir.
class RadioReportsCubit extends Cubit<RadioReportsState> {
  RadioReportsCubit(this._api) : super(const RadioReportsState());

  final KyqApiClient _api;

  Future<void> load() async {
    try {
      final list = await _api.radioReports();
      if (!isClosed) emit(RadioReportsState(reports: list, loading: false));
    } on ApiException catch (e) {
      if (!isClosed) emit(RadioReportsState(reports: state.reports, loading: false, error: radioAdminError(e)));
    }
  }
}

class RadioReportsPage extends StatelessWidget {
  const RadioReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RadioReportsCubit, RadioReportsState>(
      builder: (context, s) => Scaffold(
        appBar: AppBar(title: const Text('Reportes de Radio')),
        body: RefreshIndicator(
          onRefresh: context.read<RadioReportsCubit>().load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Solo se ve el mensaje reportado y cada apertura queda registrada con tu nombre y la hora.'),
              const SizedBox(height: 12),
              if (s.loading && s.reports.isEmpty) const Center(child: CircularProgressIndicator()),
              if (s.error != null) Text(s.error!),
              if (!s.loading && s.reports.isEmpty) const Text('No hay reportes pendientes.'),
              for (final r in s.reports)
                Card(
                  child: ListTile(
                    key: Key('radio.report.${r.id}'),
                    leading: const Icon(Icons.flag_outlined),
                    title: Text('${_kindLabels[r.messageKind] ?? r.messageKind} · ${r.conversationTitle}'),
                    subtitle: Text([formatDate(r.createdAt), if (r.reason.isNotEmpty) '"${r.reason}"'].join(' · ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await context.push('/radio/reports/${r.id}');
                      if (context.mounted) await context.read<RadioReportsCubit>().load();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class RadioReportState {
  const RadioReportState({this.detail, this.loading = true, this.error, this.resolved = false});

  final RadioReportDetail? detail;
  final bool loading;
  final String? error;
  final bool resolved;
}

class RadioReportCubit extends Cubit<RadioReportState> {
  RadioReportCubit(this._api, this.id) : super(const RadioReportState());

  final KyqApiClient _api;
  final String id;

  /// Abrir es el acceso que el backend registra (FR-037).
  Future<void> load() async {
    try {
      final d = await _api.radioReport(id);
      if (!isClosed) emit(RadioReportState(detail: d, loading: false));
    } on ApiException catch (e) {
      if (!isClosed) emit(RadioReportState(loading: false, error: radioAdminError(e)));
    }
  }

  Future<void> resolve(String decision, String note) async {
    try {
      await _api.resolveRadioReport(id, decision, note: note.trim().isEmpty ? null : note.trim());
      if (!isClosed) emit(RadioReportState(detail: state.detail, loading: false, resolved: true));
    } on ApiException catch (e) {
      final msg = e.code == 'not_channel' ? 'El mensaje no es de un canal de grupo.' : radioAdminError(e);
      if (!isClosed) emit(RadioReportState(detail: state.detail, loading: false, error: msg));
    }
  }
}

class RadioReportPage extends StatefulWidget {
  const RadioReportPage({super.key, required this.player});

  final ReportPlayer player;

  @override
  State<RadioReportPage> createState() => _RadioReportPageState();
}

class _RadioReportPageState extends State<RadioReportPage> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    widget.player.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RadioReportCubit, RadioReportState>(
      listenWhen: (a, b) => b.resolved != a.resolved || (b.error != null && b.error != a.error),
      listener: (context, s) {
        if (s.resolved) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte resuelto.')));
          context.pop();
        } else if (s.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!)));
        }
      },
      builder: (context, s) {
        final d = s.detail;
        if (d == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Reporte')),
            body: Center(child: s.loading ? const CircularProgressIndicator() : Text(s.error ?? '')),
          );
        }
        final m = d.message;
        final media = d.mediaUrl;
        return Scaffold(
          appBar: AppBar(title: Text('${_kindLabels[m.kind.name] ?? m.kind.name} reportado')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('En ${d.report.conversationTitle}', style: Theme.of(context).textTheme.titleMedium),
              Text('De ${d.authorName} · ${formatDate(m.createdAt)}', key: const Key('radio.report.author')),
              if (d.report.reason.isNotEmpty) Text('Motivo: "${d.report.reason}"'),
              const Divider(height: 32),
              if (m.body case final body? when body.isNotEmpty)
                Text(body, key: const Key('radio.report.body'), style: Theme.of(context).textTheme.bodyLarge),
              if (m.lat != null) Text('Ubicación: ${m.lat!.toStringAsFixed(5)}, ${m.lng!.toStringAsFixed(5)}'),
              if (media != null && m.kind == RadioMessageKind.voice)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    key: const Key('radio.report.play'),
                    onPressed: () => widget.player.play(media),
                    icon: const Icon(Icons.play_arrow),
                    label: Text('Escuchar (${((m.durationMs ?? 0) / 1000).toStringAsFixed(1)} s)'),
                  ),
                ),
              if (media != null && m.kind == RadioMessageKind.photo)
                Image.network(media, key: const Key('radio.report.photo'), height: 320, fit: BoxFit.contain),
              if (media == null && (m.kind == RadioMessageKind.voice || m.kind == RadioMessageKind.photo))
                const Text('El archivo ya no existe (venció o se borró).'),
              const Divider(height: 32),
              TextField(
                key: const Key('radio.report.note'),
                controller: _note,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
              for (final e in _decisions.entries)
                ListTile(
                  key: Key('radio.report.decide.${e.key}'),
                  title: Text(e.value.$1),
                  subtitle: Text(e.value.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.read<RadioReportCubit>().resolve(e.key, _note.text),
                ),
            ],
          ),
        );
      },
    );
  }
}
