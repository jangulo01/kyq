import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import 'saved_places.dart';

/// Letras mínimas para buscar (igual que el backend).
const minPlaceQuery = 3;

/// Espera tras la última tecla antes de buscar.
const placeSearchDebounce = Duration(milliseconds: 300);

/// Abre el buscador de direcciones (010, US5) y devuelve el lugar elegido; null si el pasajero
/// prefiere marcarlo en el mapa o vuelve atrás. Lee el cliente y los lugares guardados del contexto.
Future<Place?> showPlaceSearch(BuildContext context, {required String title}) => Navigator.of(context).push<Place>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: context.read<KyqApiClient>()),
        RepositoryProvider.value(value: context.read<SavedPlacesStore>()),
      ],
      child: PlaceSearchPage(title: title),
    ),
  ),
);

/// Buscador: antes de escribir, Casa, Trabajo y recientes; desde 3 letras, sugerencias de la
/// ciudad. Sin buscador disponible, invita a marcar el punto en el mapa (FR-016).
class PlaceSearchPage extends StatefulWidget {
  const PlaceSearchPage({super.key, required this.title});

  final String title;

  @override
  State<PlaceSearchPage> createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends State<PlaceSearchPage> {
  final _query = TextEditingController();
  Timer? _debounce;
  SavedPlaces _saved = const SavedPlaces();
  List<Place>? _results;
  bool _searching = false;
  String? _error;

  /// Número de la búsqueda en curso: una respuesta vieja no pisa a la nueva.
  int _seq = 0;

  SavedPlacesStore get _store => context.read<SavedPlacesStore>();

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final saved = await _store.load();
    if (mounted) setState(() => _saved = saved);
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.length < minPlaceQuery) {
      _seq++;
      setState(() {
        _results = null;
        _searching = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(placeSearchDebounce, () => _search(q));
  }

  Future<void> _search(String q) async {
    final seq = ++_seq;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await context.read<KyqApiClient>().searchPlaces(q);
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = const [];
        _searching = false;
        _error = e.code == 'network'
            ? 'Sin conexión. Puedes marcar el punto en el mapa.'
            : 'El buscador no está disponible ahora. Puedes marcar el punto en el mapa.';
      });
    }
  }

  Future<void> _choose(Place place) async {
    final navigator = Navigator.of(context);
    await _store.addRecent(place);
    navigator.pop(place);
  }

  Future<void> _saveAs(SavedSlot slot, Place place) async {
    final messenger = ScaffoldMessenger.of(context);
    await _store.save(slot, place);
    await _loadSaved();
    messenger.showSnackBar(SnackBar(content: Text('Guardado como ${slot == SavedSlot.home ? 'Casa' : 'Trabajo'}.')));
  }

  Widget _tile(Place place, {required Key key, IconData icon = Icons.place_outlined, String? title}) => ListTile(
    key: key,
    leading: Icon(icon),
    title: Text(title ?? place.label),
    subtitle: Text(title != null ? place.label : place.detail, maxLines: 1, overflow: TextOverflow.ellipsis),
    onTap: () => _choose(place),
    trailing: PopupMenuButton<SavedSlot>(
      tooltip: 'Guardar',
      onSelected: (slot) => _saveAs(slot, place),
      itemBuilder: (_) => const [
        PopupMenuItem(value: SavedSlot.home, child: Text('Guardar como Casa')),
        PopupMenuItem(value: SavedSlot.work, child: Text('Guardar como Trabajo')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('places.query'),
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(hintText: widget.title, border: InputBorder.none),
          onChanged: _onChanged,
        ),
      ),
      body: ListView(
        children: [
          if (_searching) const LinearProgressIndicator(),
          if (results == null) ...[
            if (_saved.home case final home?)
              _tile(home, key: const Key('places.home'), icon: Icons.home_outlined, title: 'Casa'),
            if (_saved.work case final work?)
              _tile(work, key: const Key('places.work'), icon: Icons.work_outline, title: 'Trabajo'),
            for (final (i, p) in _saved.recents.indexed) _tile(p, key: Key('places.recent.$i'), icon: Icons.history),
            if (_saved.home == null && _saved.work == null && _saved.recents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Escribe una dirección o un lugar, por ejemplo "Calle 72 # 10" o "Andino".'),
              ),
          ] else ...[
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, key: const Key('places.error')),
              )
            else if (results.isEmpty && !_searching)
              const Padding(padding: EdgeInsets.all(16), child: Text('Sin resultados en tu ciudad.')),
            for (final (i, p) in results.indexed) _tile(p, key: Key('places.result.$i')),
          ],
          ListTile(
            key: const Key('places.useMap'),
            leading: const Icon(Icons.map_outlined),
            title: const Text('Marcar en el mapa'),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
