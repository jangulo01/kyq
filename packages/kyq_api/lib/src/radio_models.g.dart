// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radio_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RadioMe _$RadioMeFromJson(Map<String, dynamic> json) => _RadioMe(
  access: $enumDecode(_$RadioAccessEnumMap, json['access'], unknownValue: RadioAccess.none),
  accessReason: json['access_reason'] as String?,
  trialDaysLeft: (json['trial_days_left'] as num?)?.toInt(),
  status: $enumDecode(_$RadioPresenceEnumMap, json['status'], unknownValue: RadioPresence.available),
  radioOn: json['radio_on'] as bool,
  pushMode: $enumDecode(_$RadioPushModeEnumMap, json['push_mode'], unknownValue: RadioPushMode.hold),
  consentRequired: json['consent_required'] as bool,
  retentionDays: (json['retention_days'] as num?)?.toInt() ?? 30,
  clientsEnabled: json['clients_enabled'] as bool?,
);

Map<String, dynamic> _$RadioMeToJson(_RadioMe instance) => <String, dynamic>{
  'access': _$RadioAccessEnumMap[instance.access]!,
  'access_reason': instance.accessReason,
  'trial_days_left': instance.trialDaysLeft,
  'status': _$RadioPresenceEnumMap[instance.status]!,
  'radio_on': instance.radioOn,
  'push_mode': _$RadioPushModeEnumMap[instance.pushMode]!,
  'consent_required': instance.consentRequired,
  'retention_days': instance.retentionDays,
  'clients_enabled': instance.clientsEnabled,
};

const _$RadioAccessEnumMap = {RadioAccess.full: 'full', RadioAccess.listen: 'listen', RadioAccess.none: 'none'};

const _$RadioPresenceEnumMap = {
  RadioPresence.available: 'available',
  RadioPresence.busy: 'busy',
  RadioPresence.listenOnly: 'listen_only',
  RadioPresence.offline: 'offline',
};

const _$RadioPushModeEnumMap = {RadioPushMode.hold: 'hold', RadioPushMode.toggle: 'toggle'};

_RadioConversation _$RadioConversationFromJson(Map<String, dynamic> json) => _RadioConversation(
  id: json['id'] as String,
  kind: $enumDecode(_$RadioConversationKindEnumMap, json['kind'], unknownValue: RadioConversationKind.channel),
  title: json['title'] as String,
  photoUrl: json['photo_url'] as String?,
  peerId: json['peer_id'] as String?,
  peerStatus: $enumDecodeNullable(_$RadioPresenceEnumMap, json['peer_status'], unknownValue: RadioPresence.offline),
  peerMuted: json['peer_muted'] as bool? ?? false,
  onlineCount: (json['online_count'] as num?)?.toInt(),
  myRole: $enumDecodeNullable(_$RadioRoleEnumMap, json['my_role'], unknownValue: RadioRole.member),
  myMemberStatus: json['my_member_status'] as String? ?? 'active',
  listening: json['listening'] as bool,
  unreadCount: (json['unread_count'] as num).toInt(),
  lastMessageAt: json['last_message_at'] == null ? null : DateTime.parse(json['last_message_at'] as String),
  status: json['status'] as String? ?? 'active',
  canTalk: json['can_talk'] as bool? ?? false,
);

Map<String, dynamic> _$RadioConversationToJson(_RadioConversation instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$RadioConversationKindEnumMap[instance.kind]!,
  'title': instance.title,
  'photo_url': instance.photoUrl,
  'peer_id': instance.peerId,
  'peer_status': _$RadioPresenceEnumMap[instance.peerStatus],
  'peer_muted': instance.peerMuted,
  'online_count': instance.onlineCount,
  'my_role': _$RadioRoleEnumMap[instance.myRole],
  'my_member_status': instance.myMemberStatus,
  'listening': instance.listening,
  'unread_count': instance.unreadCount,
  'last_message_at': instance.lastMessageAt?.toIso8601String(),
  'status': instance.status,
  'can_talk': instance.canTalk,
};

const _$RadioConversationKindEnumMap = {
  RadioConversationKind.direct: 'direct',
  RadioConversationKind.client: 'client',
  RadioConversationKind.channel: 'channel',
  RadioConversationKind.cooperative: 'cooperative',
};

const _$RadioRoleEnumMap = {
  RadioRole.owner: 'owner',
  RadioRole.moderator: 'moderator',
  RadioRole.member: 'member',
  RadioRole.listener: 'listener',
};

_RadioMember _$RadioMemberFromJson(Map<String, dynamic> json) => _RadioMember(
  userId: json['user_id'] as String,
  displayName: json['display_name'] as String,
  role: $enumDecode(_$RadioRoleEnumMap, json['role'], unknownValue: RadioRole.member),
  status: $enumDecode(_$RadioMemberStatusEnumMap, json['status'], unknownValue: RadioMemberStatus.active),
  presence: $enumDecode(_$RadioPresenceEnumMap, json['presence'], unknownValue: RadioPresence.offline),
  isPassenger: json['is_passenger'] as bool? ?? false,
);

Map<String, dynamic> _$RadioMemberToJson(_RadioMember instance) => <String, dynamic>{
  'user_id': instance.userId,
  'display_name': instance.displayName,
  'role': _$RadioRoleEnumMap[instance.role]!,
  'status': _$RadioMemberStatusEnumMap[instance.status]!,
  'presence': _$RadioPresenceEnumMap[instance.presence]!,
  'is_passenger': instance.isPassenger,
};

const _$RadioMemberStatusEnumMap = {
  RadioMemberStatus.pending: 'pending',
  RadioMemberStatus.active: 'active',
  RadioMemberStatus.muted: 'muted',
  RadioMemberStatus.blocked: 'blocked',
};

_RadioMessage _$RadioMessageFromJson(Map<String, dynamic> json) => _RadioMessage(
  id: json['id'] as String,
  conversationId: json['conversation_id'] as String,
  authorId: json['author_id'] as String?,
  authorName: json['author_name'] as String? ?? '',
  kind: $enumDecode(_$RadioMessageKindEnumMap, json['kind'], unknownValue: RadioMessageKind.text),
  status: json['status'] as String? ?? 'ready',
  body: json['body'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  durationMs: (json['duration_ms'] as num?)?.toInt(),
  hasMedia: json['has_media'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
  expiresAt: json['expires_at'] == null ? null : DateTime.parse(json['expires_at'] as String),
  heard: json['heard'] as bool? ?? false,
  saved: json['saved'] as bool? ?? false,
);

Map<String, dynamic> _$RadioMessageToJson(_RadioMessage instance) => <String, dynamic>{
  'id': instance.id,
  'conversation_id': instance.conversationId,
  'author_id': instance.authorId,
  'author_name': instance.authorName,
  'kind': _$RadioMessageKindEnumMap[instance.kind]!,
  'status': instance.status,
  'body': instance.body,
  'lat': instance.lat,
  'lng': instance.lng,
  'duration_ms': instance.durationMs,
  'has_media': instance.hasMedia,
  'created_at': instance.createdAt.toIso8601String(),
  'expires_at': instance.expiresAt?.toIso8601String(),
  'heard': instance.heard,
  'saved': instance.saved,
};

const _$RadioMessageKindEnumMap = {
  RadioMessageKind.voice: 'voice',
  RadioMessageKind.text: 'text',
  RadioMessageKind.photo: 'photo',
  RadioMessageKind.location: 'location',
  RadioMessageKind.alert: 'alert',
  RadioMessageKind.emergency: 'emergency',
};

_RadioCredentials _$RadioCredentialsFromJson(Map<String, dynamic> json) => _RadioCredentials(
  url: json['url'] as String,
  token: json['token'] as String,
  room: json['room'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$RadioCredentialsToJson(_RadioCredentials instance) => <String, dynamic>{
  'url': instance.url,
  'token': instance.token,
  'room': instance.room,
  'expires_at': instance.expiresAt.toIso8601String(),
};

_RadioFloor _$RadioFloorFromJson(Map<String, dynamic> json) =>
    _RadioFloor(messageId: json['message_id'] as String, expiresAt: DateTime.parse(json['expires_at'] as String));

Map<String, dynamic> _$RadioFloorToJson(_RadioFloor instance) => <String, dynamic>{
  'message_id': instance.messageId,
  'expires_at': instance.expiresAt.toIso8601String(),
};

_RadioInvite _$RadioInviteFromJson(Map<String, dynamic> json) => _RadioInvite(
  code: json['code'] as String,
  url: json['url'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$RadioInviteToJson(_RadioInvite instance) => <String, dynamic>{
  'code': instance.code,
  'url': instance.url,
  'expires_at': instance.expiresAt.toIso8601String(),
};

_RadioInvitePreview _$RadioInvitePreviewFromJson(Map<String, dynamic> json) => _RadioInvitePreview(
  kind: json['kind'] as String,
  inviterName: json['inviter_name'] as String,
  channelName: json['channel_name'] as String?,
  inviteeKind: json['invitee_kind'] as String,
);

Map<String, dynamic> _$RadioInvitePreviewToJson(_RadioInvitePreview instance) => <String, dynamic>{
  'kind': instance.kind,
  'inviter_name': instance.inviterName,
  'channel_name': instance.channelName,
  'invitee_kind': instance.inviteeKind,
};

_RadioQuietHours _$RadioQuietHoursFromJson(Map<String, dynamic> json) => _RadioQuietHours(
  weekdays: (json['weekdays'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
  starts: json['starts'] as String,
  ends: json['ends'] as String,
  enabled: json['enabled'] as bool? ?? true,
);

Map<String, dynamic> _$RadioQuietHoursToJson(_RadioQuietHours instance) => <String, dynamic>{
  'weekdays': instance.weekdays,
  'starts': instance.starts,
  'ends': instance.ends,
  'enabled': instance.enabled,
};

_RadioPhotoUpload _$RadioPhotoUploadFromJson(Map<String, dynamic> json) => _RadioPhotoUpload(
  messageId: json['message_id'] as String,
  uploadUrl: json['upload_url'] as String,
  contentType: json['content_type'] as String? ?? 'image/jpeg',
);

Map<String, dynamic> _$RadioPhotoUploadToJson(_RadioPhotoUpload instance) => <String, dynamic>{
  'message_id': instance.messageId,
  'upload_url': instance.uploadUrl,
  'content_type': instance.contentType,
};

_RadioEmergency _$RadioEmergencyFromJson(Map<String, dynamic> json) =>
    _RadioEmergency(alertId: json['alert_id'] as String, tripId: json['trip_id'] as String?);

Map<String, dynamic> _$RadioEmergencyToJson(_RadioEmergency instance) => <String, dynamic>{
  'alert_id': instance.alertId,
  'trip_id': instance.tripId,
};

_RadioSettings _$RadioSettingsFromJson(Map<String, dynamic> json) => _RadioSettings(
  trialPolicy: json['trial_policy'] as String,
  trialDays: (json['trial_days'] as num).toInt(),
  passengersInChannels: json['passengers_in_channels'] as String,
  retentionDays: (json['retention_days'] as num).toInt(),
  updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String),
  updatedByName: json['updated_by_name'] as String? ?? '',
  estimatedMonthlyCostMinor:
      (json['estimated_monthly_cost_minor'] as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())) ??
      const <String, int>{},
);

Map<String, dynamic> _$RadioSettingsToJson(_RadioSettings instance) => <String, dynamic>{
  'trial_policy': instance.trialPolicy,
  'trial_days': instance.trialDays,
  'passengers_in_channels': instance.passengersInChannels,
  'retention_days': instance.retentionDays,
  'updated_at': instance.updatedAt?.toIso8601String(),
  'updated_by_name': instance.updatedByName,
  'estimated_monthly_cost_minor': instance.estimatedMonthlyCostMinor,
};

_RadioBulkUpload _$RadioBulkUploadFromJson(Map<String, dynamic> json) => _RadioBulkUpload(
  id: json['id'] as String,
  fileName: json['file_name'] as String,
  status: json['status'] as String,
  rowsTotal: (json['rows_total'] as num).toInt(),
  counts:
      (json['counts'] as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())) ??
      const <String, int>{},
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$RadioBulkUploadToJson(_RadioBulkUpload instance) => <String, dynamic>{
  'id': instance.id,
  'file_name': instance.fileName,
  'status': instance.status,
  'rows_total': instance.rowsTotal,
  'counts': instance.counts,
  'created_at': instance.createdAt.toIso8601String(),
};

_RadioBulkRow _$RadioBulkRowFromJson(Map<String, dynamic> json) => _RadioBulkRow(
  line: (json['line'] as num).toInt(),
  name: json['name'] as String? ?? '',
  phoneMasked: json['phone_masked'] as String? ?? '',
  kind: json['kind'] as String? ?? 'driver',
  channel: json['channel'] as String? ?? '',
  role: $enumDecodeNullable(_$RadioRoleEnumMap, json['role'], unknownValue: RadioRole.member),
  status: json['status'] as String,
  error: json['error'] as String?,
);

Map<String, dynamic> _$RadioBulkRowToJson(_RadioBulkRow instance) => <String, dynamic>{
  'line': instance.line,
  'name': instance.name,
  'phone_masked': instance.phoneMasked,
  'kind': instance.kind,
  'channel': instance.channel,
  'role': _$RadioRoleEnumMap[instance.role],
  'status': instance.status,
  'error': instance.error,
};

_RadioReport _$RadioReportFromJson(Map<String, dynamic> json) => _RadioReport(
  id: json['id'] as String,
  messageKind: json['message_kind'] as String,
  conversationTitle: json['conversation_title'] as String,
  reason: json['reason'] as String? ?? '',
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$RadioReportToJson(_RadioReport instance) => <String, dynamic>{
  'id': instance.id,
  'message_kind': instance.messageKind,
  'conversation_title': instance.conversationTitle,
  'reason': instance.reason,
  'created_at': instance.createdAt.toIso8601String(),
};
