// Modelos de 009 (operación del panel): inspección de viajes, centro de soporte, megáfono,
// sesiones sin fallos y dominios espejo (specs/001-…/contracts/api.yaml).
import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';

part 'ops_models.freezed.dart';
part 'ops_models.g.dart';

/// Participante sin datos de contacto.
@freezed
abstract class PersonRef with _$PersonRef {
  const factory PersonRef({required String id, required String displayName}) = _PersonRef;

  factory PersonRef.fromJson(Map<String, dynamic> json) => _$PersonRefFromJson(json);
}

@freezed
abstract class TripStep with _$TripStep {
  const factory TripStep({required String status, required DateTime at}) = _TripStep;

  factory TripStep.fromJson(Map<String, dynamic> json) => _$TripStepFromJson(json);
}

@freezed
abstract class InspectionPosition with _$InspectionPosition {
  const factory InspectionPosition({
    required double lat,
    required double lng,
    required DateTime locationAt,
    @Default(false) bool stale,
  }) = _InspectionPosition;

  factory InspectionPosition.fromJson(Map<String, dynamic> json) => _$InspectionPositionFromJson(json);
}

@freezed
abstract class InspectionPayment with _$InspectionPayment {
  const factory InspectionPayment({required String status, String? method}) = _InspectionPayment;

  factory InspectionPayment.fromJson(Map<String, dynamic> json) => _$InspectionPaymentFromJson(json);
}

@freezed
abstract class InspectionSos with _$InspectionSos {
  const factory InspectionSos({required String id, required String status}) = _InspectionSos;

  factory InspectionSos.fromJson(Map<String, dynamic> json) => _$InspectionSosFromJson(json);
}

/// `GET /v1/admin/trips/{tripId}` (009 FR-002): sin teléfonos.
@freezed
abstract class TripInspection with _$TripInspection {
  const factory TripInspection({
    required String tripId,
    required String status,
    required bool active,
    String? cancelReason,
    required String dispatch,
    @Default(0) int handoverCount,
    String? cooperativeName,
    required PersonRef passenger,
    required PersonRef driver,
    required String vehiclePlate,
    @Default('') String vehicleDescription,
    required GeoPoint pickup,
    required GeoPoint dropoff,
    required int distanceM,
    required int durationS,
    required String currency,
    required int listFareMinor,
    required int suggestedFareMinor,
    int? agreedFareMinor,
    @Default(0) int preferentialDiscountPct,
    @Default(<TripStep>[]) List<TripStep> steps,
    InspectionPosition? driverPosition,
    InspectionPayment? payment,
    InspectionSos? openSos,
    required DateTime generatedAt,
  }) = _TripInspection;

  factory TripInspection.fromJson(Map<String, dynamic> json) => _$TripInspectionFromJson(json);
}

/// Temas de un caso de soporte (009 FR-005).
enum SupportTopic {
  trip,
  payment,
  @JsonValue('lost_item')
  lostItem,
  safety,
  account,
  other,
}

/// Valor de [SupportTopic] en la API.
String supportTopicToApi(SupportTopic t) => switch (t) {
  SupportTopic.lostItem => 'lost_item',
  _ => t.name,
};

/// Estados de un caso (009 FR-007).
enum SupportStatus {
  open,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('waiting_user')
  waitingUser,
  resolved,
  closed,
}

/// Valor de [SupportStatus] en la API.
String supportStatusToApi(SupportStatus s) => switch (s) {
  SupportStatus.inProgress => 'in_progress',
  SupportStatus.waitingUser => 'waiting_user',
  _ => s.name,
};

@freezed
abstract class SupportCase with _$SupportCase {
  const factory SupportCase({
    required String id,
    required SupportTopic topic,
    required String subject,
    required SupportStatus status,
    required PersonRef user,
    required String userRole,
    PersonRef? counterpart,
    String? tripId,
    String? tripPaymentId,
    PersonRef? assignedTo,
    required DateTime createdAt,
    required DateTime lastMessageAt,
    DateTime? lastUserMessageAt,

    /// El último mensaje visible es del usuario: espera respuesta del soporte.
    @Default(false) bool awaitingReply,
    DateTime? resolvedAt,
    DateTime? closedAt,
  }) = _SupportCase;

  factory SupportCase.fromJson(Map<String, dynamic> json) => _$SupportCaseFromJson(json);
}

enum SupportAuthor { user, admin, system }

@freezed
abstract class SupportMessage with _$SupportMessage {
  const factory SupportMessage({
    required String id,
    required SupportAuthor authorKind,
    String? authorName,
    @Default(false) bool mine,
    required String body,
    @Default(false) bool internal,
    required DateTime createdAt,
  }) = _SupportMessage;

  factory SupportMessage.fromJson(Map<String, dynamic> json) => _$SupportMessageFromJson(json);
}

/// Caso con su conversación (`SupportCaseDetail`).
class SupportCaseDetail {
  const SupportCaseDetail({required this.supportCase, required this.messages});

  factory SupportCaseDetail.fromJson(Map<String, dynamic> json) => SupportCaseDetail(
    supportCase: SupportCase.fromJson(json),
    messages: [
      for (final m in (json['messages'] as List? ?? const [])) SupportMessage.fromJson(m as Map<String, dynamic>),
    ],
  );

  final SupportCase supportCase;
  final List<SupportMessage> messages;
}

/// Viaje reciente para asociar a un caso.
@freezed
abstract class SupportTripRef with _$SupportTripRef {
  const factory SupportTripRef({
    required String id,
    required String status,
    required DateTime createdAt,
    required String otherParty,
  }) = _SupportTripRef;

  factory SupportTripRef.fromJson(Map<String, dynamic> json) => _$SupportTripRefFromJson(json);
}

/// `POST /v1/admin/megaphone`: en el aire hasta [endsAt].
@freezed
abstract class MegaphoneOnAir with _$MegaphoneOnAir {
  const factory MegaphoneOnAir({
    required String broadcastId,
    required String url,
    required String token,
    required DateTime endsAt,
    required int recipients,
  }) = _MegaphoneOnAir;

  factory MegaphoneOnAir.fromJson(Map<String, dynamic> json) => _$MegaphoneOnAirFromJson(json);
}

@freezed
abstract class MegaphoneBroadcast with _$MegaphoneBroadcast {
  const factory MegaphoneBroadcast({
    required String id,
    required String adminName,
    @Default(<String>[]) List<String> cells,
    required int resolution,
    required DateTime startedAt,
    DateTime? endedAt,
    int? durationS,
    @Default(0) int recipients,
  }) = _MegaphoneBroadcast;

  factory MegaphoneBroadcast.fromJson(Map<String, dynamic> json) => _$MegaphoneBroadcastFromJson(json);
}

@freezed
abstract class AppSessions with _$AppSessions {
  const factory AppSessions({
    required String app,
    double? crashFree24h,
    double? crashFree7d,
    String? topRelease,
    @Default(false) bool belowTarget,
    @Default('') String link,
  }) = _AppSessions;

  factory AppSessions.fromJson(Map<String, dynamic> json) => _$AppSessionsFromJson(json);
}

/// `GET /v1/admin/health/sessions` (009 FR-017): `ok`, `not_configured` o `unavailable`.
@freezed
abstract class SessionsReport with _$SessionsReport {
  const factory SessionsReport({
    required String status,
    required DateTime checkedAt,
    @Default(0.99) double target,
    @Default(<AppSessions>[]) List<AppSessions> apps,
  }) = _SessionsReport;

  factory SessionsReport.fromJson(Map<String, dynamic> json) => _$SessionsReportFromJson(json);
}

@freezed
abstract class MirrorDomain with _$MirrorDomain {
  const factory MirrorDomain({
    required String id,
    required String apiUrl,
    required String realtimeUrl,
    required int position,
    required bool active,

    /// `ok`, `down` o `unchecked`.
    @Default('unchecked') String status,
    int? latencyMs,
  }) = _MirrorDomain;

  factory MirrorDomain.fromJson(Map<String, dynamic> json) => _$MirrorDomainFromJson(json);
}

@freezed
abstract class MirrorDomainListing with _$MirrorDomainListing {
  const factory MirrorDomainListing({
    required int version,
    required bool signingConfigured,
    String? publicKey,
    @Default(<MirrorDomain>[]) List<MirrorDomain> domains,
  }) = _MirrorDomainListing;

  factory MirrorDomainListing.fromJson(Map<String, dynamic> json) => _$MirrorDomainListingFromJson(json);
}

/// `GET /v1/domains`: lista firmada; [payload] son los bytes exactos que se firmaron.
@freezed
abstract class SignedDomainList with _$SignedDomainList {
  const factory SignedDomainList({required String payload, required String signature}) = _SignedDomainList;

  factory SignedDomainList.fromJson(Map<String, dynamic> json) => _$SignedDomainListFromJson(json);
}
