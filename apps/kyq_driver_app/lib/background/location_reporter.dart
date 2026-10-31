import 'dart:async';

/// Posición del conductor lista para enviar a `POST /v1/driver/location`.
class LocationFix {
  const LocationFix({
    required this.lat,
    required this.lng,
    required this.recordedAt,
    this.heading,
    this.speedMps,
    this.accuracyM,
  });

  final double lat;
  final double lng;
  final double? heading;
  final double? speedMps;
  final DateTime recordedAt;

  /// 010: precisión del GPS en metros; el backend la usa para la llegada automática.
  final double? accuracyM;
}

/// Fuente de la posición actual. La real usa `geolocator`; las pruebas usan un falso.
abstract interface class PositionSource {
  /// Última posición conocida, o null si aún no hay ninguna.
  Future<LocationFix?> current();

  /// Libera el GPS.
  Future<void> stop();
}

/// Destino de cada posición (normalmente `KyqApiClient.sendLocation`).
typedef LocationSink = Future<void> Function(LocationFix fix);

/// Envía la posición cada [interval] mientras el conductor está ONLINE (T055).
///
/// Dart puro: no depende de Flutter ni de plugins, para probarlo con falsos.
class LocationReporter {
  LocationReporter({
    required this._source,
    required this._sink,
    this.interval = const Duration(seconds: 3),
    this.staleAfter = const Duration(seconds: 60),
    this.onError,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PositionSource _source;
  final LocationSink _sink;
  final Duration interval;

  /// Lecturas más viejas no se envían: el pasajero vería una posición desactualizada.
  final Duration staleAfter;
  final DateTime Function() _now;

  /// Se llama con los errores de lectura o envío; el envío sigue en el siguiente intervalo.
  final void Function(Object error)? onError;

  Timer? _timer;
  bool _sending = false;

  bool get running => _timer != null;

  void start() {
    if (running) return;
    _timer = Timer.periodic(interval, (_) => tick());
    unawaited(tick());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _source.stop();
  }

  /// Lee y envía una posición. Devuelve true si se envió. No se solapan dos envíos.
  ///
  /// La última lectura se reenvía en cada intervalo aunque el GPS no haya dado otra (equipo
  /// quieto o bajo techo): así el backend recibe la posición cada 3 s como pide FR-008/FR-014.
  Future<bool> tick() async {
    if (_sending) return false;
    _sending = true;
    try {
      final fix = await _source.current();
      if (fix == null || _now().difference(fix.recordedAt) > staleAfter) return false;
      await _sink(fix);
      return true;
    } on Object catch (e) {
      onError?.call(e);
      return false;
    } finally {
      _sending = false;
    }
  }
}
