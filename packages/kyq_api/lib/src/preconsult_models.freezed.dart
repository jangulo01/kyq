// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preconsult_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Preconsult {

 String get id; String get passengerId; String get passengerName; String get driverId; String get driverName;@JsonKey(unknownEnumValue: PreconsultStatus.unknown) PreconsultStatus get status; DateTime get openedAt; DateTime get joinDeadline; DateTime get closesAt; DateTime? get joinedAt; DateTime? get answeredAt; DateTime? get closedAt;@JsonKey(unknownEnumValue: PreconsultCloseReason.unknown) PreconsultCloseReason? get closeReason;
/// Create a copy of Preconsult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreconsultCopyWith<Preconsult> get copyWith => _$PreconsultCopyWithImpl<Preconsult>(this as Preconsult, _$identity);

  /// Serializes this Preconsult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Preconsult&&(identical(other.id, id) || other.id == id)&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.passengerName, passengerName) || other.passengerName == passengerName)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.status, status) || other.status == status)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.joinDeadline, joinDeadline) || other.joinDeadline == joinDeadline)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.answeredAt, answeredAt) || other.answeredAt == answeredAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.closeReason, closeReason) || other.closeReason == closeReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,passengerId,passengerName,driverId,driverName,status,openedAt,joinDeadline,closesAt,joinedAt,answeredAt,closedAt,closeReason);

@override
String toString() {
  return 'Preconsult(id: $id, passengerId: $passengerId, passengerName: $passengerName, driverId: $driverId, driverName: $driverName, status: $status, openedAt: $openedAt, joinDeadline: $joinDeadline, closesAt: $closesAt, joinedAt: $joinedAt, answeredAt: $answeredAt, closedAt: $closedAt, closeReason: $closeReason)';
}


}

/// @nodoc
abstract mixin class $PreconsultCopyWith<$Res>  {
  factory $PreconsultCopyWith(Preconsult value, $Res Function(Preconsult) _then) = _$PreconsultCopyWithImpl;
@useResult
$Res call({
 String id, String passengerId, String passengerName, String driverId, String driverName,@JsonKey(unknownEnumValue: PreconsultStatus.unknown) PreconsultStatus status, DateTime openedAt, DateTime joinDeadline, DateTime closesAt, DateTime? joinedAt, DateTime? answeredAt, DateTime? closedAt,@JsonKey(unknownEnumValue: PreconsultCloseReason.unknown) PreconsultCloseReason? closeReason
});




}
/// @nodoc
class _$PreconsultCopyWithImpl<$Res>
    implements $PreconsultCopyWith<$Res> {
  _$PreconsultCopyWithImpl(this._self, this._then);

  final Preconsult _self;
  final $Res Function(Preconsult) _then;

/// Create a copy of Preconsult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? passengerId = null,Object? passengerName = null,Object? driverId = null,Object? driverName = null,Object? status = null,Object? openedAt = null,Object? joinDeadline = null,Object? closesAt = null,Object? joinedAt = freezed,Object? answeredAt = freezed,Object? closedAt = freezed,Object? closeReason = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,passengerId: null == passengerId ? _self.passengerId : passengerId // ignore: cast_nullable_to_non_nullable
as String,passengerName: null == passengerName ? _self.passengerName : passengerName // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PreconsultStatus,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as DateTime,joinDeadline: null == joinDeadline ? _self.joinDeadline : joinDeadline // ignore: cast_nullable_to_non_nullable
as DateTime,closesAt: null == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,answeredAt: freezed == answeredAt ? _self.answeredAt : answeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closeReason: freezed == closeReason ? _self.closeReason : closeReason // ignore: cast_nullable_to_non_nullable
as PreconsultCloseReason?,
  ));
}

}


/// Adds pattern-matching-related methods to [Preconsult].
extension PreconsultPatterns on Preconsult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Preconsult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Preconsult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Preconsult value)  $default,){
final _that = this;
switch (_that) {
case _Preconsult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Preconsult value)?  $default,){
final _that = this;
switch (_that) {
case _Preconsult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String passengerId,  String passengerName,  String driverId,  String driverName, @JsonKey(unknownEnumValue: PreconsultStatus.unknown)  PreconsultStatus status,  DateTime openedAt,  DateTime joinDeadline,  DateTime closesAt,  DateTime? joinedAt,  DateTime? answeredAt,  DateTime? closedAt, @JsonKey(unknownEnumValue: PreconsultCloseReason.unknown)  PreconsultCloseReason? closeReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Preconsult() when $default != null:
return $default(_that.id,_that.passengerId,_that.passengerName,_that.driverId,_that.driverName,_that.status,_that.openedAt,_that.joinDeadline,_that.closesAt,_that.joinedAt,_that.answeredAt,_that.closedAt,_that.closeReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String passengerId,  String passengerName,  String driverId,  String driverName, @JsonKey(unknownEnumValue: PreconsultStatus.unknown)  PreconsultStatus status,  DateTime openedAt,  DateTime joinDeadline,  DateTime closesAt,  DateTime? joinedAt,  DateTime? answeredAt,  DateTime? closedAt, @JsonKey(unknownEnumValue: PreconsultCloseReason.unknown)  PreconsultCloseReason? closeReason)  $default,) {final _that = this;
switch (_that) {
case _Preconsult():
return $default(_that.id,_that.passengerId,_that.passengerName,_that.driverId,_that.driverName,_that.status,_that.openedAt,_that.joinDeadline,_that.closesAt,_that.joinedAt,_that.answeredAt,_that.closedAt,_that.closeReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String passengerId,  String passengerName,  String driverId,  String driverName, @JsonKey(unknownEnumValue: PreconsultStatus.unknown)  PreconsultStatus status,  DateTime openedAt,  DateTime joinDeadline,  DateTime closesAt,  DateTime? joinedAt,  DateTime? answeredAt,  DateTime? closedAt, @JsonKey(unknownEnumValue: PreconsultCloseReason.unknown)  PreconsultCloseReason? closeReason)?  $default,) {final _that = this;
switch (_that) {
case _Preconsult() when $default != null:
return $default(_that.id,_that.passengerId,_that.passengerName,_that.driverId,_that.driverName,_that.status,_that.openedAt,_that.joinDeadline,_that.closesAt,_that.joinedAt,_that.answeredAt,_that.closedAt,_that.closeReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Preconsult extends Preconsult {
  const _Preconsult({required this.id, required this.passengerId, required this.passengerName, required this.driverId, required this.driverName, @JsonKey(unknownEnumValue: PreconsultStatus.unknown) required this.status, required this.openedAt, required this.joinDeadline, required this.closesAt, this.joinedAt, this.answeredAt, this.closedAt, @JsonKey(unknownEnumValue: PreconsultCloseReason.unknown) this.closeReason}): super._();
  factory _Preconsult.fromJson(Map<String, dynamic> json) => _$PreconsultFromJson(json);

@override final  String id;
@override final  String passengerId;
@override final  String passengerName;
@override final  String driverId;
@override final  String driverName;
@override@JsonKey(unknownEnumValue: PreconsultStatus.unknown) final  PreconsultStatus status;
@override final  DateTime openedAt;
@override final  DateTime joinDeadline;
@override final  DateTime closesAt;
@override final  DateTime? joinedAt;
@override final  DateTime? answeredAt;
@override final  DateTime? closedAt;
@override@JsonKey(unknownEnumValue: PreconsultCloseReason.unknown) final  PreconsultCloseReason? closeReason;

/// Create a copy of Preconsult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreconsultCopyWith<_Preconsult> get copyWith => __$PreconsultCopyWithImpl<_Preconsult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreconsultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Preconsult&&(identical(other.id, id) || other.id == id)&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.passengerName, passengerName) || other.passengerName == passengerName)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.status, status) || other.status == status)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&(identical(other.joinDeadline, joinDeadline) || other.joinDeadline == joinDeadline)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.answeredAt, answeredAt) || other.answeredAt == answeredAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.closeReason, closeReason) || other.closeReason == closeReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,passengerId,passengerName,driverId,driverName,status,openedAt,joinDeadline,closesAt,joinedAt,answeredAt,closedAt,closeReason);

@override
String toString() {
  return 'Preconsult(id: $id, passengerId: $passengerId, passengerName: $passengerName, driverId: $driverId, driverName: $driverName, status: $status, openedAt: $openedAt, joinDeadline: $joinDeadline, closesAt: $closesAt, joinedAt: $joinedAt, answeredAt: $answeredAt, closedAt: $closedAt, closeReason: $closeReason)';
}


}

/// @nodoc
abstract mixin class _$PreconsultCopyWith<$Res> implements $PreconsultCopyWith<$Res> {
  factory _$PreconsultCopyWith(_Preconsult value, $Res Function(_Preconsult) _then) = __$PreconsultCopyWithImpl;
@override @useResult
$Res call({
 String id, String passengerId, String passengerName, String driverId, String driverName,@JsonKey(unknownEnumValue: PreconsultStatus.unknown) PreconsultStatus status, DateTime openedAt, DateTime joinDeadline, DateTime closesAt, DateTime? joinedAt, DateTime? answeredAt, DateTime? closedAt,@JsonKey(unknownEnumValue: PreconsultCloseReason.unknown) PreconsultCloseReason? closeReason
});




}
/// @nodoc
class __$PreconsultCopyWithImpl<$Res>
    implements _$PreconsultCopyWith<$Res> {
  __$PreconsultCopyWithImpl(this._self, this._then);

  final _Preconsult _self;
  final $Res Function(_Preconsult) _then;

/// Create a copy of Preconsult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? passengerId = null,Object? passengerName = null,Object? driverId = null,Object? driverName = null,Object? status = null,Object? openedAt = null,Object? joinDeadline = null,Object? closesAt = null,Object? joinedAt = freezed,Object? answeredAt = freezed,Object? closedAt = freezed,Object? closeReason = freezed,}) {
  return _then(_Preconsult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,passengerId: null == passengerId ? _self.passengerId : passengerId // ignore: cast_nullable_to_non_nullable
as String,passengerName: null == passengerName ? _self.passengerName : passengerName // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PreconsultStatus,openedAt: null == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as DateTime,joinDeadline: null == joinDeadline ? _self.joinDeadline : joinDeadline // ignore: cast_nullable_to_non_nullable
as DateTime,closesAt: null == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,answeredAt: freezed == answeredAt ? _self.answeredAt : answeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closeReason: freezed == closeReason ? _self.closeReason : closeReason // ignore: cast_nullable_to_non_nullable
as PreconsultCloseReason?,
  ));
}


}


/// @nodoc
mixin _$PreconsultSettings {

 bool get acceptsPreconsults; List<String> get blockedPassengerIds;
/// Create a copy of PreconsultSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreconsultSettingsCopyWith<PreconsultSettings> get copyWith => _$PreconsultSettingsCopyWithImpl<PreconsultSettings>(this as PreconsultSettings, _$identity);

  /// Serializes this PreconsultSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreconsultSettings&&(identical(other.acceptsPreconsults, acceptsPreconsults) || other.acceptsPreconsults == acceptsPreconsults)&&const DeepCollectionEquality().equals(other.blockedPassengerIds, blockedPassengerIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,acceptsPreconsults,const DeepCollectionEquality().hash(blockedPassengerIds));

@override
String toString() {
  return 'PreconsultSettings(acceptsPreconsults: $acceptsPreconsults, blockedPassengerIds: $blockedPassengerIds)';
}


}

/// @nodoc
abstract mixin class $PreconsultSettingsCopyWith<$Res>  {
  factory $PreconsultSettingsCopyWith(PreconsultSettings value, $Res Function(PreconsultSettings) _then) = _$PreconsultSettingsCopyWithImpl;
@useResult
$Res call({
 bool acceptsPreconsults, List<String> blockedPassengerIds
});




}
/// @nodoc
class _$PreconsultSettingsCopyWithImpl<$Res>
    implements $PreconsultSettingsCopyWith<$Res> {
  _$PreconsultSettingsCopyWithImpl(this._self, this._then);

  final PreconsultSettings _self;
  final $Res Function(PreconsultSettings) _then;

/// Create a copy of PreconsultSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? acceptsPreconsults = null,Object? blockedPassengerIds = null,}) {
  return _then(_self.copyWith(
acceptsPreconsults: null == acceptsPreconsults ? _self.acceptsPreconsults : acceptsPreconsults // ignore: cast_nullable_to_non_nullable
as bool,blockedPassengerIds: null == blockedPassengerIds ? _self.blockedPassengerIds : blockedPassengerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PreconsultSettings].
extension PreconsultSettingsPatterns on PreconsultSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreconsultSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreconsultSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreconsultSettings value)  $default,){
final _that = this;
switch (_that) {
case _PreconsultSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreconsultSettings value)?  $default,){
final _that = this;
switch (_that) {
case _PreconsultSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool acceptsPreconsults,  List<String> blockedPassengerIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreconsultSettings() when $default != null:
return $default(_that.acceptsPreconsults,_that.blockedPassengerIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool acceptsPreconsults,  List<String> blockedPassengerIds)  $default,) {final _that = this;
switch (_that) {
case _PreconsultSettings():
return $default(_that.acceptsPreconsults,_that.blockedPassengerIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool acceptsPreconsults,  List<String> blockedPassengerIds)?  $default,) {final _that = this;
switch (_that) {
case _PreconsultSettings() when $default != null:
return $default(_that.acceptsPreconsults,_that.blockedPassengerIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreconsultSettings implements PreconsultSettings {
  const _PreconsultSettings({required this.acceptsPreconsults, final  List<String> blockedPassengerIds = const <String>[]}): _blockedPassengerIds = blockedPassengerIds;
  factory _PreconsultSettings.fromJson(Map<String, dynamic> json) => _$PreconsultSettingsFromJson(json);

@override final  bool acceptsPreconsults;
 final  List<String> _blockedPassengerIds;
@override@JsonKey() List<String> get blockedPassengerIds {
  if (_blockedPassengerIds is EqualUnmodifiableListView) return _blockedPassengerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blockedPassengerIds);
}


/// Create a copy of PreconsultSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreconsultSettingsCopyWith<_PreconsultSettings> get copyWith => __$PreconsultSettingsCopyWithImpl<_PreconsultSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreconsultSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreconsultSettings&&(identical(other.acceptsPreconsults, acceptsPreconsults) || other.acceptsPreconsults == acceptsPreconsults)&&const DeepCollectionEquality().equals(other._blockedPassengerIds, _blockedPassengerIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,acceptsPreconsults,const DeepCollectionEquality().hash(_blockedPassengerIds));

@override
String toString() {
  return 'PreconsultSettings(acceptsPreconsults: $acceptsPreconsults, blockedPassengerIds: $blockedPassengerIds)';
}


}

/// @nodoc
abstract mixin class _$PreconsultSettingsCopyWith<$Res> implements $PreconsultSettingsCopyWith<$Res> {
  factory _$PreconsultSettingsCopyWith(_PreconsultSettings value, $Res Function(_PreconsultSettings) _then) = __$PreconsultSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool acceptsPreconsults, List<String> blockedPassengerIds
});




}
/// @nodoc
class __$PreconsultSettingsCopyWithImpl<$Res>
    implements _$PreconsultSettingsCopyWith<$Res> {
  __$PreconsultSettingsCopyWithImpl(this._self, this._then);

  final _PreconsultSettings _self;
  final $Res Function(_PreconsultSettings) _then;

/// Create a copy of PreconsultSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? acceptsPreconsults = null,Object? blockedPassengerIds = null,}) {
  return _then(_PreconsultSettings(
acceptsPreconsults: null == acceptsPreconsults ? _self.acceptsPreconsults : acceptsPreconsults // ignore: cast_nullable_to_non_nullable
as bool,blockedPassengerIds: null == blockedPassengerIds ? _self._blockedPassengerIds : blockedPassengerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
