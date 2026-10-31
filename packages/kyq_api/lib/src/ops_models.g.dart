// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ops_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PersonRef _$PersonRefFromJson(Map<String, dynamic> json) =>
    _PersonRef(id: json['id'] as String, displayName: json['display_name'] as String);

Map<String, dynamic> _$PersonRefToJson(_PersonRef instance) => <String, dynamic>{
  'id': instance.id,
  'display_name': instance.displayName,
};

_TripStep _$TripStepFromJson(Map<String, dynamic> json) =>
    _TripStep(status: json['status'] as String, at: DateTime.parse(json['at'] as String));

Map<String, dynamic> _$TripStepToJson(_TripStep instance) => <String, dynamic>{
  'status': instance.status,
  'at': instance.at.toIso8601String(),
};

_InspectionPosition _$InspectionPositionFromJson(Map<String, dynamic> json) => _InspectionPosition(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  locationAt: DateTime.parse(json['location_at'] as String),
  stale: json['stale'] as bool? ?? false,
);

Map<String, dynamic> _$InspectionPositionToJson(_InspectionPosition instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
  'location_at': instance.locationAt.toIso8601String(),
  'stale': instance.stale,
};

_InspectionPayment _$InspectionPaymentFromJson(Map<String, dynamic> json) =>
    _InspectionPayment(status: json['status'] as String, method: json['method'] as String?);

Map<String, dynamic> _$InspectionPaymentToJson(_InspectionPayment instance) => <String, dynamic>{
  'status': instance.status,
  'method': instance.method,
};

_InspectionSos _$InspectionSosFromJson(Map<String, dynamic> json) =>
    _InspectionSos(id: json['id'] as String, status: json['status'] as String);

Map<String, dynamic> _$InspectionSosToJson(_InspectionSos instance) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
};

_TripInspection _$TripInspectionFromJson(Map<String, dynamic> json) => _TripInspection(
  tripId: json['trip_id'] as String,
  status: json['status'] as String,
  active: json['active'] as bool,
  cancelReason: json['cancel_reason'] as String?,
  dispatch: json['dispatch'] as String,
  handoverCount: (json['handover_count'] as num?)?.toInt() ?? 0,
  cooperativeName: json['cooperative_name'] as String?,
  passenger: PersonRef.fromJson(json['passenger'] as Map<String, dynamic>),
  driver: PersonRef.fromJson(json['driver'] as Map<String, dynamic>),
  vehiclePlate: json['vehicle_plate'] as String,
  vehicleDescription: json['vehicle_description'] as String? ?? '',
  pickup: GeoPoint.fromJson(json['pickup'] as Map<String, dynamic>),
  dropoff: GeoPoint.fromJson(json['dropoff'] as Map<String, dynamic>),
  distanceM: (json['distance_m'] as num).toInt(),
  durationS: (json['duration_s'] as num).toInt(),
  currency: json['currency'] as String,
  listFareMinor: (json['list_fare_minor'] as num).toInt(),
  suggestedFareMinor: (json['suggested_fare_minor'] as num).toInt(),
  agreedFareMinor: (json['agreed_fare_minor'] as num?)?.toInt(),
  preferentialDiscountPct: (json['preferential_discount_pct'] as num?)?.toInt() ?? 0,
  steps:
      (json['steps'] as List<dynamic>?)?.map((e) => TripStep.fromJson(e as Map<String, dynamic>)).toList() ??
      const <TripStep>[],
  driverPosition: json['driver_position'] == null
      ? null
      : InspectionPosition.fromJson(json['driver_position'] as Map<String, dynamic>),
  payment: json['payment'] == null ? null : InspectionPayment.fromJson(json['payment'] as Map<String, dynamic>),
  openSos: json['open_sos'] == null ? null : InspectionSos.fromJson(json['open_sos'] as Map<String, dynamic>),
  generatedAt: DateTime.parse(json['generated_at'] as String),
);

Map<String, dynamic> _$TripInspectionToJson(_TripInspection instance) => <String, dynamic>{
  'trip_id': instance.tripId,
  'status': instance.status,
  'active': instance.active,
  'cancel_reason': instance.cancelReason,
  'dispatch': instance.dispatch,
  'handover_count': instance.handoverCount,
  'cooperative_name': instance.cooperativeName,
  'passenger': instance.passenger.toJson(),
  'driver': instance.driver.toJson(),
  'vehicle_plate': instance.vehiclePlate,
  'vehicle_description': instance.vehicleDescription,
  'pickup': instance.pickup.toJson(),
  'dropoff': instance.dropoff.toJson(),
  'distance_m': instance.distanceM,
  'duration_s': instance.durationS,
  'currency': instance.currency,
  'list_fare_minor': instance.listFareMinor,
  'suggested_fare_minor': instance.suggestedFareMinor,
  'agreed_fare_minor': instance.agreedFareMinor,
  'preferential_discount_pct': instance.preferentialDiscountPct,
  'steps': instance.steps.map((e) => e.toJson()).toList(),
  'driver_position': instance.driverPosition?.toJson(),
  'payment': instance.payment?.toJson(),
  'open_sos': instance.openSos?.toJson(),
  'generated_at': instance.generatedAt.toIso8601String(),
};

_SupportCase _$SupportCaseFromJson(Map<String, dynamic> json) => _SupportCase(
  id: json['id'] as String,
  topic: $enumDecode(_$SupportTopicEnumMap, json['topic']),
  subject: json['subject'] as String,
  status: $enumDecode(_$SupportStatusEnumMap, json['status']),
  user: PersonRef.fromJson(json['user'] as Map<String, dynamic>),
  userRole: json['user_role'] as String,
  counterpart: json['counterpart'] == null ? null : PersonRef.fromJson(json['counterpart'] as Map<String, dynamic>),
  tripId: json['trip_id'] as String?,
  tripPaymentId: json['trip_payment_id'] as String?,
  assignedTo: json['assigned_to'] == null ? null : PersonRef.fromJson(json['assigned_to'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['created_at'] as String),
  lastMessageAt: DateTime.parse(json['last_message_at'] as String),
  lastUserMessageAt: json['last_user_message_at'] == null
      ? null
      : DateTime.parse(json['last_user_message_at'] as String),
  awaitingReply: json['awaiting_reply'] as bool? ?? false,
  resolvedAt: json['resolved_at'] == null ? null : DateTime.parse(json['resolved_at'] as String),
  closedAt: json['closed_at'] == null ? null : DateTime.parse(json['closed_at'] as String),
);

Map<String, dynamic> _$SupportCaseToJson(_SupportCase instance) => <String, dynamic>{
  'id': instance.id,
  'topic': _$SupportTopicEnumMap[instance.topic]!,
  'subject': instance.subject,
  'status': _$SupportStatusEnumMap[instance.status]!,
  'user': instance.user.toJson(),
  'user_role': instance.userRole,
  'counterpart': instance.counterpart?.toJson(),
  'trip_id': instance.tripId,
  'trip_payment_id': instance.tripPaymentId,
  'assigned_to': instance.assignedTo?.toJson(),
  'created_at': instance.createdAt.toIso8601String(),
  'last_message_at': instance.lastMessageAt.toIso8601String(),
  'last_user_message_at': instance.lastUserMessageAt?.toIso8601String(),
  'awaiting_reply': instance.awaitingReply,
  'resolved_at': instance.resolvedAt?.toIso8601String(),
  'closed_at': instance.closedAt?.toIso8601String(),
};

const _$SupportTopicEnumMap = {
  SupportTopic.trip: 'trip',
  SupportTopic.payment: 'payment',
  SupportTopic.lostItem: 'lost_item',
  SupportTopic.safety: 'safety',
  SupportTopic.account: 'account',
  SupportTopic.other: 'other',
};

const _$SupportStatusEnumMap = {
  SupportStatus.open: 'open',
  SupportStatus.inProgress: 'in_progress',
  SupportStatus.waitingUser: 'waiting_user',
  SupportStatus.resolved: 'resolved',
  SupportStatus.closed: 'closed',
};

_SupportMessage _$SupportMessageFromJson(Map<String, dynamic> json) => _SupportMessage(
  id: json['id'] as String,
  authorKind: $enumDecode(_$SupportAuthorEnumMap, json['author_kind']),
  authorName: json['author_name'] as String?,
  mine: json['mine'] as bool? ?? false,
  body: json['body'] as String,
  internal: json['internal'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$SupportMessageToJson(_SupportMessage instance) => <String, dynamic>{
  'id': instance.id,
  'author_kind': _$SupportAuthorEnumMap[instance.authorKind]!,
  'author_name': instance.authorName,
  'mine': instance.mine,
  'body': instance.body,
  'internal': instance.internal,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$SupportAuthorEnumMap = {
  SupportAuthor.user: 'user',
  SupportAuthor.admin: 'admin',
  SupportAuthor.system: 'system',
};

_SupportTripRef _$SupportTripRefFromJson(Map<String, dynamic> json) => _SupportTripRef(
  id: json['id'] as String,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  otherParty: json['other_party'] as String,
);

Map<String, dynamic> _$SupportTripRefToJson(_SupportTripRef instance) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  'other_party': instance.otherParty,
};

_MegaphoneOnAir _$MegaphoneOnAirFromJson(Map<String, dynamic> json) => _MegaphoneOnAir(
  broadcastId: json['broadcast_id'] as String,
  url: json['url'] as String,
  token: json['token'] as String,
  endsAt: DateTime.parse(json['ends_at'] as String),
  recipients: (json['recipients'] as num).toInt(),
);

Map<String, dynamic> _$MegaphoneOnAirToJson(_MegaphoneOnAir instance) => <String, dynamic>{
  'broadcast_id': instance.broadcastId,
  'url': instance.url,
  'token': instance.token,
  'ends_at': instance.endsAt.toIso8601String(),
  'recipients': instance.recipients,
};

_MegaphoneBroadcast _$MegaphoneBroadcastFromJson(Map<String, dynamic> json) => _MegaphoneBroadcast(
  id: json['id'] as String,
  adminName: json['admin_name'] as String,
  cells: (json['cells'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
  resolution: (json['resolution'] as num).toInt(),
  startedAt: DateTime.parse(json['started_at'] as String),
  endedAt: json['ended_at'] == null ? null : DateTime.parse(json['ended_at'] as String),
  durationS: (json['duration_s'] as num?)?.toInt(),
  recipients: (json['recipients'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$MegaphoneBroadcastToJson(_MegaphoneBroadcast instance) => <String, dynamic>{
  'id': instance.id,
  'admin_name': instance.adminName,
  'cells': instance.cells,
  'resolution': instance.resolution,
  'started_at': instance.startedAt.toIso8601String(),
  'ended_at': instance.endedAt?.toIso8601String(),
  'duration_s': instance.durationS,
  'recipients': instance.recipients,
};

_AppSessions _$AppSessionsFromJson(Map<String, dynamic> json) => _AppSessions(
  app: json['app'] as String,
  crashFree24h: (json['crash_free24h'] as num?)?.toDouble(),
  crashFree7d: (json['crash_free7d'] as num?)?.toDouble(),
  topRelease: json['top_release'] as String?,
  belowTarget: json['below_target'] as bool? ?? false,
  link: json['link'] as String? ?? '',
);

Map<String, dynamic> _$AppSessionsToJson(_AppSessions instance) => <String, dynamic>{
  'app': instance.app,
  'crash_free24h': instance.crashFree24h,
  'crash_free7d': instance.crashFree7d,
  'top_release': instance.topRelease,
  'below_target': instance.belowTarget,
  'link': instance.link,
};

_SessionsReport _$SessionsReportFromJson(Map<String, dynamic> json) => _SessionsReport(
  status: json['status'] as String,
  checkedAt: DateTime.parse(json['checked_at'] as String),
  target: (json['target'] as num?)?.toDouble() ?? 0.99,
  apps:
      (json['apps'] as List<dynamic>?)?.map((e) => AppSessions.fromJson(e as Map<String, dynamic>)).toList() ??
      const <AppSessions>[],
);

Map<String, dynamic> _$SessionsReportToJson(_SessionsReport instance) => <String, dynamic>{
  'status': instance.status,
  'checked_at': instance.checkedAt.toIso8601String(),
  'target': instance.target,
  'apps': instance.apps.map((e) => e.toJson()).toList(),
};

_MirrorDomain _$MirrorDomainFromJson(Map<String, dynamic> json) => _MirrorDomain(
  id: json['id'] as String,
  apiUrl: json['api_url'] as String,
  realtimeUrl: json['realtime_url'] as String,
  position: (json['position'] as num).toInt(),
  active: json['active'] as bool,
  status: json['status'] as String? ?? 'unchecked',
  latencyMs: (json['latency_ms'] as num?)?.toInt(),
);

Map<String, dynamic> _$MirrorDomainToJson(_MirrorDomain instance) => <String, dynamic>{
  'id': instance.id,
  'api_url': instance.apiUrl,
  'realtime_url': instance.realtimeUrl,
  'position': instance.position,
  'active': instance.active,
  'status': instance.status,
  'latency_ms': instance.latencyMs,
};

_MirrorDomainListing _$MirrorDomainListingFromJson(Map<String, dynamic> json) => _MirrorDomainListing(
  version: (json['version'] as num).toInt(),
  signingConfigured: json['signing_configured'] as bool,
  publicKey: json['public_key'] as String?,
  domains:
      (json['domains'] as List<dynamic>?)?.map((e) => MirrorDomain.fromJson(e as Map<String, dynamic>)).toList() ??
      const <MirrorDomain>[],
);

Map<String, dynamic> _$MirrorDomainListingToJson(_MirrorDomainListing instance) => <String, dynamic>{
  'version': instance.version,
  'signing_configured': instance.signingConfigured,
  'public_key': instance.publicKey,
  'domains': instance.domains.map((e) => e.toJson()).toList(),
};

_SignedDomainList _$SignedDomainListFromJson(Map<String, dynamic> json) =>
    _SignedDomainList(payload: json['payload'] as String, signature: json['signature'] as String);

Map<String, dynamic> _$SignedDomainListToJson(_SignedDomainList instance) => <String, dynamic>{
  'payload': instance.payload,
  'signature': instance.signature,
};
