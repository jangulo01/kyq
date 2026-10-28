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

/// [PttApi] del canal de grupo de la cooperativa del conductor (006, COOP_GROUP).
///
/// Mismo control de turno que el viaje, con un único turno para todo el grupo. Un 404
/// (`no_cooperative`: salió, lo retiraron o la cooperativa se suspendió) cierra el canal.
class KyqCooperativePttApi implements PttApi {
  KyqCooperativePttApi(this._api);

  final KyqApiClient _api;

  @override
  Future<PttCredentials> token() => _map(_api.cooperativePttToken);

  @override
  Future<DateTime> requestFloor() => _map(_api.requestCooperativeFloor);

  @override
  Future<void> releaseFloor() => _map(_api.releaseCooperativeFloor);

  Future<T> _map<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      throw switch (e.statusCode) {
        409 => const PttFloorBusy(),
        404 || 410 => const PttChannelClosed(),
        _ => e,
      };
    }
  }
}
