// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'safety_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SosPoint {

 double get lat; double get lng; double? get accuracyM; DateTime get recordedAt;
/// Create a copy of SosPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosPointCopyWith<SosPoint> get copyWith => _$SosPointCopyWithImpl<SosPoint>(this as SosPoint, _$identity);

  /// Serializes this SosPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.accuracyM, accuracyM) || other.accuracyM == accuracyM)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,accuracyM,recordedAt);

@override
String toString() {
  return 'SosPoint(lat: $lat, lng: $lng, accuracyM: $accuracyM, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class $SosPointCopyWith<$Res>  {
  factory $SosPointCopyWith(SosPoint value, $Res Function(SosPoint) _then) = _$SosPointCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, double? accuracyM, DateTime recordedAt
});




}
/// @nodoc
class _$SosPointCopyWithImpl<$Res>
    implements $SosPointCopyWith<$Res> {
  _$SosPointCopyWithImpl(this._self, this._then);

  final SosPoint _self;
  final $Res Function(SosPoint) _then;

/// Create a copy of SosPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? accuracyM = freezed,Object? recordedAt = null,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,accuracyM: freezed == accuracyM ? _self.accuracyM : accuracyM // ignore: cast_nullable_to_non_nullable
as double?,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SosPoint].
extension SosPointPatterns on SosPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosPoint value)  $default,){
final _that = this;
switch (_that) {
case _SosPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosPoint value)?  $default,){
final _that = this;
switch (_that) {
case _SosPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng,  double? accuracyM,  DateTime recordedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosPoint() when $default != null:
return $default(_that.lat,_that.lng,_that.accuracyM,_that.recordedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng,  double? accuracyM,  DateTime recordedAt)  $default,) {final _that = this;
switch (_that) {
case _SosPoint():
return $default(_that.lat,_that.lng,_that.accuracyM,_that.recordedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng,  double? accuracyM,  DateTime recordedAt)?  $default,) {final _that = this;
switch (_that) {
case _SosPoint() when $default != null:
return $default(_that.lat,_that.lng,_that.accuracyM,_that.recordedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SosPoint implements SosPoint {
  const _SosPoint({required this.lat, required this.lng, this.accuracyM, required this.recordedAt});
  factory _SosPoint.fromJson(Map<String, dynamic> json) => _$SosPointFromJson(json);

@override final  double lat;
@override final  double lng;
@override final  double? accuracyM;
@override final  DateTime recordedAt;

/// Create a copy of SosPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosPointCopyWith<_SosPoint> get copyWith => __$SosPointCopyWithImpl<_SosPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SosPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.accuracyM, accuracyM) || other.accuracyM == accuracyM)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,accuracyM,recordedAt);

@override
String toString() {
  return 'SosPoint(lat: $lat, lng: $lng, accuracyM: $accuracyM, recordedAt: $recordedAt)';
}


}

/// @nodoc
abstract mixin class _$SosPointCopyWith<$Res> implements $SosPointCopyWith<$Res> {
  factory _$SosPointCopyWith(_SosPoint value, $Res Function(_SosPoint) _then) = __$SosPointCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng, double? accuracyM, DateTime recordedAt
});




}
/// @nodoc
class __$SosPointCopyWithImpl<$Res>
    implements _$SosPointCopyWith<$Res> {
  __$SosPointCopyWithImpl(this._self, this._then);

  final _SosPoint _self;
  final $Res Function(_SosPoint) _then;

/// Create a copy of SosPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? accuracyM = freezed,Object? recordedAt = null,}) {
  return _then(_SosPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,accuracyM: freezed == accuracyM ? _self.accuracyM : accuracyM // ignore: cast_nullable_to_non_nullable
as double?,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SosLocation {

 double get lat; double get lng; double? get accuracyM; DateTime? get at;
/// Create a copy of SosLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosLocationCopyWith<SosLocation> get copyWith => _$SosLocationCopyWithImpl<SosLocation>(this as SosLocation, _$identity);

  /// Serializes this SosLocation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosLocation&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.accuracyM, accuracyM) || other.accuracyM == accuracyM)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,accuracyM,at);

@override
String toString() {
  return 'SosLocation(lat: $lat, lng: $lng, accuracyM: $accuracyM, at: $at)';
}


}

/// @nodoc
abstract mixin class $SosLocationCopyWith<$Res>  {
  factory $SosLocationCopyWith(SosLocation value, $Res Function(SosLocation) _then) = _$SosLocationCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, double? accuracyM, DateTime? at
});




}
/// @nodoc
class _$SosLocationCopyWithImpl<$Res>
    implements $SosLocationCopyWith<$Res> {
  _$SosLocationCopyWithImpl(this._self, this._then);

  final SosLocation _self;
  final $Res Function(SosLocation) _then;

/// Create a copy of SosLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? accuracyM = freezed,Object? at = freezed,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,accuracyM: freezed == accuracyM ? _self.accuracyM : accuracyM // ignore: cast_nullable_to_non_nullable
as double?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SosLocation].
extension SosLocationPatterns on SosLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosLocation value)  $default,){
final _that = this;
switch (_that) {
case _SosLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosLocation value)?  $default,){
final _that = this;
switch (_that) {
case _SosLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng,  double? accuracyM,  DateTime? at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosLocation() when $default != null:
return $default(_that.lat,_that.lng,_that.accuracyM,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng,  double? accuracyM,  DateTime? at)  $default,) {final _that = this;
switch (_that) {
case _SosLocation():
return $default(_that.lat,_that.lng,_that.accuracyM,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng,  double? accuracyM,  DateTime? at)?  $default,) {final _that = this;
switch (_that) {
case _SosLocation() when $default != null:
return $default(_that.lat,_that.lng,_that.accuracyM,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SosLocation implements SosLocation {
  const _SosLocation({required this.lat, required this.lng, this.accuracyM, this.at});
  factory _SosLocation.fromJson(Map<String, dynamic> json) => _$SosLocationFromJson(json);

@override final  double lat;
@override final  double lng;
@override final  double? accuracyM;
@override final  DateTime? at;

/// Create a copy of SosLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosLocationCopyWith<_SosLocation> get copyWith => __$SosLocationCopyWithImpl<_SosLocation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SosLocationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosLocation&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.accuracyM, accuracyM) || other.accuracyM == accuracyM)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,accuracyM,at);

@override
String toString() {
  return 'SosLocation(lat: $lat, lng: $lng, accuracyM: $accuracyM, at: $at)';
}


}

/// @nodoc
abstract mixin class _$SosLocationCopyWith<$Res> implements $SosLocationCopyWith<$Res> {
  factory _$SosLocationCopyWith(_SosLocation value, $Res Function(_SosLocation) _then) = __$SosLocationCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng, double? accuracyM, DateTime? at
});




}
/// @nodoc
class __$SosLocationCopyWithImpl<$Res>
    implements _$SosLocationCopyWith<$Res> {
  __$SosLocationCopyWithImpl(this._self, this._then);

  final _SosLocation _self;
  final $Res Function(_SosLocation) _then;

/// Create a copy of SosLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? accuracyM = freezed,Object? at = freezed,}) {
  return _then(_SosLocation(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,accuracyM: freezed == accuracyM ? _self.accuracyM : accuracyM // ignore: cast_nullable_to_non_nullable
as double?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$SosAlertSelf {

 String get id; String get tripId; SosStatus get status; bool get operatorConnected; bool get escalated; DateTime get createdAt;
/// Create a copy of SosAlertSelf
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosAlertSelfCopyWith<SosAlertSelf> get copyWith => _$SosAlertSelfCopyWithImpl<SosAlertSelf>(this as SosAlertSelf, _$identity);

  /// Serializes this SosAlertSelf to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosAlertSelf&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.status, status) || other.status == status)&&(identical(other.operatorConnected, operatorConnected) || other.operatorConnected == operatorConnected)&&(identical(other.escalated, escalated) || other.escalated == escalated)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,status,operatorConnected,escalated,createdAt);

@override
String toString() {
  return 'SosAlertSelf(id: $id, tripId: $tripId, status: $status, operatorConnected: $operatorConnected, escalated: $escalated, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SosAlertSelfCopyWith<$Res>  {
  factory $SosAlertSelfCopyWith(SosAlertSelf value, $Res Function(SosAlertSelf) _then) = _$SosAlertSelfCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, SosStatus status, bool operatorConnected, bool escalated, DateTime createdAt
});




}
/// @nodoc
class _$SosAlertSelfCopyWithImpl<$Res>
    implements $SosAlertSelfCopyWith<$Res> {
  _$SosAlertSelfCopyWithImpl(this._self, this._then);

  final SosAlertSelf _self;
  final $Res Function(SosAlertSelf) _then;

/// Create a copy of SosAlertSelf
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? status = null,Object? operatorConnected = null,Object? escalated = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SosStatus,operatorConnected: null == operatorConnected ? _self.operatorConnected : operatorConnected // ignore: cast_nullable_to_non_nullable
as bool,escalated: null == escalated ? _self.escalated : escalated // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SosAlertSelf].
extension SosAlertSelfPatterns on SosAlertSelf {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosAlertSelf value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosAlertSelf() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosAlertSelf value)  $default,){
final _that = this;
switch (_that) {
case _SosAlertSelf():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosAlertSelf value)?  $default,){
final _that = this;
switch (_that) {
case _SosAlertSelf() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  SosStatus status,  bool operatorConnected,  bool escalated,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosAlertSelf() when $default != null:
return $default(_that.id,_that.tripId,_that.status,_that.operatorConnected,_that.escalated,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  SosStatus status,  bool operatorConnected,  bool escalated,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _SosAlertSelf():
return $default(_that.id,_that.tripId,_that.status,_that.operatorConnected,_that.escalated,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  SosStatus status,  bool operatorConnected,  bool escalated,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SosAlertSelf() when $default != null:
return $default(_that.id,_that.tripId,_that.status,_that.operatorConnected,_that.escalated,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SosAlertSelf implements SosAlertSelf {
  const _SosAlertSelf({required this.id, required this.tripId, required this.status, this.operatorConnected = false, this.escalated = false, required this.createdAt});
  factory _SosAlertSelf.fromJson(Map<String, dynamic> json) => _$SosAlertSelfFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  SosStatus status;
@override@JsonKey() final  bool operatorConnected;
@override@JsonKey() final  bool escalated;
@override final  DateTime createdAt;

/// Create a copy of SosAlertSelf
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosAlertSelfCopyWith<_SosAlertSelf> get copyWith => __$SosAlertSelfCopyWithImpl<_SosAlertSelf>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SosAlertSelfToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosAlertSelf&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.status, status) || other.status == status)&&(identical(other.operatorConnected, operatorConnected) || other.operatorConnected == operatorConnected)&&(identical(other.escalated, escalated) || other.escalated == escalated)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,status,operatorConnected,escalated,createdAt);

@override
String toString() {
  return 'SosAlertSelf(id: $id, tripId: $tripId, status: $status, operatorConnected: $operatorConnected, escalated: $escalated, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SosAlertSelfCopyWith<$Res> implements $SosAlertSelfCopyWith<$Res> {
  factory _$SosAlertSelfCopyWith(_SosAlertSelf value, $Res Function(_SosAlertSelf) _then) = __$SosAlertSelfCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, SosStatus status, bool operatorConnected, bool escalated, DateTime createdAt
});




}
/// @nodoc
class __$SosAlertSelfCopyWithImpl<$Res>
    implements _$SosAlertSelfCopyWith<$Res> {
  __$SosAlertSelfCopyWithImpl(this._self, this._then);

  final _SosAlertSelf _self;
  final $Res Function(_SosAlertSelf) _then;

/// Create a copy of SosAlertSelf
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? status = null,Object? operatorConnected = null,Object? escalated = null,Object? createdAt = null,}) {
  return _then(_SosAlertSelf(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SosStatus,operatorConnected: null == operatorConnected ? _self.operatorConnected : operatorConnected // ignore: cast_nullable_to_non_nullable
as bool,escalated: null == escalated ? _self.escalated : escalated // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SosVoice {

 String get url; String get token; String get room; bool get canPublish;
/// Create a copy of SosVoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosVoiceCopyWith<SosVoice> get copyWith => _$SosVoiceCopyWithImpl<SosVoice>(this as SosVoice, _$identity);

  /// Serializes this SosVoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosVoice&&(identical(other.url, url) || other.url == url)&&(identical(other.token, token) || other.token == token)&&(identical(other.room, room) || other.room == room)&&(identical(other.canPublish, canPublish) || other.canPublish == canPublish));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,token,room,canPublish);

@override
String toString() {
  return 'SosVoice(url: $url, token: $token, room: $room, canPublish: $canPublish)';
}


}

/// @nodoc
abstract mixin class $SosVoiceCopyWith<$Res>  {
  factory $SosVoiceCopyWith(SosVoice value, $Res Function(SosVoice) _then) = _$SosVoiceCopyWithImpl;
@useResult
$Res call({
 String url, String token, String room, bool canPublish
});




}
/// @nodoc
class _$SosVoiceCopyWithImpl<$Res>
    implements $SosVoiceCopyWith<$Res> {
  _$SosVoiceCopyWithImpl(this._self, this._then);

  final SosVoice _self;
  final $Res Function(SosVoice) _then;

/// Create a copy of SosVoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? token = null,Object? room = null,Object? canPublish = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,canPublish: null == canPublish ? _self.canPublish : canPublish // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SosVoice].
extension SosVoicePatterns on SosVoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosVoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosVoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosVoice value)  $default,){
final _that = this;
switch (_that) {
case _SosVoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosVoice value)?  $default,){
final _that = this;
switch (_that) {
case _SosVoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String token,  String room,  bool canPublish)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosVoice() when $default != null:
return $default(_that.url,_that.token,_that.room,_that.canPublish);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String token,  String room,  bool canPublish)  $default,) {final _that = this;
switch (_that) {
case _SosVoice():
return $default(_that.url,_that.token,_that.room,_that.canPublish);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String token,  String room,  bool canPublish)?  $default,) {final _that = this;
switch (_that) {
case _SosVoice() when $default != null:
return $default(_that.url,_that.token,_that.room,_that.canPublish);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SosVoice implements SosVoice {
  const _SosVoice({required this.url, required this.token, required this.room, this.canPublish = false});
  factory _SosVoice.fromJson(Map<String, dynamic> json) => _$SosVoiceFromJson(json);

@override final  String url;
@override final  String token;
@override final  String room;
@override@JsonKey() final  bool canPublish;

/// Create a copy of SosVoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosVoiceCopyWith<_SosVoice> get copyWith => __$SosVoiceCopyWithImpl<_SosVoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SosVoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosVoice&&(identical(other.url, url) || other.url == url)&&(identical(other.token, token) || other.token == token)&&(identical(other.room, room) || other.room == room)&&(identical(other.canPublish, canPublish) || other.canPublish == canPublish));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,token,room,canPublish);

@override
String toString() {
  return 'SosVoice(url: $url, token: $token, room: $room, canPublish: $canPublish)';
}


}

/// @nodoc
abstract mixin class _$SosVoiceCopyWith<$Res> implements $SosVoiceCopyWith<$Res> {
  factory _$SosVoiceCopyWith(_SosVoice value, $Res Function(_SosVoice) _then) = __$SosVoiceCopyWithImpl;
@override @useResult
$Res call({
 String url, String token, String room, bool canPublish
});




}
/// @nodoc
class __$SosVoiceCopyWithImpl<$Res>
    implements _$SosVoiceCopyWith<$Res> {
  __$SosVoiceCopyWithImpl(this._self, this._then);

  final _SosVoice _self;
  final $Res Function(_SosVoice) _then;

/// Create a copy of SosVoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? token = null,Object? room = null,Object? canPublish = null,}) {
  return _then(_SosVoice(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,canPublish: null == canPublish ? _self.canPublish : canPublish // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SosRaise {

 SosAlertSelf get alert; SosVoice? get voice; bool get needsPin;
/// Create a copy of SosRaise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosRaiseCopyWith<SosRaise> get copyWith => _$SosRaiseCopyWithImpl<SosRaise>(this as SosRaise, _$identity);

  /// Serializes this SosRaise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosRaise&&(identical(other.alert, alert) || other.alert == alert)&&(identical(other.voice, voice) || other.voice == voice)&&(identical(other.needsPin, needsPin) || other.needsPin == needsPin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,alert,voice,needsPin);

@override
String toString() {
  return 'SosRaise(alert: $alert, voice: $voice, needsPin: $needsPin)';
}


}

/// @nodoc
abstract mixin class $SosRaiseCopyWith<$Res>  {
  factory $SosRaiseCopyWith(SosRaise value, $Res Function(SosRaise) _then) = _$SosRaiseCopyWithImpl;
@useResult
$Res call({
 SosAlertSelf alert, SosVoice? voice, bool needsPin
});


$SosAlertSelfCopyWith<$Res> get alert;$SosVoiceCopyWith<$Res>? get voice;

}
/// @nodoc
class _$SosRaiseCopyWithImpl<$Res>
    implements $SosRaiseCopyWith<$Res> {
  _$SosRaiseCopyWithImpl(this._self, this._then);

  final SosRaise _self;
  final $Res Function(SosRaise) _then;

/// Create a copy of SosRaise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? alert = null,Object? voice = freezed,Object? needsPin = null,}) {
  return _then(_self.copyWith(
alert: null == alert ? _self.alert : alert // ignore: cast_nullable_to_non_nullable
as SosAlertSelf,voice: freezed == voice ? _self.voice : voice // ignore: cast_nullable_to_non_nullable
as SosVoice?,needsPin: null == needsPin ? _self.needsPin : needsPin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of SosRaise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosAlertSelfCopyWith<$Res> get alert {
  
  return $SosAlertSelfCopyWith<$Res>(_self.alert, (value) {
    return _then(_self.copyWith(alert: value));
  });
}/// Create a copy of SosRaise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosVoiceCopyWith<$Res>? get voice {
    if (_self.voice == null) {
    return null;
  }

  return $SosVoiceCopyWith<$Res>(_self.voice!, (value) {
    return _then(_self.copyWith(voice: value));
  });
}
}


/// Adds pattern-matching-related methods to [SosRaise].
extension SosRaisePatterns on SosRaise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosRaise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosRaise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosRaise value)  $default,){
final _that = this;
switch (_that) {
case _SosRaise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosRaise value)?  $default,){
final _that = this;
switch (_that) {
case _SosRaise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SosAlertSelf alert,  SosVoice? voice,  bool needsPin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosRaise() when $default != null:
return $default(_that.alert,_that.voice,_that.needsPin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SosAlertSelf alert,  SosVoice? voice,  bool needsPin)  $default,) {final _that = this;
switch (_that) {
case _SosRaise():
return $default(_that.alert,_that.voice,_that.needsPin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SosAlertSelf alert,  SosVoice? voice,  bool needsPin)?  $default,) {final _that = this;
switch (_that) {
case _SosRaise() when $default != null:
return $default(_that.alert,_that.voice,_that.needsPin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SosRaise implements SosRaise {
  const _SosRaise({required this.alert, this.voice, this.needsPin = false});
  factory _SosRaise.fromJson(Map<String, dynamic> json) => _$SosRaiseFromJson(json);

@override final  SosAlertSelf alert;
@override final  SosVoice? voice;
@override@JsonKey() final  bool needsPin;

/// Create a copy of SosRaise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosRaiseCopyWith<_SosRaise> get copyWith => __$SosRaiseCopyWithImpl<_SosRaise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SosRaiseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosRaise&&(identical(other.alert, alert) || other.alert == alert)&&(identical(other.voice, voice) || other.voice == voice)&&(identical(other.needsPin, needsPin) || other.needsPin == needsPin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,alert,voice,needsPin);

@override
String toString() {
  return 'SosRaise(alert: $alert, voice: $voice, needsPin: $needsPin)';
}


}

/// @nodoc
abstract mixin class _$SosRaiseCopyWith<$Res> implements $SosRaiseCopyWith<$Res> {
  factory _$SosRaiseCopyWith(_SosRaise value, $Res Function(_SosRaise) _then) = __$SosRaiseCopyWithImpl;
@override @useResult
$Res call({
 SosAlertSelf alert, SosVoice? voice, bool needsPin
});


@override $SosAlertSelfCopyWith<$Res> get alert;@override $SosVoiceCopyWith<$Res>? get voice;

}
/// @nodoc
class __$SosRaiseCopyWithImpl<$Res>
    implements _$SosRaiseCopyWith<$Res> {
  __$SosRaiseCopyWithImpl(this._self, this._then);

  final _SosRaise _self;
  final $Res Function(_SosRaise) _then;

/// Create a copy of SosRaise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? alert = null,Object? voice = freezed,Object? needsPin = null,}) {
  return _then(_SosRaise(
alert: null == alert ? _self.alert : alert // ignore: cast_nullable_to_non_nullable
as SosAlertSelf,voice: freezed == voice ? _self.voice : voice // ignore: cast_nullable_to_non_nullable
as SosVoice?,needsPin: null == needsPin ? _self.needsPin : needsPin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SosRaise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosAlertSelfCopyWith<$Res> get alert {
  
  return $SosAlertSelfCopyWith<$Res>(_self.alert, (value) {
    return _then(_self.copyWith(alert: value));
  });
}/// Create a copy of SosRaise
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosVoiceCopyWith<$Res>? get voice {
    if (_self.voice == null) {
    return null;
  }

  return $SosVoiceCopyWith<$Res>(_self.voice!, (value) {
    return _then(_self.copyWith(voice: value));
  });
}
}


/// @nodoc
mixin _$SosAlertSummary {

 String get id; String get tripId; SosRole get raisedRole; String get raisedByName; SosStatus get status; bool get cancelWithoutPin; String? get claimedBy; String? get claimedByName; SosOutcome? get outcome; bool get escalated; bool get hasRecording; DateTime get createdAt; DateTime? get claimedAt; DateTime? get closedAt; SosLocation? get lastLocation;
/// Create a copy of SosAlertSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosAlertSummaryCopyWith<SosAlertSummary> get copyWith => _$SosAlertSummaryCopyWithImpl<SosAlertSummary>(this as SosAlertSummary, _$identity);

  /// Serializes this SosAlertSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosAlertSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.raisedRole, raisedRole) || other.raisedRole == raisedRole)&&(identical(other.raisedByName, raisedByName) || other.raisedByName == raisedByName)&&(identical(other.status, status) || other.status == status)&&(identical(other.cancelWithoutPin, cancelWithoutPin) || other.cancelWithoutPin == cancelWithoutPin)&&(identical(other.claimedBy, claimedBy) || other.claimedBy == claimedBy)&&(identical(other.claimedByName, claimedByName) || other.claimedByName == claimedByName)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.escalated, escalated) || other.escalated == escalated)&&(identical(other.hasRecording, hasRecording) || other.hasRecording == hasRecording)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.claimedAt, claimedAt) || other.claimedAt == claimedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.lastLocation, lastLocation) || other.lastLocation == lastLocation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,raisedRole,raisedByName,status,cancelWithoutPin,claimedBy,claimedByName,outcome,escalated,hasRecording,createdAt,claimedAt,closedAt,lastLocation);

@override
String toString() {
  return 'SosAlertSummary(id: $id, tripId: $tripId, raisedRole: $raisedRole, raisedByName: $raisedByName, status: $status, cancelWithoutPin: $cancelWithoutPin, claimedBy: $claimedBy, claimedByName: $claimedByName, outcome: $outcome, escalated: $escalated, hasRecording: $hasRecording, createdAt: $createdAt, claimedAt: $claimedAt, closedAt: $closedAt, lastLocation: $lastLocation)';
}


}

/// @nodoc
abstract mixin class $SosAlertSummaryCopyWith<$Res>  {
  factory $SosAlertSummaryCopyWith(SosAlertSummary value, $Res Function(SosAlertSummary) _then) = _$SosAlertSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, SosRole raisedRole, String raisedByName, SosStatus status, bool cancelWithoutPin, String? claimedBy, String? claimedByName, SosOutcome? outcome, bool escalated, bool hasRecording, DateTime createdAt, DateTime? claimedAt, DateTime? closedAt, SosLocation? lastLocation
});


$SosLocationCopyWith<$Res>? get lastLocation;

}
/// @nodoc
class _$SosAlertSummaryCopyWithImpl<$Res>
    implements $SosAlertSummaryCopyWith<$Res> {
  _$SosAlertSummaryCopyWithImpl(this._self, this._then);

  final SosAlertSummary _self;
  final $Res Function(SosAlertSummary) _then;

/// Create a copy of SosAlertSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? raisedRole = null,Object? raisedByName = null,Object? status = null,Object? cancelWithoutPin = null,Object? claimedBy = freezed,Object? claimedByName = freezed,Object? outcome = freezed,Object? escalated = null,Object? hasRecording = null,Object? createdAt = null,Object? claimedAt = freezed,Object? closedAt = freezed,Object? lastLocation = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,raisedRole: null == raisedRole ? _self.raisedRole : raisedRole // ignore: cast_nullable_to_non_nullable
as SosRole,raisedByName: null == raisedByName ? _self.raisedByName : raisedByName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SosStatus,cancelWithoutPin: null == cancelWithoutPin ? _self.cancelWithoutPin : cancelWithoutPin // ignore: cast_nullable_to_non_nullable
as bool,claimedBy: freezed == claimedBy ? _self.claimedBy : claimedBy // ignore: cast_nullable_to_non_nullable
as String?,claimedByName: freezed == claimedByName ? _self.claimedByName : claimedByName // ignore: cast_nullable_to_non_nullable
as String?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as SosOutcome?,escalated: null == escalated ? _self.escalated : escalated // ignore: cast_nullable_to_non_nullable
as bool,hasRecording: null == hasRecording ? _self.hasRecording : hasRecording // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,claimedAt: freezed == claimedAt ? _self.claimedAt : claimedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastLocation: freezed == lastLocation ? _self.lastLocation : lastLocation // ignore: cast_nullable_to_non_nullable
as SosLocation?,
  ));
}
/// Create a copy of SosAlertSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosLocationCopyWith<$Res>? get lastLocation {
    if (_self.lastLocation == null) {
    return null;
  }

  return $SosLocationCopyWith<$Res>(_self.lastLocation!, (value) {
    return _then(_self.copyWith(lastLocation: value));
  });
}
}


/// Adds pattern-matching-related methods to [SosAlertSummary].
extension SosAlertSummaryPatterns on SosAlertSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosAlertSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosAlertSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosAlertSummary value)  $default,){
final _that = this;
switch (_that) {
case _SosAlertSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosAlertSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SosAlertSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  SosRole raisedRole,  String raisedByName,  SosStatus status,  bool cancelWithoutPin,  String? claimedBy,  String? claimedByName,  SosOutcome? outcome,  bool escalated,  bool hasRecording,  DateTime createdAt,  DateTime? claimedAt,  DateTime? closedAt,  SosLocation? lastLocation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosAlertSummary() when $default != null:
return $default(_that.id,_that.tripId,_that.raisedRole,_that.raisedByName,_that.status,_that.cancelWithoutPin,_that.claimedBy,_that.claimedByName,_that.outcome,_that.escalated,_that.hasRecording,_that.createdAt,_that.claimedAt,_that.closedAt,_that.lastLocation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  SosRole raisedRole,  String raisedByName,  SosStatus status,  bool cancelWithoutPin,  String? claimedBy,  String? claimedByName,  SosOutcome? outcome,  bool escalated,  bool hasRecording,  DateTime createdAt,  DateTime? claimedAt,  DateTime? closedAt,  SosLocation? lastLocation)  $default,) {final _that = this;
switch (_that) {
case _SosAlertSummary():
return $default(_that.id,_that.tripId,_that.raisedRole,_that.raisedByName,_that.status,_that.cancelWithoutPin,_that.claimedBy,_that.claimedByName,_that.outcome,_that.escalated,_that.hasRecording,_that.createdAt,_that.claimedAt,_that.closedAt,_that.lastLocation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  SosRole raisedRole,  String raisedByName,  SosStatus status,  bool cancelWithoutPin,  String? claimedBy,  String? claimedByName,  SosOutcome? outcome,  bool escalated,  bool hasRecording,  DateTime createdAt,  DateTime? claimedAt,  DateTime? closedAt,  SosLocation? lastLocation)?  $default,) {final _that = this;
switch (_that) {
case _SosAlertSummary() when $default != null:
return $default(_that.id,_that.tripId,_that.raisedRole,_that.raisedByName,_that.status,_that.cancelWithoutPin,_that.claimedBy,_that.claimedByName,_that.outcome,_that.escalated,_that.hasRecording,_that.createdAt,_that.claimedAt,_that.closedAt,_that.lastLocation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SosAlertSummary implements SosAlertSummary {
  const _SosAlertSummary({required this.id, required this.tripId, required this.raisedRole, required this.raisedByName, required this.status, this.cancelWithoutPin = false, this.claimedBy, this.claimedByName, this.outcome, this.escalated = false, this.hasRecording = false, required this.createdAt, this.claimedAt, this.closedAt, this.lastLocation});
  factory _SosAlertSummary.fromJson(Map<String, dynamic> json) => _$SosAlertSummaryFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  SosRole raisedRole;
@override final  String raisedByName;
@override final  SosStatus status;
@override@JsonKey() final  bool cancelWithoutPin;
@override final  String? claimedBy;
@override final  String? claimedByName;
@override final  SosOutcome? outcome;
@override@JsonKey() final  bool escalated;
@override@JsonKey() final  bool hasRecording;
@override final  DateTime createdAt;
@override final  DateTime? claimedAt;
@override final  DateTime? closedAt;
@override final  SosLocation? lastLocation;

/// Create a copy of SosAlertSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosAlertSummaryCopyWith<_SosAlertSummary> get copyWith => __$SosAlertSummaryCopyWithImpl<_SosAlertSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SosAlertSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosAlertSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.raisedRole, raisedRole) || other.raisedRole == raisedRole)&&(identical(other.raisedByName, raisedByName) || other.raisedByName == raisedByName)&&(identical(other.status, status) || other.status == status)&&(identical(other.cancelWithoutPin, cancelWithoutPin) || other.cancelWithoutPin == cancelWithoutPin)&&(identical(other.claimedBy, claimedBy) || other.claimedBy == claimedBy)&&(identical(other.claimedByName, claimedByName) || other.claimedByName == claimedByName)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.escalated, escalated) || other.escalated == escalated)&&(identical(other.hasRecording, hasRecording) || other.hasRecording == hasRecording)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.claimedAt, claimedAt) || other.claimedAt == claimedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.lastLocation, lastLocation) || other.lastLocation == lastLocation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,raisedRole,raisedByName,status,cancelWithoutPin,claimedBy,claimedByName,outcome,escalated,hasRecording,createdAt,claimedAt,closedAt,lastLocation);

@override
String toString() {
  return 'SosAlertSummary(id: $id, tripId: $tripId, raisedRole: $raisedRole, raisedByName: $raisedByName, status: $status, cancelWithoutPin: $cancelWithoutPin, claimedBy: $claimedBy, claimedByName: $claimedByName, outcome: $outcome, escalated: $escalated, hasRecording: $hasRecording, createdAt: $createdAt, claimedAt: $claimedAt, closedAt: $closedAt, lastLocation: $lastLocation)';
}


}

/// @nodoc
abstract mixin class _$SosAlertSummaryCopyWith<$Res> implements $SosAlertSummaryCopyWith<$Res> {
  factory _$SosAlertSummaryCopyWith(_SosAlertSummary value, $Res Function(_SosAlertSummary) _then) = __$SosAlertSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, SosRole raisedRole, String raisedByName, SosStatus status, bool cancelWithoutPin, String? claimedBy, String? claimedByName, SosOutcome? outcome, bool escalated, bool hasRecording, DateTime createdAt, DateTime? claimedAt, DateTime? closedAt, SosLocation? lastLocation
});


@override $SosLocationCopyWith<$Res>? get lastLocation;

}
/// @nodoc
class __$SosAlertSummaryCopyWithImpl<$Res>
    implements _$SosAlertSummaryCopyWith<$Res> {
  __$SosAlertSummaryCopyWithImpl(this._self, this._then);

  final _SosAlertSummary _self;
  final $Res Function(_SosAlertSummary) _then;

/// Create a copy of SosAlertSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? raisedRole = null,Object? raisedByName = null,Object? status = null,Object? cancelWithoutPin = null,Object? claimedBy = freezed,Object? claimedByName = freezed,Object? outcome = freezed,Object? escalated = null,Object? hasRecording = null,Object? createdAt = null,Object? claimedAt = freezed,Object? closedAt = freezed,Object? lastLocation = freezed,}) {
  return _then(_SosAlertSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,raisedRole: null == raisedRole ? _self.raisedRole : raisedRole // ignore: cast_nullable_to_non_nullable
as SosRole,raisedByName: null == raisedByName ? _self.raisedByName : raisedByName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SosStatus,cancelWithoutPin: null == cancelWithoutPin ? _self.cancelWithoutPin : cancelWithoutPin // ignore: cast_nullable_to_non_nullable
as bool,claimedBy: freezed == claimedBy ? _self.claimedBy : claimedBy // ignore: cast_nullable_to_non_nullable
as String?,claimedByName: freezed == claimedByName ? _self.claimedByName : claimedByName // ignore: cast_nullable_to_non_nullable
as String?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as SosOutcome?,escalated: null == escalated ? _self.escalated : escalated // ignore: cast_nullable_to_non_nullable
as bool,hasRecording: null == hasRecording ? _self.hasRecording : hasRecording // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,claimedAt: freezed == claimedAt ? _self.claimedAt : claimedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastLocation: freezed == lastLocation ? _self.lastLocation : lastLocation // ignore: cast_nullable_to_non_nullable
as SosLocation?,
  ));
}

/// Create a copy of SosAlertSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosLocationCopyWith<$Res>? get lastLocation {
    if (_self.lastLocation == null) {
    return null;
  }

  return $SosLocationCopyWith<$Res>(_self.lastLocation!, (value) {
    return _then(_self.copyWith(lastLocation: value));
  });
}
}


/// @nodoc
mixin _$SosNote {

 String get id; String get operatorId; String get operatorName; String get body; DateTime get createdAt;
/// Create a copy of SosNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosNoteCopyWith<SosNote> get copyWith => _$SosNoteCopyWithImpl<SosNote>(this as SosNote, _$identity);

  /// Serializes this SosNote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosNote&&(identical(other.id, id) || other.id == id)&&(identical(other.operatorId, operatorId) || other.operatorId == operatorId)&&(identical(other.operatorName, operatorName) || other.operatorName == operatorName)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,operatorId,operatorName,body,createdAt);

@override
String toString() {
  return 'SosNote(id: $id, operatorId: $operatorId, operatorName: $operatorName, body: $body, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SosNoteCopyWith<$Res>  {
  factory $SosNoteCopyWith(SosNote value, $Res Function(SosNote) _then) = _$SosNoteCopyWithImpl;
@useResult
$Res call({
 String id, String operatorId, String operatorName, String body, DateTime createdAt
});




}
/// @nodoc
class _$SosNoteCopyWithImpl<$Res>
    implements $SosNoteCopyWith<$Res> {
  _$SosNoteCopyWithImpl(this._self, this._then);

  final SosNote _self;
  final $Res Function(SosNote) _then;

/// Create a copy of SosNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? operatorId = null,Object? operatorName = null,Object? body = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,operatorId: null == operatorId ? _self.operatorId : operatorId // ignore: cast_nullable_to_non_nullable
as String,operatorName: null == operatorName ? _self.operatorName : operatorName // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SosNote].
extension SosNotePatterns on SosNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosNote value)  $default,){
final _that = this;
switch (_that) {
case _SosNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosNote value)?  $default,){
final _that = this;
switch (_that) {
case _SosNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String operatorId,  String operatorName,  String body,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosNote() when $default != null:
return $default(_that.id,_that.operatorId,_that.operatorName,_that.body,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String operatorId,  String operatorName,  String body,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _SosNote():
return $default(_that.id,_that.operatorId,_that.operatorName,_that.body,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String operatorId,  String operatorName,  String body,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SosNote() when $default != null:
return $default(_that.id,_that.operatorId,_that.operatorName,_that.body,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SosNote implements SosNote {
  const _SosNote({required this.id, required this.operatorId, required this.operatorName, required this.body, required this.createdAt});
  factory _SosNote.fromJson(Map<String, dynamic> json) => _$SosNoteFromJson(json);

@override final  String id;
@override final  String operatorId;
@override final  String operatorName;
@override final  String body;
@override final  DateTime createdAt;

/// Create a copy of SosNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosNoteCopyWith<_SosNote> get copyWith => __$SosNoteCopyWithImpl<_SosNote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SosNoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosNote&&(identical(other.id, id) || other.id == id)&&(identical(other.operatorId, operatorId) || other.operatorId == operatorId)&&(identical(other.operatorName, operatorName) || other.operatorName == operatorName)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,operatorId,operatorName,body,createdAt);

@override
String toString() {
  return 'SosNote(id: $id, operatorId: $operatorId, operatorName: $operatorName, body: $body, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SosNoteCopyWith<$Res> implements $SosNoteCopyWith<$Res> {
  factory _$SosNoteCopyWith(_SosNote value, $Res Function(_SosNote) _then) = __$SosNoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String operatorId, String operatorName, String body, DateTime createdAt
});




}
/// @nodoc
class __$SosNoteCopyWithImpl<$Res>
    implements _$SosNoteCopyWith<$Res> {
  __$SosNoteCopyWithImpl(this._self, this._then);

  final _SosNote _self;
  final $Res Function(_SosNote) _then;

/// Create a copy of SosNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? operatorId = null,Object? operatorName = null,Object? body = null,Object? createdAt = null,}) {
  return _then(_SosNote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,operatorId: null == operatorId ? _self.operatorId : operatorId // ignore: cast_nullable_to_non_nullable
as String,operatorName: null == operatorName ? _self.operatorName : operatorName // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SosPerson {

 String get userId; String get name;
/// Create a copy of SosPerson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosPersonCopyWith<SosPerson> get copyWith => _$SosPersonCopyWithImpl<SosPerson>(this as SosPerson, _$identity);

  /// Serializes this SosPerson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosPerson&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,name);

@override
String toString() {
  return 'SosPerson(userId: $userId, name: $name)';
}


}

/// @nodoc
abstract mixin class $SosPersonCopyWith<$Res>  {
  factory $SosPersonCopyWith(SosPerson value, $Res Function(SosPerson) _then) = _$SosPersonCopyWithImpl;
@useResult
$Res call({
 String userId, String name
});




}
/// @nodoc
class _$SosPersonCopyWithImpl<$Res>
    implements $SosPersonCopyWith<$Res> {
  _$SosPersonCopyWithImpl(this._self, this._then);

  final SosPerson _self;
  final $Res Function(SosPerson) _then;

/// Create a copy of SosPerson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? name = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SosPerson].
extension SosPersonPatterns on SosPerson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosPerson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosPerson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosPerson value)  $default,){
final _that = this;
switch (_that) {
case _SosPerson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosPerson value)?  $default,){
final _that = this;
switch (_that) {
case _SosPerson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosPerson() when $default != null:
return $default(_that.userId,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String name)  $default,) {final _that = this;
switch (_that) {
case _SosPerson():
return $default(_that.userId,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String name)?  $default,) {final _that = this;
switch (_that) {
case _SosPerson() when $default != null:
return $default(_that.userId,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SosPerson implements SosPerson {
  const _SosPerson({required this.userId, required this.name});
  factory _SosPerson.fromJson(Map<String, dynamic> json) => _$SosPersonFromJson(json);

@override final  String userId;
@override final  String name;

/// Create a copy of SosPerson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosPersonCopyWith<_SosPerson> get copyWith => __$SosPersonCopyWithImpl<_SosPerson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SosPersonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosPerson&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,name);

@override
String toString() {
  return 'SosPerson(userId: $userId, name: $name)';
}


}

/// @nodoc
abstract mixin class _$SosPersonCopyWith<$Res> implements $SosPersonCopyWith<$Res> {
  factory _$SosPersonCopyWith(_SosPerson value, $Res Function(_SosPerson) _then) = __$SosPersonCopyWithImpl;
@override @useResult
$Res call({
 String userId, String name
});




}
/// @nodoc
class __$SosPersonCopyWithImpl<$Res>
    implements _$SosPersonCopyWith<$Res> {
  __$SosPersonCopyWithImpl(this._self, this._then);

  final _SosPerson _self;
  final $Res Function(_SosPerson) _then;

/// Create a copy of SosPerson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? name = null,}) {
  return _then(_SosPerson(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SosDriver {

 String get userId; String get name; String get vehiclePlate; String get vehicleDescription; String? get vehicleBrand; String? get vehicleModel; String? get vehicleColor;
/// Create a copy of SosDriver
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosDriverCopyWith<SosDriver> get copyWith => _$SosDriverCopyWithImpl<SosDriver>(this as SosDriver, _$identity);

  /// Serializes this SosDriver to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosDriver&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleDescription, vehicleDescription) || other.vehicleDescription == vehicleDescription)&&(identical(other.vehicleBrand, vehicleBrand) || other.vehicleBrand == vehicleBrand)&&(identical(other.vehicleModel, vehicleModel) || other.vehicleModel == vehicleModel)&&(identical(other.vehicleColor, vehicleColor) || other.vehicleColor == vehicleColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,name,vehiclePlate,vehicleDescription,vehicleBrand,vehicleModel,vehicleColor);

@override
String toString() {
  return 'SosDriver(userId: $userId, name: $name, vehiclePlate: $vehiclePlate, vehicleDescription: $vehicleDescription, vehicleBrand: $vehicleBrand, vehicleModel: $vehicleModel, vehicleColor: $vehicleColor)';
}


}

/// @nodoc
abstract mixin class $SosDriverCopyWith<$Res>  {
  factory $SosDriverCopyWith(SosDriver value, $Res Function(SosDriver) _then) = _$SosDriverCopyWithImpl;
@useResult
$Res call({
 String userId, String name, String vehiclePlate, String vehicleDescription, String? vehicleBrand, String? vehicleModel, String? vehicleColor
});




}
/// @nodoc
class _$SosDriverCopyWithImpl<$Res>
    implements $SosDriverCopyWith<$Res> {
  _$SosDriverCopyWithImpl(this._self, this._then);

  final SosDriver _self;
  final $Res Function(SosDriver) _then;

/// Create a copy of SosDriver
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? name = null,Object? vehiclePlate = null,Object? vehicleDescription = null,Object? vehicleBrand = freezed,Object? vehicleModel = freezed,Object? vehicleColor = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,vehicleDescription: null == vehicleDescription ? _self.vehicleDescription : vehicleDescription // ignore: cast_nullable_to_non_nullable
as String,vehicleBrand: freezed == vehicleBrand ? _self.vehicleBrand : vehicleBrand // ignore: cast_nullable_to_non_nullable
as String?,vehicleModel: freezed == vehicleModel ? _self.vehicleModel : vehicleModel // ignore: cast_nullable_to_non_nullable
as String?,vehicleColor: freezed == vehicleColor ? _self.vehicleColor : vehicleColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SosDriver].
extension SosDriverPatterns on SosDriver {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosDriver value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosDriver() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosDriver value)  $default,){
final _that = this;
switch (_that) {
case _SosDriver():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosDriver value)?  $default,){
final _that = this;
switch (_that) {
case _SosDriver() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String name,  String vehiclePlate,  String vehicleDescription,  String? vehicleBrand,  String? vehicleModel,  String? vehicleColor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosDriver() when $default != null:
return $default(_that.userId,_that.name,_that.vehiclePlate,_that.vehicleDescription,_that.vehicleBrand,_that.vehicleModel,_that.vehicleColor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String name,  String vehiclePlate,  String vehicleDescription,  String? vehicleBrand,  String? vehicleModel,  String? vehicleColor)  $default,) {final _that = this;
switch (_that) {
case _SosDriver():
return $default(_that.userId,_that.name,_that.vehiclePlate,_that.vehicleDescription,_that.vehicleBrand,_that.vehicleModel,_that.vehicleColor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String name,  String vehiclePlate,  String vehicleDescription,  String? vehicleBrand,  String? vehicleModel,  String? vehicleColor)?  $default,) {final _that = this;
switch (_that) {
case _SosDriver() when $default != null:
return $default(_that.userId,_that.name,_that.vehiclePlate,_that.vehicleDescription,_that.vehicleBrand,_that.vehicleModel,_that.vehicleColor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SosDriver implements SosDriver {
  const _SosDriver({required this.userId, required this.name, required this.vehiclePlate, required this.vehicleDescription, this.vehicleBrand, this.vehicleModel, this.vehicleColor});
  factory _SosDriver.fromJson(Map<String, dynamic> json) => _$SosDriverFromJson(json);

@override final  String userId;
@override final  String name;
@override final  String vehiclePlate;
@override final  String vehicleDescription;
@override final  String? vehicleBrand;
@override final  String? vehicleModel;
@override final  String? vehicleColor;

/// Create a copy of SosDriver
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosDriverCopyWith<_SosDriver> get copyWith => __$SosDriverCopyWithImpl<_SosDriver>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SosDriverToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosDriver&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleDescription, vehicleDescription) || other.vehicleDescription == vehicleDescription)&&(identical(other.vehicleBrand, vehicleBrand) || other.vehicleBrand == vehicleBrand)&&(identical(other.vehicleModel, vehicleModel) || other.vehicleModel == vehicleModel)&&(identical(other.vehicleColor, vehicleColor) || other.vehicleColor == vehicleColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,name,vehiclePlate,vehicleDescription,vehicleBrand,vehicleModel,vehicleColor);

@override
String toString() {
  return 'SosDriver(userId: $userId, name: $name, vehiclePlate: $vehiclePlate, vehicleDescription: $vehicleDescription, vehicleBrand: $vehicleBrand, vehicleModel: $vehicleModel, vehicleColor: $vehicleColor)';
}


}

/// @nodoc
abstract mixin class _$SosDriverCopyWith<$Res> implements $SosDriverCopyWith<$Res> {
  factory _$SosDriverCopyWith(_SosDriver value, $Res Function(_SosDriver) _then) = __$SosDriverCopyWithImpl;
@override @useResult
$Res call({
 String userId, String name, String vehiclePlate, String vehicleDescription, String? vehicleBrand, String? vehicleModel, String? vehicleColor
});




}
/// @nodoc
class __$SosDriverCopyWithImpl<$Res>
    implements _$SosDriverCopyWith<$Res> {
  __$SosDriverCopyWithImpl(this._self, this._then);

  final _SosDriver _self;
  final $Res Function(_SosDriver) _then;

/// Create a copy of SosDriver
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? name = null,Object? vehiclePlate = null,Object? vehicleDescription = null,Object? vehicleBrand = freezed,Object? vehicleModel = freezed,Object? vehicleColor = freezed,}) {
  return _then(_SosDriver(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,vehicleDescription: null == vehicleDescription ? _self.vehicleDescription : vehicleDescription // ignore: cast_nullable_to_non_nullable
as String,vehicleBrand: freezed == vehicleBrand ? _self.vehicleBrand : vehicleBrand // ignore: cast_nullable_to_non_nullable
as String?,vehicleModel: freezed == vehicleModel ? _self.vehicleModel : vehicleModel // ignore: cast_nullable_to_non_nullable
as String?,vehicleColor: freezed == vehicleColor ? _self.vehicleColor : vehicleColor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SosTrip {

 String get status; GeoPoint get pickup; GeoPoint get dropoff;
/// Create a copy of SosTrip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosTripCopyWith<SosTrip> get copyWith => _$SosTripCopyWithImpl<SosTrip>(this as SosTrip, _$identity);

  /// Serializes this SosTrip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosTrip&&(identical(other.status, status) || other.status == status)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,pickup,dropoff);

@override
String toString() {
  return 'SosTrip(status: $status, pickup: $pickup, dropoff: $dropoff)';
}


}

/// @nodoc
abstract mixin class $SosTripCopyWith<$Res>  {
  factory $SosTripCopyWith(SosTrip value, $Res Function(SosTrip) _then) = _$SosTripCopyWithImpl;
@useResult
$Res call({
 String status, GeoPoint pickup, GeoPoint dropoff
});


$GeoPointCopyWith<$Res> get pickup;$GeoPointCopyWith<$Res> get dropoff;

}
/// @nodoc
class _$SosTripCopyWithImpl<$Res>
    implements $SosTripCopyWith<$Res> {
  _$SosTripCopyWithImpl(this._self, this._then);

  final SosTrip _self;
  final $Res Function(SosTrip) _then;

/// Create a copy of SosTrip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? pickup = null,Object? dropoff = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as GeoPoint,
  ));
}
/// Create a copy of SosTrip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get pickup {
  
  return $GeoPointCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of SosTrip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get dropoff {
  
  return $GeoPointCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// Adds pattern-matching-related methods to [SosTrip].
extension SosTripPatterns on SosTrip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosTrip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosTrip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosTrip value)  $default,){
final _that = this;
switch (_that) {
case _SosTrip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosTrip value)?  $default,){
final _that = this;
switch (_that) {
case _SosTrip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  GeoPoint pickup,  GeoPoint dropoff)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosTrip() when $default != null:
return $default(_that.status,_that.pickup,_that.dropoff);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  GeoPoint pickup,  GeoPoint dropoff)  $default,) {final _that = this;
switch (_that) {
case _SosTrip():
return $default(_that.status,_that.pickup,_that.dropoff);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  GeoPoint pickup,  GeoPoint dropoff)?  $default,) {final _that = this;
switch (_that) {
case _SosTrip() when $default != null:
return $default(_that.status,_that.pickup,_that.dropoff);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SosTrip implements SosTrip {
  const _SosTrip({required this.status, required this.pickup, required this.dropoff});
  factory _SosTrip.fromJson(Map<String, dynamic> json) => _$SosTripFromJson(json);

@override final  String status;
@override final  GeoPoint pickup;
@override final  GeoPoint dropoff;

/// Create a copy of SosTrip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosTripCopyWith<_SosTrip> get copyWith => __$SosTripCopyWithImpl<_SosTrip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SosTripToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosTrip&&(identical(other.status, status) || other.status == status)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,pickup,dropoff);

@override
String toString() {
  return 'SosTrip(status: $status, pickup: $pickup, dropoff: $dropoff)';
}


}

/// @nodoc
abstract mixin class _$SosTripCopyWith<$Res> implements $SosTripCopyWith<$Res> {
  factory _$SosTripCopyWith(_SosTrip value, $Res Function(_SosTrip) _then) = __$SosTripCopyWithImpl;
@override @useResult
$Res call({
 String status, GeoPoint pickup, GeoPoint dropoff
});


@override $GeoPointCopyWith<$Res> get pickup;@override $GeoPointCopyWith<$Res> get dropoff;

}
/// @nodoc
class __$SosTripCopyWithImpl<$Res>
    implements _$SosTripCopyWith<$Res> {
  __$SosTripCopyWithImpl(this._self, this._then);

  final _SosTrip _self;
  final $Res Function(_SosTrip) _then;

/// Create a copy of SosTrip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? pickup = null,Object? dropoff = null,}) {
  return _then(_SosTrip(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as GeoPoint,
  ));
}

/// Create a copy of SosTrip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get pickup {
  
  return $GeoPointCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of SosTrip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get dropoff {
  
  return $GeoPointCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// @nodoc
mixin _$EmergencyContact {

 String get name; String get phoneE164;
/// Create a copy of EmergencyContact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmergencyContactCopyWith<EmergencyContact> get copyWith => _$EmergencyContactCopyWithImpl<EmergencyContact>(this as EmergencyContact, _$identity);

  /// Serializes this EmergencyContact to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmergencyContact&&(identical(other.name, name) || other.name == name)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phoneE164);

@override
String toString() {
  return 'EmergencyContact(name: $name, phoneE164: $phoneE164)';
}


}

/// @nodoc
abstract mixin class $EmergencyContactCopyWith<$Res>  {
  factory $EmergencyContactCopyWith(EmergencyContact value, $Res Function(EmergencyContact) _then) = _$EmergencyContactCopyWithImpl;
@useResult
$Res call({
 String name, String phoneE164
});




}
/// @nodoc
class _$EmergencyContactCopyWithImpl<$Res>
    implements $EmergencyContactCopyWith<$Res> {
  _$EmergencyContactCopyWithImpl(this._self, this._then);

  final EmergencyContact _self;
  final $Res Function(EmergencyContact) _then;

/// Create a copy of EmergencyContact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? phoneE164 = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phoneE164: null == phoneE164 ? _self.phoneE164 : phoneE164 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EmergencyContact].
extension EmergencyContactPatterns on EmergencyContact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmergencyContact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmergencyContact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmergencyContact value)  $default,){
final _that = this;
switch (_that) {
case _EmergencyContact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmergencyContact value)?  $default,){
final _that = this;
switch (_that) {
case _EmergencyContact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String phoneE164)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmergencyContact() when $default != null:
return $default(_that.name,_that.phoneE164);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String phoneE164)  $default,) {final _that = this;
switch (_that) {
case _EmergencyContact():
return $default(_that.name,_that.phoneE164);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String phoneE164)?  $default,) {final _that = this;
switch (_that) {
case _EmergencyContact() when $default != null:
return $default(_that.name,_that.phoneE164);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmergencyContact implements EmergencyContact {
  const _EmergencyContact({required this.name, required this.phoneE164});
  factory _EmergencyContact.fromJson(Map<String, dynamic> json) => _$EmergencyContactFromJson(json);

@override final  String name;
@override final  String phoneE164;

/// Create a copy of EmergencyContact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmergencyContactCopyWith<_EmergencyContact> get copyWith => __$EmergencyContactCopyWithImpl<_EmergencyContact>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmergencyContactToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmergencyContact&&(identical(other.name, name) || other.name == name)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phoneE164);

@override
String toString() {
  return 'EmergencyContact(name: $name, phoneE164: $phoneE164)';
}


}

/// @nodoc
abstract mixin class _$EmergencyContactCopyWith<$Res> implements $EmergencyContactCopyWith<$Res> {
  factory _$EmergencyContactCopyWith(_EmergencyContact value, $Res Function(_EmergencyContact) _then) = __$EmergencyContactCopyWithImpl;
@override @useResult
$Res call({
 String name, String phoneE164
});




}
/// @nodoc
class __$EmergencyContactCopyWithImpl<$Res>
    implements _$EmergencyContactCopyWith<$Res> {
  __$EmergencyContactCopyWithImpl(this._self, this._then);

  final _EmergencyContact _self;
  final $Res Function(_EmergencyContact) _then;

/// Create a copy of EmergencyContact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? phoneE164 = null,}) {
  return _then(_EmergencyContact(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phoneE164: null == phoneE164 ? _self.phoneE164 : phoneE164 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SosAlertDetail {

 String get id; String get tripId; SosRole get raisedRole; String get raisedByName; SosStatus get status; bool get cancelWithoutPin; String? get claimedBy; String? get claimedByName; SosOutcome? get outcome; bool get escalated; bool get hasRecording; DateTime get createdAt; DateTime? get claimedAt; DateTime? get closedAt; SosLocation? get lastLocation;@JsonKey(name: 'raised_by_phone_e164') String get raisedByPhone; List<EmergencyContact> get emergencyContacts; SosTrip get trip; SosPerson get passenger; SosDriver get driver; List<SosLocation> get track; List<SosNote> get notes; List<String> get relatedAlertIds; String? get recordingUrl; int get raisedByAlerts; int get raisedByFalseAlarms;
/// Create a copy of SosAlertDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SosAlertDetailCopyWith<SosAlertDetail> get copyWith => _$SosAlertDetailCopyWithImpl<SosAlertDetail>(this as SosAlertDetail, _$identity);

  /// Serializes this SosAlertDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SosAlertDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.raisedRole, raisedRole) || other.raisedRole == raisedRole)&&(identical(other.raisedByName, raisedByName) || other.raisedByName == raisedByName)&&(identical(other.status, status) || other.status == status)&&(identical(other.cancelWithoutPin, cancelWithoutPin) || other.cancelWithoutPin == cancelWithoutPin)&&(identical(other.claimedBy, claimedBy) || other.claimedBy == claimedBy)&&(identical(other.claimedByName, claimedByName) || other.claimedByName == claimedByName)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.escalated, escalated) || other.escalated == escalated)&&(identical(other.hasRecording, hasRecording) || other.hasRecording == hasRecording)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.claimedAt, claimedAt) || other.claimedAt == claimedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.lastLocation, lastLocation) || other.lastLocation == lastLocation)&&(identical(other.raisedByPhone, raisedByPhone) || other.raisedByPhone == raisedByPhone)&&const DeepCollectionEquality().equals(other.emergencyContacts, emergencyContacts)&&(identical(other.trip, trip) || other.trip == trip)&&(identical(other.passenger, passenger) || other.passenger == passenger)&&(identical(other.driver, driver) || other.driver == driver)&&const DeepCollectionEquality().equals(other.track, track)&&const DeepCollectionEquality().equals(other.notes, notes)&&const DeepCollectionEquality().equals(other.relatedAlertIds, relatedAlertIds)&&(identical(other.recordingUrl, recordingUrl) || other.recordingUrl == recordingUrl)&&(identical(other.raisedByAlerts, raisedByAlerts) || other.raisedByAlerts == raisedByAlerts)&&(identical(other.raisedByFalseAlarms, raisedByFalseAlarms) || other.raisedByFalseAlarms == raisedByFalseAlarms));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,tripId,raisedRole,raisedByName,status,cancelWithoutPin,claimedBy,claimedByName,outcome,escalated,hasRecording,createdAt,claimedAt,closedAt,lastLocation,raisedByPhone,const DeepCollectionEquality().hash(emergencyContacts),trip,passenger,driver,const DeepCollectionEquality().hash(track),const DeepCollectionEquality().hash(notes),const DeepCollectionEquality().hash(relatedAlertIds),recordingUrl,raisedByAlerts,raisedByFalseAlarms]);

@override
String toString() {
  return 'SosAlertDetail(id: $id, tripId: $tripId, raisedRole: $raisedRole, raisedByName: $raisedByName, status: $status, cancelWithoutPin: $cancelWithoutPin, claimedBy: $claimedBy, claimedByName: $claimedByName, outcome: $outcome, escalated: $escalated, hasRecording: $hasRecording, createdAt: $createdAt, claimedAt: $claimedAt, closedAt: $closedAt, lastLocation: $lastLocation, raisedByPhone: $raisedByPhone, emergencyContacts: $emergencyContacts, trip: $trip, passenger: $passenger, driver: $driver, track: $track, notes: $notes, relatedAlertIds: $relatedAlertIds, recordingUrl: $recordingUrl, raisedByAlerts: $raisedByAlerts, raisedByFalseAlarms: $raisedByFalseAlarms)';
}


}

/// @nodoc
abstract mixin class $SosAlertDetailCopyWith<$Res>  {
  factory $SosAlertDetailCopyWith(SosAlertDetail value, $Res Function(SosAlertDetail) _then) = _$SosAlertDetailCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, SosRole raisedRole, String raisedByName, SosStatus status, bool cancelWithoutPin, String? claimedBy, String? claimedByName, SosOutcome? outcome, bool escalated, bool hasRecording, DateTime createdAt, DateTime? claimedAt, DateTime? closedAt, SosLocation? lastLocation,@JsonKey(name: 'raised_by_phone_e164') String raisedByPhone, List<EmergencyContact> emergencyContacts, SosTrip trip, SosPerson passenger, SosDriver driver, List<SosLocation> track, List<SosNote> notes, List<String> relatedAlertIds, String? recordingUrl, int raisedByAlerts, int raisedByFalseAlarms
});


$SosLocationCopyWith<$Res>? get lastLocation;$SosTripCopyWith<$Res> get trip;$SosPersonCopyWith<$Res> get passenger;$SosDriverCopyWith<$Res> get driver;

}
/// @nodoc
class _$SosAlertDetailCopyWithImpl<$Res>
    implements $SosAlertDetailCopyWith<$Res> {
  _$SosAlertDetailCopyWithImpl(this._self, this._then);

  final SosAlertDetail _self;
  final $Res Function(SosAlertDetail) _then;

/// Create a copy of SosAlertDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? raisedRole = null,Object? raisedByName = null,Object? status = null,Object? cancelWithoutPin = null,Object? claimedBy = freezed,Object? claimedByName = freezed,Object? outcome = freezed,Object? escalated = null,Object? hasRecording = null,Object? createdAt = null,Object? claimedAt = freezed,Object? closedAt = freezed,Object? lastLocation = freezed,Object? raisedByPhone = null,Object? emergencyContacts = null,Object? trip = null,Object? passenger = null,Object? driver = null,Object? track = null,Object? notes = null,Object? relatedAlertIds = null,Object? recordingUrl = freezed,Object? raisedByAlerts = null,Object? raisedByFalseAlarms = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,raisedRole: null == raisedRole ? _self.raisedRole : raisedRole // ignore: cast_nullable_to_non_nullable
as SosRole,raisedByName: null == raisedByName ? _self.raisedByName : raisedByName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SosStatus,cancelWithoutPin: null == cancelWithoutPin ? _self.cancelWithoutPin : cancelWithoutPin // ignore: cast_nullable_to_non_nullable
as bool,claimedBy: freezed == claimedBy ? _self.claimedBy : claimedBy // ignore: cast_nullable_to_non_nullable
as String?,claimedByName: freezed == claimedByName ? _self.claimedByName : claimedByName // ignore: cast_nullable_to_non_nullable
as String?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as SosOutcome?,escalated: null == escalated ? _self.escalated : escalated // ignore: cast_nullable_to_non_nullable
as bool,hasRecording: null == hasRecording ? _self.hasRecording : hasRecording // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,claimedAt: freezed == claimedAt ? _self.claimedAt : claimedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastLocation: freezed == lastLocation ? _self.lastLocation : lastLocation // ignore: cast_nullable_to_non_nullable
as SosLocation?,raisedByPhone: null == raisedByPhone ? _self.raisedByPhone : raisedByPhone // ignore: cast_nullable_to_non_nullable
as String,emergencyContacts: null == emergencyContacts ? _self.emergencyContacts : emergencyContacts // ignore: cast_nullable_to_non_nullable
as List<EmergencyContact>,trip: null == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as SosTrip,passenger: null == passenger ? _self.passenger : passenger // ignore: cast_nullable_to_non_nullable
as SosPerson,driver: null == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as SosDriver,track: null == track ? _self.track : track // ignore: cast_nullable_to_non_nullable
as List<SosLocation>,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as List<SosNote>,relatedAlertIds: null == relatedAlertIds ? _self.relatedAlertIds : relatedAlertIds // ignore: cast_nullable_to_non_nullable
as List<String>,recordingUrl: freezed == recordingUrl ? _self.recordingUrl : recordingUrl // ignore: cast_nullable_to_non_nullable
as String?,raisedByAlerts: null == raisedByAlerts ? _self.raisedByAlerts : raisedByAlerts // ignore: cast_nullable_to_non_nullable
as int,raisedByFalseAlarms: null == raisedByFalseAlarms ? _self.raisedByFalseAlarms : raisedByFalseAlarms // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of SosAlertDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosLocationCopyWith<$Res>? get lastLocation {
    if (_self.lastLocation == null) {
    return null;
  }

  return $SosLocationCopyWith<$Res>(_self.lastLocation!, (value) {
    return _then(_self.copyWith(lastLocation: value));
  });
}/// Create a copy of SosAlertDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosTripCopyWith<$Res> get trip {
  
  return $SosTripCopyWith<$Res>(_self.trip, (value) {
    return _then(_self.copyWith(trip: value));
  });
}/// Create a copy of SosAlertDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosPersonCopyWith<$Res> get passenger {
  
  return $SosPersonCopyWith<$Res>(_self.passenger, (value) {
    return _then(_self.copyWith(passenger: value));
  });
}/// Create a copy of SosAlertDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosDriverCopyWith<$Res> get driver {
  
  return $SosDriverCopyWith<$Res>(_self.driver, (value) {
    return _then(_self.copyWith(driver: value));
  });
}
}


/// Adds pattern-matching-related methods to [SosAlertDetail].
extension SosAlertDetailPatterns on SosAlertDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SosAlertDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SosAlertDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SosAlertDetail value)  $default,){
final _that = this;
switch (_that) {
case _SosAlertDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SosAlertDetail value)?  $default,){
final _that = this;
switch (_that) {
case _SosAlertDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  SosRole raisedRole,  String raisedByName,  SosStatus status,  bool cancelWithoutPin,  String? claimedBy,  String? claimedByName,  SosOutcome? outcome,  bool escalated,  bool hasRecording,  DateTime createdAt,  DateTime? claimedAt,  DateTime? closedAt,  SosLocation? lastLocation, @JsonKey(name: 'raised_by_phone_e164')  String raisedByPhone,  List<EmergencyContact> emergencyContacts,  SosTrip trip,  SosPerson passenger,  SosDriver driver,  List<SosLocation> track,  List<SosNote> notes,  List<String> relatedAlertIds,  String? recordingUrl,  int raisedByAlerts,  int raisedByFalseAlarms)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SosAlertDetail() when $default != null:
return $default(_that.id,_that.tripId,_that.raisedRole,_that.raisedByName,_that.status,_that.cancelWithoutPin,_that.claimedBy,_that.claimedByName,_that.outcome,_that.escalated,_that.hasRecording,_that.createdAt,_that.claimedAt,_that.closedAt,_that.lastLocation,_that.raisedByPhone,_that.emergencyContacts,_that.trip,_that.passenger,_that.driver,_that.track,_that.notes,_that.relatedAlertIds,_that.recordingUrl,_that.raisedByAlerts,_that.raisedByFalseAlarms);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  SosRole raisedRole,  String raisedByName,  SosStatus status,  bool cancelWithoutPin,  String? claimedBy,  String? claimedByName,  SosOutcome? outcome,  bool escalated,  bool hasRecording,  DateTime createdAt,  DateTime? claimedAt,  DateTime? closedAt,  SosLocation? lastLocation, @JsonKey(name: 'raised_by_phone_e164')  String raisedByPhone,  List<EmergencyContact> emergencyContacts,  SosTrip trip,  SosPerson passenger,  SosDriver driver,  List<SosLocation> track,  List<SosNote> notes,  List<String> relatedAlertIds,  String? recordingUrl,  int raisedByAlerts,  int raisedByFalseAlarms)  $default,) {final _that = this;
switch (_that) {
case _SosAlertDetail():
return $default(_that.id,_that.tripId,_that.raisedRole,_that.raisedByName,_that.status,_that.cancelWithoutPin,_that.claimedBy,_that.claimedByName,_that.outcome,_that.escalated,_that.hasRecording,_that.createdAt,_that.claimedAt,_that.closedAt,_that.lastLocation,_that.raisedByPhone,_that.emergencyContacts,_that.trip,_that.passenger,_that.driver,_that.track,_that.notes,_that.relatedAlertIds,_that.recordingUrl,_that.raisedByAlerts,_that.raisedByFalseAlarms);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  SosRole raisedRole,  String raisedByName,  SosStatus status,  bool cancelWithoutPin,  String? claimedBy,  String? claimedByName,  SosOutcome? outcome,  bool escalated,  bool hasRecording,  DateTime createdAt,  DateTime? claimedAt,  DateTime? closedAt,  SosLocation? lastLocation, @JsonKey(name: 'raised_by_phone_e164')  String raisedByPhone,  List<EmergencyContact> emergencyContacts,  SosTrip trip,  SosPerson passenger,  SosDriver driver,  List<SosLocation> track,  List<SosNote> notes,  List<String> relatedAlertIds,  String? recordingUrl,  int raisedByAlerts,  int raisedByFalseAlarms)?  $default,) {final _that = this;
switch (_that) {
case _SosAlertDetail() when $default != null:
return $default(_that.id,_that.tripId,_that.raisedRole,_that.raisedByName,_that.status,_that.cancelWithoutPin,_that.claimedBy,_that.claimedByName,_that.outcome,_that.escalated,_that.hasRecording,_that.createdAt,_that.claimedAt,_that.closedAt,_that.lastLocation,_that.raisedByPhone,_that.emergencyContacts,_that.trip,_that.passenger,_that.driver,_that.track,_that.notes,_that.relatedAlertIds,_that.recordingUrl,_that.raisedByAlerts,_that.raisedByFalseAlarms);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SosAlertDetail implements SosAlertDetail {
  const _SosAlertDetail({required this.id, required this.tripId, required this.raisedRole, required this.raisedByName, required this.status, this.cancelWithoutPin = false, this.claimedBy, this.claimedByName, this.outcome, this.escalated = false, this.hasRecording = false, required this.createdAt, this.claimedAt, this.closedAt, this.lastLocation, @JsonKey(name: 'raised_by_phone_e164') this.raisedByPhone = '', final  List<EmergencyContact> emergencyContacts = const [], required this.trip, required this.passenger, required this.driver, final  List<SosLocation> track = const [], final  List<SosNote> notes = const [], final  List<String> relatedAlertIds = const [], this.recordingUrl, this.raisedByAlerts = 0, this.raisedByFalseAlarms = 0}): _emergencyContacts = emergencyContacts,_track = track,_notes = notes,_relatedAlertIds = relatedAlertIds;
  factory _SosAlertDetail.fromJson(Map<String, dynamic> json) => _$SosAlertDetailFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  SosRole raisedRole;
@override final  String raisedByName;
@override final  SosStatus status;
@override@JsonKey() final  bool cancelWithoutPin;
@override final  String? claimedBy;
@override final  String? claimedByName;
@override final  SosOutcome? outcome;
@override@JsonKey() final  bool escalated;
@override@JsonKey() final  bool hasRecording;
@override final  DateTime createdAt;
@override final  DateTime? claimedAt;
@override final  DateTime? closedAt;
@override final  SosLocation? lastLocation;
@override@JsonKey(name: 'raised_by_phone_e164') final  String raisedByPhone;
 final  List<EmergencyContact> _emergencyContacts;
@override@JsonKey() List<EmergencyContact> get emergencyContacts {
  if (_emergencyContacts is EqualUnmodifiableListView) return _emergencyContacts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_emergencyContacts);
}

@override final  SosTrip trip;
@override final  SosPerson passenger;
@override final  SosDriver driver;
 final  List<SosLocation> _track;
@override@JsonKey() List<SosLocation> get track {
  if (_track is EqualUnmodifiableListView) return _track;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_track);
}

 final  List<SosNote> _notes;
@override@JsonKey() List<SosNote> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}

 final  List<String> _relatedAlertIds;
@override@JsonKey() List<String> get relatedAlertIds {
  if (_relatedAlertIds is EqualUnmodifiableListView) return _relatedAlertIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relatedAlertIds);
}

@override final  String? recordingUrl;
@override@JsonKey() final  int raisedByAlerts;
@override@JsonKey() final  int raisedByFalseAlarms;

/// Create a copy of SosAlertDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SosAlertDetailCopyWith<_SosAlertDetail> get copyWith => __$SosAlertDetailCopyWithImpl<_SosAlertDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SosAlertDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SosAlertDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.raisedRole, raisedRole) || other.raisedRole == raisedRole)&&(identical(other.raisedByName, raisedByName) || other.raisedByName == raisedByName)&&(identical(other.status, status) || other.status == status)&&(identical(other.cancelWithoutPin, cancelWithoutPin) || other.cancelWithoutPin == cancelWithoutPin)&&(identical(other.claimedBy, claimedBy) || other.claimedBy == claimedBy)&&(identical(other.claimedByName, claimedByName) || other.claimedByName == claimedByName)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.escalated, escalated) || other.escalated == escalated)&&(identical(other.hasRecording, hasRecording) || other.hasRecording == hasRecording)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.claimedAt, claimedAt) || other.claimedAt == claimedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.lastLocation, lastLocation) || other.lastLocation == lastLocation)&&(identical(other.raisedByPhone, raisedByPhone) || other.raisedByPhone == raisedByPhone)&&const DeepCollectionEquality().equals(other._emergencyContacts, _emergencyContacts)&&(identical(other.trip, trip) || other.trip == trip)&&(identical(other.passenger, passenger) || other.passenger == passenger)&&(identical(other.driver, driver) || other.driver == driver)&&const DeepCollectionEquality().equals(other._track, _track)&&const DeepCollectionEquality().equals(other._notes, _notes)&&const DeepCollectionEquality().equals(other._relatedAlertIds, _relatedAlertIds)&&(identical(other.recordingUrl, recordingUrl) || other.recordingUrl == recordingUrl)&&(identical(other.raisedByAlerts, raisedByAlerts) || other.raisedByAlerts == raisedByAlerts)&&(identical(other.raisedByFalseAlarms, raisedByFalseAlarms) || other.raisedByFalseAlarms == raisedByFalseAlarms));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,tripId,raisedRole,raisedByName,status,cancelWithoutPin,claimedBy,claimedByName,outcome,escalated,hasRecording,createdAt,claimedAt,closedAt,lastLocation,raisedByPhone,const DeepCollectionEquality().hash(_emergencyContacts),trip,passenger,driver,const DeepCollectionEquality().hash(_track),const DeepCollectionEquality().hash(_notes),const DeepCollectionEquality().hash(_relatedAlertIds),recordingUrl,raisedByAlerts,raisedByFalseAlarms]);

@override
String toString() {
  return 'SosAlertDetail(id: $id, tripId: $tripId, raisedRole: $raisedRole, raisedByName: $raisedByName, status: $status, cancelWithoutPin: $cancelWithoutPin, claimedBy: $claimedBy, claimedByName: $claimedByName, outcome: $outcome, escalated: $escalated, hasRecording: $hasRecording, createdAt: $createdAt, claimedAt: $claimedAt, closedAt: $closedAt, lastLocation: $lastLocation, raisedByPhone: $raisedByPhone, emergencyContacts: $emergencyContacts, trip: $trip, passenger: $passenger, driver: $driver, track: $track, notes: $notes, relatedAlertIds: $relatedAlertIds, recordingUrl: $recordingUrl, raisedByAlerts: $raisedByAlerts, raisedByFalseAlarms: $raisedByFalseAlarms)';
}


}

/// @nodoc
abstract mixin class _$SosAlertDetailCopyWith<$Res> implements $SosAlertDetailCopyWith<$Res> {
  factory _$SosAlertDetailCopyWith(_SosAlertDetail value, $Res Function(_SosAlertDetail) _then) = __$SosAlertDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, SosRole raisedRole, String raisedByName, SosStatus status, bool cancelWithoutPin, String? claimedBy, String? claimedByName, SosOutcome? outcome, bool escalated, bool hasRecording, DateTime createdAt, DateTime? claimedAt, DateTime? closedAt, SosLocation? lastLocation,@JsonKey(name: 'raised_by_phone_e164') String raisedByPhone, List<EmergencyContact> emergencyContacts, SosTrip trip, SosPerson passenger, SosDriver driver, List<SosLocation> track, List<SosNote> notes, List<String> relatedAlertIds, String? recordingUrl, int raisedByAlerts, int raisedByFalseAlarms
});


@override $SosLocationCopyWith<$Res>? get lastLocation;@override $SosTripCopyWith<$Res> get trip;@override $SosPersonCopyWith<$Res> get passenger;@override $SosDriverCopyWith<$Res> get driver;

}
/// @nodoc
class __$SosAlertDetailCopyWithImpl<$Res>
    implements _$SosAlertDetailCopyWith<$Res> {
  __$SosAlertDetailCopyWithImpl(this._self, this._then);

  final _SosAlertDetail _self;
  final $Res Function(_SosAlertDetail) _then;

/// Create a copy of SosAlertDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? raisedRole = null,Object? raisedByName = null,Object? status = null,Object? cancelWithoutPin = null,Object? claimedBy = freezed,Object? claimedByName = freezed,Object? outcome = freezed,Object? escalated = null,Object? hasRecording = null,Object? createdAt = null,Object? claimedAt = freezed,Object? closedAt = freezed,Object? lastLocation = freezed,Object? raisedByPhone = null,Object? emergencyContacts = null,Object? trip = null,Object? passenger = null,Object? driver = null,Object? track = null,Object? notes = null,Object? relatedAlertIds = null,Object? recordingUrl = freezed,Object? raisedByAlerts = null,Object? raisedByFalseAlarms = null,}) {
  return _then(_SosAlertDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,raisedRole: null == raisedRole ? _self.raisedRole : raisedRole // ignore: cast_nullable_to_non_nullable
as SosRole,raisedByName: null == raisedByName ? _self.raisedByName : raisedByName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SosStatus,cancelWithoutPin: null == cancelWithoutPin ? _self.cancelWithoutPin : cancelWithoutPin // ignore: cast_nullable_to_non_nullable
as bool,claimedBy: freezed == claimedBy ? _self.claimedBy : claimedBy // ignore: cast_nullable_to_non_nullable
as String?,claimedByName: freezed == claimedByName ? _self.claimedByName : claimedByName // ignore: cast_nullable_to_non_nullable
as String?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as SosOutcome?,escalated: null == escalated ? _self.escalated : escalated // ignore: cast_nullable_to_non_nullable
as bool,hasRecording: null == hasRecording ? _self.hasRecording : hasRecording // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,claimedAt: freezed == claimedAt ? _self.claimedAt : claimedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastLocation: freezed == lastLocation ? _self.lastLocation : lastLocation // ignore: cast_nullable_to_non_nullable
as SosLocation?,raisedByPhone: null == raisedByPhone ? _self.raisedByPhone : raisedByPhone // ignore: cast_nullable_to_non_nullable
as String,emergencyContacts: null == emergencyContacts ? _self._emergencyContacts : emergencyContacts // ignore: cast_nullable_to_non_nullable
as List<EmergencyContact>,trip: null == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as SosTrip,passenger: null == passenger ? _self.passenger : passenger // ignore: cast_nullable_to_non_nullable
as SosPerson,driver: null == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as SosDriver,track: null == track ? _self._track : track // ignore: cast_nullable_to_non_nullable
as List<SosLocation>,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<SosNote>,relatedAlertIds: null == relatedAlertIds ? _self._relatedAlertIds : relatedAlertIds // ignore: cast_nullable_to_non_nullable
as List<String>,recordingUrl: freezed == recordingUrl ? _self.recordingUrl : recordingUrl // ignore: cast_nullable_to_non_nullable
as String?,raisedByAlerts: null == raisedByAlerts ? _self.raisedByAlerts : raisedByAlerts // ignore: cast_nullable_to_non_nullable
as int,raisedByFalseAlarms: null == raisedByFalseAlarms ? _self.raisedByFalseAlarms : raisedByFalseAlarms // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of SosAlertDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosLocationCopyWith<$Res>? get lastLocation {
    if (_self.lastLocation == null) {
    return null;
  }

  return $SosLocationCopyWith<$Res>(_self.lastLocation!, (value) {
    return _then(_self.copyWith(lastLocation: value));
  });
}/// Create a copy of SosAlertDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosTripCopyWith<$Res> get trip {
  
  return $SosTripCopyWith<$Res>(_self.trip, (value) {
    return _then(_self.copyWith(trip: value));
  });
}/// Create a copy of SosAlertDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosPersonCopyWith<$Res> get passenger {
  
  return $SosPersonCopyWith<$Res>(_self.passenger, (value) {
    return _then(_self.copyWith(passenger: value));
  });
}/// Create a copy of SosAlertDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SosDriverCopyWith<$Res> get driver {
  
  return $SosDriverCopyWith<$Res>(_self.driver, (value) {
    return _then(_self.copyWith(driver: value));
  });
}
}


/// @nodoc
mixin _$ShareLink {

 String get token; String get url;
/// Create a copy of ShareLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShareLinkCopyWith<ShareLink> get copyWith => _$ShareLinkCopyWithImpl<ShareLink>(this as ShareLink, _$identity);

  /// Serializes this ShareLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShareLink&&(identical(other.token, token) || other.token == token)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,url);

@override
String toString() {
  return 'ShareLink(token: $token, url: $url)';
}


}

/// @nodoc
abstract mixin class $ShareLinkCopyWith<$Res>  {
  factory $ShareLinkCopyWith(ShareLink value, $Res Function(ShareLink) _then) = _$ShareLinkCopyWithImpl;
@useResult
$Res call({
 String token, String url
});




}
/// @nodoc
class _$ShareLinkCopyWithImpl<$Res>
    implements $ShareLinkCopyWith<$Res> {
  _$ShareLinkCopyWithImpl(this._self, this._then);

  final ShareLink _self;
  final $Res Function(ShareLink) _then;

/// Create a copy of ShareLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? url = null,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ShareLink].
extension ShareLinkPatterns on ShareLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShareLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShareLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShareLink value)  $default,){
final _that = this;
switch (_that) {
case _ShareLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShareLink value)?  $default,){
final _that = this;
switch (_that) {
case _ShareLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShareLink() when $default != null:
return $default(_that.token,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  String url)  $default,) {final _that = this;
switch (_that) {
case _ShareLink():
return $default(_that.token,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  String url)?  $default,) {final _that = this;
switch (_that) {
case _ShareLink() when $default != null:
return $default(_that.token,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShareLink implements ShareLink {
  const _ShareLink({required this.token, required this.url});
  factory _ShareLink.fromJson(Map<String, dynamic> json) => _$ShareLinkFromJson(json);

@override final  String token;
@override final  String url;

/// Create a copy of ShareLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShareLinkCopyWith<_ShareLink> get copyWith => __$ShareLinkCopyWithImpl<_ShareLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShareLinkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShareLink&&(identical(other.token, token) || other.token == token)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,url);

@override
String toString() {
  return 'ShareLink(token: $token, url: $url)';
}


}

/// @nodoc
abstract mixin class _$ShareLinkCopyWith<$Res> implements $ShareLinkCopyWith<$Res> {
  factory _$ShareLinkCopyWith(_ShareLink value, $Res Function(_ShareLink) _then) = __$ShareLinkCopyWithImpl;
@override @useResult
$Res call({
 String token, String url
});




}
/// @nodoc
class __$ShareLinkCopyWithImpl<$Res>
    implements _$ShareLinkCopyWith<$Res> {
  __$ShareLinkCopyWithImpl(this._self, this._then);

  final _ShareLink _self;
  final $Res Function(_ShareLink) _then;

/// Create a copy of ShareLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? url = null,}) {
  return _then(_ShareLink(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
