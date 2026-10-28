// Modelos de specs/002-driver-onboarding-billing/contracts/api.yaml: alta, KYC, suscripción,
// costos y avisos.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';

part 'onboarding_models.freezed.dart';
part 'onboarding_models.g.dart';

/// Estado de alta derivado de los documentos (`GET /v1/driver/onboarding`).
enum OnboardingStatus {
  @JsonValue('profile_incomplete')
  profileIncomplete,
  @JsonValue('documents_pending')
  documentsPending,
  @JsonValue('in_review')
  inReview,
  @JsonValue('documents_ok')
  documentsOk,
}

enum DocumentStatus { uploading, submitted, approved, rejected, superseded }

/// Estado de la suscripción en las rutas de 002 (distinto de [SubscriptionStatus] de 001).
enum BillingStatus { active, grace, suspended, unpaid }

enum PaymentMethod { bold, manual }

enum PaymentStatus {
  created,
  processing,
  approved,
  rejected,
  expired,
  voided,
  @JsonValue('needs_review')
  needsReview,
}

/// Pago aún sin respuesta definitiva de Bold.
extension PaymentStatusX on PaymentStatus {
  bool get inProgress => this == PaymentStatus.created || this == PaymentStatus.processing;
}

/// Conceptos de costo medidos (RN-KYQ-004, R8).
abstract final class CostConcepts {
  static const voiceMinute = 'voice_minute';
  static const realtimeEvent = 'realtime_event';
  static const routeRequest = 'route_request';
  static const fixedMonthly = 'fixed_monthly';
  static const all = [voiceMinute, realtimeEvent, routeRequest, fixedMonthly];
}

/// Vehículo del conductor. Los conductores de 001 pueden tener solo la placa.
@freezed
abstract class Vehicle with _$Vehicle {
  const factory Vehicle({String? plate, String? brand, String? model, String? color, int? year}) = _Vehicle;

  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);
}

/// Foto de un documento con su URL firmada de lectura (solo en el expediente del panel).
@freezed
abstract class DocumentPhoto with _$DocumentPhoto {
  const factory DocumentPhoto({required DocSide side, required String url}) = _DocumentPhoto;

  factory DocumentPhoto.fromJson(Map<String, dynamic> json) => _$DocumentPhotoFromJson(json);
}

/// Un envío de documento (una versión). Fechas sin hora en `expires_at` y `exempt_until`.
@freezed
abstract class KycDocument with _$KycDocument {
  const factory KycDocument({
    required String id,
    required DocType docType,
    String? number,
    DateTime? expiresAt,
    DateTime? exemptUntil,
    required DocumentStatus status,
    @Default(false) bool expired,

    /// Migrado de 001 o marcador sin fotos: sigue valiendo, pero hay que subir el real.
    @Default(false) bool legacy,
    String? rejectReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    @Default(<DocumentPhoto>[]) List<DocumentPhoto> photos,
  }) = _KycDocument;

  factory KycDocument.fromJson(Map<String, dynamic> json) => _$KycDocumentFromJson(json);
}

/// Un tipo obligatorio (`DocumentSlot`): [current] es el aprobado y [latest] el envío más
/// reciente si no es el aprobado (null si no hay reenvío).
@freezed
abstract class OnboardingDocument with _$OnboardingDocument {
  const factory OnboardingDocument({
    required DocType docType,
    String? label,
    KycDocument? current,
    KycDocument? latest,
    @Default(0) int rejectedCount,

    /// Tras 3 rechazos del mismo documento.
    @Default(false) bool suggestSupport,
  }) = _OnboardingDocument;

  factory OnboardingDocument.fromJson(Map<String, dynamic> json) => _$OnboardingDocumentFromJson(json);
}

@freezed
abstract class Onboarding with _$Onboarding {
  const factory Onboarding({
    required OnboardingStatus status,
    Vehicle? vehicle,
    @Default(<OnboardingDocument>[]) List<OnboardingDocument> documents,
    @Default(<BlockedDocument>[]) List<BlockedDocument> blockedDocuments,
    BillingStatus? subscriptionStatus,
    DateTime? paidUntil,
    bool? canGoOnline,
  }) = _Onboarding;

  factory Onboarding.fromJson(Map<String, dynamic> json) => _$OnboardingFromJson(json);
}

/// URL firmada para subir una foto (PUT `image/jpeg`, caduca a los 10 min).
@freezed
abstract class DocumentUpload with _$DocumentUpload {
  const factory DocumentUpload({required DocSide side, required String url}) = _DocumentUpload;

  factory DocumentUpload.fromJson(Map<String, dynamic> json) => _$DocumentUploadFromJson(json);
}

/// Respuesta de `POST /v1/driver/documents`.
@freezed
abstract class CreatedDocument with _$CreatedDocument {
  const factory CreatedDocument({
    required KycDocument document,
    @Default(<DocumentUpload>[]) List<DocumentUpload> uploads,
  }) = _CreatedDocument;

  factory CreatedDocument.fromJson(Map<String, dynamic> json) => _$CreatedDocumentFromJson(json);
}

@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    required String id,
    required int amountMinor,
    required String currency,
    required PaymentMethod method,
    required PaymentStatus status,
    String? checkoutUrl,
    String? paymentMethodDetail,
    String? manualReference,

    /// Solo en el panel: por qué quedó en `needs_review`.
    String? reviewNote,
    DateTime? coversFrom,
    DateTime? coversUntil,
    String? voidReason,
    required DateTime createdAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}

@freezed
abstract class Price with _$Price {
  const factory Price({required int amountMinor, required String currency}) = _Price;

  factory Price.fromJson(Map<String, dynamic> json) => _$PriceFromJson(json);
}

/// `GET /v1/driver/subscription`: estado, precio vigente y pagos, recientes primero.
@freezed
abstract class SubscriptionView with _$SubscriptionView {
  const factory SubscriptionView({
    required BillingStatus status,
    DateTime? paidUntil,
    DateTime? graceUntil,
    Price? price,

    /// Documentos al día, precio definido y Bold activo.
    @Default(false) bool canPay,
    @Default(<Payment>[]) List<Payment> payments,
  }) = _SubscriptionView;

  factory SubscriptionView.fromJson(Map<String, dynamic> json) => _$SubscriptionViewFromJson(json);
}

/// Uso y costo de un concepto en el mes. [usage] es 1 para el fijo mensual.
@freezed
abstract class CostItem with _$CostItem {
  const factory CostItem({required String concept, @Default(0) double usage, @Default(0) double costMinor}) = _CostItem;

  factory CostItem.fromJson(Map<String, dynamic> json) => _$CostItemFromJson(json);
}

/// Costo medido de un conductor en un mes frente a lo que pagó (RN-KYQ-004). En el panel lleva
/// además el conductor.
@freezed
abstract class CostBreakdown with _$CostBreakdown {
  const factory CostBreakdown({
    String? driverId,
    String? displayName,
    @Default('') String month,
    @Default('COP') String currency,
    @Default(0) int paidMinor,
    @Default(<CostItem>[]) List<CostItem> items,
    @Default(0) double totalCostMinor,
    @Default(0) double marginMinor,
    bool? negativeMargin,
  }) = _CostBreakdown;

  factory CostBreakdown.fromJson(Map<String, dynamic> json) => _$CostBreakdownFromJson(json);
}

/// Aviso en la app (documentos, pagos). Sin datos sensibles en título ni cuerpo.
@freezed
abstract class Notice with _$Notice {
  const factory Notice({
    required String id,
    required String kind,
    required String title,
    @Default('') String body,
    required DateTime createdAt,
    DateTime? readAt,
  }) = _Notice;

  factory Notice.fromJson(Map<String, dynamic> json) => _$NoticeFromJson(json);
}

/// Fila de la cola de revisión KYC (`GET /v1/admin/kyc/queue`).
@freezed
abstract class KycQueueEntry with _$KycQueueEntry {
  const factory KycQueueEntry({
    required String driverId,
    required String displayName,
    String? vehiclePlate,
    @JsonKey(name: 'pending_documents') @Default(0) int pendingCount,
    DateTime? oldestSubmittedAt,
  }) = _KycQueueEntry;

  factory KycQueueEntry.fromJson(Map<String, dynamic> json) => _$KycQueueEntryFromJson(json);
}

/// Expediente de un conductor en el panel: por tipo, el aprobado y el envío en revisión, con las
/// URLs firmadas de sus fotos.
@freezed
abstract class KycDriverFile with _$KycDriverFile {
  const factory KycDriverFile({
    required String driverId,
    required String displayName,
    String? phoneE164,
    OnboardingStatus? status,
    Vehicle? vehicle,
    @Default(<OnboardingDocument>[]) List<OnboardingDocument> documents,
    @Default(<BlockedDocument>[]) List<BlockedDocument> blockedDocuments,
  }) = _KycDriverFile;

  factory KycDriverFile.fromJson(Map<String, dynamic> json) => _$KycDriverFileFromJson(json);
}

/// Fila de `GET /v1/admin/subscriptions`.
@freezed
abstract class AdminSubscription with _$AdminSubscription {
  const factory AdminSubscription({
    required String driverId,
    required String displayName,
    String? phoneE164,
    String? vehiclePlate,
    required BillingStatus status,
    DateTime? paidUntil,
    DateTime? graceUntil,

    /// Resumen del último pago (sin periodo ni checkout).
    Payment? lastPayment,
  }) = _AdminSubscription;

  factory AdminSubscription.fromJson(Map<String, dynamic> json) => _$AdminSubscriptionFromJson(json);
}

/// Tarifa de costo con fecha de vigencia (`/v1/admin/cost-rates`). [unitCostMicro] en
/// millonésimas de unidad mínima.
@freezed
abstract class CostRate with _$CostRate {
  const factory CostRate({
    required String concept,
    required String currency,
    required int unitCostMicro,
    required DateTime effectiveFrom,
  }) = _CostRate;

  factory CostRate.fromJson(Map<String, dynamic> json) => _$CostRateFromJson(json);
}
