// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_payment_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TripPayment {

 String get id; String get tripId; String get driverId; String get passengerId; String get driverName; String get passengerName;/// Tarifa acordada.
 int get amountMinor; String get currency;/// Siempre igual a [amountMinor] (RN-KYQ-001).
 int get driverAmountMinor; int get platformCommissionMinor; TripPaymentStatus get status; TripPaymentMethod? get method;/// Medios que el pasajero puede usar.
 List<TripPaymentMethod> get acceptedMethods;/// Solo con un pago de Bold en curso.
 String? get checkoutUrl; String? get paymentMethodDetail; DateTime? get cashReportedAt; DateTime? get cashConfirmedAt; DateTime? get disputedAt; DateTime? get unpaidMarkedAt; DateTime? get paidAt; DateTime? get voidedAt; DateTime get createdAt;/// Solo en el panel.
 String? get reviewNote; String? get resolutionNote; DateTime? get resolvedAt; String? get voidReason;
/// Create a copy of TripPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripPaymentCopyWith<TripPayment> get copyWith => _$TripPaymentCopyWithImpl<TripPayment>(this as TripPayment, _$identity);

  /// Serializes this TripPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.passengerName, passengerName) || other.passengerName == passengerName)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.driverAmountMinor, driverAmountMinor) || other.driverAmountMinor == driverAmountMinor)&&(identical(other.platformCommissionMinor, platformCommissionMinor) || other.platformCommissionMinor == platformCommissionMinor)&&(identical(other.status, status) || other.status == status)&&(identical(other.method, method) || other.method == method)&&const DeepCollectionEquality().equals(other.acceptedMethods, acceptedMethods)&&(identical(other.checkoutUrl, checkoutUrl) || other.checkoutUrl == checkoutUrl)&&(identical(other.paymentMethodDetail, paymentMethodDetail) || other.paymentMethodDetail == paymentMethodDetail)&&(identical(other.cashReportedAt, cashReportedAt) || other.cashReportedAt == cashReportedAt)&&(identical(other.cashConfirmedAt, cashConfirmedAt) || other.cashConfirmedAt == cashConfirmedAt)&&(identical(other.disputedAt, disputedAt) || other.disputedAt == disputedAt)&&(identical(other.unpaidMarkedAt, unpaidMarkedAt) || other.unpaidMarkedAt == unpaidMarkedAt)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.voidedAt, voidedAt) || other.voidedAt == voidedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.resolutionNote, resolutionNote) || other.resolutionNote == resolutionNote)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,tripId,driverId,passengerId,driverName,passengerName,amountMinor,currency,driverAmountMinor,platformCommissionMinor,status,method,const DeepCollectionEquality().hash(acceptedMethods),checkoutUrl,paymentMethodDetail,cashReportedAt,cashConfirmedAt,disputedAt,unpaidMarkedAt,paidAt,voidedAt,createdAt,reviewNote,resolutionNote,resolvedAt,voidReason]);

@override
String toString() {
  return 'TripPayment(id: $id, tripId: $tripId, driverId: $driverId, passengerId: $passengerId, driverName: $driverName, passengerName: $passengerName, amountMinor: $amountMinor, currency: $currency, driverAmountMinor: $driverAmountMinor, platformCommissionMinor: $platformCommissionMinor, status: $status, method: $method, acceptedMethods: $acceptedMethods, checkoutUrl: $checkoutUrl, paymentMethodDetail: $paymentMethodDetail, cashReportedAt: $cashReportedAt, cashConfirmedAt: $cashConfirmedAt, disputedAt: $disputedAt, unpaidMarkedAt: $unpaidMarkedAt, paidAt: $paidAt, voidedAt: $voidedAt, createdAt: $createdAt, reviewNote: $reviewNote, resolutionNote: $resolutionNote, resolvedAt: $resolvedAt, voidReason: $voidReason)';
}


}

/// @nodoc
abstract mixin class $TripPaymentCopyWith<$Res>  {
  factory $TripPaymentCopyWith(TripPayment value, $Res Function(TripPayment) _then) = _$TripPaymentCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String driverId, String passengerId, String driverName, String passengerName, int amountMinor, String currency, int driverAmountMinor, int platformCommissionMinor, TripPaymentStatus status, TripPaymentMethod? method, List<TripPaymentMethod> acceptedMethods, String? checkoutUrl, String? paymentMethodDetail, DateTime? cashReportedAt, DateTime? cashConfirmedAt, DateTime? disputedAt, DateTime? unpaidMarkedAt, DateTime? paidAt, DateTime? voidedAt, DateTime createdAt, String? reviewNote, String? resolutionNote, DateTime? resolvedAt, String? voidReason
});




}
/// @nodoc
class _$TripPaymentCopyWithImpl<$Res>
    implements $TripPaymentCopyWith<$Res> {
  _$TripPaymentCopyWithImpl(this._self, this._then);

  final TripPayment _self;
  final $Res Function(TripPayment) _then;

/// Create a copy of TripPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? driverId = null,Object? passengerId = null,Object? driverName = null,Object? passengerName = null,Object? amountMinor = null,Object? currency = null,Object? driverAmountMinor = null,Object? platformCommissionMinor = null,Object? status = null,Object? method = freezed,Object? acceptedMethods = null,Object? checkoutUrl = freezed,Object? paymentMethodDetail = freezed,Object? cashReportedAt = freezed,Object? cashConfirmedAt = freezed,Object? disputedAt = freezed,Object? unpaidMarkedAt = freezed,Object? paidAt = freezed,Object? voidedAt = freezed,Object? createdAt = null,Object? reviewNote = freezed,Object? resolutionNote = freezed,Object? resolvedAt = freezed,Object? voidReason = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,passengerId: null == passengerId ? _self.passengerId : passengerId // ignore: cast_nullable_to_non_nullable
as String,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,passengerName: null == passengerName ? _self.passengerName : passengerName // ignore: cast_nullable_to_non_nullable
as String,amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,driverAmountMinor: null == driverAmountMinor ? _self.driverAmountMinor : driverAmountMinor // ignore: cast_nullable_to_non_nullable
as int,platformCommissionMinor: null == platformCommissionMinor ? _self.platformCommissionMinor : platformCommissionMinor // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripPaymentStatus,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as TripPaymentMethod?,acceptedMethods: null == acceptedMethods ? _self.acceptedMethods : acceptedMethods // ignore: cast_nullable_to_non_nullable
as List<TripPaymentMethod>,checkoutUrl: freezed == checkoutUrl ? _self.checkoutUrl : checkoutUrl // ignore: cast_nullable_to_non_nullable
as String?,paymentMethodDetail: freezed == paymentMethodDetail ? _self.paymentMethodDetail : paymentMethodDetail // ignore: cast_nullable_to_non_nullable
as String?,cashReportedAt: freezed == cashReportedAt ? _self.cashReportedAt : cashReportedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cashConfirmedAt: freezed == cashConfirmedAt ? _self.cashConfirmedAt : cashConfirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,disputedAt: freezed == disputedAt ? _self.disputedAt : disputedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,unpaidMarkedAt: freezed == unpaidMarkedAt ? _self.unpaidMarkedAt : unpaidMarkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voidedAt: freezed == voidedAt ? _self.voidedAt : voidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,resolutionNote: freezed == resolutionNote ? _self.resolutionNote : resolutionNote // ignore: cast_nullable_to_non_nullable
as String?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TripPayment].
extension TripPaymentPatterns on TripPayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TripPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TripPayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TripPayment value)  $default,){
final _that = this;
switch (_that) {
case _TripPayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TripPayment value)?  $default,){
final _that = this;
switch (_that) {
case _TripPayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String driverId,  String passengerId,  String driverName,  String passengerName,  int amountMinor,  String currency,  int driverAmountMinor,  int platformCommissionMinor,  TripPaymentStatus status,  TripPaymentMethod? method,  List<TripPaymentMethod> acceptedMethods,  String? checkoutUrl,  String? paymentMethodDetail,  DateTime? cashReportedAt,  DateTime? cashConfirmedAt,  DateTime? disputedAt,  DateTime? unpaidMarkedAt,  DateTime? paidAt,  DateTime? voidedAt,  DateTime createdAt,  String? reviewNote,  String? resolutionNote,  DateTime? resolvedAt,  String? voidReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TripPayment() when $default != null:
return $default(_that.id,_that.tripId,_that.driverId,_that.passengerId,_that.driverName,_that.passengerName,_that.amountMinor,_that.currency,_that.driverAmountMinor,_that.platformCommissionMinor,_that.status,_that.method,_that.acceptedMethods,_that.checkoutUrl,_that.paymentMethodDetail,_that.cashReportedAt,_that.cashConfirmedAt,_that.disputedAt,_that.unpaidMarkedAt,_that.paidAt,_that.voidedAt,_that.createdAt,_that.reviewNote,_that.resolutionNote,_that.resolvedAt,_that.voidReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String driverId,  String passengerId,  String driverName,  String passengerName,  int amountMinor,  String currency,  int driverAmountMinor,  int platformCommissionMinor,  TripPaymentStatus status,  TripPaymentMethod? method,  List<TripPaymentMethod> acceptedMethods,  String? checkoutUrl,  String? paymentMethodDetail,  DateTime? cashReportedAt,  DateTime? cashConfirmedAt,  DateTime? disputedAt,  DateTime? unpaidMarkedAt,  DateTime? paidAt,  DateTime? voidedAt,  DateTime createdAt,  String? reviewNote,  String? resolutionNote,  DateTime? resolvedAt,  String? voidReason)  $default,) {final _that = this;
switch (_that) {
case _TripPayment():
return $default(_that.id,_that.tripId,_that.driverId,_that.passengerId,_that.driverName,_that.passengerName,_that.amountMinor,_that.currency,_that.driverAmountMinor,_that.platformCommissionMinor,_that.status,_that.method,_that.acceptedMethods,_that.checkoutUrl,_that.paymentMethodDetail,_that.cashReportedAt,_that.cashConfirmedAt,_that.disputedAt,_that.unpaidMarkedAt,_that.paidAt,_that.voidedAt,_that.createdAt,_that.reviewNote,_that.resolutionNote,_that.resolvedAt,_that.voidReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String driverId,  String passengerId,  String driverName,  String passengerName,  int amountMinor,  String currency,  int driverAmountMinor,  int platformCommissionMinor,  TripPaymentStatus status,  TripPaymentMethod? method,  List<TripPaymentMethod> acceptedMethods,  String? checkoutUrl,  String? paymentMethodDetail,  DateTime? cashReportedAt,  DateTime? cashConfirmedAt,  DateTime? disputedAt,  DateTime? unpaidMarkedAt,  DateTime? paidAt,  DateTime? voidedAt,  DateTime createdAt,  String? reviewNote,  String? resolutionNote,  DateTime? resolvedAt,  String? voidReason)?  $default,) {final _that = this;
switch (_that) {
case _TripPayment() when $default != null:
return $default(_that.id,_that.tripId,_that.driverId,_that.passengerId,_that.driverName,_that.passengerName,_that.amountMinor,_that.currency,_that.driverAmountMinor,_that.platformCommissionMinor,_that.status,_that.method,_that.acceptedMethods,_that.checkoutUrl,_that.paymentMethodDetail,_that.cashReportedAt,_that.cashConfirmedAt,_that.disputedAt,_that.unpaidMarkedAt,_that.paidAt,_that.voidedAt,_that.createdAt,_that.reviewNote,_that.resolutionNote,_that.resolvedAt,_that.voidReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TripPayment implements TripPayment {
  const _TripPayment({required this.id, required this.tripId, required this.driverId, required this.passengerId, this.driverName = '', this.passengerName = '', required this.amountMinor, required this.currency, required this.driverAmountMinor, this.platformCommissionMinor = 0, required this.status, this.method, final  List<TripPaymentMethod> acceptedMethods = const <TripPaymentMethod>[], this.checkoutUrl, this.paymentMethodDetail, this.cashReportedAt, this.cashConfirmedAt, this.disputedAt, this.unpaidMarkedAt, this.paidAt, this.voidedAt, required this.createdAt, this.reviewNote, this.resolutionNote, this.resolvedAt, this.voidReason}): _acceptedMethods = acceptedMethods;
  factory _TripPayment.fromJson(Map<String, dynamic> json) => _$TripPaymentFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String driverId;
@override final  String passengerId;
@override@JsonKey() final  String driverName;
@override@JsonKey() final  String passengerName;
/// Tarifa acordada.
@override final  int amountMinor;
@override final  String currency;
/// Siempre igual a [amountMinor] (RN-KYQ-001).
@override final  int driverAmountMinor;
@override@JsonKey() final  int platformCommissionMinor;
@override final  TripPaymentStatus status;
@override final  TripPaymentMethod? method;
/// Medios que el pasajero puede usar.
 final  List<TripPaymentMethod> _acceptedMethods;
/// Medios que el pasajero puede usar.
@override@JsonKey() List<TripPaymentMethod> get acceptedMethods {
  if (_acceptedMethods is EqualUnmodifiableListView) return _acceptedMethods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_acceptedMethods);
}

/// Solo con un pago de Bold en curso.
@override final  String? checkoutUrl;
@override final  String? paymentMethodDetail;
@override final  DateTime? cashReportedAt;
@override final  DateTime? cashConfirmedAt;
@override final  DateTime? disputedAt;
@override final  DateTime? unpaidMarkedAt;
@override final  DateTime? paidAt;
@override final  DateTime? voidedAt;
@override final  DateTime createdAt;
/// Solo en el panel.
@override final  String? reviewNote;
@override final  String? resolutionNote;
@override final  DateTime? resolvedAt;
@override final  String? voidReason;

/// Create a copy of TripPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripPaymentCopyWith<_TripPayment> get copyWith => __$TripPaymentCopyWithImpl<_TripPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.passengerName, passengerName) || other.passengerName == passengerName)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.driverAmountMinor, driverAmountMinor) || other.driverAmountMinor == driverAmountMinor)&&(identical(other.platformCommissionMinor, platformCommissionMinor) || other.platformCommissionMinor == platformCommissionMinor)&&(identical(other.status, status) || other.status == status)&&(identical(other.method, method) || other.method == method)&&const DeepCollectionEquality().equals(other._acceptedMethods, _acceptedMethods)&&(identical(other.checkoutUrl, checkoutUrl) || other.checkoutUrl == checkoutUrl)&&(identical(other.paymentMethodDetail, paymentMethodDetail) || other.paymentMethodDetail == paymentMethodDetail)&&(identical(other.cashReportedAt, cashReportedAt) || other.cashReportedAt == cashReportedAt)&&(identical(other.cashConfirmedAt, cashConfirmedAt) || other.cashConfirmedAt == cashConfirmedAt)&&(identical(other.disputedAt, disputedAt) || other.disputedAt == disputedAt)&&(identical(other.unpaidMarkedAt, unpaidMarkedAt) || other.unpaidMarkedAt == unpaidMarkedAt)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.voidedAt, voidedAt) || other.voidedAt == voidedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.resolutionNote, resolutionNote) || other.resolutionNote == resolutionNote)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,tripId,driverId,passengerId,driverName,passengerName,amountMinor,currency,driverAmountMinor,platformCommissionMinor,status,method,const DeepCollectionEquality().hash(_acceptedMethods),checkoutUrl,paymentMethodDetail,cashReportedAt,cashConfirmedAt,disputedAt,unpaidMarkedAt,paidAt,voidedAt,createdAt,reviewNote,resolutionNote,resolvedAt,voidReason]);

@override
String toString() {
  return 'TripPayment(id: $id, tripId: $tripId, driverId: $driverId, passengerId: $passengerId, driverName: $driverName, passengerName: $passengerName, amountMinor: $amountMinor, currency: $currency, driverAmountMinor: $driverAmountMinor, platformCommissionMinor: $platformCommissionMinor, status: $status, method: $method, acceptedMethods: $acceptedMethods, checkoutUrl: $checkoutUrl, paymentMethodDetail: $paymentMethodDetail, cashReportedAt: $cashReportedAt, cashConfirmedAt: $cashConfirmedAt, disputedAt: $disputedAt, unpaidMarkedAt: $unpaidMarkedAt, paidAt: $paidAt, voidedAt: $voidedAt, createdAt: $createdAt, reviewNote: $reviewNote, resolutionNote: $resolutionNote, resolvedAt: $resolvedAt, voidReason: $voidReason)';
}


}

/// @nodoc
abstract mixin class _$TripPaymentCopyWith<$Res> implements $TripPaymentCopyWith<$Res> {
  factory _$TripPaymentCopyWith(_TripPayment value, $Res Function(_TripPayment) _then) = __$TripPaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String driverId, String passengerId, String driverName, String passengerName, int amountMinor, String currency, int driverAmountMinor, int platformCommissionMinor, TripPaymentStatus status, TripPaymentMethod? method, List<TripPaymentMethod> acceptedMethods, String? checkoutUrl, String? paymentMethodDetail, DateTime? cashReportedAt, DateTime? cashConfirmedAt, DateTime? disputedAt, DateTime? unpaidMarkedAt, DateTime? paidAt, DateTime? voidedAt, DateTime createdAt, String? reviewNote, String? resolutionNote, DateTime? resolvedAt, String? voidReason
});




}
/// @nodoc
class __$TripPaymentCopyWithImpl<$Res>
    implements _$TripPaymentCopyWith<$Res> {
  __$TripPaymentCopyWithImpl(this._self, this._then);

  final _TripPayment _self;
  final $Res Function(_TripPayment) _then;

/// Create a copy of TripPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? driverId = null,Object? passengerId = null,Object? driverName = null,Object? passengerName = null,Object? amountMinor = null,Object? currency = null,Object? driverAmountMinor = null,Object? platformCommissionMinor = null,Object? status = null,Object? method = freezed,Object? acceptedMethods = null,Object? checkoutUrl = freezed,Object? paymentMethodDetail = freezed,Object? cashReportedAt = freezed,Object? cashConfirmedAt = freezed,Object? disputedAt = freezed,Object? unpaidMarkedAt = freezed,Object? paidAt = freezed,Object? voidedAt = freezed,Object? createdAt = null,Object? reviewNote = freezed,Object? resolutionNote = freezed,Object? resolvedAt = freezed,Object? voidReason = freezed,}) {
  return _then(_TripPayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,passengerId: null == passengerId ? _self.passengerId : passengerId // ignore: cast_nullable_to_non_nullable
as String,driverName: null == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String,passengerName: null == passengerName ? _self.passengerName : passengerName // ignore: cast_nullable_to_non_nullable
as String,amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,driverAmountMinor: null == driverAmountMinor ? _self.driverAmountMinor : driverAmountMinor // ignore: cast_nullable_to_non_nullable
as int,platformCommissionMinor: null == platformCommissionMinor ? _self.platformCommissionMinor : platformCommissionMinor // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripPaymentStatus,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as TripPaymentMethod?,acceptedMethods: null == acceptedMethods ? _self._acceptedMethods : acceptedMethods // ignore: cast_nullable_to_non_nullable
as List<TripPaymentMethod>,checkoutUrl: freezed == checkoutUrl ? _self.checkoutUrl : checkoutUrl // ignore: cast_nullable_to_non_nullable
as String?,paymentMethodDetail: freezed == paymentMethodDetail ? _self.paymentMethodDetail : paymentMethodDetail // ignore: cast_nullable_to_non_nullable
as String?,cashReportedAt: freezed == cashReportedAt ? _self.cashReportedAt : cashReportedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cashConfirmedAt: freezed == cashConfirmedAt ? _self.cashConfirmedAt : cashConfirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,disputedAt: freezed == disputedAt ? _self.disputedAt : disputedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,unpaidMarkedAt: freezed == unpaidMarkedAt ? _self.unpaidMarkedAt : unpaidMarkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voidedAt: freezed == voidedAt ? _self.voidedAt : voidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,resolutionNote: freezed == resolutionNote ? _self.resolutionNote : resolutionNote // ignore: cast_nullable_to_non_nullable
as String?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PaymentMethods {

 bool get acceptsCash; bool get acceptsBold;/// Bold está configurado en Kyq.
 bool get boldAvailable;
/// Create a copy of PaymentMethods
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentMethodsCopyWith<PaymentMethods> get copyWith => _$PaymentMethodsCopyWithImpl<PaymentMethods>(this as PaymentMethods, _$identity);

  /// Serializes this PaymentMethods to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentMethods&&(identical(other.acceptsCash, acceptsCash) || other.acceptsCash == acceptsCash)&&(identical(other.acceptsBold, acceptsBold) || other.acceptsBold == acceptsBold)&&(identical(other.boldAvailable, boldAvailable) || other.boldAvailable == boldAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,acceptsCash,acceptsBold,boldAvailable);

@override
String toString() {
  return 'PaymentMethods(acceptsCash: $acceptsCash, acceptsBold: $acceptsBold, boldAvailable: $boldAvailable)';
}


}

/// @nodoc
abstract mixin class $PaymentMethodsCopyWith<$Res>  {
  factory $PaymentMethodsCopyWith(PaymentMethods value, $Res Function(PaymentMethods) _then) = _$PaymentMethodsCopyWithImpl;
@useResult
$Res call({
 bool acceptsCash, bool acceptsBold, bool boldAvailable
});




}
/// @nodoc
class _$PaymentMethodsCopyWithImpl<$Res>
    implements $PaymentMethodsCopyWith<$Res> {
  _$PaymentMethodsCopyWithImpl(this._self, this._then);

  final PaymentMethods _self;
  final $Res Function(PaymentMethods) _then;

/// Create a copy of PaymentMethods
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? acceptsCash = null,Object? acceptsBold = null,Object? boldAvailable = null,}) {
  return _then(_self.copyWith(
acceptsCash: null == acceptsCash ? _self.acceptsCash : acceptsCash // ignore: cast_nullable_to_non_nullable
as bool,acceptsBold: null == acceptsBold ? _self.acceptsBold : acceptsBold // ignore: cast_nullable_to_non_nullable
as bool,boldAvailable: null == boldAvailable ? _self.boldAvailable : boldAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentMethods].
extension PaymentMethodsPatterns on PaymentMethods {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentMethods value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentMethods() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentMethods value)  $default,){
final _that = this;
switch (_that) {
case _PaymentMethods():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentMethods value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentMethods() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool acceptsCash,  bool acceptsBold,  bool boldAvailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentMethods() when $default != null:
return $default(_that.acceptsCash,_that.acceptsBold,_that.boldAvailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool acceptsCash,  bool acceptsBold,  bool boldAvailable)  $default,) {final _that = this;
switch (_that) {
case _PaymentMethods():
return $default(_that.acceptsCash,_that.acceptsBold,_that.boldAvailable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool acceptsCash,  bool acceptsBold,  bool boldAvailable)?  $default,) {final _that = this;
switch (_that) {
case _PaymentMethods() when $default != null:
return $default(_that.acceptsCash,_that.acceptsBold,_that.boldAvailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentMethods implements PaymentMethods {
  const _PaymentMethods({required this.acceptsCash, required this.acceptsBold, this.boldAvailable = false});
  factory _PaymentMethods.fromJson(Map<String, dynamic> json) => _$PaymentMethodsFromJson(json);

@override final  bool acceptsCash;
@override final  bool acceptsBold;
/// Bold está configurado en Kyq.
@override@JsonKey() final  bool boldAvailable;

/// Create a copy of PaymentMethods
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentMethodsCopyWith<_PaymentMethods> get copyWith => __$PaymentMethodsCopyWithImpl<_PaymentMethods>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentMethodsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentMethods&&(identical(other.acceptsCash, acceptsCash) || other.acceptsCash == acceptsCash)&&(identical(other.acceptsBold, acceptsBold) || other.acceptsBold == acceptsBold)&&(identical(other.boldAvailable, boldAvailable) || other.boldAvailable == boldAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,acceptsCash,acceptsBold,boldAvailable);

@override
String toString() {
  return 'PaymentMethods(acceptsCash: $acceptsCash, acceptsBold: $acceptsBold, boldAvailable: $boldAvailable)';
}


}

/// @nodoc
abstract mixin class _$PaymentMethodsCopyWith<$Res> implements $PaymentMethodsCopyWith<$Res> {
  factory _$PaymentMethodsCopyWith(_PaymentMethods value, $Res Function(_PaymentMethods) _then) = __$PaymentMethodsCopyWithImpl;
@override @useResult
$Res call({
 bool acceptsCash, bool acceptsBold, bool boldAvailable
});




}
/// @nodoc
class __$PaymentMethodsCopyWithImpl<$Res>
    implements _$PaymentMethodsCopyWith<$Res> {
  __$PaymentMethodsCopyWithImpl(this._self, this._then);

  final _PaymentMethods _self;
  final $Res Function(_PaymentMethods) _then;

/// Create a copy of PaymentMethods
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? acceptsCash = null,Object? acceptsBold = null,Object? boldAvailable = null,}) {
  return _then(_PaymentMethods(
acceptsCash: null == acceptsCash ? _self.acceptsCash : acceptsCash // ignore: cast_nullable_to_non_nullable
as bool,acceptsBold: null == acceptsBold ? _self.acceptsBold : acceptsBold // ignore: cast_nullable_to_non_nullable
as bool,boldAvailable: null == boldAvailable ? _self.boldAvailable : boldAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$LedgerEntry {

 String get id; String get kind; int get amountMinor; String get currency; String? get tripPaymentId; String? get tripId; String? get payoutId;/// Referencia del giro.
 String? get reference; DateTime get createdAt;
/// Create a copy of LedgerEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LedgerEntryCopyWith<LedgerEntry> get copyWith => _$LedgerEntryCopyWithImpl<LedgerEntry>(this as LedgerEntry, _$identity);

  /// Serializes this LedgerEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LedgerEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.tripPaymentId, tripPaymentId) || other.tripPaymentId == tripPaymentId)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.payoutId, payoutId) || other.payoutId == payoutId)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,amountMinor,currency,tripPaymentId,tripId,payoutId,reference,createdAt);

@override
String toString() {
  return 'LedgerEntry(id: $id, kind: $kind, amountMinor: $amountMinor, currency: $currency, tripPaymentId: $tripPaymentId, tripId: $tripId, payoutId: $payoutId, reference: $reference, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $LedgerEntryCopyWith<$Res>  {
  factory $LedgerEntryCopyWith(LedgerEntry value, $Res Function(LedgerEntry) _then) = _$LedgerEntryCopyWithImpl;
@useResult
$Res call({
 String id, String kind, int amountMinor, String currency, String? tripPaymentId, String? tripId, String? payoutId, String? reference, DateTime createdAt
});




}
/// @nodoc
class _$LedgerEntryCopyWithImpl<$Res>
    implements $LedgerEntryCopyWith<$Res> {
  _$LedgerEntryCopyWithImpl(this._self, this._then);

  final LedgerEntry _self;
  final $Res Function(LedgerEntry) _then;

/// Create a copy of LedgerEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? amountMinor = null,Object? currency = null,Object? tripPaymentId = freezed,Object? tripId = freezed,Object? payoutId = freezed,Object? reference = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,tripPaymentId: freezed == tripPaymentId ? _self.tripPaymentId : tripPaymentId // ignore: cast_nullable_to_non_nullable
as String?,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,payoutId: freezed == payoutId ? _self.payoutId : payoutId // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [LedgerEntry].
extension LedgerEntryPatterns on LedgerEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LedgerEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LedgerEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LedgerEntry value)  $default,){
final _that = this;
switch (_that) {
case _LedgerEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LedgerEntry value)?  $default,){
final _that = this;
switch (_that) {
case _LedgerEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  int amountMinor,  String currency,  String? tripPaymentId,  String? tripId,  String? payoutId,  String? reference,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LedgerEntry() when $default != null:
return $default(_that.id,_that.kind,_that.amountMinor,_that.currency,_that.tripPaymentId,_that.tripId,_that.payoutId,_that.reference,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  int amountMinor,  String currency,  String? tripPaymentId,  String? tripId,  String? payoutId,  String? reference,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _LedgerEntry():
return $default(_that.id,_that.kind,_that.amountMinor,_that.currency,_that.tripPaymentId,_that.tripId,_that.payoutId,_that.reference,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  int amountMinor,  String currency,  String? tripPaymentId,  String? tripId,  String? payoutId,  String? reference,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _LedgerEntry() when $default != null:
return $default(_that.id,_that.kind,_that.amountMinor,_that.currency,_that.tripPaymentId,_that.tripId,_that.payoutId,_that.reference,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LedgerEntry implements LedgerEntry {
  const _LedgerEntry({required this.id, required this.kind, required this.amountMinor, required this.currency, this.tripPaymentId, this.tripId, this.payoutId, this.reference, required this.createdAt});
  factory _LedgerEntry.fromJson(Map<String, dynamic> json) => _$LedgerEntryFromJson(json);

@override final  String id;
@override final  String kind;
@override final  int amountMinor;
@override final  String currency;
@override final  String? tripPaymentId;
@override final  String? tripId;
@override final  String? payoutId;
/// Referencia del giro.
@override final  String? reference;
@override final  DateTime createdAt;

/// Create a copy of LedgerEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LedgerEntryCopyWith<_LedgerEntry> get copyWith => __$LedgerEntryCopyWithImpl<_LedgerEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LedgerEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LedgerEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.tripPaymentId, tripPaymentId) || other.tripPaymentId == tripPaymentId)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.payoutId, payoutId) || other.payoutId == payoutId)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,amountMinor,currency,tripPaymentId,tripId,payoutId,reference,createdAt);

@override
String toString() {
  return 'LedgerEntry(id: $id, kind: $kind, amountMinor: $amountMinor, currency: $currency, tripPaymentId: $tripPaymentId, tripId: $tripId, payoutId: $payoutId, reference: $reference, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$LedgerEntryCopyWith<$Res> implements $LedgerEntryCopyWith<$Res> {
  factory _$LedgerEntryCopyWith(_LedgerEntry value, $Res Function(_LedgerEntry) _then) = __$LedgerEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, int amountMinor, String currency, String? tripPaymentId, String? tripId, String? payoutId, String? reference, DateTime createdAt
});




}
/// @nodoc
class __$LedgerEntryCopyWithImpl<$Res>
    implements _$LedgerEntryCopyWith<$Res> {
  __$LedgerEntryCopyWithImpl(this._self, this._then);

  final _LedgerEntry _self;
  final $Res Function(_LedgerEntry) _then;

/// Create a copy of LedgerEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? amountMinor = null,Object? currency = null,Object? tripPaymentId = freezed,Object? tripId = freezed,Object? payoutId = freezed,Object? reference = freezed,Object? createdAt = null,}) {
  return _then(_LedgerEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,tripPaymentId: freezed == tripPaymentId ? _self.tripPaymentId : tripPaymentId // ignore: cast_nullable_to_non_nullable
as String?,tripId: freezed == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String?,payoutId: freezed == payoutId ? _self.payoutId : payoutId // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SettlementBalance {

 String get currency; int get creditedMinor; int get debitedMinor; int get paidOutMinor; int get balanceMinor;
/// Create a copy of SettlementBalance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementBalanceCopyWith<SettlementBalance> get copyWith => _$SettlementBalanceCopyWithImpl<SettlementBalance>(this as SettlementBalance, _$identity);

  /// Serializes this SettlementBalance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementBalance&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.creditedMinor, creditedMinor) || other.creditedMinor == creditedMinor)&&(identical(other.debitedMinor, debitedMinor) || other.debitedMinor == debitedMinor)&&(identical(other.paidOutMinor, paidOutMinor) || other.paidOutMinor == paidOutMinor)&&(identical(other.balanceMinor, balanceMinor) || other.balanceMinor == balanceMinor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currency,creditedMinor,debitedMinor,paidOutMinor,balanceMinor);

@override
String toString() {
  return 'SettlementBalance(currency: $currency, creditedMinor: $creditedMinor, debitedMinor: $debitedMinor, paidOutMinor: $paidOutMinor, balanceMinor: $balanceMinor)';
}


}

/// @nodoc
abstract mixin class $SettlementBalanceCopyWith<$Res>  {
  factory $SettlementBalanceCopyWith(SettlementBalance value, $Res Function(SettlementBalance) _then) = _$SettlementBalanceCopyWithImpl;
@useResult
$Res call({
 String currency, int creditedMinor, int debitedMinor, int paidOutMinor, int balanceMinor
});




}
/// @nodoc
class _$SettlementBalanceCopyWithImpl<$Res>
    implements $SettlementBalanceCopyWith<$Res> {
  _$SettlementBalanceCopyWithImpl(this._self, this._then);

  final SettlementBalance _self;
  final $Res Function(SettlementBalance) _then;

/// Create a copy of SettlementBalance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currency = null,Object? creditedMinor = null,Object? debitedMinor = null,Object? paidOutMinor = null,Object? balanceMinor = null,}) {
  return _then(_self.copyWith(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,creditedMinor: null == creditedMinor ? _self.creditedMinor : creditedMinor // ignore: cast_nullable_to_non_nullable
as int,debitedMinor: null == debitedMinor ? _self.debitedMinor : debitedMinor // ignore: cast_nullable_to_non_nullable
as int,paidOutMinor: null == paidOutMinor ? _self.paidOutMinor : paidOutMinor // ignore: cast_nullable_to_non_nullable
as int,balanceMinor: null == balanceMinor ? _self.balanceMinor : balanceMinor // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SettlementBalance].
extension SettlementBalancePatterns on SettlementBalance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettlementBalance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettlementBalance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettlementBalance value)  $default,){
final _that = this;
switch (_that) {
case _SettlementBalance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettlementBalance value)?  $default,){
final _that = this;
switch (_that) {
case _SettlementBalance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currency,  int creditedMinor,  int debitedMinor,  int paidOutMinor,  int balanceMinor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettlementBalance() when $default != null:
return $default(_that.currency,_that.creditedMinor,_that.debitedMinor,_that.paidOutMinor,_that.balanceMinor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currency,  int creditedMinor,  int debitedMinor,  int paidOutMinor,  int balanceMinor)  $default,) {final _that = this;
switch (_that) {
case _SettlementBalance():
return $default(_that.currency,_that.creditedMinor,_that.debitedMinor,_that.paidOutMinor,_that.balanceMinor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currency,  int creditedMinor,  int debitedMinor,  int paidOutMinor,  int balanceMinor)?  $default,) {final _that = this;
switch (_that) {
case _SettlementBalance() when $default != null:
return $default(_that.currency,_that.creditedMinor,_that.debitedMinor,_that.paidOutMinor,_that.balanceMinor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SettlementBalance implements SettlementBalance {
  const _SettlementBalance({required this.currency, this.creditedMinor = 0, this.debitedMinor = 0, this.paidOutMinor = 0, this.balanceMinor = 0});
  factory _SettlementBalance.fromJson(Map<String, dynamic> json) => _$SettlementBalanceFromJson(json);

@override final  String currency;
@override@JsonKey() final  int creditedMinor;
@override@JsonKey() final  int debitedMinor;
@override@JsonKey() final  int paidOutMinor;
@override@JsonKey() final  int balanceMinor;

/// Create a copy of SettlementBalance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettlementBalanceCopyWith<_SettlementBalance> get copyWith => __$SettlementBalanceCopyWithImpl<_SettlementBalance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettlementBalanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettlementBalance&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.creditedMinor, creditedMinor) || other.creditedMinor == creditedMinor)&&(identical(other.debitedMinor, debitedMinor) || other.debitedMinor == debitedMinor)&&(identical(other.paidOutMinor, paidOutMinor) || other.paidOutMinor == paidOutMinor)&&(identical(other.balanceMinor, balanceMinor) || other.balanceMinor == balanceMinor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currency,creditedMinor,debitedMinor,paidOutMinor,balanceMinor);

@override
String toString() {
  return 'SettlementBalance(currency: $currency, creditedMinor: $creditedMinor, debitedMinor: $debitedMinor, paidOutMinor: $paidOutMinor, balanceMinor: $balanceMinor)';
}


}

/// @nodoc
abstract mixin class _$SettlementBalanceCopyWith<$Res> implements $SettlementBalanceCopyWith<$Res> {
  factory _$SettlementBalanceCopyWith(_SettlementBalance value, $Res Function(_SettlementBalance) _then) = __$SettlementBalanceCopyWithImpl;
@override @useResult
$Res call({
 String currency, int creditedMinor, int debitedMinor, int paidOutMinor, int balanceMinor
});




}
/// @nodoc
class __$SettlementBalanceCopyWithImpl<$Res>
    implements _$SettlementBalanceCopyWith<$Res> {
  __$SettlementBalanceCopyWithImpl(this._self, this._then);

  final _SettlementBalance _self;
  final $Res Function(_SettlementBalance) _then;

/// Create a copy of SettlementBalance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currency = null,Object? creditedMinor = null,Object? debitedMinor = null,Object? paidOutMinor = null,Object? balanceMinor = null,}) {
  return _then(_SettlementBalance(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,creditedMinor: null == creditedMinor ? _self.creditedMinor : creditedMinor // ignore: cast_nullable_to_non_nullable
as int,debitedMinor: null == debitedMinor ? _self.debitedMinor : debitedMinor // ignore: cast_nullable_to_non_nullable
as int,paidOutMinor: null == paidOutMinor ? _self.paidOutMinor : paidOutMinor // ignore: cast_nullable_to_non_nullable
as int,balanceMinor: null == balanceMinor ? _self.balanceMinor : balanceMinor // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DriverSettlement {

 List<SettlementBalance> get balances; List<LedgerEntry> get entries; List<TripPayment> get payments;
/// Create a copy of DriverSettlement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverSettlementCopyWith<DriverSettlement> get copyWith => _$DriverSettlementCopyWithImpl<DriverSettlement>(this as DriverSettlement, _$identity);

  /// Serializes this DriverSettlement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverSettlement&&const DeepCollectionEquality().equals(other.balances, balances)&&const DeepCollectionEquality().equals(other.entries, entries)&&const DeepCollectionEquality().equals(other.payments, payments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(balances),const DeepCollectionEquality().hash(entries),const DeepCollectionEquality().hash(payments));

@override
String toString() {
  return 'DriverSettlement(balances: $balances, entries: $entries, payments: $payments)';
}


}

/// @nodoc
abstract mixin class $DriverSettlementCopyWith<$Res>  {
  factory $DriverSettlementCopyWith(DriverSettlement value, $Res Function(DriverSettlement) _then) = _$DriverSettlementCopyWithImpl;
@useResult
$Res call({
 List<SettlementBalance> balances, List<LedgerEntry> entries, List<TripPayment> payments
});




}
/// @nodoc
class _$DriverSettlementCopyWithImpl<$Res>
    implements $DriverSettlementCopyWith<$Res> {
  _$DriverSettlementCopyWithImpl(this._self, this._then);

  final DriverSettlement _self;
  final $Res Function(DriverSettlement) _then;

/// Create a copy of DriverSettlement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balances = null,Object? entries = null,Object? payments = null,}) {
  return _then(_self.copyWith(
balances: null == balances ? _self.balances : balances // ignore: cast_nullable_to_non_nullable
as List<SettlementBalance>,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<LedgerEntry>,payments: null == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as List<TripPayment>,
  ));
}

}


/// Adds pattern-matching-related methods to [DriverSettlement].
extension DriverSettlementPatterns on DriverSettlement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverSettlement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverSettlement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverSettlement value)  $default,){
final _that = this;
switch (_that) {
case _DriverSettlement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverSettlement value)?  $default,){
final _that = this;
switch (_that) {
case _DriverSettlement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SettlementBalance> balances,  List<LedgerEntry> entries,  List<TripPayment> payments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverSettlement() when $default != null:
return $default(_that.balances,_that.entries,_that.payments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SettlementBalance> balances,  List<LedgerEntry> entries,  List<TripPayment> payments)  $default,) {final _that = this;
switch (_that) {
case _DriverSettlement():
return $default(_that.balances,_that.entries,_that.payments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SettlementBalance> balances,  List<LedgerEntry> entries,  List<TripPayment> payments)?  $default,) {final _that = this;
switch (_that) {
case _DriverSettlement() when $default != null:
return $default(_that.balances,_that.entries,_that.payments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverSettlement implements DriverSettlement {
  const _DriverSettlement({final  List<SettlementBalance> balances = const <SettlementBalance>[], final  List<LedgerEntry> entries = const <LedgerEntry>[], final  List<TripPayment> payments = const <TripPayment>[]}): _balances = balances,_entries = entries,_payments = payments;
  factory _DriverSettlement.fromJson(Map<String, dynamic> json) => _$DriverSettlementFromJson(json);

 final  List<SettlementBalance> _balances;
@override@JsonKey() List<SettlementBalance> get balances {
  if (_balances is EqualUnmodifiableListView) return _balances;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_balances);
}

 final  List<LedgerEntry> _entries;
@override@JsonKey() List<LedgerEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

 final  List<TripPayment> _payments;
@override@JsonKey() List<TripPayment> get payments {
  if (_payments is EqualUnmodifiableListView) return _payments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_payments);
}


/// Create a copy of DriverSettlement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverSettlementCopyWith<_DriverSettlement> get copyWith => __$DriverSettlementCopyWithImpl<_DriverSettlement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverSettlementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverSettlement&&const DeepCollectionEquality().equals(other._balances, _balances)&&const DeepCollectionEquality().equals(other._entries, _entries)&&const DeepCollectionEquality().equals(other._payments, _payments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_balances),const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_payments));

@override
String toString() {
  return 'DriverSettlement(balances: $balances, entries: $entries, payments: $payments)';
}


}

/// @nodoc
abstract mixin class _$DriverSettlementCopyWith<$Res> implements $DriverSettlementCopyWith<$Res> {
  factory _$DriverSettlementCopyWith(_DriverSettlement value, $Res Function(_DriverSettlement) _then) = __$DriverSettlementCopyWithImpl;
@override @useResult
$Res call({
 List<SettlementBalance> balances, List<LedgerEntry> entries, List<TripPayment> payments
});




}
/// @nodoc
class __$DriverSettlementCopyWithImpl<$Res>
    implements _$DriverSettlementCopyWith<$Res> {
  __$DriverSettlementCopyWithImpl(this._self, this._then);

  final _DriverSettlement _self;
  final $Res Function(_DriverSettlement) _then;

/// Create a copy of DriverSettlement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balances = null,Object? entries = null,Object? payments = null,}) {
  return _then(_DriverSettlement(
balances: null == balances ? _self._balances : balances // ignore: cast_nullable_to_non_nullable
as List<SettlementBalance>,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<LedgerEntry>,payments: null == payments ? _self._payments : payments // ignore: cast_nullable_to_non_nullable
as List<TripPayment>,
  ));
}


}


/// @nodoc
mixin _$SettlementRow {

 String get driverId; String get displayName; String? get phoneE164; String? get vehiclePlate; String get currency; int get creditedMinor; int get debitedMinor; int get paidOutMinor; int get balanceMinor; DateTime? get lastPayoutAt;
/// Create a copy of SettlementRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementRowCopyWith<SettlementRow> get copyWith => _$SettlementRowCopyWithImpl<SettlementRow>(this as SettlementRow, _$identity);

  /// Serializes this SettlementRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementRow&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.creditedMinor, creditedMinor) || other.creditedMinor == creditedMinor)&&(identical(other.debitedMinor, debitedMinor) || other.debitedMinor == debitedMinor)&&(identical(other.paidOutMinor, paidOutMinor) || other.paidOutMinor == paidOutMinor)&&(identical(other.balanceMinor, balanceMinor) || other.balanceMinor == balanceMinor)&&(identical(other.lastPayoutAt, lastPayoutAt) || other.lastPayoutAt == lastPayoutAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,phoneE164,vehiclePlate,currency,creditedMinor,debitedMinor,paidOutMinor,balanceMinor,lastPayoutAt);

@override
String toString() {
  return 'SettlementRow(driverId: $driverId, displayName: $displayName, phoneE164: $phoneE164, vehiclePlate: $vehiclePlate, currency: $currency, creditedMinor: $creditedMinor, debitedMinor: $debitedMinor, paidOutMinor: $paidOutMinor, balanceMinor: $balanceMinor, lastPayoutAt: $lastPayoutAt)';
}


}

/// @nodoc
abstract mixin class $SettlementRowCopyWith<$Res>  {
  factory $SettlementRowCopyWith(SettlementRow value, $Res Function(SettlementRow) _then) = _$SettlementRowCopyWithImpl;
@useResult
$Res call({
 String driverId, String displayName, String? phoneE164, String? vehiclePlate, String currency, int creditedMinor, int debitedMinor, int paidOutMinor, int balanceMinor, DateTime? lastPayoutAt
});




}
/// @nodoc
class _$SettlementRowCopyWithImpl<$Res>
    implements $SettlementRowCopyWith<$Res> {
  _$SettlementRowCopyWithImpl(this._self, this._then);

  final SettlementRow _self;
  final $Res Function(SettlementRow) _then;

/// Create a copy of SettlementRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? displayName = null,Object? phoneE164 = freezed,Object? vehiclePlate = freezed,Object? currency = null,Object? creditedMinor = null,Object? debitedMinor = null,Object? paidOutMinor = null,Object? balanceMinor = null,Object? lastPayoutAt = freezed,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,phoneE164: freezed == phoneE164 ? _self.phoneE164 : phoneE164 // ignore: cast_nullable_to_non_nullable
as String?,vehiclePlate: freezed == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,creditedMinor: null == creditedMinor ? _self.creditedMinor : creditedMinor // ignore: cast_nullable_to_non_nullable
as int,debitedMinor: null == debitedMinor ? _self.debitedMinor : debitedMinor // ignore: cast_nullable_to_non_nullable
as int,paidOutMinor: null == paidOutMinor ? _self.paidOutMinor : paidOutMinor // ignore: cast_nullable_to_non_nullable
as int,balanceMinor: null == balanceMinor ? _self.balanceMinor : balanceMinor // ignore: cast_nullable_to_non_nullable
as int,lastPayoutAt: freezed == lastPayoutAt ? _self.lastPayoutAt : lastPayoutAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SettlementRow].
extension SettlementRowPatterns on SettlementRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettlementRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettlementRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettlementRow value)  $default,){
final _that = this;
switch (_that) {
case _SettlementRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettlementRow value)?  $default,){
final _that = this;
switch (_that) {
case _SettlementRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String displayName,  String? phoneE164,  String? vehiclePlate,  String currency,  int creditedMinor,  int debitedMinor,  int paidOutMinor,  int balanceMinor,  DateTime? lastPayoutAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettlementRow() when $default != null:
return $default(_that.driverId,_that.displayName,_that.phoneE164,_that.vehiclePlate,_that.currency,_that.creditedMinor,_that.debitedMinor,_that.paidOutMinor,_that.balanceMinor,_that.lastPayoutAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String displayName,  String? phoneE164,  String? vehiclePlate,  String currency,  int creditedMinor,  int debitedMinor,  int paidOutMinor,  int balanceMinor,  DateTime? lastPayoutAt)  $default,) {final _that = this;
switch (_that) {
case _SettlementRow():
return $default(_that.driverId,_that.displayName,_that.phoneE164,_that.vehiclePlate,_that.currency,_that.creditedMinor,_that.debitedMinor,_that.paidOutMinor,_that.balanceMinor,_that.lastPayoutAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String displayName,  String? phoneE164,  String? vehiclePlate,  String currency,  int creditedMinor,  int debitedMinor,  int paidOutMinor,  int balanceMinor,  DateTime? lastPayoutAt)?  $default,) {final _that = this;
switch (_that) {
case _SettlementRow() when $default != null:
return $default(_that.driverId,_that.displayName,_that.phoneE164,_that.vehiclePlate,_that.currency,_that.creditedMinor,_that.debitedMinor,_that.paidOutMinor,_that.balanceMinor,_that.lastPayoutAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SettlementRow implements SettlementRow {
  const _SettlementRow({required this.driverId, required this.displayName, this.phoneE164, this.vehiclePlate, required this.currency, this.creditedMinor = 0, this.debitedMinor = 0, this.paidOutMinor = 0, this.balanceMinor = 0, this.lastPayoutAt});
  factory _SettlementRow.fromJson(Map<String, dynamic> json) => _$SettlementRowFromJson(json);

@override final  String driverId;
@override final  String displayName;
@override final  String? phoneE164;
@override final  String? vehiclePlate;
@override final  String currency;
@override@JsonKey() final  int creditedMinor;
@override@JsonKey() final  int debitedMinor;
@override@JsonKey() final  int paidOutMinor;
@override@JsonKey() final  int balanceMinor;
@override final  DateTime? lastPayoutAt;

/// Create a copy of SettlementRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettlementRowCopyWith<_SettlementRow> get copyWith => __$SettlementRowCopyWithImpl<_SettlementRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettlementRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettlementRow&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.creditedMinor, creditedMinor) || other.creditedMinor == creditedMinor)&&(identical(other.debitedMinor, debitedMinor) || other.debitedMinor == debitedMinor)&&(identical(other.paidOutMinor, paidOutMinor) || other.paidOutMinor == paidOutMinor)&&(identical(other.balanceMinor, balanceMinor) || other.balanceMinor == balanceMinor)&&(identical(other.lastPayoutAt, lastPayoutAt) || other.lastPayoutAt == lastPayoutAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,phoneE164,vehiclePlate,currency,creditedMinor,debitedMinor,paidOutMinor,balanceMinor,lastPayoutAt);

@override
String toString() {
  return 'SettlementRow(driverId: $driverId, displayName: $displayName, phoneE164: $phoneE164, vehiclePlate: $vehiclePlate, currency: $currency, creditedMinor: $creditedMinor, debitedMinor: $debitedMinor, paidOutMinor: $paidOutMinor, balanceMinor: $balanceMinor, lastPayoutAt: $lastPayoutAt)';
}


}

/// @nodoc
abstract mixin class _$SettlementRowCopyWith<$Res> implements $SettlementRowCopyWith<$Res> {
  factory _$SettlementRowCopyWith(_SettlementRow value, $Res Function(_SettlementRow) _then) = __$SettlementRowCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String displayName, String? phoneE164, String? vehiclePlate, String currency, int creditedMinor, int debitedMinor, int paidOutMinor, int balanceMinor, DateTime? lastPayoutAt
});




}
/// @nodoc
class __$SettlementRowCopyWithImpl<$Res>
    implements _$SettlementRowCopyWith<$Res> {
  __$SettlementRowCopyWithImpl(this._self, this._then);

  final _SettlementRow _self;
  final $Res Function(_SettlementRow) _then;

/// Create a copy of SettlementRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? displayName = null,Object? phoneE164 = freezed,Object? vehiclePlate = freezed,Object? currency = null,Object? creditedMinor = null,Object? debitedMinor = null,Object? paidOutMinor = null,Object? balanceMinor = null,Object? lastPayoutAt = freezed,}) {
  return _then(_SettlementRow(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,phoneE164: freezed == phoneE164 ? _self.phoneE164 : phoneE164 // ignore: cast_nullable_to_non_nullable
as String?,vehiclePlate: freezed == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,creditedMinor: null == creditedMinor ? _self.creditedMinor : creditedMinor // ignore: cast_nullable_to_non_nullable
as int,debitedMinor: null == debitedMinor ? _self.debitedMinor : debitedMinor // ignore: cast_nullable_to_non_nullable
as int,paidOutMinor: null == paidOutMinor ? _self.paidOutMinor : paidOutMinor // ignore: cast_nullable_to_non_nullable
as int,balanceMinor: null == balanceMinor ? _self.balanceMinor : balanceMinor // ignore: cast_nullable_to_non_nullable
as int,lastPayoutAt: freezed == lastPayoutAt ? _self.lastPayoutAt : lastPayoutAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
