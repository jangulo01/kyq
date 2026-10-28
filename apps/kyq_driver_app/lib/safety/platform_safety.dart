import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../background/geolocator_source.dart';

/// Kit de seguridad del conductor (003): GPS a 1 Hz durante la alerta, menú de compartir y
/// marcador del 123. El servicio en primer plano de ONLINE mantiene viva la app con la pantalla
/// apagada, así que la ubicación y la voz siguen en segundo plano (US1-3).
SafetyPlatform platformSafety() => SafetyPlatform(
  location: GeolocatorSosSource.new,
  share: (text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  },
  callEmergency: () async {
    await launchUrl(
      Uri(scheme: 'tel', path: '123'),
      mode: LaunchMode.externalApplication,
    );
  },
);

/// [SosLocationSource] con `geolocator` a 1 Hz (FR-003): mantiene un flujo y entrega la última
/// posición; si el GPS aún no dio ninguna, usa la última conocida del sistema.
class GeolocatorSosSource implements SosLocationSource {
  StreamSubscription<Position>? _sub;
  SosPoint? _last;

  SosPoint _point(Position p) => SosPoint(
    lat: p.latitude,
    lng: p.longitude,
    accuracyM: p.accuracy >= 0 ? p.accuracy : null,
    recordedAt: p.timestamp,
  );

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        forceLocationManager: forceLocationManager,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.best);
  }

  @override
  Future<SosPoint?> current() async {
    _sub ??= Geolocator.getPositionStream(locationSettings: _settings()).listen(
      (p) => _last = _point(p),
      onError: (Object e) {
        debugPrint('GPS SOS: $e');
        _sub?.cancel();
        _sub = null;
      },
    );
    if (_last != null) return _last;
    try {
      final known = await Geolocator.getLastKnownPosition(forceAndroidLocationManager: forceLocationManager);
      return known == null ? null : _point(known);
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _last = null;
  }
}
