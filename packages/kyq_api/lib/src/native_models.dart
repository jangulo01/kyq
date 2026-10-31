// Modelos de 010 (experiencia nativa): reservas, ficha del cliente y direcciones
// (specs/001-…/contracts/api.yaml).
import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';
import 'ops_models.dart';

part 'native_models.freezed.dart';
part 'native_models.g.dart';

/// Estados de una reserva (010 data-model).
enum ReservationStatus { pending, confirmed, rejected, cancelled, expired, fulfilled, missed }

@freezed
abstract class Reservation with _$Reservation {
  const factory Reservation({
    required String id,
    required PersonRef passenger,
    required PersonRef driver,
    required GeoPoint pickup,
    required GeoPoint dropoff,
    String? pickupLabel,
    String? dropoffLabel,
    required DateTime scheduledAt,
    required int distanceM,
    required int durationS,
    required String currency,

    /// Tarifa reservada (con la preferencial de 008 si aplicaba).
    required int fareMinor,
    required int listFareMinor,
    @Default(0) int preferentialDiscountPct,
    @JsonKey(unknownEnumValue: ReservationStatus.cancelled) required ReservationStatus status,
    @Default(false) bool cancelledByMe,
    String? tripId,

    /// Agenda: otra reserva del conductor a menos de 30 minutos.
    @Default(false) bool overlaps,
  }) = _Reservation;

  factory Reservation.fromJson(Map<String, dynamic> json) => _$ReservationFromJson(json);
}

/// Reserva abierta (pendiente o confirmada) que aún no llegó.
extension ReservationOpen on Reservation {
  bool get open => status == ReservationStatus.pending || status == ReservationStatus.confirmed;
}

@freezed
abstract class UpcomingReservation with _$UpcomingReservation {
  const factory UpcomingReservation({
    required String id,
    required DateTime scheduledAt,
    @JsonKey(unknownEnumValue: ReservationStatus.pending) required ReservationStatus status,
  }) = _UpcomingReservation;

  factory UpcomingReservation.fromJson(Map<String, dynamic> json) => _$UpcomingReservationFromJson(json);
}

/// Ficha de un cliente para su conductor (010 FR-007); la nota es privada del conductor.
@freezed
abstract class ClientCard with _$ClientCard {
  const factory ClientCard({
    required String passengerId,
    required String displayName,
    required DateTime affiliatedAt,
    @Default(AffiliationSource.qrScan) AffiliationSource source,
    @Default(0) int tripsTogether,
    DateTime? lastTripAt,
    String? note,
    @Default(<UpcomingReservation>[]) List<UpcomingReservation> upcomingReservations,
  }) = _ClientCard;

  factory ClientCard.fromJson(Map<String, dynamic> json) => _$ClientCardFromJson(json);
}

/// Sugerencia del buscador de direcciones (010 FR-014).
@freezed
abstract class Place with _$Place {
  const factory Place({required String label, @Default('') String detail, required double lat, required double lng}) =
      _Place;

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);
}

extension PlacePoint on Place {
  GeoPoint get point => GeoPoint(lat: lat, lng: lng);
}
