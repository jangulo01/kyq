// Modelos de specs/007-control-tower-crm/contracts/api.yaml: torre de control, finanzas,
// fidelización, moderación y salud (solo panel de administración).
import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';

part 'admin_models.freezed.dart';
part 'admin_models.g.dart';

/// Nivel de presión de un hexágono: solicitudes frente a conductores libres.
enum PressureLevel {
  none,
  balanced,
  high,
  @JsonValue('no_supply')
  noSupply,
}

@freezed
abstract class TowerTotals with _$TowerTotals {
  const factory TowerTotals({
    @Default(0) int online,
    @Default(0) int free,
    @Default(0) int busy,
    @Default(0) int withoutLocation,
    @Default(0) int stale,
    @Default(0) int activeTrips,
    @Default(0) int requests,
    @Default(0) int unservedRequests,
  }) = _TowerTotals;

  factory TowerTotals.fromJson(Map<String, dynamic> json) => _$TowerTotalsFromJson(json);
}

/// Hexágono H3 con actividad.
@freezed
abstract class TowerCell with _$TowerCell {
  const factory TowerCell({
    required String cell,
    required GeoPoint center,
    @Default(<GeoPoint>[]) List<GeoPoint> boundary,
    @Default(0) int freeDrivers,
    @Default(0) int busyDrivers,
    @Default(0) int activeTrips,
    @Default(0) int requests,
    @Default(0) int unservedRequests,

    /// Solicitudes por conductor libre; null sin conductores libres.
    double? pressure,
    @JsonKey(unknownEnumValue: PressureLevel.none) @Default(PressureLevel.none) PressureLevel level,
  }) = _TowerCell;

  factory TowerCell.fromJson(Map<String, dynamic> json) => _$TowerCellFromJson(json);
}

/// Conductor ONLINE dibujado en la torre.
@freezed
abstract class TowerDriver with _$TowerDriver {
  const factory TowerDriver({
    required String driverId,
    required String displayName,
    required DriverPresence presence,
    required double lat,
    required double lng,
    required DateTime locationAt,
    @Default(false) bool stale,
    required String cell,
  }) = _TowerDriver;

  factory TowerDriver.fromJson(Map<String, dynamic> json) => _$TowerDriverFromJson(json);
}

/// `GET /v1/admin/tower`.
@freezed
abstract class TowerSnapshot with _$TowerSnapshot {
  const factory TowerSnapshot({
    required DateTime generatedAt,
    required int resolution,
    @Default(60) int windowMinutes,
    @Default(120) int staleAfterSeconds,
    @Default(TowerTotals()) TowerTotals totals,
    @Default(<TowerCell>[]) List<TowerCell> cells,
    @Default(<TowerDriver>[]) List<TowerDriver> drivers,
  }) = _TowerSnapshot;

  factory TowerSnapshot.fromJson(Map<String, dynamic> json) => _$TowerSnapshotFromJson(json);
}

@freezed
abstract class FinanceConceptCost with _$FinanceConceptCost {
  const factory FinanceConceptCost({required String concept, @Default(0) double costMinor}) = _FinanceConceptCost;

  factory FinanceConceptCost.fromJson(Map<String, dynamic> json) => _$FinanceConceptCostFromJson(json);
}

/// Un mes de suscripciones frente a infraestructura.
@freezed
abstract class FinanceMonth with _$FinanceMonth {
  const factory FinanceMonth({
    required String month,
    @Default(0) int revenueMinor,
    @Default(0) double infraCostMinor,
    @Default(0) double marginMinor,
    double? marginPct,
    @Default(0) int drivers,
    @Default(0) int activeDrivers,
    @Default(0) int payingDrivers,
    @Default(0) int negativeMarginDrivers,
    double? costPerActiveDriverMinor,
    double? revenuePerPayingDriverMinor,
    @Default(<FinanceConceptCost>[]) List<FinanceConceptCost> costByConcept,
    @Default(false) bool ratesMissing,
  }) = _FinanceMonth;

  factory FinanceMonth.fromJson(Map<String, dynamic> json) => _$FinanceMonthFromJson(json);
}

@freezed
abstract class FinanceTotals with _$FinanceTotals {
  const factory FinanceTotals({
    @Default(0) int revenueMinor,
    @Default(0) double infraCostMinor,
    @Default(0) double marginMinor,
    double? marginPct,
  }) = _FinanceTotals;

  factory FinanceTotals.fromJson(Map<String, dynamic> json) => _$FinanceTotalsFromJson(json);
}

/// `GET /v1/admin/finance`; [months] del más antiguo al más reciente.
@freezed
abstract class FinanceReport with _$FinanceReport {
  const factory FinanceReport({
    @Default('COP') String currency,
    @Default(<FinanceMonth>[]) List<FinanceMonth> months,
    @Default(FinanceTotals()) FinanceTotals totals,
  }) = _FinanceReport;

  factory FinanceReport.fromJson(Map<String, dynamic> json) => _$FinanceReportFromJson(json);
}

@freezed
abstract class CrmWeek with _$CrmWeek {
  const factory CrmWeek({
    required DateTime weekStart,
    @Default(0) int created,
    @Default(0) int removed,
    @Default(0) int activeEnd,
  }) = _CrmWeek;

  factory CrmWeek.fromJson(Map<String, dynamic> json) => _$CrmWeekFromJson(json);
}

@freezed
abstract class CrmAffiliations with _$CrmAffiliations {
  const factory CrmAffiliations({
    @Default(0) int activeNow,
    @Default(0) int activeAtStart,
    @Default(0) int created,
    @Default(0) int removed,
    @Default(0) int net,
    double? churnRate,
    @Default(<CrmWeek>[]) List<CrmWeek> weekly,

    /// 008: altas por origen (`qr_scan`, `post_trip`, `link`).
    @Default(<String, int>{}) Map<String, int> createdBySource,
  }) = _CrmAffiliations;

  factory CrmAffiliations.fromJson(Map<String, dynamic> json) => _$CrmAffiliationsFromJson(json);
}

@freezed
abstract class CrmRepeat with _$CrmRepeat {
  const factory CrmRepeat({
    @Default(0) int pairs,
    @Default(0) int repeatPairs,
    double? repeatRate,
    @Default(0) int completedTrips,
    double? avgTripsPerPair,
  }) = _CrmRepeat;

  factory CrmRepeat.fromJson(Map<String, dynamic> json) => _$CrmRepeatFromJson(json);
}

/// SC-008 de 001: afiliaciones con petición de viaje en sus primeros 30 días.
@freezed
abstract class Sc008 with _$Sc008 {
  const factory Sc008({
    @Default(0) int matured,
    @JsonKey(name: 'with_request_30d') @Default(0) int withRequest30d,
    double? rate,
    @Default(0.8) double target,
    bool? met,
    @Default(0) int pending,
  }) = _Sc008;

  factory Sc008.fromJson(Map<String, dynamic> json) => _$Sc008FromJson(json);
}

@freezed
abstract class ChurnedDriver with _$ChurnedDriver {
  const factory ChurnedDriver({
    required String driverId,
    required String displayName,
    @Default(0) int removed,
    @Default(0) int activeNow,
  }) = _ChurnedDriver;

  factory ChurnedDriver.fromJson(Map<String, dynamic> json) => _$ChurnedDriverFromJson(json);
}

@freezed
abstract class InactiveChosenDriver with _$InactiveChosenDriver {
  const factory InactiveChosenDriver({
    required String driverId,
    required String displayName,
    @Default(0) int activeAffiliations,
    DateTime? lastCompletedAt,
  }) = _InactiveChosenDriver;

  factory InactiveChosenDriver.fromJson(Map<String, dynamic> json) => _$InactiveChosenDriverFromJson(json);
}

/// `GET /v1/admin/crm`.
@freezed
abstract class CrmReport with _$CrmReport {
  const factory CrmReport({
    required DateTime from,
    required DateTime to,
    @Default(CrmAffiliations()) CrmAffiliations affiliations,
    @Default(CrmRepeat()) CrmRepeat repeat,
    @Default(Sc008()) Sc008 sc008,
    @Default(<ChurnedDriver>[]) List<ChurnedDriver> churnedDrivers,
    @Default(<InactiveChosenDriver>[]) List<InactiveChosenDriver> inactiveChosenDrivers,
  }) = _CrmReport;

  factory CrmReport.fromJson(Map<String, dynamic> json) => _$CrmReportFromJson(json);
}

/// Usuario en la pantalla de moderación.
@freezed
abstract class ModeratedUser with _$ModeratedUser {
  const ModeratedUser._();

  const factory ModeratedUser({
    required String userId,
    required String displayName,
    required String phoneE164,
    required UserRole role,
    required DateTime createdAt,
    DateTime? suspendedAt,
    String? suspensionReason,
  }) = _ModeratedUser;

  factory ModeratedUser.fromJson(Map<String, dynamic> json) => _$ModeratedUserFromJson(json);

  bool get suspended => suspendedAt != null;
}

enum ModerationKind { suspend, reactivate }

/// Entrada del historial de moderación de un usuario.
@freezed
abstract class ModerationAction with _$ModerationAction {
  const factory ModerationAction({
    required String id,
    required ModerationKind action,
    required String reason,
    required String actorId,
    required String actorName,
    required DateTime createdAt,
  }) = _ModerationAction;

  factory ModerationAction.fromJson(Map<String, dynamic> json) => _$ModerationActionFromJson(json);
}

enum HealthStatus { ok, down, disabled, degraded }

@freezed
abstract class HealthCheck with _$HealthCheck {
  const factory HealthCheck({
    required String name,
    @JsonKey(unknownEnumValue: HealthStatus.down) required HealthStatus status,
    int? latencyMs,
    @Default('') String detail,
  }) = _HealthCheck;

  factory HealthCheck.fromJson(Map<String, dynamic> json) => _$HealthCheckFromJson(json);
}

/// `GET /v1/admin/health`.
@freezed
abstract class HealthReport with _$HealthReport {
  const factory HealthReport({
    @JsonKey(unknownEnumValue: HealthStatus.down) required HealthStatus status,
    required DateTime checkedAt,
    @Default(<HealthCheck>[]) List<HealthCheck> checks,
  }) = _HealthReport;

  factory HealthReport.fromJson(Map<String, dynamic> json) => _$HealthReportFromJson(json);
}
