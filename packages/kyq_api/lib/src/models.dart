// Modelos de specs/001-chosen-driver-trip-ptt/contracts/api.yaml.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'cooperative_models.dart';

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

/// Documentos obligatorios del conductor (002, R7). Cédula y revisión técnico-mecánica son nuevos
/// en 002; 001 solo tenía los otros tres.
enum DocType {
  @JsonValue('national_id')
  nationalId,
  license,
  @JsonValue('mandatory_insurance')
  mandatoryInsurance,
  @JsonValue('technical_inspection')
  technicalInspection,
  @JsonValue('vehicle_registration')
  vehicleRegistration,
}

/// Valor de [DocType] en la API (ruta `/documents/{docType}`).
String docTypeToApi(DocType type) => switch (type) {
  DocType.nationalId => 'national_id',
  DocType.license => 'license',
  DocType.mandatoryInsurance => 'mandatory_insurance',
  DocType.technicalInspection => 'technical_inspection',
  DocType.vehicleRegistration => 'vehicle_registration',
};

/// Reglas de captura de cada tipo (FR-005).
extension DocTypeRules on DocType {
  /// Cédula y licencia llevan reverso; el resto, solo frente.
  bool get hasBack => this == DocType.nationalId || this == DocType.license;

  /// Cédula y tarjeta de propiedad no vencen.
  bool get expires => this != DocType.nationalId && this != DocType.vehicleRegistration;

  /// Lados que se fotografían, en orden.
  List<DocSide> get sides => hasBack ? const [DocSide.front, DocSide.back] : const [DocSide.front];
}

/// Lado fotografiado de un documento.
enum DocSide { front, back }

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
  const factory Tokens({
    required String accessToken,
    required String refreshToken,
    required UserRole role,

    /// 009: `support` en la sesión de un usuario suspendido: solo abre soporte.
    String? scope,
  }) = _Tokens;

  factory Tokens.fromJson(Map<String, dynamic> json) => _$TokensFromJson(json);
}

/// 009: lectura del alcance de la sesión.
extension TokensScope on Tokens {
  /// Sesión de un usuario suspendido: solo puede usar el centro de soporte.
  bool get supportOnly => scope == 'support';
}

@freezed
abstract class GeoPoint with _$GeoPoint {
  const factory GeoPoint({required double lat, required double lng}) = _GeoPoint;

  factory GeoPoint.fromJson(Map<String, dynamic> json) => _$GeoPointFromJson(json);
}

/// Vista de 001 de un documento aprobado (`/v1/driver/me`, `/v1/admin/drivers`).
@freezed
abstract class DriverDocument with _$DriverDocument {
  const factory DriverDocument({required DocType docType, String? expiresAt, required bool approved}) = _DriverDocument;

  factory DriverDocument.fromJson(Map<String, dynamic> json) => _$DriverDocumentFromJson(json);
}

enum BlockedDocumentProblem { missing, expired }

/// Documento obligatorio que bloquea ONLINE (RN-KYQ-016): falta un aprobado o venció (002).
@freezed
abstract class BlockedDocument with _$BlockedDocument {
  const factory BlockedDocument({required DocType docType, required BlockedDocumentProblem problem}) = _BlockedDocument;

  factory BlockedDocument.fromJson(Map<String, dynamic> json) => _$BlockedDocumentFromJson(json);
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
    @Default(<BlockedDocument>[]) List<BlockedDocument> blockedDocuments,
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
    @Default(<BlockedDocument>[]) List<BlockedDocument> blockedDocuments,
    @Default(<DriverDocument>[]) List<DriverDocument> documents,
  }) = _AdminDriver;

  factory AdminDriver.fromJson(Map<String, dynamic> json) => _$AdminDriverFromJson(json);
}

/// 010: zona aproximada de un Conductor Elegido libre (pin dorado).
@freezed
abstract class DriverZone with _$DriverZone {
  const factory DriverZone({required String cell, required double lat, required double lng}) = _DriverZone;

  factory DriverZone.fromJson(Map<String, dynamic> json) => _$DriverZoneFromJson(json);
}

@freezed
abstract class ChosenDriver with _$ChosenDriver {
  const factory ChosenDriver({
    required String driverId,
    required String displayName,
    required String vehicleDescription,
    required DriverPresence presence,
    DateTime? busyUntilEstimate,

    /// 006: cooperativa activa del conductor, si tiene (selector de despacho).
    CooperativeRef? cooperative,

    /// 010: zona aproximada (centro de su hexágono) si está libre; nunca su posición.
    DriverZone? zone,
  }) = _ChosenDriver;

  factory ChosenDriver.fromJson(Map<String, dynamic> json) => _$ChosenDriverFromJson(json);
}

/// Tabla de tarifas de una ciudad (`PUT /v1/admin/fare-tables/{cityCode}`).
@freezed
abstract class FareTableInput with _$FareTableInput {
  const factory FareTableInput({
    required String currency,
    required int baseMinor,
    required int perKmMinor,
    required int perMinuteMinor,
    required int minimumMinor,
    @Default(1) int roundingMinor,
  }) = _FareTableInput;

  factory FareTableInput.fromJson(Map<String, dynamic> json) => _$FareTableInputFromJson(json);
}

/// 008: origen de una afiliación (contracts/api.yaml#AffiliationSource).
enum AffiliationSource {
  @JsonValue('qr_scan')
  qrScan,
  @JsonValue('post_trip')
  postTrip,
  link,
}

/// 008: preferencias de despacho del conductor (`/v1/driver/dispatch-settings`).
@freezed
abstract class DispatchSettings with _$DispatchSettings {
  const factory DispatchSettings({
    @Default(false) bool acceptsZonePool,
    @Default(0) int preferentialDiscountPct,
    @Default('') String affiliateLink,
  }) = _DispatchSettings;

  factory DispatchSettings.fromJson(Map<String, dynamic> json) => _$DispatchSettingsFromJson(json);
}

/// Pasajero de la cartera del conductor (`GET /v1/driver/clients`).
@freezed
abstract class DriverClient with _$DriverClient {
  const factory DriverClient({
    required String passengerId,
    required String displayName,
    required DateTime affiliatedAt,

    /// 008: cómo llegó a la cartera.
    @Default(AffiliationSource.qrScan) AffiliationSource source,
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

    /// 008: tarifa sin descuento; con [preferentialDiscountPct] > 0, [suggestedFareMinor] ya lo aplica.
    int? listFareMinor,
    @Default(0) int preferentialDiscountPct,
  }) = _FareQuote;

  factory FareQuote.fromJson(Map<String, dynamic> json) => _$FareQuoteFromJson(json);
}

enum ProposalParty { driver, passenger }

enum ProposalStatus { open, accepted, rejected, superseded, expired }

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
    // 006: despacho y delegación (RN-KYQ-008).
    @Default(TripDispatch.chosenDriver) TripDispatch dispatch,
    String? requestedDriverId,

    /// Nombre del conductor actual; cambia si la solicitud pasa a un compañero.
    String? driverName,
    String? cooperativeId,
    String? cooperativeName,
    @Default(false) bool allowDelegation,
    @Default(0) int handoverCount,
    @Default(false) bool canDelegate,
    // 008: tarifa de lista y descuento preferencial aplicado (RN-KYQ-013).
    int? listFareMinor,
    @Default(0) int preferentialDiscountPct,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}

/// Credenciales de la sala de voz del viaje (`POST /v1/trips/{tripId}/ptt/token`).
@freezed
abstract class PttCredentials with _$PttCredentials {
  const factory PttCredentials({required String url, required String token, required String room, DateTime? closesAt}) =
      _PttCredentials;

  factory PttCredentials.fromJson(Map<String, dynamic> json) => _$PttCredentialsFromJson(json);
}

/// 006: lectura de la delegación del viaje.
extension TripDelegation on Trip {
  /// La solicitud la atiende un compañero de la cooperativa y no el Conductor Elegido pedido. En la
  /// bolsa zonal (008) pasar al siguiente conductor cercano no es una delegación.
  bool get isDelegated =>
      dispatch != TripDispatch.zonePool && requestedDriverId != null && requestedDriverId != driverId;
}
