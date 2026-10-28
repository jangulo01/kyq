import 'package:flutter/material.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Estilo del mapa base: `KYQ_MAP_STYLE_URL` o el servicio `tiles` (puerto 8081) del host de la API.
final mapStyleUrl = _styleOverride.isNotEmpty ? _styleOverride : _styleFromApiHost();

const _styleOverride = String.fromEnvironment('KYQ_MAP_STYLE_URL');
const _apiUrl = String.fromEnvironment('KYQ_API_URL', defaultValue: 'http://localhost:8080');

String _styleFromApiHost() =>
    Uri.parse(_apiUrl).replace(port: 8081, path: '/style.json', query: null, fragment: null).toString();

/// Construye el mapa de la alerta. Las pruebas lo sustituyen porque MapLibre no se pinta en ellas.
typedef SosMapBuilder = Widget Function(SosAlertDetail alert);

/// Mapa real: recorrido desde el SOS (línea), posición actual (rojo) y origen/destino del viaje.
Widget maplibreSosMap(SosAlertDetail alert) => SosLiveMap(alert: alert);

class SosLiveMap extends StatefulWidget {
  const SosLiveMap({super.key, required this.alert});

  final SosAlertDetail alert;

  @override
  State<SosLiveMap> createState() => _SosLiveMapState();
}

class _SosLiveMapState extends State<SosLiveMap> {
  MapLibreMapController? _controller;
  bool _ready = false;
  bool _drawing = false;
  bool _pending = false;
  int _drawnPoints = -1;

  LatLng? get _current {
    final l = widget.alert.lastLocation;
    return l == null ? null : LatLng(l.lat, l.lng);
  }

  @override
  void didUpdateWidget(SosLiveMap old) {
    super.didUpdateWidget(old);
    _redraw();
  }

  // Los redibujados no se solapan: MapLibre falla con dos clear/add a la vez.
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
      debugPrint('Mapa SOS: $e');
    } finally {
      _drawing = false;
    }
  }

  Future<void> _draw() async {
    final c = _controller;
    final a = widget.alert;
    if (c == null || !_ready || a.track.length == _drawnPoints) return;
    _drawnPoints = a.track.length;
    await c.clearLines();
    await c.clearCircles();
    if (a.track.length > 1) {
      await c.addLine(
        LineOptions(
          geometry: [for (final p in a.track) LatLng(p.lat, p.lng)],
          lineColor: '#C62828',
          lineWidth: 4,
          lineOpacity: 0.8,
        ),
      );
    }
    for (final (point, color) in [
      (LatLng(a.trip.pickup.lat, a.trip.pickup.lng), '#2E7D32'),
      (LatLng(a.trip.dropoff.lat, a.trip.dropoff.lng), '#1565C0'),
      ?(_current == null ? null : (_current!, '#C62828')),
    ]) {
      await c.addCircle(
        CircleOptions(
          geometry: point,
          circleRadius: point == _current ? 11 : 7,
          circleColor: color,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
        ),
      );
    }
    final current = _current;
    if (current != null) await c.animateCamera(CameraUpdate.newLatLng(current));
  }

  @override
  Widget build(BuildContext context) {
    final start = _current ?? LatLng(widget.alert.trip.pickup.lat, widget.alert.trip.pickup.lng);
    return MapLibreMap(
      styleString: mapStyleUrl,
      initialCameraPosition: CameraPosition(target: start, zoom: 15),
      onMapCreated: (c) => _controller = c,
      onStyleLoadedCallback: () {
        _ready = true;
        _redraw();
      },
      attributionButtonPosition: AttributionButtonPosition.bottomLeft,
    );
  }
}
