// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Vehicle _$VehicleFromJson(Map<String, dynamic> json) => _Vehicle(
  plate: json['plate'] as String?,
  brand: json['brand'] as String?,
  model: json['model'] as String?,
  color: json['color'] as String?,
  year: (json['year'] as num?)?.toInt(),
);

Map<String, dynamic> _$VehicleToJson(_Vehicle instance) => <String, dynamic>{
  'plate': instance.plate,
  'brand': instance.brand,
  'model': instance.model,
  'color': instance.color,
  'year': instance.year,
};

_DocumentPhoto _$DocumentPhotoFromJson(Map<String, dynamic> json) =>
    _DocumentPhoto(side: $enumDecode(_$DocSideEnumMap, json['side']), url: json['url'] as String);

Map<String, dynamic> _$DocumentPhotoToJson(_DocumentPhoto instance) => <String, dynamic>{
  'side': _$DocSideEnumMap[instance.side]!,
  'url': instance.url,
};

const _$DocSideEnumMap = {DocSide.front: 'front', DocSide.back: 'back'};

_KycDocument _$KycDocumentFromJson(Map<String, dynamic> json) => _KycDocument(
  id: json['id'] as String,
  docType: $enumDecode(_$DocTypeEnumMap, json['doc_type']),
  number: json['number'] as String?,
  expiresAt: json['expires_at'] == null ? null : DateTime.parse(json['expires_at'] as String),
  exemptUntil: json['exempt_until'] == null ? null : DateTime.parse(json['exempt_until'] as String),
  status: $enumDecode(_$DocumentStatusEnumMap, json['status']),
  expired: json['expired'] as bool? ?? false,
  legacy: json['legacy'] as bool? ?? false,
  rejectReason: json['reject_reason'] as String?,
  submittedAt: json['submitted_at'] == null ? null : DateTime.parse(json['submitted_at'] as String),
  reviewedAt: json['reviewed_at'] == null ? null : DateTime.parse(json['reviewed_at'] as String),
  photos:
      (json['photos'] as List<dynamic>?)?.map((e) => DocumentPhoto.fromJson(e as Map<String, dynamic>)).toList() ??
      const <DocumentPhoto>[],
);

Map<String, dynamic> _$KycDocumentToJson(_KycDocument instance) => <String, dynamic>{
  'id': instance.id,
  'doc_type': _$DocTypeEnumMap[instance.docType]!,
  'number': instance.number,
  'expires_at': instance.expiresAt?.toIso8601String(),
  'exempt_until': instance.exemptUntil?.toIso8601String(),
  'status': _$DocumentStatusEnumMap[instance.status]!,
  'expired': instance.expired,
  'legacy': instance.legacy,
  'reject_reason': instance.rejectReason,
  'submitted_at': instance.submittedAt?.toIso8601String(),
  'reviewed_at': instance.reviewedAt?.toIso8601String(),
  'photos': instance.photos.map((e) => e.toJson()).toList(),
};

const _$DocTypeEnumMap = {
  DocType.nationalId: 'national_id',
  DocType.license: 'license',
  DocType.mandatoryInsurance: 'mandatory_insurance',
  DocType.technicalInspection: 'technical_inspection',
  DocType.vehicleRegistration: 'vehicle_registration',
};

const _$DocumentStatusEnumMap = {
  DocumentStatus.uploading: 'uploading',
  DocumentStatus.submitted: 'submitted',
  DocumentStatus.approved: 'approved',
  DocumentStatus.rejected: 'rejected',
  DocumentStatus.superseded: 'superseded',
};

_OnboardingDocument _$OnboardingDocumentFromJson(Map<String, dynamic> json) => _OnboardingDocument(
  docType: $enumDecode(_$DocTypeEnumMap, json['doc_type']),
  label: json['label'] as String?,
  current: json['current'] == null ? null : KycDocument.fromJson(json['current'] as Map<String, dynamic>),
  latest: json['latest'] == null ? null : KycDocument.fromJson(json['latest'] as Map<String, dynamic>),
  rejectedCount: (json['rejected_count'] as num?)?.toInt() ?? 0,
  suggestSupport: json['suggest_support'] as bool? ?? false,
);

Map<String, dynamic> _$OnboardingDocumentToJson(_OnboardingDocument instance) => <String, dynamic>{
  'doc_type': _$DocTypeEnumMap[instance.docType]!,
  'label': instance.label,
  'current': instance.current?.toJson(),
  'latest': instance.latest?.toJson(),
  'rejected_count': instance.rejectedCount,
  'suggest_support': instance.suggestSupport,
};

_Onboarding _$OnboardingFromJson(Map<String, dynamic> json) => _Onboarding(
  status: $enumDecode(_$OnboardingStatusEnumMap, json['status']),
  vehicle: json['vehicle'] == null ? null : Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
  documents:
      (json['documents'] as List<dynamic>?)
          ?.map((e) => OnboardingDocument.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OnboardingDocument>[],
  blockedDocuments:
      (json['blocked_documents'] as List<dynamic>?)
          ?.map((e) => BlockedDocument.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BlockedDocument>[],
  subscriptionStatus: $enumDecodeNullable(_$BillingStatusEnumMap, json['subscription_status']),
  paidUntil: json['paid_until'] == null ? null : DateTime.parse(json['paid_until'] as String),
  canGoOnline: json['can_go_online'] as bool?,
);

Map<String, dynamic> _$OnboardingToJson(_Onboarding instance) => <String, dynamic>{
  'status': _$OnboardingStatusEnumMap[instance.status]!,
  'vehicle': instance.vehicle?.toJson(),
  'documents': instance.documents.map((e) => e.toJson()).toList(),
  'blocked_documents': instance.blockedDocuments.map((e) => e.toJson()).toList(),
  'subscription_status': _$BillingStatusEnumMap[instance.subscriptionStatus],
  'paid_until': instance.paidUntil?.toIso8601String(),
  'can_go_online': instance.canGoOnline,
};

const _$OnboardingStatusEnumMap = {
  OnboardingStatus.profileIncomplete: 'profile_incomplete',
  OnboardingStatus.documentsPending: 'documents_pending',
  OnboardingStatus.inReview: 'in_review',
  OnboardingStatus.documentsOk: 'documents_ok',
};

const _$BillingStatusEnumMap = {
  BillingStatus.active: 'active',
  BillingStatus.grace: 'grace',
  BillingStatus.suspended: 'suspended',
  BillingStatus.unpaid: 'unpaid',
};

_DocumentUpload _$DocumentUploadFromJson(Map<String, dynamic> json) =>
    _DocumentUpload(side: $enumDecode(_$DocSideEnumMap, json['side']), url: json['url'] as String);

Map<String, dynamic> _$DocumentUploadToJson(_DocumentUpload instance) => <String, dynamic>{
  'side': _$DocSideEnumMap[instance.side]!,
  'url': instance.url,
};

_CreatedDocument _$CreatedDocumentFromJson(Map<String, dynamic> json) => _CreatedDocument(
  document: KycDocument.fromJson(json['document'] as Map<String, dynamic>),
  uploads:
      (json['uploads'] as List<dynamic>?)?.map((e) => DocumentUpload.fromJson(e as Map<String, dynamic>)).toList() ??
      const <DocumentUpload>[],
);

Map<String, dynamic> _$CreatedDocumentToJson(_CreatedDocument instance) => <String, dynamic>{
  'document': instance.document.toJson(),
  'uploads': instance.uploads.map((e) => e.toJson()).toList(),
};

_Payment _$PaymentFromJson(Map<String, dynamic> json) => _Payment(
  id: json['id'] as String,
  amountMinor: (json['amount_minor'] as num).toInt(),
  currency: json['currency'] as String,
  method: $enumDecode(_$PaymentMethodEnumMap, json['method']),
  status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
  checkoutUrl: json['checkout_url'] as String?,
  paymentMethodDetail: json['payment_method_detail'] as String?,
  manualReference: json['manual_reference'] as String?,
  reviewNote: json['review_note'] as String?,
  coversFrom: json['covers_from'] == null ? null : DateTime.parse(json['covers_from'] as String),
  coversUntil: json['covers_until'] == null ? null : DateTime.parse(json['covers_until'] as String),
  voidReason: json['void_reason'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$PaymentToJson(_Payment instance) => <String, dynamic>{
  'id': instance.id,
  'amount_minor': instance.amountMinor,
  'currency': instance.currency,
  'method': _$PaymentMethodEnumMap[instance.method]!,
  'status': _$PaymentStatusEnumMap[instance.status]!,
  'checkout_url': instance.checkoutUrl,
  'payment_method_detail': instance.paymentMethodDetail,
  'manual_reference': instance.manualReference,
  'review_note': instance.reviewNote,
  'covers_from': instance.coversFrom?.toIso8601String(),
  'covers_until': instance.coversUntil?.toIso8601String(),
  'void_reason': instance.voidReason,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$PaymentMethodEnumMap = {PaymentMethod.bold: 'bold', PaymentMethod.manual: 'manual'};

const _$PaymentStatusEnumMap = {
  PaymentStatus.created: 'created',
  PaymentStatus.processing: 'processing',
  PaymentStatus.approved: 'approved',
  PaymentStatus.rejected: 'rejected',
  PaymentStatus.expired: 'expired',
  PaymentStatus.voided: 'voided',
  PaymentStatus.needsReview: 'needs_review',
};

_Price _$PriceFromJson(Map<String, dynamic> json) =>
    _Price(amountMinor: (json['amount_minor'] as num).toInt(), currency: json['currency'] as String);

Map<String, dynamic> _$PriceToJson(_Price instance) => <String, dynamic>{
  'amount_minor': instance.amountMinor,
  'currency': instance.currency,
};

_SubscriptionView _$SubscriptionViewFromJson(Map<String, dynamic> json) => _SubscriptionView(
  status: $enumDecode(_$BillingStatusEnumMap, json['status']),
  paidUntil: json['paid_until'] == null ? null : DateTime.parse(json['paid_until'] as String),
  graceUntil: json['grace_until'] == null ? null : DateTime.parse(json['grace_until'] as String),
  price: json['price'] == null ? null : Price.fromJson(json['price'] as Map<String, dynamic>),
  canPay: json['can_pay'] as bool? ?? false,
  payments:
      (json['payments'] as List<dynamic>?)?.map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList() ??
      const <Payment>[],
);

Map<String, dynamic> _$SubscriptionViewToJson(_SubscriptionView instance) => <String, dynamic>{
  'status': _$BillingStatusEnumMap[instance.status]!,
  'paid_until': instance.paidUntil?.toIso8601String(),
  'grace_until': instance.graceUntil?.toIso8601String(),
  'price': instance.price?.toJson(),
  'can_pay': instance.canPay,
  'payments': instance.payments.map((e) => e.toJson()).toList(),
};

_CostItem _$CostItemFromJson(Map<String, dynamic> json) => _CostItem(
  concept: json['concept'] as String,
  usage: (json['usage'] as num?)?.toDouble() ?? 0,
  costMinor: (json['cost_minor'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$CostItemToJson(_CostItem instance) => <String, dynamic>{
  'concept': instance.concept,
  'usage': instance.usage,
  'cost_minor': instance.costMinor,
};

_CostBreakdown _$CostBreakdownFromJson(Map<String, dynamic> json) => _CostBreakdown(
  driverId: json['driver_id'] as String?,
  displayName: json['display_name'] as String?,
  month: json['month'] as String? ?? '',
  currency: json['currency'] as String? ?? 'COP',
  paidMinor: (json['paid_minor'] as num?)?.toInt() ?? 0,
  items:
      (json['items'] as List<dynamic>?)?.map((e) => CostItem.fromJson(e as Map<String, dynamic>)).toList() ??
      const <CostItem>[],
  totalCostMinor: (json['total_cost_minor'] as num?)?.toDouble() ?? 0,
  marginMinor: (json['margin_minor'] as num?)?.toDouble() ?? 0,
  negativeMargin: json['negative_margin'] as bool?,
);

Map<String, dynamic> _$CostBreakdownToJson(_CostBreakdown instance) => <String, dynamic>{
  'driver_id': instance.driverId,
  'display_name': instance.displayName,
  'month': instance.month,
  'currency': instance.currency,
  'paid_minor': instance.paidMinor,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total_cost_minor': instance.totalCostMinor,
  'margin_minor': instance.marginMinor,
  'negative_margin': instance.negativeMargin,
};

_Notice _$NoticeFromJson(Map<String, dynamic> json) => _Notice(
  id: json['id'] as String,
  kind: json['kind'] as String,
  title: json['title'] as String,
  body: json['body'] as String? ?? '',
  createdAt: DateTime.parse(json['created_at'] as String),
  readAt: json['read_at'] == null ? null : DateTime.parse(json['read_at'] as String),
);

Map<String, dynamic> _$NoticeToJson(_Notice instance) => <String, dynamic>{
  'id': instance.id,
  'kind': instance.kind,
  'title': instance.title,
  'body': instance.body,
  'created_at': instance.createdAt.toIso8601String(),
  'read_at': instance.readAt?.toIso8601String(),
};

_KycQueueEntry _$KycQueueEntryFromJson(Map<String, dynamic> json) => _KycQueueEntry(
  driverId: json['driver_id'] as String,
  displayName: json['display_name'] as String,
  vehiclePlate: json['vehicle_plate'] as String?,
  pendingCount: (json['pending_documents'] as num?)?.toInt() ?? 0,
  oldestSubmittedAt: json['oldest_submitted_at'] == null ? null : DateTime.parse(json['oldest_submitted_at'] as String),
);

Map<String, dynamic> _$KycQueueEntryToJson(_KycQueueEntry instance) => <String, dynamic>{
  'driver_id': instance.driverId,
  'display_name': instance.displayName,
  'vehicle_plate': instance.vehiclePlate,
  'pending_documents': instance.pendingCount,
  'oldest_submitted_at': instance.oldestSubmittedAt?.toIso8601String(),
};

_KycDriverFile _$KycDriverFileFromJson(Map<String, dynamic> json) => _KycDriverFile(
  driverId: json['driver_id'] as String,
  displayName: json['display_name'] as String,
  phoneE164: json['phone_e164'] as String?,
  status: $enumDecodeNullable(_$OnboardingStatusEnumMap, json['status']),
  vehicle: json['vehicle'] == null ? null : Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
  documents:
      (json['documents'] as List<dynamic>?)
          ?.map((e) => OnboardingDocument.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OnboardingDocument>[],
  blockedDocuments:
      (json['blocked_documents'] as List<dynamic>?)
          ?.map((e) => BlockedDocument.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BlockedDocument>[],
);

Map<String, dynamic> _$KycDriverFileToJson(_KycDriverFile instance) => <String, dynamic>{
  'driver_id': instance.driverId,
  'display_name': instance.displayName,
  'phone_e164': instance.phoneE164,
  'status': _$OnboardingStatusEnumMap[instance.status],
  'vehicle': instance.vehicle?.toJson(),
  'documents': instance.documents.map((e) => e.toJson()).toList(),
  'blocked_documents': instance.blockedDocuments.map((e) => e.toJson()).toList(),
};

_AdminSubscription _$AdminSubscriptionFromJson(Map<String, dynamic> json) => _AdminSubscription(
  driverId: json['driver_id'] as String,
  displayName: json['display_name'] as String,
  phoneE164: json['phone_e164'] as String?,
  vehiclePlate: json['vehicle_plate'] as String?,
  status: $enumDecode(_$BillingStatusEnumMap, json['status']),
  paidUntil: json['paid_until'] == null ? null : DateTime.parse(json['paid_until'] as String),
  graceUntil: json['grace_until'] == null ? null : DateTime.parse(json['grace_until'] as String),
  lastPayment: json['last_payment'] == null ? null : Payment.fromJson(json['last_payment'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AdminSubscriptionToJson(_AdminSubscription instance) => <String, dynamic>{
  'driver_id': instance.driverId,
  'display_name': instance.displayName,
  'phone_e164': instance.phoneE164,
  'vehicle_plate': instance.vehiclePlate,
  'status': _$BillingStatusEnumMap[instance.status]!,
  'paid_until': instance.paidUntil?.toIso8601String(),
  'grace_until': instance.graceUntil?.toIso8601String(),
  'last_payment': instance.lastPayment?.toJson(),
};

_CostRate _$CostRateFromJson(Map<String, dynamic> json) => _CostRate(
  concept: json['concept'] as String,
  currency: json['currency'] as String,
  unitCostMicro: (json['unit_cost_micro'] as num).toInt(),
  effectiveFrom: DateTime.parse(json['effective_from'] as String),
);

Map<String, dynamic> _$CostRateToJson(_CostRate instance) => <String, dynamic>{
  'concept': instance.concept,
  'currency': instance.currency,
  'unit_cost_micro': instance.unitCostMicro,
  'effective_from': instance.effectiveFrom.toIso8601String(),
};
