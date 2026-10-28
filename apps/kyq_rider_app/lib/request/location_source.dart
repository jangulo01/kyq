import 'package:geolocator/geolocator.dart';
import 'package:kyq_api/kyq_api.dart';

/// No se pudo obtener la ubicación; [message] se muestra tal cual al pasajero.
class LocationUnavailable implements Exception {
  const LocationUnavailable(this.message);

  final String message;
}

/// Ubicación del teléfono, detrás de una interfaz para poder probar sin GPS.
abstract interface class LocationSource {
  /// true si ya hay permiso y no hace falta explicar nada antes de pedirlo.
  Future<bool> hasPermission();

  /// Pide permiso si falta y devuelve la posición actual. Lanza [LocationUnavailable].
  Future<GeoPoint> current();
}

class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  @override
  Future<bool> hasPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  @override
  Future<GeoPoint> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable('Activa la ubicación del teléfono o marca el origen en el mapa.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable(
        'El permiso de ubicación está bloqueado. Actívalo en los ajustes del teléfono o marca el origen en el mapa.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationUnavailable('Sin permiso de ubicación. Marca el origen en el mapa.');
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      return GeoPoint(lat: pos.latitude, lng: pos.longitude);
    } on Exception {
      throw const LocationUnavailable('No pudimos obtener tu ubicación. Marca el origen en el mapa.');
    }
  }
}
