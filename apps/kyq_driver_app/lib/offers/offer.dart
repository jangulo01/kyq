import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

/// Oferta exclusiva de viaje recibida por `trip.offer` (FR-011).
class Offer {
  const Offer({
    required this.tripId,
    required this.passengerName,
    required this.pickup,
    required this.dropoff,
    required this.distanceM,
    required this.durationS,
    required this.suggestedFareMinor,
    required this.currency,
    required this.expiresAt,
    this.delegated = false,
    this.canDelegate = false,
    this.cooperativeName,
    this.requestedDriverName,
  });

  factory Offer.fromEvent(TripOffered e) => Offer(
    tripId: e.tripId,
    passengerName: e.passengerName,
    pickup: GeoPoint(lat: e.pickup.lat, lng: e.pickup.lng),
    dropoff: GeoPoint(lat: e.dropoff.lat, lng: e.dropoff.lng),
    distanceM: e.distanceM,
    durationS: e.durationS,
    suggestedFareMinor: e.suggestedFareMinor,
    currency: e.currency,
    expiresAt: e.expiresAt,
    delegated: e.delegated,
    canDelegate: e.canDelegate,
    cooperativeName: e.cooperativeName,
    requestedDriverName: e.requestedDriverName,
  );

  final String tripId;
  final String passengerName;
  final GeoPoint pickup;
  final GeoPoint dropoff;
  final int distanceM;
  final int durationS;
  final int suggestedFareMinor;
  final String currency;
  final DateTime expiresAt;

  /// 006: la solicitud llega derivada desde el Conductor Elegido [requestedDriverName].
  final bool delegated;

  /// 006: con consentimiento del pasajero, el conductor puede pasarla a su cooperativa.
  final bool canDelegate;
  final String? cooperativeName;
  final String? requestedDriverName;
}

/// "4,2 km · 12 min".
String formatDistanceDuration(int distanceM, int durationS) {
  final km = (distanceM / 1000).toStringAsFixed(1).replaceAll('.', ',');
  final min = (durationS / 60).ceil();
  return '$km km · $min min';
}

/// Coordenadas legibles mientras no haya geocodificación inversa.
String formatPoint(GeoPoint p) => '${p.lat.toStringAsFixed(5)}, ${p.lng.toStringAsFixed(5)}';
