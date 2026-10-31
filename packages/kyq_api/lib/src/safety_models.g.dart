// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SosPoint _$SosPointFromJson(Map<String, dynamic> json) => _SosPoint(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
  recordedAt: DateTime.parse(json['recorded_at'] as String),
);

Map<String, dynamic> _$SosPointToJson(_SosPoint instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
  'accuracy_m': instance.accuracyM,
  'recorded_at': instance.recordedAt.toIso8601String(),
};

_SosLocation _$SosLocationFromJson(Map<String, dynamic> json) => _SosLocation(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
  at: json['at'] == null ? null : DateTime.parse(json['at'] as String),
);

Map<String, dynamic> _$SosLocationToJson(_SosLocation instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
  'accuracy_m': instance.accuracyM,
  'at': instance.at?.toIso8601String(),
};

_SosAlertSelf _$SosAlertSelfFromJson(Map<String, dynamic> json) => _SosAlertSelf(
  id: json['id'] as String,
  tripId: json['trip_id'] as String?,
  status: $enumDecode(_$SosStatusEnumMap, json['status']),
  operatorConnected: json['operator_connected'] as bool? ?? false,
  escalated: json['escalated'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$SosAlertSelfToJson(_SosAlertSelf instance) => <String, dynamic>{
  'id': instance.id,
  'trip_id': instance.tripId,
  'status': _$SosStatusEnumMap[instance.status]!,
  'operator_connected': instance.operatorConnected,
  'escalated': instance.escalated,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$SosStatusEnumMap = {
  SosStatus.open: 'open',
  SosStatus.claimed: 'claimed',
  SosStatus.closed: 'closed',
  SosStatus.cancelledByUser: 'cancelled_by_user',
};

_SosVoice _$SosVoiceFromJson(Map<String, dynamic> json) => _SosVoice(
  url: json['url'] as String,
  token: json['token'] as String,
  room: json['room'] as String,
  canPublish: json['can_publish'] as bool? ?? false,
);

Map<String, dynamic> _$SosVoiceToJson(_SosVoice instance) => <String, dynamic>{
  'url': instance.url,
  'token': instance.token,
  'room': instance.room,
  'can_publish': instance.canPublish,
};

_SosRaise _$SosRaiseFromJson(Map<String, dynamic> json) => _SosRaise(
  alert: SosAlertSelf.fromJson(json['alert'] as Map<String, dynamic>),
  voice: json['voice'] == null ? null : SosVoice.fromJson(json['voice'] as Map<String, dynamic>),
  needsPin: json['needs_pin'] as bool? ?? false,
);

Map<String, dynamic> _$SosRaiseToJson(_SosRaise instance) => <String, dynamic>{
  'alert': instance.alert.toJson(),
  'voice': instance.voice?.toJson(),
  'needs_pin': instance.needsPin,
};

_SosAlertSummary _$SosAlertSummaryFromJson(Map<String, dynamic> json) => _SosAlertSummary(
  id: json['id'] as String,
  tripId: json['trip_id'] as String?,
  raisedFrom: json['raised_from'] as String? ?? 'trip',
  raisedRole: $enumDecode(_$SosRoleEnumMap, json['raised_role']),
  raisedByName: json['raised_by_name'] as String,
  status: $enumDecode(_$SosStatusEnumMap, json['status']),
  cancelWithoutPin: json['cancel_without_pin'] as bool? ?? false,
  claimedBy: json['claimed_by'] as String?,
  claimedByName: json['claimed_by_name'] as String?,
  outcome: $enumDecodeNullable(_$SosOutcomeEnumMap, json['outcome']),
  escalated: json['escalated'] as bool? ?? false,
  hasRecording: json['has_recording'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
  claimedAt: json['claimed_at'] == null ? null : DateTime.parse(json['claimed_at'] as String),
  closedAt: json['closed_at'] == null ? null : DateTime.parse(json['closed_at'] as String),
  lastLocation: json['last_location'] == null
      ? null
      : SosLocation.fromJson(json['last_location'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SosAlertSummaryToJson(_SosAlertSummary instance) => <String, dynamic>{
  'id': instance.id,
  'trip_id': instance.tripId,
  'raised_from': instance.raisedFrom,
  'raised_role': _$SosRoleEnumMap[instance.raisedRole]!,
  'raised_by_name': instance.raisedByName,
  'status': _$SosStatusEnumMap[instance.status]!,
  'cancel_without_pin': instance.cancelWithoutPin,
  'claimed_by': instance.claimedBy,
  'claimed_by_name': instance.claimedByName,
  'outcome': _$SosOutcomeEnumMap[instance.outcome],
  'escalated': instance.escalated,
  'has_recording': instance.hasRecording,
  'created_at': instance.createdAt.toIso8601String(),
  'claimed_at': instance.claimedAt?.toIso8601String(),
  'closed_at': instance.closedAt?.toIso8601String(),
  'last_location': instance.lastLocation?.toJson(),
};

const _$SosRoleEnumMap = {SosRole.passenger: 'passenger', SosRole.driver: 'driver'};

const _$SosOutcomeEnumMap = {
  SosOutcome.falseAlarm: 'false_alarm',
  SosOutcome.resolved: 'resolved',
  SosOutcome.escalatedAuthorities: 'escalated_authorities',
  SosOutcome.noResponse: 'no_response',
};

_SosNote _$SosNoteFromJson(Map<String, dynamic> json) => _SosNote(
  id: json['id'] as String,
  operatorId: json['operator_id'] as String,
  operatorName: json['operator_name'] as String,
  body: json['body'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$SosNoteToJson(_SosNote instance) => <String, dynamic>{
  'id': instance.id,
  'operator_id': instance.operatorId,
  'operator_name': instance.operatorName,
  'body': instance.body,
  'created_at': instance.createdAt.toIso8601String(),
};

_SosPerson _$SosPersonFromJson(Map<String, dynamic> json) =>
    _SosPerson(userId: json['user_id'] as String, name: json['name'] as String);

Map<String, dynamic> _$SosPersonToJson(_SosPerson instance) => <String, dynamic>{
  'user_id': instance.userId,
  'name': instance.name,
};

_SosDriver _$SosDriverFromJson(Map<String, dynamic> json) => _SosDriver(
  userId: json['user_id'] as String,
  name: json['name'] as String,
  vehiclePlate: json['vehicle_plate'] as String,
  vehicleDescription: json['vehicle_description'] as String,
  vehicleBrand: json['vehicle_brand'] as String?,
  vehicleModel: json['vehicle_model'] as String?,
  vehicleColor: json['vehicle_color'] as String?,
);

Map<String, dynamic> _$SosDriverToJson(_SosDriver instance) => <String, dynamic>{
  'user_id': instance.userId,
  'name': instance.name,
  'vehicle_plate': instance.vehiclePlate,
  'vehicle_description': instance.vehicleDescription,
  'vehicle_brand': instance.vehicleBrand,
  'vehicle_model': instance.vehicleModel,
  'vehicle_color': instance.vehicleColor,
};

_SosTrip _$SosTripFromJson(Map<String, dynamic> json) => _SosTrip(
  status: json['status'] as String,
  pickup: GeoPoint.fromJson(json['pickup'] as Map<String, dynamic>),
  dropoff: GeoPoint.fromJson(json['dropoff'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SosTripToJson(_SosTrip instance) => <String, dynamic>{
  'status': instance.status,
  'pickup': instance.pickup.toJson(),
  'dropoff': instance.dropoff.toJson(),
};

_EmergencyContact _$EmergencyContactFromJson(Map<String, dynamic> json) =>
    _EmergencyContact(name: json['name'] as String, phoneE164: json['phone_e164'] as String);

Map<String, dynamic> _$EmergencyContactToJson(_EmergencyContact instance) => <String, dynamic>{
  'name': instance.name,
  'phone_e164': instance.phoneE164,
};

_SosAlertDetail _$SosAlertDetailFromJson(Map<String, dynamic> json) => _SosAlertDetail(
  id: json['id'] as String,
  tripId: json['trip_id'] as String?,
  raisedFrom: json['raised_from'] as String? ?? 'trip',
  raisedRole: $enumDecode(_$SosRoleEnumMap, json['raised_role']),
  raisedByName: json['raised_by_name'] as String,
  status: $enumDecode(_$SosStatusEnumMap, json['status']),
  cancelWithoutPin: json['cancel_without_pin'] as bool? ?? false,
  claimedBy: json['claimed_by'] as String?,
  claimedByName: json['claimed_by_name'] as String?,
  outcome: $enumDecodeNullable(_$SosOutcomeEnumMap, json['outcome']),
  escalated: json['escalated'] as bool? ?? false,
  hasRecording: json['has_recording'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
  claimedAt: json['claimed_at'] == null ? null : DateTime.parse(json['claimed_at'] as String),
  closedAt: json['closed_at'] == null ? null : DateTime.parse(json['closed_at'] as String),
  lastLocation: json['last_location'] == null
      ? null
      : SosLocation.fromJson(json['last_location'] as Map<String, dynamic>),
  raisedByPhone: json['raised_by_phone_e164'] as String? ?? '',
  emergencyContacts:
      (json['emergency_contacts'] as List<dynamic>?)
          ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  trip: SosTrip.fromJson(json['trip'] as Map<String, dynamic>),
  passenger: SosPerson.fromJson(json['passenger'] as Map<String, dynamic>),
  driver: SosDriver.fromJson(json['driver'] as Map<String, dynamic>),
  track:
      (json['track'] as List<dynamic>?)?.map((e) => SosLocation.fromJson(e as Map<String, dynamic>)).toList() ??
      const [],
  notes:
      (json['notes'] as List<dynamic>?)?.map((e) => SosNote.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
  relatedAlertIds: (json['related_alert_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
  recordingUrl: json['recording_url'] as String?,
  raisedByAlerts: (json['raised_by_alerts'] as num?)?.toInt() ?? 0,
  raisedByFalseAlarms: (json['raised_by_false_alarms'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SosAlertDetailToJson(_SosAlertDetail instance) => <String, dynamic>{
  'id': instance.id,
  'trip_id': instance.tripId,
  'raised_from': instance.raisedFrom,
  'raised_role': _$SosRoleEnumMap[instance.raisedRole]!,
  'raised_by_name': instance.raisedByName,
  'status': _$SosStatusEnumMap[instance.status]!,
  'cancel_without_pin': instance.cancelWithoutPin,
  'claimed_by': instance.claimedBy,
  'claimed_by_name': instance.claimedByName,
  'outcome': _$SosOutcomeEnumMap[instance.outcome],
  'escalated': instance.escalated,
  'has_recording': instance.hasRecording,
  'created_at': instance.createdAt.toIso8601String(),
  'claimed_at': instance.claimedAt?.toIso8601String(),
  'closed_at': instance.closedAt?.toIso8601String(),
  'last_location': instance.lastLocation?.toJson(),
  'raised_by_phone_e164': instance.raisedByPhone,
  'emergency_contacts': instance.emergencyContacts.map((e) => e.toJson()).toList(),
  'trip': instance.trip.toJson(),
  'passenger': instance.passenger.toJson(),
  'driver': instance.driver.toJson(),
  'track': instance.track.map((e) => e.toJson()).toList(),
  'notes': instance.notes.map((e) => e.toJson()).toList(),
  'related_alert_ids': instance.relatedAlertIds,
  'recording_url': instance.recordingUrl,
  'raised_by_alerts': instance.raisedByAlerts,
  'raised_by_false_alarms': instance.raisedByFalseAlarms,
};

_ShareLink _$ShareLinkFromJson(Map<String, dynamic> json) =>
    _ShareLink(token: json['token'] as String, url: json['url'] as String);

Map<String, dynamic> _$ShareLinkToJson(_ShareLink instance) => <String, dynamic>{
  'token': instance.token,
  'url': instance.url,
};
