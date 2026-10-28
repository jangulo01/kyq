import 'package:kyq_radio/kyq_radio.dart';

import '../background/location_reporter.dart';

/// Ubicación de la radio con el GPS de la app (enviar ubicación, emergencia).
class PositionRadioLocation implements RadioLocation {
  const PositionRadioLocation(this.source);

  final PositionSource source;

  @override
  Future<RadioPoint?> current() async {
    final fix = await source.current();
    return fix == null ? null : (lat: fix.lat, lng: fix.lng);
  }
}
