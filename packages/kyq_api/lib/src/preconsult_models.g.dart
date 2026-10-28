// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preconsult_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Preconsult _$PreconsultFromJson(Map<String, dynamic> json) => _Preconsult(
  id: json['id'] as String,
  passengerId: json['passenger_id'] as String,
  passengerName: json['passenger_name'] as String,
  driverId: json['driver_id'] as String,
  driverName: json['driver_name'] as String,
  status: $enumDecode(_$PreconsultStatusEnumMap, json['status'], unknownValue: PreconsultStatus.unknown),
  openedAt: DateTime.parse(json['opened_at'] as String),
  joinDeadline: DateTime.parse(json['join_deadline'] as String),
  closesAt: DateTime.parse(json['closes_at'] as String),
  joinedAt: json['joined_at'] == null ? null : DateTime.parse(json['joined_at'] as String),
  answeredAt: json['answered_at'] == null ? null : DateTime.parse(json['answered_at'] as String),
  closedAt: json['closed_at'] == null ? null : DateTime.parse(json['closed_at'] as String),
  closeReason: $enumDecodeNullable(
    _$PreconsultCloseReasonEnumMap,
    json['close_reason'],
    unknownValue: PreconsultCloseReason.unknown,
  ),
);

Map<String, dynamic> _$PreconsultToJson(_Preconsult instance) => <String, dynamic>{
  'id': instance.id,
  'passenger_id': instance.passengerId,
  'passenger_name': instance.passengerName,
  'driver_id': instance.driverId,
  'driver_name': instance.driverName,
  'status': _$PreconsultStatusEnumMap[instance.status]!,
  'opened_at': instance.openedAt.toIso8601String(),
  'join_deadline': instance.joinDeadline.toIso8601String(),
  'closes_at': instance.closesAt.toIso8601String(),
  'joined_at': instance.joinedAt?.toIso8601String(),
  'answered_at': instance.answeredAt?.toIso8601String(),
  'closed_at': instance.closedAt?.toIso8601String(),
  'close_reason': _$PreconsultCloseReasonEnumMap[instance.closeReason],
};

const _$PreconsultStatusEnumMap = {
  PreconsultStatus.open: 'open',
  PreconsultStatus.answered: 'answered',
  PreconsultStatus.unanswered: 'unanswered',
  PreconsultStatus.missed: 'missed',
  PreconsultStatus.unknown: 'unknown',
};

const _$PreconsultCloseReasonEnumMap = {
  PreconsultCloseReason.endedByPassenger: 'ended_by_passenger',
  PreconsultCloseReason.endedByDriver: 'ended_by_driver',
  PreconsultCloseReason.disabled: 'disabled',
  PreconsultCloseReason.missed: 'missed',
  PreconsultCloseReason.driverUnavailable: 'driver_unavailable',
  PreconsultCloseReason.expired: 'expired',
  PreconsultCloseReason.unknown: 'unknown',
};

_PreconsultSettings _$PreconsultSettingsFromJson(Map<String, dynamic> json) => _PreconsultSettings(
  acceptsPreconsults: json['accepts_preconsults'] as bool,
  blockedPassengerIds:
      (json['blocked_passenger_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
);

Map<String, dynamic> _$PreconsultSettingsToJson(_PreconsultSettings instance) => <String, dynamic>{
  'accepts_preconsults': instance.acceptsPreconsults,
  'blocked_passenger_ids': instance.blockedPassengerIds,
};
