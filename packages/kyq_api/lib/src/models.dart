// Modelos de specs/001-chosen-driver-trip-ptt/contracts/api.yaml.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum UserRole { passenger, driver, admin }

enum DriverPresence { offline, free, busy }

enum SubscriptionStatus {
  active,
  @JsonValue('grace_period')
  gracePeriod,
  suspended,
}

enum DocType {
  license,
  @JsonValue('mandatory_insurance')
  mandatoryInsurance,
  @JsonValue('vehicle_registration')
  vehicleRegistration,
}

/// Valor de [DocType] en la API (ruta `/documents/{docType}`).
String docTypeToApi(DocType type) => switch (type) {
  DocType.license => 'license',
  DocType.mandatoryInsurance => 'mandatory_insurance',
  DocType.vehicleRegistration => 'vehicle_registration',
};

enum TripStatus {
  @JsonValue('REQUESTED')
  requested,
  @JsonValue('FARE_PENDING')
  farePending,
  @JsonValue('NEGOTIATION_PENDING')
  negotiationPending,
  @JsonValue('NEGOTIATING')
  negotiating,
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('ARRIVED')
  arrived,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('CANCELLED')
  cancelled,
}

@freezed
abstract class Tokens with _$Tokens {
  const factory Tokens({required String accessToken, required String refreshToken, required UserRole role}) = _Tokens;

  factory Tokens.fromJson(Map<String, dynamic> json) => _$TokensFromJson(json);
}

@freezed
abstract class GeoPoint with _$GeoPoint {
  const factory GeoPoint({required double lat, required double lng}) = _GeoPoint;

  factory GeoPoint.fromJson(Map<String, dynamic> json) => _$GeoPointFromJson(json);
}

@freezed
abstract class DriverDocument with _$DriverDocument {
  const factory DriverDocument({required DocType docType, required String expiresAt, required bool approved}) =
      _DriverDocument;

  factory DriverDocument.fromJson(Map<String, dynamic> json) => _$DriverDocumentFromJson(json);
}

@freezed
abstract class DriverMe with _$DriverMe {
  const factory DriverMe({
    required String driverId,
    required String qrToken,
    required DriverPresence presence,
    required SubscriptionStatus subscriptionStatus,
    DateTime? paidUntil,
    required bool canGoOnline,
    String? blockReason,
    @Default(<DriverDocument>[]) List<DriverDocument> documents,
  }) = _DriverMe;

  factory DriverMe.fromJson(Map<String, dynamic> json) => _$DriverMeFromJson(json);
}

/// Fila de `GET /v1/admin/drivers`.
@freezed
abstract class AdminDriver with _$AdminDriver {
  const factory AdminDriver({
    required String driverId,
    required String phoneE164,
    required String displayName,
    required String qrToken,
    required String vehiclePlate,
    required String vehicleDescription,
    required DriverPresence presence,
    DateTime? paidUntil,
    required SubscriptionStatus subscriptionStatus,
    required bool canGoOnline,
    String? blockReason,
    @Default(<DriverDocument>[]) List<DriverDocument> documents,
  }) = _AdminDriver;

  factory AdminDriver.fromJson(Map<String, dynamic> json) => _$AdminDriverFromJson(json);
}

@freezed
abstract class ChosenDriver with _$ChosenDriver {
  const factory ChosenDriver({
    required String driverId,
    required String displayName,
    required String vehicleDescription,
    required DriverPresence presence,
    DateTime? busyUntilEstimate,
  }) = _ChosenDriver;

  factory ChosenDriver.fromJson(Map<String, dynamic> json) => _$ChosenDriverFromJson(json);
}

/// Pasajero de la cartera del conductor (`GET /v1/driver/clients`).
@freezed
abstract class DriverClient with _$DriverClient {
  const factory DriverClient({
    required String passengerId,
    required String displayName,
    required DateTime affiliatedAt,
  }) = _DriverClient;

  factory DriverClient.fromJson(Map<String, dynamic> json) => _$DriverClientFromJson(json);
}

@freezed
abstract class FareQuote with _$FareQuote {
  const factory FareQuote({
    required int distanceM,
    required int durationS,
    required int suggestedFareMinor,
    required String currency,
  }) = _FareQuote;

  factory FareQuote.fromJson(Map<String, dynamic> json) => _$FareQuoteFromJson(json);
}

enum ProposalParty { driver, passenger }

enum ProposalStatus { open, accepted, superseded, expired }

@freezed
abstract class FareProposal with _$FareProposal {
  const factory FareProposal({
    required String id,
    required ProposalParty proposedBy,
    required int amountMinor,
    required ProposalStatus status,
    required DateTime expiresAt,
  }) = _FareProposal;

  factory FareProposal.fromJson(Map<String, dynamic> json) => _$FareProposalFromJson(json);
}

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    required TripStatus status,
    required String passengerId,
    required String driverId,
    required GeoPoint pickup,
    required GeoPoint dropoff,
    required int distanceM,
    required int durationS,
    required String currency,
    required int suggestedFareMinor,
    int? agreedFareMinor,
    int? driverPayoutMinor,
    @Default(0) int platformCommissionMinor,
    FareProposal? openProposal,
    DateTime? offerExpiresAt,
    DateTime? negotiationExpiresAt,
    String? cancelReason,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}
