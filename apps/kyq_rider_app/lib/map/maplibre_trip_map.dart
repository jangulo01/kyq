import 'dart:typed_data';
import 'dart:ui' as ui;

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

/// Imagen de la flecha del vehículo (apunta al norte; MapLibre la gira con `iconRotate`).
const _driverIcon = 'kyq-driver';

/// Flecha azul con borde blanco de 64 px, dibujada en el teléfono: sin recursos externos.
Future<Uint8List> _arrowPng() async {
  const size = 64.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final path = Path()
    ..moveTo(size / 2, 4)
    ..lineTo(size - 10, size - 8)
    ..lineTo(size / 2, size - 20)
    ..lineTo(10, size - 8)
    ..close();
  canvas.drawPath(path, Paint()..color = const Color(0xFF1565C0));
  canvas.drawPath(
    path,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round,
  );
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Mapa MapLibre con círculos para origen (verde), destino (rojo) y pines dorados (010), y una
/// flecha que gira con el rumbo para el conductor.
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
  bool _iconReady = false;
  Symbol? _driver;

  /// Puntos fijos dibujados la última vez: solo se redibujan si cambian.
  String? _drawnStatic;

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
    final points = [
      (m.pickup, '#2E7D32', 9.0),
      (m.dropoff, '#C62828', 9.0),
      for (final g in m.golden) (g, '#D4AF37', 11.0),
    ];
    final key = points.map((p) => '${p.$1?.lat},${p.$1?.lng},${p.$2}').join('|');
    if (key != _drawnStatic) {
      _drawnStatic = key;
      await controller.clearCircles();
      for (final (point, color, radius) in points) {
        final at = _latLng(point);
        if (at == null) continue;
        await controller.addCircle(
          CircleOptions(
            geometry: at,
            circleRadius: radius,
            circleColor: color,
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2,
          ),
        );
      }
    }
    await _drawDriver(controller, m);
    // Centra una vez en el primer punto conocido (conductor, recogida o un pin dorado).
    final focus = _latLng(m.driver ?? m.pickup ?? m.golden.firstOrNull);
    if (!_centered && focus != null) {
      _centered = true;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(focus, 15));
    }
  }

  // 010: la flecha se mueve con updateSymbol en cada paso de la animación, sin redibujar el resto.
  Future<void> _drawDriver(MapLibreMapController controller, TripMapMarkers m) async {
    final at = _latLng(m.driver);
    if (at == null) {
      if (_driver case final d?) await controller.removeSymbol(d);
      _driver = null;
      return;
    }
    if (!_iconReady) {
      await controller.addImage(_driverIcon, await _arrowPng());
      _iconReady = true;
    }
    final options = SymbolOptions(
      geometry: at,
      iconImage: _driverIcon,
      iconSize: 0.6,
      iconRotate: m.driverHeading ?? 0,
      iconAnchor: 'center',
    );
    if (_driver case final d?) {
      await controller.updateSymbol(d, options);
    } else {
      _driver = await controller.addSymbol(options);
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = _latLng(widget.markers.driver ?? widget.markers.pickup ?? widget.markers.golden.firstOrNull);
    return MapLibreMap(
      styleString: mapStyleUrl,
      initialCameraPosition: CameraPosition(target: start ?? _fallbackCenter, zoom: start == null ? 11 : 15),
      onMapCreated: (c) => _controller = c,
      onStyleLoadedCallback: () {
        // Un estilo nuevo borra las anotaciones y las imágenes: se dibuja todo de nuevo.
        _styleReady = true;
        _iconReady = false;
        _driver = null;
        _drawnStatic = null;
        _centered = start != null;
        _redraw();
      },
      onMapClick: widget.onTap == null ? null : (_, at) => widget.onTap!(GeoPoint(lat: at.latitude, lng: at.longitude)),
      attributionButtonPosition: AttributionButtonPosition.bottomLeft,
    );
  }
}
