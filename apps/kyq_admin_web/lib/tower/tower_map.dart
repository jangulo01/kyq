import 'package:flutter/material.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../app/app.dart' show apiBaseUrl;

/// 009: toques en el mapa y hexágonos elegidos para el megáfono.
class TowerMapTaps {
  const TowerMapTaps({required this.onDriver, required this.onCell, this.selected = const {}});

  /// Clic en un conductor: abre su viaje activo si está ocupado (FR-001).
  final void Function(String driverId) onDriver;

  /// Clic en un hexágono: sus viajes y la selección del megáfono.
  final void Function(String cell) onCell;
  final Set<String> selected;
}

/// Construye el mapa de la torre. Las pruebas lo sustituyen porque MapLibre no se puede pintar en
/// ellas.
typedef TowerMapBuilder = Widget Function(TowerSnapshot snapshot, TowerMapTaps taps);

/// Mapa real con MapLibre.
Widget maplibreTowerMap(TowerSnapshot snapshot, TowerMapTaps taps) => MaplibreTowerMap(snapshot: snapshot, taps: taps);

/// Estilo del mapa base propio (Protomaps sobre PMTiles, `infra/tiles`). `KYQ_MAP_STYLE_URL` lo
/// fija; si no, el servicio `tiles` (puerto 8081) del mismo host que la API.
final towerStyleUrl = _styleOverride.isNotEmpty ? _styleOverride : _styleFromApiHost();

const _styleOverride = String.fromEnvironment('KYQ_MAP_STYLE_URL');

String _styleFromApiHost() =>
    Uri.parse(apiBaseUrl).replace(port: 8081, path: '/style.json', query: null, fragment: null).toString();

/// Bogotá, si aún no hay nada que mostrar.
const _fallbackCenter = LatLng(4.6097, -74.0817);

/// Colores por nivel de presión y por estado del conductor (los mismos de la leyenda).
const levelColors = {
  PressureLevel.noSupply: Color(0xFFC62828),
  PressureLevel.high: Color(0xFFEF6C00),
  PressureLevel.balanced: Color(0xFF2E7D32),
  PressureLevel.none: Color(0xFF78909C),
};
const freeColor = Color(0xFF2E7D32);
const busyColor = Color(0xFFEF6C00);

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

const _levelNames = {
  PressureLevel.noSupply: 'no_supply',
  PressureLevel.high: 'high',
  PressureLevel.balanced: 'balanced',
  PressureLevel.none: 'none',
};

/// Hexágonos como FeatureCollection GeoJSON (anillo cerrado, [lng, lat]); [selected] los marca
/// para el megáfono.
Map<String, dynamic> hexagonsGeoJson(TowerSnapshot s, {Set<String> selected = const {}}) => {
  'type': 'FeatureCollection',
  'features': [
    for (final c in s.cells)
      if (c.boundary.length >= 3)
        {
          'type': 'Feature',
          'id': c.cell,
          'properties': {
            'cell': c.cell,
            'level': _levelNames[c.level],
            'free': c.freeDrivers,
            'busy': c.busyDrivers,
            'requests': c.requests,
            'selected': selected.contains(c.cell),
          },
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                for (final p in c.boundary) [p.lng, p.lat],
                [c.boundary.first.lng, c.boundary.first.lat],
              ],
            ],
          },
        },
  ],
};

/// Conductores como puntos GeoJSON.
Map<String, dynamic> driversGeoJson(TowerSnapshot s) => {
  'type': 'FeatureCollection',
  'features': [
    for (final d in s.drivers)
      {
        'type': 'Feature',
        'id': d.driverId,
        'properties': {'presence': d.presence.name, 'stale': d.stale, 'name': d.displayName},
        'geometry': {
          'type': 'Point',
          'coordinates': [d.lng, d.lat],
        },
      },
  ],
};

/// Mapa MapLibre con los hexágonos coloreados por presión y los conductores por estado.
class MaplibreTowerMap extends StatefulWidget {
  const MaplibreTowerMap({super.key, required this.snapshot, required this.taps});

  final TowerSnapshot snapshot;
  final TowerMapTaps taps;

  @override
  State<MaplibreTowerMap> createState() => _MaplibreTowerMapState();
}

class _MaplibreTowerMapState extends State<MaplibreTowerMap> {
  MapLibreMapController? _controller;
  bool _styleReady = false;
  bool _centered = false;

  // MapLibre falla si dos actualizaciones de la misma fuente se solapan; se agrupan.
  bool _drawing = false;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    // index.html carga MapLibre GL JS con el protocolo pmtiles y publica el global.
    MapLibreMap.webLibrarySource = const MapLibreJsSource.preloaded();
  }

  @override
  void didUpdateWidget(MaplibreTowerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot != widget.snapshot || oldWidget.taps.selected != widget.taps.selected) _redraw();
  }

  Future<void> _redraw() async {
    if (_drawing) {
      _pending = true;
      return;
    }
    _drawing = true;
    try {
      do {
        _pending = false;
        await _draw();
      } while (_pending && mounted);
    } on Object catch (e) {
      debugPrint('Mapa de la torre: $e');
    } finally {
      _drawing = false;
    }
  }

  Future<void> _addLayers(MapLibreMapController c) async {
    await c.addGeoJsonSource('hexagons', hexagonsGeoJson(widget.snapshot, selected: widget.taps.selected));
    await c.addGeoJsonSource('drivers', driversGeoJson(widget.snapshot));
    final levelColor = [
      'match',
      ['get', 'level'],
      for (final e in _levelNames.entries) ...[e.value, _hex(levelColors[e.key]!)],
      _hex(levelColors[PressureLevel.none]!),
    ];
    await c.addFillLayer('hexagons', 'hexagons-fill', FillLayerProperties(fillColor: levelColor, fillOpacity: 0.35));
    await c.addLineLayer(
      'hexagons',
      'hexagons-line',
      LineLayerProperties(
        lineColor: levelColor,
        lineWidth: [
          'case',
          ['get', 'selected'],
          4.0,
          1.5,
        ],
      ),
    );
    await c.addCircleLayer(
      'drivers',
      'drivers-circle',
      CircleLayerProperties(
        circleRadius: 7,
        circleColor: [
          'match',
          ['get', 'presence'],
          'busy',
          _hex(busyColor),
          _hex(freeColor),
        ],
        circleOpacity: [
          'case',
          ['get', 'stale'],
          0.4,
          1.0,
        ],
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
    );
  }

  Future<void> _draw() async {
    final c = _controller;
    if (c == null || !_styleReady) return;
    await c.setGeoJsonSource('hexagons', hexagonsGeoJson(widget.snapshot, selected: widget.taps.selected));
    await c.setGeoJsonSource('drivers', driversGeoJson(widget.snapshot));
    final focus = _focus(widget.snapshot);
    if (!_centered && focus != null) {
      _centered = true;
      await c.animateCamera(CameraUpdate.newLatLngZoom(focus, 12));
    }
  }

  static LatLng? _focus(TowerSnapshot s) {
    if (s.drivers.isNotEmpty) return LatLng(s.drivers.first.lat, s.drivers.first.lng);
    if (s.cells.isNotEmpty) return LatLng(s.cells.first.center.lat, s.cells.first.center.lng);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final start = _focus(widget.snapshot);
    return MapLibreMap(
      styleString: towerStyleUrl,
      initialCameraPosition: CameraPosition(target: start ?? _fallbackCenter, zoom: 12),
      onMapCreated: (c) {
        _controller = c;
        // 009: un clic en un conductor o un hexágono (FR-001).
        c.onFeatureTapped.add((point, coordinates, id, layerId, annotation) {
          if (layerId == 'drivers-circle') widget.taps.onDriver(id);
          if (layerId == 'hexagons-fill') widget.taps.onCell(id);
        });
      },
      onStyleLoadedCallback: () async {
        final c = _controller;
        if (c == null) return;
        try {
          await _addLayers(c);
          _styleReady = true;
          _centered = start != null;
          await _redraw();
        } on Object catch (e) {
          debugPrint('Mapa de la torre: $e');
        }
      },
      attributionButtonPosition: AttributionButtonPosition.bottomLeft,
    );
  }
}
