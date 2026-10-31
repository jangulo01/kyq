// Modelos de 011 Radio Kyq (specs/001-…/contracts/api.yaml). Nunca traen teléfonos (FR-004).
import 'package:freezed_annotation/freezed_annotation.dart';

part 'radio_models.freezed.dart';
part 'radio_models.g.dart';

/// Acceso efectivo a Radio (FR-005).
enum RadioAccess { full, listen, none }

/// Estado de radio de una persona (FR-019).
enum RadioPresence {
  available,
  busy,
  @JsonValue('listen_only')
  listenOnly,
  offline,
}

enum RadioConversationKind { direct, client, channel, cooperative }

/// Roles de un canal (FR-016).
enum RadioRole { owner, moderator, member, listener }

enum RadioMemberStatus { pending, active, muted, blocked }

enum RadioMessageKind { voice, text, photo, location, alert, emergency }

/// Modo del botón grande (FR-007).
enum RadioPushMode { hold, toggle }

@freezed
abstract class RadioMe with _$RadioMe {
  const factory RadioMe({
    @JsonKey(unknownEnumValue: RadioAccess.none) required RadioAccess access,
    String? accessReason,
    int? trialDaysLeft,
    @JsonKey(unknownEnumValue: RadioPresence.available) required RadioPresence status,
    required bool radioOn,
    @JsonKey(unknownEnumValue: RadioPushMode.hold) required RadioPushMode pushMode,
    required bool consentRequired,
    @Default(30) int retentionDays,

    /// Solo conductores: "Radio con mis clientes" (FR-003).
    bool? clientsEnabled,
  }) = _RadioMe;

  factory RadioMe.fromJson(Map<String, dynamic> json) => _$RadioMeFromJson(json);
}

@freezed
abstract class RadioConversation with _$RadioConversation {
  const factory RadioConversation({
    required String id,
    @JsonKey(unknownEnumValue: RadioConversationKind.channel) required RadioConversationKind kind,
    required String title,
    String? photoUrl,
    String? peerId,
    @JsonKey(unknownEnumValue: RadioPresence.offline) RadioPresence? peerStatus,
    @Default(false) bool peerMuted,
    @Default(false) bool peerBlocked,
    int? onlineCount,
    @JsonKey(unknownEnumValue: RadioRole.member) RadioRole? myRole,
    @Default('active') String myMemberStatus,
    required bool listening,
    required int unreadCount,
    DateTime? lastMessageAt,
    @Default('active') String status,
    @Default(false) bool canTalk,
  }) = _RadioConversation;

  factory RadioConversation.fromJson(Map<String, dynamic> json) => _$RadioConversationFromJson(json);
}

extension RadioConversationX on RadioConversation {
  bool get isChannel => kind == RadioConversationKind.channel || kind == RadioConversationKind.cooperative;
  bool get suspended => status == 'suspended';
  bool get pending => myMemberStatus == 'pending';
  bool get moderates => myRole == RadioRole.owner || myRole == RadioRole.moderator;
}

@freezed
abstract class RadioMember with _$RadioMember {
  const factory RadioMember({
    required String userId,
    required String displayName,
    @JsonKey(unknownEnumValue: RadioRole.member) required RadioRole role,
    @JsonKey(unknownEnumValue: RadioMemberStatus.active) required RadioMemberStatus status,
    @JsonKey(unknownEnumValue: RadioPresence.offline) required RadioPresence presence,
    @Default(false) bool isPassenger,
  }) = _RadioMember;

  factory RadioMember.fromJson(Map<String, dynamic> json) => _$RadioMemberFromJson(json);
}

/// Detalle de una conversación: la fila de la lista más los datos del canal y sus miembros.
class RadioConversationDetail {
  const RadioConversationDetail({
    required this.conversation,
    this.description,
    this.joinMode,
    this.passengerRoleMax,
    this.members = const [],
  });

  factory RadioConversationDetail.fromJson(Map<String, dynamic> json) => RadioConversationDetail(
    conversation: RadioConversation.fromJson(json),
    description: json['description'] as String?,
    joinMode: json['join_mode'] as String?,
    passengerRoleMax: switch (json['passenger_role_max']) {
      final String r => RadioRole.values.firstWhere((v) => v.name == r, orElse: () => RadioRole.listener),
      _ => null,
    },
    members: [
      for (final m in (json['members'] as List<dynamic>? ?? const [])) RadioMember.fromJson(m as Map<String, dynamic>),
    ],
  );

  final RadioConversation conversation;
  final String? description;

  /// `open_link` o `approval`.
  final String? joinMode;
  final RadioRole? passengerRoleMax;
  final List<RadioMember> members;
}

@freezed
abstract class RadioMessage with _$RadioMessage {
  const factory RadioMessage({
    required String id,
    required String conversationId,
    String? authorId,
    @Default('') String authorName,
    @JsonKey(unknownEnumValue: RadioMessageKind.text) required RadioMessageKind kind,
    @Default('ready') String status,
    String? body,
    double? lat,
    double? lng,
    int? durationMs,
    @Default(false) bool hasMedia,
    required DateTime createdAt,
    DateTime? expiresAt,
    @Default(false) bool heard,
    @Default(false) bool saved,
  }) = _RadioMessage;

  factory RadioMessage.fromJson(Map<String, dynamic> json) => _$RadioMessageFromJson(json);
}

/// Credenciales de la sala de una conversación: solo escuchar; hablar llega con el turno.
@freezed
abstract class RadioCredentials with _$RadioCredentials {
  const factory RadioCredentials({
    required String url,
    required String token,
    required String room,
    required DateTime expiresAt,
  }) = _RadioCredentials;

  factory RadioCredentials.fromJson(Map<String, dynamic> json) => _$RadioCredentialsFromJson(json);
}

@freezed
abstract class RadioFloor with _$RadioFloor {
  const factory RadioFloor({required String messageId, required DateTime expiresAt}) = _RadioFloor;

  factory RadioFloor.fromJson(Map<String, dynamic> json) => _$RadioFloorFromJson(json);
}

@freezed
abstract class RadioInvite with _$RadioInvite {
  const factory RadioInvite({required String code, required String url, required DateTime expiresAt}) = _RadioInvite;

  factory RadioInvite.fromJson(Map<String, dynamic> json) => _$RadioInviteFromJson(json);
}

@freezed
abstract class RadioInvitePreview with _$RadioInvitePreview {
  const factory RadioInvitePreview({
    /// `contact` o `channel`.
    required String kind,
    required String inviterName,
    String? channelName,

    /// `driver` o `passenger`: qué app abre la invitación.
    required String inviteeKind,
  }) = _RadioInvitePreview;

  factory RadioInvitePreview.fromJson(Map<String, dynamic> json) => _$RadioInvitePreviewFromJson(json);
}

/// Resultado de aceptar una invitación: la conversación, o pendiente de aprobación (202).
class RadioAcceptResult {
  const RadioAcceptResult(this.conversation, {this.pending = false});

  final RadioConversation conversation;
  final bool pending;
}

@freezed
abstract class RadioQuietHours with _$RadioQuietHours {
  const factory RadioQuietHours({
    /// 1 = lunes … 7 = domingo.
    required List<int> weekdays,

    /// "22:00".
    required String starts,
    required String ends,
    @Default(true) bool enabled,
  }) = _RadioQuietHours;

  factory RadioQuietHours.fromJson(Map<String, dynamic> json) => _$RadioQuietHoursFromJson(json);
}

@freezed
abstract class RadioPhotoUpload with _$RadioPhotoUpload {
  const factory RadioPhotoUpload({
    required String messageId,
    required String uploadUrl,
    @Default('image/jpeg') String contentType,
  }) = _RadioPhotoUpload;

  factory RadioPhotoUpload.fromJson(Map<String, dynamic> json) => _$RadioPhotoUploadFromJson(json);
}

@freezed
abstract class RadioEmergency with _$RadioEmergency {
  const factory RadioEmergency({required String alertId, String? tripId}) = _RadioEmergency;

  factory RadioEmergency.fromJson(Map<String, dynamic> json) => _$RadioEmergencyFromJson(json);
}

// Panel (FR-033–FR-040)

@freezed
abstract class RadioSettings with _$RadioSettings {
  const factory RadioSettings({
    /// `trial`, `subscription_only` o `listen_only`.
    required String trialPolicy,
    required int trialDays,

    /// `none`, `listen_only` o `all_roles`.
    required String passengersInChannels,
    required int retentionDays,
    DateTime? updatedAt,
    @Default('') String updatedByName,

    /// Costo mensual estimado por retención ("7", "30", "90"), en unidades mínimas.
    @Default(<String, int>{}) Map<String, int> estimatedMonthlyCostMinor,
  }) = _RadioSettings;

  factory RadioSettings.fromJson(Map<String, dynamic> json) => _$RadioSettingsFromJson(json);
}

@freezed
abstract class RadioBulkUpload with _$RadioBulkUpload {
  const factory RadioBulkUpload({
    required String id,
    required String fileName,

    /// `validated`, `sending` o `done`.
    required String status,
    required int rowsTotal,
    @Default(<String, int>{}) Map<String, int> counts,
    required DateTime createdAt,
  }) = _RadioBulkUpload;

  factory RadioBulkUpload.fromJson(Map<String, dynamic> json) => _$RadioBulkUploadFromJson(json);
}

@freezed
abstract class RadioBulkRow with _$RadioBulkRow {
  const factory RadioBulkRow({
    required int line,
    @Default('') String name,
    @Default('') String phoneMasked,
    @Default('driver') String kind,
    @Default('') String channel,
    @JsonKey(unknownEnumValue: RadioRole.member) RadioRole? role,

    /// `pending`, `sent`, `failed`, `accepted`, `already_member` o `expired`.
    required String status,
    String? error,
  }) = _RadioBulkRow;

  factory RadioBulkRow.fromJson(Map<String, dynamic> json) => _$RadioBulkRowFromJson(json);
}

/// Detalle de una carga masiva: sus totales y el estado de cada fila.
class RadioBulkUploadDetail {
  const RadioBulkUploadDetail({required this.upload, this.rows = const []});

  factory RadioBulkUploadDetail.fromJson(Map<String, dynamic> json) => RadioBulkUploadDetail(
    upload: RadioBulkUpload.fromJson(json),
    rows: [
      for (final r in (json['rows'] as List<dynamic>? ?? const [])) RadioBulkRow.fromJson(r as Map<String, dynamic>),
    ],
  );

  final RadioBulkUpload upload;
  final List<RadioBulkRow> rows;
}

@freezed
abstract class RadioReport with _$RadioReport {
  const factory RadioReport({
    required String id,
    required String messageKind,
    required String conversationTitle,
    @Default('') String reason,
    required DateTime createdAt,
  }) = _RadioReport;

  factory RadioReport.fromJson(Map<String, dynamic> json) => _$RadioReportFromJson(json);
}

/// Un reporte abierto en el panel: solo ese mensaje y su contexto mínimo (FR-036, FR-037).
class RadioReportDetail {
  const RadioReportDetail({required this.report, required this.message, this.mediaUrl, this.authorName = ''});

  factory RadioReportDetail.fromJson(Map<String, dynamic> json) => RadioReportDetail(
    report: RadioReport.fromJson(json),
    message: RadioMessage.fromJson(json['message'] as Map<String, dynamic>),
    mediaUrl: json['media_url'] as String?,
    authorName: json['author_name'] as String? ?? '',
  );

  final RadioReport report;
  final RadioMessage message;
  final String? mediaUrl;
  final String authorName;
}

/// Rutas de Radio que usan las apps (paquete kyq_radio), detrás de una interfaz para probar sin red.
abstract interface class RadioApi {
  Future<RadioMe> radioMe();

  Future<RadioMe> updateRadioMe({RadioPresence? status, bool? radioOn, RadioPushMode? pushMode});

  Future<void> acceptRadioConsent();

  Future<void> radioHeartbeat();

  Future<List<RadioQuietHours>> radioQuietHours();

  Future<void> setRadioQuietHours(List<RadioQuietHours> rules);

  Future<List<RadioConversation>> radioConversations();

  Future<RadioConversationDetail> radioConversation(String id);

  Future<void> deleteRadioConversation(String id);

  Future<void> setRadioListening(String id, bool listening);

  Future<RadioCredentials> radioToken(String conversationId);

  Future<RadioFloor> takeRadioFloor(String conversationId);

  Future<void> releaseRadioFloor(String conversationId);

  Future<List<RadioMessage>> radioMessages(String conversationId, {String? before, int limit});

  Future<RadioMessage> sendRadioText(String conversationId, String body);

  Future<RadioMessage> sendRadioLocation(String conversationId, double lat, double lng, {String? label});

  Future<RadioMessage> sendRadioAlert(String conversationId, {String? body});

  Future<RadioPhotoUpload> reserveRadioPhoto(String conversationId);

  Future<void> uploadRadioPhoto(String uploadUrl, List<int> jpeg);

  Future<void> confirmRadioPhoto(String messageId);

  Future<String> radioMediaUrl(String messageId);

  Future<void> setRadioReceipt(String messageId, {bool? heard, bool? saved});

  Future<void> reportRadioMessage(String messageId, {String reason});

  /// Sin GPS [lat] y [lng] van nulos: la emergencia sale igual (FR-030).
  Future<RadioEmergency> radioEmergency(String conversationId, {double? lat, double? lng});

  /// Con teléfono devuelve null: el SMS sale sin revelar si la cuenta existe (FR-002).
  Future<RadioInvite?> inviteRadioContact({String? phoneE164});

  Future<RadioInvitePreview> radioInvitePreview(String code);

  Future<RadioAcceptResult> acceptRadioInvite(String code);

  Future<void> setRadioClients(bool enabled);

  Future<void> setRadioClient(String passengerId, {bool? muted, bool? blocked});

  Future<RadioConversation> createRadioChannel({
    required String name,
    String? description,
    String joinMode,
    RadioRole? passengerRoleMax,
  });

  Future<RadioConversation> updateRadioChannel(
    String id, {
    String? name,
    String? description,
    String? joinMode,
    RadioRole? passengerRoleMax,
    bool setPassengerRole,
  });

  Future<RadioInvite> radioChannelInvite(String id);

  /// [action]: approve, reject, mute, unmute, remove, block o unblock.
  Future<void> moderateRadioMember(String conversationId, String userId, {String? action, RadioRole? role});

  Future<void> leaveRadioChannel(String id);
}
