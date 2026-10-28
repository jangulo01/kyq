// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TowerTotals {

 int get online; int get free; int get busy; int get withoutLocation; int get stale; int get activeTrips; int get requests; int get unservedRequests;
/// Create a copy of TowerTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TowerTotalsCopyWith<TowerTotals> get copyWith => _$TowerTotalsCopyWithImpl<TowerTotals>(this as TowerTotals, _$identity);

  /// Serializes this TowerTotals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TowerTotals&&(identical(other.online, online) || other.online == online)&&(identical(other.free, free) || other.free == free)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.withoutLocation, withoutLocation) || other.withoutLocation == withoutLocation)&&(identical(other.stale, stale) || other.stale == stale)&&(identical(other.activeTrips, activeTrips) || other.activeTrips == activeTrips)&&(identical(other.requests, requests) || other.requests == requests)&&(identical(other.unservedRequests, unservedRequests) || other.unservedRequests == unservedRequests));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,online,free,busy,withoutLocation,stale,activeTrips,requests,unservedRequests);

@override
String toString() {
  return 'TowerTotals(online: $online, free: $free, busy: $busy, withoutLocation: $withoutLocation, stale: $stale, activeTrips: $activeTrips, requests: $requests, unservedRequests: $unservedRequests)';
}


}

/// @nodoc
abstract mixin class $TowerTotalsCopyWith<$Res>  {
  factory $TowerTotalsCopyWith(TowerTotals value, $Res Function(TowerTotals) _then) = _$TowerTotalsCopyWithImpl;
@useResult
$Res call({
 int online, int free, int busy, int withoutLocation, int stale, int activeTrips, int requests, int unservedRequests
});




}
/// @nodoc
class _$TowerTotalsCopyWithImpl<$Res>
    implements $TowerTotalsCopyWith<$Res> {
  _$TowerTotalsCopyWithImpl(this._self, this._then);

  final TowerTotals _self;
  final $Res Function(TowerTotals) _then;

/// Create a copy of TowerTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? online = null,Object? free = null,Object? busy = null,Object? withoutLocation = null,Object? stale = null,Object? activeTrips = null,Object? requests = null,Object? unservedRequests = null,}) {
  return _then(_self.copyWith(
online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as int,free: null == free ? _self.free : free // ignore: cast_nullable_to_non_nullable
as int,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as int,withoutLocation: null == withoutLocation ? _self.withoutLocation : withoutLocation // ignore: cast_nullable_to_non_nullable
as int,stale: null == stale ? _self.stale : stale // ignore: cast_nullable_to_non_nullable
as int,activeTrips: null == activeTrips ? _self.activeTrips : activeTrips // ignore: cast_nullable_to_non_nullable
as int,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as int,unservedRequests: null == unservedRequests ? _self.unservedRequests : unservedRequests // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TowerTotals].
extension TowerTotalsPatterns on TowerTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TowerTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TowerTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TowerTotals value)  $default,){
final _that = this;
switch (_that) {
case _TowerTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TowerTotals value)?  $default,){
final _that = this;
switch (_that) {
case _TowerTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int online,  int free,  int busy,  int withoutLocation,  int stale,  int activeTrips,  int requests,  int unservedRequests)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TowerTotals() when $default != null:
return $default(_that.online,_that.free,_that.busy,_that.withoutLocation,_that.stale,_that.activeTrips,_that.requests,_that.unservedRequests);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int online,  int free,  int busy,  int withoutLocation,  int stale,  int activeTrips,  int requests,  int unservedRequests)  $default,) {final _that = this;
switch (_that) {
case _TowerTotals():
return $default(_that.online,_that.free,_that.busy,_that.withoutLocation,_that.stale,_that.activeTrips,_that.requests,_that.unservedRequests);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int online,  int free,  int busy,  int withoutLocation,  int stale,  int activeTrips,  int requests,  int unservedRequests)?  $default,) {final _that = this;
switch (_that) {
case _TowerTotals() when $default != null:
return $default(_that.online,_that.free,_that.busy,_that.withoutLocation,_that.stale,_that.activeTrips,_that.requests,_that.unservedRequests);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TowerTotals implements TowerTotals {
  const _TowerTotals({this.online = 0, this.free = 0, this.busy = 0, this.withoutLocation = 0, this.stale = 0, this.activeTrips = 0, this.requests = 0, this.unservedRequests = 0});
  factory _TowerTotals.fromJson(Map<String, dynamic> json) => _$TowerTotalsFromJson(json);

@override@JsonKey() final  int online;
@override@JsonKey() final  int free;
@override@JsonKey() final  int busy;
@override@JsonKey() final  int withoutLocation;
@override@JsonKey() final  int stale;
@override@JsonKey() final  int activeTrips;
@override@JsonKey() final  int requests;
@override@JsonKey() final  int unservedRequests;

/// Create a copy of TowerTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TowerTotalsCopyWith<_TowerTotals> get copyWith => __$TowerTotalsCopyWithImpl<_TowerTotals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TowerTotalsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TowerTotals&&(identical(other.online, online) || other.online == online)&&(identical(other.free, free) || other.free == free)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.withoutLocation, withoutLocation) || other.withoutLocation == withoutLocation)&&(identical(other.stale, stale) || other.stale == stale)&&(identical(other.activeTrips, activeTrips) || other.activeTrips == activeTrips)&&(identical(other.requests, requests) || other.requests == requests)&&(identical(other.unservedRequests, unservedRequests) || other.unservedRequests == unservedRequests));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,online,free,busy,withoutLocation,stale,activeTrips,requests,unservedRequests);

@override
String toString() {
  return 'TowerTotals(online: $online, free: $free, busy: $busy, withoutLocation: $withoutLocation, stale: $stale, activeTrips: $activeTrips, requests: $requests, unservedRequests: $unservedRequests)';
}


}

/// @nodoc
abstract mixin class _$TowerTotalsCopyWith<$Res> implements $TowerTotalsCopyWith<$Res> {
  factory _$TowerTotalsCopyWith(_TowerTotals value, $Res Function(_TowerTotals) _then) = __$TowerTotalsCopyWithImpl;
@override @useResult
$Res call({
 int online, int free, int busy, int withoutLocation, int stale, int activeTrips, int requests, int unservedRequests
});




}
/// @nodoc
class __$TowerTotalsCopyWithImpl<$Res>
    implements _$TowerTotalsCopyWith<$Res> {
  __$TowerTotalsCopyWithImpl(this._self, this._then);

  final _TowerTotals _self;
  final $Res Function(_TowerTotals) _then;

/// Create a copy of TowerTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? online = null,Object? free = null,Object? busy = null,Object? withoutLocation = null,Object? stale = null,Object? activeTrips = null,Object? requests = null,Object? unservedRequests = null,}) {
  return _then(_TowerTotals(
online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as int,free: null == free ? _self.free : free // ignore: cast_nullable_to_non_nullable
as int,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as int,withoutLocation: null == withoutLocation ? _self.withoutLocation : withoutLocation // ignore: cast_nullable_to_non_nullable
as int,stale: null == stale ? _self.stale : stale // ignore: cast_nullable_to_non_nullable
as int,activeTrips: null == activeTrips ? _self.activeTrips : activeTrips // ignore: cast_nullable_to_non_nullable
as int,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as int,unservedRequests: null == unservedRequests ? _self.unservedRequests : unservedRequests // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TowerCell {

 String get cell; GeoPoint get center; List<GeoPoint> get boundary; int get freeDrivers; int get busyDrivers; int get activeTrips; int get requests; int get unservedRequests;/// Solicitudes por conductor libre; null sin conductores libres.
 double? get pressure;@JsonKey(unknownEnumValue: PressureLevel.none) PressureLevel get level;
/// Create a copy of TowerCell
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TowerCellCopyWith<TowerCell> get copyWith => _$TowerCellCopyWithImpl<TowerCell>(this as TowerCell, _$identity);

  /// Serializes this TowerCell to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TowerCell&&(identical(other.cell, cell) || other.cell == cell)&&(identical(other.center, center) || other.center == center)&&const DeepCollectionEquality().equals(other.boundary, boundary)&&(identical(other.freeDrivers, freeDrivers) || other.freeDrivers == freeDrivers)&&(identical(other.busyDrivers, busyDrivers) || other.busyDrivers == busyDrivers)&&(identical(other.activeTrips, activeTrips) || other.activeTrips == activeTrips)&&(identical(other.requests, requests) || other.requests == requests)&&(identical(other.unservedRequests, unservedRequests) || other.unservedRequests == unservedRequests)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cell,center,const DeepCollectionEquality().hash(boundary),freeDrivers,busyDrivers,activeTrips,requests,unservedRequests,pressure,level);

@override
String toString() {
  return 'TowerCell(cell: $cell, center: $center, boundary: $boundary, freeDrivers: $freeDrivers, busyDrivers: $busyDrivers, activeTrips: $activeTrips, requests: $requests, unservedRequests: $unservedRequests, pressure: $pressure, level: $level)';
}


}

/// @nodoc
abstract mixin class $TowerCellCopyWith<$Res>  {
  factory $TowerCellCopyWith(TowerCell value, $Res Function(TowerCell) _then) = _$TowerCellCopyWithImpl;
@useResult
$Res call({
 String cell, GeoPoint center, List<GeoPoint> boundary, int freeDrivers, int busyDrivers, int activeTrips, int requests, int unservedRequests, double? pressure,@JsonKey(unknownEnumValue: PressureLevel.none) PressureLevel level
});


$GeoPointCopyWith<$Res> get center;

}
/// @nodoc
class _$TowerCellCopyWithImpl<$Res>
    implements $TowerCellCopyWith<$Res> {
  _$TowerCellCopyWithImpl(this._self, this._then);

  final TowerCell _self;
  final $Res Function(TowerCell) _then;

/// Create a copy of TowerCell
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cell = null,Object? center = null,Object? boundary = null,Object? freeDrivers = null,Object? busyDrivers = null,Object? activeTrips = null,Object? requests = null,Object? unservedRequests = null,Object? pressure = freezed,Object? level = null,}) {
  return _then(_self.copyWith(
cell: null == cell ? _self.cell : cell // ignore: cast_nullable_to_non_nullable
as String,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as GeoPoint,boundary: null == boundary ? _self.boundary : boundary // ignore: cast_nullable_to_non_nullable
as List<GeoPoint>,freeDrivers: null == freeDrivers ? _self.freeDrivers : freeDrivers // ignore: cast_nullable_to_non_nullable
as int,busyDrivers: null == busyDrivers ? _self.busyDrivers : busyDrivers // ignore: cast_nullable_to_non_nullable
as int,activeTrips: null == activeTrips ? _self.activeTrips : activeTrips // ignore: cast_nullable_to_non_nullable
as int,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as int,unservedRequests: null == unservedRequests ? _self.unservedRequests : unservedRequests // ignore: cast_nullable_to_non_nullable
as int,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as PressureLevel,
  ));
}
/// Create a copy of TowerCell
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get center {
  
  return $GeoPointCopyWith<$Res>(_self.center, (value) {
    return _then(_self.copyWith(center: value));
  });
}
}


/// Adds pattern-matching-related methods to [TowerCell].
extension TowerCellPatterns on TowerCell {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TowerCell value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TowerCell() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TowerCell value)  $default,){
final _that = this;
switch (_that) {
case _TowerCell():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TowerCell value)?  $default,){
final _that = this;
switch (_that) {
case _TowerCell() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String cell,  GeoPoint center,  List<GeoPoint> boundary,  int freeDrivers,  int busyDrivers,  int activeTrips,  int requests,  int unservedRequests,  double? pressure, @JsonKey(unknownEnumValue: PressureLevel.none)  PressureLevel level)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TowerCell() when $default != null:
return $default(_that.cell,_that.center,_that.boundary,_that.freeDrivers,_that.busyDrivers,_that.activeTrips,_that.requests,_that.unservedRequests,_that.pressure,_that.level);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String cell,  GeoPoint center,  List<GeoPoint> boundary,  int freeDrivers,  int busyDrivers,  int activeTrips,  int requests,  int unservedRequests,  double? pressure, @JsonKey(unknownEnumValue: PressureLevel.none)  PressureLevel level)  $default,) {final _that = this;
switch (_that) {
case _TowerCell():
return $default(_that.cell,_that.center,_that.boundary,_that.freeDrivers,_that.busyDrivers,_that.activeTrips,_that.requests,_that.unservedRequests,_that.pressure,_that.level);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String cell,  GeoPoint center,  List<GeoPoint> boundary,  int freeDrivers,  int busyDrivers,  int activeTrips,  int requests,  int unservedRequests,  double? pressure, @JsonKey(unknownEnumValue: PressureLevel.none)  PressureLevel level)?  $default,) {final _that = this;
switch (_that) {
case _TowerCell() when $default != null:
return $default(_that.cell,_that.center,_that.boundary,_that.freeDrivers,_that.busyDrivers,_that.activeTrips,_that.requests,_that.unservedRequests,_that.pressure,_that.level);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TowerCell implements TowerCell {
  const _TowerCell({required this.cell, required this.center, final  List<GeoPoint> boundary = const <GeoPoint>[], this.freeDrivers = 0, this.busyDrivers = 0, this.activeTrips = 0, this.requests = 0, this.unservedRequests = 0, this.pressure, @JsonKey(unknownEnumValue: PressureLevel.none) this.level = PressureLevel.none}): _boundary = boundary;
  factory _TowerCell.fromJson(Map<String, dynamic> json) => _$TowerCellFromJson(json);

@override final  String cell;
@override final  GeoPoint center;
 final  List<GeoPoint> _boundary;
@override@JsonKey() List<GeoPoint> get boundary {
  if (_boundary is EqualUnmodifiableListView) return _boundary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_boundary);
}

@override@JsonKey() final  int freeDrivers;
@override@JsonKey() final  int busyDrivers;
@override@JsonKey() final  int activeTrips;
@override@JsonKey() final  int requests;
@override@JsonKey() final  int unservedRequests;
/// Solicitudes por conductor libre; null sin conductores libres.
@override final  double? pressure;
@override@JsonKey(unknownEnumValue: PressureLevel.none) final  PressureLevel level;

/// Create a copy of TowerCell
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TowerCellCopyWith<_TowerCell> get copyWith => __$TowerCellCopyWithImpl<_TowerCell>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TowerCellToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TowerCell&&(identical(other.cell, cell) || other.cell == cell)&&(identical(other.center, center) || other.center == center)&&const DeepCollectionEquality().equals(other._boundary, _boundary)&&(identical(other.freeDrivers, freeDrivers) || other.freeDrivers == freeDrivers)&&(identical(other.busyDrivers, busyDrivers) || other.busyDrivers == busyDrivers)&&(identical(other.activeTrips, activeTrips) || other.activeTrips == activeTrips)&&(identical(other.requests, requests) || other.requests == requests)&&(identical(other.unservedRequests, unservedRequests) || other.unservedRequests == unservedRequests)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cell,center,const DeepCollectionEquality().hash(_boundary),freeDrivers,busyDrivers,activeTrips,requests,unservedRequests,pressure,level);

@override
String toString() {
  return 'TowerCell(cell: $cell, center: $center, boundary: $boundary, freeDrivers: $freeDrivers, busyDrivers: $busyDrivers, activeTrips: $activeTrips, requests: $requests, unservedRequests: $unservedRequests, pressure: $pressure, level: $level)';
}


}

/// @nodoc
abstract mixin class _$TowerCellCopyWith<$Res> implements $TowerCellCopyWith<$Res> {
  factory _$TowerCellCopyWith(_TowerCell value, $Res Function(_TowerCell) _then) = __$TowerCellCopyWithImpl;
@override @useResult
$Res call({
 String cell, GeoPoint center, List<GeoPoint> boundary, int freeDrivers, int busyDrivers, int activeTrips, int requests, int unservedRequests, double? pressure,@JsonKey(unknownEnumValue: PressureLevel.none) PressureLevel level
});


@override $GeoPointCopyWith<$Res> get center;

}
/// @nodoc
class __$TowerCellCopyWithImpl<$Res>
    implements _$TowerCellCopyWith<$Res> {
  __$TowerCellCopyWithImpl(this._self, this._then);

  final _TowerCell _self;
  final $Res Function(_TowerCell) _then;

/// Create a copy of TowerCell
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cell = null,Object? center = null,Object? boundary = null,Object? freeDrivers = null,Object? busyDrivers = null,Object? activeTrips = null,Object? requests = null,Object? unservedRequests = null,Object? pressure = freezed,Object? level = null,}) {
  return _then(_TowerCell(
cell: null == cell ? _self.cell : cell // ignore: cast_nullable_to_non_nullable
as String,center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as GeoPoint,boundary: null == boundary ? _self._boundary : boundary // ignore: cast_nullable_to_non_nullable
as List<GeoPoint>,freeDrivers: null == freeDrivers ? _self.freeDrivers : freeDrivers // ignore: cast_nullable_to_non_nullable
as int,busyDrivers: null == busyDrivers ? _self.busyDrivers : busyDrivers // ignore: cast_nullable_to_non_nullable
as int,activeTrips: null == activeTrips ? _self.activeTrips : activeTrips // ignore: cast_nullable_to_non_nullable
as int,requests: null == requests ? _self.requests : requests // ignore: cast_nullable_to_non_nullable
as int,unservedRequests: null == unservedRequests ? _self.unservedRequests : unservedRequests // ignore: cast_nullable_to_non_nullable
as int,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as PressureLevel,
  ));
}

/// Create a copy of TowerCell
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get center {
  
  return $GeoPointCopyWith<$Res>(_self.center, (value) {
    return _then(_self.copyWith(center: value));
  });
}
}


/// @nodoc
mixin _$TowerDriver {

 String get driverId; String get displayName; DriverPresence get presence; double get lat; double get lng; DateTime get locationAt; bool get stale; String get cell;
/// Create a copy of TowerDriver
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TowerDriverCopyWith<TowerDriver> get copyWith => _$TowerDriverCopyWithImpl<TowerDriver>(this as TowerDriver, _$identity);

  /// Serializes this TowerDriver to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TowerDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.locationAt, locationAt) || other.locationAt == locationAt)&&(identical(other.stale, stale) || other.stale == stale)&&(identical(other.cell, cell) || other.cell == cell));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,presence,lat,lng,locationAt,stale,cell);

@override
String toString() {
  return 'TowerDriver(driverId: $driverId, displayName: $displayName, presence: $presence, lat: $lat, lng: $lng, locationAt: $locationAt, stale: $stale, cell: $cell)';
}


}

/// @nodoc
abstract mixin class $TowerDriverCopyWith<$Res>  {
  factory $TowerDriverCopyWith(TowerDriver value, $Res Function(TowerDriver) _then) = _$TowerDriverCopyWithImpl;
@useResult
$Res call({
 String driverId, String displayName, DriverPresence presence, double lat, double lng, DateTime locationAt, bool stale, String cell
});




}
/// @nodoc
class _$TowerDriverCopyWithImpl<$Res>
    implements $TowerDriverCopyWith<$Res> {
  _$TowerDriverCopyWithImpl(this._self, this._then);

  final TowerDriver _self;
  final $Res Function(TowerDriver) _then;

/// Create a copy of TowerDriver
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? displayName = null,Object? presence = null,Object? lat = null,Object? lng = null,Object? locationAt = null,Object? stale = null,Object? cell = null,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as DriverPresence,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,locationAt: null == locationAt ? _self.locationAt : locationAt // ignore: cast_nullable_to_non_nullable
as DateTime,stale: null == stale ? _self.stale : stale // ignore: cast_nullable_to_non_nullable
as bool,cell: null == cell ? _self.cell : cell // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TowerDriver].
extension TowerDriverPatterns on TowerDriver {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TowerDriver value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TowerDriver() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TowerDriver value)  $default,){
final _that = this;
switch (_that) {
case _TowerDriver():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TowerDriver value)?  $default,){
final _that = this;
switch (_that) {
case _TowerDriver() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String displayName,  DriverPresence presence,  double lat,  double lng,  DateTime locationAt,  bool stale,  String cell)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TowerDriver() when $default != null:
return $default(_that.driverId,_that.displayName,_that.presence,_that.lat,_that.lng,_that.locationAt,_that.stale,_that.cell);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String displayName,  DriverPresence presence,  double lat,  double lng,  DateTime locationAt,  bool stale,  String cell)  $default,) {final _that = this;
switch (_that) {
case _TowerDriver():
return $default(_that.driverId,_that.displayName,_that.presence,_that.lat,_that.lng,_that.locationAt,_that.stale,_that.cell);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String displayName,  DriverPresence presence,  double lat,  double lng,  DateTime locationAt,  bool stale,  String cell)?  $default,) {final _that = this;
switch (_that) {
case _TowerDriver() when $default != null:
return $default(_that.driverId,_that.displayName,_that.presence,_that.lat,_that.lng,_that.locationAt,_that.stale,_that.cell);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TowerDriver implements TowerDriver {
  const _TowerDriver({required this.driverId, required this.displayName, required this.presence, required this.lat, required this.lng, required this.locationAt, this.stale = false, required this.cell});
  factory _TowerDriver.fromJson(Map<String, dynamic> json) => _$TowerDriverFromJson(json);

@override final  String driverId;
@override final  String displayName;
@override final  DriverPresence presence;
@override final  double lat;
@override final  double lng;
@override final  DateTime locationAt;
@override@JsonKey() final  bool stale;
@override final  String cell;

/// Create a copy of TowerDriver
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TowerDriverCopyWith<_TowerDriver> get copyWith => __$TowerDriverCopyWithImpl<_TowerDriver>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TowerDriverToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TowerDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.locationAt, locationAt) || other.locationAt == locationAt)&&(identical(other.stale, stale) || other.stale == stale)&&(identical(other.cell, cell) || other.cell == cell));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,presence,lat,lng,locationAt,stale,cell);

@override
String toString() {
  return 'TowerDriver(driverId: $driverId, displayName: $displayName, presence: $presence, lat: $lat, lng: $lng, locationAt: $locationAt, stale: $stale, cell: $cell)';
}


}

/// @nodoc
abstract mixin class _$TowerDriverCopyWith<$Res> implements $TowerDriverCopyWith<$Res> {
  factory _$TowerDriverCopyWith(_TowerDriver value, $Res Function(_TowerDriver) _then) = __$TowerDriverCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String displayName, DriverPresence presence, double lat, double lng, DateTime locationAt, bool stale, String cell
});




}
/// @nodoc
class __$TowerDriverCopyWithImpl<$Res>
    implements _$TowerDriverCopyWith<$Res> {
  __$TowerDriverCopyWithImpl(this._self, this._then);

  final _TowerDriver _self;
  final $Res Function(_TowerDriver) _then;

/// Create a copy of TowerDriver
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? displayName = null,Object? presence = null,Object? lat = null,Object? lng = null,Object? locationAt = null,Object? stale = null,Object? cell = null,}) {
  return _then(_TowerDriver(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as DriverPresence,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,locationAt: null == locationAt ? _self.locationAt : locationAt // ignore: cast_nullable_to_non_nullable
as DateTime,stale: null == stale ? _self.stale : stale // ignore: cast_nullable_to_non_nullable
as bool,cell: null == cell ? _self.cell : cell // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TowerSnapshot {

 DateTime get generatedAt; int get resolution; int get windowMinutes; int get staleAfterSeconds; TowerTotals get totals; List<TowerCell> get cells; List<TowerDriver> get drivers;
/// Create a copy of TowerSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TowerSnapshotCopyWith<TowerSnapshot> get copyWith => _$TowerSnapshotCopyWithImpl<TowerSnapshot>(this as TowerSnapshot, _$identity);

  /// Serializes this TowerSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TowerSnapshot&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.windowMinutes, windowMinutes) || other.windowMinutes == windowMinutes)&&(identical(other.staleAfterSeconds, staleAfterSeconds) || other.staleAfterSeconds == staleAfterSeconds)&&(identical(other.totals, totals) || other.totals == totals)&&const DeepCollectionEquality().equals(other.cells, cells)&&const DeepCollectionEquality().equals(other.drivers, drivers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generatedAt,resolution,windowMinutes,staleAfterSeconds,totals,const DeepCollectionEquality().hash(cells),const DeepCollectionEquality().hash(drivers));

@override
String toString() {
  return 'TowerSnapshot(generatedAt: $generatedAt, resolution: $resolution, windowMinutes: $windowMinutes, staleAfterSeconds: $staleAfterSeconds, totals: $totals, cells: $cells, drivers: $drivers)';
}


}

/// @nodoc
abstract mixin class $TowerSnapshotCopyWith<$Res>  {
  factory $TowerSnapshotCopyWith(TowerSnapshot value, $Res Function(TowerSnapshot) _then) = _$TowerSnapshotCopyWithImpl;
@useResult
$Res call({
 DateTime generatedAt, int resolution, int windowMinutes, int staleAfterSeconds, TowerTotals totals, List<TowerCell> cells, List<TowerDriver> drivers
});


$TowerTotalsCopyWith<$Res> get totals;

}
/// @nodoc
class _$TowerSnapshotCopyWithImpl<$Res>
    implements $TowerSnapshotCopyWith<$Res> {
  _$TowerSnapshotCopyWithImpl(this._self, this._then);

  final TowerSnapshot _self;
  final $Res Function(TowerSnapshot) _then;

/// Create a copy of TowerSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? generatedAt = null,Object? resolution = null,Object? windowMinutes = null,Object? staleAfterSeconds = null,Object? totals = null,Object? cells = null,Object? drivers = null,}) {
  return _then(_self.copyWith(
generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,resolution: null == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as int,windowMinutes: null == windowMinutes ? _self.windowMinutes : windowMinutes // ignore: cast_nullable_to_non_nullable
as int,staleAfterSeconds: null == staleAfterSeconds ? _self.staleAfterSeconds : staleAfterSeconds // ignore: cast_nullable_to_non_nullable
as int,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as TowerTotals,cells: null == cells ? _self.cells : cells // ignore: cast_nullable_to_non_nullable
as List<TowerCell>,drivers: null == drivers ? _self.drivers : drivers // ignore: cast_nullable_to_non_nullable
as List<TowerDriver>,
  ));
}
/// Create a copy of TowerSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TowerTotalsCopyWith<$Res> get totals {
  
  return $TowerTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}


/// Adds pattern-matching-related methods to [TowerSnapshot].
extension TowerSnapshotPatterns on TowerSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TowerSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TowerSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TowerSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _TowerSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TowerSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _TowerSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime generatedAt,  int resolution,  int windowMinutes,  int staleAfterSeconds,  TowerTotals totals,  List<TowerCell> cells,  List<TowerDriver> drivers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TowerSnapshot() when $default != null:
return $default(_that.generatedAt,_that.resolution,_that.windowMinutes,_that.staleAfterSeconds,_that.totals,_that.cells,_that.drivers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime generatedAt,  int resolution,  int windowMinutes,  int staleAfterSeconds,  TowerTotals totals,  List<TowerCell> cells,  List<TowerDriver> drivers)  $default,) {final _that = this;
switch (_that) {
case _TowerSnapshot():
return $default(_that.generatedAt,_that.resolution,_that.windowMinutes,_that.staleAfterSeconds,_that.totals,_that.cells,_that.drivers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime generatedAt,  int resolution,  int windowMinutes,  int staleAfterSeconds,  TowerTotals totals,  List<TowerCell> cells,  List<TowerDriver> drivers)?  $default,) {final _that = this;
switch (_that) {
case _TowerSnapshot() when $default != null:
return $default(_that.generatedAt,_that.resolution,_that.windowMinutes,_that.staleAfterSeconds,_that.totals,_that.cells,_that.drivers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TowerSnapshot implements TowerSnapshot {
  const _TowerSnapshot({required this.generatedAt, required this.resolution, this.windowMinutes = 60, this.staleAfterSeconds = 120, this.totals = const TowerTotals(), final  List<TowerCell> cells = const <TowerCell>[], final  List<TowerDriver> drivers = const <TowerDriver>[]}): _cells = cells,_drivers = drivers;
  factory _TowerSnapshot.fromJson(Map<String, dynamic> json) => _$TowerSnapshotFromJson(json);

@override final  DateTime generatedAt;
@override final  int resolution;
@override@JsonKey() final  int windowMinutes;
@override@JsonKey() final  int staleAfterSeconds;
@override@JsonKey() final  TowerTotals totals;
 final  List<TowerCell> _cells;
@override@JsonKey() List<TowerCell> get cells {
  if (_cells is EqualUnmodifiableListView) return _cells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cells);
}

 final  List<TowerDriver> _drivers;
@override@JsonKey() List<TowerDriver> get drivers {
  if (_drivers is EqualUnmodifiableListView) return _drivers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_drivers);
}


/// Create a copy of TowerSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TowerSnapshotCopyWith<_TowerSnapshot> get copyWith => __$TowerSnapshotCopyWithImpl<_TowerSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TowerSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TowerSnapshot&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.windowMinutes, windowMinutes) || other.windowMinutes == windowMinutes)&&(identical(other.staleAfterSeconds, staleAfterSeconds) || other.staleAfterSeconds == staleAfterSeconds)&&(identical(other.totals, totals) || other.totals == totals)&&const DeepCollectionEquality().equals(other._cells, _cells)&&const DeepCollectionEquality().equals(other._drivers, _drivers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,generatedAt,resolution,windowMinutes,staleAfterSeconds,totals,const DeepCollectionEquality().hash(_cells),const DeepCollectionEquality().hash(_drivers));

@override
String toString() {
  return 'TowerSnapshot(generatedAt: $generatedAt, resolution: $resolution, windowMinutes: $windowMinutes, staleAfterSeconds: $staleAfterSeconds, totals: $totals, cells: $cells, drivers: $drivers)';
}


}

/// @nodoc
abstract mixin class _$TowerSnapshotCopyWith<$Res> implements $TowerSnapshotCopyWith<$Res> {
  factory _$TowerSnapshotCopyWith(_TowerSnapshot value, $Res Function(_TowerSnapshot) _then) = __$TowerSnapshotCopyWithImpl;
@override @useResult
$Res call({
 DateTime generatedAt, int resolution, int windowMinutes, int staleAfterSeconds, TowerTotals totals, List<TowerCell> cells, List<TowerDriver> drivers
});


@override $TowerTotalsCopyWith<$Res> get totals;

}
/// @nodoc
class __$TowerSnapshotCopyWithImpl<$Res>
    implements _$TowerSnapshotCopyWith<$Res> {
  __$TowerSnapshotCopyWithImpl(this._self, this._then);

  final _TowerSnapshot _self;
  final $Res Function(_TowerSnapshot) _then;

/// Create a copy of TowerSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? generatedAt = null,Object? resolution = null,Object? windowMinutes = null,Object? staleAfterSeconds = null,Object? totals = null,Object? cells = null,Object? drivers = null,}) {
  return _then(_TowerSnapshot(
generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,resolution: null == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as int,windowMinutes: null == windowMinutes ? _self.windowMinutes : windowMinutes // ignore: cast_nullable_to_non_nullable
as int,staleAfterSeconds: null == staleAfterSeconds ? _self.staleAfterSeconds : staleAfterSeconds // ignore: cast_nullable_to_non_nullable
as int,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as TowerTotals,cells: null == cells ? _self._cells : cells // ignore: cast_nullable_to_non_nullable
as List<TowerCell>,drivers: null == drivers ? _self._drivers : drivers // ignore: cast_nullable_to_non_nullable
as List<TowerDriver>,
  ));
}

/// Create a copy of TowerSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TowerTotalsCopyWith<$Res> get totals {
  
  return $TowerTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}


/// @nodoc
mixin _$FinanceConceptCost {

 String get concept; double get costMinor;
/// Create a copy of FinanceConceptCost
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinanceConceptCostCopyWith<FinanceConceptCost> get copyWith => _$FinanceConceptCostCopyWithImpl<FinanceConceptCost>(this as FinanceConceptCost, _$identity);

  /// Serializes this FinanceConceptCost to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinanceConceptCost&&(identical(other.concept, concept) || other.concept == concept)&&(identical(other.costMinor, costMinor) || other.costMinor == costMinor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,concept,costMinor);

@override
String toString() {
  return 'FinanceConceptCost(concept: $concept, costMinor: $costMinor)';
}


}

/// @nodoc
abstract mixin class $FinanceConceptCostCopyWith<$Res>  {
  factory $FinanceConceptCostCopyWith(FinanceConceptCost value, $Res Function(FinanceConceptCost) _then) = _$FinanceConceptCostCopyWithImpl;
@useResult
$Res call({
 String concept, double costMinor
});




}
/// @nodoc
class _$FinanceConceptCostCopyWithImpl<$Res>
    implements $FinanceConceptCostCopyWith<$Res> {
  _$FinanceConceptCostCopyWithImpl(this._self, this._then);

  final FinanceConceptCost _self;
  final $Res Function(FinanceConceptCost) _then;

/// Create a copy of FinanceConceptCost
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? concept = null,Object? costMinor = null,}) {
  return _then(_self.copyWith(
concept: null == concept ? _self.concept : concept // ignore: cast_nullable_to_non_nullable
as String,costMinor: null == costMinor ? _self.costMinor : costMinor // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [FinanceConceptCost].
extension FinanceConceptCostPatterns on FinanceConceptCost {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinanceConceptCost value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinanceConceptCost() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinanceConceptCost value)  $default,){
final _that = this;
switch (_that) {
case _FinanceConceptCost():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinanceConceptCost value)?  $default,){
final _that = this;
switch (_that) {
case _FinanceConceptCost() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String concept,  double costMinor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinanceConceptCost() when $default != null:
return $default(_that.concept,_that.costMinor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String concept,  double costMinor)  $default,) {final _that = this;
switch (_that) {
case _FinanceConceptCost():
return $default(_that.concept,_that.costMinor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String concept,  double costMinor)?  $default,) {final _that = this;
switch (_that) {
case _FinanceConceptCost() when $default != null:
return $default(_that.concept,_that.costMinor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinanceConceptCost implements FinanceConceptCost {
  const _FinanceConceptCost({required this.concept, this.costMinor = 0});
  factory _FinanceConceptCost.fromJson(Map<String, dynamic> json) => _$FinanceConceptCostFromJson(json);

@override final  String concept;
@override@JsonKey() final  double costMinor;

/// Create a copy of FinanceConceptCost
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinanceConceptCostCopyWith<_FinanceConceptCost> get copyWith => __$FinanceConceptCostCopyWithImpl<_FinanceConceptCost>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinanceConceptCostToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinanceConceptCost&&(identical(other.concept, concept) || other.concept == concept)&&(identical(other.costMinor, costMinor) || other.costMinor == costMinor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,concept,costMinor);

@override
String toString() {
  return 'FinanceConceptCost(concept: $concept, costMinor: $costMinor)';
}


}

/// @nodoc
abstract mixin class _$FinanceConceptCostCopyWith<$Res> implements $FinanceConceptCostCopyWith<$Res> {
  factory _$FinanceConceptCostCopyWith(_FinanceConceptCost value, $Res Function(_FinanceConceptCost) _then) = __$FinanceConceptCostCopyWithImpl;
@override @useResult
$Res call({
 String concept, double costMinor
});




}
/// @nodoc
class __$FinanceConceptCostCopyWithImpl<$Res>
    implements _$FinanceConceptCostCopyWith<$Res> {
  __$FinanceConceptCostCopyWithImpl(this._self, this._then);

  final _FinanceConceptCost _self;
  final $Res Function(_FinanceConceptCost) _then;

/// Create a copy of FinanceConceptCost
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? concept = null,Object? costMinor = null,}) {
  return _then(_FinanceConceptCost(
concept: null == concept ? _self.concept : concept // ignore: cast_nullable_to_non_nullable
as String,costMinor: null == costMinor ? _self.costMinor : costMinor // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$FinanceMonth {

 String get month; int get revenueMinor; double get infraCostMinor; double get marginMinor; double? get marginPct; int get drivers; int get activeDrivers; int get payingDrivers; int get negativeMarginDrivers; double? get costPerActiveDriverMinor; double? get revenuePerPayingDriverMinor; List<FinanceConceptCost> get costByConcept; bool get ratesMissing;
/// Create a copy of FinanceMonth
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinanceMonthCopyWith<FinanceMonth> get copyWith => _$FinanceMonthCopyWithImpl<FinanceMonth>(this as FinanceMonth, _$identity);

  /// Serializes this FinanceMonth to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinanceMonth&&(identical(other.month, month) || other.month == month)&&(identical(other.revenueMinor, revenueMinor) || other.revenueMinor == revenueMinor)&&(identical(other.infraCostMinor, infraCostMinor) || other.infraCostMinor == infraCostMinor)&&(identical(other.marginMinor, marginMinor) || other.marginMinor == marginMinor)&&(identical(other.marginPct, marginPct) || other.marginPct == marginPct)&&(identical(other.drivers, drivers) || other.drivers == drivers)&&(identical(other.activeDrivers, activeDrivers) || other.activeDrivers == activeDrivers)&&(identical(other.payingDrivers, payingDrivers) || other.payingDrivers == payingDrivers)&&(identical(other.negativeMarginDrivers, negativeMarginDrivers) || other.negativeMarginDrivers == negativeMarginDrivers)&&(identical(other.costPerActiveDriverMinor, costPerActiveDriverMinor) || other.costPerActiveDriverMinor == costPerActiveDriverMinor)&&(identical(other.revenuePerPayingDriverMinor, revenuePerPayingDriverMinor) || other.revenuePerPayingDriverMinor == revenuePerPayingDriverMinor)&&const DeepCollectionEquality().equals(other.costByConcept, costByConcept)&&(identical(other.ratesMissing, ratesMissing) || other.ratesMissing == ratesMissing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,revenueMinor,infraCostMinor,marginMinor,marginPct,drivers,activeDrivers,payingDrivers,negativeMarginDrivers,costPerActiveDriverMinor,revenuePerPayingDriverMinor,const DeepCollectionEquality().hash(costByConcept),ratesMissing);

@override
String toString() {
  return 'FinanceMonth(month: $month, revenueMinor: $revenueMinor, infraCostMinor: $infraCostMinor, marginMinor: $marginMinor, marginPct: $marginPct, drivers: $drivers, activeDrivers: $activeDrivers, payingDrivers: $payingDrivers, negativeMarginDrivers: $negativeMarginDrivers, costPerActiveDriverMinor: $costPerActiveDriverMinor, revenuePerPayingDriverMinor: $revenuePerPayingDriverMinor, costByConcept: $costByConcept, ratesMissing: $ratesMissing)';
}


}

/// @nodoc
abstract mixin class $FinanceMonthCopyWith<$Res>  {
  factory $FinanceMonthCopyWith(FinanceMonth value, $Res Function(FinanceMonth) _then) = _$FinanceMonthCopyWithImpl;
@useResult
$Res call({
 String month, int revenueMinor, double infraCostMinor, double marginMinor, double? marginPct, int drivers, int activeDrivers, int payingDrivers, int negativeMarginDrivers, double? costPerActiveDriverMinor, double? revenuePerPayingDriverMinor, List<FinanceConceptCost> costByConcept, bool ratesMissing
});




}
/// @nodoc
class _$FinanceMonthCopyWithImpl<$Res>
    implements $FinanceMonthCopyWith<$Res> {
  _$FinanceMonthCopyWithImpl(this._self, this._then);

  final FinanceMonth _self;
  final $Res Function(FinanceMonth) _then;

/// Create a copy of FinanceMonth
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? revenueMinor = null,Object? infraCostMinor = null,Object? marginMinor = null,Object? marginPct = freezed,Object? drivers = null,Object? activeDrivers = null,Object? payingDrivers = null,Object? negativeMarginDrivers = null,Object? costPerActiveDriverMinor = freezed,Object? revenuePerPayingDriverMinor = freezed,Object? costByConcept = null,Object? ratesMissing = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,revenueMinor: null == revenueMinor ? _self.revenueMinor : revenueMinor // ignore: cast_nullable_to_non_nullable
as int,infraCostMinor: null == infraCostMinor ? _self.infraCostMinor : infraCostMinor // ignore: cast_nullable_to_non_nullable
as double,marginMinor: null == marginMinor ? _self.marginMinor : marginMinor // ignore: cast_nullable_to_non_nullable
as double,marginPct: freezed == marginPct ? _self.marginPct : marginPct // ignore: cast_nullable_to_non_nullable
as double?,drivers: null == drivers ? _self.drivers : drivers // ignore: cast_nullable_to_non_nullable
as int,activeDrivers: null == activeDrivers ? _self.activeDrivers : activeDrivers // ignore: cast_nullable_to_non_nullable
as int,payingDrivers: null == payingDrivers ? _self.payingDrivers : payingDrivers // ignore: cast_nullable_to_non_nullable
as int,negativeMarginDrivers: null == negativeMarginDrivers ? _self.negativeMarginDrivers : negativeMarginDrivers // ignore: cast_nullable_to_non_nullable
as int,costPerActiveDriverMinor: freezed == costPerActiveDriverMinor ? _self.costPerActiveDriverMinor : costPerActiveDriverMinor // ignore: cast_nullable_to_non_nullable
as double?,revenuePerPayingDriverMinor: freezed == revenuePerPayingDriverMinor ? _self.revenuePerPayingDriverMinor : revenuePerPayingDriverMinor // ignore: cast_nullable_to_non_nullable
as double?,costByConcept: null == costByConcept ? _self.costByConcept : costByConcept // ignore: cast_nullable_to_non_nullable
as List<FinanceConceptCost>,ratesMissing: null == ratesMissing ? _self.ratesMissing : ratesMissing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FinanceMonth].
extension FinanceMonthPatterns on FinanceMonth {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinanceMonth value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinanceMonth() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinanceMonth value)  $default,){
final _that = this;
switch (_that) {
case _FinanceMonth():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinanceMonth value)?  $default,){
final _that = this;
switch (_that) {
case _FinanceMonth() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String month,  int revenueMinor,  double infraCostMinor,  double marginMinor,  double? marginPct,  int drivers,  int activeDrivers,  int payingDrivers,  int negativeMarginDrivers,  double? costPerActiveDriverMinor,  double? revenuePerPayingDriverMinor,  List<FinanceConceptCost> costByConcept,  bool ratesMissing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinanceMonth() when $default != null:
return $default(_that.month,_that.revenueMinor,_that.infraCostMinor,_that.marginMinor,_that.marginPct,_that.drivers,_that.activeDrivers,_that.payingDrivers,_that.negativeMarginDrivers,_that.costPerActiveDriverMinor,_that.revenuePerPayingDriverMinor,_that.costByConcept,_that.ratesMissing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String month,  int revenueMinor,  double infraCostMinor,  double marginMinor,  double? marginPct,  int drivers,  int activeDrivers,  int payingDrivers,  int negativeMarginDrivers,  double? costPerActiveDriverMinor,  double? revenuePerPayingDriverMinor,  List<FinanceConceptCost> costByConcept,  bool ratesMissing)  $default,) {final _that = this;
switch (_that) {
case _FinanceMonth():
return $default(_that.month,_that.revenueMinor,_that.infraCostMinor,_that.marginMinor,_that.marginPct,_that.drivers,_that.activeDrivers,_that.payingDrivers,_that.negativeMarginDrivers,_that.costPerActiveDriverMinor,_that.revenuePerPayingDriverMinor,_that.costByConcept,_that.ratesMissing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String month,  int revenueMinor,  double infraCostMinor,  double marginMinor,  double? marginPct,  int drivers,  int activeDrivers,  int payingDrivers,  int negativeMarginDrivers,  double? costPerActiveDriverMinor,  double? revenuePerPayingDriverMinor,  List<FinanceConceptCost> costByConcept,  bool ratesMissing)?  $default,) {final _that = this;
switch (_that) {
case _FinanceMonth() when $default != null:
return $default(_that.month,_that.revenueMinor,_that.infraCostMinor,_that.marginMinor,_that.marginPct,_that.drivers,_that.activeDrivers,_that.payingDrivers,_that.negativeMarginDrivers,_that.costPerActiveDriverMinor,_that.revenuePerPayingDriverMinor,_that.costByConcept,_that.ratesMissing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinanceMonth implements FinanceMonth {
  const _FinanceMonth({required this.month, this.revenueMinor = 0, this.infraCostMinor = 0, this.marginMinor = 0, this.marginPct, this.drivers = 0, this.activeDrivers = 0, this.payingDrivers = 0, this.negativeMarginDrivers = 0, this.costPerActiveDriverMinor, this.revenuePerPayingDriverMinor, final  List<FinanceConceptCost> costByConcept = const <FinanceConceptCost>[], this.ratesMissing = false}): _costByConcept = costByConcept;
  factory _FinanceMonth.fromJson(Map<String, dynamic> json) => _$FinanceMonthFromJson(json);

@override final  String month;
@override@JsonKey() final  int revenueMinor;
@override@JsonKey() final  double infraCostMinor;
@override@JsonKey() final  double marginMinor;
@override final  double? marginPct;
@override@JsonKey() final  int drivers;
@override@JsonKey() final  int activeDrivers;
@override@JsonKey() final  int payingDrivers;
@override@JsonKey() final  int negativeMarginDrivers;
@override final  double? costPerActiveDriverMinor;
@override final  double? revenuePerPayingDriverMinor;
 final  List<FinanceConceptCost> _costByConcept;
@override@JsonKey() List<FinanceConceptCost> get costByConcept {
  if (_costByConcept is EqualUnmodifiableListView) return _costByConcept;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_costByConcept);
}

@override@JsonKey() final  bool ratesMissing;

/// Create a copy of FinanceMonth
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinanceMonthCopyWith<_FinanceMonth> get copyWith => __$FinanceMonthCopyWithImpl<_FinanceMonth>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinanceMonthToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinanceMonth&&(identical(other.month, month) || other.month == month)&&(identical(other.revenueMinor, revenueMinor) || other.revenueMinor == revenueMinor)&&(identical(other.infraCostMinor, infraCostMinor) || other.infraCostMinor == infraCostMinor)&&(identical(other.marginMinor, marginMinor) || other.marginMinor == marginMinor)&&(identical(other.marginPct, marginPct) || other.marginPct == marginPct)&&(identical(other.drivers, drivers) || other.drivers == drivers)&&(identical(other.activeDrivers, activeDrivers) || other.activeDrivers == activeDrivers)&&(identical(other.payingDrivers, payingDrivers) || other.payingDrivers == payingDrivers)&&(identical(other.negativeMarginDrivers, negativeMarginDrivers) || other.negativeMarginDrivers == negativeMarginDrivers)&&(identical(other.costPerActiveDriverMinor, costPerActiveDriverMinor) || other.costPerActiveDriverMinor == costPerActiveDriverMinor)&&(identical(other.revenuePerPayingDriverMinor, revenuePerPayingDriverMinor) || other.revenuePerPayingDriverMinor == revenuePerPayingDriverMinor)&&const DeepCollectionEquality().equals(other._costByConcept, _costByConcept)&&(identical(other.ratesMissing, ratesMissing) || other.ratesMissing == ratesMissing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,revenueMinor,infraCostMinor,marginMinor,marginPct,drivers,activeDrivers,payingDrivers,negativeMarginDrivers,costPerActiveDriverMinor,revenuePerPayingDriverMinor,const DeepCollectionEquality().hash(_costByConcept),ratesMissing);

@override
String toString() {
  return 'FinanceMonth(month: $month, revenueMinor: $revenueMinor, infraCostMinor: $infraCostMinor, marginMinor: $marginMinor, marginPct: $marginPct, drivers: $drivers, activeDrivers: $activeDrivers, payingDrivers: $payingDrivers, negativeMarginDrivers: $negativeMarginDrivers, costPerActiveDriverMinor: $costPerActiveDriverMinor, revenuePerPayingDriverMinor: $revenuePerPayingDriverMinor, costByConcept: $costByConcept, ratesMissing: $ratesMissing)';
}


}

/// @nodoc
abstract mixin class _$FinanceMonthCopyWith<$Res> implements $FinanceMonthCopyWith<$Res> {
  factory _$FinanceMonthCopyWith(_FinanceMonth value, $Res Function(_FinanceMonth) _then) = __$FinanceMonthCopyWithImpl;
@override @useResult
$Res call({
 String month, int revenueMinor, double infraCostMinor, double marginMinor, double? marginPct, int drivers, int activeDrivers, int payingDrivers, int negativeMarginDrivers, double? costPerActiveDriverMinor, double? revenuePerPayingDriverMinor, List<FinanceConceptCost> costByConcept, bool ratesMissing
});




}
/// @nodoc
class __$FinanceMonthCopyWithImpl<$Res>
    implements _$FinanceMonthCopyWith<$Res> {
  __$FinanceMonthCopyWithImpl(this._self, this._then);

  final _FinanceMonth _self;
  final $Res Function(_FinanceMonth) _then;

/// Create a copy of FinanceMonth
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? revenueMinor = null,Object? infraCostMinor = null,Object? marginMinor = null,Object? marginPct = freezed,Object? drivers = null,Object? activeDrivers = null,Object? payingDrivers = null,Object? negativeMarginDrivers = null,Object? costPerActiveDriverMinor = freezed,Object? revenuePerPayingDriverMinor = freezed,Object? costByConcept = null,Object? ratesMissing = null,}) {
  return _then(_FinanceMonth(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,revenueMinor: null == revenueMinor ? _self.revenueMinor : revenueMinor // ignore: cast_nullable_to_non_nullable
as int,infraCostMinor: null == infraCostMinor ? _self.infraCostMinor : infraCostMinor // ignore: cast_nullable_to_non_nullable
as double,marginMinor: null == marginMinor ? _self.marginMinor : marginMinor // ignore: cast_nullable_to_non_nullable
as double,marginPct: freezed == marginPct ? _self.marginPct : marginPct // ignore: cast_nullable_to_non_nullable
as double?,drivers: null == drivers ? _self.drivers : drivers // ignore: cast_nullable_to_non_nullable
as int,activeDrivers: null == activeDrivers ? _self.activeDrivers : activeDrivers // ignore: cast_nullable_to_non_nullable
as int,payingDrivers: null == payingDrivers ? _self.payingDrivers : payingDrivers // ignore: cast_nullable_to_non_nullable
as int,negativeMarginDrivers: null == negativeMarginDrivers ? _self.negativeMarginDrivers : negativeMarginDrivers // ignore: cast_nullable_to_non_nullable
as int,costPerActiveDriverMinor: freezed == costPerActiveDriverMinor ? _self.costPerActiveDriverMinor : costPerActiveDriverMinor // ignore: cast_nullable_to_non_nullable
as double?,revenuePerPayingDriverMinor: freezed == revenuePerPayingDriverMinor ? _self.revenuePerPayingDriverMinor : revenuePerPayingDriverMinor // ignore: cast_nullable_to_non_nullable
as double?,costByConcept: null == costByConcept ? _self._costByConcept : costByConcept // ignore: cast_nullable_to_non_nullable
as List<FinanceConceptCost>,ratesMissing: null == ratesMissing ? _self.ratesMissing : ratesMissing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$FinanceTotals {

 int get revenueMinor; double get infraCostMinor; double get marginMinor; double? get marginPct;
/// Create a copy of FinanceTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinanceTotalsCopyWith<FinanceTotals> get copyWith => _$FinanceTotalsCopyWithImpl<FinanceTotals>(this as FinanceTotals, _$identity);

  /// Serializes this FinanceTotals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinanceTotals&&(identical(other.revenueMinor, revenueMinor) || other.revenueMinor == revenueMinor)&&(identical(other.infraCostMinor, infraCostMinor) || other.infraCostMinor == infraCostMinor)&&(identical(other.marginMinor, marginMinor) || other.marginMinor == marginMinor)&&(identical(other.marginPct, marginPct) || other.marginPct == marginPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,revenueMinor,infraCostMinor,marginMinor,marginPct);

@override
String toString() {
  return 'FinanceTotals(revenueMinor: $revenueMinor, infraCostMinor: $infraCostMinor, marginMinor: $marginMinor, marginPct: $marginPct)';
}


}

/// @nodoc
abstract mixin class $FinanceTotalsCopyWith<$Res>  {
  factory $FinanceTotalsCopyWith(FinanceTotals value, $Res Function(FinanceTotals) _then) = _$FinanceTotalsCopyWithImpl;
@useResult
$Res call({
 int revenueMinor, double infraCostMinor, double marginMinor, double? marginPct
});




}
/// @nodoc
class _$FinanceTotalsCopyWithImpl<$Res>
    implements $FinanceTotalsCopyWith<$Res> {
  _$FinanceTotalsCopyWithImpl(this._self, this._then);

  final FinanceTotals _self;
  final $Res Function(FinanceTotals) _then;

/// Create a copy of FinanceTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? revenueMinor = null,Object? infraCostMinor = null,Object? marginMinor = null,Object? marginPct = freezed,}) {
  return _then(_self.copyWith(
revenueMinor: null == revenueMinor ? _self.revenueMinor : revenueMinor // ignore: cast_nullable_to_non_nullable
as int,infraCostMinor: null == infraCostMinor ? _self.infraCostMinor : infraCostMinor // ignore: cast_nullable_to_non_nullable
as double,marginMinor: null == marginMinor ? _self.marginMinor : marginMinor // ignore: cast_nullable_to_non_nullable
as double,marginPct: freezed == marginPct ? _self.marginPct : marginPct // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [FinanceTotals].
extension FinanceTotalsPatterns on FinanceTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinanceTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinanceTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinanceTotals value)  $default,){
final _that = this;
switch (_that) {
case _FinanceTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinanceTotals value)?  $default,){
final _that = this;
switch (_that) {
case _FinanceTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int revenueMinor,  double infraCostMinor,  double marginMinor,  double? marginPct)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinanceTotals() when $default != null:
return $default(_that.revenueMinor,_that.infraCostMinor,_that.marginMinor,_that.marginPct);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int revenueMinor,  double infraCostMinor,  double marginMinor,  double? marginPct)  $default,) {final _that = this;
switch (_that) {
case _FinanceTotals():
return $default(_that.revenueMinor,_that.infraCostMinor,_that.marginMinor,_that.marginPct);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int revenueMinor,  double infraCostMinor,  double marginMinor,  double? marginPct)?  $default,) {final _that = this;
switch (_that) {
case _FinanceTotals() when $default != null:
return $default(_that.revenueMinor,_that.infraCostMinor,_that.marginMinor,_that.marginPct);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinanceTotals implements FinanceTotals {
  const _FinanceTotals({this.revenueMinor = 0, this.infraCostMinor = 0, this.marginMinor = 0, this.marginPct});
  factory _FinanceTotals.fromJson(Map<String, dynamic> json) => _$FinanceTotalsFromJson(json);

@override@JsonKey() final  int revenueMinor;
@override@JsonKey() final  double infraCostMinor;
@override@JsonKey() final  double marginMinor;
@override final  double? marginPct;

/// Create a copy of FinanceTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinanceTotalsCopyWith<_FinanceTotals> get copyWith => __$FinanceTotalsCopyWithImpl<_FinanceTotals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinanceTotalsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinanceTotals&&(identical(other.revenueMinor, revenueMinor) || other.revenueMinor == revenueMinor)&&(identical(other.infraCostMinor, infraCostMinor) || other.infraCostMinor == infraCostMinor)&&(identical(other.marginMinor, marginMinor) || other.marginMinor == marginMinor)&&(identical(other.marginPct, marginPct) || other.marginPct == marginPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,revenueMinor,infraCostMinor,marginMinor,marginPct);

@override
String toString() {
  return 'FinanceTotals(revenueMinor: $revenueMinor, infraCostMinor: $infraCostMinor, marginMinor: $marginMinor, marginPct: $marginPct)';
}


}

/// @nodoc
abstract mixin class _$FinanceTotalsCopyWith<$Res> implements $FinanceTotalsCopyWith<$Res> {
  factory _$FinanceTotalsCopyWith(_FinanceTotals value, $Res Function(_FinanceTotals) _then) = __$FinanceTotalsCopyWithImpl;
@override @useResult
$Res call({
 int revenueMinor, double infraCostMinor, double marginMinor, double? marginPct
});




}
/// @nodoc
class __$FinanceTotalsCopyWithImpl<$Res>
    implements _$FinanceTotalsCopyWith<$Res> {
  __$FinanceTotalsCopyWithImpl(this._self, this._then);

  final _FinanceTotals _self;
  final $Res Function(_FinanceTotals) _then;

/// Create a copy of FinanceTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? revenueMinor = null,Object? infraCostMinor = null,Object? marginMinor = null,Object? marginPct = freezed,}) {
  return _then(_FinanceTotals(
revenueMinor: null == revenueMinor ? _self.revenueMinor : revenueMinor // ignore: cast_nullable_to_non_nullable
as int,infraCostMinor: null == infraCostMinor ? _self.infraCostMinor : infraCostMinor // ignore: cast_nullable_to_non_nullable
as double,marginMinor: null == marginMinor ? _self.marginMinor : marginMinor // ignore: cast_nullable_to_non_nullable
as double,marginPct: freezed == marginPct ? _self.marginPct : marginPct // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$FinanceReport {

 String get currency; List<FinanceMonth> get months; FinanceTotals get totals;
/// Create a copy of FinanceReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinanceReportCopyWith<FinanceReport> get copyWith => _$FinanceReportCopyWithImpl<FinanceReport>(this as FinanceReport, _$identity);

  /// Serializes this FinanceReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinanceReport&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.months, months)&&(identical(other.totals, totals) || other.totals == totals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currency,const DeepCollectionEquality().hash(months),totals);

@override
String toString() {
  return 'FinanceReport(currency: $currency, months: $months, totals: $totals)';
}


}

/// @nodoc
abstract mixin class $FinanceReportCopyWith<$Res>  {
  factory $FinanceReportCopyWith(FinanceReport value, $Res Function(FinanceReport) _then) = _$FinanceReportCopyWithImpl;
@useResult
$Res call({
 String currency, List<FinanceMonth> months, FinanceTotals totals
});


$FinanceTotalsCopyWith<$Res> get totals;

}
/// @nodoc
class _$FinanceReportCopyWithImpl<$Res>
    implements $FinanceReportCopyWith<$Res> {
  _$FinanceReportCopyWithImpl(this._self, this._then);

  final FinanceReport _self;
  final $Res Function(FinanceReport) _then;

/// Create a copy of FinanceReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currency = null,Object? months = null,Object? totals = null,}) {
  return _then(_self.copyWith(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,months: null == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as List<FinanceMonth>,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as FinanceTotals,
  ));
}
/// Create a copy of FinanceReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FinanceTotalsCopyWith<$Res> get totals {
  
  return $FinanceTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}


/// Adds pattern-matching-related methods to [FinanceReport].
extension FinanceReportPatterns on FinanceReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinanceReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinanceReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinanceReport value)  $default,){
final _that = this;
switch (_that) {
case _FinanceReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinanceReport value)?  $default,){
final _that = this;
switch (_that) {
case _FinanceReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currency,  List<FinanceMonth> months,  FinanceTotals totals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinanceReport() when $default != null:
return $default(_that.currency,_that.months,_that.totals);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currency,  List<FinanceMonth> months,  FinanceTotals totals)  $default,) {final _that = this;
switch (_that) {
case _FinanceReport():
return $default(_that.currency,_that.months,_that.totals);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currency,  List<FinanceMonth> months,  FinanceTotals totals)?  $default,) {final _that = this;
switch (_that) {
case _FinanceReport() when $default != null:
return $default(_that.currency,_that.months,_that.totals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinanceReport implements FinanceReport {
  const _FinanceReport({this.currency = 'COP', final  List<FinanceMonth> months = const <FinanceMonth>[], this.totals = const FinanceTotals()}): _months = months;
  factory _FinanceReport.fromJson(Map<String, dynamic> json) => _$FinanceReportFromJson(json);

@override@JsonKey() final  String currency;
 final  List<FinanceMonth> _months;
@override@JsonKey() List<FinanceMonth> get months {
  if (_months is EqualUnmodifiableListView) return _months;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_months);
}

@override@JsonKey() final  FinanceTotals totals;

/// Create a copy of FinanceReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinanceReportCopyWith<_FinanceReport> get copyWith => __$FinanceReportCopyWithImpl<_FinanceReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinanceReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinanceReport&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other._months, _months)&&(identical(other.totals, totals) || other.totals == totals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currency,const DeepCollectionEquality().hash(_months),totals);

@override
String toString() {
  return 'FinanceReport(currency: $currency, months: $months, totals: $totals)';
}


}

/// @nodoc
abstract mixin class _$FinanceReportCopyWith<$Res> implements $FinanceReportCopyWith<$Res> {
  factory _$FinanceReportCopyWith(_FinanceReport value, $Res Function(_FinanceReport) _then) = __$FinanceReportCopyWithImpl;
@override @useResult
$Res call({
 String currency, List<FinanceMonth> months, FinanceTotals totals
});


@override $FinanceTotalsCopyWith<$Res> get totals;

}
/// @nodoc
class __$FinanceReportCopyWithImpl<$Res>
    implements _$FinanceReportCopyWith<$Res> {
  __$FinanceReportCopyWithImpl(this._self, this._then);

  final _FinanceReport _self;
  final $Res Function(_FinanceReport) _then;

/// Create a copy of FinanceReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currency = null,Object? months = null,Object? totals = null,}) {
  return _then(_FinanceReport(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,months: null == months ? _self._months : months // ignore: cast_nullable_to_non_nullable
as List<FinanceMonth>,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as FinanceTotals,
  ));
}

/// Create a copy of FinanceReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FinanceTotalsCopyWith<$Res> get totals {
  
  return $FinanceTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}


/// @nodoc
mixin _$CrmWeek {

 DateTime get weekStart; int get created; int get removed; int get activeEnd;
/// Create a copy of CrmWeek
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CrmWeekCopyWith<CrmWeek> get copyWith => _$CrmWeekCopyWithImpl<CrmWeek>(this as CrmWeek, _$identity);

  /// Serializes this CrmWeek to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrmWeek&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.created, created) || other.created == created)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.activeEnd, activeEnd) || other.activeEnd == activeEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekStart,created,removed,activeEnd);

@override
String toString() {
  return 'CrmWeek(weekStart: $weekStart, created: $created, removed: $removed, activeEnd: $activeEnd)';
}


}

/// @nodoc
abstract mixin class $CrmWeekCopyWith<$Res>  {
  factory $CrmWeekCopyWith(CrmWeek value, $Res Function(CrmWeek) _then) = _$CrmWeekCopyWithImpl;
@useResult
$Res call({
 DateTime weekStart, int created, int removed, int activeEnd
});




}
/// @nodoc
class _$CrmWeekCopyWithImpl<$Res>
    implements $CrmWeekCopyWith<$Res> {
  _$CrmWeekCopyWithImpl(this._self, this._then);

  final CrmWeek _self;
  final $Res Function(CrmWeek) _then;

/// Create a copy of CrmWeek
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekStart = null,Object? created = null,Object? removed = null,Object? activeEnd = null,}) {
  return _then(_self.copyWith(
weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,activeEnd: null == activeEnd ? _self.activeEnd : activeEnd // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CrmWeek].
extension CrmWeekPatterns on CrmWeek {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CrmWeek value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CrmWeek() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CrmWeek value)  $default,){
final _that = this;
switch (_that) {
case _CrmWeek():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CrmWeek value)?  $default,){
final _that = this;
switch (_that) {
case _CrmWeek() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime weekStart,  int created,  int removed,  int activeEnd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CrmWeek() when $default != null:
return $default(_that.weekStart,_that.created,_that.removed,_that.activeEnd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime weekStart,  int created,  int removed,  int activeEnd)  $default,) {final _that = this;
switch (_that) {
case _CrmWeek():
return $default(_that.weekStart,_that.created,_that.removed,_that.activeEnd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime weekStart,  int created,  int removed,  int activeEnd)?  $default,) {final _that = this;
switch (_that) {
case _CrmWeek() when $default != null:
return $default(_that.weekStart,_that.created,_that.removed,_that.activeEnd);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CrmWeek implements CrmWeek {
  const _CrmWeek({required this.weekStart, this.created = 0, this.removed = 0, this.activeEnd = 0});
  factory _CrmWeek.fromJson(Map<String, dynamic> json) => _$CrmWeekFromJson(json);

@override final  DateTime weekStart;
@override@JsonKey() final  int created;
@override@JsonKey() final  int removed;
@override@JsonKey() final  int activeEnd;

/// Create a copy of CrmWeek
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CrmWeekCopyWith<_CrmWeek> get copyWith => __$CrmWeekCopyWithImpl<_CrmWeek>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CrmWeekToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CrmWeek&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.created, created) || other.created == created)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.activeEnd, activeEnd) || other.activeEnd == activeEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekStart,created,removed,activeEnd);

@override
String toString() {
  return 'CrmWeek(weekStart: $weekStart, created: $created, removed: $removed, activeEnd: $activeEnd)';
}


}

/// @nodoc
abstract mixin class _$CrmWeekCopyWith<$Res> implements $CrmWeekCopyWith<$Res> {
  factory _$CrmWeekCopyWith(_CrmWeek value, $Res Function(_CrmWeek) _then) = __$CrmWeekCopyWithImpl;
@override @useResult
$Res call({
 DateTime weekStart, int created, int removed, int activeEnd
});




}
/// @nodoc
class __$CrmWeekCopyWithImpl<$Res>
    implements _$CrmWeekCopyWith<$Res> {
  __$CrmWeekCopyWithImpl(this._self, this._then);

  final _CrmWeek _self;
  final $Res Function(_CrmWeek) _then;

/// Create a copy of CrmWeek
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekStart = null,Object? created = null,Object? removed = null,Object? activeEnd = null,}) {
  return _then(_CrmWeek(
weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,activeEnd: null == activeEnd ? _self.activeEnd : activeEnd // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CrmAffiliations {

 int get activeNow; int get activeAtStart; int get created; int get removed; int get net; double? get churnRate; List<CrmWeek> get weekly;/// 008: altas por origen (`qr_scan`, `post_trip`, `link`).
 Map<String, int> get createdBySource;
/// Create a copy of CrmAffiliations
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CrmAffiliationsCopyWith<CrmAffiliations> get copyWith => _$CrmAffiliationsCopyWithImpl<CrmAffiliations>(this as CrmAffiliations, _$identity);

  /// Serializes this CrmAffiliations to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrmAffiliations&&(identical(other.activeNow, activeNow) || other.activeNow == activeNow)&&(identical(other.activeAtStart, activeAtStart) || other.activeAtStart == activeAtStart)&&(identical(other.created, created) || other.created == created)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.net, net) || other.net == net)&&(identical(other.churnRate, churnRate) || other.churnRate == churnRate)&&const DeepCollectionEquality().equals(other.weekly, weekly)&&const DeepCollectionEquality().equals(other.createdBySource, createdBySource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activeNow,activeAtStart,created,removed,net,churnRate,const DeepCollectionEquality().hash(weekly),const DeepCollectionEquality().hash(createdBySource));

@override
String toString() {
  return 'CrmAffiliations(activeNow: $activeNow, activeAtStart: $activeAtStart, created: $created, removed: $removed, net: $net, churnRate: $churnRate, weekly: $weekly, createdBySource: $createdBySource)';
}


}

/// @nodoc
abstract mixin class $CrmAffiliationsCopyWith<$Res>  {
  factory $CrmAffiliationsCopyWith(CrmAffiliations value, $Res Function(CrmAffiliations) _then) = _$CrmAffiliationsCopyWithImpl;
@useResult
$Res call({
 int activeNow, int activeAtStart, int created, int removed, int net, double? churnRate, List<CrmWeek> weekly, Map<String, int> createdBySource
});




}
/// @nodoc
class _$CrmAffiliationsCopyWithImpl<$Res>
    implements $CrmAffiliationsCopyWith<$Res> {
  _$CrmAffiliationsCopyWithImpl(this._self, this._then);

  final CrmAffiliations _self;
  final $Res Function(CrmAffiliations) _then;

/// Create a copy of CrmAffiliations
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeNow = null,Object? activeAtStart = null,Object? created = null,Object? removed = null,Object? net = null,Object? churnRate = freezed,Object? weekly = null,Object? createdBySource = null,}) {
  return _then(_self.copyWith(
activeNow: null == activeNow ? _self.activeNow : activeNow // ignore: cast_nullable_to_non_nullable
as int,activeAtStart: null == activeAtStart ? _self.activeAtStart : activeAtStart // ignore: cast_nullable_to_non_nullable
as int,created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,churnRate: freezed == churnRate ? _self.churnRate : churnRate // ignore: cast_nullable_to_non_nullable
as double?,weekly: null == weekly ? _self.weekly : weekly // ignore: cast_nullable_to_non_nullable
as List<CrmWeek>,createdBySource: null == createdBySource ? _self.createdBySource : createdBySource // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [CrmAffiliations].
extension CrmAffiliationsPatterns on CrmAffiliations {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CrmAffiliations value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CrmAffiliations() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CrmAffiliations value)  $default,){
final _that = this;
switch (_that) {
case _CrmAffiliations():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CrmAffiliations value)?  $default,){
final _that = this;
switch (_that) {
case _CrmAffiliations() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int activeNow,  int activeAtStart,  int created,  int removed,  int net,  double? churnRate,  List<CrmWeek> weekly,  Map<String, int> createdBySource)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CrmAffiliations() when $default != null:
return $default(_that.activeNow,_that.activeAtStart,_that.created,_that.removed,_that.net,_that.churnRate,_that.weekly,_that.createdBySource);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int activeNow,  int activeAtStart,  int created,  int removed,  int net,  double? churnRate,  List<CrmWeek> weekly,  Map<String, int> createdBySource)  $default,) {final _that = this;
switch (_that) {
case _CrmAffiliations():
return $default(_that.activeNow,_that.activeAtStart,_that.created,_that.removed,_that.net,_that.churnRate,_that.weekly,_that.createdBySource);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int activeNow,  int activeAtStart,  int created,  int removed,  int net,  double? churnRate,  List<CrmWeek> weekly,  Map<String, int> createdBySource)?  $default,) {final _that = this;
switch (_that) {
case _CrmAffiliations() when $default != null:
return $default(_that.activeNow,_that.activeAtStart,_that.created,_that.removed,_that.net,_that.churnRate,_that.weekly,_that.createdBySource);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CrmAffiliations implements CrmAffiliations {
  const _CrmAffiliations({this.activeNow = 0, this.activeAtStart = 0, this.created = 0, this.removed = 0, this.net = 0, this.churnRate, final  List<CrmWeek> weekly = const <CrmWeek>[], final  Map<String, int> createdBySource = const <String, int>{}}): _weekly = weekly,_createdBySource = createdBySource;
  factory _CrmAffiliations.fromJson(Map<String, dynamic> json) => _$CrmAffiliationsFromJson(json);

@override@JsonKey() final  int activeNow;
@override@JsonKey() final  int activeAtStart;
@override@JsonKey() final  int created;
@override@JsonKey() final  int removed;
@override@JsonKey() final  int net;
@override final  double? churnRate;
 final  List<CrmWeek> _weekly;
@override@JsonKey() List<CrmWeek> get weekly {
  if (_weekly is EqualUnmodifiableListView) return _weekly;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekly);
}

/// 008: altas por origen (`qr_scan`, `post_trip`, `link`).
 final  Map<String, int> _createdBySource;
/// 008: altas por origen (`qr_scan`, `post_trip`, `link`).
@override@JsonKey() Map<String, int> get createdBySource {
  if (_createdBySource is EqualUnmodifiableMapView) return _createdBySource;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_createdBySource);
}


/// Create a copy of CrmAffiliations
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CrmAffiliationsCopyWith<_CrmAffiliations> get copyWith => __$CrmAffiliationsCopyWithImpl<_CrmAffiliations>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CrmAffiliationsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CrmAffiliations&&(identical(other.activeNow, activeNow) || other.activeNow == activeNow)&&(identical(other.activeAtStart, activeAtStart) || other.activeAtStart == activeAtStart)&&(identical(other.created, created) || other.created == created)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.net, net) || other.net == net)&&(identical(other.churnRate, churnRate) || other.churnRate == churnRate)&&const DeepCollectionEquality().equals(other._weekly, _weekly)&&const DeepCollectionEquality().equals(other._createdBySource, _createdBySource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activeNow,activeAtStart,created,removed,net,churnRate,const DeepCollectionEquality().hash(_weekly),const DeepCollectionEquality().hash(_createdBySource));

@override
String toString() {
  return 'CrmAffiliations(activeNow: $activeNow, activeAtStart: $activeAtStart, created: $created, removed: $removed, net: $net, churnRate: $churnRate, weekly: $weekly, createdBySource: $createdBySource)';
}


}

/// @nodoc
abstract mixin class _$CrmAffiliationsCopyWith<$Res> implements $CrmAffiliationsCopyWith<$Res> {
  factory _$CrmAffiliationsCopyWith(_CrmAffiliations value, $Res Function(_CrmAffiliations) _then) = __$CrmAffiliationsCopyWithImpl;
@override @useResult
$Res call({
 int activeNow, int activeAtStart, int created, int removed, int net, double? churnRate, List<CrmWeek> weekly, Map<String, int> createdBySource
});




}
/// @nodoc
class __$CrmAffiliationsCopyWithImpl<$Res>
    implements _$CrmAffiliationsCopyWith<$Res> {
  __$CrmAffiliationsCopyWithImpl(this._self, this._then);

  final _CrmAffiliations _self;
  final $Res Function(_CrmAffiliations) _then;

/// Create a copy of CrmAffiliations
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeNow = null,Object? activeAtStart = null,Object? created = null,Object? removed = null,Object? net = null,Object? churnRate = freezed,Object? weekly = null,Object? createdBySource = null,}) {
  return _then(_CrmAffiliations(
activeNow: null == activeNow ? _self.activeNow : activeNow // ignore: cast_nullable_to_non_nullable
as int,activeAtStart: null == activeAtStart ? _self.activeAtStart : activeAtStart // ignore: cast_nullable_to_non_nullable
as int,created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,churnRate: freezed == churnRate ? _self.churnRate : churnRate // ignore: cast_nullable_to_non_nullable
as double?,weekly: null == weekly ? _self._weekly : weekly // ignore: cast_nullable_to_non_nullable
as List<CrmWeek>,createdBySource: null == createdBySource ? _self._createdBySource : createdBySource // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}


/// @nodoc
mixin _$CrmRepeat {

 int get pairs; int get repeatPairs; double? get repeatRate; int get completedTrips; double? get avgTripsPerPair;
/// Create a copy of CrmRepeat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CrmRepeatCopyWith<CrmRepeat> get copyWith => _$CrmRepeatCopyWithImpl<CrmRepeat>(this as CrmRepeat, _$identity);

  /// Serializes this CrmRepeat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrmRepeat&&(identical(other.pairs, pairs) || other.pairs == pairs)&&(identical(other.repeatPairs, repeatPairs) || other.repeatPairs == repeatPairs)&&(identical(other.repeatRate, repeatRate) || other.repeatRate == repeatRate)&&(identical(other.completedTrips, completedTrips) || other.completedTrips == completedTrips)&&(identical(other.avgTripsPerPair, avgTripsPerPair) || other.avgTripsPerPair == avgTripsPerPair));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pairs,repeatPairs,repeatRate,completedTrips,avgTripsPerPair);

@override
String toString() {
  return 'CrmRepeat(pairs: $pairs, repeatPairs: $repeatPairs, repeatRate: $repeatRate, completedTrips: $completedTrips, avgTripsPerPair: $avgTripsPerPair)';
}


}

/// @nodoc
abstract mixin class $CrmRepeatCopyWith<$Res>  {
  factory $CrmRepeatCopyWith(CrmRepeat value, $Res Function(CrmRepeat) _then) = _$CrmRepeatCopyWithImpl;
@useResult
$Res call({
 int pairs, int repeatPairs, double? repeatRate, int completedTrips, double? avgTripsPerPair
});




}
/// @nodoc
class _$CrmRepeatCopyWithImpl<$Res>
    implements $CrmRepeatCopyWith<$Res> {
  _$CrmRepeatCopyWithImpl(this._self, this._then);

  final CrmRepeat _self;
  final $Res Function(CrmRepeat) _then;

/// Create a copy of CrmRepeat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pairs = null,Object? repeatPairs = null,Object? repeatRate = freezed,Object? completedTrips = null,Object? avgTripsPerPair = freezed,}) {
  return _then(_self.copyWith(
pairs: null == pairs ? _self.pairs : pairs // ignore: cast_nullable_to_non_nullable
as int,repeatPairs: null == repeatPairs ? _self.repeatPairs : repeatPairs // ignore: cast_nullable_to_non_nullable
as int,repeatRate: freezed == repeatRate ? _self.repeatRate : repeatRate // ignore: cast_nullable_to_non_nullable
as double?,completedTrips: null == completedTrips ? _self.completedTrips : completedTrips // ignore: cast_nullable_to_non_nullable
as int,avgTripsPerPair: freezed == avgTripsPerPair ? _self.avgTripsPerPair : avgTripsPerPair // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [CrmRepeat].
extension CrmRepeatPatterns on CrmRepeat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CrmRepeat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CrmRepeat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CrmRepeat value)  $default,){
final _that = this;
switch (_that) {
case _CrmRepeat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CrmRepeat value)?  $default,){
final _that = this;
switch (_that) {
case _CrmRepeat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int pairs,  int repeatPairs,  double? repeatRate,  int completedTrips,  double? avgTripsPerPair)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CrmRepeat() when $default != null:
return $default(_that.pairs,_that.repeatPairs,_that.repeatRate,_that.completedTrips,_that.avgTripsPerPair);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int pairs,  int repeatPairs,  double? repeatRate,  int completedTrips,  double? avgTripsPerPair)  $default,) {final _that = this;
switch (_that) {
case _CrmRepeat():
return $default(_that.pairs,_that.repeatPairs,_that.repeatRate,_that.completedTrips,_that.avgTripsPerPair);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int pairs,  int repeatPairs,  double? repeatRate,  int completedTrips,  double? avgTripsPerPair)?  $default,) {final _that = this;
switch (_that) {
case _CrmRepeat() when $default != null:
return $default(_that.pairs,_that.repeatPairs,_that.repeatRate,_that.completedTrips,_that.avgTripsPerPair);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CrmRepeat implements CrmRepeat {
  const _CrmRepeat({this.pairs = 0, this.repeatPairs = 0, this.repeatRate, this.completedTrips = 0, this.avgTripsPerPair});
  factory _CrmRepeat.fromJson(Map<String, dynamic> json) => _$CrmRepeatFromJson(json);

@override@JsonKey() final  int pairs;
@override@JsonKey() final  int repeatPairs;
@override final  double? repeatRate;
@override@JsonKey() final  int completedTrips;
@override final  double? avgTripsPerPair;

/// Create a copy of CrmRepeat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CrmRepeatCopyWith<_CrmRepeat> get copyWith => __$CrmRepeatCopyWithImpl<_CrmRepeat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CrmRepeatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CrmRepeat&&(identical(other.pairs, pairs) || other.pairs == pairs)&&(identical(other.repeatPairs, repeatPairs) || other.repeatPairs == repeatPairs)&&(identical(other.repeatRate, repeatRate) || other.repeatRate == repeatRate)&&(identical(other.completedTrips, completedTrips) || other.completedTrips == completedTrips)&&(identical(other.avgTripsPerPair, avgTripsPerPair) || other.avgTripsPerPair == avgTripsPerPair));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pairs,repeatPairs,repeatRate,completedTrips,avgTripsPerPair);

@override
String toString() {
  return 'CrmRepeat(pairs: $pairs, repeatPairs: $repeatPairs, repeatRate: $repeatRate, completedTrips: $completedTrips, avgTripsPerPair: $avgTripsPerPair)';
}


}

/// @nodoc
abstract mixin class _$CrmRepeatCopyWith<$Res> implements $CrmRepeatCopyWith<$Res> {
  factory _$CrmRepeatCopyWith(_CrmRepeat value, $Res Function(_CrmRepeat) _then) = __$CrmRepeatCopyWithImpl;
@override @useResult
$Res call({
 int pairs, int repeatPairs, double? repeatRate, int completedTrips, double? avgTripsPerPair
});




}
/// @nodoc
class __$CrmRepeatCopyWithImpl<$Res>
    implements _$CrmRepeatCopyWith<$Res> {
  __$CrmRepeatCopyWithImpl(this._self, this._then);

  final _CrmRepeat _self;
  final $Res Function(_CrmRepeat) _then;

/// Create a copy of CrmRepeat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pairs = null,Object? repeatPairs = null,Object? repeatRate = freezed,Object? completedTrips = null,Object? avgTripsPerPair = freezed,}) {
  return _then(_CrmRepeat(
pairs: null == pairs ? _self.pairs : pairs // ignore: cast_nullable_to_non_nullable
as int,repeatPairs: null == repeatPairs ? _self.repeatPairs : repeatPairs // ignore: cast_nullable_to_non_nullable
as int,repeatRate: freezed == repeatRate ? _self.repeatRate : repeatRate // ignore: cast_nullable_to_non_nullable
as double?,completedTrips: null == completedTrips ? _self.completedTrips : completedTrips // ignore: cast_nullable_to_non_nullable
as int,avgTripsPerPair: freezed == avgTripsPerPair ? _self.avgTripsPerPair : avgTripsPerPair // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$Sc008 {

 int get matured;@JsonKey(name: 'with_request_30d') int get withRequest30d; double? get rate; double get target; bool? get met; int get pending;
/// Create a copy of Sc008
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Sc008CopyWith<Sc008> get copyWith => _$Sc008CopyWithImpl<Sc008>(this as Sc008, _$identity);

  /// Serializes this Sc008 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Sc008&&(identical(other.matured, matured) || other.matured == matured)&&(identical(other.withRequest30d, withRequest30d) || other.withRequest30d == withRequest30d)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.target, target) || other.target == target)&&(identical(other.met, met) || other.met == met)&&(identical(other.pending, pending) || other.pending == pending));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matured,withRequest30d,rate,target,met,pending);

@override
String toString() {
  return 'Sc008(matured: $matured, withRequest30d: $withRequest30d, rate: $rate, target: $target, met: $met, pending: $pending)';
}


}

/// @nodoc
abstract mixin class $Sc008CopyWith<$Res>  {
  factory $Sc008CopyWith(Sc008 value, $Res Function(Sc008) _then) = _$Sc008CopyWithImpl;
@useResult
$Res call({
 int matured,@JsonKey(name: 'with_request_30d') int withRequest30d, double? rate, double target, bool? met, int pending
});




}
/// @nodoc
class _$Sc008CopyWithImpl<$Res>
    implements $Sc008CopyWith<$Res> {
  _$Sc008CopyWithImpl(this._self, this._then);

  final Sc008 _self;
  final $Res Function(Sc008) _then;

/// Create a copy of Sc008
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? matured = null,Object? withRequest30d = null,Object? rate = freezed,Object? target = null,Object? met = freezed,Object? pending = null,}) {
  return _then(_self.copyWith(
matured: null == matured ? _self.matured : matured // ignore: cast_nullable_to_non_nullable
as int,withRequest30d: null == withRequest30d ? _self.withRequest30d : withRequest30d // ignore: cast_nullable_to_non_nullable
as int,rate: freezed == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double?,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as double,met: freezed == met ? _self.met : met // ignore: cast_nullable_to_non_nullable
as bool?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Sc008].
extension Sc008Patterns on Sc008 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Sc008 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Sc008() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Sc008 value)  $default,){
final _that = this;
switch (_that) {
case _Sc008():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Sc008 value)?  $default,){
final _that = this;
switch (_that) {
case _Sc008() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int matured, @JsonKey(name: 'with_request_30d')  int withRequest30d,  double? rate,  double target,  bool? met,  int pending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Sc008() when $default != null:
return $default(_that.matured,_that.withRequest30d,_that.rate,_that.target,_that.met,_that.pending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int matured, @JsonKey(name: 'with_request_30d')  int withRequest30d,  double? rate,  double target,  bool? met,  int pending)  $default,) {final _that = this;
switch (_that) {
case _Sc008():
return $default(_that.matured,_that.withRequest30d,_that.rate,_that.target,_that.met,_that.pending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int matured, @JsonKey(name: 'with_request_30d')  int withRequest30d,  double? rate,  double target,  bool? met,  int pending)?  $default,) {final _that = this;
switch (_that) {
case _Sc008() when $default != null:
return $default(_that.matured,_that.withRequest30d,_that.rate,_that.target,_that.met,_that.pending);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Sc008 implements Sc008 {
  const _Sc008({this.matured = 0, @JsonKey(name: 'with_request_30d') this.withRequest30d = 0, this.rate, this.target = 0.8, this.met, this.pending = 0});
  factory _Sc008.fromJson(Map<String, dynamic> json) => _$Sc008FromJson(json);

@override@JsonKey() final  int matured;
@override@JsonKey(name: 'with_request_30d') final  int withRequest30d;
@override final  double? rate;
@override@JsonKey() final  double target;
@override final  bool? met;
@override@JsonKey() final  int pending;

/// Create a copy of Sc008
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Sc008CopyWith<_Sc008> get copyWith => __$Sc008CopyWithImpl<_Sc008>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Sc008ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Sc008&&(identical(other.matured, matured) || other.matured == matured)&&(identical(other.withRequest30d, withRequest30d) || other.withRequest30d == withRequest30d)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.target, target) || other.target == target)&&(identical(other.met, met) || other.met == met)&&(identical(other.pending, pending) || other.pending == pending));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,matured,withRequest30d,rate,target,met,pending);

@override
String toString() {
  return 'Sc008(matured: $matured, withRequest30d: $withRequest30d, rate: $rate, target: $target, met: $met, pending: $pending)';
}


}

/// @nodoc
abstract mixin class _$Sc008CopyWith<$Res> implements $Sc008CopyWith<$Res> {
  factory _$Sc008CopyWith(_Sc008 value, $Res Function(_Sc008) _then) = __$Sc008CopyWithImpl;
@override @useResult
$Res call({
 int matured,@JsonKey(name: 'with_request_30d') int withRequest30d, double? rate, double target, bool? met, int pending
});




}
/// @nodoc
class __$Sc008CopyWithImpl<$Res>
    implements _$Sc008CopyWith<$Res> {
  __$Sc008CopyWithImpl(this._self, this._then);

  final _Sc008 _self;
  final $Res Function(_Sc008) _then;

/// Create a copy of Sc008
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? matured = null,Object? withRequest30d = null,Object? rate = freezed,Object? target = null,Object? met = freezed,Object? pending = null,}) {
  return _then(_Sc008(
matured: null == matured ? _self.matured : matured // ignore: cast_nullable_to_non_nullable
as int,withRequest30d: null == withRequest30d ? _self.withRequest30d : withRequest30d // ignore: cast_nullable_to_non_nullable
as int,rate: freezed == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double?,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as double,met: freezed == met ? _self.met : met // ignore: cast_nullable_to_non_nullable
as bool?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ChurnedDriver {

 String get driverId; String get displayName; int get removed; int get activeNow;
/// Create a copy of ChurnedDriver
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChurnedDriverCopyWith<ChurnedDriver> get copyWith => _$ChurnedDriverCopyWithImpl<ChurnedDriver>(this as ChurnedDriver, _$identity);

  /// Serializes this ChurnedDriver to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChurnedDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.activeNow, activeNow) || other.activeNow == activeNow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,removed,activeNow);

@override
String toString() {
  return 'ChurnedDriver(driverId: $driverId, displayName: $displayName, removed: $removed, activeNow: $activeNow)';
}


}

/// @nodoc
abstract mixin class $ChurnedDriverCopyWith<$Res>  {
  factory $ChurnedDriverCopyWith(ChurnedDriver value, $Res Function(ChurnedDriver) _then) = _$ChurnedDriverCopyWithImpl;
@useResult
$Res call({
 String driverId, String displayName, int removed, int activeNow
});




}
/// @nodoc
class _$ChurnedDriverCopyWithImpl<$Res>
    implements $ChurnedDriverCopyWith<$Res> {
  _$ChurnedDriverCopyWithImpl(this._self, this._then);

  final ChurnedDriver _self;
  final $Res Function(ChurnedDriver) _then;

/// Create a copy of ChurnedDriver
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? displayName = null,Object? removed = null,Object? activeNow = null,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,activeNow: null == activeNow ? _self.activeNow : activeNow // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChurnedDriver].
extension ChurnedDriverPatterns on ChurnedDriver {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChurnedDriver value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChurnedDriver() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChurnedDriver value)  $default,){
final _that = this;
switch (_that) {
case _ChurnedDriver():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChurnedDriver value)?  $default,){
final _that = this;
switch (_that) {
case _ChurnedDriver() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String displayName,  int removed,  int activeNow)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChurnedDriver() when $default != null:
return $default(_that.driverId,_that.displayName,_that.removed,_that.activeNow);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String displayName,  int removed,  int activeNow)  $default,) {final _that = this;
switch (_that) {
case _ChurnedDriver():
return $default(_that.driverId,_that.displayName,_that.removed,_that.activeNow);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String displayName,  int removed,  int activeNow)?  $default,) {final _that = this;
switch (_that) {
case _ChurnedDriver() when $default != null:
return $default(_that.driverId,_that.displayName,_that.removed,_that.activeNow);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChurnedDriver implements ChurnedDriver {
  const _ChurnedDriver({required this.driverId, required this.displayName, this.removed = 0, this.activeNow = 0});
  factory _ChurnedDriver.fromJson(Map<String, dynamic> json) => _$ChurnedDriverFromJson(json);

@override final  String driverId;
@override final  String displayName;
@override@JsonKey() final  int removed;
@override@JsonKey() final  int activeNow;

/// Create a copy of ChurnedDriver
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChurnedDriverCopyWith<_ChurnedDriver> get copyWith => __$ChurnedDriverCopyWithImpl<_ChurnedDriver>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChurnedDriverToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChurnedDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.activeNow, activeNow) || other.activeNow == activeNow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,removed,activeNow);

@override
String toString() {
  return 'ChurnedDriver(driverId: $driverId, displayName: $displayName, removed: $removed, activeNow: $activeNow)';
}


}

/// @nodoc
abstract mixin class _$ChurnedDriverCopyWith<$Res> implements $ChurnedDriverCopyWith<$Res> {
  factory _$ChurnedDriverCopyWith(_ChurnedDriver value, $Res Function(_ChurnedDriver) _then) = __$ChurnedDriverCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String displayName, int removed, int activeNow
});




}
/// @nodoc
class __$ChurnedDriverCopyWithImpl<$Res>
    implements _$ChurnedDriverCopyWith<$Res> {
  __$ChurnedDriverCopyWithImpl(this._self, this._then);

  final _ChurnedDriver _self;
  final $Res Function(_ChurnedDriver) _then;

/// Create a copy of ChurnedDriver
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? displayName = null,Object? removed = null,Object? activeNow = null,}) {
  return _then(_ChurnedDriver(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,activeNow: null == activeNow ? _self.activeNow : activeNow // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$InactiveChosenDriver {

 String get driverId; String get displayName; int get activeAffiliations; DateTime? get lastCompletedAt;
/// Create a copy of InactiveChosenDriver
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InactiveChosenDriverCopyWith<InactiveChosenDriver> get copyWith => _$InactiveChosenDriverCopyWithImpl<InactiveChosenDriver>(this as InactiveChosenDriver, _$identity);

  /// Serializes this InactiveChosenDriver to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InactiveChosenDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.activeAffiliations, activeAffiliations) || other.activeAffiliations == activeAffiliations)&&(identical(other.lastCompletedAt, lastCompletedAt) || other.lastCompletedAt == lastCompletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,activeAffiliations,lastCompletedAt);

@override
String toString() {
  return 'InactiveChosenDriver(driverId: $driverId, displayName: $displayName, activeAffiliations: $activeAffiliations, lastCompletedAt: $lastCompletedAt)';
}


}

/// @nodoc
abstract mixin class $InactiveChosenDriverCopyWith<$Res>  {
  factory $InactiveChosenDriverCopyWith(InactiveChosenDriver value, $Res Function(InactiveChosenDriver) _then) = _$InactiveChosenDriverCopyWithImpl;
@useResult
$Res call({
 String driverId, String displayName, int activeAffiliations, DateTime? lastCompletedAt
});




}
/// @nodoc
class _$InactiveChosenDriverCopyWithImpl<$Res>
    implements $InactiveChosenDriverCopyWith<$Res> {
  _$InactiveChosenDriverCopyWithImpl(this._self, this._then);

  final InactiveChosenDriver _self;
  final $Res Function(InactiveChosenDriver) _then;

/// Create a copy of InactiveChosenDriver
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? displayName = null,Object? activeAffiliations = null,Object? lastCompletedAt = freezed,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,activeAffiliations: null == activeAffiliations ? _self.activeAffiliations : activeAffiliations // ignore: cast_nullable_to_non_nullable
as int,lastCompletedAt: freezed == lastCompletedAt ? _self.lastCompletedAt : lastCompletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [InactiveChosenDriver].
extension InactiveChosenDriverPatterns on InactiveChosenDriver {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InactiveChosenDriver value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InactiveChosenDriver() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InactiveChosenDriver value)  $default,){
final _that = this;
switch (_that) {
case _InactiveChosenDriver():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InactiveChosenDriver value)?  $default,){
final _that = this;
switch (_that) {
case _InactiveChosenDriver() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String displayName,  int activeAffiliations,  DateTime? lastCompletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InactiveChosenDriver() when $default != null:
return $default(_that.driverId,_that.displayName,_that.activeAffiliations,_that.lastCompletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String displayName,  int activeAffiliations,  DateTime? lastCompletedAt)  $default,) {final _that = this;
switch (_that) {
case _InactiveChosenDriver():
return $default(_that.driverId,_that.displayName,_that.activeAffiliations,_that.lastCompletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String displayName,  int activeAffiliations,  DateTime? lastCompletedAt)?  $default,) {final _that = this;
switch (_that) {
case _InactiveChosenDriver() when $default != null:
return $default(_that.driverId,_that.displayName,_that.activeAffiliations,_that.lastCompletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InactiveChosenDriver implements InactiveChosenDriver {
  const _InactiveChosenDriver({required this.driverId, required this.displayName, this.activeAffiliations = 0, this.lastCompletedAt});
  factory _InactiveChosenDriver.fromJson(Map<String, dynamic> json) => _$InactiveChosenDriverFromJson(json);

@override final  String driverId;
@override final  String displayName;
@override@JsonKey() final  int activeAffiliations;
@override final  DateTime? lastCompletedAt;

/// Create a copy of InactiveChosenDriver
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InactiveChosenDriverCopyWith<_InactiveChosenDriver> get copyWith => __$InactiveChosenDriverCopyWithImpl<_InactiveChosenDriver>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InactiveChosenDriverToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InactiveChosenDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.activeAffiliations, activeAffiliations) || other.activeAffiliations == activeAffiliations)&&(identical(other.lastCompletedAt, lastCompletedAt) || other.lastCompletedAt == lastCompletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,activeAffiliations,lastCompletedAt);

@override
String toString() {
  return 'InactiveChosenDriver(driverId: $driverId, displayName: $displayName, activeAffiliations: $activeAffiliations, lastCompletedAt: $lastCompletedAt)';
}


}

/// @nodoc
abstract mixin class _$InactiveChosenDriverCopyWith<$Res> implements $InactiveChosenDriverCopyWith<$Res> {
  factory _$InactiveChosenDriverCopyWith(_InactiveChosenDriver value, $Res Function(_InactiveChosenDriver) _then) = __$InactiveChosenDriverCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String displayName, int activeAffiliations, DateTime? lastCompletedAt
});




}
/// @nodoc
class __$InactiveChosenDriverCopyWithImpl<$Res>
    implements _$InactiveChosenDriverCopyWith<$Res> {
  __$InactiveChosenDriverCopyWithImpl(this._self, this._then);

  final _InactiveChosenDriver _self;
  final $Res Function(_InactiveChosenDriver) _then;

/// Create a copy of InactiveChosenDriver
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? displayName = null,Object? activeAffiliations = null,Object? lastCompletedAt = freezed,}) {
  return _then(_InactiveChosenDriver(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,activeAffiliations: null == activeAffiliations ? _self.activeAffiliations : activeAffiliations // ignore: cast_nullable_to_non_nullable
as int,lastCompletedAt: freezed == lastCompletedAt ? _self.lastCompletedAt : lastCompletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CrmReport {

 DateTime get from; DateTime get to; CrmAffiliations get affiliations; CrmRepeat get repeat; Sc008 get sc008; List<ChurnedDriver> get churnedDrivers; List<InactiveChosenDriver> get inactiveChosenDrivers;
/// Create a copy of CrmReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CrmReportCopyWith<CrmReport> get copyWith => _$CrmReportCopyWithImpl<CrmReport>(this as CrmReport, _$identity);

  /// Serializes this CrmReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CrmReport&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.affiliations, affiliations) || other.affiliations == affiliations)&&(identical(other.repeat, repeat) || other.repeat == repeat)&&(identical(other.sc008, sc008) || other.sc008 == sc008)&&const DeepCollectionEquality().equals(other.churnedDrivers, churnedDrivers)&&const DeepCollectionEquality().equals(other.inactiveChosenDrivers, inactiveChosenDrivers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,affiliations,repeat,sc008,const DeepCollectionEquality().hash(churnedDrivers),const DeepCollectionEquality().hash(inactiveChosenDrivers));

@override
String toString() {
  return 'CrmReport(from: $from, to: $to, affiliations: $affiliations, repeat: $repeat, sc008: $sc008, churnedDrivers: $churnedDrivers, inactiveChosenDrivers: $inactiveChosenDrivers)';
}


}

/// @nodoc
abstract mixin class $CrmReportCopyWith<$Res>  {
  factory $CrmReportCopyWith(CrmReport value, $Res Function(CrmReport) _then) = _$CrmReportCopyWithImpl;
@useResult
$Res call({
 DateTime from, DateTime to, CrmAffiliations affiliations, CrmRepeat repeat, Sc008 sc008, List<ChurnedDriver> churnedDrivers, List<InactiveChosenDriver> inactiveChosenDrivers
});


$CrmAffiliationsCopyWith<$Res> get affiliations;$CrmRepeatCopyWith<$Res> get repeat;$Sc008CopyWith<$Res> get sc008;

}
/// @nodoc
class _$CrmReportCopyWithImpl<$Res>
    implements $CrmReportCopyWith<$Res> {
  _$CrmReportCopyWithImpl(this._self, this._then);

  final CrmReport _self;
  final $Res Function(CrmReport) _then;

/// Create a copy of CrmReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,Object? affiliations = null,Object? repeat = null,Object? sc008 = null,Object? churnedDrivers = null,Object? inactiveChosenDrivers = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime,affiliations: null == affiliations ? _self.affiliations : affiliations // ignore: cast_nullable_to_non_nullable
as CrmAffiliations,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as CrmRepeat,sc008: null == sc008 ? _self.sc008 : sc008 // ignore: cast_nullable_to_non_nullable
as Sc008,churnedDrivers: null == churnedDrivers ? _self.churnedDrivers : churnedDrivers // ignore: cast_nullable_to_non_nullable
as List<ChurnedDriver>,inactiveChosenDrivers: null == inactiveChosenDrivers ? _self.inactiveChosenDrivers : inactiveChosenDrivers // ignore: cast_nullable_to_non_nullable
as List<InactiveChosenDriver>,
  ));
}
/// Create a copy of CrmReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CrmAffiliationsCopyWith<$Res> get affiliations {
  
  return $CrmAffiliationsCopyWith<$Res>(_self.affiliations, (value) {
    return _then(_self.copyWith(affiliations: value));
  });
}/// Create a copy of CrmReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CrmRepeatCopyWith<$Res> get repeat {
  
  return $CrmRepeatCopyWith<$Res>(_self.repeat, (value) {
    return _then(_self.copyWith(repeat: value));
  });
}/// Create a copy of CrmReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Sc008CopyWith<$Res> get sc008 {
  
  return $Sc008CopyWith<$Res>(_self.sc008, (value) {
    return _then(_self.copyWith(sc008: value));
  });
}
}


/// Adds pattern-matching-related methods to [CrmReport].
extension CrmReportPatterns on CrmReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CrmReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CrmReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CrmReport value)  $default,){
final _that = this;
switch (_that) {
case _CrmReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CrmReport value)?  $default,){
final _that = this;
switch (_that) {
case _CrmReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime from,  DateTime to,  CrmAffiliations affiliations,  CrmRepeat repeat,  Sc008 sc008,  List<ChurnedDriver> churnedDrivers,  List<InactiveChosenDriver> inactiveChosenDrivers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CrmReport() when $default != null:
return $default(_that.from,_that.to,_that.affiliations,_that.repeat,_that.sc008,_that.churnedDrivers,_that.inactiveChosenDrivers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime from,  DateTime to,  CrmAffiliations affiliations,  CrmRepeat repeat,  Sc008 sc008,  List<ChurnedDriver> churnedDrivers,  List<InactiveChosenDriver> inactiveChosenDrivers)  $default,) {final _that = this;
switch (_that) {
case _CrmReport():
return $default(_that.from,_that.to,_that.affiliations,_that.repeat,_that.sc008,_that.churnedDrivers,_that.inactiveChosenDrivers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime from,  DateTime to,  CrmAffiliations affiliations,  CrmRepeat repeat,  Sc008 sc008,  List<ChurnedDriver> churnedDrivers,  List<InactiveChosenDriver> inactiveChosenDrivers)?  $default,) {final _that = this;
switch (_that) {
case _CrmReport() when $default != null:
return $default(_that.from,_that.to,_that.affiliations,_that.repeat,_that.sc008,_that.churnedDrivers,_that.inactiveChosenDrivers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CrmReport implements CrmReport {
  const _CrmReport({required this.from, required this.to, this.affiliations = const CrmAffiliations(), this.repeat = const CrmRepeat(), this.sc008 = const Sc008(), final  List<ChurnedDriver> churnedDrivers = const <ChurnedDriver>[], final  List<InactiveChosenDriver> inactiveChosenDrivers = const <InactiveChosenDriver>[]}): _churnedDrivers = churnedDrivers,_inactiveChosenDrivers = inactiveChosenDrivers;
  factory _CrmReport.fromJson(Map<String, dynamic> json) => _$CrmReportFromJson(json);

@override final  DateTime from;
@override final  DateTime to;
@override@JsonKey() final  CrmAffiliations affiliations;
@override@JsonKey() final  CrmRepeat repeat;
@override@JsonKey() final  Sc008 sc008;
 final  List<ChurnedDriver> _churnedDrivers;
@override@JsonKey() List<ChurnedDriver> get churnedDrivers {
  if (_churnedDrivers is EqualUnmodifiableListView) return _churnedDrivers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_churnedDrivers);
}

 final  List<InactiveChosenDriver> _inactiveChosenDrivers;
@override@JsonKey() List<InactiveChosenDriver> get inactiveChosenDrivers {
  if (_inactiveChosenDrivers is EqualUnmodifiableListView) return _inactiveChosenDrivers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inactiveChosenDrivers);
}


/// Create a copy of CrmReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CrmReportCopyWith<_CrmReport> get copyWith => __$CrmReportCopyWithImpl<_CrmReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CrmReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CrmReport&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.affiliations, affiliations) || other.affiliations == affiliations)&&(identical(other.repeat, repeat) || other.repeat == repeat)&&(identical(other.sc008, sc008) || other.sc008 == sc008)&&const DeepCollectionEquality().equals(other._churnedDrivers, _churnedDrivers)&&const DeepCollectionEquality().equals(other._inactiveChosenDrivers, _inactiveChosenDrivers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,affiliations,repeat,sc008,const DeepCollectionEquality().hash(_churnedDrivers),const DeepCollectionEquality().hash(_inactiveChosenDrivers));

@override
String toString() {
  return 'CrmReport(from: $from, to: $to, affiliations: $affiliations, repeat: $repeat, sc008: $sc008, churnedDrivers: $churnedDrivers, inactiveChosenDrivers: $inactiveChosenDrivers)';
}


}

/// @nodoc
abstract mixin class _$CrmReportCopyWith<$Res> implements $CrmReportCopyWith<$Res> {
  factory _$CrmReportCopyWith(_CrmReport value, $Res Function(_CrmReport) _then) = __$CrmReportCopyWithImpl;
@override @useResult
$Res call({
 DateTime from, DateTime to, CrmAffiliations affiliations, CrmRepeat repeat, Sc008 sc008, List<ChurnedDriver> churnedDrivers, List<InactiveChosenDriver> inactiveChosenDrivers
});


@override $CrmAffiliationsCopyWith<$Res> get affiliations;@override $CrmRepeatCopyWith<$Res> get repeat;@override $Sc008CopyWith<$Res> get sc008;

}
/// @nodoc
class __$CrmReportCopyWithImpl<$Res>
    implements _$CrmReportCopyWith<$Res> {
  __$CrmReportCopyWithImpl(this._self, this._then);

  final _CrmReport _self;
  final $Res Function(_CrmReport) _then;

/// Create a copy of CrmReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? affiliations = null,Object? repeat = null,Object? sc008 = null,Object? churnedDrivers = null,Object? inactiveChosenDrivers = null,}) {
  return _then(_CrmReport(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime,affiliations: null == affiliations ? _self.affiliations : affiliations // ignore: cast_nullable_to_non_nullable
as CrmAffiliations,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as CrmRepeat,sc008: null == sc008 ? _self.sc008 : sc008 // ignore: cast_nullable_to_non_nullable
as Sc008,churnedDrivers: null == churnedDrivers ? _self._churnedDrivers : churnedDrivers // ignore: cast_nullable_to_non_nullable
as List<ChurnedDriver>,inactiveChosenDrivers: null == inactiveChosenDrivers ? _self._inactiveChosenDrivers : inactiveChosenDrivers // ignore: cast_nullable_to_non_nullable
as List<InactiveChosenDriver>,
  ));
}

/// Create a copy of CrmReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CrmAffiliationsCopyWith<$Res> get affiliations {
  
  return $CrmAffiliationsCopyWith<$Res>(_self.affiliations, (value) {
    return _then(_self.copyWith(affiliations: value));
  });
}/// Create a copy of CrmReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CrmRepeatCopyWith<$Res> get repeat {
  
  return $CrmRepeatCopyWith<$Res>(_self.repeat, (value) {
    return _then(_self.copyWith(repeat: value));
  });
}/// Create a copy of CrmReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Sc008CopyWith<$Res> get sc008 {
  
  return $Sc008CopyWith<$Res>(_self.sc008, (value) {
    return _then(_self.copyWith(sc008: value));
  });
}
}


/// @nodoc
mixin _$ModeratedUser {

 String get userId; String get displayName; String get phoneE164; UserRole get role; DateTime get createdAt; DateTime? get suspendedAt; String? get suspensionReason;
/// Create a copy of ModeratedUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModeratedUserCopyWith<ModeratedUser> get copyWith => _$ModeratedUserCopyWithImpl<ModeratedUser>(this as ModeratedUser, _$identity);

  /// Serializes this ModeratedUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModeratedUser&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164)&&(identical(other.role, role) || other.role == role)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.suspendedAt, suspendedAt) || other.suspendedAt == suspendedAt)&&(identical(other.suspensionReason, suspensionReason) || other.suspensionReason == suspensionReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,phoneE164,role,createdAt,suspendedAt,suspensionReason);

@override
String toString() {
  return 'ModeratedUser(userId: $userId, displayName: $displayName, phoneE164: $phoneE164, role: $role, createdAt: $createdAt, suspendedAt: $suspendedAt, suspensionReason: $suspensionReason)';
}


}

/// @nodoc
abstract mixin class $ModeratedUserCopyWith<$Res>  {
  factory $ModeratedUserCopyWith(ModeratedUser value, $Res Function(ModeratedUser) _then) = _$ModeratedUserCopyWithImpl;
@useResult
$Res call({
 String userId, String displayName, String phoneE164, UserRole role, DateTime createdAt, DateTime? suspendedAt, String? suspensionReason
});




}
/// @nodoc
class _$ModeratedUserCopyWithImpl<$Res>
    implements $ModeratedUserCopyWith<$Res> {
  _$ModeratedUserCopyWithImpl(this._self, this._then);

  final ModeratedUser _self;
  final $Res Function(ModeratedUser) _then;

/// Create a copy of ModeratedUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? phoneE164 = null,Object? role = null,Object? createdAt = null,Object? suspendedAt = freezed,Object? suspensionReason = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,phoneE164: null == phoneE164 ? _self.phoneE164 : phoneE164 // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,suspendedAt: freezed == suspendedAt ? _self.suspendedAt : suspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,suspensionReason: freezed == suspensionReason ? _self.suspensionReason : suspensionReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModeratedUser].
extension ModeratedUserPatterns on ModeratedUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModeratedUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModeratedUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModeratedUser value)  $default,){
final _that = this;
switch (_that) {
case _ModeratedUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModeratedUser value)?  $default,){
final _that = this;
switch (_that) {
case _ModeratedUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName,  String phoneE164,  UserRole role,  DateTime createdAt,  DateTime? suspendedAt,  String? suspensionReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModeratedUser() when $default != null:
return $default(_that.userId,_that.displayName,_that.phoneE164,_that.role,_that.createdAt,_that.suspendedAt,_that.suspensionReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName,  String phoneE164,  UserRole role,  DateTime createdAt,  DateTime? suspendedAt,  String? suspensionReason)  $default,) {final _that = this;
switch (_that) {
case _ModeratedUser():
return $default(_that.userId,_that.displayName,_that.phoneE164,_that.role,_that.createdAt,_that.suspendedAt,_that.suspensionReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName,  String phoneE164,  UserRole role,  DateTime createdAt,  DateTime? suspendedAt,  String? suspensionReason)?  $default,) {final _that = this;
switch (_that) {
case _ModeratedUser() when $default != null:
return $default(_that.userId,_that.displayName,_that.phoneE164,_that.role,_that.createdAt,_that.suspendedAt,_that.suspensionReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModeratedUser extends ModeratedUser {
  const _ModeratedUser({required this.userId, required this.displayName, required this.phoneE164, required this.role, required this.createdAt, this.suspendedAt, this.suspensionReason}): super._();
  factory _ModeratedUser.fromJson(Map<String, dynamic> json) => _$ModeratedUserFromJson(json);

@override final  String userId;
@override final  String displayName;
@override final  String phoneE164;
@override final  UserRole role;
@override final  DateTime createdAt;
@override final  DateTime? suspendedAt;
@override final  String? suspensionReason;

/// Create a copy of ModeratedUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModeratedUserCopyWith<_ModeratedUser> get copyWith => __$ModeratedUserCopyWithImpl<_ModeratedUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModeratedUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModeratedUser&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164)&&(identical(other.role, role) || other.role == role)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.suspendedAt, suspendedAt) || other.suspendedAt == suspendedAt)&&(identical(other.suspensionReason, suspensionReason) || other.suspensionReason == suspensionReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,phoneE164,role,createdAt,suspendedAt,suspensionReason);

@override
String toString() {
  return 'ModeratedUser(userId: $userId, displayName: $displayName, phoneE164: $phoneE164, role: $role, createdAt: $createdAt, suspendedAt: $suspendedAt, suspensionReason: $suspensionReason)';
}


}

/// @nodoc
abstract mixin class _$ModeratedUserCopyWith<$Res> implements $ModeratedUserCopyWith<$Res> {
  factory _$ModeratedUserCopyWith(_ModeratedUser value, $Res Function(_ModeratedUser) _then) = __$ModeratedUserCopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName, String phoneE164, UserRole role, DateTime createdAt, DateTime? suspendedAt, String? suspensionReason
});




}
/// @nodoc
class __$ModeratedUserCopyWithImpl<$Res>
    implements _$ModeratedUserCopyWith<$Res> {
  __$ModeratedUserCopyWithImpl(this._self, this._then);

  final _ModeratedUser _self;
  final $Res Function(_ModeratedUser) _then;

/// Create a copy of ModeratedUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? phoneE164 = null,Object? role = null,Object? createdAt = null,Object? suspendedAt = freezed,Object? suspensionReason = freezed,}) {
  return _then(_ModeratedUser(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,phoneE164: null == phoneE164 ? _self.phoneE164 : phoneE164 // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,suspendedAt: freezed == suspendedAt ? _self.suspendedAt : suspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,suspensionReason: freezed == suspensionReason ? _self.suspensionReason : suspensionReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ModerationAction {

 String get id; ModerationKind get action; String get reason; String get actorId; String get actorName; DateTime get createdAt;
/// Create a copy of ModerationAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationActionCopyWith<ModerationAction> get copyWith => _$ModerationActionCopyWithImpl<ModerationAction>(this as ModerationAction, _$identity);

  /// Serializes this ModerationAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationAction&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.actorName, actorName) || other.actorName == actorName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,reason,actorId,actorName,createdAt);

@override
String toString() {
  return 'ModerationAction(id: $id, action: $action, reason: $reason, actorId: $actorId, actorName: $actorName, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ModerationActionCopyWith<$Res>  {
  factory $ModerationActionCopyWith(ModerationAction value, $Res Function(ModerationAction) _then) = _$ModerationActionCopyWithImpl;
@useResult
$Res call({
 String id, ModerationKind action, String reason, String actorId, String actorName, DateTime createdAt
});




}
/// @nodoc
class _$ModerationActionCopyWithImpl<$Res>
    implements $ModerationActionCopyWith<$Res> {
  _$ModerationActionCopyWithImpl(this._self, this._then);

  final ModerationAction _self;
  final $Res Function(ModerationAction) _then;

/// Create a copy of ModerationAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? action = null,Object? reason = null,Object? actorId = null,Object? actorName = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as ModerationKind,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,actorName: null == actorName ? _self.actorName : actorName // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ModerationAction].
extension ModerationActionPatterns on ModerationAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationAction value)  $default,){
final _that = this;
switch (_that) {
case _ModerationAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationAction value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ModerationKind action,  String reason,  String actorId,  String actorName,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationAction() when $default != null:
return $default(_that.id,_that.action,_that.reason,_that.actorId,_that.actorName,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ModerationKind action,  String reason,  String actorId,  String actorName,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ModerationAction():
return $default(_that.id,_that.action,_that.reason,_that.actorId,_that.actorName,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ModerationKind action,  String reason,  String actorId,  String actorName,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ModerationAction() when $default != null:
return $default(_that.id,_that.action,_that.reason,_that.actorId,_that.actorName,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationAction implements ModerationAction {
  const _ModerationAction({required this.id, required this.action, required this.reason, required this.actorId, required this.actorName, required this.createdAt});
  factory _ModerationAction.fromJson(Map<String, dynamic> json) => _$ModerationActionFromJson(json);

@override final  String id;
@override final  ModerationKind action;
@override final  String reason;
@override final  String actorId;
@override final  String actorName;
@override final  DateTime createdAt;

/// Create a copy of ModerationAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationActionCopyWith<_ModerationAction> get copyWith => __$ModerationActionCopyWithImpl<_ModerationAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationAction&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.actorName, actorName) || other.actorName == actorName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,action,reason,actorId,actorName,createdAt);

@override
String toString() {
  return 'ModerationAction(id: $id, action: $action, reason: $reason, actorId: $actorId, actorName: $actorName, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ModerationActionCopyWith<$Res> implements $ModerationActionCopyWith<$Res> {
  factory _$ModerationActionCopyWith(_ModerationAction value, $Res Function(_ModerationAction) _then) = __$ModerationActionCopyWithImpl;
@override @useResult
$Res call({
 String id, ModerationKind action, String reason, String actorId, String actorName, DateTime createdAt
});




}
/// @nodoc
class __$ModerationActionCopyWithImpl<$Res>
    implements _$ModerationActionCopyWith<$Res> {
  __$ModerationActionCopyWithImpl(this._self, this._then);

  final _ModerationAction _self;
  final $Res Function(_ModerationAction) _then;

/// Create a copy of ModerationAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? action = null,Object? reason = null,Object? actorId = null,Object? actorName = null,Object? createdAt = null,}) {
  return _then(_ModerationAction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as ModerationKind,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,actorName: null == actorName ? _self.actorName : actorName // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$HealthCheck {

 String get name;@JsonKey(unknownEnumValue: HealthStatus.down) HealthStatus get status; int? get latencyMs; String get detail;
/// Create a copy of HealthCheck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthCheckCopyWith<HealthCheck> get copyWith => _$HealthCheckCopyWithImpl<HealthCheck>(this as HealthCheck, _$identity);

  /// Serializes this HealthCheck to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthCheck&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,status,latencyMs,detail);

@override
String toString() {
  return 'HealthCheck(name: $name, status: $status, latencyMs: $latencyMs, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $HealthCheckCopyWith<$Res>  {
  factory $HealthCheckCopyWith(HealthCheck value, $Res Function(HealthCheck) _then) = _$HealthCheckCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(unknownEnumValue: HealthStatus.down) HealthStatus status, int? latencyMs, String detail
});




}
/// @nodoc
class _$HealthCheckCopyWithImpl<$Res>
    implements $HealthCheckCopyWith<$Res> {
  _$HealthCheckCopyWithImpl(this._self, this._then);

  final HealthCheck _self;
  final $Res Function(HealthCheck) _then;

/// Create a copy of HealthCheck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? status = null,Object? latencyMs = freezed,Object? detail = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HealthStatus,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int?,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthCheck].
extension HealthCheckPatterns on HealthCheck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthCheck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthCheck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthCheck value)  $default,){
final _that = this;
switch (_that) {
case _HealthCheck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthCheck value)?  $default,){
final _that = this;
switch (_that) {
case _HealthCheck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(unknownEnumValue: HealthStatus.down)  HealthStatus status,  int? latencyMs,  String detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthCheck() when $default != null:
return $default(_that.name,_that.status,_that.latencyMs,_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(unknownEnumValue: HealthStatus.down)  HealthStatus status,  int? latencyMs,  String detail)  $default,) {final _that = this;
switch (_that) {
case _HealthCheck():
return $default(_that.name,_that.status,_that.latencyMs,_that.detail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(unknownEnumValue: HealthStatus.down)  HealthStatus status,  int? latencyMs,  String detail)?  $default,) {final _that = this;
switch (_that) {
case _HealthCheck() when $default != null:
return $default(_that.name,_that.status,_that.latencyMs,_that.detail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HealthCheck implements HealthCheck {
  const _HealthCheck({required this.name, @JsonKey(unknownEnumValue: HealthStatus.down) required this.status, this.latencyMs, this.detail = ''});
  factory _HealthCheck.fromJson(Map<String, dynamic> json) => _$HealthCheckFromJson(json);

@override final  String name;
@override@JsonKey(unknownEnumValue: HealthStatus.down) final  HealthStatus status;
@override final  int? latencyMs;
@override@JsonKey() final  String detail;

/// Create a copy of HealthCheck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthCheckCopyWith<_HealthCheck> get copyWith => __$HealthCheckCopyWithImpl<_HealthCheck>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthCheckToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthCheck&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.detail, detail) || other.detail == detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,status,latencyMs,detail);

@override
String toString() {
  return 'HealthCheck(name: $name, status: $status, latencyMs: $latencyMs, detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$HealthCheckCopyWith<$Res> implements $HealthCheckCopyWith<$Res> {
  factory _$HealthCheckCopyWith(_HealthCheck value, $Res Function(_HealthCheck) _then) = __$HealthCheckCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(unknownEnumValue: HealthStatus.down) HealthStatus status, int? latencyMs, String detail
});




}
/// @nodoc
class __$HealthCheckCopyWithImpl<$Res>
    implements _$HealthCheckCopyWith<$Res> {
  __$HealthCheckCopyWithImpl(this._self, this._then);

  final _HealthCheck _self;
  final $Res Function(_HealthCheck) _then;

/// Create a copy of HealthCheck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? status = null,Object? latencyMs = freezed,Object? detail = null,}) {
  return _then(_HealthCheck(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HealthStatus,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int?,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$HealthReport {

@JsonKey(unknownEnumValue: HealthStatus.down) HealthStatus get status; DateTime get checkedAt; List<HealthCheck> get checks;
/// Create a copy of HealthReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthReportCopyWith<HealthReport> get copyWith => _$HealthReportCopyWithImpl<HealthReport>(this as HealthReport, _$identity);

  /// Serializes this HealthReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthReport&&(identical(other.status, status) || other.status == status)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&const DeepCollectionEquality().equals(other.checks, checks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,checkedAt,const DeepCollectionEquality().hash(checks));

@override
String toString() {
  return 'HealthReport(status: $status, checkedAt: $checkedAt, checks: $checks)';
}


}

/// @nodoc
abstract mixin class $HealthReportCopyWith<$Res>  {
  factory $HealthReportCopyWith(HealthReport value, $Res Function(HealthReport) _then) = _$HealthReportCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: HealthStatus.down) HealthStatus status, DateTime checkedAt, List<HealthCheck> checks
});




}
/// @nodoc
class _$HealthReportCopyWithImpl<$Res>
    implements $HealthReportCopyWith<$Res> {
  _$HealthReportCopyWithImpl(this._self, this._then);

  final HealthReport _self;
  final $Res Function(HealthReport) _then;

/// Create a copy of HealthReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? checkedAt = null,Object? checks = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HealthStatus,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,checks: null == checks ? _self.checks : checks // ignore: cast_nullable_to_non_nullable
as List<HealthCheck>,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthReport].
extension HealthReportPatterns on HealthReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthReport value)  $default,){
final _that = this;
switch (_that) {
case _HealthReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthReport value)?  $default,){
final _that = this;
switch (_that) {
case _HealthReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: HealthStatus.down)  HealthStatus status,  DateTime checkedAt,  List<HealthCheck> checks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthReport() when $default != null:
return $default(_that.status,_that.checkedAt,_that.checks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: HealthStatus.down)  HealthStatus status,  DateTime checkedAt,  List<HealthCheck> checks)  $default,) {final _that = this;
switch (_that) {
case _HealthReport():
return $default(_that.status,_that.checkedAt,_that.checks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: HealthStatus.down)  HealthStatus status,  DateTime checkedAt,  List<HealthCheck> checks)?  $default,) {final _that = this;
switch (_that) {
case _HealthReport() when $default != null:
return $default(_that.status,_that.checkedAt,_that.checks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HealthReport implements HealthReport {
  const _HealthReport({@JsonKey(unknownEnumValue: HealthStatus.down) required this.status, required this.checkedAt, final  List<HealthCheck> checks = const <HealthCheck>[]}): _checks = checks;
  factory _HealthReport.fromJson(Map<String, dynamic> json) => _$HealthReportFromJson(json);

@override@JsonKey(unknownEnumValue: HealthStatus.down) final  HealthStatus status;
@override final  DateTime checkedAt;
 final  List<HealthCheck> _checks;
@override@JsonKey() List<HealthCheck> get checks {
  if (_checks is EqualUnmodifiableListView) return _checks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_checks);
}


/// Create a copy of HealthReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthReportCopyWith<_HealthReport> get copyWith => __$HealthReportCopyWithImpl<_HealthReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthReport&&(identical(other.status, status) || other.status == status)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&const DeepCollectionEquality().equals(other._checks, _checks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,checkedAt,const DeepCollectionEquality().hash(_checks));

@override
String toString() {
  return 'HealthReport(status: $status, checkedAt: $checkedAt, checks: $checks)';
}


}

/// @nodoc
abstract mixin class _$HealthReportCopyWith<$Res> implements $HealthReportCopyWith<$Res> {
  factory _$HealthReportCopyWith(_HealthReport value, $Res Function(_HealthReport) _then) = __$HealthReportCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: HealthStatus.down) HealthStatus status, DateTime checkedAt, List<HealthCheck> checks
});




}
/// @nodoc
class __$HealthReportCopyWithImpl<$Res>
    implements _$HealthReportCopyWith<$Res> {
  __$HealthReportCopyWithImpl(this._self, this._then);

  final _HealthReport _self;
  final $Res Function(_HealthReport) _then;

/// Create a copy of HealthReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? checkedAt = null,Object? checks = null,}) {
  return _then(_HealthReport(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HealthStatus,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,checks: null == checks ? _self._checks : checks // ignore: cast_nullable_to_non_nullable
as List<HealthCheck>,
  ));
}


}

// dart format on
