import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';

import 'radio_settings_page.dart';

/// Un CSV elegido por el administrador; null si cancela.
typedef CsvPicker = Future<({String name, String text})?> Function();

/// Selector del navegador para el CSV de la carga masiva.
Future<({String name, String text})?> pickCsvFile() async {
  final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['csv', 'txt']);
  if (files.isEmpty) return null;
  final bytes = await files.first.readAsBytes();
  return (name: files.first.name, text: utf8.decode(bytes, allowMalformed: true));
}

/// Estados de cada fila (FR-034).
const bulkStatusLabels = {
  'pending': 'Lista para enviar',
  'sent': 'Enviada',
  'failed': 'Fallida',
  'accepted': 'Aceptada',
  'already_member': 'Ya estaba',
  'expired': 'Vencida',
};

String _roleLabel(RadioRole? r) => switch (r) {
  RadioRole.owner => 'Dueño',
  RadioRole.moderator => 'Moderador',
  RadioRole.listener => 'Oyente',
  _ => 'Miembro',
};

@immutable
class BulkUploadsState {
  const BulkUploadsState({this.uploads = const [], this.loading = true, this.error});

  final List<RadioBulkUpload> uploads;
  final bool loading;
  final String? error;
}

/// Cargas masivas de invitaciones (US10, FR-033).
class BulkUploadsCubit extends Cubit<BulkUploadsState> {
  BulkUploadsCubit(this._api) : super(const BulkUploadsState());

  final KyqApiClient _api;

  Future<void> load() async {
    try {
      final list = await _api.radioBulkUploads();
      if (!isClosed) emit(BulkUploadsState(uploads: list, loading: false));
    } on ApiException catch (e) {
      if (!isClosed) emit(BulkUploadsState(uploads: state.uploads, loading: false, error: radioAdminError(e)));
    }
  }

  /// Sube y valida sin enviar; devuelve la carga para revisarla.
  Future<RadioBulkUploadDetail?> upload(String name, String csv) async {
    try {
      final d = await _api.uploadRadioBulk(name, csv);
      await load();
      return d;
    } on ApiException catch (e) {
      if (!isClosed) emit(BulkUploadsState(uploads: state.uploads, loading: false, error: radioAdminError(e)));
      return null;
    }
  }
}

class BulkUploadsPage extends StatelessWidget {
  const BulkUploadsPage({super.key, this.pick = pickCsvFile});

  final CsvPicker pick;

  Future<void> _upload(BuildContext context) async {
    final cubit = context.read<BulkUploadsCubit>();
    final file = await pick();
    if (file == null) return;
    final d = await cubit.upload(file.name, file.text);
    if (d != null && context.mounted) await context.push('/radio/bulk/${d.upload.id}');
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BulkUploadsCubit, BulkUploadsState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!))),
      builder: (context, s) => Scaffold(
        appBar: AppBar(title: const Text('Cargas masivas de Radio')),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('radio.bulk.upload'),
          onPressed: () => _upload(context),
          icon: const Icon(Icons.upload_file),
          label: const Text('Subir CSV'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
          children: [
            const Text(
              'Columnas: nombre, teléfono, tipo (conductor o pasajero), canal y rol (dueño, moderador, miembro u '
              'oyente). Hasta 2 000 filas. Un canal nuevo se crea con la fila de rol dueño, que debe usar ya '
              'Kyq Conductor. Nada se envía hasta que confirmas.',
            ),
            const SizedBox(height: 16),
            if (s.loading && s.uploads.isEmpty) const Center(child: CircularProgressIndicator()),
            if (!s.loading && s.uploads.isEmpty) const Text('Aún no hay cargas.'),
            for (final u in s.uploads)
              Card(
                child: ListTile(
                  key: Key('radio.bulk.${u.id}'),
                  leading: const Icon(Icons.description_outlined),
                  title: Text(u.fileName),
                  subtitle: Text(
                    '${u.rowsTotal} filas · '
                    '${[for (final e in u.counts.entries) '${bulkStatusLabels[e.key] ?? e.key}: ${e.value}'].join(' · ')}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.push('/radio/bulk/${u.id}');
                    if (context.mounted) await context.read<BulkUploadsCubit>().load();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

@immutable
class BulkDetailState {
  const BulkDetailState({this.detail, this.loading = true, this.sending = false, this.error, this.notice});

  final RadioBulkUploadDetail? detail;
  final bool loading;
  final bool sending;
  final String? error;
  final String? notice;
}

class BulkDetailCubit extends Cubit<BulkDetailState> {
  BulkDetailCubit(this._api, this.id) : super(const BulkDetailState());

  final KyqApiClient _api;
  final String id;

  Future<void> load() async {
    try {
      final d = await _api.radioBulkUpload(id);
      if (!isClosed) emit(BulkDetailState(detail: d, loading: false));
    } on ApiException catch (e) {
      if (!isClosed) emit(BulkDetailState(detail: state.detail, loading: false, error: radioAdminError(e)));
    }
  }

  /// Confirma y envía; con [onlyFailed] reenvía las fallidas (FR-034).
  Future<void> send({bool onlyFailed = false}) async {
    emit(BulkDetailState(detail: state.detail, loading: false, sending: true));
    try {
      await _api.sendRadioBulk(id, onlyFailed: onlyFailed);
      final d = await _api.radioBulkUpload(id);
      if (!isClosed) {
        emit(
          BulkDetailState(
            detail: d,
            loading: false,
            notice: onlyFailed ? 'Reenviando las fallidas.' : 'Envío en curso: 20 SMS por segundo.',
          ),
        );
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(BulkDetailState(detail: state.detail, loading: false, error: radioAdminError(e)));
    }
  }
}

class BulkDetailPage extends StatelessWidget {
  const BulkDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BulkDetailCubit, BulkDetailState>(
      listenWhen: (a, b) => (b.error != null && a.error != b.error) || (b.notice != null && a.notice != b.notice),
      listener: (context, s) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error ?? s.notice!))),
      builder: (context, s) {
        final cubit = context.read<BulkDetailCubit>();
        final d = s.detail;
        if (d == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Carga masiva')),
            body: Center(child: s.loading ? const CircularProgressIndicator() : Text(s.error ?? '')),
          );
        }
        final u = d.upload;
        final failed = u.counts['failed'] ?? 0;
        final pending = u.counts['pending'] ?? 0;
        final invalid = d.rows.where((r) => r.status == 'failed' && r.error != null).length;
        return Scaffold(
          appBar: AppBar(
            title: Text(u.fileName),
            actions: [IconButton(tooltip: 'Actualizar', onPressed: cubit.load, icon: const Icon(Icons.refresh))],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final e in u.counts.entries)
                    Chip(
                      key: Key('radio.bulk.count.${e.key}'),
                      label: Text('${bulkStatusLabels[e.key] ?? e.key}: ${e.value}'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (u.status == 'validated' && invalid > 0)
                Text(
                  '$invalid filas tienen errores y no se enviarán. Corrígelas en el archivo y súbelo de nuevo, '
                  'o confirma para enviar las demás.',
                  key: const Key('radio.bulk.errors'),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (u.status == 'validated')
                    FilledButton.icon(
                      key: const Key('radio.bulk.send'),
                      onPressed: s.sending || pending == 0 ? null : () => cubit.send(),
                      icon: const Icon(Icons.send),
                      label: Text('Confirmar y enviar $pending SMS'),
                    ),
                  if (u.status == 'done' && failed > 0)
                    OutlinedButton.icon(
                      key: const Key('radio.bulk.resend'),
                      onPressed: s.sending ? null : () => cubit.send(onlyFailed: true),
                      icon: const Icon(Icons.replay),
                      label: const Text('Reenviar las fallidas'),
                    ),
                  if (u.status == 'sending') const Text('Enviando…'),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Línea')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Teléfono')),
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Canal')),
                    DataColumn(label: Text('Rol')),
                    DataColumn(label: Text('Estado')),
                  ],
                  rows: [
                    for (final r in d.rows)
                      DataRow(
                        key: ValueKey('radio.bulk.row.${r.line}'),
                        cells: [
                          DataCell(Text('${r.line}')),
                          DataCell(Text(r.name)),
                          DataCell(Text(r.phoneMasked)),
                          DataCell(Text(r.kind == 'passenger' ? 'Pasajero' : 'Conductor')),
                          DataCell(Text(r.channel)),
                          DataCell(Text(_roleLabel(r.role))),
                          DataCell(
                            Text(
                              r.error == null
                                  ? bulkStatusLabels[r.status] ?? r.status
                                  : '${bulkStatusLabels[r.status] ?? r.status}: ${r.error}',
                              style: r.status == 'failed'
                                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
