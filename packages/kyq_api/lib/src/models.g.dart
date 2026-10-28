// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Tokens _$TokensFromJson(Map<String, dynamic> json) => _Tokens(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  scope: json['scope'] as String?,
);

Map<String, dynamic> _$TokensToJson(_Tokens instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'role': _$UserRoleEnumMap[instance.role]!,
  'scope': instance.scope,
};

const _$UserRoleEnumMap = {UserRole.passenger: 'passenger', UserRole.driver: 'driver', UserRole.admin: 'admin'};

_GeoPoint _$GeoPointFromJson(Map<String, dynamic> json) =>
    _GeoPoint(lat: (json['lat'] as num).toDouble(), lng: (json['lng'] as num).toDouble());

Map<String, dynamic> _$GeoPointToJson(_GeoPoint instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
};

_DriverDocument _$DriverDocumentFromJson(Map<String, dynamic> json) => _DriverDocument(
  docType: $enumDecode(_$DocTypeEnumMap, json['doc_type']),
  expiresAt: json['expires_at'] as String?,
  approved: json['approved'] as bool,
);

Map<String, dynamic> _$DriverDocumentToJson(_DriverDocument instance) => <String, dynamic>{
  'doc_type': _$DocTypeEnumMap[instance.docType]!,
  'expires_at': instance.expiresAt,
  'approved': instance.approved,
};

const _$DocTypeEnumMap = {
  DocType.nationalId: 'national_id',
  DocType.license: 'license',
  DocType.mandatoryInsurance: 'mandatory_insurance',
  DocType.technicalInspection: 'technical_inspection',
  DocType.vehicleRegistration: 'vehicle_registration',
};

_BlockedDocument _$BlockedDocumentFromJson(Map<String, dynamic> json) => _BlockedDocument(
  docType: $enumDecode(_$DocTypeEnumMap, json['doc_type']),
  problem: $enumDecode(_$BlockedDocumentProblemEnumMap, json['problem']),
);

Map<String, dynamic> _$BlockedDocumentToJson(_BlockedDocument instance) => <String, dynamic>{
  'doc_type': _$DocTypeEnumMap[instance.docType]!,
  'problem': _$BlockedDocumentProblemEnumMap[instance.problem]!,
};

const _$BlockedDocumentProblemEnumMap = {
  BlockedDocumentProblem.missing: 'missing',
  BlockedDocumentProblem.expired: 'expired',
};

_DriverMe _$DriverMeFromJson(Map<String, dynamic> json) => _DriverMe(
  driverId: json['driver_id'] as String,
  qrToken: json['qr_token'] as String,
  presence: $enumDecode(_$DriverPresenceEnumMap, json['presence']),
  subscriptionStatus: $enumDecode(_$SubscriptionStatusEnumMap, json['subscription_status']),
  paidUntil: json['paid_until'] == null ? null : DateTime.parse(json['paid_until'] as String),
  canGoOnline: json['can_go_online'] as bool,
  blockReason: json['block_reason'] as String?,
  blockedDocuments:
      (json['blocked_documents'] as List<dynamic>?)
          ?.map((e) => BlockedDocument.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BlockedDocument>[],
  documents:
      (json['documents'] as List<dynamic>?)?.map((e) => DriverDocument.fromJson(e as Map<String, dynamic>)).toList() ??
      const <DriverDocument>[],
);

Map<String, dynamic> _$DriverMeToJson(_DriverMe instance) => <String, dynamic>{
  'driver_id': instance.driverId,
  'qr_token': instance.qrToken,
  'presence': _$DriverPresenceEnumMap[instance.presence]!,
  'subscription_status': _$SubscriptionStatusEnumMap[instance.subscriptionStatus]!,
  'paid_until': instance.paidUntil?.toIso8601String(),
  'can_go_online': instance.canGoOnline,
  'block_reason': instance.blockReason,
  'blocked_documents': instance.blockedDocuments.map((e) => e.toJson()).toList(),
  'documents': instance.documents.map((e) => e.toJson()).toList(),
};

const _$DriverPresenceEnumMap = {
  DriverPresence.offline: 'offline',
  DriverPresence.free: 'free',
  DriverPresence.busy: 'busy',
};

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.gracePeriod: 'grace_period',
  SubscriptionStatus.suspended: 'suspended',
};

_AdminDriver _$AdminDriverFromJson(Map<String, dynamic> json) => _AdminDriver(
  driverId: json['driver_id'] as String,
  phoneE164: json['phone_e164'] as String,
  displayName: json['display_name'] as String,
  qrToken: json['qr_token'] as String,
  vehiclePlate: json['vehicle_plate'] as String,
  vehicleDescription: json['vehicle_description'] as String,
  presence: $enumDecode(_$DriverPresenceEnumMap, json['presence']),
  paidUntil: json['paid_until'] == null ? null : DateTime.parse(json['paid_until'] as String),
  subscriptionStatus: $enumDecode(_$SubscriptionStatusEnumMap, json['subscription_status']),
  canGoOnline: json['can_go_online'] as bool,
  blockReason: json['block_reason'] as String?,
  blockedDocuments:
      (json['blocked_documents'] as List<dynamic>?)
          ?.map((e) => BlockedDocument.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BlockedDocument>[],
  documents:
      (json['documents'] as List<dynamic>?)?.map((e) => DriverDocument.fromJson(e as Map<String, dynamic>)).toList() ??
      const <DriverDocument>[],
);

Map<String, dynamic> _$AdminDriverToJson(_AdminDriver instance) => <String, dynamic>{
  'driver_id': instance.driverId,
  'phone_e164': instance.phoneE164,
  'display_name': instance.displayName,
  'qr_token': instance.qrToken,
  'vehicle_plate': instance.vehiclePlate,
  'vehicle_description': instance.vehicleDescription,
  'presence': _$DriverPresenceEnumMap[instance.presence]!,
  'paid_until': instance.paidUntil?.toIso8601String(),
  'subscription_status': _$SubscriptionStatusEnumMap[instance.subscriptionStatus]!,
  'can_go_online': instance.canGoOnline,
  'block_reason': instance.blockReason,
  'blocked_documents': instance.blockedDocuments.map((e) => e.toJson()).toList(),
  'documents': instance.documents.map((e) => e.toJson()).toList(),
};

_ChosenDriver _$ChosenDriverFromJson(Map<String, dynamic> json) => _ChosenDriver(
  driverId: json['driver_id'] as String,
  displayName: json['display_name'] as String,
  vehicleDescription: json['vehicle_description'] as String,
  presence: $enumDecode(_$DriverPresenceEnumMap, json['presence']),
  busyUntilEstimate: json['busy_until_estimate'] == null ? null : DateTime.parse(json['busy_until_estimate'] as String),
  cooperative: json['cooperative'] == null
      ? null
      : CooperativeRef.fromJson(json['cooperative'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChosenDriverToJson(_ChosenDriver instance) => <String, dynamic>{
  'driver_id': instance.driverId,
  'display_name': instance.displayName,
  'vehicle_description': instance.vehicleDescription,
  'presence': _$DriverPresenceEnumMap[instance.presence]!,
  'busy_until_estimate': instance.busyUntilEstimate?.toIso8601String(),
  'cooperative': instance.cooperative?.toJson(),
};

_FareTableInput _$FareTableInputFromJson(Map<String, dynamic> json) => _FareTableInput(
  currency: json['currency'] as String,
  baseMinor: (json['base_minor'] as num).toInt(),
  perKmMinor: (json['per_km_minor'] as num).toInt(),
  perMinuteMinor: (json['per_minute_minor'] as num).toInt(),
  minimumMinor: (json['minimum_minor'] as num).toInt(),
  roundingMinor: (json['rounding_minor'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$FareTableInputToJson(_FareTableInput instance) => <String, dynamic>{
  'currency': instance.currency,
  'base_minor': instance.baseMinor,
  'per_km_minor': instance.perKmMinor,
  'per_minute_minor': instance.perMinuteMinor,
  'minimum_minor': instance.minimumMinor,
  'rounding_minor': instance.roundingMinor,
};

_DispatchSettings _$DispatchSettingsFromJson(Map<String, dynamic> json) => _DispatchSettings(
  acceptsZonePool: json['accepts_zone_pool'] as bool? ?? false,
  preferentialDiscountPct: (json['preferential_discount_pct'] as num?)?.toInt() ?? 0,
  affiliateLink: json['affiliate_link'] as String? ?? '',
);

Map<String, dynamic> _$DispatchSettingsToJson(_DispatchSettings instance) => <String, dynamic>{
  'accepts_zone_pool': instance.acceptsZonePool,
  'preferential_discount_pct': instance.preferentialDiscountPct,
  'affiliate_link': instance.affiliateLink,
};

_DriverClient _$DriverClientFromJson(Map<String, dynamic> json) => _DriverClient(
  passengerId: json['passenger_id'] as String,
  displayName: json['display_name'] as String,
  affiliatedAt: DateTime.parse(json['affiliated_at'] as String),
  source: $enumDecodeNullable(_$AffiliationSourceEnumMap, json['source']) ?? AffiliationSource.qrScan,
);

Map<String, dynamic> _$DriverClientToJson(_DriverClient instance) => <String, dynamic>{
  'passenger_id': instance.passengerId,
  'display_name': instance.displayName,
  'affiliated_at': instance.affiliatedAt.toIso8601String(),
  'source': _$AffiliationSourceEnumMap[instance.source]!,
};

const _$AffiliationSourceEnumMap = {
  AffiliationSource.qrScan: 'qr_scan',
  AffiliationSource.postTrip: 'post_trip',
  AffiliationSource.link: 'link',
};

_FareQuote _$FareQuoteFromJson(Map<String, dynamic> json) => _FareQuote(
  distanceM: (json['distance_m'] as num).toInt(),
  durationS: (json['duration_s'] as num).toInt(),
  suggestedFareMinor: (json['suggested_fare_minor'] as num).toInt(),
  currency: json['currency'] as String,
  listFareMinor: (json['list_fare_minor'] as num?)?.toInt(),
  preferentialDiscountPct: (json['preferential_discount_pct'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$FareQuoteToJson(_FareQuote instance) => <String, dynamic>{
  'distance_m': instance.distanceM,
  'duration_s': instance.durationS,
  'suggested_fare_minor': instance.suggestedFareMinor,
  'currency': instance.currency,
  'list_fare_minor': instance.listFareMinor,
  'preferential_discount_pct': instance.preferentialDiscountPct,
};

_FareProposal _$FareProposalFromJson(Map<String, dynamic> json) => _FareProposal(
  id: json['id'] as String,
  proposedBy: $enumDecode(_$ProposalPartyEnumMap, json['proposed_by']),
  amountMinor: (json['amount_minor'] as num).toInt(),
  status: $enumDecode(_$ProposalStatusEnumMap, json['status']),
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$FareProposalToJson(_FareProposal instance) => <String, dynamic>{
  'id': instance.id,
  'proposed_by': _$ProposalPartyEnumMap[instance.proposedBy]!,
  'amount_minor': instance.amountMinor,
  'status': _$ProposalStatusEnumMap[instance.status]!,
  'expires_at': instance.expiresAt.toIso8601String(),
};

const _$ProposalPartyEnumMap = {ProposalParty.driver: 'driver', ProposalParty.passenger: 'passenger'};

const _$ProposalStatusEnumMap = {
  ProposalStatus.open: 'open',
  ProposalStatus.accepted: 'accepted',
  ProposalStatus.rejected: 'rejected',
  ProposalStatus.superseded: 'superseded',
  ProposalStatus.expired: 'expired',
};

_Trip _$TripFromJson(Map<String, dynamic> json) => _Trip(
  id: json['id'] as String,
  status: $enumDecode(_$TripStatusEnumMap, json['status']),
  passengerId: json['passenger_id'] as String,
  driverId: json['driver_id'] as String,
  pickup: GeoPoint.fromJson(json['pickup'] as Map<String, dynamic>),
  dropoff: GeoPoint.fromJson(json['dropoff'] as Map<String, dynamic>),
  distanceM: (json['distance_m'] as num).toInt(),
  durationS: (json['duration_s'] as num).toInt(),
  currency: json['currency'] as String,
  suggestedFareMinor: (json['suggested_fare_minor'] as num).toInt(),
  agreedFareMinor: (json['agreed_fare_minor'] as num?)?.toInt(),
  driverPayoutMinor: (json['driver_payout_minor'] as num?)?.toInt(),
  platformCommissionMinor: (json['platform_commission_minor'] as num?)?.toInt() ?? 0,
  openProposal: json['open_proposal'] == null
      ? null
      : FareProposal.fromJson(json['open_proposal'] as Map<String, dynamic>),
  offerExpiresAt: json['offer_expires_at'] == null ? null : DateTime.parse(json['offer_expires_at'] as String),
  negotiationExpiresAt: json['negotiation_expires_at'] == null
      ? null
      : DateTime.parse(json['negotiation_expires_at'] as String),
  cancelReason: json['cancel_reason'] as String?,
  dispatch: $enumDecodeNullable(_$TripDispatchEnumMap, json['dispatch']) ?? TripDispatch.chosenDriver,
  requestedDriverId: json['requested_driver_id'] as String?,
  driverName: json['driver_name'] as String?,
  cooperativeId: json['cooperative_id'] as String?,
  cooperativeName: json['cooperative_name'] as String?,
  allowDelegation: json['allow_delegation'] as bool? ?? false,
  handoverCount: (json['handover_count'] as num?)?.toInt() ?? 0,
  canDelegate: json['can_delegate'] as bool? ?? false,
  listFareMinor: (json['list_fare_minor'] as num?)?.toInt(),
  preferentialDiscountPct: (json['preferential_discount_pct'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TripToJson(_Trip instance) => <String, dynamic>{
  'id': instance.id,
  'status': _$TripStatusEnumMap[instance.status]!,
  'passenger_id': instance.passengerId,
  'driver_id': instance.driverId,
  'pickup': instance.pickup.toJson(),
  'dropoff': instance.dropoff.toJson(),
  'distance_m': instance.distanceM,
  'duration_s': instance.durationS,
  'currency': instance.currency,
  'suggested_fare_minor': instance.suggestedFareMinor,
  'agreed_fare_minor': instance.agreedFareMinor,
  'driver_payout_minor': instance.driverPayoutMinor,
  'platform_commission_minor': instance.platformCommissionMinor,
  'open_proposal': instance.openProposal?.toJson(),
  'offer_expires_at': instance.offerExpiresAt?.toIso8601String(),
  'negotiation_expires_at': instance.negotiationExpiresAt?.toIso8601String(),
  'cancel_reason': instance.cancelReason,
  'dispatch': _$TripDispatchEnumMap[instance.dispatch]!,
  'requested_driver_id': instance.requestedDriverId,
  'driver_name': instance.driverName,
  'cooperative_id': instance.cooperativeId,
  'cooperative_name': instance.cooperativeName,
  'allow_delegation': instance.allowDelegation,
  'handover_count': instance.handoverCount,
  'can_delegate': instance.canDelegate,
  'list_fare_minor': instance.listFareMinor,
  'preferential_discount_pct': instance.preferentialDiscountPct,
};

const _$TripStatusEnumMap = {
  TripStatus.requested: 'REQUESTED',
  TripStatus.farePending: 'FARE_PENDING',
  TripStatus.negotiationPending: 'NEGOTIATION_PENDING',
  TripStatus.negotiating: 'NEGOTIATING',
  TripStatus.accepted: 'ACCEPTED',
  TripStatus.arrived: 'ARRIVED',
  TripStatus.inProgress: 'IN_PROGRESS',
  TripStatus.completed: 'COMPLETED',
  TripStatus.cancelled: 'CANCELLED',
};

const _$TripDispatchEnumMap = {
  TripDispatch.chosenDriver: 'chosen_driver',
  TripDispatch.cooperative: 'cooperative',
  TripDispatch.zonePool: 'zone_pool',
};

_PttCredentials _$PttCredentialsFromJson(Map<String, dynamic> json) => _PttCredentials(
  url: json['url'] as String,
  token: json['token'] as String,
  room: json['room'] as String,
  closesAt: json['closes_at'] == null ? null : DateTime.parse(json['closes_at'] as String),
);

Map<String, dynamic> _$PttCredentialsToJson(_PttCredentials instance) => <String, dynamic>{
  'url': instance.url,
  'token': instance.token,
  'room': instance.room,
  'closes_at': instance.closesAt?.toIso8601String(),
};
