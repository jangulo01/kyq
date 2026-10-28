// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'radio_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RadioMe {

@JsonKey(unknownEnumValue: RadioAccess.none) RadioAccess get access; String? get accessReason; int? get trialDaysLeft;@JsonKey(unknownEnumValue: RadioPresence.available) RadioPresence get status; bool get radioOn;@JsonKey(unknownEnumValue: RadioPushMode.hold) RadioPushMode get pushMode; bool get consentRequired; int get retentionDays;/// Solo conductores: "Radio con mis clientes" (FR-003).
 bool? get clientsEnabled;
/// Create a copy of RadioMe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioMeCopyWith<RadioMe> get copyWith => _$RadioMeCopyWithImpl<RadioMe>(this as RadioMe, _$identity);

  /// Serializes this RadioMe to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioMe&&(identical(other.access, access) || other.access == access)&&(identical(other.accessReason, accessReason) || other.accessReason == accessReason)&&(identical(other.trialDaysLeft, trialDaysLeft) || other.trialDaysLeft == trialDaysLeft)&&(identical(other.status, status) || other.status == status)&&(identical(other.radioOn, radioOn) || other.radioOn == radioOn)&&(identical(other.pushMode, pushMode) || other.pushMode == pushMode)&&(identical(other.consentRequired, consentRequired) || other.consentRequired == consentRequired)&&(identical(other.retentionDays, retentionDays) || other.retentionDays == retentionDays)&&(identical(other.clientsEnabled, clientsEnabled) || other.clientsEnabled == clientsEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,access,accessReason,trialDaysLeft,status,radioOn,pushMode,consentRequired,retentionDays,clientsEnabled);

@override
String toString() {
  return 'RadioMe(access: $access, accessReason: $accessReason, trialDaysLeft: $trialDaysLeft, status: $status, radioOn: $radioOn, pushMode: $pushMode, consentRequired: $consentRequired, retentionDays: $retentionDays, clientsEnabled: $clientsEnabled)';
}


}

/// @nodoc
abstract mixin class $RadioMeCopyWith<$Res>  {
  factory $RadioMeCopyWith(RadioMe value, $Res Function(RadioMe) _then) = _$RadioMeCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: RadioAccess.none) RadioAccess access, String? accessReason, int? trialDaysLeft,@JsonKey(unknownEnumValue: RadioPresence.available) RadioPresence status, bool radioOn,@JsonKey(unknownEnumValue: RadioPushMode.hold) RadioPushMode pushMode, bool consentRequired, int retentionDays, bool? clientsEnabled
});




}
/// @nodoc
class _$RadioMeCopyWithImpl<$Res>
    implements $RadioMeCopyWith<$Res> {
  _$RadioMeCopyWithImpl(this._self, this._then);

  final RadioMe _self;
  final $Res Function(RadioMe) _then;

/// Create a copy of RadioMe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? access = null,Object? accessReason = freezed,Object? trialDaysLeft = freezed,Object? status = null,Object? radioOn = null,Object? pushMode = null,Object? consentRequired = null,Object? retentionDays = null,Object? clientsEnabled = freezed,}) {
  return _then(_self.copyWith(
access: null == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as RadioAccess,accessReason: freezed == accessReason ? _self.accessReason : accessReason // ignore: cast_nullable_to_non_nullable
as String?,trialDaysLeft: freezed == trialDaysLeft ? _self.trialDaysLeft : trialDaysLeft // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RadioPresence,radioOn: null == radioOn ? _self.radioOn : radioOn // ignore: cast_nullable_to_non_nullable
as bool,pushMode: null == pushMode ? _self.pushMode : pushMode // ignore: cast_nullable_to_non_nullable
as RadioPushMode,consentRequired: null == consentRequired ? _self.consentRequired : consentRequired // ignore: cast_nullable_to_non_nullable
as bool,retentionDays: null == retentionDays ? _self.retentionDays : retentionDays // ignore: cast_nullable_to_non_nullable
as int,clientsEnabled: freezed == clientsEnabled ? _self.clientsEnabled : clientsEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioMe].
extension RadioMePatterns on RadioMe {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioMe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioMe() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioMe value)  $default,){
final _that = this;
switch (_that) {
case _RadioMe():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioMe value)?  $default,){
final _that = this;
switch (_that) {
case _RadioMe() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: RadioAccess.none)  RadioAccess access,  String? accessReason,  int? trialDaysLeft, @JsonKey(unknownEnumValue: RadioPresence.available)  RadioPresence status,  bool radioOn, @JsonKey(unknownEnumValue: RadioPushMode.hold)  RadioPushMode pushMode,  bool consentRequired,  int retentionDays,  bool? clientsEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioMe() when $default != null:
return $default(_that.access,_that.accessReason,_that.trialDaysLeft,_that.status,_that.radioOn,_that.pushMode,_that.consentRequired,_that.retentionDays,_that.clientsEnabled);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: RadioAccess.none)  RadioAccess access,  String? accessReason,  int? trialDaysLeft, @JsonKey(unknownEnumValue: RadioPresence.available)  RadioPresence status,  bool radioOn, @JsonKey(unknownEnumValue: RadioPushMode.hold)  RadioPushMode pushMode,  bool consentRequired,  int retentionDays,  bool? clientsEnabled)  $default,) {final _that = this;
switch (_that) {
case _RadioMe():
return $default(_that.access,_that.accessReason,_that.trialDaysLeft,_that.status,_that.radioOn,_that.pushMode,_that.consentRequired,_that.retentionDays,_that.clientsEnabled);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: RadioAccess.none)  RadioAccess access,  String? accessReason,  int? trialDaysLeft, @JsonKey(unknownEnumValue: RadioPresence.available)  RadioPresence status,  bool radioOn, @JsonKey(unknownEnumValue: RadioPushMode.hold)  RadioPushMode pushMode,  bool consentRequired,  int retentionDays,  bool? clientsEnabled)?  $default,) {final _that = this;
switch (_that) {
case _RadioMe() when $default != null:
return $default(_that.access,_that.accessReason,_that.trialDaysLeft,_that.status,_that.radioOn,_that.pushMode,_that.consentRequired,_that.retentionDays,_that.clientsEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioMe implements RadioMe {
  const _RadioMe({@JsonKey(unknownEnumValue: RadioAccess.none) required this.access, this.accessReason, this.trialDaysLeft, @JsonKey(unknownEnumValue: RadioPresence.available) required this.status, required this.radioOn, @JsonKey(unknownEnumValue: RadioPushMode.hold) required this.pushMode, required this.consentRequired, this.retentionDays = 30, this.clientsEnabled});
  factory _RadioMe.fromJson(Map<String, dynamic> json) => _$RadioMeFromJson(json);

@override@JsonKey(unknownEnumValue: RadioAccess.none) final  RadioAccess access;
@override final  String? accessReason;
@override final  int? trialDaysLeft;
@override@JsonKey(unknownEnumValue: RadioPresence.available) final  RadioPresence status;
@override final  bool radioOn;
@override@JsonKey(unknownEnumValue: RadioPushMode.hold) final  RadioPushMode pushMode;
@override final  bool consentRequired;
@override@JsonKey() final  int retentionDays;
/// Solo conductores: "Radio con mis clientes" (FR-003).
@override final  bool? clientsEnabled;

/// Create a copy of RadioMe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioMeCopyWith<_RadioMe> get copyWith => __$RadioMeCopyWithImpl<_RadioMe>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioMeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioMe&&(identical(other.access, access) || other.access == access)&&(identical(other.accessReason, accessReason) || other.accessReason == accessReason)&&(identical(other.trialDaysLeft, trialDaysLeft) || other.trialDaysLeft == trialDaysLeft)&&(identical(other.status, status) || other.status == status)&&(identical(other.radioOn, radioOn) || other.radioOn == radioOn)&&(identical(other.pushMode, pushMode) || other.pushMode == pushMode)&&(identical(other.consentRequired, consentRequired) || other.consentRequired == consentRequired)&&(identical(other.retentionDays, retentionDays) || other.retentionDays == retentionDays)&&(identical(other.clientsEnabled, clientsEnabled) || other.clientsEnabled == clientsEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,access,accessReason,trialDaysLeft,status,radioOn,pushMode,consentRequired,retentionDays,clientsEnabled);

@override
String toString() {
  return 'RadioMe(access: $access, accessReason: $accessReason, trialDaysLeft: $trialDaysLeft, status: $status, radioOn: $radioOn, pushMode: $pushMode, consentRequired: $consentRequired, retentionDays: $retentionDays, clientsEnabled: $clientsEnabled)';
}


}

/// @nodoc
abstract mixin class _$RadioMeCopyWith<$Res> implements $RadioMeCopyWith<$Res> {
  factory _$RadioMeCopyWith(_RadioMe value, $Res Function(_RadioMe) _then) = __$RadioMeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: RadioAccess.none) RadioAccess access, String? accessReason, int? trialDaysLeft,@JsonKey(unknownEnumValue: RadioPresence.available) RadioPresence status, bool radioOn,@JsonKey(unknownEnumValue: RadioPushMode.hold) RadioPushMode pushMode, bool consentRequired, int retentionDays, bool? clientsEnabled
});




}
/// @nodoc
class __$RadioMeCopyWithImpl<$Res>
    implements _$RadioMeCopyWith<$Res> {
  __$RadioMeCopyWithImpl(this._self, this._then);

  final _RadioMe _self;
  final $Res Function(_RadioMe) _then;

/// Create a copy of RadioMe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? access = null,Object? accessReason = freezed,Object? trialDaysLeft = freezed,Object? status = null,Object? radioOn = null,Object? pushMode = null,Object? consentRequired = null,Object? retentionDays = null,Object? clientsEnabled = freezed,}) {
  return _then(_RadioMe(
access: null == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as RadioAccess,accessReason: freezed == accessReason ? _self.accessReason : accessReason // ignore: cast_nullable_to_non_nullable
as String?,trialDaysLeft: freezed == trialDaysLeft ? _self.trialDaysLeft : trialDaysLeft // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RadioPresence,radioOn: null == radioOn ? _self.radioOn : radioOn // ignore: cast_nullable_to_non_nullable
as bool,pushMode: null == pushMode ? _self.pushMode : pushMode // ignore: cast_nullable_to_non_nullable
as RadioPushMode,consentRequired: null == consentRequired ? _self.consentRequired : consentRequired // ignore: cast_nullable_to_non_nullable
as bool,retentionDays: null == retentionDays ? _self.retentionDays : retentionDays // ignore: cast_nullable_to_non_nullable
as int,clientsEnabled: freezed == clientsEnabled ? _self.clientsEnabled : clientsEnabled // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$RadioConversation {

 String get id;@JsonKey(unknownEnumValue: RadioConversationKind.channel) RadioConversationKind get kind; String get title; String? get photoUrl; String? get peerId;@JsonKey(unknownEnumValue: RadioPresence.offline) RadioPresence? get peerStatus; bool get peerMuted; int? get onlineCount;@JsonKey(unknownEnumValue: RadioRole.member) RadioRole? get myRole; String get myMemberStatus; bool get listening; int get unreadCount; DateTime? get lastMessageAt; String get status; bool get canTalk;
/// Create a copy of RadioConversation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioConversationCopyWith<RadioConversation> get copyWith => _$RadioConversationCopyWithImpl<RadioConversation>(this as RadioConversation, _$identity);

  /// Serializes this RadioConversation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioConversation&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.peerStatus, peerStatus) || other.peerStatus == peerStatus)&&(identical(other.peerMuted, peerMuted) || other.peerMuted == peerMuted)&&(identical(other.onlineCount, onlineCount) || other.onlineCount == onlineCount)&&(identical(other.myRole, myRole) || other.myRole == myRole)&&(identical(other.myMemberStatus, myMemberStatus) || other.myMemberStatus == myMemberStatus)&&(identical(other.listening, listening) || other.listening == listening)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.canTalk, canTalk) || other.canTalk == canTalk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,photoUrl,peerId,peerStatus,peerMuted,onlineCount,myRole,myMemberStatus,listening,unreadCount,lastMessageAt,status,canTalk);

@override
String toString() {
  return 'RadioConversation(id: $id, kind: $kind, title: $title, photoUrl: $photoUrl, peerId: $peerId, peerStatus: $peerStatus, peerMuted: $peerMuted, onlineCount: $onlineCount, myRole: $myRole, myMemberStatus: $myMemberStatus, listening: $listening, unreadCount: $unreadCount, lastMessageAt: $lastMessageAt, status: $status, canTalk: $canTalk)';
}


}

/// @nodoc
abstract mixin class $RadioConversationCopyWith<$Res>  {
  factory $RadioConversationCopyWith(RadioConversation value, $Res Function(RadioConversation) _then) = _$RadioConversationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: RadioConversationKind.channel) RadioConversationKind kind, String title, String? photoUrl, String? peerId,@JsonKey(unknownEnumValue: RadioPresence.offline) RadioPresence? peerStatus, bool peerMuted, int? onlineCount,@JsonKey(unknownEnumValue: RadioRole.member) RadioRole? myRole, String myMemberStatus, bool listening, int unreadCount, DateTime? lastMessageAt, String status, bool canTalk
});




}
/// @nodoc
class _$RadioConversationCopyWithImpl<$Res>
    implements $RadioConversationCopyWith<$Res> {
  _$RadioConversationCopyWithImpl(this._self, this._then);

  final RadioConversation _self;
  final $Res Function(RadioConversation) _then;

/// Create a copy of RadioConversation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? photoUrl = freezed,Object? peerId = freezed,Object? peerStatus = freezed,Object? peerMuted = null,Object? onlineCount = freezed,Object? myRole = freezed,Object? myMemberStatus = null,Object? listening = null,Object? unreadCount = null,Object? lastMessageAt = freezed,Object? status = null,Object? canTalk = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RadioConversationKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as String?,peerStatus: freezed == peerStatus ? _self.peerStatus : peerStatus // ignore: cast_nullable_to_non_nullable
as RadioPresence?,peerMuted: null == peerMuted ? _self.peerMuted : peerMuted // ignore: cast_nullable_to_non_nullable
as bool,onlineCount: freezed == onlineCount ? _self.onlineCount : onlineCount // ignore: cast_nullable_to_non_nullable
as int?,myRole: freezed == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as RadioRole?,myMemberStatus: null == myMemberStatus ? _self.myMemberStatus : myMemberStatus // ignore: cast_nullable_to_non_nullable
as String,listening: null == listening ? _self.listening : listening // ignore: cast_nullable_to_non_nullable
as bool,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,canTalk: null == canTalk ? _self.canTalk : canTalk // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioConversation].
extension RadioConversationPatterns on RadioConversation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioConversation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioConversation() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioConversation value)  $default,){
final _that = this;
switch (_that) {
case _RadioConversation():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioConversation value)?  $default,){
final _that = this;
switch (_that) {
case _RadioConversation() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: RadioConversationKind.channel)  RadioConversationKind kind,  String title,  String? photoUrl,  String? peerId, @JsonKey(unknownEnumValue: RadioPresence.offline)  RadioPresence? peerStatus,  bool peerMuted,  int? onlineCount, @JsonKey(unknownEnumValue: RadioRole.member)  RadioRole? myRole,  String myMemberStatus,  bool listening,  int unreadCount,  DateTime? lastMessageAt,  String status,  bool canTalk)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioConversation() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.photoUrl,_that.peerId,_that.peerStatus,_that.peerMuted,_that.onlineCount,_that.myRole,_that.myMemberStatus,_that.listening,_that.unreadCount,_that.lastMessageAt,_that.status,_that.canTalk);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: RadioConversationKind.channel)  RadioConversationKind kind,  String title,  String? photoUrl,  String? peerId, @JsonKey(unknownEnumValue: RadioPresence.offline)  RadioPresence? peerStatus,  bool peerMuted,  int? onlineCount, @JsonKey(unknownEnumValue: RadioRole.member)  RadioRole? myRole,  String myMemberStatus,  bool listening,  int unreadCount,  DateTime? lastMessageAt,  String status,  bool canTalk)  $default,) {final _that = this;
switch (_that) {
case _RadioConversation():
return $default(_that.id,_that.kind,_that.title,_that.photoUrl,_that.peerId,_that.peerStatus,_that.peerMuted,_that.onlineCount,_that.myRole,_that.myMemberStatus,_that.listening,_that.unreadCount,_that.lastMessageAt,_that.status,_that.canTalk);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: RadioConversationKind.channel)  RadioConversationKind kind,  String title,  String? photoUrl,  String? peerId, @JsonKey(unknownEnumValue: RadioPresence.offline)  RadioPresence? peerStatus,  bool peerMuted,  int? onlineCount, @JsonKey(unknownEnumValue: RadioRole.member)  RadioRole? myRole,  String myMemberStatus,  bool listening,  int unreadCount,  DateTime? lastMessageAt,  String status,  bool canTalk)?  $default,) {final _that = this;
switch (_that) {
case _RadioConversation() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.photoUrl,_that.peerId,_that.peerStatus,_that.peerMuted,_that.onlineCount,_that.myRole,_that.myMemberStatus,_that.listening,_that.unreadCount,_that.lastMessageAt,_that.status,_that.canTalk);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioConversation implements RadioConversation {
  const _RadioConversation({required this.id, @JsonKey(unknownEnumValue: RadioConversationKind.channel) required this.kind, required this.title, this.photoUrl, this.peerId, @JsonKey(unknownEnumValue: RadioPresence.offline) this.peerStatus, this.peerMuted = false, this.onlineCount, @JsonKey(unknownEnumValue: RadioRole.member) this.myRole, this.myMemberStatus = 'active', required this.listening, required this.unreadCount, this.lastMessageAt, this.status = 'active', this.canTalk = false});
  factory _RadioConversation.fromJson(Map<String, dynamic> json) => _$RadioConversationFromJson(json);

@override final  String id;
@override@JsonKey(unknownEnumValue: RadioConversationKind.channel) final  RadioConversationKind kind;
@override final  String title;
@override final  String? photoUrl;
@override final  String? peerId;
@override@JsonKey(unknownEnumValue: RadioPresence.offline) final  RadioPresence? peerStatus;
@override@JsonKey() final  bool peerMuted;
@override final  int? onlineCount;
@override@JsonKey(unknownEnumValue: RadioRole.member) final  RadioRole? myRole;
@override@JsonKey() final  String myMemberStatus;
@override final  bool listening;
@override final  int unreadCount;
@override final  DateTime? lastMessageAt;
@override@JsonKey() final  String status;
@override@JsonKey() final  bool canTalk;

/// Create a copy of RadioConversation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioConversationCopyWith<_RadioConversation> get copyWith => __$RadioConversationCopyWithImpl<_RadioConversation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioConversationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioConversation&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.peerStatus, peerStatus) || other.peerStatus == peerStatus)&&(identical(other.peerMuted, peerMuted) || other.peerMuted == peerMuted)&&(identical(other.onlineCount, onlineCount) || other.onlineCount == onlineCount)&&(identical(other.myRole, myRole) || other.myRole == myRole)&&(identical(other.myMemberStatus, myMemberStatus) || other.myMemberStatus == myMemberStatus)&&(identical(other.listening, listening) || other.listening == listening)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.canTalk, canTalk) || other.canTalk == canTalk));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,photoUrl,peerId,peerStatus,peerMuted,onlineCount,myRole,myMemberStatus,listening,unreadCount,lastMessageAt,status,canTalk);

@override
String toString() {
  return 'RadioConversation(id: $id, kind: $kind, title: $title, photoUrl: $photoUrl, peerId: $peerId, peerStatus: $peerStatus, peerMuted: $peerMuted, onlineCount: $onlineCount, myRole: $myRole, myMemberStatus: $myMemberStatus, listening: $listening, unreadCount: $unreadCount, lastMessageAt: $lastMessageAt, status: $status, canTalk: $canTalk)';
}


}

/// @nodoc
abstract mixin class _$RadioConversationCopyWith<$Res> implements $RadioConversationCopyWith<$Res> {
  factory _$RadioConversationCopyWith(_RadioConversation value, $Res Function(_RadioConversation) _then) = __$RadioConversationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: RadioConversationKind.channel) RadioConversationKind kind, String title, String? photoUrl, String? peerId,@JsonKey(unknownEnumValue: RadioPresence.offline) RadioPresence? peerStatus, bool peerMuted, int? onlineCount,@JsonKey(unknownEnumValue: RadioRole.member) RadioRole? myRole, String myMemberStatus, bool listening, int unreadCount, DateTime? lastMessageAt, String status, bool canTalk
});




}
/// @nodoc
class __$RadioConversationCopyWithImpl<$Res>
    implements _$RadioConversationCopyWith<$Res> {
  __$RadioConversationCopyWithImpl(this._self, this._then);

  final _RadioConversation _self;
  final $Res Function(_RadioConversation) _then;

/// Create a copy of RadioConversation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? photoUrl = freezed,Object? peerId = freezed,Object? peerStatus = freezed,Object? peerMuted = null,Object? onlineCount = freezed,Object? myRole = freezed,Object? myMemberStatus = null,Object? listening = null,Object? unreadCount = null,Object? lastMessageAt = freezed,Object? status = null,Object? canTalk = null,}) {
  return _then(_RadioConversation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RadioConversationKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,peerId: freezed == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as String?,peerStatus: freezed == peerStatus ? _self.peerStatus : peerStatus // ignore: cast_nullable_to_non_nullable
as RadioPresence?,peerMuted: null == peerMuted ? _self.peerMuted : peerMuted // ignore: cast_nullable_to_non_nullable
as bool,onlineCount: freezed == onlineCount ? _self.onlineCount : onlineCount // ignore: cast_nullable_to_non_nullable
as int?,myRole: freezed == myRole ? _self.myRole : myRole // ignore: cast_nullable_to_non_nullable
as RadioRole?,myMemberStatus: null == myMemberStatus ? _self.myMemberStatus : myMemberStatus // ignore: cast_nullable_to_non_nullable
as String,listening: null == listening ? _self.listening : listening // ignore: cast_nullable_to_non_nullable
as bool,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,canTalk: null == canTalk ? _self.canTalk : canTalk // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$RadioMember {

 String get userId; String get displayName;@JsonKey(unknownEnumValue: RadioRole.member) RadioRole get role;@JsonKey(unknownEnumValue: RadioMemberStatus.active) RadioMemberStatus get status;@JsonKey(unknownEnumValue: RadioPresence.offline) RadioPresence get presence; bool get isPassenger;
/// Create a copy of RadioMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioMemberCopyWith<RadioMember> get copyWith => _$RadioMemberCopyWithImpl<RadioMember>(this as RadioMember, _$identity);

  /// Serializes this RadioMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.isPassenger, isPassenger) || other.isPassenger == isPassenger));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,role,status,presence,isPassenger);

@override
String toString() {
  return 'RadioMember(userId: $userId, displayName: $displayName, role: $role, status: $status, presence: $presence, isPassenger: $isPassenger)';
}


}

/// @nodoc
abstract mixin class $RadioMemberCopyWith<$Res>  {
  factory $RadioMemberCopyWith(RadioMember value, $Res Function(RadioMember) _then) = _$RadioMemberCopyWithImpl;
@useResult
$Res call({
 String userId, String displayName,@JsonKey(unknownEnumValue: RadioRole.member) RadioRole role,@JsonKey(unknownEnumValue: RadioMemberStatus.active) RadioMemberStatus status,@JsonKey(unknownEnumValue: RadioPresence.offline) RadioPresence presence, bool isPassenger
});




}
/// @nodoc
class _$RadioMemberCopyWithImpl<$Res>
    implements $RadioMemberCopyWith<$Res> {
  _$RadioMemberCopyWithImpl(this._self, this._then);

  final RadioMember _self;
  final $Res Function(RadioMember) _then;

/// Create a copy of RadioMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? role = null,Object? status = null,Object? presence = null,Object? isPassenger = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as RadioRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RadioMemberStatus,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as RadioPresence,isPassenger: null == isPassenger ? _self.isPassenger : isPassenger // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioMember].
extension RadioMemberPatterns on RadioMember {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioMember() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioMember value)  $default,){
final _that = this;
switch (_that) {
case _RadioMember():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioMember value)?  $default,){
final _that = this;
switch (_that) {
case _RadioMember() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName, @JsonKey(unknownEnumValue: RadioRole.member)  RadioRole role, @JsonKey(unknownEnumValue: RadioMemberStatus.active)  RadioMemberStatus status, @JsonKey(unknownEnumValue: RadioPresence.offline)  RadioPresence presence,  bool isPassenger)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.role,_that.status,_that.presence,_that.isPassenger);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName, @JsonKey(unknownEnumValue: RadioRole.member)  RadioRole role, @JsonKey(unknownEnumValue: RadioMemberStatus.active)  RadioMemberStatus status, @JsonKey(unknownEnumValue: RadioPresence.offline)  RadioPresence presence,  bool isPassenger)  $default,) {final _that = this;
switch (_that) {
case _RadioMember():
return $default(_that.userId,_that.displayName,_that.role,_that.status,_that.presence,_that.isPassenger);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName, @JsonKey(unknownEnumValue: RadioRole.member)  RadioRole role, @JsonKey(unknownEnumValue: RadioMemberStatus.active)  RadioMemberStatus status, @JsonKey(unknownEnumValue: RadioPresence.offline)  RadioPresence presence,  bool isPassenger)?  $default,) {final _that = this;
switch (_that) {
case _RadioMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.role,_that.status,_that.presence,_that.isPassenger);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioMember implements RadioMember {
  const _RadioMember({required this.userId, required this.displayName, @JsonKey(unknownEnumValue: RadioRole.member) required this.role, @JsonKey(unknownEnumValue: RadioMemberStatus.active) required this.status, @JsonKey(unknownEnumValue: RadioPresence.offline) required this.presence, this.isPassenger = false});
  factory _RadioMember.fromJson(Map<String, dynamic> json) => _$RadioMemberFromJson(json);

@override final  String userId;
@override final  String displayName;
@override@JsonKey(unknownEnumValue: RadioRole.member) final  RadioRole role;
@override@JsonKey(unknownEnumValue: RadioMemberStatus.active) final  RadioMemberStatus status;
@override@JsonKey(unknownEnumValue: RadioPresence.offline) final  RadioPresence presence;
@override@JsonKey() final  bool isPassenger;

/// Create a copy of RadioMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioMemberCopyWith<_RadioMember> get copyWith => __$RadioMemberCopyWithImpl<_RadioMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.isPassenger, isPassenger) || other.isPassenger == isPassenger));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,role,status,presence,isPassenger);

@override
String toString() {
  return 'RadioMember(userId: $userId, displayName: $displayName, role: $role, status: $status, presence: $presence, isPassenger: $isPassenger)';
}


}

/// @nodoc
abstract mixin class _$RadioMemberCopyWith<$Res> implements $RadioMemberCopyWith<$Res> {
  factory _$RadioMemberCopyWith(_RadioMember value, $Res Function(_RadioMember) _then) = __$RadioMemberCopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName,@JsonKey(unknownEnumValue: RadioRole.member) RadioRole role,@JsonKey(unknownEnumValue: RadioMemberStatus.active) RadioMemberStatus status,@JsonKey(unknownEnumValue: RadioPresence.offline) RadioPresence presence, bool isPassenger
});




}
/// @nodoc
class __$RadioMemberCopyWithImpl<$Res>
    implements _$RadioMemberCopyWith<$Res> {
  __$RadioMemberCopyWithImpl(this._self, this._then);

  final _RadioMember _self;
  final $Res Function(_RadioMember) _then;

/// Create a copy of RadioMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? role = null,Object? status = null,Object? presence = null,Object? isPassenger = null,}) {
  return _then(_RadioMember(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as RadioRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RadioMemberStatus,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as RadioPresence,isPassenger: null == isPassenger ? _self.isPassenger : isPassenger // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$RadioMessage {

 String get id; String get conversationId; String? get authorId; String get authorName;@JsonKey(unknownEnumValue: RadioMessageKind.text) RadioMessageKind get kind; String get status; String? get body; double? get lat; double? get lng; int? get durationMs; bool get hasMedia; DateTime get createdAt; DateTime? get expiresAt; bool get heard; bool get saved;
/// Create a copy of RadioMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioMessageCopyWith<RadioMessage> get copyWith => _$RadioMessageCopyWithImpl<RadioMessage>(this as RadioMessage, _$identity);

  /// Serializes this RadioMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.status, status) || other.status == status)&&(identical(other.body, body) || other.body == body)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.hasMedia, hasMedia) || other.hasMedia == hasMedia)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.heard, heard) || other.heard == heard)&&(identical(other.saved, saved) || other.saved == saved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversationId,authorId,authorName,kind,status,body,lat,lng,durationMs,hasMedia,createdAt,expiresAt,heard,saved);

@override
String toString() {
  return 'RadioMessage(id: $id, conversationId: $conversationId, authorId: $authorId, authorName: $authorName, kind: $kind, status: $status, body: $body, lat: $lat, lng: $lng, durationMs: $durationMs, hasMedia: $hasMedia, createdAt: $createdAt, expiresAt: $expiresAt, heard: $heard, saved: $saved)';
}


}

/// @nodoc
abstract mixin class $RadioMessageCopyWith<$Res>  {
  factory $RadioMessageCopyWith(RadioMessage value, $Res Function(RadioMessage) _then) = _$RadioMessageCopyWithImpl;
@useResult
$Res call({
 String id, String conversationId, String? authorId, String authorName,@JsonKey(unknownEnumValue: RadioMessageKind.text) RadioMessageKind kind, String status, String? body, double? lat, double? lng, int? durationMs, bool hasMedia, DateTime createdAt, DateTime? expiresAt, bool heard, bool saved
});




}
/// @nodoc
class _$RadioMessageCopyWithImpl<$Res>
    implements $RadioMessageCopyWith<$Res> {
  _$RadioMessageCopyWithImpl(this._self, this._then);

  final RadioMessage _self;
  final $Res Function(RadioMessage) _then;

/// Create a copy of RadioMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conversationId = null,Object? authorId = freezed,Object? authorName = null,Object? kind = null,Object? status = null,Object? body = freezed,Object? lat = freezed,Object? lng = freezed,Object? durationMs = freezed,Object? hasMedia = null,Object? createdAt = null,Object? expiresAt = freezed,Object? heard = null,Object? saved = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String?,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RadioMessageKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,hasMedia: null == hasMedia ? _self.hasMedia : hasMedia // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,heard: null == heard ? _self.heard : heard // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioMessage].
extension RadioMessagePatterns on RadioMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioMessage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioMessage value)  $default,){
final _that = this;
switch (_that) {
case _RadioMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioMessage value)?  $default,){
final _that = this;
switch (_that) {
case _RadioMessage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String conversationId,  String? authorId,  String authorName, @JsonKey(unknownEnumValue: RadioMessageKind.text)  RadioMessageKind kind,  String status,  String? body,  double? lat,  double? lng,  int? durationMs,  bool hasMedia,  DateTime createdAt,  DateTime? expiresAt,  bool heard,  bool saved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioMessage() when $default != null:
return $default(_that.id,_that.conversationId,_that.authorId,_that.authorName,_that.kind,_that.status,_that.body,_that.lat,_that.lng,_that.durationMs,_that.hasMedia,_that.createdAt,_that.expiresAt,_that.heard,_that.saved);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String conversationId,  String? authorId,  String authorName, @JsonKey(unknownEnumValue: RadioMessageKind.text)  RadioMessageKind kind,  String status,  String? body,  double? lat,  double? lng,  int? durationMs,  bool hasMedia,  DateTime createdAt,  DateTime? expiresAt,  bool heard,  bool saved)  $default,) {final _that = this;
switch (_that) {
case _RadioMessage():
return $default(_that.id,_that.conversationId,_that.authorId,_that.authorName,_that.kind,_that.status,_that.body,_that.lat,_that.lng,_that.durationMs,_that.hasMedia,_that.createdAt,_that.expiresAt,_that.heard,_that.saved);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String conversationId,  String? authorId,  String authorName, @JsonKey(unknownEnumValue: RadioMessageKind.text)  RadioMessageKind kind,  String status,  String? body,  double? lat,  double? lng,  int? durationMs,  bool hasMedia,  DateTime createdAt,  DateTime? expiresAt,  bool heard,  bool saved)?  $default,) {final _that = this;
switch (_that) {
case _RadioMessage() when $default != null:
return $default(_that.id,_that.conversationId,_that.authorId,_that.authorName,_that.kind,_that.status,_that.body,_that.lat,_that.lng,_that.durationMs,_that.hasMedia,_that.createdAt,_that.expiresAt,_that.heard,_that.saved);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioMessage implements RadioMessage {
  const _RadioMessage({required this.id, required this.conversationId, this.authorId, this.authorName = '', @JsonKey(unknownEnumValue: RadioMessageKind.text) required this.kind, this.status = 'ready', this.body, this.lat, this.lng, this.durationMs, this.hasMedia = false, required this.createdAt, this.expiresAt, this.heard = false, this.saved = false});
  factory _RadioMessage.fromJson(Map<String, dynamic> json) => _$RadioMessageFromJson(json);

@override final  String id;
@override final  String conversationId;
@override final  String? authorId;
@override@JsonKey() final  String authorName;
@override@JsonKey(unknownEnumValue: RadioMessageKind.text) final  RadioMessageKind kind;
@override@JsonKey() final  String status;
@override final  String? body;
@override final  double? lat;
@override final  double? lng;
@override final  int? durationMs;
@override@JsonKey() final  bool hasMedia;
@override final  DateTime createdAt;
@override final  DateTime? expiresAt;
@override@JsonKey() final  bool heard;
@override@JsonKey() final  bool saved;

/// Create a copy of RadioMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioMessageCopyWith<_RadioMessage> get copyWith => __$RadioMessageCopyWithImpl<_RadioMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.status, status) || other.status == status)&&(identical(other.body, body) || other.body == body)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.hasMedia, hasMedia) || other.hasMedia == hasMedia)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.heard, heard) || other.heard == heard)&&(identical(other.saved, saved) || other.saved == saved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversationId,authorId,authorName,kind,status,body,lat,lng,durationMs,hasMedia,createdAt,expiresAt,heard,saved);

@override
String toString() {
  return 'RadioMessage(id: $id, conversationId: $conversationId, authorId: $authorId, authorName: $authorName, kind: $kind, status: $status, body: $body, lat: $lat, lng: $lng, durationMs: $durationMs, hasMedia: $hasMedia, createdAt: $createdAt, expiresAt: $expiresAt, heard: $heard, saved: $saved)';
}


}

/// @nodoc
abstract mixin class _$RadioMessageCopyWith<$Res> implements $RadioMessageCopyWith<$Res> {
  factory _$RadioMessageCopyWith(_RadioMessage value, $Res Function(_RadioMessage) _then) = __$RadioMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String conversationId, String? authorId, String authorName,@JsonKey(unknownEnumValue: RadioMessageKind.text) RadioMessageKind kind, String status, String? body, double? lat, double? lng, int? durationMs, bool hasMedia, DateTime createdAt, DateTime? expiresAt, bool heard, bool saved
});




}
/// @nodoc
class __$RadioMessageCopyWithImpl<$Res>
    implements _$RadioMessageCopyWith<$Res> {
  __$RadioMessageCopyWithImpl(this._self, this._then);

  final _RadioMessage _self;
  final $Res Function(_RadioMessage) _then;

/// Create a copy of RadioMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conversationId = null,Object? authorId = freezed,Object? authorName = null,Object? kind = null,Object? status = null,Object? body = freezed,Object? lat = freezed,Object? lng = freezed,Object? durationMs = freezed,Object? hasMedia = null,Object? createdAt = null,Object? expiresAt = freezed,Object? heard = null,Object? saved = null,}) {
  return _then(_RadioMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String?,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RadioMessageKind,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,hasMedia: null == hasMedia ? _self.hasMedia : hasMedia // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,heard: null == heard ? _self.heard : heard // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$RadioCredentials {

 String get url; String get token; String get room; DateTime get expiresAt;
/// Create a copy of RadioCredentials
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioCredentialsCopyWith<RadioCredentials> get copyWith => _$RadioCredentialsCopyWithImpl<RadioCredentials>(this as RadioCredentials, _$identity);

  /// Serializes this RadioCredentials to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioCredentials&&(identical(other.url, url) || other.url == url)&&(identical(other.token, token) || other.token == token)&&(identical(other.room, room) || other.room == room)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,token,room,expiresAt);

@override
String toString() {
  return 'RadioCredentials(url: $url, token: $token, room: $room, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $RadioCredentialsCopyWith<$Res>  {
  factory $RadioCredentialsCopyWith(RadioCredentials value, $Res Function(RadioCredentials) _then) = _$RadioCredentialsCopyWithImpl;
@useResult
$Res call({
 String url, String token, String room, DateTime expiresAt
});




}
/// @nodoc
class _$RadioCredentialsCopyWithImpl<$Res>
    implements $RadioCredentialsCopyWith<$Res> {
  _$RadioCredentialsCopyWithImpl(this._self, this._then);

  final RadioCredentials _self;
  final $Res Function(RadioCredentials) _then;

/// Create a copy of RadioCredentials
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? token = null,Object? room = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioCredentials].
extension RadioCredentialsPatterns on RadioCredentials {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioCredentials value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioCredentials() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioCredentials value)  $default,){
final _that = this;
switch (_that) {
case _RadioCredentials():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioCredentials value)?  $default,){
final _that = this;
switch (_that) {
case _RadioCredentials() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String token,  String room,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioCredentials() when $default != null:
return $default(_that.url,_that.token,_that.room,_that.expiresAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String token,  String room,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _RadioCredentials():
return $default(_that.url,_that.token,_that.room,_that.expiresAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String token,  String room,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _RadioCredentials() when $default != null:
return $default(_that.url,_that.token,_that.room,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioCredentials implements RadioCredentials {
  const _RadioCredentials({required this.url, required this.token, required this.room, required this.expiresAt});
  factory _RadioCredentials.fromJson(Map<String, dynamic> json) => _$RadioCredentialsFromJson(json);

@override final  String url;
@override final  String token;
@override final  String room;
@override final  DateTime expiresAt;

/// Create a copy of RadioCredentials
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioCredentialsCopyWith<_RadioCredentials> get copyWith => __$RadioCredentialsCopyWithImpl<_RadioCredentials>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioCredentialsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioCredentials&&(identical(other.url, url) || other.url == url)&&(identical(other.token, token) || other.token == token)&&(identical(other.room, room) || other.room == room)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,token,room,expiresAt);

@override
String toString() {
  return 'RadioCredentials(url: $url, token: $token, room: $room, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$RadioCredentialsCopyWith<$Res> implements $RadioCredentialsCopyWith<$Res> {
  factory _$RadioCredentialsCopyWith(_RadioCredentials value, $Res Function(_RadioCredentials) _then) = __$RadioCredentialsCopyWithImpl;
@override @useResult
$Res call({
 String url, String token, String room, DateTime expiresAt
});




}
/// @nodoc
class __$RadioCredentialsCopyWithImpl<$Res>
    implements _$RadioCredentialsCopyWith<$Res> {
  __$RadioCredentialsCopyWithImpl(this._self, this._then);

  final _RadioCredentials _self;
  final $Res Function(_RadioCredentials) _then;

/// Create a copy of RadioCredentials
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? token = null,Object? room = null,Object? expiresAt = null,}) {
  return _then(_RadioCredentials(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$RadioFloor {

 String get messageId; DateTime get expiresAt;
/// Create a copy of RadioFloor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioFloorCopyWith<RadioFloor> get copyWith => _$RadioFloorCopyWithImpl<RadioFloor>(this as RadioFloor, _$identity);

  /// Serializes this RadioFloor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioFloor&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,expiresAt);

@override
String toString() {
  return 'RadioFloor(messageId: $messageId, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $RadioFloorCopyWith<$Res>  {
  factory $RadioFloorCopyWith(RadioFloor value, $Res Function(RadioFloor) _then) = _$RadioFloorCopyWithImpl;
@useResult
$Res call({
 String messageId, DateTime expiresAt
});




}
/// @nodoc
class _$RadioFloorCopyWithImpl<$Res>
    implements $RadioFloorCopyWith<$Res> {
  _$RadioFloorCopyWithImpl(this._self, this._then);

  final RadioFloor _self;
  final $Res Function(RadioFloor) _then;

/// Create a copy of RadioFloor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioFloor].
extension RadioFloorPatterns on RadioFloor {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioFloor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioFloor() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioFloor value)  $default,){
final _that = this;
switch (_that) {
case _RadioFloor():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioFloor value)?  $default,){
final _that = this;
switch (_that) {
case _RadioFloor() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioFloor() when $default != null:
return $default(_that.messageId,_that.expiresAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _RadioFloor():
return $default(_that.messageId,_that.expiresAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _RadioFloor() when $default != null:
return $default(_that.messageId,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioFloor implements RadioFloor {
  const _RadioFloor({required this.messageId, required this.expiresAt});
  factory _RadioFloor.fromJson(Map<String, dynamic> json) => _$RadioFloorFromJson(json);

@override final  String messageId;
@override final  DateTime expiresAt;

/// Create a copy of RadioFloor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioFloorCopyWith<_RadioFloor> get copyWith => __$RadioFloorCopyWithImpl<_RadioFloor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioFloorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioFloor&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,expiresAt);

@override
String toString() {
  return 'RadioFloor(messageId: $messageId, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$RadioFloorCopyWith<$Res> implements $RadioFloorCopyWith<$Res> {
  factory _$RadioFloorCopyWith(_RadioFloor value, $Res Function(_RadioFloor) _then) = __$RadioFloorCopyWithImpl;
@override @useResult
$Res call({
 String messageId, DateTime expiresAt
});




}
/// @nodoc
class __$RadioFloorCopyWithImpl<$Res>
    implements _$RadioFloorCopyWith<$Res> {
  __$RadioFloorCopyWithImpl(this._self, this._then);

  final _RadioFloor _self;
  final $Res Function(_RadioFloor) _then;

/// Create a copy of RadioFloor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? expiresAt = null,}) {
  return _then(_RadioFloor(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$RadioInvite {

 String get code; String get url; DateTime get expiresAt;
/// Create a copy of RadioInvite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioInviteCopyWith<RadioInvite> get copyWith => _$RadioInviteCopyWithImpl<RadioInvite>(this as RadioInvite, _$identity);

  /// Serializes this RadioInvite to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioInvite&&(identical(other.code, code) || other.code == code)&&(identical(other.url, url) || other.url == url)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,url,expiresAt);

@override
String toString() {
  return 'RadioInvite(code: $code, url: $url, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $RadioInviteCopyWith<$Res>  {
  factory $RadioInviteCopyWith(RadioInvite value, $Res Function(RadioInvite) _then) = _$RadioInviteCopyWithImpl;
@useResult
$Res call({
 String code, String url, DateTime expiresAt
});




}
/// @nodoc
class _$RadioInviteCopyWithImpl<$Res>
    implements $RadioInviteCopyWith<$Res> {
  _$RadioInviteCopyWithImpl(this._self, this._then);

  final RadioInvite _self;
  final $Res Function(RadioInvite) _then;

/// Create a copy of RadioInvite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? url = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioInvite].
extension RadioInvitePatterns on RadioInvite {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioInvite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioInvite() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioInvite value)  $default,){
final _that = this;
switch (_that) {
case _RadioInvite():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioInvite value)?  $default,){
final _that = this;
switch (_that) {
case _RadioInvite() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String url,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioInvite() when $default != null:
return $default(_that.code,_that.url,_that.expiresAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String url,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _RadioInvite():
return $default(_that.code,_that.url,_that.expiresAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String url,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _RadioInvite() when $default != null:
return $default(_that.code,_that.url,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioInvite implements RadioInvite {
  const _RadioInvite({required this.code, required this.url, required this.expiresAt});
  factory _RadioInvite.fromJson(Map<String, dynamic> json) => _$RadioInviteFromJson(json);

@override final  String code;
@override final  String url;
@override final  DateTime expiresAt;

/// Create a copy of RadioInvite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioInviteCopyWith<_RadioInvite> get copyWith => __$RadioInviteCopyWithImpl<_RadioInvite>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioInviteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioInvite&&(identical(other.code, code) || other.code == code)&&(identical(other.url, url) || other.url == url)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,url,expiresAt);

@override
String toString() {
  return 'RadioInvite(code: $code, url: $url, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$RadioInviteCopyWith<$Res> implements $RadioInviteCopyWith<$Res> {
  factory _$RadioInviteCopyWith(_RadioInvite value, $Res Function(_RadioInvite) _then) = __$RadioInviteCopyWithImpl;
@override @useResult
$Res call({
 String code, String url, DateTime expiresAt
});




}
/// @nodoc
class __$RadioInviteCopyWithImpl<$Res>
    implements _$RadioInviteCopyWith<$Res> {
  __$RadioInviteCopyWithImpl(this._self, this._then);

  final _RadioInvite _self;
  final $Res Function(_RadioInvite) _then;

/// Create a copy of RadioInvite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? url = null,Object? expiresAt = null,}) {
  return _then(_RadioInvite(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$RadioInvitePreview {

/// `contact` o `channel`.
 String get kind; String get inviterName; String? get channelName;/// `driver` o `passenger`: qué app abre la invitación.
 String get inviteeKind;
/// Create a copy of RadioInvitePreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioInvitePreviewCopyWith<RadioInvitePreview> get copyWith => _$RadioInvitePreviewCopyWithImpl<RadioInvitePreview>(this as RadioInvitePreview, _$identity);

  /// Serializes this RadioInvitePreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioInvitePreview&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.inviterName, inviterName) || other.inviterName == inviterName)&&(identical(other.channelName, channelName) || other.channelName == channelName)&&(identical(other.inviteeKind, inviteeKind) || other.inviteeKind == inviteeKind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,inviterName,channelName,inviteeKind);

@override
String toString() {
  return 'RadioInvitePreview(kind: $kind, inviterName: $inviterName, channelName: $channelName, inviteeKind: $inviteeKind)';
}


}

/// @nodoc
abstract mixin class $RadioInvitePreviewCopyWith<$Res>  {
  factory $RadioInvitePreviewCopyWith(RadioInvitePreview value, $Res Function(RadioInvitePreview) _then) = _$RadioInvitePreviewCopyWithImpl;
@useResult
$Res call({
 String kind, String inviterName, String? channelName, String inviteeKind
});




}
/// @nodoc
class _$RadioInvitePreviewCopyWithImpl<$Res>
    implements $RadioInvitePreviewCopyWith<$Res> {
  _$RadioInvitePreviewCopyWithImpl(this._self, this._then);

  final RadioInvitePreview _self;
  final $Res Function(RadioInvitePreview) _then;

/// Create a copy of RadioInvitePreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? inviterName = null,Object? channelName = freezed,Object? inviteeKind = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,inviterName: null == inviterName ? _self.inviterName : inviterName // ignore: cast_nullable_to_non_nullable
as String,channelName: freezed == channelName ? _self.channelName : channelName // ignore: cast_nullable_to_non_nullable
as String?,inviteeKind: null == inviteeKind ? _self.inviteeKind : inviteeKind // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioInvitePreview].
extension RadioInvitePreviewPatterns on RadioInvitePreview {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioInvitePreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioInvitePreview() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioInvitePreview value)  $default,){
final _that = this;
switch (_that) {
case _RadioInvitePreview():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioInvitePreview value)?  $default,){
final _that = this;
switch (_that) {
case _RadioInvitePreview() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String inviterName,  String? channelName,  String inviteeKind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioInvitePreview() when $default != null:
return $default(_that.kind,_that.inviterName,_that.channelName,_that.inviteeKind);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String inviterName,  String? channelName,  String inviteeKind)  $default,) {final _that = this;
switch (_that) {
case _RadioInvitePreview():
return $default(_that.kind,_that.inviterName,_that.channelName,_that.inviteeKind);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String inviterName,  String? channelName,  String inviteeKind)?  $default,) {final _that = this;
switch (_that) {
case _RadioInvitePreview() when $default != null:
return $default(_that.kind,_that.inviterName,_that.channelName,_that.inviteeKind);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioInvitePreview implements RadioInvitePreview {
  const _RadioInvitePreview({required this.kind, required this.inviterName, this.channelName, required this.inviteeKind});
  factory _RadioInvitePreview.fromJson(Map<String, dynamic> json) => _$RadioInvitePreviewFromJson(json);

/// `contact` o `channel`.
@override final  String kind;
@override final  String inviterName;
@override final  String? channelName;
/// `driver` o `passenger`: qué app abre la invitación.
@override final  String inviteeKind;

/// Create a copy of RadioInvitePreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioInvitePreviewCopyWith<_RadioInvitePreview> get copyWith => __$RadioInvitePreviewCopyWithImpl<_RadioInvitePreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioInvitePreviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioInvitePreview&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.inviterName, inviterName) || other.inviterName == inviterName)&&(identical(other.channelName, channelName) || other.channelName == channelName)&&(identical(other.inviteeKind, inviteeKind) || other.inviteeKind == inviteeKind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,inviterName,channelName,inviteeKind);

@override
String toString() {
  return 'RadioInvitePreview(kind: $kind, inviterName: $inviterName, channelName: $channelName, inviteeKind: $inviteeKind)';
}


}

/// @nodoc
abstract mixin class _$RadioInvitePreviewCopyWith<$Res> implements $RadioInvitePreviewCopyWith<$Res> {
  factory _$RadioInvitePreviewCopyWith(_RadioInvitePreview value, $Res Function(_RadioInvitePreview) _then) = __$RadioInvitePreviewCopyWithImpl;
@override @useResult
$Res call({
 String kind, String inviterName, String? channelName, String inviteeKind
});




}
/// @nodoc
class __$RadioInvitePreviewCopyWithImpl<$Res>
    implements _$RadioInvitePreviewCopyWith<$Res> {
  __$RadioInvitePreviewCopyWithImpl(this._self, this._then);

  final _RadioInvitePreview _self;
  final $Res Function(_RadioInvitePreview) _then;

/// Create a copy of RadioInvitePreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? inviterName = null,Object? channelName = freezed,Object? inviteeKind = null,}) {
  return _then(_RadioInvitePreview(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,inviterName: null == inviterName ? _self.inviterName : inviterName // ignore: cast_nullable_to_non_nullable
as String,channelName: freezed == channelName ? _self.channelName : channelName // ignore: cast_nullable_to_non_nullable
as String?,inviteeKind: null == inviteeKind ? _self.inviteeKind : inviteeKind // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RadioQuietHours {

/// 1 = lunes … 7 = domingo.
 List<int> get weekdays;/// "22:00".
 String get starts; String get ends; bool get enabled;
/// Create a copy of RadioQuietHours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioQuietHoursCopyWith<RadioQuietHours> get copyWith => _$RadioQuietHoursCopyWithImpl<RadioQuietHours>(this as RadioQuietHours, _$identity);

  /// Serializes this RadioQuietHours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioQuietHours&&const DeepCollectionEquality().equals(other.weekdays, weekdays)&&(identical(other.starts, starts) || other.starts == starts)&&(identical(other.ends, ends) || other.ends == ends)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(weekdays),starts,ends,enabled);

@override
String toString() {
  return 'RadioQuietHours(weekdays: $weekdays, starts: $starts, ends: $ends, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $RadioQuietHoursCopyWith<$Res>  {
  factory $RadioQuietHoursCopyWith(RadioQuietHours value, $Res Function(RadioQuietHours) _then) = _$RadioQuietHoursCopyWithImpl;
@useResult
$Res call({
 List<int> weekdays, String starts, String ends, bool enabled
});




}
/// @nodoc
class _$RadioQuietHoursCopyWithImpl<$Res>
    implements $RadioQuietHoursCopyWith<$Res> {
  _$RadioQuietHoursCopyWithImpl(this._self, this._then);

  final RadioQuietHours _self;
  final $Res Function(RadioQuietHours) _then;

/// Create a copy of RadioQuietHours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekdays = null,Object? starts = null,Object? ends = null,Object? enabled = null,}) {
  return _then(_self.copyWith(
weekdays: null == weekdays ? _self.weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,starts: null == starts ? _self.starts : starts // ignore: cast_nullable_to_non_nullable
as String,ends: null == ends ? _self.ends : ends // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioQuietHours].
extension RadioQuietHoursPatterns on RadioQuietHours {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioQuietHours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioQuietHours() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioQuietHours value)  $default,){
final _that = this;
switch (_that) {
case _RadioQuietHours():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioQuietHours value)?  $default,){
final _that = this;
switch (_that) {
case _RadioQuietHours() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<int> weekdays,  String starts,  String ends,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioQuietHours() when $default != null:
return $default(_that.weekdays,_that.starts,_that.ends,_that.enabled);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<int> weekdays,  String starts,  String ends,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _RadioQuietHours():
return $default(_that.weekdays,_that.starts,_that.ends,_that.enabled);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<int> weekdays,  String starts,  String ends,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _RadioQuietHours() when $default != null:
return $default(_that.weekdays,_that.starts,_that.ends,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioQuietHours implements RadioQuietHours {
  const _RadioQuietHours({required final  List<int> weekdays, required this.starts, required this.ends, this.enabled = true}): _weekdays = weekdays;
  factory _RadioQuietHours.fromJson(Map<String, dynamic> json) => _$RadioQuietHoursFromJson(json);

/// 1 = lunes … 7 = domingo.
 final  List<int> _weekdays;
/// 1 = lunes … 7 = domingo.
@override List<int> get weekdays {
  if (_weekdays is EqualUnmodifiableListView) return _weekdays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekdays);
}

/// "22:00".
@override final  String starts;
@override final  String ends;
@override@JsonKey() final  bool enabled;

/// Create a copy of RadioQuietHours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioQuietHoursCopyWith<_RadioQuietHours> get copyWith => __$RadioQuietHoursCopyWithImpl<_RadioQuietHours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioQuietHoursToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioQuietHours&&const DeepCollectionEquality().equals(other._weekdays, _weekdays)&&(identical(other.starts, starts) || other.starts == starts)&&(identical(other.ends, ends) || other.ends == ends)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_weekdays),starts,ends,enabled);

@override
String toString() {
  return 'RadioQuietHours(weekdays: $weekdays, starts: $starts, ends: $ends, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$RadioQuietHoursCopyWith<$Res> implements $RadioQuietHoursCopyWith<$Res> {
  factory _$RadioQuietHoursCopyWith(_RadioQuietHours value, $Res Function(_RadioQuietHours) _then) = __$RadioQuietHoursCopyWithImpl;
@override @useResult
$Res call({
 List<int> weekdays, String starts, String ends, bool enabled
});




}
/// @nodoc
class __$RadioQuietHoursCopyWithImpl<$Res>
    implements _$RadioQuietHoursCopyWith<$Res> {
  __$RadioQuietHoursCopyWithImpl(this._self, this._then);

  final _RadioQuietHours _self;
  final $Res Function(_RadioQuietHours) _then;

/// Create a copy of RadioQuietHours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekdays = null,Object? starts = null,Object? ends = null,Object? enabled = null,}) {
  return _then(_RadioQuietHours(
weekdays: null == weekdays ? _self._weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>,starts: null == starts ? _self.starts : starts // ignore: cast_nullable_to_non_nullable
as String,ends: null == ends ? _self.ends : ends // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$RadioPhotoUpload {

 String get messageId; String get uploadUrl; String get contentType;
/// Create a copy of RadioPhotoUpload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioPhotoUploadCopyWith<RadioPhotoUpload> get copyWith => _$RadioPhotoUploadCopyWithImpl<RadioPhotoUpload>(this as RadioPhotoUpload, _$identity);

  /// Serializes this RadioPhotoUpload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioPhotoUpload&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.contentType, contentType) || other.contentType == contentType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,uploadUrl,contentType);

@override
String toString() {
  return 'RadioPhotoUpload(messageId: $messageId, uploadUrl: $uploadUrl, contentType: $contentType)';
}


}

/// @nodoc
abstract mixin class $RadioPhotoUploadCopyWith<$Res>  {
  factory $RadioPhotoUploadCopyWith(RadioPhotoUpload value, $Res Function(RadioPhotoUpload) _then) = _$RadioPhotoUploadCopyWithImpl;
@useResult
$Res call({
 String messageId, String uploadUrl, String contentType
});




}
/// @nodoc
class _$RadioPhotoUploadCopyWithImpl<$Res>
    implements $RadioPhotoUploadCopyWith<$Res> {
  _$RadioPhotoUploadCopyWithImpl(this._self, this._then);

  final RadioPhotoUpload _self;
  final $Res Function(RadioPhotoUpload) _then;

/// Create a copy of RadioPhotoUpload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? uploadUrl = null,Object? contentType = null,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioPhotoUpload].
extension RadioPhotoUploadPatterns on RadioPhotoUpload {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioPhotoUpload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioPhotoUpload() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioPhotoUpload value)  $default,){
final _that = this;
switch (_that) {
case _RadioPhotoUpload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioPhotoUpload value)?  $default,){
final _that = this;
switch (_that) {
case _RadioPhotoUpload() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  String uploadUrl,  String contentType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioPhotoUpload() when $default != null:
return $default(_that.messageId,_that.uploadUrl,_that.contentType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  String uploadUrl,  String contentType)  $default,) {final _that = this;
switch (_that) {
case _RadioPhotoUpload():
return $default(_that.messageId,_that.uploadUrl,_that.contentType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  String uploadUrl,  String contentType)?  $default,) {final _that = this;
switch (_that) {
case _RadioPhotoUpload() when $default != null:
return $default(_that.messageId,_that.uploadUrl,_that.contentType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioPhotoUpload implements RadioPhotoUpload {
  const _RadioPhotoUpload({required this.messageId, required this.uploadUrl, this.contentType = 'image/jpeg'});
  factory _RadioPhotoUpload.fromJson(Map<String, dynamic> json) => _$RadioPhotoUploadFromJson(json);

@override final  String messageId;
@override final  String uploadUrl;
@override@JsonKey() final  String contentType;

/// Create a copy of RadioPhotoUpload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioPhotoUploadCopyWith<_RadioPhotoUpload> get copyWith => __$RadioPhotoUploadCopyWithImpl<_RadioPhotoUpload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioPhotoUploadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioPhotoUpload&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.contentType, contentType) || other.contentType == contentType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,uploadUrl,contentType);

@override
String toString() {
  return 'RadioPhotoUpload(messageId: $messageId, uploadUrl: $uploadUrl, contentType: $contentType)';
}


}

/// @nodoc
abstract mixin class _$RadioPhotoUploadCopyWith<$Res> implements $RadioPhotoUploadCopyWith<$Res> {
  factory _$RadioPhotoUploadCopyWith(_RadioPhotoUpload value, $Res Function(_RadioPhotoUpload) _then) = __$RadioPhotoUploadCopyWithImpl;
@override @useResult
$Res call({
 String messageId, String uploadUrl, String contentType
});




}
/// @nodoc
class __$RadioPhotoUploadCopyWithImpl<$Res>
    implements _$RadioPhotoUploadCopyWith<$Res> {
  __$RadioPhotoUploadCopyWithImpl(this._self, this._then);

  final _RadioPhotoUpload _self;
  final $Res Function(_RadioPhotoUpload) _then;

/// Create a copy of RadioPhotoUpload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? uploadUrl = null,Object? contentType = null,}) {
  return _then(_RadioPhotoUpload(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RadioEmergency {

 String get alertId; String? get tripId;
/// Create a copy of RadioEmergency
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioEmergencyCopyWith<RadioEmergency> get copyWith => _$RadioEmergencyCopyWithImpl<RadioEmergency>(this as RadioEmergency, _$identity);

  /// Serializes this RadioEmergency to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioEmergency&&(identical(other.alertId, alertId) || other.alertId == alertId)&&(identical(other.tripId, tripId) || other.tripId == tripId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,alertId,tripId);

@override
String toString() {
  return 'RadioEmergency(alertId: $alertId, tripId: $tripId)';
}


}

/// @nodoc
abstract mixin class $RadioEmergencyCopyWith<$Res>  {
  factory $RadioEmergencyCopyWith(RadioEmergency value, $Res Function(RadioEmergency) _then) = _$RadioEmergencyCopyWithImpl;
@useResult
$Res call({
 String alertId, String? tripId
});




}
/// @nodoc
class _$RadioEmergencyCopyWithImpl<$Res>
    implements $RadioEmergencyCopyWith<$Res> {
  _$RadioEmergencyCopyWithImpl(this._self, this._then);

  final RadioEmergency _self;
  final $Res Function(RadioEmergency) _then;

/// Create a copy of RadioEmergency
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? alertId = null,Object? tripId = freezed,}) {
  return _then(_self.copyWith(
alertId: null == alertId ? _self.alertId : alertId // ignore: cast_nullable_to_non_nullable
as String,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioEmergency].
extension RadioEmergencyPatterns on RadioEmergency {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioEmergency value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioEmergency() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioEmergency value)  $default,){
final _that = this;
switch (_that) {
case _RadioEmergency():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioEmergency value)?  $default,){
final _that = this;
switch (_that) {
case _RadioEmergency() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String alertId,  String? tripId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioEmergency() when $default != null:
return $default(_that.alertId,_that.tripId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String alertId,  String? tripId)  $default,) {final _that = this;
switch (_that) {
case _RadioEmergency():
return $default(_that.alertId,_that.tripId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String alertId,  String? tripId)?  $default,) {final _that = this;
switch (_that) {
case _RadioEmergency() when $default != null:
return $default(_that.alertId,_that.tripId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioEmergency implements RadioEmergency {
  const _RadioEmergency({required this.alertId, this.tripId});
  factory _RadioEmergency.fromJson(Map<String, dynamic> json) => _$RadioEmergencyFromJson(json);

@override final  String alertId;
@override final  String? tripId;

/// Create a copy of RadioEmergency
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioEmergencyCopyWith<_RadioEmergency> get copyWith => __$RadioEmergencyCopyWithImpl<_RadioEmergency>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioEmergencyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioEmergency&&(identical(other.alertId, alertId) || other.alertId == alertId)&&(identical(other.tripId, tripId) || other.tripId == tripId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,alertId,tripId);

@override
String toString() {
  return 'RadioEmergency(alertId: $alertId, tripId: $tripId)';
}


}

/// @nodoc
abstract mixin class _$RadioEmergencyCopyWith<$Res> implements $RadioEmergencyCopyWith<$Res> {
  factory _$RadioEmergencyCopyWith(_RadioEmergency value, $Res Function(_RadioEmergency) _then) = __$RadioEmergencyCopyWithImpl;
@override @useResult
$Res call({
 String alertId, String? tripId
});




}
/// @nodoc
class __$RadioEmergencyCopyWithImpl<$Res>
    implements _$RadioEmergencyCopyWith<$Res> {
  __$RadioEmergencyCopyWithImpl(this._self, this._then);

  final _RadioEmergency _self;
  final $Res Function(_RadioEmergency) _then;

/// Create a copy of RadioEmergency
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? alertId = null,Object? tripId = freezed,}) {
  return _then(_RadioEmergency(
alertId: null == alertId ? _self.alertId : alertId // ignore: cast_nullable_to_non_nullable
as String,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RadioSettings {

/// `trial`, `subscription_only` o `listen_only`.
 String get trialPolicy; int get trialDays;/// `none`, `listen_only` o `all_roles`.
 String get passengersInChannels; int get retentionDays; DateTime? get updatedAt; String get updatedByName;/// Costo mensual estimado por retención ("7", "30", "90"), en unidades mínimas.
 Map<String, int> get estimatedMonthlyCostMinor;
/// Create a copy of RadioSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioSettingsCopyWith<RadioSettings> get copyWith => _$RadioSettingsCopyWithImpl<RadioSettings>(this as RadioSettings, _$identity);

  /// Serializes this RadioSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioSettings&&(identical(other.trialPolicy, trialPolicy) || other.trialPolicy == trialPolicy)&&(identical(other.trialDays, trialDays) || other.trialDays == trialDays)&&(identical(other.passengersInChannels, passengersInChannels) || other.passengersInChannels == passengersInChannels)&&(identical(other.retentionDays, retentionDays) || other.retentionDays == retentionDays)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedByName, updatedByName) || other.updatedByName == updatedByName)&&const DeepCollectionEquality().equals(other.estimatedMonthlyCostMinor, estimatedMonthlyCostMinor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trialPolicy,trialDays,passengersInChannels,retentionDays,updatedAt,updatedByName,const DeepCollectionEquality().hash(estimatedMonthlyCostMinor));

@override
String toString() {
  return 'RadioSettings(trialPolicy: $trialPolicy, trialDays: $trialDays, passengersInChannels: $passengersInChannels, retentionDays: $retentionDays, updatedAt: $updatedAt, updatedByName: $updatedByName, estimatedMonthlyCostMinor: $estimatedMonthlyCostMinor)';
}


}

/// @nodoc
abstract mixin class $RadioSettingsCopyWith<$Res>  {
  factory $RadioSettingsCopyWith(RadioSettings value, $Res Function(RadioSettings) _then) = _$RadioSettingsCopyWithImpl;
@useResult
$Res call({
 String trialPolicy, int trialDays, String passengersInChannels, int retentionDays, DateTime? updatedAt, String updatedByName, Map<String, int> estimatedMonthlyCostMinor
});




}
/// @nodoc
class _$RadioSettingsCopyWithImpl<$Res>
    implements $RadioSettingsCopyWith<$Res> {
  _$RadioSettingsCopyWithImpl(this._self, this._then);

  final RadioSettings _self;
  final $Res Function(RadioSettings) _then;

/// Create a copy of RadioSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trialPolicy = null,Object? trialDays = null,Object? passengersInChannels = null,Object? retentionDays = null,Object? updatedAt = freezed,Object? updatedByName = null,Object? estimatedMonthlyCostMinor = null,}) {
  return _then(_self.copyWith(
trialPolicy: null == trialPolicy ? _self.trialPolicy : trialPolicy // ignore: cast_nullable_to_non_nullable
as String,trialDays: null == trialDays ? _self.trialDays : trialDays // ignore: cast_nullable_to_non_nullable
as int,passengersInChannels: null == passengersInChannels ? _self.passengersInChannels : passengersInChannels // ignore: cast_nullable_to_non_nullable
as String,retentionDays: null == retentionDays ? _self.retentionDays : retentionDays // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedByName: null == updatedByName ? _self.updatedByName : updatedByName // ignore: cast_nullable_to_non_nullable
as String,estimatedMonthlyCostMinor: null == estimatedMonthlyCostMinor ? _self.estimatedMonthlyCostMinor : estimatedMonthlyCostMinor // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioSettings].
extension RadioSettingsPatterns on RadioSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioSettings value)  $default,){
final _that = this;
switch (_that) {
case _RadioSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioSettings value)?  $default,){
final _that = this;
switch (_that) {
case _RadioSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String trialPolicy,  int trialDays,  String passengersInChannels,  int retentionDays,  DateTime? updatedAt,  String updatedByName,  Map<String, int> estimatedMonthlyCostMinor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioSettings() when $default != null:
return $default(_that.trialPolicy,_that.trialDays,_that.passengersInChannels,_that.retentionDays,_that.updatedAt,_that.updatedByName,_that.estimatedMonthlyCostMinor);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String trialPolicy,  int trialDays,  String passengersInChannels,  int retentionDays,  DateTime? updatedAt,  String updatedByName,  Map<String, int> estimatedMonthlyCostMinor)  $default,) {final _that = this;
switch (_that) {
case _RadioSettings():
return $default(_that.trialPolicy,_that.trialDays,_that.passengersInChannels,_that.retentionDays,_that.updatedAt,_that.updatedByName,_that.estimatedMonthlyCostMinor);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String trialPolicy,  int trialDays,  String passengersInChannels,  int retentionDays,  DateTime? updatedAt,  String updatedByName,  Map<String, int> estimatedMonthlyCostMinor)?  $default,) {final _that = this;
switch (_that) {
case _RadioSettings() when $default != null:
return $default(_that.trialPolicy,_that.trialDays,_that.passengersInChannels,_that.retentionDays,_that.updatedAt,_that.updatedByName,_that.estimatedMonthlyCostMinor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioSettings implements RadioSettings {
  const _RadioSettings({required this.trialPolicy, required this.trialDays, required this.passengersInChannels, required this.retentionDays, this.updatedAt, this.updatedByName = '', final  Map<String, int> estimatedMonthlyCostMinor = const <String, int>{}}): _estimatedMonthlyCostMinor = estimatedMonthlyCostMinor;
  factory _RadioSettings.fromJson(Map<String, dynamic> json) => _$RadioSettingsFromJson(json);

/// `trial`, `subscription_only` o `listen_only`.
@override final  String trialPolicy;
@override final  int trialDays;
/// `none`, `listen_only` o `all_roles`.
@override final  String passengersInChannels;
@override final  int retentionDays;
@override final  DateTime? updatedAt;
@override@JsonKey() final  String updatedByName;
/// Costo mensual estimado por retención ("7", "30", "90"), en unidades mínimas.
 final  Map<String, int> _estimatedMonthlyCostMinor;
/// Costo mensual estimado por retención ("7", "30", "90"), en unidades mínimas.
@override@JsonKey() Map<String, int> get estimatedMonthlyCostMinor {
  if (_estimatedMonthlyCostMinor is EqualUnmodifiableMapView) return _estimatedMonthlyCostMinor;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_estimatedMonthlyCostMinor);
}


/// Create a copy of RadioSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioSettingsCopyWith<_RadioSettings> get copyWith => __$RadioSettingsCopyWithImpl<_RadioSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioSettings&&(identical(other.trialPolicy, trialPolicy) || other.trialPolicy == trialPolicy)&&(identical(other.trialDays, trialDays) || other.trialDays == trialDays)&&(identical(other.passengersInChannels, passengersInChannels) || other.passengersInChannels == passengersInChannels)&&(identical(other.retentionDays, retentionDays) || other.retentionDays == retentionDays)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedByName, updatedByName) || other.updatedByName == updatedByName)&&const DeepCollectionEquality().equals(other._estimatedMonthlyCostMinor, _estimatedMonthlyCostMinor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trialPolicy,trialDays,passengersInChannels,retentionDays,updatedAt,updatedByName,const DeepCollectionEquality().hash(_estimatedMonthlyCostMinor));

@override
String toString() {
  return 'RadioSettings(trialPolicy: $trialPolicy, trialDays: $trialDays, passengersInChannels: $passengersInChannels, retentionDays: $retentionDays, updatedAt: $updatedAt, updatedByName: $updatedByName, estimatedMonthlyCostMinor: $estimatedMonthlyCostMinor)';
}


}

/// @nodoc
abstract mixin class _$RadioSettingsCopyWith<$Res> implements $RadioSettingsCopyWith<$Res> {
  factory _$RadioSettingsCopyWith(_RadioSettings value, $Res Function(_RadioSettings) _then) = __$RadioSettingsCopyWithImpl;
@override @useResult
$Res call({
 String trialPolicy, int trialDays, String passengersInChannels, int retentionDays, DateTime? updatedAt, String updatedByName, Map<String, int> estimatedMonthlyCostMinor
});




}
/// @nodoc
class __$RadioSettingsCopyWithImpl<$Res>
    implements _$RadioSettingsCopyWith<$Res> {
  __$RadioSettingsCopyWithImpl(this._self, this._then);

  final _RadioSettings _self;
  final $Res Function(_RadioSettings) _then;

/// Create a copy of RadioSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trialPolicy = null,Object? trialDays = null,Object? passengersInChannels = null,Object? retentionDays = null,Object? updatedAt = freezed,Object? updatedByName = null,Object? estimatedMonthlyCostMinor = null,}) {
  return _then(_RadioSettings(
trialPolicy: null == trialPolicy ? _self.trialPolicy : trialPolicy // ignore: cast_nullable_to_non_nullable
as String,trialDays: null == trialDays ? _self.trialDays : trialDays // ignore: cast_nullable_to_non_nullable
as int,passengersInChannels: null == passengersInChannels ? _self.passengersInChannels : passengersInChannels // ignore: cast_nullable_to_non_nullable
as String,retentionDays: null == retentionDays ? _self.retentionDays : retentionDays // ignore: cast_nullable_to_non_nullable
as int,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedByName: null == updatedByName ? _self.updatedByName : updatedByName // ignore: cast_nullable_to_non_nullable
as String,estimatedMonthlyCostMinor: null == estimatedMonthlyCostMinor ? _self._estimatedMonthlyCostMinor : estimatedMonthlyCostMinor // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}


/// @nodoc
mixin _$RadioBulkUpload {

 String get id; String get fileName;/// `validated`, `sending` o `done`.
 String get status; int get rowsTotal; Map<String, int> get counts; DateTime get createdAt;
/// Create a copy of RadioBulkUpload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioBulkUploadCopyWith<RadioBulkUpload> get copyWith => _$RadioBulkUploadCopyWithImpl<RadioBulkUpload>(this as RadioBulkUpload, _$identity);

  /// Serializes this RadioBulkUpload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioBulkUpload&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.status, status) || other.status == status)&&(identical(other.rowsTotal, rowsTotal) || other.rowsTotal == rowsTotal)&&const DeepCollectionEquality().equals(other.counts, counts)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,status,rowsTotal,const DeepCollectionEquality().hash(counts),createdAt);

@override
String toString() {
  return 'RadioBulkUpload(id: $id, fileName: $fileName, status: $status, rowsTotal: $rowsTotal, counts: $counts, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $RadioBulkUploadCopyWith<$Res>  {
  factory $RadioBulkUploadCopyWith(RadioBulkUpload value, $Res Function(RadioBulkUpload) _then) = _$RadioBulkUploadCopyWithImpl;
@useResult
$Res call({
 String id, String fileName, String status, int rowsTotal, Map<String, int> counts, DateTime createdAt
});




}
/// @nodoc
class _$RadioBulkUploadCopyWithImpl<$Res>
    implements $RadioBulkUploadCopyWith<$Res> {
  _$RadioBulkUploadCopyWithImpl(this._self, this._then);

  final RadioBulkUpload _self;
  final $Res Function(RadioBulkUpload) _then;

/// Create a copy of RadioBulkUpload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fileName = null,Object? status = null,Object? rowsTotal = null,Object? counts = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,rowsTotal: null == rowsTotal ? _self.rowsTotal : rowsTotal // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioBulkUpload].
extension RadioBulkUploadPatterns on RadioBulkUpload {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioBulkUpload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioBulkUpload() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioBulkUpload value)  $default,){
final _that = this;
switch (_that) {
case _RadioBulkUpload():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioBulkUpload value)?  $default,){
final _that = this;
switch (_that) {
case _RadioBulkUpload() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fileName,  String status,  int rowsTotal,  Map<String, int> counts,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioBulkUpload() when $default != null:
return $default(_that.id,_that.fileName,_that.status,_that.rowsTotal,_that.counts,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fileName,  String status,  int rowsTotal,  Map<String, int> counts,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _RadioBulkUpload():
return $default(_that.id,_that.fileName,_that.status,_that.rowsTotal,_that.counts,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fileName,  String status,  int rowsTotal,  Map<String, int> counts,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _RadioBulkUpload() when $default != null:
return $default(_that.id,_that.fileName,_that.status,_that.rowsTotal,_that.counts,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioBulkUpload implements RadioBulkUpload {
  const _RadioBulkUpload({required this.id, required this.fileName, required this.status, required this.rowsTotal, final  Map<String, int> counts = const <String, int>{}, required this.createdAt}): _counts = counts;
  factory _RadioBulkUpload.fromJson(Map<String, dynamic> json) => _$RadioBulkUploadFromJson(json);

@override final  String id;
@override final  String fileName;
/// `validated`, `sending` o `done`.
@override final  String status;
@override final  int rowsTotal;
 final  Map<String, int> _counts;
@override@JsonKey() Map<String, int> get counts {
  if (_counts is EqualUnmodifiableMapView) return _counts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_counts);
}

@override final  DateTime createdAt;

/// Create a copy of RadioBulkUpload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioBulkUploadCopyWith<_RadioBulkUpload> get copyWith => __$RadioBulkUploadCopyWithImpl<_RadioBulkUpload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioBulkUploadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioBulkUpload&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.status, status) || other.status == status)&&(identical(other.rowsTotal, rowsTotal) || other.rowsTotal == rowsTotal)&&const DeepCollectionEquality().equals(other._counts, _counts)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,status,rowsTotal,const DeepCollectionEquality().hash(_counts),createdAt);

@override
String toString() {
  return 'RadioBulkUpload(id: $id, fileName: $fileName, status: $status, rowsTotal: $rowsTotal, counts: $counts, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RadioBulkUploadCopyWith<$Res> implements $RadioBulkUploadCopyWith<$Res> {
  factory _$RadioBulkUploadCopyWith(_RadioBulkUpload value, $Res Function(_RadioBulkUpload) _then) = __$RadioBulkUploadCopyWithImpl;
@override @useResult
$Res call({
 String id, String fileName, String status, int rowsTotal, Map<String, int> counts, DateTime createdAt
});




}
/// @nodoc
class __$RadioBulkUploadCopyWithImpl<$Res>
    implements _$RadioBulkUploadCopyWith<$Res> {
  __$RadioBulkUploadCopyWithImpl(this._self, this._then);

  final _RadioBulkUpload _self;
  final $Res Function(_RadioBulkUpload) _then;

/// Create a copy of RadioBulkUpload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fileName = null,Object? status = null,Object? rowsTotal = null,Object? counts = null,Object? createdAt = null,}) {
  return _then(_RadioBulkUpload(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,rowsTotal: null == rowsTotal ? _self.rowsTotal : rowsTotal // ignore: cast_nullable_to_non_nullable
as int,counts: null == counts ? _self._counts : counts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$RadioBulkRow {

 int get line; String get name; String get phoneMasked; String get kind; String get channel;@JsonKey(unknownEnumValue: RadioRole.member) RadioRole? get role;/// `pending`, `sent`, `failed`, `accepted`, `already_member` o `expired`.
 String get status; String? get error;
/// Create a copy of RadioBulkRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioBulkRowCopyWith<RadioBulkRow> get copyWith => _$RadioBulkRowCopyWithImpl<RadioBulkRow>(this as RadioBulkRow, _$identity);

  /// Serializes this RadioBulkRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioBulkRow&&(identical(other.line, line) || other.line == line)&&(identical(other.name, name) || other.name == name)&&(identical(other.phoneMasked, phoneMasked) || other.phoneMasked == phoneMasked)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,line,name,phoneMasked,kind,channel,role,status,error);

@override
String toString() {
  return 'RadioBulkRow(line: $line, name: $name, phoneMasked: $phoneMasked, kind: $kind, channel: $channel, role: $role, status: $status, error: $error)';
}


}

/// @nodoc
abstract mixin class $RadioBulkRowCopyWith<$Res>  {
  factory $RadioBulkRowCopyWith(RadioBulkRow value, $Res Function(RadioBulkRow) _then) = _$RadioBulkRowCopyWithImpl;
@useResult
$Res call({
 int line, String name, String phoneMasked, String kind, String channel,@JsonKey(unknownEnumValue: RadioRole.member) RadioRole? role, String status, String? error
});




}
/// @nodoc
class _$RadioBulkRowCopyWithImpl<$Res>
    implements $RadioBulkRowCopyWith<$Res> {
  _$RadioBulkRowCopyWithImpl(this._self, this._then);

  final RadioBulkRow _self;
  final $Res Function(RadioBulkRow) _then;

/// Create a copy of RadioBulkRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? line = null,Object? name = null,Object? phoneMasked = null,Object? kind = null,Object? channel = null,Object? role = freezed,Object? status = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phoneMasked: null == phoneMasked ? _self.phoneMasked : phoneMasked // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as RadioRole?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioBulkRow].
extension RadioBulkRowPatterns on RadioBulkRow {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioBulkRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioBulkRow() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioBulkRow value)  $default,){
final _that = this;
switch (_that) {
case _RadioBulkRow():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioBulkRow value)?  $default,){
final _that = this;
switch (_that) {
case _RadioBulkRow() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int line,  String name,  String phoneMasked,  String kind,  String channel, @JsonKey(unknownEnumValue: RadioRole.member)  RadioRole? role,  String status,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioBulkRow() when $default != null:
return $default(_that.line,_that.name,_that.phoneMasked,_that.kind,_that.channel,_that.role,_that.status,_that.error);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int line,  String name,  String phoneMasked,  String kind,  String channel, @JsonKey(unknownEnumValue: RadioRole.member)  RadioRole? role,  String status,  String? error)  $default,) {final _that = this;
switch (_that) {
case _RadioBulkRow():
return $default(_that.line,_that.name,_that.phoneMasked,_that.kind,_that.channel,_that.role,_that.status,_that.error);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int line,  String name,  String phoneMasked,  String kind,  String channel, @JsonKey(unknownEnumValue: RadioRole.member)  RadioRole? role,  String status,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _RadioBulkRow() when $default != null:
return $default(_that.line,_that.name,_that.phoneMasked,_that.kind,_that.channel,_that.role,_that.status,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioBulkRow implements RadioBulkRow {
  const _RadioBulkRow({required this.line, this.name = '', this.phoneMasked = '', this.kind = 'driver', this.channel = '', @JsonKey(unknownEnumValue: RadioRole.member) this.role, required this.status, this.error});
  factory _RadioBulkRow.fromJson(Map<String, dynamic> json) => _$RadioBulkRowFromJson(json);

@override final  int line;
@override@JsonKey() final  String name;
@override@JsonKey() final  String phoneMasked;
@override@JsonKey() final  String kind;
@override@JsonKey() final  String channel;
@override@JsonKey(unknownEnumValue: RadioRole.member) final  RadioRole? role;
/// `pending`, `sent`, `failed`, `accepted`, `already_member` o `expired`.
@override final  String status;
@override final  String? error;

/// Create a copy of RadioBulkRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioBulkRowCopyWith<_RadioBulkRow> get copyWith => __$RadioBulkRowCopyWithImpl<_RadioBulkRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioBulkRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioBulkRow&&(identical(other.line, line) || other.line == line)&&(identical(other.name, name) || other.name == name)&&(identical(other.phoneMasked, phoneMasked) || other.phoneMasked == phoneMasked)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,line,name,phoneMasked,kind,channel,role,status,error);

@override
String toString() {
  return 'RadioBulkRow(line: $line, name: $name, phoneMasked: $phoneMasked, kind: $kind, channel: $channel, role: $role, status: $status, error: $error)';
}


}

/// @nodoc
abstract mixin class _$RadioBulkRowCopyWith<$Res> implements $RadioBulkRowCopyWith<$Res> {
  factory _$RadioBulkRowCopyWith(_RadioBulkRow value, $Res Function(_RadioBulkRow) _then) = __$RadioBulkRowCopyWithImpl;
@override @useResult
$Res call({
 int line, String name, String phoneMasked, String kind, String channel,@JsonKey(unknownEnumValue: RadioRole.member) RadioRole? role, String status, String? error
});




}
/// @nodoc
class __$RadioBulkRowCopyWithImpl<$Res>
    implements _$RadioBulkRowCopyWith<$Res> {
  __$RadioBulkRowCopyWithImpl(this._self, this._then);

  final _RadioBulkRow _self;
  final $Res Function(_RadioBulkRow) _then;

/// Create a copy of RadioBulkRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? line = null,Object? name = null,Object? phoneMasked = null,Object? kind = null,Object? channel = null,Object? role = freezed,Object? status = null,Object? error = freezed,}) {
  return _then(_RadioBulkRow(
line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phoneMasked: null == phoneMasked ? _self.phoneMasked : phoneMasked // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as RadioRole?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RadioReport {

 String get id; String get messageKind; String get conversationTitle; String get reason; DateTime get createdAt;
/// Create a copy of RadioReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadioReportCopyWith<RadioReport> get copyWith => _$RadioReportCopyWithImpl<RadioReport>(this as RadioReport, _$identity);

  /// Serializes this RadioReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioReport&&(identical(other.id, id) || other.id == id)&&(identical(other.messageKind, messageKind) || other.messageKind == messageKind)&&(identical(other.conversationTitle, conversationTitle) || other.conversationTitle == conversationTitle)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,messageKind,conversationTitle,reason,createdAt);

@override
String toString() {
  return 'RadioReport(id: $id, messageKind: $messageKind, conversationTitle: $conversationTitle, reason: $reason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $RadioReportCopyWith<$Res>  {
  factory $RadioReportCopyWith(RadioReport value, $Res Function(RadioReport) _then) = _$RadioReportCopyWithImpl;
@useResult
$Res call({
 String id, String messageKind, String conversationTitle, String reason, DateTime createdAt
});




}
/// @nodoc
class _$RadioReportCopyWithImpl<$Res>
    implements $RadioReportCopyWith<$Res> {
  _$RadioReportCopyWithImpl(this._self, this._then);

  final RadioReport _self;
  final $Res Function(RadioReport) _then;

/// Create a copy of RadioReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? messageKind = null,Object? conversationTitle = null,Object? reason = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,messageKind: null == messageKind ? _self.messageKind : messageKind // ignore: cast_nullable_to_non_nullable
as String,conversationTitle: null == conversationTitle ? _self.conversationTitle : conversationTitle // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RadioReport].
extension RadioReportPatterns on RadioReport {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadioReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadioReport() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadioReport value)  $default,){
final _that = this;
switch (_that) {
case _RadioReport():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadioReport value)?  $default,){
final _that = this;
switch (_that) {
case _RadioReport() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String messageKind,  String conversationTitle,  String reason,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadioReport() when $default != null:
return $default(_that.id,_that.messageKind,_that.conversationTitle,_that.reason,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String messageKind,  String conversationTitle,  String reason,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _RadioReport():
return $default(_that.id,_that.messageKind,_that.conversationTitle,_that.reason,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String messageKind,  String conversationTitle,  String reason,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _RadioReport() when $default != null:
return $default(_that.id,_that.messageKind,_that.conversationTitle,_that.reason,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadioReport implements RadioReport {
  const _RadioReport({required this.id, required this.messageKind, required this.conversationTitle, this.reason = '', required this.createdAt});
  factory _RadioReport.fromJson(Map<String, dynamic> json) => _$RadioReportFromJson(json);

@override final  String id;
@override final  String messageKind;
@override final  String conversationTitle;
@override@JsonKey() final  String reason;
@override final  DateTime createdAt;

/// Create a copy of RadioReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadioReportCopyWith<_RadioReport> get copyWith => __$RadioReportCopyWithImpl<_RadioReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadioReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadioReport&&(identical(other.id, id) || other.id == id)&&(identical(other.messageKind, messageKind) || other.messageKind == messageKind)&&(identical(other.conversationTitle, conversationTitle) || other.conversationTitle == conversationTitle)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,messageKind,conversationTitle,reason,createdAt);

@override
String toString() {
  return 'RadioReport(id: $id, messageKind: $messageKind, conversationTitle: $conversationTitle, reason: $reason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RadioReportCopyWith<$Res> implements $RadioReportCopyWith<$Res> {
  factory _$RadioReportCopyWith(_RadioReport value, $Res Function(_RadioReport) _then) = __$RadioReportCopyWithImpl;
@override @useResult
$Res call({
 String id, String messageKind, String conversationTitle, String reason, DateTime createdAt
});




}
/// @nodoc
class __$RadioReportCopyWithImpl<$Res>
    implements _$RadioReportCopyWith<$Res> {
  __$RadioReportCopyWithImpl(this._self, this._then);

  final _RadioReport _self;
  final $Res Function(_RadioReport) _then;

/// Create a copy of RadioReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? messageKind = null,Object? conversationTitle = null,Object? reason = null,Object? createdAt = null,}) {
  return _then(_RadioReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,messageKind: null == messageKind ? _self.messageKind : messageKind // ignore: cast_nullable_to_non_nullable
as String,conversationTitle: null == conversationTitle ? _self.conversationTitle : conversationTitle // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
