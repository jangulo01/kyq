// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cooperative_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CooperativeRef {

 String get id; String get name;
/// Create a copy of CooperativeRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CooperativeRefCopyWith<CooperativeRef> get copyWith => _$CooperativeRefCopyWithImpl<CooperativeRef>(this as CooperativeRef, _$identity);

  /// Serializes this CooperativeRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CooperativeRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'CooperativeRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $CooperativeRefCopyWith<$Res>  {
  factory $CooperativeRefCopyWith(CooperativeRef value, $Res Function(CooperativeRef) _then) = _$CooperativeRefCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$CooperativeRefCopyWithImpl<$Res>
    implements $CooperativeRefCopyWith<$Res> {
  _$CooperativeRefCopyWithImpl(this._self, this._then);

  final CooperativeRef _self;
  final $Res Function(CooperativeRef) _then;

/// Create a copy of CooperativeRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CooperativeRef].
extension CooperativeRefPatterns on CooperativeRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CooperativeRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CooperativeRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CooperativeRef value)  $default,){
final _that = this;
switch (_that) {
case _CooperativeRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CooperativeRef value)?  $default,){
final _that = this;
switch (_that) {
case _CooperativeRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CooperativeRef() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name)  $default,) {final _that = this;
switch (_that) {
case _CooperativeRef():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _CooperativeRef() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CooperativeRef implements CooperativeRef {
  const _CooperativeRef({required this.id, required this.name});
  factory _CooperativeRef.fromJson(Map<String, dynamic> json) => _$CooperativeRefFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of CooperativeRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CooperativeRefCopyWith<_CooperativeRef> get copyWith => __$CooperativeRefCopyWithImpl<_CooperativeRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CooperativeRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CooperativeRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'CooperativeRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$CooperativeRefCopyWith<$Res> implements $CooperativeRefCopyWith<$Res> {
  factory _$CooperativeRefCopyWith(_CooperativeRef value, $Res Function(_CooperativeRef) _then) = __$CooperativeRefCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$CooperativeRefCopyWithImpl<$Res>
    implements _$CooperativeRefCopyWith<$Res> {
  __$CooperativeRefCopyWithImpl(this._self, this._then);

  final _CooperativeRef _self;
  final $Res Function(_CooperativeRef) _then;

/// Create a copy of CooperativeRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_CooperativeRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Cooperative {

 String get id; String get name; String get cityCode; String? get nit; CooperativeStatus get status; int get membersCount; int get pendingCount; DateTime? get createdAt;
/// Create a copy of Cooperative
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CooperativeCopyWith<Cooperative> get copyWith => _$CooperativeCopyWithImpl<Cooperative>(this as Cooperative, _$identity);

  /// Serializes this Cooperative to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Cooperative&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.cityCode, cityCode) || other.cityCode == cityCode)&&(identical(other.nit, nit) || other.nit == nit)&&(identical(other.status, status) || other.status == status)&&(identical(other.membersCount, membersCount) || other.membersCount == membersCount)&&(identical(other.pendingCount, pendingCount) || other.pendingCount == pendingCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,cityCode,nit,status,membersCount,pendingCount,createdAt);

@override
String toString() {
  return 'Cooperative(id: $id, name: $name, cityCode: $cityCode, nit: $nit, status: $status, membersCount: $membersCount, pendingCount: $pendingCount, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CooperativeCopyWith<$Res>  {
  factory $CooperativeCopyWith(Cooperative value, $Res Function(Cooperative) _then) = _$CooperativeCopyWithImpl;
@useResult
$Res call({
 String id, String name, String cityCode, String? nit, CooperativeStatus status, int membersCount, int pendingCount, DateTime? createdAt
});




}
/// @nodoc
class _$CooperativeCopyWithImpl<$Res>
    implements $CooperativeCopyWith<$Res> {
  _$CooperativeCopyWithImpl(this._self, this._then);

  final Cooperative _self;
  final $Res Function(Cooperative) _then;

/// Create a copy of Cooperative
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? cityCode = null,Object? nit = freezed,Object? status = null,Object? membersCount = null,Object? pendingCount = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cityCode: null == cityCode ? _self.cityCode : cityCode // ignore: cast_nullable_to_non_nullable
as String,nit: freezed == nit ? _self.nit : nit // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CooperativeStatus,membersCount: null == membersCount ? _self.membersCount : membersCount // ignore: cast_nullable_to_non_nullable
as int,pendingCount: null == pendingCount ? _self.pendingCount : pendingCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Cooperative].
extension CooperativePatterns on Cooperative {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Cooperative value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Cooperative() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Cooperative value)  $default,){
final _that = this;
switch (_that) {
case _Cooperative():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Cooperative value)?  $default,){
final _that = this;
switch (_that) {
case _Cooperative() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String cityCode,  String? nit,  CooperativeStatus status,  int membersCount,  int pendingCount,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Cooperative() when $default != null:
return $default(_that.id,_that.name,_that.cityCode,_that.nit,_that.status,_that.membersCount,_that.pendingCount,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String cityCode,  String? nit,  CooperativeStatus status,  int membersCount,  int pendingCount,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Cooperative():
return $default(_that.id,_that.name,_that.cityCode,_that.nit,_that.status,_that.membersCount,_that.pendingCount,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String cityCode,  String? nit,  CooperativeStatus status,  int membersCount,  int pendingCount,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Cooperative() when $default != null:
return $default(_that.id,_that.name,_that.cityCode,_that.nit,_that.status,_that.membersCount,_that.pendingCount,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Cooperative implements Cooperative {
  const _Cooperative({required this.id, required this.name, required this.cityCode, this.nit, required this.status, this.membersCount = 0, this.pendingCount = 0, this.createdAt});
  factory _Cooperative.fromJson(Map<String, dynamic> json) => _$CooperativeFromJson(json);

@override final  String id;
@override final  String name;
@override final  String cityCode;
@override final  String? nit;
@override final  CooperativeStatus status;
@override@JsonKey() final  int membersCount;
@override@JsonKey() final  int pendingCount;
@override final  DateTime? createdAt;

/// Create a copy of Cooperative
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CooperativeCopyWith<_Cooperative> get copyWith => __$CooperativeCopyWithImpl<_Cooperative>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CooperativeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Cooperative&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.cityCode, cityCode) || other.cityCode == cityCode)&&(identical(other.nit, nit) || other.nit == nit)&&(identical(other.status, status) || other.status == status)&&(identical(other.membersCount, membersCount) || other.membersCount == membersCount)&&(identical(other.pendingCount, pendingCount) || other.pendingCount == pendingCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,cityCode,nit,status,membersCount,pendingCount,createdAt);

@override
String toString() {
  return 'Cooperative(id: $id, name: $name, cityCode: $cityCode, nit: $nit, status: $status, membersCount: $membersCount, pendingCount: $pendingCount, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CooperativeCopyWith<$Res> implements $CooperativeCopyWith<$Res> {
  factory _$CooperativeCopyWith(_Cooperative value, $Res Function(_Cooperative) _then) = __$CooperativeCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String cityCode, String? nit, CooperativeStatus status, int membersCount, int pendingCount, DateTime? createdAt
});




}
/// @nodoc
class __$CooperativeCopyWithImpl<$Res>
    implements _$CooperativeCopyWith<$Res> {
  __$CooperativeCopyWithImpl(this._self, this._then);

  final _Cooperative _self;
  final $Res Function(_Cooperative) _then;

/// Create a copy of Cooperative
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? cityCode = null,Object? nit = freezed,Object? status = null,Object? membersCount = null,Object? pendingCount = null,Object? createdAt = freezed,}) {
  return _then(_Cooperative(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cityCode: null == cityCode ? _self.cityCode : cityCode // ignore: cast_nullable_to_non_nullable
as String,nit: freezed == nit ? _self.nit : nit // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CooperativeStatus,membersCount: null == membersCount ? _self.membersCount : membersCount // ignore: cast_nullable_to_non_nullable
as int,pendingCount: null == pendingCount ? _self.pendingCount : pendingCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CooperativeMember {

 String get membershipId; String get driverId; String get displayName; String get vehiclePlate; CooperativeRole get role; String get presence; DateTime? get since;
/// Create a copy of CooperativeMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CooperativeMemberCopyWith<CooperativeMember> get copyWith => _$CooperativeMemberCopyWithImpl<CooperativeMember>(this as CooperativeMember, _$identity);

  /// Serializes this CooperativeMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CooperativeMember&&(identical(other.membershipId, membershipId) || other.membershipId == membershipId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.role, role) || other.role == role)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.since, since) || other.since == since));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,membershipId,driverId,displayName,vehiclePlate,role,presence,since);

@override
String toString() {
  return 'CooperativeMember(membershipId: $membershipId, driverId: $driverId, displayName: $displayName, vehiclePlate: $vehiclePlate, role: $role, presence: $presence, since: $since)';
}


}

/// @nodoc
abstract mixin class $CooperativeMemberCopyWith<$Res>  {
  factory $CooperativeMemberCopyWith(CooperativeMember value, $Res Function(CooperativeMember) _then) = _$CooperativeMemberCopyWithImpl;
@useResult
$Res call({
 String membershipId, String driverId, String displayName, String vehiclePlate, CooperativeRole role, String presence, DateTime? since
});




}
/// @nodoc
class _$CooperativeMemberCopyWithImpl<$Res>
    implements $CooperativeMemberCopyWith<$Res> {
  _$CooperativeMemberCopyWithImpl(this._self, this._then);

  final CooperativeMember _self;
  final $Res Function(CooperativeMember) _then;

/// Create a copy of CooperativeMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? membershipId = null,Object? driverId = null,Object? displayName = null,Object? vehiclePlate = null,Object? role = null,Object? presence = null,Object? since = freezed,}) {
  return _then(_self.copyWith(
membershipId: null == membershipId ? _self.membershipId : membershipId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as CooperativeRole,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as String,since: freezed == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CooperativeMember].
extension CooperativeMemberPatterns on CooperativeMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CooperativeMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CooperativeMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CooperativeMember value)  $default,){
final _that = this;
switch (_that) {
case _CooperativeMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CooperativeMember value)?  $default,){
final _that = this;
switch (_that) {
case _CooperativeMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String membershipId,  String driverId,  String displayName,  String vehiclePlate,  CooperativeRole role,  String presence,  DateTime? since)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CooperativeMember() when $default != null:
return $default(_that.membershipId,_that.driverId,_that.displayName,_that.vehiclePlate,_that.role,_that.presence,_that.since);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String membershipId,  String driverId,  String displayName,  String vehiclePlate,  CooperativeRole role,  String presence,  DateTime? since)  $default,) {final _that = this;
switch (_that) {
case _CooperativeMember():
return $default(_that.membershipId,_that.driverId,_that.displayName,_that.vehiclePlate,_that.role,_that.presence,_that.since);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String membershipId,  String driverId,  String displayName,  String vehiclePlate,  CooperativeRole role,  String presence,  DateTime? since)?  $default,) {final _that = this;
switch (_that) {
case _CooperativeMember() when $default != null:
return $default(_that.membershipId,_that.driverId,_that.displayName,_that.vehiclePlate,_that.role,_that.presence,_that.since);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CooperativeMember implements CooperativeMember {
  const _CooperativeMember({required this.membershipId, required this.driverId, required this.displayName, required this.vehiclePlate, required this.role, this.presence = DriverPresenceName.offline, this.since});
  factory _CooperativeMember.fromJson(Map<String, dynamic> json) => _$CooperativeMemberFromJson(json);

@override final  String membershipId;
@override final  String driverId;
@override final  String displayName;
@override final  String vehiclePlate;
@override final  CooperativeRole role;
@override@JsonKey() final  String presence;
@override final  DateTime? since;

/// Create a copy of CooperativeMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CooperativeMemberCopyWith<_CooperativeMember> get copyWith => __$CooperativeMemberCopyWithImpl<_CooperativeMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CooperativeMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CooperativeMember&&(identical(other.membershipId, membershipId) || other.membershipId == membershipId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.role, role) || other.role == role)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.since, since) || other.since == since));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,membershipId,driverId,displayName,vehiclePlate,role,presence,since);

@override
String toString() {
  return 'CooperativeMember(membershipId: $membershipId, driverId: $driverId, displayName: $displayName, vehiclePlate: $vehiclePlate, role: $role, presence: $presence, since: $since)';
}


}

/// @nodoc
abstract mixin class _$CooperativeMemberCopyWith<$Res> implements $CooperativeMemberCopyWith<$Res> {
  factory _$CooperativeMemberCopyWith(_CooperativeMember value, $Res Function(_CooperativeMember) _then) = __$CooperativeMemberCopyWithImpl;
@override @useResult
$Res call({
 String membershipId, String driverId, String displayName, String vehiclePlate, CooperativeRole role, String presence, DateTime? since
});




}
/// @nodoc
class __$CooperativeMemberCopyWithImpl<$Res>
    implements _$CooperativeMemberCopyWith<$Res> {
  __$CooperativeMemberCopyWithImpl(this._self, this._then);

  final _CooperativeMember _self;
  final $Res Function(_CooperativeMember) _then;

/// Create a copy of CooperativeMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? membershipId = null,Object? driverId = null,Object? displayName = null,Object? vehiclePlate = null,Object? role = null,Object? presence = null,Object? since = freezed,}) {
  return _then(_CooperativeMember(
membershipId: null == membershipId ? _self.membershipId : membershipId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as CooperativeRole,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as String,since: freezed == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$MembershipRequest {

 String get membershipId; String get driverId; String get displayName; String get vehiclePlate; DateTime get requestedAt;
/// Create a copy of MembershipRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipRequestCopyWith<MembershipRequest> get copyWith => _$MembershipRequestCopyWithImpl<MembershipRequest>(this as MembershipRequest, _$identity);

  /// Serializes this MembershipRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipRequest&&(identical(other.membershipId, membershipId) || other.membershipId == membershipId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,membershipId,driverId,displayName,vehiclePlate,requestedAt);

@override
String toString() {
  return 'MembershipRequest(membershipId: $membershipId, driverId: $driverId, displayName: $displayName, vehiclePlate: $vehiclePlate, requestedAt: $requestedAt)';
}


}

/// @nodoc
abstract mixin class $MembershipRequestCopyWith<$Res>  {
  factory $MembershipRequestCopyWith(MembershipRequest value, $Res Function(MembershipRequest) _then) = _$MembershipRequestCopyWithImpl;
@useResult
$Res call({
 String membershipId, String driverId, String displayName, String vehiclePlate, DateTime requestedAt
});




}
/// @nodoc
class _$MembershipRequestCopyWithImpl<$Res>
    implements $MembershipRequestCopyWith<$Res> {
  _$MembershipRequestCopyWithImpl(this._self, this._then);

  final MembershipRequest _self;
  final $Res Function(MembershipRequest) _then;

/// Create a copy of MembershipRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? membershipId = null,Object? driverId = null,Object? displayName = null,Object? vehiclePlate = null,Object? requestedAt = null,}) {
  return _then(_self.copyWith(
membershipId: null == membershipId ? _self.membershipId : membershipId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MembershipRequest].
extension MembershipRequestPatterns on MembershipRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MembershipRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MembershipRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MembershipRequest value)  $default,){
final _that = this;
switch (_that) {
case _MembershipRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MembershipRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MembershipRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String membershipId,  String driverId,  String displayName,  String vehiclePlate,  DateTime requestedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MembershipRequest() when $default != null:
return $default(_that.membershipId,_that.driverId,_that.displayName,_that.vehiclePlate,_that.requestedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String membershipId,  String driverId,  String displayName,  String vehiclePlate,  DateTime requestedAt)  $default,) {final _that = this;
switch (_that) {
case _MembershipRequest():
return $default(_that.membershipId,_that.driverId,_that.displayName,_that.vehiclePlate,_that.requestedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String membershipId,  String driverId,  String displayName,  String vehiclePlate,  DateTime requestedAt)?  $default,) {final _that = this;
switch (_that) {
case _MembershipRequest() when $default != null:
return $default(_that.membershipId,_that.driverId,_that.displayName,_that.vehiclePlate,_that.requestedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MembershipRequest implements MembershipRequest {
  const _MembershipRequest({required this.membershipId, required this.driverId, required this.displayName, required this.vehiclePlate, required this.requestedAt});
  factory _MembershipRequest.fromJson(Map<String, dynamic> json) => _$MembershipRequestFromJson(json);

@override final  String membershipId;
@override final  String driverId;
@override final  String displayName;
@override final  String vehiclePlate;
@override final  DateTime requestedAt;

/// Create a copy of MembershipRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipRequestCopyWith<_MembershipRequest> get copyWith => __$MembershipRequestCopyWithImpl<_MembershipRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembershipRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MembershipRequest&&(identical(other.membershipId, membershipId) || other.membershipId == membershipId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,membershipId,driverId,displayName,vehiclePlate,requestedAt);

@override
String toString() {
  return 'MembershipRequest(membershipId: $membershipId, driverId: $driverId, displayName: $displayName, vehiclePlate: $vehiclePlate, requestedAt: $requestedAt)';
}


}

/// @nodoc
abstract mixin class _$MembershipRequestCopyWith<$Res> implements $MembershipRequestCopyWith<$Res> {
  factory _$MembershipRequestCopyWith(_MembershipRequest value, $Res Function(_MembershipRequest) _then) = __$MembershipRequestCopyWithImpl;
@override @useResult
$Res call({
 String membershipId, String driverId, String displayName, String vehiclePlate, DateTime requestedAt
});




}
/// @nodoc
class __$MembershipRequestCopyWithImpl<$Res>
    implements _$MembershipRequestCopyWith<$Res> {
  __$MembershipRequestCopyWithImpl(this._self, this._then);

  final _MembershipRequest _self;
  final $Res Function(_MembershipRequest) _then;

/// Create a copy of MembershipRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? membershipId = null,Object? driverId = null,Object? displayName = null,Object? vehiclePlate = null,Object? requestedAt = null,}) {
  return _then(_MembershipRequest(
membershipId: null == membershipId ? _self.membershipId : membershipId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$Membership {

 String get id; CooperativeRef get cooperative; CooperativeStatus get cooperativeStatus; CooperativeRole get role; MembershipStatus get status; String? get rejectReason; DateTime? get requestedAt; DateTime? get decidedAt;
/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipCopyWith<Membership> get copyWith => _$MembershipCopyWithImpl<Membership>(this as Membership, _$identity);

  /// Serializes this Membership to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Membership&&(identical(other.id, id) || other.id == id)&&(identical(other.cooperative, cooperative) || other.cooperative == cooperative)&&(identical(other.cooperativeStatus, cooperativeStatus) || other.cooperativeStatus == cooperativeStatus)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectReason, rejectReason) || other.rejectReason == rejectReason)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cooperative,cooperativeStatus,role,status,rejectReason,requestedAt,decidedAt);

@override
String toString() {
  return 'Membership(id: $id, cooperative: $cooperative, cooperativeStatus: $cooperativeStatus, role: $role, status: $status, rejectReason: $rejectReason, requestedAt: $requestedAt, decidedAt: $decidedAt)';
}


}

/// @nodoc
abstract mixin class $MembershipCopyWith<$Res>  {
  factory $MembershipCopyWith(Membership value, $Res Function(Membership) _then) = _$MembershipCopyWithImpl;
@useResult
$Res call({
 String id, CooperativeRef cooperative, CooperativeStatus cooperativeStatus, CooperativeRole role, MembershipStatus status, String? rejectReason, DateTime? requestedAt, DateTime? decidedAt
});


$CooperativeRefCopyWith<$Res> get cooperative;

}
/// @nodoc
class _$MembershipCopyWithImpl<$Res>
    implements $MembershipCopyWith<$Res> {
  _$MembershipCopyWithImpl(this._self, this._then);

  final Membership _self;
  final $Res Function(Membership) _then;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? cooperative = null,Object? cooperativeStatus = null,Object? role = null,Object? status = null,Object? rejectReason = freezed,Object? requestedAt = freezed,Object? decidedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cooperative: null == cooperative ? _self.cooperative : cooperative // ignore: cast_nullable_to_non_nullable
as CooperativeRef,cooperativeStatus: null == cooperativeStatus ? _self.cooperativeStatus : cooperativeStatus // ignore: cast_nullable_to_non_nullable
as CooperativeStatus,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as CooperativeRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MembershipStatus,rejectReason: freezed == rejectReason ? _self.rejectReason : rejectReason // ignore: cast_nullable_to_non_nullable
as String?,requestedAt: freezed == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CooperativeRefCopyWith<$Res> get cooperative {
  
  return $CooperativeRefCopyWith<$Res>(_self.cooperative, (value) {
    return _then(_self.copyWith(cooperative: value));
  });
}
}


/// Adds pattern-matching-related methods to [Membership].
extension MembershipPatterns on Membership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Membership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Membership() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Membership value)  $default,){
final _that = this;
switch (_that) {
case _Membership():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Membership value)?  $default,){
final _that = this;
switch (_that) {
case _Membership() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  CooperativeRef cooperative,  CooperativeStatus cooperativeStatus,  CooperativeRole role,  MembershipStatus status,  String? rejectReason,  DateTime? requestedAt,  DateTime? decidedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.id,_that.cooperative,_that.cooperativeStatus,_that.role,_that.status,_that.rejectReason,_that.requestedAt,_that.decidedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  CooperativeRef cooperative,  CooperativeStatus cooperativeStatus,  CooperativeRole role,  MembershipStatus status,  String? rejectReason,  DateTime? requestedAt,  DateTime? decidedAt)  $default,) {final _that = this;
switch (_that) {
case _Membership():
return $default(_that.id,_that.cooperative,_that.cooperativeStatus,_that.role,_that.status,_that.rejectReason,_that.requestedAt,_that.decidedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  CooperativeRef cooperative,  CooperativeStatus cooperativeStatus,  CooperativeRole role,  MembershipStatus status,  String? rejectReason,  DateTime? requestedAt,  DateTime? decidedAt)?  $default,) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.id,_that.cooperative,_that.cooperativeStatus,_that.role,_that.status,_that.rejectReason,_that.requestedAt,_that.decidedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Membership implements Membership {
  const _Membership({required this.id, required this.cooperative, this.cooperativeStatus = CooperativeStatus.active, required this.role, required this.status, this.rejectReason, this.requestedAt, this.decidedAt});
  factory _Membership.fromJson(Map<String, dynamic> json) => _$MembershipFromJson(json);

@override final  String id;
@override final  CooperativeRef cooperative;
@override@JsonKey() final  CooperativeStatus cooperativeStatus;
@override final  CooperativeRole role;
@override final  MembershipStatus status;
@override final  String? rejectReason;
@override final  DateTime? requestedAt;
@override final  DateTime? decidedAt;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipCopyWith<_Membership> get copyWith => __$MembershipCopyWithImpl<_Membership>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembershipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Membership&&(identical(other.id, id) || other.id == id)&&(identical(other.cooperative, cooperative) || other.cooperative == cooperative)&&(identical(other.cooperativeStatus, cooperativeStatus) || other.cooperativeStatus == cooperativeStatus)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectReason, rejectReason) || other.rejectReason == rejectReason)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,cooperative,cooperativeStatus,role,status,rejectReason,requestedAt,decidedAt);

@override
String toString() {
  return 'Membership(id: $id, cooperative: $cooperative, cooperativeStatus: $cooperativeStatus, role: $role, status: $status, rejectReason: $rejectReason, requestedAt: $requestedAt, decidedAt: $decidedAt)';
}


}

/// @nodoc
abstract mixin class _$MembershipCopyWith<$Res> implements $MembershipCopyWith<$Res> {
  factory _$MembershipCopyWith(_Membership value, $Res Function(_Membership) _then) = __$MembershipCopyWithImpl;
@override @useResult
$Res call({
 String id, CooperativeRef cooperative, CooperativeStatus cooperativeStatus, CooperativeRole role, MembershipStatus status, String? rejectReason, DateTime? requestedAt, DateTime? decidedAt
});


@override $CooperativeRefCopyWith<$Res> get cooperative;

}
/// @nodoc
class __$MembershipCopyWithImpl<$Res>
    implements _$MembershipCopyWith<$Res> {
  __$MembershipCopyWithImpl(this._self, this._then);

  final _Membership _self;
  final $Res Function(_Membership) _then;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? cooperative = null,Object? cooperativeStatus = null,Object? role = null,Object? status = null,Object? rejectReason = freezed,Object? requestedAt = freezed,Object? decidedAt = freezed,}) {
  return _then(_Membership(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,cooperative: null == cooperative ? _self.cooperative : cooperative // ignore: cast_nullable_to_non_nullable
as CooperativeRef,cooperativeStatus: null == cooperativeStatus ? _self.cooperativeStatus : cooperativeStatus // ignore: cast_nullable_to_non_nullable
as CooperativeStatus,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as CooperativeRole,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MembershipStatus,rejectReason: freezed == rejectReason ? _self.rejectReason : rejectReason // ignore: cast_nullable_to_non_nullable
as String?,requestedAt: freezed == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CooperativeRefCopyWith<$Res> get cooperative {
  
  return $CooperativeRefCopyWith<$Res>(_self.cooperative, (value) {
    return _then(_self.copyWith(cooperative: value));
  });
}
}


/// @nodoc
mixin _$CooperativeDetail {

 Cooperative get cooperative; List<CooperativeMember> get members; List<MembershipRequest> get requests;
/// Create a copy of CooperativeDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CooperativeDetailCopyWith<CooperativeDetail> get copyWith => _$CooperativeDetailCopyWithImpl<CooperativeDetail>(this as CooperativeDetail, _$identity);

  /// Serializes this CooperativeDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CooperativeDetail&&(identical(other.cooperative, cooperative) || other.cooperative == cooperative)&&const DeepCollectionEquality().equals(other.members, members)&&const DeepCollectionEquality().equals(other.requests, requests));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cooperative,const DeepCollectionEquality().hash(members),const DeepCollectionEquality().hash(requests));

@override
String toString() {
  return 'CooperativeDetail(cooperative: $cooperative, members: $members, requests: $requests)';
}


}

/// @nodoc
abstract mixin class $CooperativeDetailCopyWith<$Res>  {
  factory $CooperativeDetailCopyWith(CooperativeDetail value, $Res Function(CooperativeDetail) _then) = _$CooperativeDetailCopyWithImpl;
@useResult
$Res call({
 Cooperative cooperative, List<CooperativeMember> members, List<MembershipRequest> requests
});


$CooperativeCopyWith<$Res> get cooperative;

}
/// @nodoc
class _$CooperativeDetailCopyWithImpl<$Res>
    implements $CooperativeDetailCopyWith<$Res> {
  _$CooperativeDetailCopyWithImpl(this._self, this._then);

  final CooperativeDetail _self;
  final $Res Function(CooperativeDetail) _then;

/// Create a copy of CooperativeDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cooperative = null,Object? members = null,Object? requests = null,}) {
  return _then(_self.copyWith(
cooperative: null == cooperative ? _self.cooperative : cooperative // ignore: cast_nullable_to_non_nullable
as Cooperative,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<CooperativeMember>,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as List<MembershipRequest>,
  ));
}
/// Create a copy of CooperativeDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CooperativeCopyWith<$Res> get cooperative {
  
  return $CooperativeCopyWith<$Res>(_self.cooperative, (value) {
    return _then(_self.copyWith(cooperative: value));
  });
}
}


/// Adds pattern-matching-related methods to [CooperativeDetail].
extension CooperativeDetailPatterns on CooperativeDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CooperativeDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CooperativeDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CooperativeDetail value)  $default,){
final _that = this;
switch (_that) {
case _CooperativeDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CooperativeDetail value)?  $default,){
final _that = this;
switch (_that) {
case _CooperativeDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Cooperative cooperative,  List<CooperativeMember> members,  List<MembershipRequest> requests)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CooperativeDetail() when $default != null:
return $default(_that.cooperative,_that.members,_that.requests);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Cooperative cooperative,  List<CooperativeMember> members,  List<MembershipRequest> requests)  $default,) {final _that = this;
switch (_that) {
case _CooperativeDetail():
return $default(_that.cooperative,_that.members,_that.requests);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Cooperative cooperative,  List<CooperativeMember> members,  List<MembershipRequest> requests)?  $default,) {final _that = this;
switch (_that) {
case _CooperativeDetail() when $default != null:
return $default(_that.cooperative,_that.members,_that.requests);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CooperativeDetail implements CooperativeDetail {
  const _CooperativeDetail({required this.cooperative, final  List<CooperativeMember> members = const <CooperativeMember>[], final  List<MembershipRequest> requests = const <MembershipRequest>[]}): _members = members,_requests = requests;
  factory _CooperativeDetail.fromJson(Map<String, dynamic> json) => _$CooperativeDetailFromJson(json);

@override final  Cooperative cooperative;
 final  List<CooperativeMember> _members;
@override@JsonKey() List<CooperativeMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

 final  List<MembershipRequest> _requests;
@override@JsonKey() List<MembershipRequest> get requests {
  if (_requests is EqualUnmodifiableListView) return _requests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requests);
}


/// Create a copy of CooperativeDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CooperativeDetailCopyWith<_CooperativeDetail> get copyWith => __$CooperativeDetailCopyWithImpl<_CooperativeDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CooperativeDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CooperativeDetail&&(identical(other.cooperative, cooperative) || other.cooperative == cooperative)&&const DeepCollectionEquality().equals(other._members, _members)&&const DeepCollectionEquality().equals(other._requests, _requests));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cooperative,const DeepCollectionEquality().hash(_members),const DeepCollectionEquality().hash(_requests));

@override
String toString() {
  return 'CooperativeDetail(cooperative: $cooperative, members: $members, requests: $requests)';
}


}

/// @nodoc
abstract mixin class _$CooperativeDetailCopyWith<$Res> implements $CooperativeDetailCopyWith<$Res> {
  factory _$CooperativeDetailCopyWith(_CooperativeDetail value, $Res Function(_CooperativeDetail) _then) = __$CooperativeDetailCopyWithImpl;
@override @useResult
$Res call({
 Cooperative cooperative, List<CooperativeMember> members, List<MembershipRequest> requests
});


@override $CooperativeCopyWith<$Res> get cooperative;

}
/// @nodoc
class __$CooperativeDetailCopyWithImpl<$Res>
    implements _$CooperativeDetailCopyWith<$Res> {
  __$CooperativeDetailCopyWithImpl(this._self, this._then);

  final _CooperativeDetail _self;
  final $Res Function(_CooperativeDetail) _then;

/// Create a copy of CooperativeDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cooperative = null,Object? members = null,Object? requests = null,}) {
  return _then(_CooperativeDetail(
cooperative: null == cooperative ? _self.cooperative : cooperative // ignore: cast_nullable_to_non_nullable
as Cooperative,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<CooperativeMember>,requests: null == requests ? _self._requests : requests // ignore: cast_nullable_to_non_nullable
as List<MembershipRequest>,
  ));
}

/// Create a copy of CooperativeDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CooperativeCopyWith<$Res> get cooperative {
  
  return $CooperativeCopyWith<$Res>(_self.cooperative, (value) {
    return _then(_self.copyWith(cooperative: value));
  });
}
}


/// @nodoc
mixin _$DriverCooperative {

 Membership? get membership; List<CooperativeMember> get members; List<MembershipRequest> get requests;
/// Create a copy of DriverCooperative
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverCooperativeCopyWith<DriverCooperative> get copyWith => _$DriverCooperativeCopyWithImpl<DriverCooperative>(this as DriverCooperative, _$identity);

  /// Serializes this DriverCooperative to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverCooperative&&(identical(other.membership, membership) || other.membership == membership)&&const DeepCollectionEquality().equals(other.members, members)&&const DeepCollectionEquality().equals(other.requests, requests));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,membership,const DeepCollectionEquality().hash(members),const DeepCollectionEquality().hash(requests));

@override
String toString() {
  return 'DriverCooperative(membership: $membership, members: $members, requests: $requests)';
}


}

/// @nodoc
abstract mixin class $DriverCooperativeCopyWith<$Res>  {
  factory $DriverCooperativeCopyWith(DriverCooperative value, $Res Function(DriverCooperative) _then) = _$DriverCooperativeCopyWithImpl;
@useResult
$Res call({
 Membership? membership, List<CooperativeMember> members, List<MembershipRequest> requests
});


$MembershipCopyWith<$Res>? get membership;

}
/// @nodoc
class _$DriverCooperativeCopyWithImpl<$Res>
    implements $DriverCooperativeCopyWith<$Res> {
  _$DriverCooperativeCopyWithImpl(this._self, this._then);

  final DriverCooperative _self;
  final $Res Function(DriverCooperative) _then;

/// Create a copy of DriverCooperative
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? membership = freezed,Object? members = null,Object? requests = null,}) {
  return _then(_self.copyWith(
membership: freezed == membership ? _self.membership : membership // ignore: cast_nullable_to_non_nullable
as Membership?,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<CooperativeMember>,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as List<MembershipRequest>,
  ));
}
/// Create a copy of DriverCooperative
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MembershipCopyWith<$Res>? get membership {
    if (_self.membership == null) {
    return null;
  }

  return $MembershipCopyWith<$Res>(_self.membership!, (value) {
    return _then(_self.copyWith(membership: value));
  });
}
}


/// Adds pattern-matching-related methods to [DriverCooperative].
extension DriverCooperativePatterns on DriverCooperative {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverCooperative value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverCooperative() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverCooperative value)  $default,){
final _that = this;
switch (_that) {
case _DriverCooperative():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverCooperative value)?  $default,){
final _that = this;
switch (_that) {
case _DriverCooperative() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Membership? membership,  List<CooperativeMember> members,  List<MembershipRequest> requests)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverCooperative() when $default != null:
return $default(_that.membership,_that.members,_that.requests);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Membership? membership,  List<CooperativeMember> members,  List<MembershipRequest> requests)  $default,) {final _that = this;
switch (_that) {
case _DriverCooperative():
return $default(_that.membership,_that.members,_that.requests);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Membership? membership,  List<CooperativeMember> members,  List<MembershipRequest> requests)?  $default,) {final _that = this;
switch (_that) {
case _DriverCooperative() when $default != null:
return $default(_that.membership,_that.members,_that.requests);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverCooperative implements DriverCooperative {
  const _DriverCooperative({this.membership, final  List<CooperativeMember> members = const <CooperativeMember>[], final  List<MembershipRequest> requests = const <MembershipRequest>[]}): _members = members,_requests = requests;
  factory _DriverCooperative.fromJson(Map<String, dynamic> json) => _$DriverCooperativeFromJson(json);

@override final  Membership? membership;
 final  List<CooperativeMember> _members;
@override@JsonKey() List<CooperativeMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

 final  List<MembershipRequest> _requests;
@override@JsonKey() List<MembershipRequest> get requests {
  if (_requests is EqualUnmodifiableListView) return _requests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requests);
}


/// Create a copy of DriverCooperative
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverCooperativeCopyWith<_DriverCooperative> get copyWith => __$DriverCooperativeCopyWithImpl<_DriverCooperative>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverCooperativeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverCooperative&&(identical(other.membership, membership) || other.membership == membership)&&const DeepCollectionEquality().equals(other._members, _members)&&const DeepCollectionEquality().equals(other._requests, _requests));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,membership,const DeepCollectionEquality().hash(_members),const DeepCollectionEquality().hash(_requests));

@override
String toString() {
  return 'DriverCooperative(membership: $membership, members: $members, requests: $requests)';
}


}

/// @nodoc
abstract mixin class _$DriverCooperativeCopyWith<$Res> implements $DriverCooperativeCopyWith<$Res> {
  factory _$DriverCooperativeCopyWith(_DriverCooperative value, $Res Function(_DriverCooperative) _then) = __$DriverCooperativeCopyWithImpl;
@override @useResult
$Res call({
 Membership? membership, List<CooperativeMember> members, List<MembershipRequest> requests
});


@override $MembershipCopyWith<$Res>? get membership;

}
/// @nodoc
class __$DriverCooperativeCopyWithImpl<$Res>
    implements _$DriverCooperativeCopyWith<$Res> {
  __$DriverCooperativeCopyWithImpl(this._self, this._then);

  final _DriverCooperative _self;
  final $Res Function(_DriverCooperative) _then;

/// Create a copy of DriverCooperative
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? membership = freezed,Object? members = null,Object? requests = null,}) {
  return _then(_DriverCooperative(
membership: freezed == membership ? _self.membership : membership // ignore: cast_nullable_to_non_nullable
as Membership?,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<CooperativeMember>,requests: null == requests ? _self._requests : requests // ignore: cast_nullable_to_non_nullable
as List<MembershipRequest>,
  ));
}

/// Create a copy of DriverCooperative
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MembershipCopyWith<$Res>? get membership {
    if (_self.membership == null) {
    return null;
  }

  return $MembershipCopyWith<$Res>(_self.membership!, (value) {
    return _then(_self.copyWith(membership: value));
  });
}
}

// dart format on
