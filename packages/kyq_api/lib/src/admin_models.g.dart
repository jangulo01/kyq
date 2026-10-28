// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TowerTotals _$TowerTotalsFromJson(Map<String, dynamic> json) => _TowerTotals(
  online: (json['online'] as num?)?.toInt() ?? 0,
  free: (json['free'] as num?)?.toInt() ?? 0,
  busy: (json['busy'] as num?)?.toInt() ?? 0,
  withoutLocation: (json['without_location'] as num?)?.toInt() ?? 0,
  stale: (json['stale'] as num?)?.toInt() ?? 0,
  activeTrips: (json['active_trips'] as num?)?.toInt() ?? 0,
  requests: (json['requests'] as num?)?.toInt() ?? 0,
  unservedRequests: (json['unserved_requests'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TowerTotalsToJson(_TowerTotals instance) => <String, dynamic>{
  'online': instance.online,
  'free': instance.free,
  'busy': instance.busy,
  'without_location': instance.withoutLocation,
  'stale': instance.stale,
  'active_trips': instance.activeTrips,
  'requests': instance.requests,
  'unserved_requests': instance.unservedRequests,
};

_TowerCell _$TowerCellFromJson(Map<String, dynamic> json) => _TowerCell(
  cell: json['cell'] as String,
  center: GeoPoint.fromJson(json['center'] as Map<String, dynamic>),
  boundary:
      (json['boundary'] as List<dynamic>?)?.map((e) => GeoPoint.fromJson(e as Map<String, dynamic>)).toList() ??
      const <GeoPoint>[],
  freeDrivers: (json['free_drivers'] as num?)?.toInt() ?? 0,
  busyDrivers: (json['busy_drivers'] as num?)?.toInt() ?? 0,
  activeTrips: (json['active_trips'] as num?)?.toInt() ?? 0,
  requests: (json['requests'] as num?)?.toInt() ?? 0,
  unservedRequests: (json['unserved_requests'] as num?)?.toInt() ?? 0,
  pressure: (json['pressure'] as num?)?.toDouble(),
  level:
      $enumDecodeNullable(_$PressureLevelEnumMap, json['level'], unknownValue: PressureLevel.none) ??
      PressureLevel.none,
  tripIds: (json['trip_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
);

Map<String, dynamic> _$TowerCellToJson(_TowerCell instance) => <String, dynamic>{
  'cell': instance.cell,
  'center': instance.center.toJson(),
  'boundary': instance.boundary.map((e) => e.toJson()).toList(),
  'free_drivers': instance.freeDrivers,
  'busy_drivers': instance.busyDrivers,
  'active_trips': instance.activeTrips,
  'requests': instance.requests,
  'unserved_requests': instance.unservedRequests,
  'pressure': instance.pressure,
  'level': _$PressureLevelEnumMap[instance.level]!,
  'trip_ids': instance.tripIds,
};

const _$PressureLevelEnumMap = {
  PressureLevel.none: 'none',
  PressureLevel.balanced: 'balanced',
  PressureLevel.high: 'high',
  PressureLevel.noSupply: 'no_supply',
};

_TowerDriver _$TowerDriverFromJson(Map<String, dynamic> json) => _TowerDriver(
  driverId: json['driver_id'] as String,
  displayName: json['display_name'] as String,
  presence: $enumDecode(_$DriverPresenceEnumMap, json['presence']),
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  locationAt: DateTime.parse(json['location_at'] as String),
  stale: json['stale'] as bool? ?? false,
  cell: json['cell'] as String,
  activeTripId: json['active_trip_id'] as String?,
);

Map<String, dynamic> _$TowerDriverToJson(_TowerDriver instance) => <String, dynamic>{
  'driver_id': instance.driverId,
  'display_name': instance.displayName,
  'presence': _$DriverPresenceEnumMap[instance.presence]!,
  'lat': instance.lat,
  'lng': instance.lng,
  'location_at': instance.locationAt.toIso8601String(),
  'stale': instance.stale,
  'cell': instance.cell,
  'active_trip_id': instance.activeTripId,
};

const _$DriverPresenceEnumMap = {
  DriverPresence.offline: 'offline',
  DriverPresence.free: 'free',
  DriverPresence.busy: 'busy',
};

_TowerSnapshot _$TowerSnapshotFromJson(Map<String, dynamic> json) => _TowerSnapshot(
  generatedAt: DateTime.parse(json['generated_at'] as String),
  resolution: (json['resolution'] as num).toInt(),
  windowMinutes: (json['window_minutes'] as num?)?.toInt() ?? 60,
  staleAfterSeconds: (json['stale_after_seconds'] as num?)?.toInt() ?? 120,
  totals: json['totals'] == null ? const TowerTotals() : TowerTotals.fromJson(json['totals'] as Map<String, dynamic>),
  cells:
      (json['cells'] as List<dynamic>?)?.map((e) => TowerCell.fromJson(e as Map<String, dynamic>)).toList() ??
      const <TowerCell>[],
  drivers:
      (json['drivers'] as List<dynamic>?)?.map((e) => TowerDriver.fromJson(e as Map<String, dynamic>)).toList() ??
      const <TowerDriver>[],
);

Map<String, dynamic> _$TowerSnapshotToJson(_TowerSnapshot instance) => <String, dynamic>{
  'generated_at': instance.generatedAt.toIso8601String(),
  'resolution': instance.resolution,
  'window_minutes': instance.windowMinutes,
  'stale_after_seconds': instance.staleAfterSeconds,
  'totals': instance.totals.toJson(),
  'cells': instance.cells.map((e) => e.toJson()).toList(),
  'drivers': instance.drivers.map((e) => e.toJson()).toList(),
};

_FinanceConceptCost _$FinanceConceptCostFromJson(Map<String, dynamic> json) =>
    _FinanceConceptCost(concept: json['concept'] as String, costMinor: (json['cost_minor'] as num?)?.toDouble() ?? 0);

Map<String, dynamic> _$FinanceConceptCostToJson(_FinanceConceptCost instance) => <String, dynamic>{
  'concept': instance.concept,
  'cost_minor': instance.costMinor,
};

_FinanceMonth _$FinanceMonthFromJson(Map<String, dynamic> json) => _FinanceMonth(
  month: json['month'] as String,
  revenueMinor: (json['revenue_minor'] as num?)?.toInt() ?? 0,
  infraCostMinor: (json['infra_cost_minor'] as num?)?.toDouble() ?? 0,
  marginMinor: (json['margin_minor'] as num?)?.toDouble() ?? 0,
  marginPct: (json['margin_pct'] as num?)?.toDouble(),
  drivers: (json['drivers'] as num?)?.toInt() ?? 0,
  activeDrivers: (json['active_drivers'] as num?)?.toInt() ?? 0,
  payingDrivers: (json['paying_drivers'] as num?)?.toInt() ?? 0,
  negativeMarginDrivers: (json['negative_margin_drivers'] as num?)?.toInt() ?? 0,
  costPerActiveDriverMinor: (json['cost_per_active_driver_minor'] as num?)?.toDouble(),
  revenuePerPayingDriverMinor: (json['revenue_per_paying_driver_minor'] as num?)?.toDouble(),
  costByConcept:
      (json['cost_by_concept'] as List<dynamic>?)
          ?.map((e) => FinanceConceptCost.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <FinanceConceptCost>[],
  ratesMissing: json['rates_missing'] as bool? ?? false,
);

Map<String, dynamic> _$FinanceMonthToJson(_FinanceMonth instance) => <String, dynamic>{
  'month': instance.month,
  'revenue_minor': instance.revenueMinor,
  'infra_cost_minor': instance.infraCostMinor,
  'margin_minor': instance.marginMinor,
  'margin_pct': instance.marginPct,
  'drivers': instance.drivers,
  'active_drivers': instance.activeDrivers,
  'paying_drivers': instance.payingDrivers,
  'negative_margin_drivers': instance.negativeMarginDrivers,
  'cost_per_active_driver_minor': instance.costPerActiveDriverMinor,
  'revenue_per_paying_driver_minor': instance.revenuePerPayingDriverMinor,
  'cost_by_concept': instance.costByConcept.map((e) => e.toJson()).toList(),
  'rates_missing': instance.ratesMissing,
};

_FinanceTotals _$FinanceTotalsFromJson(Map<String, dynamic> json) => _FinanceTotals(
  revenueMinor: (json['revenue_minor'] as num?)?.toInt() ?? 0,
  infraCostMinor: (json['infra_cost_minor'] as num?)?.toDouble() ?? 0,
  marginMinor: (json['margin_minor'] as num?)?.toDouble() ?? 0,
  marginPct: (json['margin_pct'] as num?)?.toDouble(),
);

Map<String, dynamic> _$FinanceTotalsToJson(_FinanceTotals instance) => <String, dynamic>{
  'revenue_minor': instance.revenueMinor,
  'infra_cost_minor': instance.infraCostMinor,
  'margin_minor': instance.marginMinor,
  'margin_pct': instance.marginPct,
};

_FinanceReport _$FinanceReportFromJson(Map<String, dynamic> json) => _FinanceReport(
  currency: json['currency'] as String? ?? 'COP',
  months:
      (json['months'] as List<dynamic>?)?.map((e) => FinanceMonth.fromJson(e as Map<String, dynamic>)).toList() ??
      const <FinanceMonth>[],
  totals: json['totals'] == null
      ? const FinanceTotals()
      : FinanceTotals.fromJson(json['totals'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FinanceReportToJson(_FinanceReport instance) => <String, dynamic>{
  'currency': instance.currency,
  'months': instance.months.map((e) => e.toJson()).toList(),
  'totals': instance.totals.toJson(),
};

_CrmWeek _$CrmWeekFromJson(Map<String, dynamic> json) => _CrmWeek(
  weekStart: DateTime.parse(json['week_start'] as String),
  created: (json['created'] as num?)?.toInt() ?? 0,
  removed: (json['removed'] as num?)?.toInt() ?? 0,
  activeEnd: (json['active_end'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CrmWeekToJson(_CrmWeek instance) => <String, dynamic>{
  'week_start': instance.weekStart.toIso8601String(),
  'created': instance.created,
  'removed': instance.removed,
  'active_end': instance.activeEnd,
};

_CrmAffiliations _$CrmAffiliationsFromJson(Map<String, dynamic> json) => _CrmAffiliations(
  activeNow: (json['active_now'] as num?)?.toInt() ?? 0,
  activeAtStart: (json['active_at_start'] as num?)?.toInt() ?? 0,
  created: (json['created'] as num?)?.toInt() ?? 0,
  removed: (json['removed'] as num?)?.toInt() ?? 0,
  net: (json['net'] as num?)?.toInt() ?? 0,
  churnRate: (json['churn_rate'] as num?)?.toDouble(),
  weekly:
      (json['weekly'] as List<dynamic>?)?.map((e) => CrmWeek.fromJson(e as Map<String, dynamic>)).toList() ??
      const <CrmWeek>[],
  createdBySource:
      (json['created_by_source'] as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())) ??
      const <String, int>{},
);

Map<String, dynamic> _$CrmAffiliationsToJson(_CrmAffiliations instance) => <String, dynamic>{
  'active_now': instance.activeNow,
  'active_at_start': instance.activeAtStart,
  'created': instance.created,
  'removed': instance.removed,
  'net': instance.net,
  'churn_rate': instance.churnRate,
  'weekly': instance.weekly.map((e) => e.toJson()).toList(),
  'created_by_source': instance.createdBySource,
};

_CrmRepeat _$CrmRepeatFromJson(Map<String, dynamic> json) => _CrmRepeat(
  pairs: (json['pairs'] as num?)?.toInt() ?? 0,
  repeatPairs: (json['repeat_pairs'] as num?)?.toInt() ?? 0,
  repeatRate: (json['repeat_rate'] as num?)?.toDouble(),
  completedTrips: (json['completed_trips'] as num?)?.toInt() ?? 0,
  avgTripsPerPair: (json['avg_trips_per_pair'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CrmRepeatToJson(_CrmRepeat instance) => <String, dynamic>{
  'pairs': instance.pairs,
  'repeat_pairs': instance.repeatPairs,
  'repeat_rate': instance.repeatRate,
  'completed_trips': instance.completedTrips,
  'avg_trips_per_pair': instance.avgTripsPerPair,
};

_Sc008 _$Sc008FromJson(Map<String, dynamic> json) => _Sc008(
  matured: (json['matured'] as num?)?.toInt() ?? 0,
  withRequest30d: (json['with_request_30d'] as num?)?.toInt() ?? 0,
  rate: (json['rate'] as num?)?.toDouble(),
  target: (json['target'] as num?)?.toDouble() ?? 0.8,
  met: json['met'] as bool?,
  pending: (json['pending'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$Sc008ToJson(_Sc008 instance) => <String, dynamic>{
  'matured': instance.matured,
  'with_request_30d': instance.withRequest30d,
  'rate': instance.rate,
  'target': instance.target,
  'met': instance.met,
  'pending': instance.pending,
};

_ChurnedDriver _$ChurnedDriverFromJson(Map<String, dynamic> json) => _ChurnedDriver(
  driverId: json['driver_id'] as String,
  displayName: json['display_name'] as String,
  removed: (json['removed'] as num?)?.toInt() ?? 0,
  activeNow: (json['active_now'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ChurnedDriverToJson(_ChurnedDriver instance) => <String, dynamic>{
  'driver_id': instance.driverId,
  'display_name': instance.displayName,
  'removed': instance.removed,
  'active_now': instance.activeNow,
};

_InactiveChosenDriver _$InactiveChosenDriverFromJson(Map<String, dynamic> json) => _InactiveChosenDriver(
  driverId: json['driver_id'] as String,
  displayName: json['display_name'] as String,
  activeAffiliations: (json['active_affiliations'] as num?)?.toInt() ?? 0,
  lastCompletedAt: json['last_completed_at'] == null ? null : DateTime.parse(json['last_completed_at'] as String),
);

Map<String, dynamic> _$InactiveChosenDriverToJson(_InactiveChosenDriver instance) => <String, dynamic>{
  'driver_id': instance.driverId,
  'display_name': instance.displayName,
  'active_affiliations': instance.activeAffiliations,
  'last_completed_at': instance.lastCompletedAt?.toIso8601String(),
};

_CrmReport _$CrmReportFromJson(Map<String, dynamic> json) => _CrmReport(
  from: DateTime.parse(json['from'] as String),
  to: DateTime.parse(json['to'] as String),
  affiliations: json['affiliations'] == null
      ? const CrmAffiliations()
      : CrmAffiliations.fromJson(json['affiliations'] as Map<String, dynamic>),
  repeat: json['repeat'] == null ? const CrmRepeat() : CrmRepeat.fromJson(json['repeat'] as Map<String, dynamic>),
  sc008: json['sc008'] == null ? const Sc008() : Sc008.fromJson(json['sc008'] as Map<String, dynamic>),
  churnedDrivers:
      (json['churned_drivers'] as List<dynamic>?)
          ?.map((e) => ChurnedDriver.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ChurnedDriver>[],
  inactiveChosenDrivers:
      (json['inactive_chosen_drivers'] as List<dynamic>?)
          ?.map((e) => InactiveChosenDriver.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <InactiveChosenDriver>[],
);

Map<String, dynamic> _$CrmReportToJson(_CrmReport instance) => <String, dynamic>{
  'from': instance.from.toIso8601String(),
  'to': instance.to.toIso8601String(),
  'affiliations': instance.affiliations.toJson(),
  'repeat': instance.repeat.toJson(),
  'sc008': instance.sc008.toJson(),
  'churned_drivers': instance.churnedDrivers.map((e) => e.toJson()).toList(),
  'inactive_chosen_drivers': instance.inactiveChosenDrivers.map((e) => e.toJson()).toList(),
};

_ModeratedUser _$ModeratedUserFromJson(Map<String, dynamic> json) => _ModeratedUser(
  userId: json['user_id'] as String,
  displayName: json['display_name'] as String,
  phoneE164: json['phone_e164'] as String,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  createdAt: DateTime.parse(json['created_at'] as String),
  suspendedAt: json['suspended_at'] == null ? null : DateTime.parse(json['suspended_at'] as String),
  suspensionReason: json['suspension_reason'] as String?,
);

Map<String, dynamic> _$ModeratedUserToJson(_ModeratedUser instance) => <String, dynamic>{
  'user_id': instance.userId,
  'display_name': instance.displayName,
  'phone_e164': instance.phoneE164,
  'role': _$UserRoleEnumMap[instance.role]!,
  'created_at': instance.createdAt.toIso8601String(),
  'suspended_at': instance.suspendedAt?.toIso8601String(),
  'suspension_reason': instance.suspensionReason,
};

const _$UserRoleEnumMap = {UserRole.passenger: 'passenger', UserRole.driver: 'driver', UserRole.admin: 'admin'};

_ModerationAction _$ModerationActionFromJson(Map<String, dynamic> json) => _ModerationAction(
  id: json['id'] as String,
  action: $enumDecode(_$ModerationKindEnumMap, json['action']),
  reason: json['reason'] as String,
  actorId: json['actor_id'] as String,
  actorName: json['actor_name'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ModerationActionToJson(_ModerationAction instance) => <String, dynamic>{
  'id': instance.id,
  'action': _$ModerationKindEnumMap[instance.action]!,
  'reason': instance.reason,
  'actor_id': instance.actorId,
  'actor_name': instance.actorName,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$ModerationKindEnumMap = {ModerationKind.suspend: 'suspend', ModerationKind.reactivate: 'reactivate'};

_HealthCheck _$HealthCheckFromJson(Map<String, dynamic> json) => _HealthCheck(
  name: json['name'] as String,
  status: $enumDecode(_$HealthStatusEnumMap, json['status'], unknownValue: HealthStatus.down),
  latencyMs: (json['latency_ms'] as num?)?.toInt(),
  detail: json['detail'] as String? ?? '',
);

Map<String, dynamic> _$HealthCheckToJson(_HealthCheck instance) => <String, dynamic>{
  'name': instance.name,
  'status': _$HealthStatusEnumMap[instance.status]!,
  'latency_ms': instance.latencyMs,
  'detail': instance.detail,
};

const _$HealthStatusEnumMap = {
  HealthStatus.ok: 'ok',
  HealthStatus.down: 'down',
  HealthStatus.disabled: 'disabled',
  HealthStatus.degraded: 'degraded',
};

_HealthReport _$HealthReportFromJson(Map<String, dynamic> json) => _HealthReport(
  status: $enumDecode(_$HealthStatusEnumMap, json['status'], unknownValue: HealthStatus.down),
  checkedAt: DateTime.parse(json['checked_at'] as String),
  checks:
      (json['checks'] as List<dynamic>?)?.map((e) => HealthCheck.fromJson(e as Map<String, dynamic>)).toList() ??
      const <HealthCheck>[],
);

Map<String, dynamic> _$HealthReportToJson(_HealthReport instance) => <String, dynamic>{
  'status': _$HealthStatusEnumMap[instance.status]!,
  'checked_at': instance.checkedAt.toIso8601String(),
  'checks': instance.checks.map((e) => e.toJson()).toList(),
};
