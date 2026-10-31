// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ops_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PersonRef {

 String get id; String get displayName;
/// Create a copy of PersonRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonRefCopyWith<PersonRef> get copyWith => _$PersonRefCopyWithImpl<PersonRef>(this as PersonRef, _$identity);

  /// Serializes this PersonRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonRef&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName);

@override
String toString() {
  return 'PersonRef(id: $id, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $PersonRefCopyWith<$Res>  {
  factory $PersonRefCopyWith(PersonRef value, $Res Function(PersonRef) _then) = _$PersonRefCopyWithImpl;
@useResult
$Res call({
 String id, String displayName
});




}
/// @nodoc
class _$PersonRefCopyWithImpl<$Res>
    implements $PersonRefCopyWith<$Res> {
  _$PersonRefCopyWithImpl(this._self, this._then);

  final PersonRef _self;
  final $Res Function(PersonRef) _then;

/// Create a copy of PersonRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonRef].
extension PersonRefPatterns on PersonRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonRef value)  $default,){
final _that = this;
switch (_that) {
case _PersonRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonRef value)?  $default,){
final _that = this;
switch (_that) {
case _PersonRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonRef() when $default != null:
return $default(_that.id,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName)  $default,) {final _that = this;
switch (_that) {
case _PersonRef():
return $default(_that.id,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName)?  $default,) {final _that = this;
switch (_that) {
case _PersonRef() when $default != null:
return $default(_that.id,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonRef implements PersonRef {
  const _PersonRef({required this.id, required this.displayName});
  factory _PersonRef.fromJson(Map<String, dynamic> json) => _$PersonRefFromJson(json);

@override final  String id;
@override final  String displayName;

/// Create a copy of PersonRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonRefCopyWith<_PersonRef> get copyWith => __$PersonRefCopyWithImpl<_PersonRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonRef&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName);

@override
String toString() {
  return 'PersonRef(id: $id, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$PersonRefCopyWith<$Res> implements $PersonRefCopyWith<$Res> {
  factory _$PersonRefCopyWith(_PersonRef value, $Res Function(_PersonRef) _then) = __$PersonRefCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName
});




}
/// @nodoc
class __$PersonRefCopyWithImpl<$Res>
    implements _$PersonRefCopyWith<$Res> {
  __$PersonRefCopyWithImpl(this._self, this._then);

  final _PersonRef _self;
  final $Res Function(_PersonRef) _then;

/// Create a copy of PersonRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,}) {
  return _then(_PersonRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TripStep {

 String get status; DateTime get at;
/// Create a copy of TripStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripStepCopyWith<TripStep> get copyWith => _$TripStepCopyWithImpl<TripStep>(this as TripStep, _$identity);

  /// Serializes this TripStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripStep&&(identical(other.status, status) || other.status == status)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,at);

@override
String toString() {
  return 'TripStep(status: $status, at: $at)';
}


}

/// @nodoc
abstract mixin class $TripStepCopyWith<$Res>  {
  factory $TripStepCopyWith(TripStep value, $Res Function(TripStep) _then) = _$TripStepCopyWithImpl;
@useResult
$Res call({
 String status, DateTime at
});




}
/// @nodoc
class _$TripStepCopyWithImpl<$Res>
    implements $TripStepCopyWith<$Res> {
  _$TripStepCopyWithImpl(this._self, this._then);

  final TripStep _self;
  final $Res Function(TripStep) _then;

/// Create a copy of TripStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? at = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TripStep].
extension TripStepPatterns on TripStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripStep value)  $default,){
final _that = this;
switch (_that) {
case _TripStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripStep value)?  $default,){
final _that = this;
switch (_that) {
case _TripStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  DateTime at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripStep() when $default != null:
return $default(_that.status,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  DateTime at)  $default,) {final _that = this;
switch (_that) {
case _TripStep():
return $default(_that.status,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  DateTime at)?  $default,) {final _that = this;
switch (_that) {
case _TripStep() when $default != null:
return $default(_that.status,_that.at);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripStep implements TripStep {
  const _TripStep({required this.status, required this.at});
  factory _TripStep.fromJson(Map<String, dynamic> json) => _$TripStepFromJson(json);

@override final  String status;
@override final  DateTime at;

/// Create a copy of TripStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripStepCopyWith<_TripStep> get copyWith => __$TripStepCopyWithImpl<_TripStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripStep&&(identical(other.status, status) || other.status == status)&&(identical(other.at, at) || other.at == at));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,at);

@override
String toString() {
  return 'TripStep(status: $status, at: $at)';
}


}

/// @nodoc
abstract mixin class _$TripStepCopyWith<$Res> implements $TripStepCopyWith<$Res> {
  factory _$TripStepCopyWith(_TripStep value, $Res Function(_TripStep) _then) = __$TripStepCopyWithImpl;
@override @useResult
$Res call({
 String status, DateTime at
});




}
/// @nodoc
class __$TripStepCopyWithImpl<$Res>
    implements _$TripStepCopyWith<$Res> {
  __$TripStepCopyWithImpl(this._self, this._then);

  final _TripStep _self;
  final $Res Function(_TripStep) _then;

/// Create a copy of TripStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? at = null,}) {
  return _then(_TripStep(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$InspectionPosition {

 double get lat; double get lng; DateTime get locationAt; bool get stale;
/// Create a copy of InspectionPosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InspectionPositionCopyWith<InspectionPosition> get copyWith => _$InspectionPositionCopyWithImpl<InspectionPosition>(this as InspectionPosition, _$identity);

  /// Serializes this InspectionPosition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InspectionPosition&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.locationAt, locationAt) || other.locationAt == locationAt)&&(identical(other.stale, stale) || other.stale == stale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,locationAt,stale);

@override
String toString() {
  return 'InspectionPosition(lat: $lat, lng: $lng, locationAt: $locationAt, stale: $stale)';
}


}

/// @nodoc
abstract mixin class $InspectionPositionCopyWith<$Res>  {
  factory $InspectionPositionCopyWith(InspectionPosition value, $Res Function(InspectionPosition) _then) = _$InspectionPositionCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, DateTime locationAt, bool stale
});




}
/// @nodoc
class _$InspectionPositionCopyWithImpl<$Res>
    implements $InspectionPositionCopyWith<$Res> {
  _$InspectionPositionCopyWithImpl(this._self, this._then);

  final InspectionPosition _self;
  final $Res Function(InspectionPosition) _then;

/// Create a copy of InspectionPosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? locationAt = null,Object? stale = null,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,locationAt: null == locationAt ? _self.locationAt : locationAt // ignore: cast_nullable_to_non_nullable
as DateTime,stale: null == stale ? _self.stale : stale // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [InspectionPosition].
extension InspectionPositionPatterns on InspectionPosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InspectionPosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InspectionPosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InspectionPosition value)  $default,){
final _that = this;
switch (_that) {
case _InspectionPosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InspectionPosition value)?  $default,){
final _that = this;
switch (_that) {
case _InspectionPosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng,  DateTime locationAt,  bool stale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InspectionPosition() when $default != null:
return $default(_that.lat,_that.lng,_that.locationAt,_that.stale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng,  DateTime locationAt,  bool stale)  $default,) {final _that = this;
switch (_that) {
case _InspectionPosition():
return $default(_that.lat,_that.lng,_that.locationAt,_that.stale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng,  DateTime locationAt,  bool stale)?  $default,) {final _that = this;
switch (_that) {
case _InspectionPosition() when $default != null:
return $default(_that.lat,_that.lng,_that.locationAt,_that.stale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InspectionPosition implements InspectionPosition {
  const _InspectionPosition({required this.lat, required this.lng, required this.locationAt, this.stale = false});
  factory _InspectionPosition.fromJson(Map<String, dynamic> json) => _$InspectionPositionFromJson(json);

@override final  double lat;
@override final  double lng;
@override final  DateTime locationAt;
@override@JsonKey() final  bool stale;

/// Create a copy of InspectionPosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InspectionPositionCopyWith<_InspectionPosition> get copyWith => __$InspectionPositionCopyWithImpl<_InspectionPosition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InspectionPositionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InspectionPosition&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.locationAt, locationAt) || other.locationAt == locationAt)&&(identical(other.stale, stale) || other.stale == stale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,locationAt,stale);

@override
String toString() {
  return 'InspectionPosition(lat: $lat, lng: $lng, locationAt: $locationAt, stale: $stale)';
}


}

/// @nodoc
abstract mixin class _$InspectionPositionCopyWith<$Res> implements $InspectionPositionCopyWith<$Res> {
  factory _$InspectionPositionCopyWith(_InspectionPosition value, $Res Function(_InspectionPosition) _then) = __$InspectionPositionCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng, DateTime locationAt, bool stale
});




}
/// @nodoc
class __$InspectionPositionCopyWithImpl<$Res>
    implements _$InspectionPositionCopyWith<$Res> {
  __$InspectionPositionCopyWithImpl(this._self, this._then);

  final _InspectionPosition _self;
  final $Res Function(_InspectionPosition) _then;

/// Create a copy of InspectionPosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? locationAt = null,Object? stale = null,}) {
  return _then(_InspectionPosition(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,locationAt: null == locationAt ? _self.locationAt : locationAt // ignore: cast_nullable_to_non_nullable
as DateTime,stale: null == stale ? _self.stale : stale // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$InspectionPayment {

 String get status; String? get method;
/// Create a copy of InspectionPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InspectionPaymentCopyWith<InspectionPayment> get copyWith => _$InspectionPaymentCopyWithImpl<InspectionPayment>(this as InspectionPayment, _$identity);

  /// Serializes this InspectionPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InspectionPayment&&(identical(other.status, status) || other.status == status)&&(identical(other.method, method) || other.method == method));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,method);

@override
String toString() {
  return 'InspectionPayment(status: $status, method: $method)';
}


}

/// @nodoc
abstract mixin class $InspectionPaymentCopyWith<$Res>  {
  factory $InspectionPaymentCopyWith(InspectionPayment value, $Res Function(InspectionPayment) _then) = _$InspectionPaymentCopyWithImpl;
@useResult
$Res call({
 String status, String? method
});




}
/// @nodoc
class _$InspectionPaymentCopyWithImpl<$Res>
    implements $InspectionPaymentCopyWith<$Res> {
  _$InspectionPaymentCopyWithImpl(this._self, this._then);

  final InspectionPayment _self;
  final $Res Function(InspectionPayment) _then;

/// Create a copy of InspectionPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? method = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InspectionPayment].
extension InspectionPaymentPatterns on InspectionPayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InspectionPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InspectionPayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InspectionPayment value)  $default,){
final _that = this;
switch (_that) {
case _InspectionPayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InspectionPayment value)?  $default,){
final _that = this;
switch (_that) {
case _InspectionPayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String? method)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InspectionPayment() when $default != null:
return $default(_that.status,_that.method);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String? method)  $default,) {final _that = this;
switch (_that) {
case _InspectionPayment():
return $default(_that.status,_that.method);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String? method)?  $default,) {final _that = this;
switch (_that) {
case _InspectionPayment() when $default != null:
return $default(_that.status,_that.method);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InspectionPayment implements InspectionPayment {
  const _InspectionPayment({required this.status, this.method});
  factory _InspectionPayment.fromJson(Map<String, dynamic> json) => _$InspectionPaymentFromJson(json);

@override final  String status;
@override final  String? method;

/// Create a copy of InspectionPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InspectionPaymentCopyWith<_InspectionPayment> get copyWith => __$InspectionPaymentCopyWithImpl<_InspectionPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InspectionPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InspectionPayment&&(identical(other.status, status) || other.status == status)&&(identical(other.method, method) || other.method == method));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,method);

@override
String toString() {
  return 'InspectionPayment(status: $status, method: $method)';
}


}

/// @nodoc
abstract mixin class _$InspectionPaymentCopyWith<$Res> implements $InspectionPaymentCopyWith<$Res> {
  factory _$InspectionPaymentCopyWith(_InspectionPayment value, $Res Function(_InspectionPayment) _then) = __$InspectionPaymentCopyWithImpl;
@override @useResult
$Res call({
 String status, String? method
});




}
/// @nodoc
class __$InspectionPaymentCopyWithImpl<$Res>
    implements _$InspectionPaymentCopyWith<$Res> {
  __$InspectionPaymentCopyWithImpl(this._self, this._then);

  final _InspectionPayment _self;
  final $Res Function(_InspectionPayment) _then;

/// Create a copy of InspectionPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? method = freezed,}) {
  return _then(_InspectionPayment(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InspectionSos {

 String get id; String get status;
/// Create a copy of InspectionSos
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InspectionSosCopyWith<InspectionSos> get copyWith => _$InspectionSosCopyWithImpl<InspectionSos>(this as InspectionSos, _$identity);

  /// Serializes this InspectionSos to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InspectionSos&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status);

@override
String toString() {
  return 'InspectionSos(id: $id, status: $status)';
}


}

/// @nodoc
abstract mixin class $InspectionSosCopyWith<$Res>  {
  factory $InspectionSosCopyWith(InspectionSos value, $Res Function(InspectionSos) _then) = _$InspectionSosCopyWithImpl;
@useResult
$Res call({
 String id, String status
});




}
/// @nodoc
class _$InspectionSosCopyWithImpl<$Res>
    implements $InspectionSosCopyWith<$Res> {
  _$InspectionSosCopyWithImpl(this._self, this._then);

  final InspectionSos _self;
  final $Res Function(InspectionSos) _then;

/// Create a copy of InspectionSos
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InspectionSos].
extension InspectionSosPatterns on InspectionSos {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InspectionSos value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InspectionSos() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InspectionSos value)  $default,){
final _that = this;
switch (_that) {
case _InspectionSos():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InspectionSos value)?  $default,){
final _that = this;
switch (_that) {
case _InspectionSos() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InspectionSos() when $default != null:
return $default(_that.id,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String status)  $default,) {final _that = this;
switch (_that) {
case _InspectionSos():
return $default(_that.id,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String status)?  $default,) {final _that = this;
switch (_that) {
case _InspectionSos() when $default != null:
return $default(_that.id,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InspectionSos implements InspectionSos {
  const _InspectionSos({required this.id, required this.status});
  factory _InspectionSos.fromJson(Map<String, dynamic> json) => _$InspectionSosFromJson(json);

@override final  String id;
@override final  String status;

/// Create a copy of InspectionSos
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InspectionSosCopyWith<_InspectionSos> get copyWith => __$InspectionSosCopyWithImpl<_InspectionSos>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InspectionSosToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InspectionSos&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status);

@override
String toString() {
  return 'InspectionSos(id: $id, status: $status)';
}


}

/// @nodoc
abstract mixin class _$InspectionSosCopyWith<$Res> implements $InspectionSosCopyWith<$Res> {
  factory _$InspectionSosCopyWith(_InspectionSos value, $Res Function(_InspectionSos) _then) = __$InspectionSosCopyWithImpl;
@override @useResult
$Res call({
 String id, String status
});




}
/// @nodoc
class __$InspectionSosCopyWithImpl<$Res>
    implements _$InspectionSosCopyWith<$Res> {
  __$InspectionSosCopyWithImpl(this._self, this._then);

  final _InspectionSos _self;
  final $Res Function(_InspectionSos) _then;

/// Create a copy of InspectionSos
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,}) {
  return _then(_InspectionSos(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TripInspection {

 String get tripId; String get status; bool get active; String? get cancelReason; String get dispatch; int get handoverCount; String? get cooperativeName; PersonRef get passenger; PersonRef get driver; String get vehiclePlate; String get vehicleDescription; GeoPoint get pickup; GeoPoint get dropoff; int get distanceM; int get durationS; String get currency; int get listFareMinor; int get suggestedFareMinor; int? get agreedFareMinor; int get preferentialDiscountPct; List<TripStep> get steps; InspectionPosition? get driverPosition; InspectionPayment? get payment; InspectionSos? get openSos; DateTime get generatedAt;
/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripInspectionCopyWith<TripInspection> get copyWith => _$TripInspectionCopyWithImpl<TripInspection>(this as TripInspection, _$identity);

  /// Serializes this TripInspection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripInspection&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.status, status) || other.status == status)&&(identical(other.active, active) || other.active == active)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason)&&(identical(other.dispatch, dispatch) || other.dispatch == dispatch)&&(identical(other.handoverCount, handoverCount) || other.handoverCount == handoverCount)&&(identical(other.cooperativeName, cooperativeName) || other.cooperativeName == cooperativeName)&&(identical(other.passenger, passenger) || other.passenger == passenger)&&(identical(other.driver, driver) || other.driver == driver)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleDescription, vehicleDescription) || other.vehicleDescription == vehicleDescription)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.listFareMinor, listFareMinor) || other.listFareMinor == listFareMinor)&&(identical(other.suggestedFareMinor, suggestedFareMinor) || other.suggestedFareMinor == suggestedFareMinor)&&(identical(other.agreedFareMinor, agreedFareMinor) || other.agreedFareMinor == agreedFareMinor)&&(identical(other.preferentialDiscountPct, preferentialDiscountPct) || other.preferentialDiscountPct == preferentialDiscountPct)&&const DeepCollectionEquality().equals(other.steps, steps)&&(identical(other.driverPosition, driverPosition) || other.driverPosition == driverPosition)&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.openSos, openSos) || other.openSos == openSos)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,tripId,status,active,cancelReason,dispatch,handoverCount,cooperativeName,passenger,driver,vehiclePlate,vehicleDescription,pickup,dropoff,distanceM,durationS,currency,listFareMinor,suggestedFareMinor,agreedFareMinor,preferentialDiscountPct,const DeepCollectionEquality().hash(steps),driverPosition,payment,openSos,generatedAt]);

@override
String toString() {
  return 'TripInspection(tripId: $tripId, status: $status, active: $active, cancelReason: $cancelReason, dispatch: $dispatch, handoverCount: $handoverCount, cooperativeName: $cooperativeName, passenger: $passenger, driver: $driver, vehiclePlate: $vehiclePlate, vehicleDescription: $vehicleDescription, pickup: $pickup, dropoff: $dropoff, distanceM: $distanceM, durationS: $durationS, currency: $currency, listFareMinor: $listFareMinor, suggestedFareMinor: $suggestedFareMinor, agreedFareMinor: $agreedFareMinor, preferentialDiscountPct: $preferentialDiscountPct, steps: $steps, driverPosition: $driverPosition, payment: $payment, openSos: $openSos, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class $TripInspectionCopyWith<$Res>  {
  factory $TripInspectionCopyWith(TripInspection value, $Res Function(TripInspection) _then) = _$TripInspectionCopyWithImpl;
@useResult
$Res call({
 String tripId, String status, bool active, String? cancelReason, String dispatch, int handoverCount, String? cooperativeName, PersonRef passenger, PersonRef driver, String vehiclePlate, String vehicleDescription, GeoPoint pickup, GeoPoint dropoff, int distanceM, int durationS, String currency, int listFareMinor, int suggestedFareMinor, int? agreedFareMinor, int preferentialDiscountPct, List<TripStep> steps, InspectionPosition? driverPosition, InspectionPayment? payment, InspectionSos? openSos, DateTime generatedAt
});


$PersonRefCopyWith<$Res> get passenger;$PersonRefCopyWith<$Res> get driver;$GeoPointCopyWith<$Res> get pickup;$GeoPointCopyWith<$Res> get dropoff;$InspectionPositionCopyWith<$Res>? get driverPosition;$InspectionPaymentCopyWith<$Res>? get payment;$InspectionSosCopyWith<$Res>? get openSos;

}
/// @nodoc
class _$TripInspectionCopyWithImpl<$Res>
    implements $TripInspectionCopyWith<$Res> {
  _$TripInspectionCopyWithImpl(this._self, this._then);

  final TripInspection _self;
  final $Res Function(TripInspection) _then;

/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tripId = null,Object? status = null,Object? active = null,Object? cancelReason = freezed,Object? dispatch = null,Object? handoverCount = null,Object? cooperativeName = freezed,Object? passenger = null,Object? driver = null,Object? vehiclePlate = null,Object? vehicleDescription = null,Object? pickup = null,Object? dropoff = null,Object? distanceM = null,Object? durationS = null,Object? currency = null,Object? listFareMinor = null,Object? suggestedFareMinor = null,Object? agreedFareMinor = freezed,Object? preferentialDiscountPct = null,Object? steps = null,Object? driverPosition = freezed,Object? payment = freezed,Object? openSos = freezed,Object? generatedAt = null,}) {
  return _then(_self.copyWith(
tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,dispatch: null == dispatch ? _self.dispatch : dispatch // ignore: cast_nullable_to_non_nullable
as String,handoverCount: null == handoverCount ? _self.handoverCount : handoverCount // ignore: cast_nullable_to_non_nullable
as int,cooperativeName: freezed == cooperativeName ? _self.cooperativeName : cooperativeName // ignore: cast_nullable_to_non_nullable
as String?,passenger: null == passenger ? _self.passenger : passenger // ignore: cast_nullable_to_non_nullable
as PersonRef,driver: null == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as PersonRef,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,vehicleDescription: null == vehicleDescription ? _self.vehicleDescription : vehicleDescription // ignore: cast_nullable_to_non_nullable
as String,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as GeoPoint,distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int,durationS: null == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,listFareMinor: null == listFareMinor ? _self.listFareMinor : listFareMinor // ignore: cast_nullable_to_non_nullable
as int,suggestedFareMinor: null == suggestedFareMinor ? _self.suggestedFareMinor : suggestedFareMinor // ignore: cast_nullable_to_non_nullable
as int,agreedFareMinor: freezed == agreedFareMinor ? _self.agreedFareMinor : agreedFareMinor // ignore: cast_nullable_to_non_nullable
as int?,preferentialDiscountPct: null == preferentialDiscountPct ? _self.preferentialDiscountPct : preferentialDiscountPct // ignore: cast_nullable_to_non_nullable
as int,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<TripStep>,driverPosition: freezed == driverPosition ? _self.driverPosition : driverPosition // ignore: cast_nullable_to_non_nullable
as InspectionPosition?,payment: freezed == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as InspectionPayment?,openSos: freezed == openSos ? _self.openSos : openSos // ignore: cast_nullable_to_non_nullable
as InspectionSos?,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res> get passenger {
  
  return $PersonRefCopyWith<$Res>(_self.passenger, (value) {
    return _then(_self.copyWith(passenger: value));
  });
}/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res> get driver {
  
  return $PersonRefCopyWith<$Res>(_self.driver, (value) {
    return _then(_self.copyWith(driver: value));
  });
}/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get pickup {
  
  return $GeoPointCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get dropoff {
  
  return $GeoPointCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InspectionPositionCopyWith<$Res>? get driverPosition {
    if (_self.driverPosition == null) {
    return null;
  }

  return $InspectionPositionCopyWith<$Res>(_self.driverPosition!, (value) {
    return _then(_self.copyWith(driverPosition: value));
  });
}/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InspectionPaymentCopyWith<$Res>? get payment {
    if (_self.payment == null) {
    return null;
  }

  return $InspectionPaymentCopyWith<$Res>(_self.payment!, (value) {
    return _then(_self.copyWith(payment: value));
  });
}/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InspectionSosCopyWith<$Res>? get openSos {
    if (_self.openSos == null) {
    return null;
  }

  return $InspectionSosCopyWith<$Res>(_self.openSos!, (value) {
    return _then(_self.copyWith(openSos: value));
  });
}
}


/// Adds pattern-matching-related methods to [TripInspection].
extension TripInspectionPatterns on TripInspection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripInspection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripInspection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripInspection value)  $default,){
final _that = this;
switch (_that) {
case _TripInspection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripInspection value)?  $default,){
final _that = this;
switch (_that) {
case _TripInspection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tripId,  String status,  bool active,  String? cancelReason,  String dispatch,  int handoverCount,  String? cooperativeName,  PersonRef passenger,  PersonRef driver,  String vehiclePlate,  String vehicleDescription,  GeoPoint pickup,  GeoPoint dropoff,  int distanceM,  int durationS,  String currency,  int listFareMinor,  int suggestedFareMinor,  int? agreedFareMinor,  int preferentialDiscountPct,  List<TripStep> steps,  InspectionPosition? driverPosition,  InspectionPayment? payment,  InspectionSos? openSos,  DateTime generatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripInspection() when $default != null:
return $default(_that.tripId,_that.status,_that.active,_that.cancelReason,_that.dispatch,_that.handoverCount,_that.cooperativeName,_that.passenger,_that.driver,_that.vehiclePlate,_that.vehicleDescription,_that.pickup,_that.dropoff,_that.distanceM,_that.durationS,_that.currency,_that.listFareMinor,_that.suggestedFareMinor,_that.agreedFareMinor,_that.preferentialDiscountPct,_that.steps,_that.driverPosition,_that.payment,_that.openSos,_that.generatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tripId,  String status,  bool active,  String? cancelReason,  String dispatch,  int handoverCount,  String? cooperativeName,  PersonRef passenger,  PersonRef driver,  String vehiclePlate,  String vehicleDescription,  GeoPoint pickup,  GeoPoint dropoff,  int distanceM,  int durationS,  String currency,  int listFareMinor,  int suggestedFareMinor,  int? agreedFareMinor,  int preferentialDiscountPct,  List<TripStep> steps,  InspectionPosition? driverPosition,  InspectionPayment? payment,  InspectionSos? openSos,  DateTime generatedAt)  $default,) {final _that = this;
switch (_that) {
case _TripInspection():
return $default(_that.tripId,_that.status,_that.active,_that.cancelReason,_that.dispatch,_that.handoverCount,_that.cooperativeName,_that.passenger,_that.driver,_that.vehiclePlate,_that.vehicleDescription,_that.pickup,_that.dropoff,_that.distanceM,_that.durationS,_that.currency,_that.listFareMinor,_that.suggestedFareMinor,_that.agreedFareMinor,_that.preferentialDiscountPct,_that.steps,_that.driverPosition,_that.payment,_that.openSos,_that.generatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tripId,  String status,  bool active,  String? cancelReason,  String dispatch,  int handoverCount,  String? cooperativeName,  PersonRef passenger,  PersonRef driver,  String vehiclePlate,  String vehicleDescription,  GeoPoint pickup,  GeoPoint dropoff,  int distanceM,  int durationS,  String currency,  int listFareMinor,  int suggestedFareMinor,  int? agreedFareMinor,  int preferentialDiscountPct,  List<TripStep> steps,  InspectionPosition? driverPosition,  InspectionPayment? payment,  InspectionSos? openSos,  DateTime generatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TripInspection() when $default != null:
return $default(_that.tripId,_that.status,_that.active,_that.cancelReason,_that.dispatch,_that.handoverCount,_that.cooperativeName,_that.passenger,_that.driver,_that.vehiclePlate,_that.vehicleDescription,_that.pickup,_that.dropoff,_that.distanceM,_that.durationS,_that.currency,_that.listFareMinor,_that.suggestedFareMinor,_that.agreedFareMinor,_that.preferentialDiscountPct,_that.steps,_that.driverPosition,_that.payment,_that.openSos,_that.generatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripInspection implements TripInspection {
  const _TripInspection({required this.tripId, required this.status, required this.active, this.cancelReason, required this.dispatch, this.handoverCount = 0, this.cooperativeName, required this.passenger, required this.driver, required this.vehiclePlate, this.vehicleDescription = '', required this.pickup, required this.dropoff, required this.distanceM, required this.durationS, required this.currency, required this.listFareMinor, required this.suggestedFareMinor, this.agreedFareMinor, this.preferentialDiscountPct = 0, final  List<TripStep> steps = const <TripStep>[], this.driverPosition, this.payment, this.openSos, required this.generatedAt}): _steps = steps;
  factory _TripInspection.fromJson(Map<String, dynamic> json) => _$TripInspectionFromJson(json);

@override final  String tripId;
@override final  String status;
@override final  bool active;
@override final  String? cancelReason;
@override final  String dispatch;
@override@JsonKey() final  int handoverCount;
@override final  String? cooperativeName;
@override final  PersonRef passenger;
@override final  PersonRef driver;
@override final  String vehiclePlate;
@override@JsonKey() final  String vehicleDescription;
@override final  GeoPoint pickup;
@override final  GeoPoint dropoff;
@override final  int distanceM;
@override final  int durationS;
@override final  String currency;
@override final  int listFareMinor;
@override final  int suggestedFareMinor;
@override final  int? agreedFareMinor;
@override@JsonKey() final  int preferentialDiscountPct;
 final  List<TripStep> _steps;
@override@JsonKey() List<TripStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override final  InspectionPosition? driverPosition;
@override final  InspectionPayment? payment;
@override final  InspectionSos? openSos;
@override final  DateTime generatedAt;

/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripInspectionCopyWith<_TripInspection> get copyWith => __$TripInspectionCopyWithImpl<_TripInspection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripInspectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripInspection&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.status, status) || other.status == status)&&(identical(other.active, active) || other.active == active)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason)&&(identical(other.dispatch, dispatch) || other.dispatch == dispatch)&&(identical(other.handoverCount, handoverCount) || other.handoverCount == handoverCount)&&(identical(other.cooperativeName, cooperativeName) || other.cooperativeName == cooperativeName)&&(identical(other.passenger, passenger) || other.passenger == passenger)&&(identical(other.driver, driver) || other.driver == driver)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleDescription, vehicleDescription) || other.vehicleDescription == vehicleDescription)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.listFareMinor, listFareMinor) || other.listFareMinor == listFareMinor)&&(identical(other.suggestedFareMinor, suggestedFareMinor) || other.suggestedFareMinor == suggestedFareMinor)&&(identical(other.agreedFareMinor, agreedFareMinor) || other.agreedFareMinor == agreedFareMinor)&&(identical(other.preferentialDiscountPct, preferentialDiscountPct) || other.preferentialDiscountPct == preferentialDiscountPct)&&const DeepCollectionEquality().equals(other._steps, _steps)&&(identical(other.driverPosition, driverPosition) || other.driverPosition == driverPosition)&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.openSos, openSos) || other.openSos == openSos)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,tripId,status,active,cancelReason,dispatch,handoverCount,cooperativeName,passenger,driver,vehiclePlate,vehicleDescription,pickup,dropoff,distanceM,durationS,currency,listFareMinor,suggestedFareMinor,agreedFareMinor,preferentialDiscountPct,const DeepCollectionEquality().hash(_steps),driverPosition,payment,openSos,generatedAt]);

@override
String toString() {
  return 'TripInspection(tripId: $tripId, status: $status, active: $active, cancelReason: $cancelReason, dispatch: $dispatch, handoverCount: $handoverCount, cooperativeName: $cooperativeName, passenger: $passenger, driver: $driver, vehiclePlate: $vehiclePlate, vehicleDescription: $vehicleDescription, pickup: $pickup, dropoff: $dropoff, distanceM: $distanceM, durationS: $durationS, currency: $currency, listFareMinor: $listFareMinor, suggestedFareMinor: $suggestedFareMinor, agreedFareMinor: $agreedFareMinor, preferentialDiscountPct: $preferentialDiscountPct, steps: $steps, driverPosition: $driverPosition, payment: $payment, openSos: $openSos, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class _$TripInspectionCopyWith<$Res> implements $TripInspectionCopyWith<$Res> {
  factory _$TripInspectionCopyWith(_TripInspection value, $Res Function(_TripInspection) _then) = __$TripInspectionCopyWithImpl;
@override @useResult
$Res call({
 String tripId, String status, bool active, String? cancelReason, String dispatch, int handoverCount, String? cooperativeName, PersonRef passenger, PersonRef driver, String vehiclePlate, String vehicleDescription, GeoPoint pickup, GeoPoint dropoff, int distanceM, int durationS, String currency, int listFareMinor, int suggestedFareMinor, int? agreedFareMinor, int preferentialDiscountPct, List<TripStep> steps, InspectionPosition? driverPosition, InspectionPayment? payment, InspectionSos? openSos, DateTime generatedAt
});


@override $PersonRefCopyWith<$Res> get passenger;@override $PersonRefCopyWith<$Res> get driver;@override $GeoPointCopyWith<$Res> get pickup;@override $GeoPointCopyWith<$Res> get dropoff;@override $InspectionPositionCopyWith<$Res>? get driverPosition;@override $InspectionPaymentCopyWith<$Res>? get payment;@override $InspectionSosCopyWith<$Res>? get openSos;

}
/// @nodoc
class __$TripInspectionCopyWithImpl<$Res>
    implements _$TripInspectionCopyWith<$Res> {
  __$TripInspectionCopyWithImpl(this._self, this._then);

  final _TripInspection _self;
  final $Res Function(_TripInspection) _then;

/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tripId = null,Object? status = null,Object? active = null,Object? cancelReason = freezed,Object? dispatch = null,Object? handoverCount = null,Object? cooperativeName = freezed,Object? passenger = null,Object? driver = null,Object? vehiclePlate = null,Object? vehicleDescription = null,Object? pickup = null,Object? dropoff = null,Object? distanceM = null,Object? durationS = null,Object? currency = null,Object? listFareMinor = null,Object? suggestedFareMinor = null,Object? agreedFareMinor = freezed,Object? preferentialDiscountPct = null,Object? steps = null,Object? driverPosition = freezed,Object? payment = freezed,Object? openSos = freezed,Object? generatedAt = null,}) {
  return _then(_TripInspection(
tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,dispatch: null == dispatch ? _self.dispatch : dispatch // ignore: cast_nullable_to_non_nullable
as String,handoverCount: null == handoverCount ? _self.handoverCount : handoverCount // ignore: cast_nullable_to_non_nullable
as int,cooperativeName: freezed == cooperativeName ? _self.cooperativeName : cooperativeName // ignore: cast_nullable_to_non_nullable
as String?,passenger: null == passenger ? _self.passenger : passenger // ignore: cast_nullable_to_non_nullable
as PersonRef,driver: null == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as PersonRef,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,vehicleDescription: null == vehicleDescription ? _self.vehicleDescription : vehicleDescription // ignore: cast_nullable_to_non_nullable
as String,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as GeoPoint,distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int,durationS: null == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,listFareMinor: null == listFareMinor ? _self.listFareMinor : listFareMinor // ignore: cast_nullable_to_non_nullable
as int,suggestedFareMinor: null == suggestedFareMinor ? _self.suggestedFareMinor : suggestedFareMinor // ignore: cast_nullable_to_non_nullable
as int,agreedFareMinor: freezed == agreedFareMinor ? _self.agreedFareMinor : agreedFareMinor // ignore: cast_nullable_to_non_nullable
as int?,preferentialDiscountPct: null == preferentialDiscountPct ? _self.preferentialDiscountPct : preferentialDiscountPct // ignore: cast_nullable_to_non_nullable
as int,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<TripStep>,driverPosition: freezed == driverPosition ? _self.driverPosition : driverPosition // ignore: cast_nullable_to_non_nullable
as InspectionPosition?,payment: freezed == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as InspectionPayment?,openSos: freezed == openSos ? _self.openSos : openSos // ignore: cast_nullable_to_non_nullable
as InspectionSos?,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res> get passenger {
  
  return $PersonRefCopyWith<$Res>(_self.passenger, (value) {
    return _then(_self.copyWith(passenger: value));
  });
}/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res> get driver {
  
  return $PersonRefCopyWith<$Res>(_self.driver, (value) {
    return _then(_self.copyWith(driver: value));
  });
}/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get pickup {
  
  return $GeoPointCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get dropoff {
  
  return $GeoPointCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InspectionPositionCopyWith<$Res>? get driverPosition {
    if (_self.driverPosition == null) {
    return null;
  }

  return $InspectionPositionCopyWith<$Res>(_self.driverPosition!, (value) {
    return _then(_self.copyWith(driverPosition: value));
  });
}/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InspectionPaymentCopyWith<$Res>? get payment {
    if (_self.payment == null) {
    return null;
  }

  return $InspectionPaymentCopyWith<$Res>(_self.payment!, (value) {
    return _then(_self.copyWith(payment: value));
  });
}/// Create a copy of TripInspection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InspectionSosCopyWith<$Res>? get openSos {
    if (_self.openSos == null) {
    return null;
  }

  return $InspectionSosCopyWith<$Res>(_self.openSos!, (value) {
    return _then(_self.copyWith(openSos: value));
  });
}
}


/// @nodoc
mixin _$SupportCase {

 String get id; SupportTopic get topic; String get subject; SupportStatus get status; PersonRef get user; String get userRole; PersonRef? get counterpart; String? get tripId; String? get tripPaymentId; PersonRef? get assignedTo; DateTime get createdAt; DateTime get lastMessageAt; DateTime? get lastUserMessageAt;/// El último mensaje visible es del usuario: espera respuesta del soporte.
 bool get awaitingReply; DateTime? get resolvedAt; DateTime? get closedAt;
/// Create a copy of SupportCase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportCaseCopyWith<SupportCase> get copyWith => _$SupportCaseCopyWithImpl<SupportCase>(this as SupportCase, _$identity);

  /// Serializes this SupportCase to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportCase&&(identical(other.id, id) || other.id == id)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user)&&(identical(other.userRole, userRole) || other.userRole == userRole)&&(identical(other.counterpart, counterpart) || other.counterpart == counterpart)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.tripPaymentId, tripPaymentId) || other.tripPaymentId == tripPaymentId)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.lastUserMessageAt, lastUserMessageAt) || other.lastUserMessageAt == lastUserMessageAt)&&(identical(other.awaitingReply, awaitingReply) || other.awaitingReply == awaitingReply)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,topic,subject,status,user,userRole,counterpart,tripId,tripPaymentId,assignedTo,createdAt,lastMessageAt,lastUserMessageAt,awaitingReply,resolvedAt,closedAt);

@override
String toString() {
  return 'SupportCase(id: $id, topic: $topic, subject: $subject, status: $status, user: $user, userRole: $userRole, counterpart: $counterpart, tripId: $tripId, tripPaymentId: $tripPaymentId, assignedTo: $assignedTo, createdAt: $createdAt, lastMessageAt: $lastMessageAt, lastUserMessageAt: $lastUserMessageAt, awaitingReply: $awaitingReply, resolvedAt: $resolvedAt, closedAt: $closedAt)';
}


}

/// @nodoc
abstract mixin class $SupportCaseCopyWith<$Res>  {
  factory $SupportCaseCopyWith(SupportCase value, $Res Function(SupportCase) _then) = _$SupportCaseCopyWithImpl;
@useResult
$Res call({
 String id, SupportTopic topic, String subject, SupportStatus status, PersonRef user, String userRole, PersonRef? counterpart, String? tripId, String? tripPaymentId, PersonRef? assignedTo, DateTime createdAt, DateTime lastMessageAt, DateTime? lastUserMessageAt, bool awaitingReply, DateTime? resolvedAt, DateTime? closedAt
});


$PersonRefCopyWith<$Res> get user;$PersonRefCopyWith<$Res>? get counterpart;$PersonRefCopyWith<$Res>? get assignedTo;

}
/// @nodoc
class _$SupportCaseCopyWithImpl<$Res>
    implements $SupportCaseCopyWith<$Res> {
  _$SupportCaseCopyWithImpl(this._self, this._then);

  final SupportCase _self;
  final $Res Function(SupportCase) _then;

/// Create a copy of SupportCase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? topic = null,Object? subject = null,Object? status = null,Object? user = null,Object? userRole = null,Object? counterpart = freezed,Object? tripId = freezed,Object? tripPaymentId = freezed,Object? assignedTo = freezed,Object? createdAt = null,Object? lastMessageAt = null,Object? lastUserMessageAt = freezed,Object? awaitingReply = null,Object? resolvedAt = freezed,Object? closedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as SupportTopic,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SupportStatus,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as PersonRef,userRole: null == userRole ? _self.userRole : userRole // ignore: cast_nullable_to_non_nullable
as String,counterpart: freezed == counterpart ? _self.counterpart : counterpart // ignore: cast_nullable_to_non_nullable
as PersonRef?,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,tripPaymentId: freezed == tripPaymentId ? _self.tripPaymentId : tripPaymentId // ignore: cast_nullable_to_non_nullable
as String?,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as PersonRef?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastMessageAt: null == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastUserMessageAt: freezed == lastUserMessageAt ? _self.lastUserMessageAt : lastUserMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,awaitingReply: null == awaitingReply ? _self.awaitingReply : awaitingReply // ignore: cast_nullable_to_non_nullable
as bool,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of SupportCase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res> get user {
  
  return $PersonRefCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of SupportCase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res>? get counterpart {
    if (_self.counterpart == null) {
    return null;
  }

  return $PersonRefCopyWith<$Res>(_self.counterpart!, (value) {
    return _then(_self.copyWith(counterpart: value));
  });
}/// Create a copy of SupportCase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res>? get assignedTo {
    if (_self.assignedTo == null) {
    return null;
  }

  return $PersonRefCopyWith<$Res>(_self.assignedTo!, (value) {
    return _then(_self.copyWith(assignedTo: value));
  });
}
}


/// Adds pattern-matching-related methods to [SupportCase].
extension SupportCasePatterns on SupportCase {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportCase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportCase() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportCase value)  $default,){
final _that = this;
switch (_that) {
case _SupportCase():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportCase value)?  $default,){
final _that = this;
switch (_that) {
case _SupportCase() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SupportTopic topic,  String subject,  SupportStatus status,  PersonRef user,  String userRole,  PersonRef? counterpart,  String? tripId,  String? tripPaymentId,  PersonRef? assignedTo,  DateTime createdAt,  DateTime lastMessageAt,  DateTime? lastUserMessageAt,  bool awaitingReply,  DateTime? resolvedAt,  DateTime? closedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportCase() when $default != null:
return $default(_that.id,_that.topic,_that.subject,_that.status,_that.user,_that.userRole,_that.counterpart,_that.tripId,_that.tripPaymentId,_that.assignedTo,_that.createdAt,_that.lastMessageAt,_that.lastUserMessageAt,_that.awaitingReply,_that.resolvedAt,_that.closedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SupportTopic topic,  String subject,  SupportStatus status,  PersonRef user,  String userRole,  PersonRef? counterpart,  String? tripId,  String? tripPaymentId,  PersonRef? assignedTo,  DateTime createdAt,  DateTime lastMessageAt,  DateTime? lastUserMessageAt,  bool awaitingReply,  DateTime? resolvedAt,  DateTime? closedAt)  $default,) {final _that = this;
switch (_that) {
case _SupportCase():
return $default(_that.id,_that.topic,_that.subject,_that.status,_that.user,_that.userRole,_that.counterpart,_that.tripId,_that.tripPaymentId,_that.assignedTo,_that.createdAt,_that.lastMessageAt,_that.lastUserMessageAt,_that.awaitingReply,_that.resolvedAt,_that.closedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SupportTopic topic,  String subject,  SupportStatus status,  PersonRef user,  String userRole,  PersonRef? counterpart,  String? tripId,  String? tripPaymentId,  PersonRef? assignedTo,  DateTime createdAt,  DateTime lastMessageAt,  DateTime? lastUserMessageAt,  bool awaitingReply,  DateTime? resolvedAt,  DateTime? closedAt)?  $default,) {final _that = this;
switch (_that) {
case _SupportCase() when $default != null:
return $default(_that.id,_that.topic,_that.subject,_that.status,_that.user,_that.userRole,_that.counterpart,_that.tripId,_that.tripPaymentId,_that.assignedTo,_that.createdAt,_that.lastMessageAt,_that.lastUserMessageAt,_that.awaitingReply,_that.resolvedAt,_that.closedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportCase implements SupportCase {
  const _SupportCase({required this.id, required this.topic, required this.subject, required this.status, required this.user, required this.userRole, this.counterpart, this.tripId, this.tripPaymentId, this.assignedTo, required this.createdAt, required this.lastMessageAt, this.lastUserMessageAt, this.awaitingReply = false, this.resolvedAt, this.closedAt});
  factory _SupportCase.fromJson(Map<String, dynamic> json) => _$SupportCaseFromJson(json);

@override final  String id;
@override final  SupportTopic topic;
@override final  String subject;
@override final  SupportStatus status;
@override final  PersonRef user;
@override final  String userRole;
@override final  PersonRef? counterpart;
@override final  String? tripId;
@override final  String? tripPaymentId;
@override final  PersonRef? assignedTo;
@override final  DateTime createdAt;
@override final  DateTime lastMessageAt;
@override final  DateTime? lastUserMessageAt;
/// El último mensaje visible es del usuario: espera respuesta del soporte.
@override@JsonKey() final  bool awaitingReply;
@override final  DateTime? resolvedAt;
@override final  DateTime? closedAt;

/// Create a copy of SupportCase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportCaseCopyWith<_SupportCase> get copyWith => __$SupportCaseCopyWithImpl<_SupportCase>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportCaseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportCase&&(identical(other.id, id) || other.id == id)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user)&&(identical(other.userRole, userRole) || other.userRole == userRole)&&(identical(other.counterpart, counterpart) || other.counterpart == counterpart)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.tripPaymentId, tripPaymentId) || other.tripPaymentId == tripPaymentId)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.lastUserMessageAt, lastUserMessageAt) || other.lastUserMessageAt == lastUserMessageAt)&&(identical(other.awaitingReply, awaitingReply) || other.awaitingReply == awaitingReply)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,topic,subject,status,user,userRole,counterpart,tripId,tripPaymentId,assignedTo,createdAt,lastMessageAt,lastUserMessageAt,awaitingReply,resolvedAt,closedAt);

@override
String toString() {
  return 'SupportCase(id: $id, topic: $topic, subject: $subject, status: $status, user: $user, userRole: $userRole, counterpart: $counterpart, tripId: $tripId, tripPaymentId: $tripPaymentId, assignedTo: $assignedTo, createdAt: $createdAt, lastMessageAt: $lastMessageAt, lastUserMessageAt: $lastUserMessageAt, awaitingReply: $awaitingReply, resolvedAt: $resolvedAt, closedAt: $closedAt)';
}


}

/// @nodoc
abstract mixin class _$SupportCaseCopyWith<$Res> implements $SupportCaseCopyWith<$Res> {
  factory _$SupportCaseCopyWith(_SupportCase value, $Res Function(_SupportCase) _then) = __$SupportCaseCopyWithImpl;
@override @useResult
$Res call({
 String id, SupportTopic topic, String subject, SupportStatus status, PersonRef user, String userRole, PersonRef? counterpart, String? tripId, String? tripPaymentId, PersonRef? assignedTo, DateTime createdAt, DateTime lastMessageAt, DateTime? lastUserMessageAt, bool awaitingReply, DateTime? resolvedAt, DateTime? closedAt
});


@override $PersonRefCopyWith<$Res> get user;@override $PersonRefCopyWith<$Res>? get counterpart;@override $PersonRefCopyWith<$Res>? get assignedTo;

}
/// @nodoc
class __$SupportCaseCopyWithImpl<$Res>
    implements _$SupportCaseCopyWith<$Res> {
  __$SupportCaseCopyWithImpl(this._self, this._then);

  final _SupportCase _self;
  final $Res Function(_SupportCase) _then;

/// Create a copy of SupportCase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? topic = null,Object? subject = null,Object? status = null,Object? user = null,Object? userRole = null,Object? counterpart = freezed,Object? tripId = freezed,Object? tripPaymentId = freezed,Object? assignedTo = freezed,Object? createdAt = null,Object? lastMessageAt = null,Object? lastUserMessageAt = freezed,Object? awaitingReply = null,Object? resolvedAt = freezed,Object? closedAt = freezed,}) {
  return _then(_SupportCase(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as SupportTopic,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SupportStatus,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as PersonRef,userRole: null == userRole ? _self.userRole : userRole // ignore: cast_nullable_to_non_nullable
as String,counterpart: freezed == counterpart ? _self.counterpart : counterpart // ignore: cast_nullable_to_non_nullable
as PersonRef?,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,tripPaymentId: freezed == tripPaymentId ? _self.tripPaymentId : tripPaymentId // ignore: cast_nullable_to_non_nullable
as String?,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as PersonRef?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastMessageAt: null == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastUserMessageAt: freezed == lastUserMessageAt ? _self.lastUserMessageAt : lastUserMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,awaitingReply: null == awaitingReply ? _self.awaitingReply : awaitingReply // ignore: cast_nullable_to_non_nullable
as bool,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of SupportCase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res> get user {
  
  return $PersonRefCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of SupportCase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res>? get counterpart {
    if (_self.counterpart == null) {
    return null;
  }

  return $PersonRefCopyWith<$Res>(_self.counterpart!, (value) {
    return _then(_self.copyWith(counterpart: value));
  });
}/// Create a copy of SupportCase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res>? get assignedTo {
    if (_self.assignedTo == null) {
    return null;
  }

  return $PersonRefCopyWith<$Res>(_self.assignedTo!, (value) {
    return _then(_self.copyWith(assignedTo: value));
  });
}
}


/// @nodoc
mixin _$SupportMessage {

 String get id; SupportAuthor get authorKind; String? get authorName; bool get mine; String get body; bool get internal; DateTime get createdAt;
/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportMessageCopyWith<SupportMessage> get copyWith => _$SupportMessageCopyWithImpl<SupportMessage>(this as SupportMessage, _$identity);

  /// Serializes this SupportMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.authorKind, authorKind) || other.authorKind == authorKind)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.mine, mine) || other.mine == mine)&&(identical(other.body, body) || other.body == body)&&(identical(other.internal, internal) || other.internal == internal)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorKind,authorName,mine,body,internal,createdAt);

@override
String toString() {
  return 'SupportMessage(id: $id, authorKind: $authorKind, authorName: $authorName, mine: $mine, body: $body, internal: $internal, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SupportMessageCopyWith<$Res>  {
  factory $SupportMessageCopyWith(SupportMessage value, $Res Function(SupportMessage) _then) = _$SupportMessageCopyWithImpl;
@useResult
$Res call({
 String id, SupportAuthor authorKind, String? authorName, bool mine, String body, bool internal, DateTime createdAt
});




}
/// @nodoc
class _$SupportMessageCopyWithImpl<$Res>
    implements $SupportMessageCopyWith<$Res> {
  _$SupportMessageCopyWithImpl(this._self, this._then);

  final SupportMessage _self;
  final $Res Function(SupportMessage) _then;

/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorKind = null,Object? authorName = freezed,Object? mine = null,Object? body = null,Object? internal = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorKind: null == authorKind ? _self.authorKind : authorKind // ignore: cast_nullable_to_non_nullable
as SupportAuthor,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,mine: null == mine ? _self.mine : mine // ignore: cast_nullable_to_non_nullable
as bool,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,internal: null == internal ? _self.internal : internal // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportMessage].
extension SupportMessagePatterns on SupportMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportMessage value)  $default,){
final _that = this;
switch (_that) {
case _SupportMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportMessage value)?  $default,){
final _that = this;
switch (_that) {
case _SupportMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SupportAuthor authorKind,  String? authorName,  bool mine,  String body,  bool internal,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportMessage() when $default != null:
return $default(_that.id,_that.authorKind,_that.authorName,_that.mine,_that.body,_that.internal,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SupportAuthor authorKind,  String? authorName,  bool mine,  String body,  bool internal,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _SupportMessage():
return $default(_that.id,_that.authorKind,_that.authorName,_that.mine,_that.body,_that.internal,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SupportAuthor authorKind,  String? authorName,  bool mine,  String body,  bool internal,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SupportMessage() when $default != null:
return $default(_that.id,_that.authorKind,_that.authorName,_that.mine,_that.body,_that.internal,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportMessage implements SupportMessage {
  const _SupportMessage({required this.id, required this.authorKind, this.authorName, this.mine = false, required this.body, this.internal = false, required this.createdAt});
  factory _SupportMessage.fromJson(Map<String, dynamic> json) => _$SupportMessageFromJson(json);

@override final  String id;
@override final  SupportAuthor authorKind;
@override final  String? authorName;
@override@JsonKey() final  bool mine;
@override final  String body;
@override@JsonKey() final  bool internal;
@override final  DateTime createdAt;

/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportMessageCopyWith<_SupportMessage> get copyWith => __$SupportMessageCopyWithImpl<_SupportMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.authorKind, authorKind) || other.authorKind == authorKind)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.mine, mine) || other.mine == mine)&&(identical(other.body, body) || other.body == body)&&(identical(other.internal, internal) || other.internal == internal)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorKind,authorName,mine,body,internal,createdAt);

@override
String toString() {
  return 'SupportMessage(id: $id, authorKind: $authorKind, authorName: $authorName, mine: $mine, body: $body, internal: $internal, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SupportMessageCopyWith<$Res> implements $SupportMessageCopyWith<$Res> {
  factory _$SupportMessageCopyWith(_SupportMessage value, $Res Function(_SupportMessage) _then) = __$SupportMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, SupportAuthor authorKind, String? authorName, bool mine, String body, bool internal, DateTime createdAt
});




}
/// @nodoc
class __$SupportMessageCopyWithImpl<$Res>
    implements _$SupportMessageCopyWith<$Res> {
  __$SupportMessageCopyWithImpl(this._self, this._then);

  final _SupportMessage _self;
  final $Res Function(_SupportMessage) _then;

/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? authorKind = null,Object? authorName = freezed,Object? mine = null,Object? body = null,Object? internal = null,Object? createdAt = null,}) {
  return _then(_SupportMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorKind: null == authorKind ? _self.authorKind : authorKind // ignore: cast_nullable_to_non_nullable
as SupportAuthor,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,mine: null == mine ? _self.mine : mine // ignore: cast_nullable_to_non_nullable
as bool,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,internal: null == internal ? _self.internal : internal // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SupportTripRef {

 String get id; String get status; DateTime get createdAt; String get otherParty;
/// Create a copy of SupportTripRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTripRefCopyWith<SupportTripRef> get copyWith => _$SupportTripRefCopyWithImpl<SupportTripRef>(this as SupportTripRef, _$identity);

  /// Serializes this SupportTripRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTripRef&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.otherParty, otherParty) || other.otherParty == otherParty));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,createdAt,otherParty);

@override
String toString() {
  return 'SupportTripRef(id: $id, status: $status, createdAt: $createdAt, otherParty: $otherParty)';
}


}

/// @nodoc
abstract mixin class $SupportTripRefCopyWith<$Res>  {
  factory $SupportTripRefCopyWith(SupportTripRef value, $Res Function(SupportTripRef) _then) = _$SupportTripRefCopyWithImpl;
@useResult
$Res call({
 String id, String status, DateTime createdAt, String otherParty
});




}
/// @nodoc
class _$SupportTripRefCopyWithImpl<$Res>
    implements $SupportTripRefCopyWith<$Res> {
  _$SupportTripRefCopyWithImpl(this._self, this._then);

  final SupportTripRef _self;
  final $Res Function(SupportTripRef) _then;

/// Create a copy of SupportTripRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? createdAt = null,Object? otherParty = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,otherParty: null == otherParty ? _self.otherParty : otherParty // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportTripRef].
extension SupportTripRefPatterns on SupportTripRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportTripRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportTripRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportTripRef value)  $default,){
final _that = this;
switch (_that) {
case _SupportTripRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportTripRef value)?  $default,){
final _that = this;
switch (_that) {
case _SupportTripRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String status,  DateTime createdAt,  String otherParty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportTripRef() when $default != null:
return $default(_that.id,_that.status,_that.createdAt,_that.otherParty);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String status,  DateTime createdAt,  String otherParty)  $default,) {final _that = this;
switch (_that) {
case _SupportTripRef():
return $default(_that.id,_that.status,_that.createdAt,_that.otherParty);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String status,  DateTime createdAt,  String otherParty)?  $default,) {final _that = this;
switch (_that) {
case _SupportTripRef() when $default != null:
return $default(_that.id,_that.status,_that.createdAt,_that.otherParty);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportTripRef implements SupportTripRef {
  const _SupportTripRef({required this.id, required this.status, required this.createdAt, required this.otherParty});
  factory _SupportTripRef.fromJson(Map<String, dynamic> json) => _$SupportTripRefFromJson(json);

@override final  String id;
@override final  String status;
@override final  DateTime createdAt;
@override final  String otherParty;

/// Create a copy of SupportTripRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportTripRefCopyWith<_SupportTripRef> get copyWith => __$SupportTripRefCopyWithImpl<_SupportTripRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportTripRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTripRef&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.otherParty, otherParty) || other.otherParty == otherParty));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,createdAt,otherParty);

@override
String toString() {
  return 'SupportTripRef(id: $id, status: $status, createdAt: $createdAt, otherParty: $otherParty)';
}


}

/// @nodoc
abstract mixin class _$SupportTripRefCopyWith<$Res> implements $SupportTripRefCopyWith<$Res> {
  factory _$SupportTripRefCopyWith(_SupportTripRef value, $Res Function(_SupportTripRef) _then) = __$SupportTripRefCopyWithImpl;
@override @useResult
$Res call({
 String id, String status, DateTime createdAt, String otherParty
});




}
/// @nodoc
class __$SupportTripRefCopyWithImpl<$Res>
    implements _$SupportTripRefCopyWith<$Res> {
  __$SupportTripRefCopyWithImpl(this._self, this._then);

  final _SupportTripRef _self;
  final $Res Function(_SupportTripRef) _then;

/// Create a copy of SupportTripRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? createdAt = null,Object? otherParty = null,}) {
  return _then(_SupportTripRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,otherParty: null == otherParty ? _self.otherParty : otherParty // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MegaphoneOnAir {

 String get broadcastId; String get url; String get token; DateTime get endsAt; int get recipients;
/// Create a copy of MegaphoneOnAir
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MegaphoneOnAirCopyWith<MegaphoneOnAir> get copyWith => _$MegaphoneOnAirCopyWithImpl<MegaphoneOnAir>(this as MegaphoneOnAir, _$identity);

  /// Serializes this MegaphoneOnAir to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MegaphoneOnAir&&(identical(other.broadcastId, broadcastId) || other.broadcastId == broadcastId)&&(identical(other.url, url) || other.url == url)&&(identical(other.token, token) || other.token == token)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.recipients, recipients) || other.recipients == recipients));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,broadcastId,url,token,endsAt,recipients);

@override
String toString() {
  return 'MegaphoneOnAir(broadcastId: $broadcastId, url: $url, token: $token, endsAt: $endsAt, recipients: $recipients)';
}


}

/// @nodoc
abstract mixin class $MegaphoneOnAirCopyWith<$Res>  {
  factory $MegaphoneOnAirCopyWith(MegaphoneOnAir value, $Res Function(MegaphoneOnAir) _then) = _$MegaphoneOnAirCopyWithImpl;
@useResult
$Res call({
 String broadcastId, String url, String token, DateTime endsAt, int recipients
});




}
/// @nodoc
class _$MegaphoneOnAirCopyWithImpl<$Res>
    implements $MegaphoneOnAirCopyWith<$Res> {
  _$MegaphoneOnAirCopyWithImpl(this._self, this._then);

  final MegaphoneOnAir _self;
  final $Res Function(MegaphoneOnAir) _then;

/// Create a copy of MegaphoneOnAir
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? broadcastId = null,Object? url = null,Object? token = null,Object? endsAt = null,Object? recipients = null,}) {
  return _then(_self.copyWith(
broadcastId: null == broadcastId ? _self.broadcastId : broadcastId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,recipients: null == recipients ? _self.recipients : recipients // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MegaphoneOnAir].
extension MegaphoneOnAirPatterns on MegaphoneOnAir {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MegaphoneOnAir value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MegaphoneOnAir() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MegaphoneOnAir value)  $default,){
final _that = this;
switch (_that) {
case _MegaphoneOnAir():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MegaphoneOnAir value)?  $default,){
final _that = this;
switch (_that) {
case _MegaphoneOnAir() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String broadcastId,  String url,  String token,  DateTime endsAt,  int recipients)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MegaphoneOnAir() when $default != null:
return $default(_that.broadcastId,_that.url,_that.token,_that.endsAt,_that.recipients);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String broadcastId,  String url,  String token,  DateTime endsAt,  int recipients)  $default,) {final _that = this;
switch (_that) {
case _MegaphoneOnAir():
return $default(_that.broadcastId,_that.url,_that.token,_that.endsAt,_that.recipients);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String broadcastId,  String url,  String token,  DateTime endsAt,  int recipients)?  $default,) {final _that = this;
switch (_that) {
case _MegaphoneOnAir() when $default != null:
return $default(_that.broadcastId,_that.url,_that.token,_that.endsAt,_that.recipients);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MegaphoneOnAir implements MegaphoneOnAir {
  const _MegaphoneOnAir({required this.broadcastId, required this.url, required this.token, required this.endsAt, required this.recipients});
  factory _MegaphoneOnAir.fromJson(Map<String, dynamic> json) => _$MegaphoneOnAirFromJson(json);

@override final  String broadcastId;
@override final  String url;
@override final  String token;
@override final  DateTime endsAt;
@override final  int recipients;

/// Create a copy of MegaphoneOnAir
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MegaphoneOnAirCopyWith<_MegaphoneOnAir> get copyWith => __$MegaphoneOnAirCopyWithImpl<_MegaphoneOnAir>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MegaphoneOnAirToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MegaphoneOnAir&&(identical(other.broadcastId, broadcastId) || other.broadcastId == broadcastId)&&(identical(other.url, url) || other.url == url)&&(identical(other.token, token) || other.token == token)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt)&&(identical(other.recipients, recipients) || other.recipients == recipients));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,broadcastId,url,token,endsAt,recipients);

@override
String toString() {
  return 'MegaphoneOnAir(broadcastId: $broadcastId, url: $url, token: $token, endsAt: $endsAt, recipients: $recipients)';
}


}

/// @nodoc
abstract mixin class _$MegaphoneOnAirCopyWith<$Res> implements $MegaphoneOnAirCopyWith<$Res> {
  factory _$MegaphoneOnAirCopyWith(_MegaphoneOnAir value, $Res Function(_MegaphoneOnAir) _then) = __$MegaphoneOnAirCopyWithImpl;
@override @useResult
$Res call({
 String broadcastId, String url, String token, DateTime endsAt, int recipients
});




}
/// @nodoc
class __$MegaphoneOnAirCopyWithImpl<$Res>
    implements _$MegaphoneOnAirCopyWith<$Res> {
  __$MegaphoneOnAirCopyWithImpl(this._self, this._then);

  final _MegaphoneOnAir _self;
  final $Res Function(_MegaphoneOnAir) _then;

/// Create a copy of MegaphoneOnAir
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? broadcastId = null,Object? url = null,Object? token = null,Object? endsAt = null,Object? recipients = null,}) {
  return _then(_MegaphoneOnAir(
broadcastId: null == broadcastId ? _self.broadcastId : broadcastId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,endsAt: null == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime,recipients: null == recipients ? _self.recipients : recipients // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MegaphoneBroadcast {

 String get id; String get adminName; List<String> get cells; int get resolution; DateTime get startedAt; DateTime? get endedAt; int? get durationS; int get recipients;
/// Create a copy of MegaphoneBroadcast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MegaphoneBroadcastCopyWith<MegaphoneBroadcast> get copyWith => _$MegaphoneBroadcastCopyWithImpl<MegaphoneBroadcast>(this as MegaphoneBroadcast, _$identity);

  /// Serializes this MegaphoneBroadcast to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MegaphoneBroadcast&&(identical(other.id, id) || other.id == id)&&(identical(other.adminName, adminName) || other.adminName == adminName)&&const DeepCollectionEquality().equals(other.cells, cells)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.recipients, recipients) || other.recipients == recipients));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,adminName,const DeepCollectionEquality().hash(cells),resolution,startedAt,endedAt,durationS,recipients);

@override
String toString() {
  return 'MegaphoneBroadcast(id: $id, adminName: $adminName, cells: $cells, resolution: $resolution, startedAt: $startedAt, endedAt: $endedAt, durationS: $durationS, recipients: $recipients)';
}


}

/// @nodoc
abstract mixin class $MegaphoneBroadcastCopyWith<$Res>  {
  factory $MegaphoneBroadcastCopyWith(MegaphoneBroadcast value, $Res Function(MegaphoneBroadcast) _then) = _$MegaphoneBroadcastCopyWithImpl;
@useResult
$Res call({
 String id, String adminName, List<String> cells, int resolution, DateTime startedAt, DateTime? endedAt, int? durationS, int recipients
});




}
/// @nodoc
class _$MegaphoneBroadcastCopyWithImpl<$Res>
    implements $MegaphoneBroadcastCopyWith<$Res> {
  _$MegaphoneBroadcastCopyWithImpl(this._self, this._then);

  final MegaphoneBroadcast _self;
  final $Res Function(MegaphoneBroadcast) _then;

/// Create a copy of MegaphoneBroadcast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? adminName = null,Object? cells = null,Object? resolution = null,Object? startedAt = null,Object? endedAt = freezed,Object? durationS = freezed,Object? recipients = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,adminName: null == adminName ? _self.adminName : adminName // ignore: cast_nullable_to_non_nullable
as String,cells: null == cells ? _self.cells : cells // ignore: cast_nullable_to_non_nullable
as List<String>,resolution: null == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,durationS: freezed == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as int?,recipients: null == recipients ? _self.recipients : recipients // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MegaphoneBroadcast].
extension MegaphoneBroadcastPatterns on MegaphoneBroadcast {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MegaphoneBroadcast value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MegaphoneBroadcast() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MegaphoneBroadcast value)  $default,){
final _that = this;
switch (_that) {
case _MegaphoneBroadcast():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MegaphoneBroadcast value)?  $default,){
final _that = this;
switch (_that) {
case _MegaphoneBroadcast() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String adminName,  List<String> cells,  int resolution,  DateTime startedAt,  DateTime? endedAt,  int? durationS,  int recipients)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MegaphoneBroadcast() when $default != null:
return $default(_that.id,_that.adminName,_that.cells,_that.resolution,_that.startedAt,_that.endedAt,_that.durationS,_that.recipients);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String adminName,  List<String> cells,  int resolution,  DateTime startedAt,  DateTime? endedAt,  int? durationS,  int recipients)  $default,) {final _that = this;
switch (_that) {
case _MegaphoneBroadcast():
return $default(_that.id,_that.adminName,_that.cells,_that.resolution,_that.startedAt,_that.endedAt,_that.durationS,_that.recipients);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String adminName,  List<String> cells,  int resolution,  DateTime startedAt,  DateTime? endedAt,  int? durationS,  int recipients)?  $default,) {final _that = this;
switch (_that) {
case _MegaphoneBroadcast() when $default != null:
return $default(_that.id,_that.adminName,_that.cells,_that.resolution,_that.startedAt,_that.endedAt,_that.durationS,_that.recipients);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MegaphoneBroadcast implements MegaphoneBroadcast {
  const _MegaphoneBroadcast({required this.id, required this.adminName, final  List<String> cells = const <String>[], required this.resolution, required this.startedAt, this.endedAt, this.durationS, this.recipients = 0}): _cells = cells;
  factory _MegaphoneBroadcast.fromJson(Map<String, dynamic> json) => _$MegaphoneBroadcastFromJson(json);

@override final  String id;
@override final  String adminName;
 final  List<String> _cells;
@override@JsonKey() List<String> get cells {
  if (_cells is EqualUnmodifiableListView) return _cells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cells);
}

@override final  int resolution;
@override final  DateTime startedAt;
@override final  DateTime? endedAt;
@override final  int? durationS;
@override@JsonKey() final  int recipients;

/// Create a copy of MegaphoneBroadcast
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MegaphoneBroadcastCopyWith<_MegaphoneBroadcast> get copyWith => __$MegaphoneBroadcastCopyWithImpl<_MegaphoneBroadcast>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MegaphoneBroadcastToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MegaphoneBroadcast&&(identical(other.id, id) || other.id == id)&&(identical(other.adminName, adminName) || other.adminName == adminName)&&const DeepCollectionEquality().equals(other._cells, _cells)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.recipients, recipients) || other.recipients == recipients));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,adminName,const DeepCollectionEquality().hash(_cells),resolution,startedAt,endedAt,durationS,recipients);

@override
String toString() {
  return 'MegaphoneBroadcast(id: $id, adminName: $adminName, cells: $cells, resolution: $resolution, startedAt: $startedAt, endedAt: $endedAt, durationS: $durationS, recipients: $recipients)';
}


}

/// @nodoc
abstract mixin class _$MegaphoneBroadcastCopyWith<$Res> implements $MegaphoneBroadcastCopyWith<$Res> {
  factory _$MegaphoneBroadcastCopyWith(_MegaphoneBroadcast value, $Res Function(_MegaphoneBroadcast) _then) = __$MegaphoneBroadcastCopyWithImpl;
@override @useResult
$Res call({
 String id, String adminName, List<String> cells, int resolution, DateTime startedAt, DateTime? endedAt, int? durationS, int recipients
});




}
/// @nodoc
class __$MegaphoneBroadcastCopyWithImpl<$Res>
    implements _$MegaphoneBroadcastCopyWith<$Res> {
  __$MegaphoneBroadcastCopyWithImpl(this._self, this._then);

  final _MegaphoneBroadcast _self;
  final $Res Function(_MegaphoneBroadcast) _then;

/// Create a copy of MegaphoneBroadcast
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? adminName = null,Object? cells = null,Object? resolution = null,Object? startedAt = null,Object? endedAt = freezed,Object? durationS = freezed,Object? recipients = null,}) {
  return _then(_MegaphoneBroadcast(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,adminName: null == adminName ? _self.adminName : adminName // ignore: cast_nullable_to_non_nullable
as String,cells: null == cells ? _self._cells : cells // ignore: cast_nullable_to_non_nullable
as List<String>,resolution: null == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as int,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,durationS: freezed == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as int?,recipients: null == recipients ? _self.recipients : recipients // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AppSessions {

 String get app; double? get crashFree24h; double? get crashFree7d; String? get topRelease; bool get belowTarget; String get link;
/// Create a copy of AppSessions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSessionsCopyWith<AppSessions> get copyWith => _$AppSessionsCopyWithImpl<AppSessions>(this as AppSessions, _$identity);

  /// Serializes this AppSessions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSessions&&(identical(other.app, app) || other.app == app)&&(identical(other.crashFree24h, crashFree24h) || other.crashFree24h == crashFree24h)&&(identical(other.crashFree7d, crashFree7d) || other.crashFree7d == crashFree7d)&&(identical(other.topRelease, topRelease) || other.topRelease == topRelease)&&(identical(other.belowTarget, belowTarget) || other.belowTarget == belowTarget)&&(identical(other.link, link) || other.link == link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,app,crashFree24h,crashFree7d,topRelease,belowTarget,link);

@override
String toString() {
  return 'AppSessions(app: $app, crashFree24h: $crashFree24h, crashFree7d: $crashFree7d, topRelease: $topRelease, belowTarget: $belowTarget, link: $link)';
}


}

/// @nodoc
abstract mixin class $AppSessionsCopyWith<$Res>  {
  factory $AppSessionsCopyWith(AppSessions value, $Res Function(AppSessions) _then) = _$AppSessionsCopyWithImpl;
@useResult
$Res call({
 String app, double? crashFree24h, double? crashFree7d, String? topRelease, bool belowTarget, String link
});




}
/// @nodoc
class _$AppSessionsCopyWithImpl<$Res>
    implements $AppSessionsCopyWith<$Res> {
  _$AppSessionsCopyWithImpl(this._self, this._then);

  final AppSessions _self;
  final $Res Function(AppSessions) _then;

/// Create a copy of AppSessions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? app = null,Object? crashFree24h = freezed,Object? crashFree7d = freezed,Object? topRelease = freezed,Object? belowTarget = null,Object? link = null,}) {
  return _then(_self.copyWith(
app: null == app ? _self.app : app // ignore: cast_nullable_to_non_nullable
as String,crashFree24h: freezed == crashFree24h ? _self.crashFree24h : crashFree24h // ignore: cast_nullable_to_non_nullable
as double?,crashFree7d: freezed == crashFree7d ? _self.crashFree7d : crashFree7d // ignore: cast_nullable_to_non_nullable
as double?,topRelease: freezed == topRelease ? _self.topRelease : topRelease // ignore: cast_nullable_to_non_nullable
as String?,belowTarget: null == belowTarget ? _self.belowTarget : belowTarget // ignore: cast_nullable_to_non_nullable
as bool,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSessions].
extension AppSessionsPatterns on AppSessions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSessions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSessions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSessions value)  $default,){
final _that = this;
switch (_that) {
case _AppSessions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSessions value)?  $default,){
final _that = this;
switch (_that) {
case _AppSessions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String app,  double? crashFree24h,  double? crashFree7d,  String? topRelease,  bool belowTarget,  String link)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSessions() when $default != null:
return $default(_that.app,_that.crashFree24h,_that.crashFree7d,_that.topRelease,_that.belowTarget,_that.link);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String app,  double? crashFree24h,  double? crashFree7d,  String? topRelease,  bool belowTarget,  String link)  $default,) {final _that = this;
switch (_that) {
case _AppSessions():
return $default(_that.app,_that.crashFree24h,_that.crashFree7d,_that.topRelease,_that.belowTarget,_that.link);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String app,  double? crashFree24h,  double? crashFree7d,  String? topRelease,  bool belowTarget,  String link)?  $default,) {final _that = this;
switch (_that) {
case _AppSessions() when $default != null:
return $default(_that.app,_that.crashFree24h,_that.crashFree7d,_that.topRelease,_that.belowTarget,_that.link);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSessions implements AppSessions {
  const _AppSessions({required this.app, this.crashFree24h, this.crashFree7d, this.topRelease, this.belowTarget = false, this.link = ''});
  factory _AppSessions.fromJson(Map<String, dynamic> json) => _$AppSessionsFromJson(json);

@override final  String app;
@override final  double? crashFree24h;
@override final  double? crashFree7d;
@override final  String? topRelease;
@override@JsonKey() final  bool belowTarget;
@override@JsonKey() final  String link;

/// Create a copy of AppSessions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSessionsCopyWith<_AppSessions> get copyWith => __$AppSessionsCopyWithImpl<_AppSessions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppSessionsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSessions&&(identical(other.app, app) || other.app == app)&&(identical(other.crashFree24h, crashFree24h) || other.crashFree24h == crashFree24h)&&(identical(other.crashFree7d, crashFree7d) || other.crashFree7d == crashFree7d)&&(identical(other.topRelease, topRelease) || other.topRelease == topRelease)&&(identical(other.belowTarget, belowTarget) || other.belowTarget == belowTarget)&&(identical(other.link, link) || other.link == link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,app,crashFree24h,crashFree7d,topRelease,belowTarget,link);

@override
String toString() {
  return 'AppSessions(app: $app, crashFree24h: $crashFree24h, crashFree7d: $crashFree7d, topRelease: $topRelease, belowTarget: $belowTarget, link: $link)';
}


}

/// @nodoc
abstract mixin class _$AppSessionsCopyWith<$Res> implements $AppSessionsCopyWith<$Res> {
  factory _$AppSessionsCopyWith(_AppSessions value, $Res Function(_AppSessions) _then) = __$AppSessionsCopyWithImpl;
@override @useResult
$Res call({
 String app, double? crashFree24h, double? crashFree7d, String? topRelease, bool belowTarget, String link
});




}
/// @nodoc
class __$AppSessionsCopyWithImpl<$Res>
    implements _$AppSessionsCopyWith<$Res> {
  __$AppSessionsCopyWithImpl(this._self, this._then);

  final _AppSessions _self;
  final $Res Function(_AppSessions) _then;

/// Create a copy of AppSessions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? app = null,Object? crashFree24h = freezed,Object? crashFree7d = freezed,Object? topRelease = freezed,Object? belowTarget = null,Object? link = null,}) {
  return _then(_AppSessions(
app: null == app ? _self.app : app // ignore: cast_nullable_to_non_nullable
as String,crashFree24h: freezed == crashFree24h ? _self.crashFree24h : crashFree24h // ignore: cast_nullable_to_non_nullable
as double?,crashFree7d: freezed == crashFree7d ? _self.crashFree7d : crashFree7d // ignore: cast_nullable_to_non_nullable
as double?,topRelease: freezed == topRelease ? _self.topRelease : topRelease // ignore: cast_nullable_to_non_nullable
as String?,belowTarget: null == belowTarget ? _self.belowTarget : belowTarget // ignore: cast_nullable_to_non_nullable
as bool,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SessionsReport {

 String get status; DateTime get checkedAt; double get target; List<AppSessions> get apps;
/// Create a copy of SessionsReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionsReportCopyWith<SessionsReport> get copyWith => _$SessionsReportCopyWithImpl<SessionsReport>(this as SessionsReport, _$identity);

  /// Serializes this SessionsReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionsReport&&(identical(other.status, status) || other.status == status)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.target, target) || other.target == target)&&const DeepCollectionEquality().equals(other.apps, apps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,checkedAt,target,const DeepCollectionEquality().hash(apps));

@override
String toString() {
  return 'SessionsReport(status: $status, checkedAt: $checkedAt, target: $target, apps: $apps)';
}


}

/// @nodoc
abstract mixin class $SessionsReportCopyWith<$Res>  {
  factory $SessionsReportCopyWith(SessionsReport value, $Res Function(SessionsReport) _then) = _$SessionsReportCopyWithImpl;
@useResult
$Res call({
 String status, DateTime checkedAt, double target, List<AppSessions> apps
});




}
/// @nodoc
class _$SessionsReportCopyWithImpl<$Res>
    implements $SessionsReportCopyWith<$Res> {
  _$SessionsReportCopyWithImpl(this._self, this._then);

  final SessionsReport _self;
  final $Res Function(SessionsReport) _then;

/// Create a copy of SessionsReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? checkedAt = null,Object? target = null,Object? apps = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as double,apps: null == apps ? _self.apps : apps // ignore: cast_nullable_to_non_nullable
as List<AppSessions>,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionsReport].
extension SessionsReportPatterns on SessionsReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionsReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionsReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionsReport value)  $default,){
final _that = this;
switch (_that) {
case _SessionsReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionsReport value)?  $default,){
final _that = this;
switch (_that) {
case _SessionsReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  DateTime checkedAt,  double target,  List<AppSessions> apps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionsReport() when $default != null:
return $default(_that.status,_that.checkedAt,_that.target,_that.apps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  DateTime checkedAt,  double target,  List<AppSessions> apps)  $default,) {final _that = this;
switch (_that) {
case _SessionsReport():
return $default(_that.status,_that.checkedAt,_that.target,_that.apps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  DateTime checkedAt,  double target,  List<AppSessions> apps)?  $default,) {final _that = this;
switch (_that) {
case _SessionsReport() when $default != null:
return $default(_that.status,_that.checkedAt,_that.target,_that.apps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionsReport implements SessionsReport {
  const _SessionsReport({required this.status, required this.checkedAt, this.target = 0.99, final  List<AppSessions> apps = const <AppSessions>[]}): _apps = apps;
  factory _SessionsReport.fromJson(Map<String, dynamic> json) => _$SessionsReportFromJson(json);

@override final  String status;
@override final  DateTime checkedAt;
@override@JsonKey() final  double target;
 final  List<AppSessions> _apps;
@override@JsonKey() List<AppSessions> get apps {
  if (_apps is EqualUnmodifiableListView) return _apps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_apps);
}


/// Create a copy of SessionsReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionsReportCopyWith<_SessionsReport> get copyWith => __$SessionsReportCopyWithImpl<_SessionsReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionsReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionsReport&&(identical(other.status, status) || other.status == status)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.target, target) || other.target == target)&&const DeepCollectionEquality().equals(other._apps, _apps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,checkedAt,target,const DeepCollectionEquality().hash(_apps));

@override
String toString() {
  return 'SessionsReport(status: $status, checkedAt: $checkedAt, target: $target, apps: $apps)';
}


}

/// @nodoc
abstract mixin class _$SessionsReportCopyWith<$Res> implements $SessionsReportCopyWith<$Res> {
  factory _$SessionsReportCopyWith(_SessionsReport value, $Res Function(_SessionsReport) _then) = __$SessionsReportCopyWithImpl;
@override @useResult
$Res call({
 String status, DateTime checkedAt, double target, List<AppSessions> apps
});




}
/// @nodoc
class __$SessionsReportCopyWithImpl<$Res>
    implements _$SessionsReportCopyWith<$Res> {
  __$SessionsReportCopyWithImpl(this._self, this._then);

  final _SessionsReport _self;
  final $Res Function(_SessionsReport) _then;

/// Create a copy of SessionsReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? checkedAt = null,Object? target = null,Object? apps = null,}) {
  return _then(_SessionsReport(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as double,apps: null == apps ? _self._apps : apps // ignore: cast_nullable_to_non_nullable
as List<AppSessions>,
  ));
}


}


/// @nodoc
mixin _$MirrorDomain {

 String get id; String get apiUrl; String get realtimeUrl; int get position; bool get active;/// `ok`, `down` o `unchecked`.
 String get status; int? get latencyMs;
/// Create a copy of MirrorDomain
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MirrorDomainCopyWith<MirrorDomain> get copyWith => _$MirrorDomainCopyWithImpl<MirrorDomain>(this as MirrorDomain, _$identity);

  /// Serializes this MirrorDomain to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MirrorDomain&&(identical(other.id, id) || other.id == id)&&(identical(other.apiUrl, apiUrl) || other.apiUrl == apiUrl)&&(identical(other.realtimeUrl, realtimeUrl) || other.realtimeUrl == realtimeUrl)&&(identical(other.position, position) || other.position == position)&&(identical(other.active, active) || other.active == active)&&(identical(other.status, status) || other.status == status)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,apiUrl,realtimeUrl,position,active,status,latencyMs);

@override
String toString() {
  return 'MirrorDomain(id: $id, apiUrl: $apiUrl, realtimeUrl: $realtimeUrl, position: $position, active: $active, status: $status, latencyMs: $latencyMs)';
}


}

/// @nodoc
abstract mixin class $MirrorDomainCopyWith<$Res>  {
  factory $MirrorDomainCopyWith(MirrorDomain value, $Res Function(MirrorDomain) _then) = _$MirrorDomainCopyWithImpl;
@useResult
$Res call({
 String id, String apiUrl, String realtimeUrl, int position, bool active, String status, int? latencyMs
});




}
/// @nodoc
class _$MirrorDomainCopyWithImpl<$Res>
    implements $MirrorDomainCopyWith<$Res> {
  _$MirrorDomainCopyWithImpl(this._self, this._then);

  final MirrorDomain _self;
  final $Res Function(MirrorDomain) _then;

/// Create a copy of MirrorDomain
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? apiUrl = null,Object? realtimeUrl = null,Object? position = null,Object? active = null,Object? status = null,Object? latencyMs = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,apiUrl: null == apiUrl ? _self.apiUrl : apiUrl // ignore: cast_nullable_to_non_nullable
as String,realtimeUrl: null == realtimeUrl ? _self.realtimeUrl : realtimeUrl // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MirrorDomain].
extension MirrorDomainPatterns on MirrorDomain {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MirrorDomain value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MirrorDomain() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MirrorDomain value)  $default,){
final _that = this;
switch (_that) {
case _MirrorDomain():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MirrorDomain value)?  $default,){
final _that = this;
switch (_that) {
case _MirrorDomain() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String apiUrl,  String realtimeUrl,  int position,  bool active,  String status,  int? latencyMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MirrorDomain() when $default != null:
return $default(_that.id,_that.apiUrl,_that.realtimeUrl,_that.position,_that.active,_that.status,_that.latencyMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String apiUrl,  String realtimeUrl,  int position,  bool active,  String status,  int? latencyMs)  $default,) {final _that = this;
switch (_that) {
case _MirrorDomain():
return $default(_that.id,_that.apiUrl,_that.realtimeUrl,_that.position,_that.active,_that.status,_that.latencyMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String apiUrl,  String realtimeUrl,  int position,  bool active,  String status,  int? latencyMs)?  $default,) {final _that = this;
switch (_that) {
case _MirrorDomain() when $default != null:
return $default(_that.id,_that.apiUrl,_that.realtimeUrl,_that.position,_that.active,_that.status,_that.latencyMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MirrorDomain implements MirrorDomain {
  const _MirrorDomain({required this.id, required this.apiUrl, required this.realtimeUrl, required this.position, required this.active, this.status = 'unchecked', this.latencyMs});
  factory _MirrorDomain.fromJson(Map<String, dynamic> json) => _$MirrorDomainFromJson(json);

@override final  String id;
@override final  String apiUrl;
@override final  String realtimeUrl;
@override final  int position;
@override final  bool active;
/// `ok`, `down` o `unchecked`.
@override@JsonKey() final  String status;
@override final  int? latencyMs;

/// Create a copy of MirrorDomain
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MirrorDomainCopyWith<_MirrorDomain> get copyWith => __$MirrorDomainCopyWithImpl<_MirrorDomain>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MirrorDomainToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MirrorDomain&&(identical(other.id, id) || other.id == id)&&(identical(other.apiUrl, apiUrl) || other.apiUrl == apiUrl)&&(identical(other.realtimeUrl, realtimeUrl) || other.realtimeUrl == realtimeUrl)&&(identical(other.position, position) || other.position == position)&&(identical(other.active, active) || other.active == active)&&(identical(other.status, status) || other.status == status)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,apiUrl,realtimeUrl,position,active,status,latencyMs);

@override
String toString() {
  return 'MirrorDomain(id: $id, apiUrl: $apiUrl, realtimeUrl: $realtimeUrl, position: $position, active: $active, status: $status, latencyMs: $latencyMs)';
}


}

/// @nodoc
abstract mixin class _$MirrorDomainCopyWith<$Res> implements $MirrorDomainCopyWith<$Res> {
  factory _$MirrorDomainCopyWith(_MirrorDomain value, $Res Function(_MirrorDomain) _then) = __$MirrorDomainCopyWithImpl;
@override @useResult
$Res call({
 String id, String apiUrl, String realtimeUrl, int position, bool active, String status, int? latencyMs
});




}
/// @nodoc
class __$MirrorDomainCopyWithImpl<$Res>
    implements _$MirrorDomainCopyWith<$Res> {
  __$MirrorDomainCopyWithImpl(this._self, this._then);

  final _MirrorDomain _self;
  final $Res Function(_MirrorDomain) _then;

/// Create a copy of MirrorDomain
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? apiUrl = null,Object? realtimeUrl = null,Object? position = null,Object? active = null,Object? status = null,Object? latencyMs = freezed,}) {
  return _then(_MirrorDomain(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,apiUrl: null == apiUrl ? _self.apiUrl : apiUrl // ignore: cast_nullable_to_non_nullable
as String,realtimeUrl: null == realtimeUrl ? _self.realtimeUrl : realtimeUrl // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$MirrorDomainListing {

 int get version; bool get signingConfigured; String? get publicKey; List<MirrorDomain> get domains;
/// Create a copy of MirrorDomainListing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MirrorDomainListingCopyWith<MirrorDomainListing> get copyWith => _$MirrorDomainListingCopyWithImpl<MirrorDomainListing>(this as MirrorDomainListing, _$identity);

  /// Serializes this MirrorDomainListing to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MirrorDomainListing&&(identical(other.version, version) || other.version == version)&&(identical(other.signingConfigured, signingConfigured) || other.signingConfigured == signingConfigured)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&const DeepCollectionEquality().equals(other.domains, domains));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,signingConfigured,publicKey,const DeepCollectionEquality().hash(domains));

@override
String toString() {
  return 'MirrorDomainListing(version: $version, signingConfigured: $signingConfigured, publicKey: $publicKey, domains: $domains)';
}


}

/// @nodoc
abstract mixin class $MirrorDomainListingCopyWith<$Res>  {
  factory $MirrorDomainListingCopyWith(MirrorDomainListing value, $Res Function(MirrorDomainListing) _then) = _$MirrorDomainListingCopyWithImpl;
@useResult
$Res call({
 int version, bool signingConfigured, String? publicKey, List<MirrorDomain> domains
});




}
/// @nodoc
class _$MirrorDomainListingCopyWithImpl<$Res>
    implements $MirrorDomainListingCopyWith<$Res> {
  _$MirrorDomainListingCopyWithImpl(this._self, this._then);

  final MirrorDomainListing _self;
  final $Res Function(MirrorDomainListing) _then;

/// Create a copy of MirrorDomainListing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? signingConfigured = null,Object? publicKey = freezed,Object? domains = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,signingConfigured: null == signingConfigured ? _self.signingConfigured : signingConfigured // ignore: cast_nullable_to_non_nullable
as bool,publicKey: freezed == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String?,domains: null == domains ? _self.domains : domains // ignore: cast_nullable_to_non_nullable
as List<MirrorDomain>,
  ));
}

}


/// Adds pattern-matching-related methods to [MirrorDomainListing].
extension MirrorDomainListingPatterns on MirrorDomainListing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MirrorDomainListing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MirrorDomainListing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MirrorDomainListing value)  $default,){
final _that = this;
switch (_that) {
case _MirrorDomainListing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MirrorDomainListing value)?  $default,){
final _that = this;
switch (_that) {
case _MirrorDomainListing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  bool signingConfigured,  String? publicKey,  List<MirrorDomain> domains)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MirrorDomainListing() when $default != null:
return $default(_that.version,_that.signingConfigured,_that.publicKey,_that.domains);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  bool signingConfigured,  String? publicKey,  List<MirrorDomain> domains)  $default,) {final _that = this;
switch (_that) {
case _MirrorDomainListing():
return $default(_that.version,_that.signingConfigured,_that.publicKey,_that.domains);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  bool signingConfigured,  String? publicKey,  List<MirrorDomain> domains)?  $default,) {final _that = this;
switch (_that) {
case _MirrorDomainListing() when $default != null:
return $default(_that.version,_that.signingConfigured,_that.publicKey,_that.domains);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MirrorDomainListing implements MirrorDomainListing {
  const _MirrorDomainListing({required this.version, required this.signingConfigured, this.publicKey, final  List<MirrorDomain> domains = const <MirrorDomain>[]}): _domains = domains;
  factory _MirrorDomainListing.fromJson(Map<String, dynamic> json) => _$MirrorDomainListingFromJson(json);

@override final  int version;
@override final  bool signingConfigured;
@override final  String? publicKey;
 final  List<MirrorDomain> _domains;
@override@JsonKey() List<MirrorDomain> get domains {
  if (_domains is EqualUnmodifiableListView) return _domains;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_domains);
}


/// Create a copy of MirrorDomainListing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MirrorDomainListingCopyWith<_MirrorDomainListing> get copyWith => __$MirrorDomainListingCopyWithImpl<_MirrorDomainListing>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MirrorDomainListingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MirrorDomainListing&&(identical(other.version, version) || other.version == version)&&(identical(other.signingConfigured, signingConfigured) || other.signingConfigured == signingConfigured)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&const DeepCollectionEquality().equals(other._domains, _domains));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,version,signingConfigured,publicKey,const DeepCollectionEquality().hash(_domains));

@override
String toString() {
  return 'MirrorDomainListing(version: $version, signingConfigured: $signingConfigured, publicKey: $publicKey, domains: $domains)';
}


}

/// @nodoc
abstract mixin class _$MirrorDomainListingCopyWith<$Res> implements $MirrorDomainListingCopyWith<$Res> {
  factory _$MirrorDomainListingCopyWith(_MirrorDomainListing value, $Res Function(_MirrorDomainListing) _then) = __$MirrorDomainListingCopyWithImpl;
@override @useResult
$Res call({
 int version, bool signingConfigured, String? publicKey, List<MirrorDomain> domains
});




}
/// @nodoc
class __$MirrorDomainListingCopyWithImpl<$Res>
    implements _$MirrorDomainListingCopyWith<$Res> {
  __$MirrorDomainListingCopyWithImpl(this._self, this._then);

  final _MirrorDomainListing _self;
  final $Res Function(_MirrorDomainListing) _then;

/// Create a copy of MirrorDomainListing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? signingConfigured = null,Object? publicKey = freezed,Object? domains = null,}) {
  return _then(_MirrorDomainListing(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,signingConfigured: null == signingConfigured ? _self.signingConfigured : signingConfigured // ignore: cast_nullable_to_non_nullable
as bool,publicKey: freezed == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String?,domains: null == domains ? _self._domains : domains // ignore: cast_nullable_to_non_nullable
as List<MirrorDomain>,
  ));
}


}


/// @nodoc
mixin _$SignedDomainList {

 String get payload; String get signature;
/// Create a copy of SignedDomainList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignedDomainListCopyWith<SignedDomainList> get copyWith => _$SignedDomainListCopyWithImpl<SignedDomainList>(this as SignedDomainList, _$identity);

  /// Serializes this SignedDomainList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignedDomainList&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.signature, signature) || other.signature == signature));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,payload,signature);

@override
String toString() {
  return 'SignedDomainList(payload: $payload, signature: $signature)';
}


}

/// @nodoc
abstract mixin class $SignedDomainListCopyWith<$Res>  {
  factory $SignedDomainListCopyWith(SignedDomainList value, $Res Function(SignedDomainList) _then) = _$SignedDomainListCopyWithImpl;
@useResult
$Res call({
 String payload, String signature
});




}
/// @nodoc
class _$SignedDomainListCopyWithImpl<$Res>
    implements $SignedDomainListCopyWith<$Res> {
  _$SignedDomainListCopyWithImpl(this._self, this._then);

  final SignedDomainList _self;
  final $Res Function(SignedDomainList) _then;

/// Create a copy of SignedDomainList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? payload = null,Object? signature = null,}) {
  return _then(_self.copyWith(
payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SignedDomainList].
extension SignedDomainListPatterns on SignedDomainList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignedDomainList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignedDomainList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignedDomainList value)  $default,){
final _that = this;
switch (_that) {
case _SignedDomainList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignedDomainList value)?  $default,){
final _that = this;
switch (_that) {
case _SignedDomainList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String payload,  String signature)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignedDomainList() when $default != null:
return $default(_that.payload,_that.signature);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String payload,  String signature)  $default,) {final _that = this;
switch (_that) {
case _SignedDomainList():
return $default(_that.payload,_that.signature);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String payload,  String signature)?  $default,) {final _that = this;
switch (_that) {
case _SignedDomainList() when $default != null:
return $default(_that.payload,_that.signature);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SignedDomainList implements SignedDomainList {
  const _SignedDomainList({required this.payload, required this.signature});
  factory _SignedDomainList.fromJson(Map<String, dynamic> json) => _$SignedDomainListFromJson(json);

@override final  String payload;
@override final  String signature;

/// Create a copy of SignedDomainList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignedDomainListCopyWith<_SignedDomainList> get copyWith => __$SignedDomainListCopyWithImpl<_SignedDomainList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignedDomainListToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignedDomainList&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.signature, signature) || other.signature == signature));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,payload,signature);

@override
String toString() {
  return 'SignedDomainList(payload: $payload, signature: $signature)';
}


}

/// @nodoc
abstract mixin class _$SignedDomainListCopyWith<$Res> implements $SignedDomainListCopyWith<$Res> {
  factory _$SignedDomainListCopyWith(_SignedDomainList value, $Res Function(_SignedDomainList) _then) = __$SignedDomainListCopyWithImpl;
@override @useResult
$Res call({
 String payload, String signature
});




}
/// @nodoc
class __$SignedDomainListCopyWithImpl<$Res>
    implements _$SignedDomainListCopyWith<$Res> {
  __$SignedDomainListCopyWithImpl(this._self, this._then);

  final _SignedDomainList _self;
  final $Res Function(_SignedDomainList) _then;

/// Create a copy of SignedDomainList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? payload = null,Object? signature = null,}) {
  return _then(_SignedDomainList(
payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
