import 'dart:convert';

import 'package:kyq_api/kyq_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lugares guardados en el teléfono (010, FR-015): Casa, Trabajo y los 10 destinos recientes.
/// No salen del teléfono.
class SavedPlaces {
  const SavedPlaces({this.home, this.work, this.recents = const []});

  final Place? home;
  final Place? work;
  final List<Place> recents;
}

enum SavedSlot { home, work }

/// Destinos recientes que se recuerdan.
const maxRecents = 10;

abstract interface class SavedPlacesStore {
  Future<SavedPlaces> load();

  /// Guarda [place] como Casa o Trabajo.
  Future<void> save(SavedSlot slot, Place place);

  /// Pone [place] el primero de los recientes, sin duplicados y como mucho [maxRecents].
  Future<void> addRecent(Place place);
}

/// Mismo lugar a efectos de recientes: mismo nombre y a unos 10 m.
bool samePlace(Place a, Place b) => a.label == b.label && (a.lat - b.lat).abs() < 1e-4 && (a.lng - b.lng).abs() < 1e-4;

List<Place> withRecent(List<Place> recents, Place place) =>
    [place, ...recents.where((p) => !samePlace(p, place))].take(maxRecents).toList();

/// [SavedPlacesStore] en shared_preferences.
class SharedPrefsSavedPlaces implements SavedPlacesStore {
  const SharedPrefsSavedPlaces();

  static const _home = 'places.home', _work = 'places.work', _recents = 'places.recents';

  static Place? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return Place.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  @override
  Future<SavedPlaces> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SavedPlaces(
      home: _decode(prefs.getString(_home)),
      work: _decode(prefs.getString(_work)),
      recents: [for (final raw in prefs.getStringList(_recents) ?? const <String>[]) ?_decode(raw)],
    );
  }

  @override
  Future<void> save(SavedSlot slot, Place place) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(slot == SavedSlot.home ? _home : _work, jsonEncode(place.toJson()));
  }

  @override
  Future<void> addRecent(Place place) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (await load()).recents;
    await prefs.setStringList(_recents, [for (final p in withRecent(current, place)) jsonEncode(p.toJson())]);
  }
}

/// [SavedPlacesStore] en memoria (pruebas y web sin almacenamiento).
class MemorySavedPlaces implements SavedPlacesStore {
  MemorySavedPlaces([this.places = const SavedPlaces()]);

  SavedPlaces places;

  @override
  Future<SavedPlaces> load() async => places;

  @override
  Future<void> save(SavedSlot slot, Place place) async => places = SavedPlaces(
    home: slot == SavedSlot.home ? place : places.home,
    work: slot == SavedSlot.work ? place : places.work,
    recents: places.recents,
  );

  @override
  Future<void> addRecent(Place place) async =>
      places = SavedPlaces(home: places.home, work: places.work, recents: withRecent(places.recents, place));
}
