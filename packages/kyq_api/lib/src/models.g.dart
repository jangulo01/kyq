// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Tokens _$TokensFromJson(Map<String, dynamic> json) => _Tokens(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
);

Map<String, dynamic> _$TokensToJson(_Tokens instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'role': _$UserRoleEnumMap[instance.role]!,
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
  expiresAt: json['expires_at'] as String,
  approved: json['approved'] as bool,
);

Map<String, dynamic> _$DriverDocumentToJson(_DriverDocument instance) => <String, dynamic>{
  'doc_type': _$DocTypeEnumMap[instance.docType]!,
  'expires_at': instance.expiresAt,
  'approved': instance.approved,
};

const _$DocTypeEnumMap = {
  DocType.license: 'license',
  DocType.mandatoryInsurance: 'mandatory_insurance',
  DocType.vehicleRegistration: 'vehicle_registration',
};

_DriverMe _$DriverMeFromJson(Map<String, dynamic> json) => _DriverMe(
  driverId: json['driver_id'] as String,
  qrToken: json['qr_token'] as String,
  presence: $enumDecode(_$DriverPresenceEnumMap, json['presence']),
  subscriptionStatus: $enumDecode(_$SubscriptionStatusEnumMap, json['subscription_status']),
  paidUntil: json['paid_until'] == null ? null : DateTime.parse(json['paid_until'] as String),
  canGoOnline: json['can_go_online'] as bool,
  blockReason: json['block_reason'] as String?,
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
  'documents': instance.documents.map((e) => e.toJson()).toList(),
};

_ChosenDriver _$ChosenDriverFromJson(Map<String, dynamic> json) => _ChosenDriver(
  driverId: json['driver_id'] as String,
  displayName: json['display_name'] as String,
  vehicleDescription: json['vehicle_description'] as String,
  presence: $enumDecode(_$DriverPresenceEnumMap, json['presence']),
  busyUntilEstimate: json['busy_until_estimate'] == null ? null : DateTime.parse(json['busy_until_estimate'] as String),
);

Map<String, dynamic> _$ChosenDriverToJson(_ChosenDriver instance) => <String, dynamic>{
  'driver_id': instance.driverId,
  'display_name': instance.displayName,
  'vehicle_description': instance.vehicleDescription,
  'presence': _$DriverPresenceEnumMap[instance.presence]!,
  'busy_until_estimate': instance.busyUntilEstimate?.toIso8601String(),
};

_FareQuote _$FareQuoteFromJson(Map<String, dynamic> json) => _FareQuote(
  distanceM: (json['distance_m'] as num).toInt(),
  durationS: (json['duration_s'] as num).toInt(),
  suggestedFareMinor: (json['suggested_fare_minor'] as num).toInt(),
  currency: json['currency'] as String,
);

Map<String, dynamic> _$FareQuoteToJson(_FareQuote instance) => <String, dynamic>{
  'distance_m': instance.distanceM,
  'duration_s': instance.durationS,
  'suggested_fare_minor': instance.suggestedFareMinor,
  'currency': instance.currency,
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
