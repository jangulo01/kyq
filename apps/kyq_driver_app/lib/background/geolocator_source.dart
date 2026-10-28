import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'location_reporter.dart';

/// Fuerza el `LocationManager` de Android en vez del proveedor de Google Play Services.
///
/// `geolocator_android` ya usa `LocationManager` cuando el equipo no tiene Google Play Services;
/// esta bandera lo fuerza también en equipos que sí lo tienen pero lo tienen roto o desactivado.
const forceLocationManager = bool.fromEnvironment('KYQ_FORCE_LOCATION_MANAGER');

/// [PositionSource] con `geolocator`: mantiene un flujo de posiciones y entrega la última.
class GeolocatorPositionSource implements PositionSource {
  StreamSubscription<Position>? _sub;
  LocationFix? _last;

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 3),
        forceLocationManager: forceLocationManager,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high);
  }

  void _ensureListening() {
    _sub ??= Geolocator.getPositionStream(locationSettings: _settings()).listen(
      (p) => _last = LocationFix(
        lat: p.latitude,
        lng: p.longitude,
        heading: p.heading >= 0 ? p.heading : null,
        speedMps: p.speed >= 0 ? p.speed : null,
        recordedAt: p.timestamp,
        accuracyM: p.accuracy > 0 ? p.accuracy : null,
      ),
      onError: (Object e) {
        debugPrint('GPS: $e');
        _sub?.cancel();
        _sub = null;
      },
    );
  }

  @override
  Future<LocationFix?> current() async {
    _ensureListening();
    return _last;
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _last = null;
  }
}
