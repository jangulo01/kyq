// Modelos de 006 (specs/006-cooperatives-delegation/contracts/api.yaml): cooperativas,
// membresías y despacho con delegación (RN-KYQ-008).
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cooperative_models.freezed.dart';
part 'cooperative_models.g.dart';

/// Cómo pide el pasajero (006, FR-009). 008 añade la opción 3, la bolsa zonal: el conductor libre
/// más cercano que la tenga activada, sin necesidad de un Conductor Elegido.
enum TripDispatch {
  @JsonValue('chosen_driver')
  chosenDriver,
  cooperative,
  @JsonValue('zone_pool')
  zonePool,
}

/// Valor de [TripDispatch] en la API.
String tripDispatchToApi(TripDispatch d) => switch (d) {
  TripDispatch.chosenDriver => 'chosen_driver',
  TripDispatch.cooperative => 'cooperative',
  TripDispatch.zonePool => 'zone_pool',
};

enum CooperativeStatus { active, suspended }

enum CooperativeRole { member, coordinator }

enum MembershipStatus { pending, active, rejected, cancelled, left, removed }

@freezed
abstract class CooperativeRef with _$CooperativeRef {
  const factory CooperativeRef({required String id, required String name}) = _CooperativeRef;

  factory CooperativeRef.fromJson(Map<String, dynamic> json) => _$CooperativeRefFromJson(json);
}

@freezed
abstract class Cooperative with _$Cooperative {
  const factory Cooperative({
    required String id,
    required String name,
    required String cityCode,
    String? nit,
    required CooperativeStatus status,
    @Default(0) int membersCount,
    @Default(0) int pendingCount,
    DateTime? createdAt,
  }) = _Cooperative;

  factory Cooperative.fromJson(Map<String, dynamic> json) => _$CooperativeFromJson(json);
}

@freezed
abstract class CooperativeMember with _$CooperativeMember {
  const factory CooperativeMember({
    required String membershipId,
    required String driverId,
    required String displayName,
    required String vehiclePlate,
    required CooperativeRole role,
    @Default(DriverPresenceName.offline) String presence,
    DateTime? since,
  }) = _CooperativeMember;

  factory CooperativeMember.fromJson(Map<String, dynamic> json) => _$CooperativeMemberFromJson(json);
}

/// Nombres de presencia como texto: los miembros llegan con `presence` del contrato.
abstract final class DriverPresenceName {
  static const offline = 'offline';
  static const free = 'free';
  static const busy = 'busy';
}

@freezed
abstract class MembershipRequest with _$MembershipRequest {
  const factory MembershipRequest({
    required String membershipId,
    required String driverId,
    required String displayName,
    required String vehiclePlate,
    required DateTime requestedAt,
  }) = _MembershipRequest;

  factory MembershipRequest.fromJson(Map<String, dynamic> json) => _$MembershipRequestFromJson(json);
}

@freezed
abstract class Membership with _$Membership {
  const factory Membership({
    required String id,
    required CooperativeRef cooperative,
    @Default(CooperativeStatus.active) CooperativeStatus cooperativeStatus,
    required CooperativeRole role,
    required MembershipStatus status,
    String? rejectReason,
    DateTime? requestedAt,
    DateTime? decidedAt,
  }) = _Membership;

  factory Membership.fromJson(Map<String, dynamic> json) => _$MembershipFromJson(json);
}

@freezed
abstract class CooperativeDetail with _$CooperativeDetail {
  const factory CooperativeDetail({
    required Cooperative cooperative,
    @Default(<CooperativeMember>[]) List<CooperativeMember> members,
    @Default(<MembershipRequest>[]) List<MembershipRequest> requests,
  }) = _CooperativeDetail;

  factory CooperativeDetail.fromJson(Map<String, dynamic> json) => _$CooperativeDetailFromJson(json);
}

/// `GET /v1/driver/cooperative`: membresía (activa, pendiente o la última rechazada), compañeros
/// y, para coordinadores, solicitudes pendientes.
@freezed
abstract class DriverCooperative with _$DriverCooperative {
  const factory DriverCooperative({
    Membership? membership,
    @Default(<CooperativeMember>[]) List<CooperativeMember> members,
    @Default(<MembershipRequest>[]) List<MembershipRequest> requests,
  }) = _DriverCooperative;

  factory DriverCooperative.fromJson(Map<String, dynamic> json) => _$DriverCooperativeFromJson(json);
}

/// Atajos de lectura para la app del conductor.
extension DriverCooperativeX on DriverCooperative {
  bool get isMember => membership?.status == MembershipStatus.active;

  bool get isPending => membership?.status == MembershipStatus.pending;

  bool get isCoordinator => isMember && membership?.role == CooperativeRole.coordinator;
}
