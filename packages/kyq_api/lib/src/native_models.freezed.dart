// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'native_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Reservation {

 String get id; PersonRef get passenger; PersonRef get driver; GeoPoint get pickup; GeoPoint get dropoff; String? get pickupLabel; String? get dropoffLabel; DateTime get scheduledAt; int get distanceM; int get durationS; String get currency;/// Tarifa reservada (con la preferencial de 008 si aplicaba).
 int get fareMinor; int get listFareMinor; int get preferentialDiscountPct;@JsonKey(unknownEnumValue: ReservationStatus.cancelled) ReservationStatus get status; bool get cancelledByMe; String? get tripId;/// Agenda: otra reserva del conductor a menos de 30 minutos.
 bool get overlaps;
/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReservationCopyWith<Reservation> get copyWith => _$ReservationCopyWithImpl<Reservation>(this as Reservation, _$identity);

  /// Serializes this Reservation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reservation&&(identical(other.id, id) || other.id == id)&&(identical(other.passenger, passenger) || other.passenger == passenger)&&(identical(other.driver, driver) || other.driver == driver)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.pickupLabel, pickupLabel) || other.pickupLabel == pickupLabel)&&(identical(other.dropoffLabel, dropoffLabel) || other.dropoffLabel == dropoffLabel)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.fareMinor, fareMinor) || other.fareMinor == fareMinor)&&(identical(other.listFareMinor, listFareMinor) || other.listFareMinor == listFareMinor)&&(identical(other.preferentialDiscountPct, preferentialDiscountPct) || other.preferentialDiscountPct == preferentialDiscountPct)&&(identical(other.status, status) || other.status == status)&&(identical(other.cancelledByMe, cancelledByMe) || other.cancelledByMe == cancelledByMe)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.overlaps, overlaps) || other.overlaps == overlaps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,passenger,driver,pickup,dropoff,pickupLabel,dropoffLabel,scheduledAt,distanceM,durationS,currency,fareMinor,listFareMinor,preferentialDiscountPct,status,cancelledByMe,tripId,overlaps);

@override
String toString() {
  return 'Reservation(id: $id, passenger: $passenger, driver: $driver, pickup: $pickup, dropoff: $dropoff, pickupLabel: $pickupLabel, dropoffLabel: $dropoffLabel, scheduledAt: $scheduledAt, distanceM: $distanceM, durationS: $durationS, currency: $currency, fareMinor: $fareMinor, listFareMinor: $listFareMinor, preferentialDiscountPct: $preferentialDiscountPct, status: $status, cancelledByMe: $cancelledByMe, tripId: $tripId, overlaps: $overlaps)';
}


}

/// @nodoc
abstract mixin class $ReservationCopyWith<$Res>  {
  factory $ReservationCopyWith(Reservation value, $Res Function(Reservation) _then) = _$ReservationCopyWithImpl;
@useResult
$Res call({
 String id, PersonRef passenger, PersonRef driver, GeoPoint pickup, GeoPoint dropoff, String? pickupLabel, String? dropoffLabel, DateTime scheduledAt, int distanceM, int durationS, String currency, int fareMinor, int listFareMinor, int preferentialDiscountPct,@JsonKey(unknownEnumValue: ReservationStatus.cancelled) ReservationStatus status, bool cancelledByMe, String? tripId, bool overlaps
});


$PersonRefCopyWith<$Res> get passenger;$PersonRefCopyWith<$Res> get driver;$GeoPointCopyWith<$Res> get pickup;$GeoPointCopyWith<$Res> get dropoff;

}
/// @nodoc
class _$ReservationCopyWithImpl<$Res>
    implements $ReservationCopyWith<$Res> {
  _$ReservationCopyWithImpl(this._self, this._then);

  final Reservation _self;
  final $Res Function(Reservation) _then;

/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? passenger = null,Object? driver = null,Object? pickup = null,Object? dropoff = null,Object? pickupLabel = freezed,Object? dropoffLabel = freezed,Object? scheduledAt = null,Object? distanceM = null,Object? durationS = null,Object? currency = null,Object? fareMinor = null,Object? listFareMinor = null,Object? preferentialDiscountPct = null,Object? status = null,Object? cancelledByMe = null,Object? tripId = freezed,Object? overlaps = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,passenger: null == passenger ? _self.passenger : passenger // ignore: cast_nullable_to_non_nullable
as PersonRef,driver: null == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as PersonRef,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as GeoPoint,pickupLabel: freezed == pickupLabel ? _self.pickupLabel : pickupLabel // ignore: cast_nullable_to_non_nullable
as String?,dropoffLabel: freezed == dropoffLabel ? _self.dropoffLabel : dropoffLabel // ignore: cast_nullable_to_non_nullable
as String?,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int,durationS: null == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,fareMinor: null == fareMinor ? _self.fareMinor : fareMinor // ignore: cast_nullable_to_non_nullable
as int,listFareMinor: null == listFareMinor ? _self.listFareMinor : listFareMinor // ignore: cast_nullable_to_non_nullable
as int,preferentialDiscountPct: null == preferentialDiscountPct ? _self.preferentialDiscountPct : preferentialDiscountPct // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReservationStatus,cancelledByMe: null == cancelledByMe ? _self.cancelledByMe : cancelledByMe // ignore: cast_nullable_to_non_nullable
as bool,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,overlaps: null == overlaps ? _self.overlaps : overlaps // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res> get passenger {
  
  return $PersonRefCopyWith<$Res>(_self.passenger, (value) {
    return _then(_self.copyWith(passenger: value));
  });
}/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res> get driver {
  
  return $PersonRefCopyWith<$Res>(_self.driver, (value) {
    return _then(_self.copyWith(driver: value));
  });
}/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get pickup {
  
  return $GeoPointCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get dropoff {
  
  return $GeoPointCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}
}


/// Adds pattern-matching-related methods to [Reservation].
extension ReservationPatterns on Reservation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reservation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reservation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reservation value)  $default,){
final _that = this;
switch (_that) {
case _Reservation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reservation value)?  $default,){
final _that = this;
switch (_that) {
case _Reservation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  PersonRef passenger,  PersonRef driver,  GeoPoint pickup,  GeoPoint dropoff,  String? pickupLabel,  String? dropoffLabel,  DateTime scheduledAt,  int distanceM,  int durationS,  String currency,  int fareMinor,  int listFareMinor,  int preferentialDiscountPct, @JsonKey(unknownEnumValue: ReservationStatus.cancelled)  ReservationStatus status,  bool cancelledByMe,  String? tripId,  bool overlaps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reservation() when $default != null:
return $default(_that.id,_that.passenger,_that.driver,_that.pickup,_that.dropoff,_that.pickupLabel,_that.dropoffLabel,_that.scheduledAt,_that.distanceM,_that.durationS,_that.currency,_that.fareMinor,_that.listFareMinor,_that.preferentialDiscountPct,_that.status,_that.cancelledByMe,_that.tripId,_that.overlaps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  PersonRef passenger,  PersonRef driver,  GeoPoint pickup,  GeoPoint dropoff,  String? pickupLabel,  String? dropoffLabel,  DateTime scheduledAt,  int distanceM,  int durationS,  String currency,  int fareMinor,  int listFareMinor,  int preferentialDiscountPct, @JsonKey(unknownEnumValue: ReservationStatus.cancelled)  ReservationStatus status,  bool cancelledByMe,  String? tripId,  bool overlaps)  $default,) {final _that = this;
switch (_that) {
case _Reservation():
return $default(_that.id,_that.passenger,_that.driver,_that.pickup,_that.dropoff,_that.pickupLabel,_that.dropoffLabel,_that.scheduledAt,_that.distanceM,_that.durationS,_that.currency,_that.fareMinor,_that.listFareMinor,_that.preferentialDiscountPct,_that.status,_that.cancelledByMe,_that.tripId,_that.overlaps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  PersonRef passenger,  PersonRef driver,  GeoPoint pickup,  GeoPoint dropoff,  String? pickupLabel,  String? dropoffLabel,  DateTime scheduledAt,  int distanceM,  int durationS,  String currency,  int fareMinor,  int listFareMinor,  int preferentialDiscountPct, @JsonKey(unknownEnumValue: ReservationStatus.cancelled)  ReservationStatus status,  bool cancelledByMe,  String? tripId,  bool overlaps)?  $default,) {final _that = this;
switch (_that) {
case _Reservation() when $default != null:
return $default(_that.id,_that.passenger,_that.driver,_that.pickup,_that.dropoff,_that.pickupLabel,_that.dropoffLabel,_that.scheduledAt,_that.distanceM,_that.durationS,_that.currency,_that.fareMinor,_that.listFareMinor,_that.preferentialDiscountPct,_that.status,_that.cancelledByMe,_that.tripId,_that.overlaps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reservation implements Reservation {
  const _Reservation({required this.id, required this.passenger, required this.driver, required this.pickup, required this.dropoff, this.pickupLabel, this.dropoffLabel, required this.scheduledAt, required this.distanceM, required this.durationS, required this.currency, required this.fareMinor, required this.listFareMinor, this.preferentialDiscountPct = 0, @JsonKey(unknownEnumValue: ReservationStatus.cancelled) required this.status, this.cancelledByMe = false, this.tripId, this.overlaps = false});
  factory _Reservation.fromJson(Map<String, dynamic> json) => _$ReservationFromJson(json);

@override final  String id;
@override final  PersonRef passenger;
@override final  PersonRef driver;
@override final  GeoPoint pickup;
@override final  GeoPoint dropoff;
@override final  String? pickupLabel;
@override final  String? dropoffLabel;
@override final  DateTime scheduledAt;
@override final  int distanceM;
@override final  int durationS;
@override final  String currency;
/// Tarifa reservada (con la preferencial de 008 si aplicaba).
@override final  int fareMinor;
@override final  int listFareMinor;
@override@JsonKey() final  int preferentialDiscountPct;
@override@JsonKey(unknownEnumValue: ReservationStatus.cancelled) final  ReservationStatus status;
@override@JsonKey() final  bool cancelledByMe;
@override final  String? tripId;
/// Agenda: otra reserva del conductor a menos de 30 minutos.
@override@JsonKey() final  bool overlaps;

/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReservationCopyWith<_Reservation> get copyWith => __$ReservationCopyWithImpl<_Reservation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReservationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reservation&&(identical(other.id, id) || other.id == id)&&(identical(other.passenger, passenger) || other.passenger == passenger)&&(identical(other.driver, driver) || other.driver == driver)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.pickupLabel, pickupLabel) || other.pickupLabel == pickupLabel)&&(identical(other.dropoffLabel, dropoffLabel) || other.dropoffLabel == dropoffLabel)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.fareMinor, fareMinor) || other.fareMinor == fareMinor)&&(identical(other.listFareMinor, listFareMinor) || other.listFareMinor == listFareMinor)&&(identical(other.preferentialDiscountPct, preferentialDiscountPct) || other.preferentialDiscountPct == preferentialDiscountPct)&&(identical(other.status, status) || other.status == status)&&(identical(other.cancelledByMe, cancelledByMe) || other.cancelledByMe == cancelledByMe)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.overlaps, overlaps) || other.overlaps == overlaps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,passenger,driver,pickup,dropoff,pickupLabel,dropoffLabel,scheduledAt,distanceM,durationS,currency,fareMinor,listFareMinor,preferentialDiscountPct,status,cancelledByMe,tripId,overlaps);

@override
String toString() {
  return 'Reservation(id: $id, passenger: $passenger, driver: $driver, pickup: $pickup, dropoff: $dropoff, pickupLabel: $pickupLabel, dropoffLabel: $dropoffLabel, scheduledAt: $scheduledAt, distanceM: $distanceM, durationS: $durationS, currency: $currency, fareMinor: $fareMinor, listFareMinor: $listFareMinor, preferentialDiscountPct: $preferentialDiscountPct, status: $status, cancelledByMe: $cancelledByMe, tripId: $tripId, overlaps: $overlaps)';
}


}

/// @nodoc
abstract mixin class _$ReservationCopyWith<$Res> implements $ReservationCopyWith<$Res> {
  factory _$ReservationCopyWith(_Reservation value, $Res Function(_Reservation) _then) = __$ReservationCopyWithImpl;
@override @useResult
$Res call({
 String id, PersonRef passenger, PersonRef driver, GeoPoint pickup, GeoPoint dropoff, String? pickupLabel, String? dropoffLabel, DateTime scheduledAt, int distanceM, int durationS, String currency, int fareMinor, int listFareMinor, int preferentialDiscountPct,@JsonKey(unknownEnumValue: ReservationStatus.cancelled) ReservationStatus status, bool cancelledByMe, String? tripId, bool overlaps
});


@override $PersonRefCopyWith<$Res> get passenger;@override $PersonRefCopyWith<$Res> get driver;@override $GeoPointCopyWith<$Res> get pickup;@override $GeoPointCopyWith<$Res> get dropoff;

}
/// @nodoc
class __$ReservationCopyWithImpl<$Res>
    implements _$ReservationCopyWith<$Res> {
  __$ReservationCopyWithImpl(this._self, this._then);

  final _Reservation _self;
  final $Res Function(_Reservation) _then;

/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? passenger = null,Object? driver = null,Object? pickup = null,Object? dropoff = null,Object? pickupLabel = freezed,Object? dropoffLabel = freezed,Object? scheduledAt = null,Object? distanceM = null,Object? durationS = null,Object? currency = null,Object? fareMinor = null,Object? listFareMinor = null,Object? preferentialDiscountPct = null,Object? status = null,Object? cancelledByMe = null,Object? tripId = freezed,Object? overlaps = null,}) {
  return _then(_Reservation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,passenger: null == passenger ? _self.passenger : passenger // ignore: cast_nullable_to_non_nullable
as PersonRef,driver: null == driver ? _self.driver : driver // ignore: cast_nullable_to_non_nullable
as PersonRef,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as GeoPoint,pickupLabel: freezed == pickupLabel ? _self.pickupLabel : pickupLabel // ignore: cast_nullable_to_non_nullable
as String?,dropoffLabel: freezed == dropoffLabel ? _self.dropoffLabel : dropoffLabel // ignore: cast_nullable_to_non_nullable
as String?,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int,durationS: null == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,fareMinor: null == fareMinor ? _self.fareMinor : fareMinor // ignore: cast_nullable_to_non_nullable
as int,listFareMinor: null == listFareMinor ? _self.listFareMinor : listFareMinor // ignore: cast_nullable_to_non_nullable
as int,preferentialDiscountPct: null == preferentialDiscountPct ? _self.preferentialDiscountPct : preferentialDiscountPct // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReservationStatus,cancelledByMe: null == cancelledByMe ? _self.cancelledByMe : cancelledByMe // ignore: cast_nullable_to_non_nullable
as bool,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,overlaps: null == overlaps ? _self.overlaps : overlaps // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res> get passenger {
  
  return $PersonRefCopyWith<$Res>(_self.passenger, (value) {
    return _then(_self.copyWith(passenger: value));
  });
}/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PersonRefCopyWith<$Res> get driver {
  
  return $PersonRefCopyWith<$Res>(_self.driver, (value) {
    return _then(_self.copyWith(driver: value));
  });
}/// Create a copy of Reservation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get pickup {
  
  return $GeoPointCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of Reservation
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
mixin _$UpcomingReservation {

 String get id; DateTime get scheduledAt;@JsonKey(unknownEnumValue: ReservationStatus.pending) ReservationStatus get status;
/// Create a copy of UpcomingReservation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpcomingReservationCopyWith<UpcomingReservation> get copyWith => _$UpcomingReservationCopyWithImpl<UpcomingReservation>(this as UpcomingReservation, _$identity);

  /// Serializes this UpcomingReservation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpcomingReservation&&(identical(other.id, id) || other.id == id)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,scheduledAt,status);

@override
String toString() {
  return 'UpcomingReservation(id: $id, scheduledAt: $scheduledAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $UpcomingReservationCopyWith<$Res>  {
  factory $UpcomingReservationCopyWith(UpcomingReservation value, $Res Function(UpcomingReservation) _then) = _$UpcomingReservationCopyWithImpl;
@useResult
$Res call({
 String id, DateTime scheduledAt,@JsonKey(unknownEnumValue: ReservationStatus.pending) ReservationStatus status
});




}
/// @nodoc
class _$UpcomingReservationCopyWithImpl<$Res>
    implements $UpcomingReservationCopyWith<$Res> {
  _$UpcomingReservationCopyWithImpl(this._self, this._then);

  final UpcomingReservation _self;
  final $Res Function(UpcomingReservation) _then;

/// Create a copy of UpcomingReservation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? scheduledAt = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReservationStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [UpcomingReservation].
extension UpcomingReservationPatterns on UpcomingReservation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpcomingReservation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpcomingReservation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpcomingReservation value)  $default,){
final _that = this;
switch (_that) {
case _UpcomingReservation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpcomingReservation value)?  $default,){
final _that = this;
switch (_that) {
case _UpcomingReservation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime scheduledAt, @JsonKey(unknownEnumValue: ReservationStatus.pending)  ReservationStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpcomingReservation() when $default != null:
return $default(_that.id,_that.scheduledAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime scheduledAt, @JsonKey(unknownEnumValue: ReservationStatus.pending)  ReservationStatus status)  $default,) {final _that = this;
switch (_that) {
case _UpcomingReservation():
return $default(_that.id,_that.scheduledAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime scheduledAt, @JsonKey(unknownEnumValue: ReservationStatus.pending)  ReservationStatus status)?  $default,) {final _that = this;
switch (_that) {
case _UpcomingReservation() when $default != null:
return $default(_that.id,_that.scheduledAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpcomingReservation implements UpcomingReservation {
  const _UpcomingReservation({required this.id, required this.scheduledAt, @JsonKey(unknownEnumValue: ReservationStatus.pending) required this.status});
  factory _UpcomingReservation.fromJson(Map<String, dynamic> json) => _$UpcomingReservationFromJson(json);

@override final  String id;
@override final  DateTime scheduledAt;
@override@JsonKey(unknownEnumValue: ReservationStatus.pending) final  ReservationStatus status;

/// Create a copy of UpcomingReservation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpcomingReservationCopyWith<_UpcomingReservation> get copyWith => __$UpcomingReservationCopyWithImpl<_UpcomingReservation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpcomingReservationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpcomingReservation&&(identical(other.id, id) || other.id == id)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,scheduledAt,status);

@override
String toString() {
  return 'UpcomingReservation(id: $id, scheduledAt: $scheduledAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$UpcomingReservationCopyWith<$Res> implements $UpcomingReservationCopyWith<$Res> {
  factory _$UpcomingReservationCopyWith(_UpcomingReservation value, $Res Function(_UpcomingReservation) _then) = __$UpcomingReservationCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime scheduledAt,@JsonKey(unknownEnumValue: ReservationStatus.pending) ReservationStatus status
});




}
/// @nodoc
class __$UpcomingReservationCopyWithImpl<$Res>
    implements _$UpcomingReservationCopyWith<$Res> {
  __$UpcomingReservationCopyWithImpl(this._self, this._then);

  final _UpcomingReservation _self;
  final $Res Function(_UpcomingReservation) _then;

/// Create a copy of UpcomingReservation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? scheduledAt = null,Object? status = null,}) {
  return _then(_UpcomingReservation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ReservationStatus,
  ));
}


}


/// @nodoc
mixin _$ClientCard {

 String get passengerId; String get displayName; DateTime get affiliatedAt; AffiliationSource get source; int get tripsTogether; DateTime? get lastTripAt; String? get note; List<UpcomingReservation> get upcomingReservations;
/// Create a copy of ClientCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClientCardCopyWith<ClientCard> get copyWith => _$ClientCardCopyWithImpl<ClientCard>(this as ClientCard, _$identity);

  /// Serializes this ClientCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClientCard&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.affiliatedAt, affiliatedAt) || other.affiliatedAt == affiliatedAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.tripsTogether, tripsTogether) || other.tripsTogether == tripsTogether)&&(identical(other.lastTripAt, lastTripAt) || other.lastTripAt == lastTripAt)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.upcomingReservations, upcomingReservations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,passengerId,displayName,affiliatedAt,source,tripsTogether,lastTripAt,note,const DeepCollectionEquality().hash(upcomingReservations));

@override
String toString() {
  return 'ClientCard(passengerId: $passengerId, displayName: $displayName, affiliatedAt: $affiliatedAt, source: $source, tripsTogether: $tripsTogether, lastTripAt: $lastTripAt, note: $note, upcomingReservations: $upcomingReservations)';
}


}

/// @nodoc
abstract mixin class $ClientCardCopyWith<$Res>  {
  factory $ClientCardCopyWith(ClientCard value, $Res Function(ClientCard) _then) = _$ClientCardCopyWithImpl;
@useResult
$Res call({
 String passengerId, String displayName, DateTime affiliatedAt, AffiliationSource source, int tripsTogether, DateTime? lastTripAt, String? note, List<UpcomingReservation> upcomingReservations
});




}
/// @nodoc
class _$ClientCardCopyWithImpl<$Res>
    implements $ClientCardCopyWith<$Res> {
  _$ClientCardCopyWithImpl(this._self, this._then);

  final ClientCard _self;
  final $Res Function(ClientCard) _then;

/// Create a copy of ClientCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? passengerId = null,Object? displayName = null,Object? affiliatedAt = null,Object? source = null,Object? tripsTogether = null,Object? lastTripAt = freezed,Object? note = freezed,Object? upcomingReservations = null,}) {
  return _then(_self.copyWith(
passengerId: null == passengerId ? _self.passengerId : passengerId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,affiliatedAt: null == affiliatedAt ? _self.affiliatedAt : affiliatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AffiliationSource,tripsTogether: null == tripsTogether ? _self.tripsTogether : tripsTogether // ignore: cast_nullable_to_non_nullable
as int,lastTripAt: freezed == lastTripAt ? _self.lastTripAt : lastTripAt // ignore: cast_nullable_to_non_nullable
as DateTime?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,upcomingReservations: null == upcomingReservations ? _self.upcomingReservations : upcomingReservations // ignore: cast_nullable_to_non_nullable
as List<UpcomingReservation>,
  ));
}

}


/// Adds pattern-matching-related methods to [ClientCard].
extension ClientCardPatterns on ClientCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClientCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClientCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClientCard value)  $default,){
final _that = this;
switch (_that) {
case _ClientCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClientCard value)?  $default,){
final _that = this;
switch (_that) {
case _ClientCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String passengerId,  String displayName,  DateTime affiliatedAt,  AffiliationSource source,  int tripsTogether,  DateTime? lastTripAt,  String? note,  List<UpcomingReservation> upcomingReservations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClientCard() when $default != null:
return $default(_that.passengerId,_that.displayName,_that.affiliatedAt,_that.source,_that.tripsTogether,_that.lastTripAt,_that.note,_that.upcomingReservations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String passengerId,  String displayName,  DateTime affiliatedAt,  AffiliationSource source,  int tripsTogether,  DateTime? lastTripAt,  String? note,  List<UpcomingReservation> upcomingReservations)  $default,) {final _that = this;
switch (_that) {
case _ClientCard():
return $default(_that.passengerId,_that.displayName,_that.affiliatedAt,_that.source,_that.tripsTogether,_that.lastTripAt,_that.note,_that.upcomingReservations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String passengerId,  String displayName,  DateTime affiliatedAt,  AffiliationSource source,  int tripsTogether,  DateTime? lastTripAt,  String? note,  List<UpcomingReservation> upcomingReservations)?  $default,) {final _that = this;
switch (_that) {
case _ClientCard() when $default != null:
return $default(_that.passengerId,_that.displayName,_that.affiliatedAt,_that.source,_that.tripsTogether,_that.lastTripAt,_that.note,_that.upcomingReservations);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClientCard implements ClientCard {
  const _ClientCard({required this.passengerId, required this.displayName, required this.affiliatedAt, this.source = AffiliationSource.qrScan, this.tripsTogether = 0, this.lastTripAt, this.note, final  List<UpcomingReservation> upcomingReservations = const <UpcomingReservation>[]}): _upcomingReservations = upcomingReservations;
  factory _ClientCard.fromJson(Map<String, dynamic> json) => _$ClientCardFromJson(json);

@override final  String passengerId;
@override final  String displayName;
@override final  DateTime affiliatedAt;
@override@JsonKey() final  AffiliationSource source;
@override@JsonKey() final  int tripsTogether;
@override final  DateTime? lastTripAt;
@override final  String? note;
 final  List<UpcomingReservation> _upcomingReservations;
@override@JsonKey() List<UpcomingReservation> get upcomingReservations {
  if (_upcomingReservations is EqualUnmodifiableListView) return _upcomingReservations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_upcomingReservations);
}


/// Create a copy of ClientCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClientCardCopyWith<_ClientCard> get copyWith => __$ClientCardCopyWithImpl<_ClientCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClientCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClientCard&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.affiliatedAt, affiliatedAt) || other.affiliatedAt == affiliatedAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.tripsTogether, tripsTogether) || other.tripsTogether == tripsTogether)&&(identical(other.lastTripAt, lastTripAt) || other.lastTripAt == lastTripAt)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other._upcomingReservations, _upcomingReservations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,passengerId,displayName,affiliatedAt,source,tripsTogether,lastTripAt,note,const DeepCollectionEquality().hash(_upcomingReservations));

@override
String toString() {
  return 'ClientCard(passengerId: $passengerId, displayName: $displayName, affiliatedAt: $affiliatedAt, source: $source, tripsTogether: $tripsTogether, lastTripAt: $lastTripAt, note: $note, upcomingReservations: $upcomingReservations)';
}


}

/// @nodoc
abstract mixin class _$ClientCardCopyWith<$Res> implements $ClientCardCopyWith<$Res> {
  factory _$ClientCardCopyWith(_ClientCard value, $Res Function(_ClientCard) _then) = __$ClientCardCopyWithImpl;
@override @useResult
$Res call({
 String passengerId, String displayName, DateTime affiliatedAt, AffiliationSource source, int tripsTogether, DateTime? lastTripAt, String? note, List<UpcomingReservation> upcomingReservations
});




}
/// @nodoc
class __$ClientCardCopyWithImpl<$Res>
    implements _$ClientCardCopyWith<$Res> {
  __$ClientCardCopyWithImpl(this._self, this._then);

  final _ClientCard _self;
  final $Res Function(_ClientCard) _then;

/// Create a copy of ClientCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? passengerId = null,Object? displayName = null,Object? affiliatedAt = null,Object? source = null,Object? tripsTogether = null,Object? lastTripAt = freezed,Object? note = freezed,Object? upcomingReservations = null,}) {
  return _then(_ClientCard(
passengerId: null == passengerId ? _self.passengerId : passengerId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,affiliatedAt: null == affiliatedAt ? _self.affiliatedAt : affiliatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AffiliationSource,tripsTogether: null == tripsTogether ? _self.tripsTogether : tripsTogether // ignore: cast_nullable_to_non_nullable
as int,lastTripAt: freezed == lastTripAt ? _self.lastTripAt : lastTripAt // ignore: cast_nullable_to_non_nullable
as DateTime?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,upcomingReservations: null == upcomingReservations ? _self._upcomingReservations : upcomingReservations // ignore: cast_nullable_to_non_nullable
as List<UpcomingReservation>,
  ));
}


}


/// @nodoc
mixin _$Place {

 String get label; String get detail; double get lat; double get lng;
/// Create a copy of Place
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceCopyWith<Place> get copyWith => _$PlaceCopyWithImpl<Place>(this as Place, _$identity);

  /// Serializes this Place to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Place&&(identical(other.label, label) || other.label == label)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,detail,lat,lng);

@override
String toString() {
  return 'Place(label: $label, detail: $detail, lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class $PlaceCopyWith<$Res>  {
  factory $PlaceCopyWith(Place value, $Res Function(Place) _then) = _$PlaceCopyWithImpl;
@useResult
$Res call({
 String label, String detail, double lat, double lng
});




}
/// @nodoc
class _$PlaceCopyWithImpl<$Res>
    implements $PlaceCopyWith<$Res> {
  _$PlaceCopyWithImpl(this._self, this._then);

  final Place _self;
  final $Res Function(Place) _then;

/// Create a copy of Place
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? detail = null,Object? lat = null,Object? lng = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Place].
extension PlacePatterns on Place {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Place value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Place() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Place value)  $default,){
final _that = this;
switch (_that) {
case _Place():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Place value)?  $default,){
final _that = this;
switch (_that) {
case _Place() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String detail,  double lat,  double lng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Place() when $default != null:
return $default(_that.label,_that.detail,_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String detail,  double lat,  double lng)  $default,) {final _that = this;
switch (_that) {
case _Place():
return $default(_that.label,_that.detail,_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String detail,  double lat,  double lng)?  $default,) {final _that = this;
switch (_that) {
case _Place() when $default != null:
return $default(_that.label,_that.detail,_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Place implements Place {
  const _Place({required this.label, this.detail = '', required this.lat, required this.lng});
  factory _Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);

@override final  String label;
@override@JsonKey() final  String detail;
@override final  double lat;
@override final  double lng;

/// Create a copy of Place
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceCopyWith<_Place> get copyWith => __$PlaceCopyWithImpl<_Place>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Place&&(identical(other.label, label) || other.label == label)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,detail,lat,lng);

@override
String toString() {
  return 'Place(label: $label, detail: $detail, lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$PlaceCopyWith<$Res> implements $PlaceCopyWith<$Res> {
  factory _$PlaceCopyWith(_Place value, $Res Function(_Place) _then) = __$PlaceCopyWithImpl;
@override @useResult
$Res call({
 String label, String detail, double lat, double lng
});




}
/// @nodoc
class __$PlaceCopyWithImpl<$Res>
    implements _$PlaceCopyWith<$Res> {
  __$PlaceCopyWithImpl(this._self, this._then);

  final _Place _self;
  final $Res Function(_Place) _then;

/// Create a copy of Place
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? detail = null,Object? lat = null,Object? lng = null,}) {
  return _then(_Place(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
