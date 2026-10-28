/// Falsos de Radio para pruebas: sin red, salas ni audio.
library;

import 'dart:async';

import 'package:kyq_api/kyq_api.dart';

import 'kyq_radio.dart';

/// [RadioApi] en memoria: [conversations] y [messages] responden; [calls] anota cada llamada.
class FakeRadioApi implements RadioApi {
  FakeRadioApi({RadioMe? me, List<RadioConversation>? conversations})
    : me = me ?? fakeMe(),
      conversations = conversations ?? [];

  RadioMe me;
  List<RadioConversation> conversations;
  final messages = <String, List<RadioMessage>>{};
  final details = <String, RadioConversationDetail>{};
  final calls = <String>[];

  /// Error que lanza takeRadioFloor (p. ej. floor_busy); null concede.
  ApiException? floorError;

  /// Respuesta de las invitaciones.
  RadioInvitePreview preview = const RadioInvitePreview(kind: 'contact', inviterName: 'Carlos', inviteeKind: 'driver');
  RadioAcceptResult? acceptResult;
  ApiException? acceptError;
  int _seq = 0;

  RadioConversation _conv(String id) => conversations.firstWhere((c) => c.id == id);

  @override
  Future<RadioMe> radioMe() async => me;

  @override
  Future<RadioMe> updateRadioMe({RadioPresence? status, bool? radioOn, RadioPushMode? pushMode}) async {
    calls.add('me ${status?.name ?? ''} ${radioOn ?? ''} ${pushMode?.name ?? ''}'.trim());
    return me = me.copyWith(
      status: status ?? me.status,
      radioOn: radioOn ?? me.radioOn,
      pushMode: pushMode ?? me.pushMode,
    );
  }

  @override
  Future<void> acceptRadioConsent() async {
    calls.add('consent');
    me = me.copyWith(consentRequired: false);
  }

  @override
  Future<void> radioHeartbeat() async => calls.add('heartbeat');

  final quiet = <RadioQuietHours>[];

  @override
  Future<List<RadioQuietHours>> radioQuietHours() async => List.of(quiet);

  @override
  Future<void> setRadioQuietHours(List<RadioQuietHours> rules) async {
    calls.add('quiet ${rules.length}');
    quiet
      ..clear()
      ..addAll(rules);
  }

  @override
  Future<List<RadioConversation>> radioConversations() async => List.of(conversations);

  @override
  Future<RadioConversationDetail> radioConversation(String id) async =>
      details[id] ?? RadioConversationDetail(conversation: _conv(id));

  @override
  Future<void> deleteRadioConversation(String id) async {
    calls.add('delete $id');
    conversations.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> setRadioListening(String id, bool listening) async => calls.add('listening $id $listening');

  @override
  Future<RadioCredentials> radioToken(String conversationId) async {
    calls.add('token $conversationId');
    return RadioCredentials(
      url: 'wss://voz.test',
      token: 'lk-$conversationId',
      room: 'radio-$conversationId-x',
      expiresAt: DateTime(2030),
    );
  }

  @override
  Future<RadioFloor> takeRadioFloor(String conversationId) async {
    calls.add('floor $conversationId');
    final e = floorError;
    if (e != null) throw e;
    return RadioFloor(messageId: 'm-floor-${++_seq}', expiresAt: DateTime(2030));
  }

  @override
  Future<void> releaseRadioFloor(String conversationId) async => calls.add('release $conversationId');

  @override
  Future<List<RadioMessage>> radioMessages(String conversationId, {String? before, int limit = 50}) async {
    final all = messages[conversationId] ?? const [];
    final start = before == null ? 0 : all.indexWhere((m) => m.id == before) + 1;
    return all.skip(start).take(limit).toList();
  }

  RadioMessage _new(String conversationId, RadioMessageKind kind, {String? body, double? lat, double? lng}) {
    final m = RadioMessage(
      id: 'sent-${++_seq}',
      conversationId: conversationId,
      authorId: 'me',
      authorName: 'Yo',
      kind: kind,
      body: body,
      lat: lat,
      lng: lng,
      createdAt: DateTime(2026, 10, 28, 12, _seq),
      heard: true,
    );
    calls.add('send ${kind.name} ${body ?? ''}'.trim());
    return m;
  }

  ApiException? sendError;

  @override
  Future<RadioMessage> sendRadioText(String conversationId, String body) async {
    if (sendError case final e?) throw e;
    return _new(conversationId, RadioMessageKind.text, body: body);
  }

  @override
  Future<RadioMessage> sendRadioLocation(String conversationId, double lat, double lng, {String? label}) async =>
      _new(conversationId, RadioMessageKind.location, lat: lat, lng: lng);

  @override
  Future<RadioMessage> sendRadioAlert(String conversationId, {String? body}) async {
    if (sendError case final e?) throw e;
    return _new(conversationId, RadioMessageKind.alert, body: body);
  }

  @override
  Future<RadioPhotoUpload> reserveRadioPhoto(String conversationId) async {
    calls.add('photo $conversationId');
    return const RadioPhotoUpload(messageId: 'photo-1', uploadUrl: 'https://objects.test/put');
  }

  @override
  Future<void> uploadRadioPhoto(String uploadUrl, List<int> jpeg) async => calls.add('upload ${jpeg.length}');

  @override
  Future<void> confirmRadioPhoto(String messageId) async => calls.add('photo-uploaded $messageId');

  @override
  Future<String> radioMediaUrl(String messageId) async => 'https://objects.test/$messageId.ogg';

  @override
  Future<void> setRadioReceipt(String messageId, {bool? heard, bool? saved}) async =>
      calls.add('receipt $messageId${heard == true ? ' heard' : ''}${saved == null ? '' : ' saved=$saved'}');

  @override
  Future<void> reportRadioMessage(String messageId, {String reason = ''}) async => calls.add('report $messageId');

  @override
  Future<RadioEmergency> radioEmergency(String conversationId, {required double lat, required double lng}) async {
    calls.add('emergency $conversationId');
    return const RadioEmergency(alertId: 'sos-1');
  }

  @override
  Future<RadioInvite?> inviteRadioContact({String? phoneE164}) async {
    calls.add('invite ${phoneE164 ?? 'qr'}');
    return phoneE164 == null
        ? RadioInvite(code: 'ABCDEFGHIJ', url: 'https://kyq.test/r/ABCDEFGHIJ', expiresAt: DateTime(2030))
        : null;
  }

  @override
  Future<RadioInvitePreview> radioInvitePreview(String code) async => preview;

  @override
  Future<RadioAcceptResult> acceptRadioInvite(String code) async {
    calls.add('accept $code');
    if (acceptError case final e?) throw e;
    return acceptResult ?? RadioAcceptResult(conversations.first);
  }

  @override
  Future<void> setRadioClients(bool enabled) async {
    calls.add('clients $enabled');
    me = me.copyWith(clientsEnabled: enabled);
  }

  @override
  Future<void> setRadioClient(String passengerId, {bool? muted, bool? blocked}) async =>
      calls.add('client $passengerId muted=$muted blocked=$blocked');

  @override
  Future<RadioConversation> createRadioChannel({
    required String name,
    String? description,
    String joinMode = 'approval',
    RadioRole? passengerRoleMax,
  }) async {
    calls.add('channel $name $joinMode');
    final c = RadioConversation(
      id: 'ch-${++_seq}',
      kind: RadioConversationKind.channel,
      title: name,
      listening: true,
      unreadCount: 0,
      onlineCount: 1,
      myRole: RadioRole.owner,
      canTalk: true,
    );
    conversations = [...conversations, c];
    return c;
  }

  @override
  Future<RadioConversation> updateRadioChannel(
    String id, {
    String? name,
    String? description,
    String? joinMode,
    RadioRole? passengerRoleMax,
    bool setPassengerRole = false,
  }) async {
    calls.add('update $id');
    return _conv(id);
  }

  @override
  Future<RadioInvite> radioChannelInvite(String id) async =>
      RadioInvite(code: 'CHANNEL001', url: 'https://kyq.test/r/CHANNEL001', expiresAt: DateTime(2030));

  @override
  Future<void> moderateRadioMember(String conversationId, String userId, {String? action, RadioRole? role}) async =>
      calls.add('moderate $userId ${action ?? ''} ${role?.name ?? ''}'.trim());

  @override
  Future<void> leaveRadioChannel(String id) async => calls.add('leave $id');
}

RadioMe fakeMe({
  RadioAccess access = RadioAccess.full,
  bool radioOn = true,
  RadioPresence status = RadioPresence.available,
  bool consentRequired = false,
}) => RadioMe(
  access: access,
  status: status,
  radioOn: radioOn,
  pushMode: RadioPushMode.hold,
  consentRequired: consentRequired,
  retentionDays: 30,
  clientsEnabled: false,
);

RadioConversation fakeContact(String id, {String title = 'Jonathan', bool listening = true, int unread = 0}) =>
    RadioConversation(
      id: id,
      kind: RadioConversationKind.direct,
      title: title,
      peerId: 'peer-$id',
      peerStatus: RadioPresence.available,
      listening: listening,
      unreadCount: unread,
      canTalk: true,
    );

RadioConversation fakeChannel(String id, {String title = 'Taxistas Norte', RadioRole role = RadioRole.member}) =>
    RadioConversation(
      id: id,
      kind: RadioConversationKind.channel,
      title: title,
      onlineCount: 3,
      myRole: role,
      listening: true,
      unreadCount: 0,
      canTalk: role != RadioRole.listener,
    );

RadioMessage fakeVoice(
  String id,
  String conversationId, {
  bool heard = false,
  String author = 'Jonathan',
  int minute = 0,
}) => RadioMessage(
  id: id,
  conversationId: conversationId,
  authorId: 'peer-$conversationId',
  authorName: author,
  kind: RadioMessageKind.voice,
  durationMs: 2300,
  hasMedia: true,
  createdAt: DateTime(2026, 10, 28, 12, minute),
  heard: heard,
);

/// Reproductor falso: [play] termina cuando la prueba llama a [finish] (o al momento si [instant]).
class FakeMessagePlayer implements MessagePlayer {
  FakeMessagePlayer({this.instant = true});

  final bool instant;
  final played = <String>[];
  final speeds = <double>[];
  Completer<void>? _current;

  void finish() {
    _current?.complete();
    _current = null;
  }

  @override
  Future<void> play(String url, {double speed = 1.0}) {
    played.add(url);
    speeds.add(speed);
    if (instant) return Future.value();
    return (_current = Completer<void>()).future;
  }

  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);

  @override
  Future<void> stop() async => finish();

  @override
  Future<void> dispose() async {}
}

RadioMember fakeMember(
  String id,
  String name, {
  RadioRole role = RadioRole.member,
  RadioMemberStatus status = RadioMemberStatus.active,
  RadioPresence presence = RadioPresence.available,
  bool passenger = false,
}) =>
    RadioMember(userId: id, displayName: name, role: role, status: status, presence: presence, isPassenger: passenger);
