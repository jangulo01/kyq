// Modelos de specs/005-ptt-extras/contracts/api.yaml: pre-consulta de voz (RN-KYQ-010).
import 'package:freezed_annotation/freezed_annotation.dart';

part 'preconsult_models.freezed.dart';
part 'preconsult_models.g.dart';

/// Estado derivado de una consulta.
enum PreconsultStatus {
  open,
  answered,
  unanswered,
  missed,
  @JsonValue('unknown')
  unknown,
}

/// Motivo de cierre de una consulta.
enum PreconsultCloseReason {
  @JsonValue('ended_by_passenger')
  endedByPassenger,
  @JsonValue('ended_by_driver')
  endedByDriver,
  disabled,
  missed,
  @JsonValue('driver_unavailable')
  driverUnavailable,
  expired,
  @JsonValue('unknown')
  unknown,
}

PreconsultCloseReason preconsultCloseReasonFromApi(String? value) =>
    _$PreconsultCloseReasonEnumMap.entries.where((e) => e.value == value).firstOrNull?.key ??
    PreconsultCloseReason.unknown;

/// Consulta de voz entre un pasajero y su Conductor Elegido.
@freezed
abstract class Preconsult with _$Preconsult {
  const factory Preconsult({
    required String id,
    required String passengerId,
    required String passengerName,
    required String driverId,
    required String driverName,
    @JsonKey(unknownEnumValue: PreconsultStatus.unknown) required PreconsultStatus status,
    required DateTime openedAt,
    required DateTime joinDeadline,
    required DateTime closesAt,
    DateTime? joinedAt,
    DateTime? answeredAt,
    DateTime? closedAt,
    @JsonKey(unknownEnumValue: PreconsultCloseReason.unknown) PreconsultCloseReason? closeReason,
  }) = _Preconsult;

  const Preconsult._();

  factory Preconsult.fromJson(Map<String, dynamic> json) => _$PreconsultFromJson(json);

  bool get isOpen => status == PreconsultStatus.open;
}

/// Ajustes de consultas de voz del conductor.
@freezed
abstract class PreconsultSettings with _$PreconsultSettings {
  const factory PreconsultSettings({
    required bool acceptsPreconsults,
    @Default(<String>[]) List<String> blockedPassengerIds,
  }) = _PreconsultSettings;

  factory PreconsultSettings.fromJson(Map<String, dynamic> json) => _$PreconsultSettingsFromJson(json);
}
