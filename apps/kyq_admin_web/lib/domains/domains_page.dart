import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

@immutable
class DomainsState {
  const DomainsState({this.listing, this.loading = true, this.error});

  final MirrorDomainListing? listing;
  final bool loading;
  final String? error;
}

String _domainError(ApiException e) => switch (e.code) {
  'invalid_url' => 'La API debe ser https://dominio (sin ruta) y el tiempo real wss://dominio/….',
  'duplicate_domain' => 'Ese dominio ya está en la lista.',
  'last_active_domain' => 'Debe quedar al menos un dominio activo.',
  'domain_not_found' => 'El dominio ya no existe.',
  'network' => 'Sin conexión con el servidor.',
  _ => 'No se pudo guardar el cambio.',
};

/// Dominios espejo (009, US5): alta, orden, activar y desactivar en caliente, con su estado.
class DomainsCubit extends Cubit<DomainsState> {
  DomainsCubit(this._api) : super(const DomainsState());

  final KyqApiClient _api;

  Future<void> load() => _run(_api.mirrorDomains);

  Future<bool> add(String apiUrl, String realtimeUrl) => _run(() async {
    await _api.createMirrorDomain(apiUrl: apiUrl.trim(), realtimeUrl: realtimeUrl.trim());
    return _api.mirrorDomains();
  });

  Future<bool> setActive(MirrorDomain d, bool active) => _run(() async {
    await _api.updateMirrorDomain(d.id, apiUrl: d.apiUrl, realtimeUrl: d.realtimeUrl, active: active);
    return _api.mirrorDomains();
  });

  Future<bool> remove(MirrorDomain d) => _run(() async {
    await _api.deleteMirrorDomain(d.id);
    return _api.mirrorDomains();
  });

  /// Sube (delta -1) o baja (delta +1) un dominio en la lista.
  Future<bool> move(MirrorDomain d, int delta) {
    final ids = [for (final x in state.listing?.domains ?? const <MirrorDomain>[]) x.id];
    final i = ids.indexOf(d.id);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= ids.length) return Future.value(false);
    ids
      ..removeAt(i)
      ..insert(j, d.id);
    return _run(() => _api.reorderMirrorDomains(ids));
  }

  Future<bool> _run(Future<MirrorDomainListing> Function() action) async {
    emit(DomainsState(listing: state.listing));
    try {
      final listing = await action();
      if (!isClosed) emit(DomainsState(listing: listing, loading: false));
      return true;
    } on ApiException catch (e) {
      if (!isClosed) emit(DomainsState(listing: state.listing, loading: false, error: _domainError(e)));
      return false;
    }
  }
}

/// Página de dominios espejo: estado y latencia de cada uno al abrirla (FR-019).
class DomainsPage extends StatelessWidget {
  const DomainsPage({super.key});

  Future<void> _add(BuildContext context) async {
    final api = TextEditingController(text: 'https://');
    final rt = TextEditingController(text: 'wss://');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo dominio espejo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('domains.api'),
              controller: api,
              decoration: const InputDecoration(labelText: 'API'),
            ),
            TextField(
              key: const Key('domains.realtime'),
              controller: rt,
              decoration: const InputDecoration(
                labelText: 'Tiempo real',
                helperText: 'wss://dominio/connection/websocket',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            key: const Key('domains.save'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) await context.read<DomainsCubit>().add(api.text, rt.text);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DomainsCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dominios espejo'),
        actions: [IconButton(tooltip: 'Comprobar ahora', icon: const Icon(Icons.refresh), onPressed: cubit.load)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('domains.add'),
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('Añadir dominio'),
      ),
      body: BlocConsumer<DomainsCubit, DomainsState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!))),
        builder: (context, state) {
          final l = state.listing;
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (state.loading) const LinearProgressIndicator(),
              if (l != null && !l.signingConfigured)
                Card(
                  key: const Key('domains.unsigned'),
                  color: scheme.errorContainer,
                  child: const ListTile(
                    leading: Icon(Icons.key_off),
                    title: Text('Sin clave de firma'),
                    subtitle: Text(
                      'Las apps no reciben la lista hasta configurar KYQ_DOMAINS_SIGNING_KEY en el backend.',
                    ),
                  ),
                ),
              if (l != null) ...[
                Text(
                  'Las apps piden la lista firmada al conectar y cada 10 minutos; pasan al siguiente dominio activo '
                  'si el que usan deja de responder. Versión ${l.version}.',
                ),
                if (l.publicKey != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clave pública para las apps'),
                    subtitle: SelectableText(l.publicKey!, key: const Key('domains.publicKey')),
                    trailing: IconButton(
                      tooltip: 'Copiar',
                      icon: const Icon(Icons.copy),
                      onPressed: () => Clipboard.setData(ClipboardData(text: l.publicKey!)),
                    ),
                  ),
                const SizedBox(height: 8),
                if (l.domains.isEmpty) const Text('Aún no hay dominios.'),
                for (final (i, d) in l.domains.indexed)
                  Card(
                    key: ValueKey('domains.item.${d.id}'),
                    child: ListTile(
                      leading: Icon(
                        switch (d.status) {
                          'ok' => Icons.check_circle,
                          'down' => Icons.error,
                          _ => Icons.help_outline,
                        },
                        color: switch (d.status) {
                          'ok' => const Color(0xFF2E7D32),
                          'down' => scheme.error,
                          _ => scheme.outline,
                        },
                      ),
                      title: Text('${i + 1}. ${d.apiUrl}'),
                      subtitle: Text(
                        '${d.realtimeUrl} · '
                        '${switch (d.status) {
                          'ok' => 'responde en ${d.latencyMs} ms',
                          'down' => 'no responde',
                          _ => 'sin comprobar',
                        }}',
                      ),
                      trailing: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Subir',
                            icon: const Icon(Icons.arrow_upward),
                            onPressed: i == 0 ? null : () => cubit.move(d, -1),
                          ),
                          IconButton(
                            tooltip: 'Bajar',
                            icon: const Icon(Icons.arrow_downward),
                            onPressed: i == l.domains.length - 1 ? null : () => cubit.move(d, 1),
                          ),
                          Switch(
                            key: ValueKey('domains.active.${d.id}'),
                            value: d.active,
                            onChanged: (v) => cubit.setActive(d, v),
                          ),
                          IconButton(
                            tooltip: 'Borrar',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => cubit.remove(d),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
