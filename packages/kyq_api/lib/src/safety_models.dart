// Modelos de specs/003-sos-emergency-console/contracts/api.yaml: SOS, consola de emergencias,
// viaje compartido, contactos de emergencia y PIN de seguridad.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';

part 'safety_models.freezed.dart';
part 'safety_models.g.dart';

/// Estado de una alerta SOS.
enum SosStatus {
  open,
  claimed,
  closed,
  @JsonValue('cancelled_by_user')
  cancelledByUser,
}

/// Desenlace con el que el operador cierra el caso (FR-010).
enum SosOutcome {
  @JsonValue('false_alarm')
  falseAlarm,
  resolved,
  @JsonValue('escalated_authorities')
  escalatedAuthorities,
  @JsonValue('no_response')
  noResponse,
}

/// Valor de [SosOutcome] en la API.
String sosOutcomeToApi(SosOutcome o) => switch (o) {
  SosOutcome.falseAlarm => 'false_alarm',
  SosOutcome.resolved => 'resolved',
  SosOutcome.escalatedAuthorities => 'escalated_authorities',
  SosOutcome.noResponse => 'no_response',
};

/// Quién activó la alerta.
enum SosRole { passenger, driver }

/// Un punto de ubicación enviado durante la alerta (1 por segundo).
@freezed
abstract class SosPoint with _$SosPoint {
  const factory SosPoint({required double lat, required double lng, double? accuracyM, required DateTime recordedAt}) =
      _SosPoint;

  factory SosPoint.fromJson(Map<String, dynamic> json) => _$SosPointFromJson(json);
}

/// Ubicación guardada de una alerta (consola) o del vehículo (enlace compartido).
@freezed
abstract class SosLocation with _$SosLocation {
  const factory SosLocation({required double lat, required double lng, double? accuracyM, DateTime? at}) = _SosLocation;

  factory SosLocation.fromJson(Map<String, dynamic> json) => _$SosLocationFromJson(json);
}

/// La alerta tal como la ve quien la activó.
@freezed
abstract class SosAlertSelf with _$SosAlertSelf {
  const factory SosAlertSelf({
    required String id,

    /// null en una alerta desde Radio sin viaje (011).
    String? tripId,
    required SosStatus status,
    @Default(false) bool operatorConnected,
    @Default(false) bool escalated,
    required DateTime createdAt,
  }) = _SosAlertSelf;

  factory SosAlertSelf.fromJson(Map<String, dynamic> json) => _$SosAlertSelfFromJson(json);
}

/// Credenciales de la sala de voz SOS.
@freezed
abstract class SosVoice with _$SosVoice {
  const factory SosVoice({
    required String url,
    required String token,
    required String room,
    @Default(false) bool canPublish,
  }) = _SosVoice;

  factory SosVoice.fromJson(Map<String, dynamic> json) => _$SosVoiceFromJson(json);
}

/// Respuesta de `POST /v1/trips/{tripId}/sos`.
@freezed
abstract class SosRaise with _$SosRaise {
  const factory SosRaise({required SosAlertSelf alert, SosVoice? voice, @Default(false) bool needsPin}) = _SosRaise;

  factory SosRaise.fromJson(Map<String, dynamic> json) => _$SosRaiseFromJson(json);
}

/// Fila de la cola o del historial de la consola.
@freezed
abstract class SosAlertSummary with _$SosAlertSummary {
  const factory SosAlertSummary({
    required String id,

    /// null en una alerta desde Radio sin viaje (011).
    String? tripId,

    /// `trip` o `radio` (011).
    @Default('trip') String raisedFrom,
    required SosRole raisedRole,
    required String raisedByName,
    required SosStatus status,
    @Default(false) bool cancelWithoutPin,
    String? claimedBy,
    String? claimedByName,
    SosOutcome? outcome,
    @Default(false) bool escalated,
    @Default(false) bool hasRecording,
    required DateTime createdAt,
    DateTime? claimedAt,
    DateTime? closedAt,
    SosLocation? lastLocation,
  }) = _SosAlertSummary;

  factory SosAlertSummary.fromJson(Map<String, dynamic> json) => _$SosAlertSummaryFromJson(json);
}

@freezed
abstract class SosNote with _$SosNote {
  const factory SosNote({
    required String id,
    required String operatorId,
    required String operatorName,
    required String body,
    required DateTime createdAt,
  }) = _SosNote;

  factory SosNote.fromJson(Map<String, dynamic> json) => _$SosNoteFromJson(json);
}

@freezed
abstract class SosPerson with _$SosPerson {
  const factory SosPerson({required String userId, required String name}) = _SosPerson;

  factory SosPerson.fromJson(Map<String, dynamic> json) => _$SosPersonFromJson(json);
}

@freezed
abstract class SosDriver with _$SosDriver {
  const factory SosDriver({
    required String userId,
    required String name,
    required String vehiclePlate,
    required String vehicleDescription,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleColor,
  }) = _SosDriver;

  factory SosDriver.fromJson(Map<String, dynamic> json) => _$SosDriverFromJson(json);
}

@freezed
abstract class SosTrip with _$SosTrip {
  const factory SosTrip({required String status, required GeoPoint pickup, required GeoPoint dropoff}) = _SosTrip;

  factory SosTrip.fromJson(Map<String, dynamic> json) => _$SosTripFromJson(json);
}

/// Contacto de emergencia (máximo 3 por usuario).
@freezed
abstract class EmergencyContact with _$EmergencyContact {
  const factory EmergencyContact({required String name, required String phoneE164}) = _EmergencyContact;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => _$EmergencyContactFromJson(json);
}

/// Detalle de la alerta para el operador (FR-009).
@freezed
abstract class SosAlertDetail with _$SosAlertDetail {
  const factory SosAlertDetail({
    required String id,

    /// null en una alerta desde Radio sin viaje (011).
    String? tripId,

    /// `trip` o `radio` (011).
    @Default('trip') String raisedFrom,
    required SosRole raisedRole,
    required String raisedByName,
    required SosStatus status,
    @Default(false) bool cancelWithoutPin,
    String? claimedBy,
    String? claimedByName,
    SosOutcome? outcome,
    @Default(false) bool escalated,
    @Default(false) bool hasRecording,
    required DateTime createdAt,
    DateTime? claimedAt,
    DateTime? closedAt,
    SosLocation? lastLocation,
    @JsonKey(name: 'raised_by_phone_e164') @Default('') String raisedByPhone,
    @Default([]) List<EmergencyContact> emergencyContacts,
    required SosTrip trip,
    required SosPerson passenger,
    required SosDriver driver,
    @Default([]) List<SosLocation> track,
    @Default([]) List<SosNote> notes,
    @Default([]) List<String> relatedAlertIds,
    String? recordingUrl,
    @Default(0) int raisedByAlerts,
    @Default(0) int raisedByFalseAlarms,
  }) = _SosAlertDetail;

  factory SosAlertDetail.fromJson(Map<String, dynamic> json) => _$SosAlertDetailFromJson(json);
}

/// Enlace del viaje en vivo.
@freezed
abstract class ShareLink with _$ShareLink {
  const factory ShareLink({required String token, required String url}) = _ShareLink;

  factory ShareLink.fromJson(Map<String, dynamic> json) => _$ShareLinkFromJson(json);
}
