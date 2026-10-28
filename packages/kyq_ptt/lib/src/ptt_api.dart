import 'package:kyq_api/kyq_api.dart';

/// La otra parte tiene el turno (409).
class PttFloorBusy implements Exception {
  const PttFloorBusy();
}

/// El canal del viaje ya cerró (410, FR-020).
class PttChannelClosed implements Exception {
  const PttChannelClosed();
}

/// Endpoints PTT de un viaje. Lanza [PttFloorBusy] o [PttChannelClosed] en vez de códigos HTTP.
abstract interface class PttApi {
  Future<PttCredentials> token();

  /// Pide el turno y devuelve cuándo caduca (60 s como máximo).
  Future<DateTime> requestFloor();

  Future<void> releaseFloor();
}

/// [PttApi] sobre [KyqApiClient].
class KyqPttApi implements PttApi {
  KyqPttApi(this._api, this.tripId);

  final KyqApiClient _api;
  final String tripId;

  @override
  Future<PttCredentials> token() => _map(() => _api.pttToken(tripId));

  @override
  Future<DateTime> requestFloor() => _map(() => _api.requestFloor(tripId));

  @override
  Future<void> releaseFloor() => _map(() => _api.releaseFloor(tripId));

  Future<T> _map<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      throw switch (e.statusCode) {
        409 => const PttFloorBusy(),
        410 => const PttChannelClosed(),
        _ => e,
      };
    }
  }
}

/// [PttApi] de una pre-consulta de voz (005, RN-KYQ-010): mismas reglas de turno que el viaje,
/// con turnos de 15 s. `preconsult_waiting` (el conductor aún no se unió) llega como
/// [ApiException] y el controlador lo muestra como error reintentable.
class PreconsultPttApi implements PttApi {
  PreconsultPttApi(this._api, this.preconsultId);

  final KyqApiClient _api;
  final String preconsultId;

  @override
  Future<PttCredentials> token() => _map(() => _api.preconsultToken(preconsultId));

  @override
  Future<DateTime> requestFloor() => _map(() => _api.requestPreconsultFloor(preconsultId));

  @override
  Future<void> releaseFloor() => _map(() => _api.releasePreconsultFloor(preconsultId));

  Future<T> _map<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      throw switch ((e.statusCode, e.code)) {
        (409, 'ptt_busy') => const PttFloorBusy(),
        (410, _) => const PttChannelClosed(),
        _ => e,
      };
    }
  }
}
