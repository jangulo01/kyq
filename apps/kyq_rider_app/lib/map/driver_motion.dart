import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:kyq_api/kyq_api.dart';

import 'trip_map.dart';

/// Tope de la animación entre dos ubicaciones: el conductor envía una cada ~3 s (010, R6).
const maxMotion = Duration(seconds: 3);

/// Punto a [t] (0–1) del camino recto de [a] a [b]; en tramos urbanos cortos basta.
GeoPoint lerpPoint(GeoPoint a, GeoPoint b, double t) =>
    GeoPoint(lat: a.lat + (b.lat - a.lat) * t, lng: a.lng + (b.lng - a.lng) * t);

/// Rumbo en grados (0 = norte, 90 = este) de [a] hacia [b].
double bearing(GeoPoint a, GeoPoint b) {
  double rad(double d) => d * math.pi / 180;
  final dLng = rad(b.lng - a.lng);
  final y = math.sin(dLng) * math.cos(rad(b.lat));
  final x = math.cos(rad(a.lat)) * math.sin(rad(b.lat)) - math.sin(rad(a.lat)) * math.cos(rad(b.lat)) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Ángulo a [t] de [a] a [b] por el giro más corto (de 350° a 10° pasa por 0°).
double lerpAngle(double a, double b, double t) {
  final delta = ((b - a + 540) % 360) - 180;
  return (a + delta * t + 360) % 360;
}

/// Desplazamiento mínimo (en grados, ~2 m) para calcular un rumbo fiable entre dos puntos.
const _minMove = 2e-5;

/// Anima el vehículo del conductor entre ubicaciones (010, FR-017): en lugar de saltar, se
/// desplaza en línea recta durante el intervalo entre ubicaciones (como mucho [maxMotion]) y gira
/// según [heading] o, si no llega, según la dirección del movimiento.
class DriverMotion extends StatefulWidget {
  const DriverMotion({
    super.key,
    required this.markers,
    required this.heading,
    required this.builder,
    this.now = DateTime.now,
  });

  /// Marcadores con la última posición recibida del conductor.
  final TripMapMarkers markers;

  /// Rumbo del GPS del conductor, si lo envía.
  final double? heading;

  /// Pinta el mapa con la posición y el rumbo animados.
  final Widget Function(TripMapMarkers markers) builder;

  /// Reloj para medir el intervalo entre ubicaciones; las pruebas pasan uno manual.
  final DateTime Function() now;

  @override
  State<DriverMotion> createState() => _DriverMotionState();
}

class _DriverMotionState extends State<DriverMotion> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  GeoPoint? _from;
  GeoPoint? _to;
  double? _fromHeading;
  double? _toHeading;
  DateTime? _lastFix;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: maxMotion)..addListener(() => setState(() {}));
    _to = widget.markers.driver;
    _toHeading = widget.heading;
    _lastFix = widget.now();
  }

  @override
  void didUpdateWidget(DriverMotion old) {
    super.didUpdateWidget(old);
    final next = widget.markers.driver;
    if (next == null || next == _to) {
      if (widget.heading != old.heading && next == _to) _toHeading = widget.heading ?? _toHeading;
      return;
    }
    final current = _position;
    final currentHeading = _heading;
    _from = current ?? next;
    _fromHeading = currentHeading;
    _to = next;
    final moved =
        current != null && ((next.lat - current.lat).abs() > _minMove || (next.lng - current.lng).abs() > _minMove);
    _toHeading = widget.heading ?? (moved ? bearing(current, next) : currentHeading);
    final now = widget.now();
    final gap = _lastFix == null ? maxMotion : now.difference(_lastFix!);
    _lastFix = now;
    _anim.duration = gap > maxMotion || gap <= Duration.zero ? maxMotion : gap;
    _anim.forward(from: 0);
  }

  double get _t => Curves.linear.transform(_anim.value);

  GeoPoint? get _position {
    final from = _from, to = _to;
    if (to == null) return null;
    if (from == null || !_anim.isAnimating) return to;
    return lerpPoint(from, to, _t);
  }

  double? get _heading {
    final from = _fromHeading, to = _toHeading;
    if (to == null) return from;
    if (from == null || !_anim.isAnimating) return to;
    return lerpAngle(from, to, _t);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.markers;
    return widget.builder(
      TripMapMarkers(
        pickup: m.pickup,
        dropoff: m.dropoff,
        driver: _position,
        driverHeading: _heading,
        golden: m.golden,
      ),
    );
  }
}
