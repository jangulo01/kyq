import 'package:flutter/material.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'trip_map.dart';

/// Estilo del mapa base (Protomaps sobre PMTiles propios, ver `infra/tiles/build.sh`).
///
/// `KYQ_MAP_STYLE_URL` lo fija; si no se define, se usa el servicio `tiles` (puerto 8081) del mismo
/// host que `KYQ_API_URL`, que en desarrollo es la VM.
final mapStyleUrl = _styleOverride.isNotEmpty ? _styleOverride : _styleFromApiHost();

const _styleOverride = String.fromEnvironment('KYQ_MAP_STYLE_URL');
const _apiUrl = String.fromEnvironment('KYQ_API_URL', defaultValue: 'http://10.0.2.2:8080');

String _styleFromApiHost() =>
    Uri.parse(_apiUrl).replace(port: 8081, path: '/style.json', query: null, fragment: null).toString();

/// Centro inicial si aún no sabemos dónde está el pasajero (Bogotá).
const _fallbackCenter = LatLng(4.7110, -74.0721);

/// Mapa MapLibre con círculos para origen (verde), destino (rojo) y conductor (azul).
class MaplibreTripMap extends StatefulWidget {
  const MaplibreTripMap({super.key, required this.markers, this.onTap});

  final TripMapMarkers markers;
  final ValueChanged<GeoPoint>? onTap;

  @override
  State<MaplibreTripMap> createState() => _MaplibreTripMapState();
}

class _MaplibreTripMapState extends State<MaplibreTripMap> {
  MapLibreMapController? _controller;
  bool _styleReady = false;
  bool _centered = false;

  LatLng? _latLng(GeoPoint? p) => p == null ? null : LatLng(p.lat, p.lng);

  @override
  void didUpdateWidget(MaplibreTripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _redraw();
  }

  // MapLibre falla si dos redibujados se solapan (clear/add sobre la misma fuente GeoJSON); los
  // cambios que llegan mientras se dibuja se agrupan en un único redibujado posterior.
  bool _drawing = false;
  bool _pending = false;

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
      debugPrint('Mapa: $e');
    } finally {
      _drawing = false;
    }
  }

  Future<void> _draw() async {
    final controller = _controller;
    if (controller == null || !_styleReady) return;
    final m = widget.markers;
    await controller.clearCircles();
    for (final (point, color) in [(m.pickup, '#2E7D32'), (m.dropoff, '#C62828'), (m.driver, '#1565C0')]) {
      final at = _latLng(point);
      if (at == null) continue;
      await controller.addCircle(
        CircleOptions(
          geometry: at,
          circleRadius: 9,
          circleColor: color,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
        ),
      );
    }
    // Centra una vez en el primer punto conocido (conductor o recogida).
    final focus = _latLng(m.driver ?? m.pickup);
    if (!_centered && focus != null) {
      _centered = true;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(focus, 15));
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = _latLng(widget.markers.driver ?? widget.markers.pickup);
    return MapLibreMap(
      styleString: mapStyleUrl,
      initialCameraPosition: CameraPosition(target: start ?? _fallbackCenter, zoom: start == null ? 11 : 15),
      onMapCreated: (c) => _controller = c,
      onStyleLoadedCallback: () {
        _styleReady = true;
        _centered = start != null;
        _redraw();
      },
      onMapClick: widget.onTap == null ? null : (_, at) => widget.onTap!(GeoPoint(lat: at.latitude, lng: at.longitude)),
      attributionButtonPosition: AttributionButtonPosition.bottomLeft,
    );
  }
}
