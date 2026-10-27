// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Tokens {

 String get accessToken; String get refreshToken; UserRole get role;
/// Create a copy of Tokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokensCopyWith<Tokens> get copyWith => _$TokensCopyWithImpl<Tokens>(this as Tokens, _$identity);

  /// Serializes this Tokens to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tokens&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,role);

@override
String toString() {
  return 'Tokens(accessToken: $accessToken, refreshToken: $refreshToken, role: $role)';
}


}

/// @nodoc
abstract mixin class $TokensCopyWith<$Res>  {
  factory $TokensCopyWith(Tokens value, $Res Function(Tokens) _then) = _$TokensCopyWithImpl;
@useResult
$Res call({
 String accessToken, String refreshToken, UserRole role
});




}
/// @nodoc
class _$TokensCopyWithImpl<$Res>
    implements $TokensCopyWith<$Res> {
  _$TokensCopyWithImpl(this._self, this._then);

  final Tokens _self;
  final $Res Function(Tokens) _then;

/// Create a copy of Tokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = null,Object? role = null,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,
  ));
}

}


/// Adds pattern-matching-related methods to [Tokens].
extension TokensPatterns on Tokens {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tokens() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tokens value)  $default,){
final _that = this;
switch (_that) {
case _Tokens():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tokens value)?  $default,){
final _that = this;
switch (_that) {
case _Tokens() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  UserRole role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tokens() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  UserRole role)  $default,) {final _that = this;
switch (_that) {
case _Tokens():
return $default(_that.accessToken,_that.refreshToken,_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String refreshToken,  UserRole role)?  $default,) {final _that = this;
switch (_that) {
case _Tokens() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Tokens implements Tokens {
  const _Tokens({required this.accessToken, required this.refreshToken, required this.role});
  factory _Tokens.fromJson(Map<String, dynamic> json) => _$TokensFromJson(json);

@override final  String accessToken;
@override final  String refreshToken;
@override final  UserRole role;

/// Create a copy of Tokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokensCopyWith<_Tokens> get copyWith => __$TokensCopyWithImpl<_Tokens>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TokensToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tokens&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,role);

@override
String toString() {
  return 'Tokens(accessToken: $accessToken, refreshToken: $refreshToken, role: $role)';
}


}

/// @nodoc
abstract mixin class _$TokensCopyWith<$Res> implements $TokensCopyWith<$Res> {
  factory _$TokensCopyWith(_Tokens value, $Res Function(_Tokens) _then) = __$TokensCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String refreshToken, UserRole role
});




}
/// @nodoc
class __$TokensCopyWithImpl<$Res>
    implements _$TokensCopyWith<$Res> {
  __$TokensCopyWithImpl(this._self, this._then);

  final _Tokens _self;
  final $Res Function(_Tokens) _then;

/// Create a copy of Tokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? role = null,}) {
  return _then(_Tokens(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,
  ));
}


}


/// @nodoc
mixin _$GeoPoint {

 double get lat; double get lng;
/// Create a copy of GeoPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeoPointCopyWith<GeoPoint> get copyWith => _$GeoPointCopyWithImpl<GeoPoint>(this as GeoPoint, _$identity);

  /// Serializes this GeoPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeoPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng);

@override
String toString() {
  return 'GeoPoint(lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class $GeoPointCopyWith<$Res>  {
  factory $GeoPointCopyWith(GeoPoint value, $Res Function(GeoPoint) _then) = _$GeoPointCopyWithImpl;
@useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class _$GeoPointCopyWithImpl<$Res>
    implements $GeoPointCopyWith<$Res> {
  _$GeoPointCopyWithImpl(this._self, this._then);

  final GeoPoint _self;
  final $Res Function(GeoPoint) _then;

/// Create a copy of GeoPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [GeoPoint].
extension GeoPointPatterns on GeoPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeoPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeoPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeoPoint value)  $default,){
final _that = this;
switch (_that) {
case _GeoPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeoPoint value)?  $default,){
final _that = this;
switch (_that) {
case _GeoPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeoPoint() when $default != null:
return $default(_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng)  $default,) {final _that = this;
switch (_that) {
case _GeoPoint():
return $default(_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng)?  $default,) {final _that = this;
switch (_that) {
case _GeoPoint() when $default != null:
return $default(_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GeoPoint implements GeoPoint {
  const _GeoPoint({required this.lat, required this.lng});
  factory _GeoPoint.fromJson(Map<String, dynamic> json) => _$GeoPointFromJson(json);

@override final  double lat;
@override final  double lng;

/// Create a copy of GeoPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeoPointCopyWith<_GeoPoint> get copyWith => __$GeoPointCopyWithImpl<_GeoPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GeoPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeoPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng);

@override
String toString() {
  return 'GeoPoint(lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$GeoPointCopyWith<$Res> implements $GeoPointCopyWith<$Res> {
  factory _$GeoPointCopyWith(_GeoPoint value, $Res Function(_GeoPoint) _then) = __$GeoPointCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng
});




}
/// @nodoc
class __$GeoPointCopyWithImpl<$Res>
    implements _$GeoPointCopyWith<$Res> {
  __$GeoPointCopyWithImpl(this._self, this._then);

  final _GeoPoint _self;
  final $Res Function(_GeoPoint) _then;

/// Create a copy of GeoPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,}) {
  return _then(_GeoPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$DriverDocument {

 DocType get docType; String get expiresAt; bool get approved;
/// Create a copy of DriverDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverDocumentCopyWith<DriverDocument> get copyWith => _$DriverDocumentCopyWithImpl<DriverDocument>(this as DriverDocument, _$identity);

  /// Serializes this DriverDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverDocument&&(identical(other.docType, docType) || other.docType == docType)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.approved, approved) || other.approved == approved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,docType,expiresAt,approved);

@override
String toString() {
  return 'DriverDocument(docType: $docType, expiresAt: $expiresAt, approved: $approved)';
}


}

/// @nodoc
abstract mixin class $DriverDocumentCopyWith<$Res>  {
  factory $DriverDocumentCopyWith(DriverDocument value, $Res Function(DriverDocument) _then) = _$DriverDocumentCopyWithImpl;
@useResult
$Res call({
 DocType docType, String expiresAt, bool approved
});




}
/// @nodoc
class _$DriverDocumentCopyWithImpl<$Res>
    implements $DriverDocumentCopyWith<$Res> {
  _$DriverDocumentCopyWithImpl(this._self, this._then);

  final DriverDocument _self;
  final $Res Function(DriverDocument) _then;

/// Create a copy of DriverDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docType = null,Object? expiresAt = null,Object? approved = null,}) {
  return _then(_self.copyWith(
docType: null == docType ? _self.docType : docType // ignore: cast_nullable_to_non_nullable
as DocType,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DriverDocument].
extension DriverDocumentPatterns on DriverDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverDocument value)  $default,){
final _that = this;
switch (_that) {
case _DriverDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverDocument value)?  $default,){
final _that = this;
switch (_that) {
case _DriverDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DocType docType,  String expiresAt,  bool approved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverDocument() when $default != null:
return $default(_that.docType,_that.expiresAt,_that.approved);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DocType docType,  String expiresAt,  bool approved)  $default,) {final _that = this;
switch (_that) {
case _DriverDocument():
return $default(_that.docType,_that.expiresAt,_that.approved);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DocType docType,  String expiresAt,  bool approved)?  $default,) {final _that = this;
switch (_that) {
case _DriverDocument() when $default != null:
return $default(_that.docType,_that.expiresAt,_that.approved);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverDocument implements DriverDocument {
  const _DriverDocument({required this.docType, required this.expiresAt, required this.approved});
  factory _DriverDocument.fromJson(Map<String, dynamic> json) => _$DriverDocumentFromJson(json);

@override final  DocType docType;
@override final  String expiresAt;
@override final  bool approved;

/// Create a copy of DriverDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverDocumentCopyWith<_DriverDocument> get copyWith => __$DriverDocumentCopyWithImpl<_DriverDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverDocument&&(identical(other.docType, docType) || other.docType == docType)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.approved, approved) || other.approved == approved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,docType,expiresAt,approved);

@override
String toString() {
  return 'DriverDocument(docType: $docType, expiresAt: $expiresAt, approved: $approved)';
}


}

/// @nodoc
abstract mixin class _$DriverDocumentCopyWith<$Res> implements $DriverDocumentCopyWith<$Res> {
  factory _$DriverDocumentCopyWith(_DriverDocument value, $Res Function(_DriverDocument) _then) = __$DriverDocumentCopyWithImpl;
@override @useResult
$Res call({
 DocType docType, String expiresAt, bool approved
});




}
/// @nodoc
class __$DriverDocumentCopyWithImpl<$Res>
    implements _$DriverDocumentCopyWith<$Res> {
  __$DriverDocumentCopyWithImpl(this._self, this._then);

  final _DriverDocument _self;
  final $Res Function(_DriverDocument) _then;

/// Create a copy of DriverDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docType = null,Object? expiresAt = null,Object? approved = null,}) {
  return _then(_DriverDocument(
docType: null == docType ? _self.docType : docType // ignore: cast_nullable_to_non_nullable
as DocType,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DriverMe {

 String get driverId; String get qrToken; DriverPresence get presence; SubscriptionStatus get subscriptionStatus; DateTime? get paidUntil; bool get canGoOnline; String? get blockReason; List<DriverDocument> get documents;
/// Create a copy of DriverMe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverMeCopyWith<DriverMe> get copyWith => _$DriverMeCopyWithImpl<DriverMe>(this as DriverMe, _$identity);

  /// Serializes this DriverMe to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverMe&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.qrToken, qrToken) || other.qrToken == qrToken)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.subscriptionStatus, subscriptionStatus) || other.subscriptionStatus == subscriptionStatus)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.canGoOnline, canGoOnline) || other.canGoOnline == canGoOnline)&&(identical(other.blockReason, blockReason) || other.blockReason == blockReason)&&const DeepCollectionEquality().equals(other.documents, documents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,qrToken,presence,subscriptionStatus,paidUntil,canGoOnline,blockReason,const DeepCollectionEquality().hash(documents));

@override
String toString() {
  return 'DriverMe(driverId: $driverId, qrToken: $qrToken, presence: $presence, subscriptionStatus: $subscriptionStatus, paidUntil: $paidUntil, canGoOnline: $canGoOnline, blockReason: $blockReason, documents: $documents)';
}


}

/// @nodoc
abstract mixin class $DriverMeCopyWith<$Res>  {
  factory $DriverMeCopyWith(DriverMe value, $Res Function(DriverMe) _then) = _$DriverMeCopyWithImpl;
@useResult
$Res call({
 String driverId, String qrToken, DriverPresence presence, SubscriptionStatus subscriptionStatus, DateTime? paidUntil, bool canGoOnline, String? blockReason, List<DriverDocument> documents
});




}
/// @nodoc
class _$DriverMeCopyWithImpl<$Res>
    implements $DriverMeCopyWith<$Res> {
  _$DriverMeCopyWithImpl(this._self, this._then);

  final DriverMe _self;
  final $Res Function(DriverMe) _then;

/// Create a copy of DriverMe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? qrToken = null,Object? presence = null,Object? subscriptionStatus = null,Object? paidUntil = freezed,Object? canGoOnline = null,Object? blockReason = freezed,Object? documents = null,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,qrToken: null == qrToken ? _self.qrToken : qrToken // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as DriverPresence,subscriptionStatus: null == subscriptionStatus ? _self.subscriptionStatus : subscriptionStatus // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,paidUntil: freezed == paidUntil ? _self.paidUntil : paidUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,canGoOnline: null == canGoOnline ? _self.canGoOnline : canGoOnline // ignore: cast_nullable_to_non_nullable
as bool,blockReason: freezed == blockReason ? _self.blockReason : blockReason // ignore: cast_nullable_to_non_nullable
as String?,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<DriverDocument>,
  ));
}

}


/// Adds pattern-matching-related methods to [DriverMe].
extension DriverMePatterns on DriverMe {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverMe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverMe() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverMe value)  $default,){
final _that = this;
switch (_that) {
case _DriverMe():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverMe value)?  $default,){
final _that = this;
switch (_that) {
case _DriverMe() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String qrToken,  DriverPresence presence,  SubscriptionStatus subscriptionStatus,  DateTime? paidUntil,  bool canGoOnline,  String? blockReason,  List<DriverDocument> documents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverMe() when $default != null:
return $default(_that.driverId,_that.qrToken,_that.presence,_that.subscriptionStatus,_that.paidUntil,_that.canGoOnline,_that.blockReason,_that.documents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String qrToken,  DriverPresence presence,  SubscriptionStatus subscriptionStatus,  DateTime? paidUntil,  bool canGoOnline,  String? blockReason,  List<DriverDocument> documents)  $default,) {final _that = this;
switch (_that) {
case _DriverMe():
return $default(_that.driverId,_that.qrToken,_that.presence,_that.subscriptionStatus,_that.paidUntil,_that.canGoOnline,_that.blockReason,_that.documents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String qrToken,  DriverPresence presence,  SubscriptionStatus subscriptionStatus,  DateTime? paidUntil,  bool canGoOnline,  String? blockReason,  List<DriverDocument> documents)?  $default,) {final _that = this;
switch (_that) {
case _DriverMe() when $default != null:
return $default(_that.driverId,_that.qrToken,_that.presence,_that.subscriptionStatus,_that.paidUntil,_that.canGoOnline,_that.blockReason,_that.documents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverMe implements DriverMe {
  const _DriverMe({required this.driverId, required this.qrToken, required this.presence, required this.subscriptionStatus, this.paidUntil, required this.canGoOnline, this.blockReason, final  List<DriverDocument> documents = const <DriverDocument>[]}): _documents = documents;
  factory _DriverMe.fromJson(Map<String, dynamic> json) => _$DriverMeFromJson(json);

@override final  String driverId;
@override final  String qrToken;
@override final  DriverPresence presence;
@override final  SubscriptionStatus subscriptionStatus;
@override final  DateTime? paidUntil;
@override final  bool canGoOnline;
@override final  String? blockReason;
 final  List<DriverDocument> _documents;
@override@JsonKey() List<DriverDocument> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}


/// Create a copy of DriverMe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverMeCopyWith<_DriverMe> get copyWith => __$DriverMeCopyWithImpl<_DriverMe>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverMeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverMe&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.qrToken, qrToken) || other.qrToken == qrToken)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.subscriptionStatus, subscriptionStatus) || other.subscriptionStatus == subscriptionStatus)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.canGoOnline, canGoOnline) || other.canGoOnline == canGoOnline)&&(identical(other.blockReason, blockReason) || other.blockReason == blockReason)&&const DeepCollectionEquality().equals(other._documents, _documents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,qrToken,presence,subscriptionStatus,paidUntil,canGoOnline,blockReason,const DeepCollectionEquality().hash(_documents));

@override
String toString() {
  return 'DriverMe(driverId: $driverId, qrToken: $qrToken, presence: $presence, subscriptionStatus: $subscriptionStatus, paidUntil: $paidUntil, canGoOnline: $canGoOnline, blockReason: $blockReason, documents: $documents)';
}


}

/// @nodoc
abstract mixin class _$DriverMeCopyWith<$Res> implements $DriverMeCopyWith<$Res> {
  factory _$DriverMeCopyWith(_DriverMe value, $Res Function(_DriverMe) _then) = __$DriverMeCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String qrToken, DriverPresence presence, SubscriptionStatus subscriptionStatus, DateTime? paidUntil, bool canGoOnline, String? blockReason, List<DriverDocument> documents
});




}
/// @nodoc
class __$DriverMeCopyWithImpl<$Res>
    implements _$DriverMeCopyWith<$Res> {
  __$DriverMeCopyWithImpl(this._self, this._then);

  final _DriverMe _self;
  final $Res Function(_DriverMe) _then;

/// Create a copy of DriverMe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? qrToken = null,Object? presence = null,Object? subscriptionStatus = null,Object? paidUntil = freezed,Object? canGoOnline = null,Object? blockReason = freezed,Object? documents = null,}) {
  return _then(_DriverMe(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,qrToken: null == qrToken ? _self.qrToken : qrToken // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as DriverPresence,subscriptionStatus: null == subscriptionStatus ? _self.subscriptionStatus : subscriptionStatus // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,paidUntil: freezed == paidUntil ? _self.paidUntil : paidUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,canGoOnline: null == canGoOnline ? _self.canGoOnline : canGoOnline // ignore: cast_nullable_to_non_nullable
as bool,blockReason: freezed == blockReason ? _self.blockReason : blockReason // ignore: cast_nullable_to_non_nullable
as String?,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<DriverDocument>,
  ));
}


}


/// @nodoc
mixin _$AdminDriver {

 String get driverId; String get phoneE164; String get displayName; String get qrToken; String get vehiclePlate; String get vehicleDescription; DriverPresence get presence; DateTime? get paidUntil; SubscriptionStatus get subscriptionStatus; bool get canGoOnline; String? get blockReason; List<DriverDocument> get documents;
/// Create a copy of AdminDriver
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminDriverCopyWith<AdminDriver> get copyWith => _$AdminDriverCopyWithImpl<AdminDriver>(this as AdminDriver, _$identity);

  /// Serializes this AdminDriver to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.qrToken, qrToken) || other.qrToken == qrToken)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleDescription, vehicleDescription) || other.vehicleDescription == vehicleDescription)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.subscriptionStatus, subscriptionStatus) || other.subscriptionStatus == subscriptionStatus)&&(identical(other.canGoOnline, canGoOnline) || other.canGoOnline == canGoOnline)&&(identical(other.blockReason, blockReason) || other.blockReason == blockReason)&&const DeepCollectionEquality().equals(other.documents, documents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,phoneE164,displayName,qrToken,vehiclePlate,vehicleDescription,presence,paidUntil,subscriptionStatus,canGoOnline,blockReason,const DeepCollectionEquality().hash(documents));

@override
String toString() {
  return 'AdminDriver(driverId: $driverId, phoneE164: $phoneE164, displayName: $displayName, qrToken: $qrToken, vehiclePlate: $vehiclePlate, vehicleDescription: $vehicleDescription, presence: $presence, paidUntil: $paidUntil, subscriptionStatus: $subscriptionStatus, canGoOnline: $canGoOnline, blockReason: $blockReason, documents: $documents)';
}


}

/// @nodoc
abstract mixin class $AdminDriverCopyWith<$Res>  {
  factory $AdminDriverCopyWith(AdminDriver value, $Res Function(AdminDriver) _then) = _$AdminDriverCopyWithImpl;
@useResult
$Res call({
 String driverId, String phoneE164, String displayName, String qrToken, String vehiclePlate, String vehicleDescription, DriverPresence presence, DateTime? paidUntil, SubscriptionStatus subscriptionStatus, bool canGoOnline, String? blockReason, List<DriverDocument> documents
});




}
/// @nodoc
class _$AdminDriverCopyWithImpl<$Res>
    implements $AdminDriverCopyWith<$Res> {
  _$AdminDriverCopyWithImpl(this._self, this._then);

  final AdminDriver _self;
  final $Res Function(AdminDriver) _then;

/// Create a copy of AdminDriver
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? phoneE164 = null,Object? displayName = null,Object? qrToken = null,Object? vehiclePlate = null,Object? vehicleDescription = null,Object? presence = null,Object? paidUntil = freezed,Object? subscriptionStatus = null,Object? canGoOnline = null,Object? blockReason = freezed,Object? documents = null,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,phoneE164: null == phoneE164 ? _self.phoneE164 : phoneE164 // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,qrToken: null == qrToken ? _self.qrToken : qrToken // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,vehicleDescription: null == vehicleDescription ? _self.vehicleDescription : vehicleDescription // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as DriverPresence,paidUntil: freezed == paidUntil ? _self.paidUntil : paidUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,subscriptionStatus: null == subscriptionStatus ? _self.subscriptionStatus : subscriptionStatus // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,canGoOnline: null == canGoOnline ? _self.canGoOnline : canGoOnline // ignore: cast_nullable_to_non_nullable
as bool,blockReason: freezed == blockReason ? _self.blockReason : blockReason // ignore: cast_nullable_to_non_nullable
as String?,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<DriverDocument>,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminDriver].
extension AdminDriverPatterns on AdminDriver {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminDriver value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminDriver() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminDriver value)  $default,){
final _that = this;
switch (_that) {
case _AdminDriver():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminDriver value)?  $default,){
final _that = this;
switch (_that) {
case _AdminDriver() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String phoneE164,  String displayName,  String qrToken,  String vehiclePlate,  String vehicleDescription,  DriverPresence presence,  DateTime? paidUntil,  SubscriptionStatus subscriptionStatus,  bool canGoOnline,  String? blockReason,  List<DriverDocument> documents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminDriver() when $default != null:
return $default(_that.driverId,_that.phoneE164,_that.displayName,_that.qrToken,_that.vehiclePlate,_that.vehicleDescription,_that.presence,_that.paidUntil,_that.subscriptionStatus,_that.canGoOnline,_that.blockReason,_that.documents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String phoneE164,  String displayName,  String qrToken,  String vehiclePlate,  String vehicleDescription,  DriverPresence presence,  DateTime? paidUntil,  SubscriptionStatus subscriptionStatus,  bool canGoOnline,  String? blockReason,  List<DriverDocument> documents)  $default,) {final _that = this;
switch (_that) {
case _AdminDriver():
return $default(_that.driverId,_that.phoneE164,_that.displayName,_that.qrToken,_that.vehiclePlate,_that.vehicleDescription,_that.presence,_that.paidUntil,_that.subscriptionStatus,_that.canGoOnline,_that.blockReason,_that.documents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String phoneE164,  String displayName,  String qrToken,  String vehiclePlate,  String vehicleDescription,  DriverPresence presence,  DateTime? paidUntil,  SubscriptionStatus subscriptionStatus,  bool canGoOnline,  String? blockReason,  List<DriverDocument> documents)?  $default,) {final _that = this;
switch (_that) {
case _AdminDriver() when $default != null:
return $default(_that.driverId,_that.phoneE164,_that.displayName,_that.qrToken,_that.vehiclePlate,_that.vehicleDescription,_that.presence,_that.paidUntil,_that.subscriptionStatus,_that.canGoOnline,_that.blockReason,_that.documents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminDriver implements AdminDriver {
  const _AdminDriver({required this.driverId, required this.phoneE164, required this.displayName, required this.qrToken, required this.vehiclePlate, required this.vehicleDescription, required this.presence, this.paidUntil, required this.subscriptionStatus, required this.canGoOnline, this.blockReason, final  List<DriverDocument> documents = const <DriverDocument>[]}): _documents = documents;
  factory _AdminDriver.fromJson(Map<String, dynamic> json) => _$AdminDriverFromJson(json);

@override final  String driverId;
@override final  String phoneE164;
@override final  String displayName;
@override final  String qrToken;
@override final  String vehiclePlate;
@override final  String vehicleDescription;
@override final  DriverPresence presence;
@override final  DateTime? paidUntil;
@override final  SubscriptionStatus subscriptionStatus;
@override final  bool canGoOnline;
@override final  String? blockReason;
 final  List<DriverDocument> _documents;
@override@JsonKey() List<DriverDocument> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}


/// Create a copy of AdminDriver
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminDriverCopyWith<_AdminDriver> get copyWith => __$AdminDriverCopyWithImpl<_AdminDriver>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminDriverToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.qrToken, qrToken) || other.qrToken == qrToken)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleDescription, vehicleDescription) || other.vehicleDescription == vehicleDescription)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.subscriptionStatus, subscriptionStatus) || other.subscriptionStatus == subscriptionStatus)&&(identical(other.canGoOnline, canGoOnline) || other.canGoOnline == canGoOnline)&&(identical(other.blockReason, blockReason) || other.blockReason == blockReason)&&const DeepCollectionEquality().equals(other._documents, _documents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,phoneE164,displayName,qrToken,vehiclePlate,vehicleDescription,presence,paidUntil,subscriptionStatus,canGoOnline,blockReason,const DeepCollectionEquality().hash(_documents));

@override
String toString() {
  return 'AdminDriver(driverId: $driverId, phoneE164: $phoneE164, displayName: $displayName, qrToken: $qrToken, vehiclePlate: $vehiclePlate, vehicleDescription: $vehicleDescription, presence: $presence, paidUntil: $paidUntil, subscriptionStatus: $subscriptionStatus, canGoOnline: $canGoOnline, blockReason: $blockReason, documents: $documents)';
}


}

/// @nodoc
abstract mixin class _$AdminDriverCopyWith<$Res> implements $AdminDriverCopyWith<$Res> {
  factory _$AdminDriverCopyWith(_AdminDriver value, $Res Function(_AdminDriver) _then) = __$AdminDriverCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String phoneE164, String displayName, String qrToken, String vehiclePlate, String vehicleDescription, DriverPresence presence, DateTime? paidUntil, SubscriptionStatus subscriptionStatus, bool canGoOnline, String? blockReason, List<DriverDocument> documents
});




}
/// @nodoc
class __$AdminDriverCopyWithImpl<$Res>
    implements _$AdminDriverCopyWith<$Res> {
  __$AdminDriverCopyWithImpl(this._self, this._then);

  final _AdminDriver _self;
  final $Res Function(_AdminDriver) _then;

/// Create a copy of AdminDriver
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? phoneE164 = null,Object? displayName = null,Object? qrToken = null,Object? vehiclePlate = null,Object? vehicleDescription = null,Object? presence = null,Object? paidUntil = freezed,Object? subscriptionStatus = null,Object? canGoOnline = null,Object? blockReason = freezed,Object? documents = null,}) {
  return _then(_AdminDriver(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,phoneE164: null == phoneE164 ? _self.phoneE164 : phoneE164 // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,qrToken: null == qrToken ? _self.qrToken : qrToken // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: null == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String,vehicleDescription: null == vehicleDescription ? _self.vehicleDescription : vehicleDescription // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as DriverPresence,paidUntil: freezed == paidUntil ? _self.paidUntil : paidUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,subscriptionStatus: null == subscriptionStatus ? _self.subscriptionStatus : subscriptionStatus // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,canGoOnline: null == canGoOnline ? _self.canGoOnline : canGoOnline // ignore: cast_nullable_to_non_nullable
as bool,blockReason: freezed == blockReason ? _self.blockReason : blockReason // ignore: cast_nullable_to_non_nullable
as String?,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<DriverDocument>,
  ));
}


}


/// @nodoc
mixin _$ChosenDriver {

 String get driverId; String get displayName; String get vehicleDescription; DriverPresence get presence; DateTime? get busyUntilEstimate;
/// Create a copy of ChosenDriver
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChosenDriverCopyWith<ChosenDriver> get copyWith => _$ChosenDriverCopyWithImpl<ChosenDriver>(this as ChosenDriver, _$identity);

  /// Serializes this ChosenDriver to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChosenDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.vehicleDescription, vehicleDescription) || other.vehicleDescription == vehicleDescription)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.busyUntilEstimate, busyUntilEstimate) || other.busyUntilEstimate == busyUntilEstimate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,vehicleDescription,presence,busyUntilEstimate);

@override
String toString() {
  return 'ChosenDriver(driverId: $driverId, displayName: $displayName, vehicleDescription: $vehicleDescription, presence: $presence, busyUntilEstimate: $busyUntilEstimate)';
}


}

/// @nodoc
abstract mixin class $ChosenDriverCopyWith<$Res>  {
  factory $ChosenDriverCopyWith(ChosenDriver value, $Res Function(ChosenDriver) _then) = _$ChosenDriverCopyWithImpl;
@useResult
$Res call({
 String driverId, String displayName, String vehicleDescription, DriverPresence presence, DateTime? busyUntilEstimate
});




}
/// @nodoc
class _$ChosenDriverCopyWithImpl<$Res>
    implements $ChosenDriverCopyWith<$Res> {
  _$ChosenDriverCopyWithImpl(this._self, this._then);

  final ChosenDriver _self;
  final $Res Function(ChosenDriver) _then;

/// Create a copy of ChosenDriver
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? displayName = null,Object? vehicleDescription = null,Object? presence = null,Object? busyUntilEstimate = freezed,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,vehicleDescription: null == vehicleDescription ? _self.vehicleDescription : vehicleDescription // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as DriverPresence,busyUntilEstimate: freezed == busyUntilEstimate ? _self.busyUntilEstimate : busyUntilEstimate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChosenDriver].
extension ChosenDriverPatterns on ChosenDriver {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChosenDriver value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChosenDriver() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChosenDriver value)  $default,){
final _that = this;
switch (_that) {
case _ChosenDriver():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChosenDriver value)?  $default,){
final _that = this;
switch (_that) {
case _ChosenDriver() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String displayName,  String vehicleDescription,  DriverPresence presence,  DateTime? busyUntilEstimate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChosenDriver() when $default != null:
return $default(_that.driverId,_that.displayName,_that.vehicleDescription,_that.presence,_that.busyUntilEstimate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String displayName,  String vehicleDescription,  DriverPresence presence,  DateTime? busyUntilEstimate)  $default,) {final _that = this;
switch (_that) {
case _ChosenDriver():
return $default(_that.driverId,_that.displayName,_that.vehicleDescription,_that.presence,_that.busyUntilEstimate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String displayName,  String vehicleDescription,  DriverPresence presence,  DateTime? busyUntilEstimate)?  $default,) {final _that = this;
switch (_that) {
case _ChosenDriver() when $default != null:
return $default(_that.driverId,_that.displayName,_that.vehicleDescription,_that.presence,_that.busyUntilEstimate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChosenDriver implements ChosenDriver {
  const _ChosenDriver({required this.driverId, required this.displayName, required this.vehicleDescription, required this.presence, this.busyUntilEstimate});
  factory _ChosenDriver.fromJson(Map<String, dynamic> json) => _$ChosenDriverFromJson(json);

@override final  String driverId;
@override final  String displayName;
@override final  String vehicleDescription;
@override final  DriverPresence presence;
@override final  DateTime? busyUntilEstimate;

/// Create a copy of ChosenDriver
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChosenDriverCopyWith<_ChosenDriver> get copyWith => __$ChosenDriverCopyWithImpl<_ChosenDriver>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChosenDriverToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChosenDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.vehicleDescription, vehicleDescription) || other.vehicleDescription == vehicleDescription)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.busyUntilEstimate, busyUntilEstimate) || other.busyUntilEstimate == busyUntilEstimate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,vehicleDescription,presence,busyUntilEstimate);

@override
String toString() {
  return 'ChosenDriver(driverId: $driverId, displayName: $displayName, vehicleDescription: $vehicleDescription, presence: $presence, busyUntilEstimate: $busyUntilEstimate)';
}


}

/// @nodoc
abstract mixin class _$ChosenDriverCopyWith<$Res> implements $ChosenDriverCopyWith<$Res> {
  factory _$ChosenDriverCopyWith(_ChosenDriver value, $Res Function(_ChosenDriver) _then) = __$ChosenDriverCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String displayName, String vehicleDescription, DriverPresence presence, DateTime? busyUntilEstimate
});




}
/// @nodoc
class __$ChosenDriverCopyWithImpl<$Res>
    implements _$ChosenDriverCopyWith<$Res> {
  __$ChosenDriverCopyWithImpl(this._self, this._then);

  final _ChosenDriver _self;
  final $Res Function(_ChosenDriver) _then;

/// Create a copy of ChosenDriver
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? displayName = null,Object? vehicleDescription = null,Object? presence = null,Object? busyUntilEstimate = freezed,}) {
  return _then(_ChosenDriver(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,vehicleDescription: null == vehicleDescription ? _self.vehicleDescription : vehicleDescription // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as DriverPresence,busyUntilEstimate: freezed == busyUntilEstimate ? _self.busyUntilEstimate : busyUntilEstimate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$FareQuote {

 int get distanceM; int get durationS; int get suggestedFareMinor; String get currency;
/// Create a copy of FareQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FareQuoteCopyWith<FareQuote> get copyWith => _$FareQuoteCopyWithImpl<FareQuote>(this as FareQuote, _$identity);

  /// Serializes this FareQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FareQuote&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.suggestedFareMinor, suggestedFareMinor) || other.suggestedFareMinor == suggestedFareMinor)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,distanceM,durationS,suggestedFareMinor,currency);

@override
String toString() {
  return 'FareQuote(distanceM: $distanceM, durationS: $durationS, suggestedFareMinor: $suggestedFareMinor, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $FareQuoteCopyWith<$Res>  {
  factory $FareQuoteCopyWith(FareQuote value, $Res Function(FareQuote) _then) = _$FareQuoteCopyWithImpl;
@useResult
$Res call({
 int distanceM, int durationS, int suggestedFareMinor, String currency
});




}
/// @nodoc
class _$FareQuoteCopyWithImpl<$Res>
    implements $FareQuoteCopyWith<$Res> {
  _$FareQuoteCopyWithImpl(this._self, this._then);

  final FareQuote _self;
  final $Res Function(FareQuote) _then;

/// Create a copy of FareQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? distanceM = null,Object? durationS = null,Object? suggestedFareMinor = null,Object? currency = null,}) {
  return _then(_self.copyWith(
distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int,durationS: null == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as int,suggestedFareMinor: null == suggestedFareMinor ? _self.suggestedFareMinor : suggestedFareMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FareQuote].
extension FareQuotePatterns on FareQuote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FareQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FareQuote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FareQuote value)  $default,){
final _that = this;
switch (_that) {
case _FareQuote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FareQuote value)?  $default,){
final _that = this;
switch (_that) {
case _FareQuote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int distanceM,  int durationS,  int suggestedFareMinor,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FareQuote() when $default != null:
return $default(_that.distanceM,_that.durationS,_that.suggestedFareMinor,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int distanceM,  int durationS,  int suggestedFareMinor,  String currency)  $default,) {final _that = this;
switch (_that) {
case _FareQuote():
return $default(_that.distanceM,_that.durationS,_that.suggestedFareMinor,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int distanceM,  int durationS,  int suggestedFareMinor,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _FareQuote() when $default != null:
return $default(_that.distanceM,_that.durationS,_that.suggestedFareMinor,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FareQuote implements FareQuote {
  const _FareQuote({required this.distanceM, required this.durationS, required this.suggestedFareMinor, required this.currency});
  factory _FareQuote.fromJson(Map<String, dynamic> json) => _$FareQuoteFromJson(json);

@override final  int distanceM;
@override final  int durationS;
@override final  int suggestedFareMinor;
@override final  String currency;

/// Create a copy of FareQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FareQuoteCopyWith<_FareQuote> get copyWith => __$FareQuoteCopyWithImpl<_FareQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FareQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FareQuote&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.suggestedFareMinor, suggestedFareMinor) || other.suggestedFareMinor == suggestedFareMinor)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,distanceM,durationS,suggestedFareMinor,currency);

@override
String toString() {
  return 'FareQuote(distanceM: $distanceM, durationS: $durationS, suggestedFareMinor: $suggestedFareMinor, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$FareQuoteCopyWith<$Res> implements $FareQuoteCopyWith<$Res> {
  factory _$FareQuoteCopyWith(_FareQuote value, $Res Function(_FareQuote) _then) = __$FareQuoteCopyWithImpl;
@override @useResult
$Res call({
 int distanceM, int durationS, int suggestedFareMinor, String currency
});




}
/// @nodoc
class __$FareQuoteCopyWithImpl<$Res>
    implements _$FareQuoteCopyWith<$Res> {
  __$FareQuoteCopyWithImpl(this._self, this._then);

  final _FareQuote _self;
  final $Res Function(_FareQuote) _then;

/// Create a copy of FareQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? distanceM = null,Object? durationS = null,Object? suggestedFareMinor = null,Object? currency = null,}) {
  return _then(_FareQuote(
distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int,durationS: null == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as int,suggestedFareMinor: null == suggestedFareMinor ? _self.suggestedFareMinor : suggestedFareMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FareProposal {

 String get id; ProposalParty get proposedBy; int get amountMinor; ProposalStatus get status; DateTime get expiresAt;
/// Create a copy of FareProposal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FareProposalCopyWith<FareProposal> get copyWith => _$FareProposalCopyWithImpl<FareProposal>(this as FareProposal, _$identity);

  /// Serializes this FareProposal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FareProposal&&(identical(other.id, id) || other.id == id)&&(identical(other.proposedBy, proposedBy) || other.proposedBy == proposedBy)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,proposedBy,amountMinor,status,expiresAt);

@override
String toString() {
  return 'FareProposal(id: $id, proposedBy: $proposedBy, amountMinor: $amountMinor, status: $status, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $FareProposalCopyWith<$Res>  {
  factory $FareProposalCopyWith(FareProposal value, $Res Function(FareProposal) _then) = _$FareProposalCopyWithImpl;
@useResult
$Res call({
 String id, ProposalParty proposedBy, int amountMinor, ProposalStatus status, DateTime expiresAt
});




}
/// @nodoc
class _$FareProposalCopyWithImpl<$Res>
    implements $FareProposalCopyWith<$Res> {
  _$FareProposalCopyWithImpl(this._self, this._then);

  final FareProposal _self;
  final $Res Function(FareProposal) _then;

/// Create a copy of FareProposal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? proposedBy = null,Object? amountMinor = null,Object? status = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,proposedBy: null == proposedBy ? _self.proposedBy : proposedBy // ignore: cast_nullable_to_non_nullable
as ProposalParty,amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProposalStatus,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FareProposal].
extension FareProposalPatterns on FareProposal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FareProposal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FareProposal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FareProposal value)  $default,){
final _that = this;
switch (_that) {
case _FareProposal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FareProposal value)?  $default,){
final _that = this;
switch (_that) {
case _FareProposal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ProposalParty proposedBy,  int amountMinor,  ProposalStatus status,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FareProposal() when $default != null:
return $default(_that.id,_that.proposedBy,_that.amountMinor,_that.status,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ProposalParty proposedBy,  int amountMinor,  ProposalStatus status,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _FareProposal():
return $default(_that.id,_that.proposedBy,_that.amountMinor,_that.status,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ProposalParty proposedBy,  int amountMinor,  ProposalStatus status,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _FareProposal() when $default != null:
return $default(_that.id,_that.proposedBy,_that.amountMinor,_that.status,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FareProposal implements FareProposal {
  const _FareProposal({required this.id, required this.proposedBy, required this.amountMinor, required this.status, required this.expiresAt});
  factory _FareProposal.fromJson(Map<String, dynamic> json) => _$FareProposalFromJson(json);

@override final  String id;
@override final  ProposalParty proposedBy;
@override final  int amountMinor;
@override final  ProposalStatus status;
@override final  DateTime expiresAt;

/// Create a copy of FareProposal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FareProposalCopyWith<_FareProposal> get copyWith => __$FareProposalCopyWithImpl<_FareProposal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FareProposalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FareProposal&&(identical(other.id, id) || other.id == id)&&(identical(other.proposedBy, proposedBy) || other.proposedBy == proposedBy)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,proposedBy,amountMinor,status,expiresAt);

@override
String toString() {
  return 'FareProposal(id: $id, proposedBy: $proposedBy, amountMinor: $amountMinor, status: $status, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$FareProposalCopyWith<$Res> implements $FareProposalCopyWith<$Res> {
  factory _$FareProposalCopyWith(_FareProposal value, $Res Function(_FareProposal) _then) = __$FareProposalCopyWithImpl;
@override @useResult
$Res call({
 String id, ProposalParty proposedBy, int amountMinor, ProposalStatus status, DateTime expiresAt
});




}
/// @nodoc
class __$FareProposalCopyWithImpl<$Res>
    implements _$FareProposalCopyWith<$Res> {
  __$FareProposalCopyWithImpl(this._self, this._then);

  final _FareProposal _self;
  final $Res Function(_FareProposal) _then;

/// Create a copy of FareProposal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? proposedBy = null,Object? amountMinor = null,Object? status = null,Object? expiresAt = null,}) {
  return _then(_FareProposal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,proposedBy: null == proposedBy ? _self.proposedBy : proposedBy // ignore: cast_nullable_to_non_nullable
as ProposalParty,amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProposalStatus,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$Trip {

 String get id; TripStatus get status; String get passengerId; String get driverId; GeoPoint get pickup; GeoPoint get dropoff; int get distanceM; int get durationS; String get currency; int get suggestedFareMinor; int? get agreedFareMinor; int? get driverPayoutMinor; int get platformCommissionMinor; FareProposal? get openProposal; DateTime? get offerExpiresAt; DateTime? get negotiationExpiresAt; String? get cancelReason;
/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripCopyWith<Trip> get copyWith => _$TripCopyWithImpl<Trip>(this as Trip, _$identity);

  /// Serializes this Trip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.suggestedFareMinor, suggestedFareMinor) || other.suggestedFareMinor == suggestedFareMinor)&&(identical(other.agreedFareMinor, agreedFareMinor) || other.agreedFareMinor == agreedFareMinor)&&(identical(other.driverPayoutMinor, driverPayoutMinor) || other.driverPayoutMinor == driverPayoutMinor)&&(identical(other.platformCommissionMinor, platformCommissionMinor) || other.platformCommissionMinor == platformCommissionMinor)&&(identical(other.openProposal, openProposal) || other.openProposal == openProposal)&&(identical(other.offerExpiresAt, offerExpiresAt) || other.offerExpiresAt == offerExpiresAt)&&(identical(other.negotiationExpiresAt, negotiationExpiresAt) || other.negotiationExpiresAt == negotiationExpiresAt)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,passengerId,driverId,pickup,dropoff,distanceM,durationS,currency,suggestedFareMinor,agreedFareMinor,driverPayoutMinor,platformCommissionMinor,openProposal,offerExpiresAt,negotiationExpiresAt,cancelReason);

@override
String toString() {
  return 'Trip(id: $id, status: $status, passengerId: $passengerId, driverId: $driverId, pickup: $pickup, dropoff: $dropoff, distanceM: $distanceM, durationS: $durationS, currency: $currency, suggestedFareMinor: $suggestedFareMinor, agreedFareMinor: $agreedFareMinor, driverPayoutMinor: $driverPayoutMinor, platformCommissionMinor: $platformCommissionMinor, openProposal: $openProposal, offerExpiresAt: $offerExpiresAt, negotiationExpiresAt: $negotiationExpiresAt, cancelReason: $cancelReason)';
}


}

/// @nodoc
abstract mixin class $TripCopyWith<$Res>  {
  factory $TripCopyWith(Trip value, $Res Function(Trip) _then) = _$TripCopyWithImpl;
@useResult
$Res call({
 String id, TripStatus status, String passengerId, String driverId, GeoPoint pickup, GeoPoint dropoff, int distanceM, int durationS, String currency, int suggestedFareMinor, int? agreedFareMinor, int? driverPayoutMinor, int platformCommissionMinor, FareProposal? openProposal, DateTime? offerExpiresAt, DateTime? negotiationExpiresAt, String? cancelReason
});


$GeoPointCopyWith<$Res> get pickup;$GeoPointCopyWith<$Res> get dropoff;$FareProposalCopyWith<$Res>? get openProposal;

}
/// @nodoc
class _$TripCopyWithImpl<$Res>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._self, this._then);

  final Trip _self;
  final $Res Function(Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? passengerId = null,Object? driverId = null,Object? pickup = null,Object? dropoff = null,Object? distanceM = null,Object? durationS = null,Object? currency = null,Object? suggestedFareMinor = null,Object? agreedFareMinor = freezed,Object? driverPayoutMinor = freezed,Object? platformCommissionMinor = null,Object? openProposal = freezed,Object? offerExpiresAt = freezed,Object? negotiationExpiresAt = freezed,Object? cancelReason = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus,passengerId: null == passengerId ? _self.passengerId : passengerId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as GeoPoint,distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int,durationS: null == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,suggestedFareMinor: null == suggestedFareMinor ? _self.suggestedFareMinor : suggestedFareMinor // ignore: cast_nullable_to_non_nullable
as int,agreedFareMinor: freezed == agreedFareMinor ? _self.agreedFareMinor : agreedFareMinor // ignore: cast_nullable_to_non_nullable
as int?,driverPayoutMinor: freezed == driverPayoutMinor ? _self.driverPayoutMinor : driverPayoutMinor // ignore: cast_nullable_to_non_nullable
as int?,platformCommissionMinor: null == platformCommissionMinor ? _self.platformCommissionMinor : platformCommissionMinor // ignore: cast_nullable_to_non_nullable
as int,openProposal: freezed == openProposal ? _self.openProposal : openProposal // ignore: cast_nullable_to_non_nullable
as FareProposal?,offerExpiresAt: freezed == offerExpiresAt ? _self.offerExpiresAt : offerExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,negotiationExpiresAt: freezed == negotiationExpiresAt ? _self.negotiationExpiresAt : negotiationExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get pickup {
  
  return $GeoPointCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get dropoff {
  
  return $GeoPointCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FareProposalCopyWith<$Res>? get openProposal {
    if (_self.openProposal == null) {
    return null;
  }

  return $FareProposalCopyWith<$Res>(_self.openProposal!, (value) {
    return _then(_self.copyWith(openProposal: value));
  });
}
}


/// Adds pattern-matching-related methods to [Trip].
extension TripPatterns on Trip {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Trip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Trip value)  $default,){
final _that = this;
switch (_that) {
case _Trip():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Trip value)?  $default,){
final _that = this;
switch (_that) {
case _Trip() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  TripStatus status,  String passengerId,  String driverId,  GeoPoint pickup,  GeoPoint dropoff,  int distanceM,  int durationS,  String currency,  int suggestedFareMinor,  int? agreedFareMinor,  int? driverPayoutMinor,  int platformCommissionMinor,  FareProposal? openProposal,  DateTime? offerExpiresAt,  DateTime? negotiationExpiresAt,  String? cancelReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.status,_that.passengerId,_that.driverId,_that.pickup,_that.dropoff,_that.distanceM,_that.durationS,_that.currency,_that.suggestedFareMinor,_that.agreedFareMinor,_that.driverPayoutMinor,_that.platformCommissionMinor,_that.openProposal,_that.offerExpiresAt,_that.negotiationExpiresAt,_that.cancelReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  TripStatus status,  String passengerId,  String driverId,  GeoPoint pickup,  GeoPoint dropoff,  int distanceM,  int durationS,  String currency,  int suggestedFareMinor,  int? agreedFareMinor,  int? driverPayoutMinor,  int platformCommissionMinor,  FareProposal? openProposal,  DateTime? offerExpiresAt,  DateTime? negotiationExpiresAt,  String? cancelReason)  $default,) {final _that = this;
switch (_that) {
case _Trip():
return $default(_that.id,_that.status,_that.passengerId,_that.driverId,_that.pickup,_that.dropoff,_that.distanceM,_that.durationS,_that.currency,_that.suggestedFareMinor,_that.agreedFareMinor,_that.driverPayoutMinor,_that.platformCommissionMinor,_that.openProposal,_that.offerExpiresAt,_that.negotiationExpiresAt,_that.cancelReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  TripStatus status,  String passengerId,  String driverId,  GeoPoint pickup,  GeoPoint dropoff,  int distanceM,  int durationS,  String currency,  int suggestedFareMinor,  int? agreedFareMinor,  int? driverPayoutMinor,  int platformCommissionMinor,  FareProposal? openProposal,  DateTime? offerExpiresAt,  DateTime? negotiationExpiresAt,  String? cancelReason)?  $default,) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.status,_that.passengerId,_that.driverId,_that.pickup,_that.dropoff,_that.distanceM,_that.durationS,_that.currency,_that.suggestedFareMinor,_that.agreedFareMinor,_that.driverPayoutMinor,_that.platformCommissionMinor,_that.openProposal,_that.offerExpiresAt,_that.negotiationExpiresAt,_that.cancelReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Trip implements Trip {
  const _Trip({required this.id, required this.status, required this.passengerId, required this.driverId, required this.pickup, required this.dropoff, required this.distanceM, required this.durationS, required this.currency, required this.suggestedFareMinor, this.agreedFareMinor, this.driverPayoutMinor, this.platformCommissionMinor = 0, this.openProposal, this.offerExpiresAt, this.negotiationExpiresAt, this.cancelReason});
  factory _Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

@override final  String id;
@override final  TripStatus status;
@override final  String passengerId;
@override final  String driverId;
@override final  GeoPoint pickup;
@override final  GeoPoint dropoff;
@override final  int distanceM;
@override final  int durationS;
@override final  String currency;
@override final  int suggestedFareMinor;
@override final  int? agreedFareMinor;
@override final  int? driverPayoutMinor;
@override@JsonKey() final  int platformCommissionMinor;
@override final  FareProposal? openProposal;
@override final  DateTime? offerExpiresAt;
@override final  DateTime? negotiationExpiresAt;
@override final  String? cancelReason;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripCopyWith<_Trip> get copyWith => __$TripCopyWithImpl<_Trip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TripToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.suggestedFareMinor, suggestedFareMinor) || other.suggestedFareMinor == suggestedFareMinor)&&(identical(other.agreedFareMinor, agreedFareMinor) || other.agreedFareMinor == agreedFareMinor)&&(identical(other.driverPayoutMinor, driverPayoutMinor) || other.driverPayoutMinor == driverPayoutMinor)&&(identical(other.platformCommissionMinor, platformCommissionMinor) || other.platformCommissionMinor == platformCommissionMinor)&&(identical(other.openProposal, openProposal) || other.openProposal == openProposal)&&(identical(other.offerExpiresAt, offerExpiresAt) || other.offerExpiresAt == offerExpiresAt)&&(identical(other.negotiationExpiresAt, negotiationExpiresAt) || other.negotiationExpiresAt == negotiationExpiresAt)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,passengerId,driverId,pickup,dropoff,distanceM,durationS,currency,suggestedFareMinor,agreedFareMinor,driverPayoutMinor,platformCommissionMinor,openProposal,offerExpiresAt,negotiationExpiresAt,cancelReason);

@override
String toString() {
  return 'Trip(id: $id, status: $status, passengerId: $passengerId, driverId: $driverId, pickup: $pickup, dropoff: $dropoff, distanceM: $distanceM, durationS: $durationS, currency: $currency, suggestedFareMinor: $suggestedFareMinor, agreedFareMinor: $agreedFareMinor, driverPayoutMinor: $driverPayoutMinor, platformCommissionMinor: $platformCommissionMinor, openProposal: $openProposal, offerExpiresAt: $offerExpiresAt, negotiationExpiresAt: $negotiationExpiresAt, cancelReason: $cancelReason)';
}


}

/// @nodoc
abstract mixin class _$TripCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$TripCopyWith(_Trip value, $Res Function(_Trip) _then) = __$TripCopyWithImpl;
@override @useResult
$Res call({
 String id, TripStatus status, String passengerId, String driverId, GeoPoint pickup, GeoPoint dropoff, int distanceM, int durationS, String currency, int suggestedFareMinor, int? agreedFareMinor, int? driverPayoutMinor, int platformCommissionMinor, FareProposal? openProposal, DateTime? offerExpiresAt, DateTime? negotiationExpiresAt, String? cancelReason
});


@override $GeoPointCopyWith<$Res> get pickup;@override $GeoPointCopyWith<$Res> get dropoff;@override $FareProposalCopyWith<$Res>? get openProposal;

}
/// @nodoc
class __$TripCopyWithImpl<$Res>
    implements _$TripCopyWith<$Res> {
  __$TripCopyWithImpl(this._self, this._then);

  final _Trip _self;
  final $Res Function(_Trip) _then;

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? passengerId = null,Object? driverId = null,Object? pickup = null,Object? dropoff = null,Object? distanceM = null,Object? durationS = null,Object? currency = null,Object? suggestedFareMinor = null,Object? agreedFareMinor = freezed,Object? driverPayoutMinor = freezed,Object? platformCommissionMinor = null,Object? openProposal = freezed,Object? offerExpiresAt = freezed,Object? negotiationExpiresAt = freezed,Object? cancelReason = freezed,}) {
  return _then(_Trip(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TripStatus,passengerId: null == passengerId ? _self.passengerId : passengerId // ignore: cast_nullable_to_non_nullable
as String,driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,pickup: null == pickup ? _self.pickup : pickup // ignore: cast_nullable_to_non_nullable
as GeoPoint,dropoff: null == dropoff ? _self.dropoff : dropoff // ignore: cast_nullable_to_non_nullable
as GeoPoint,distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int,durationS: null == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,suggestedFareMinor: null == suggestedFareMinor ? _self.suggestedFareMinor : suggestedFareMinor // ignore: cast_nullable_to_non_nullable
as int,agreedFareMinor: freezed == agreedFareMinor ? _self.agreedFareMinor : agreedFareMinor // ignore: cast_nullable_to_non_nullable
as int?,driverPayoutMinor: freezed == driverPayoutMinor ? _self.driverPayoutMinor : driverPayoutMinor // ignore: cast_nullable_to_non_nullable
as int?,platformCommissionMinor: null == platformCommissionMinor ? _self.platformCommissionMinor : platformCommissionMinor // ignore: cast_nullable_to_non_nullable
as int,openProposal: freezed == openProposal ? _self.openProposal : openProposal // ignore: cast_nullable_to_non_nullable
as FareProposal?,offerExpiresAt: freezed == offerExpiresAt ? _self.offerExpiresAt : offerExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,negotiationExpiresAt: freezed == negotiationExpiresAt ? _self.negotiationExpiresAt : negotiationExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get pickup {
  
  return $GeoPointCopyWith<$Res>(_self.pickup, (value) {
    return _then(_self.copyWith(pickup: value));
  });
}/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeoPointCopyWith<$Res> get dropoff {
  
  return $GeoPointCopyWith<$Res>(_self.dropoff, (value) {
    return _then(_self.copyWith(dropoff: value));
  });
}/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FareProposalCopyWith<$Res>? get openProposal {
    if (_self.openProposal == null) {
    return null;
  }

  return $FareProposalCopyWith<$Res>(_self.openProposal!, (value) {
    return _then(_self.copyWith(openProposal: value));
  });
}
}

// dart format on
