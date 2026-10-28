// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooperative_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CooperativeRef _$CooperativeRefFromJson(Map<String, dynamic> json) =>
    _CooperativeRef(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$CooperativeRefToJson(_CooperativeRef instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

_Cooperative _$CooperativeFromJson(Map<String, dynamic> json) => _Cooperative(
  id: json['id'] as String,
  name: json['name'] as String,
  cityCode: json['city_code'] as String,
  nit: json['nit'] as String?,
  status: $enumDecode(_$CooperativeStatusEnumMap, json['status']),
  membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
  pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CooperativeToJson(_Cooperative instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'city_code': instance.cityCode,
  'nit': instance.nit,
  'status': _$CooperativeStatusEnumMap[instance.status]!,
  'members_count': instance.membersCount,
  'pending_count': instance.pendingCount,
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$CooperativeStatusEnumMap = {CooperativeStatus.active: 'active', CooperativeStatus.suspended: 'suspended'};

_CooperativeMember _$CooperativeMemberFromJson(Map<String, dynamic> json) => _CooperativeMember(
  membershipId: json['membership_id'] as String,
  driverId: json['driver_id'] as String,
  displayName: json['display_name'] as String,
  vehiclePlate: json['vehicle_plate'] as String,
  role: $enumDecode(_$CooperativeRoleEnumMap, json['role']),
  presence: json['presence'] as String? ?? DriverPresenceName.offline,
  since: json['since'] == null ? null : DateTime.parse(json['since'] as String),
);

Map<String, dynamic> _$CooperativeMemberToJson(_CooperativeMember instance) => <String, dynamic>{
  'membership_id': instance.membershipId,
  'driver_id': instance.driverId,
  'display_name': instance.displayName,
  'vehicle_plate': instance.vehiclePlate,
  'role': _$CooperativeRoleEnumMap[instance.role]!,
  'presence': instance.presence,
  'since': instance.since?.toIso8601String(),
};

const _$CooperativeRoleEnumMap = {CooperativeRole.member: 'member', CooperativeRole.coordinator: 'coordinator'};

_MembershipRequest _$MembershipRequestFromJson(Map<String, dynamic> json) => _MembershipRequest(
  membershipId: json['membership_id'] as String,
  driverId: json['driver_id'] as String,
  displayName: json['display_name'] as String,
  vehiclePlate: json['vehicle_plate'] as String,
  requestedAt: DateTime.parse(json['requested_at'] as String),
);

Map<String, dynamic> _$MembershipRequestToJson(_MembershipRequest instance) => <String, dynamic>{
  'membership_id': instance.membershipId,
  'driver_id': instance.driverId,
  'display_name': instance.displayName,
  'vehicle_plate': instance.vehiclePlate,
  'requested_at': instance.requestedAt.toIso8601String(),
};

_Membership _$MembershipFromJson(Map<String, dynamic> json) => _Membership(
  id: json['id'] as String,
  cooperative: CooperativeRef.fromJson(json['cooperative'] as Map<String, dynamic>),
  cooperativeStatus:
      $enumDecodeNullable(_$CooperativeStatusEnumMap, json['cooperative_status']) ?? CooperativeStatus.active,
  role: $enumDecode(_$CooperativeRoleEnumMap, json['role']),
  status: $enumDecode(_$MembershipStatusEnumMap, json['status']),
  rejectReason: json['reject_reason'] as String?,
  requestedAt: json['requested_at'] == null ? null : DateTime.parse(json['requested_at'] as String),
  decidedAt: json['decided_at'] == null ? null : DateTime.parse(json['decided_at'] as String),
);

Map<String, dynamic> _$MembershipToJson(_Membership instance) => <String, dynamic>{
  'id': instance.id,
  'cooperative': instance.cooperative.toJson(),
  'cooperative_status': _$CooperativeStatusEnumMap[instance.cooperativeStatus]!,
  'role': _$CooperativeRoleEnumMap[instance.role]!,
  'status': _$MembershipStatusEnumMap[instance.status]!,
  'reject_reason': instance.rejectReason,
  'requested_at': instance.requestedAt?.toIso8601String(),
  'decided_at': instance.decidedAt?.toIso8601String(),
};

const _$MembershipStatusEnumMap = {
  MembershipStatus.pending: 'pending',
  MembershipStatus.active: 'active',
  MembershipStatus.rejected: 'rejected',
  MembershipStatus.cancelled: 'cancelled',
  MembershipStatus.left: 'left',
  MembershipStatus.removed: 'removed',
};

_CooperativeDetail _$CooperativeDetailFromJson(Map<String, dynamic> json) => _CooperativeDetail(
  cooperative: Cooperative.fromJson(json['cooperative'] as Map<String, dynamic>),
  members:
      (json['members'] as List<dynamic>?)?.map((e) => CooperativeMember.fromJson(e as Map<String, dynamic>)).toList() ??
      const <CooperativeMember>[],
  requests:
      (json['requests'] as List<dynamic>?)
          ?.map((e) => MembershipRequest.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MembershipRequest>[],
);

Map<String, dynamic> _$CooperativeDetailToJson(_CooperativeDetail instance) => <String, dynamic>{
  'cooperative': instance.cooperative.toJson(),
  'members': instance.members.map((e) => e.toJson()).toList(),
  'requests': instance.requests.map((e) => e.toJson()).toList(),
};

_DriverCooperative _$DriverCooperativeFromJson(Map<String, dynamic> json) => _DriverCooperative(
  membership: json['membership'] == null ? null : Membership.fromJson(json['membership'] as Map<String, dynamic>),
  members:
      (json['members'] as List<dynamic>?)?.map((e) => CooperativeMember.fromJson(e as Map<String, dynamic>)).toList() ??
      const <CooperativeMember>[],
  requests:
      (json['requests'] as List<dynamic>?)
          ?.map((e) => MembershipRequest.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MembershipRequest>[],
);

Map<String, dynamic> _$DriverCooperativeToJson(_DriverCooperative instance) => <String, dynamic>{
  'membership': instance.membership?.toJson(),
  'members': instance.members.map((e) => e.toJson()).toList(),
  'requests': instance.requests.map((e) => e.toJson()).toList(),
};
