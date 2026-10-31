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

 String get accessToken; String get refreshToken; UserRole get role;/// 009: `support` en la sesión de un usuario suspendido: solo abre soporte.
 String? get scope;/// 011: conversaciones de Radio a las que llevaron invitaciones enviadas a este teléfono.
 List<String> get radioInvitesApplied;
/// Create a copy of Tokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokensCopyWith<Tokens> get copyWith => _$TokensCopyWithImpl<Tokens>(this as Tokens, _$identity);

  /// Serializes this Tokens to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tokens&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.role, role) || other.role == role)&&(identical(other.scope, scope) || other.scope == scope)&&const DeepCollectionEquality().equals(other.radioInvitesApplied, radioInvitesApplied));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,role,scope,const DeepCollectionEquality().hash(radioInvitesApplied));

@override
String toString() {
  return 'Tokens(accessToken: $accessToken, refreshToken: $refreshToken, role: $role, scope: $scope, radioInvitesApplied: $radioInvitesApplied)';
}


}

/// @nodoc
abstract mixin class $TokensCopyWith<$Res>  {
  factory $TokensCopyWith(Tokens value, $Res Function(Tokens) _then) = _$TokensCopyWithImpl;
@useResult
$Res call({
 String accessToken, String refreshToken, UserRole role, String? scope, List<String> radioInvitesApplied
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
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = null,Object? role = null,Object? scope = freezed,Object? radioInvitesApplied = null,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String?,radioInvitesApplied: null == radioInvitesApplied ? _self.radioInvitesApplied : radioInvitesApplied // ignore: cast_nullable_to_non_nullable
as List<String>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  UserRole role,  String? scope,  List<String> radioInvitesApplied)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tokens() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.role,_that.scope,_that.radioInvitesApplied);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String refreshToken,  UserRole role,  String? scope,  List<String> radioInvitesApplied)  $default,) {final _that = this;
switch (_that) {
case _Tokens():
return $default(_that.accessToken,_that.refreshToken,_that.role,_that.scope,_that.radioInvitesApplied);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String refreshToken,  UserRole role,  String? scope,  List<String> radioInvitesApplied)?  $default,) {final _that = this;
switch (_that) {
case _Tokens() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.role,_that.scope,_that.radioInvitesApplied);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Tokens implements Tokens {
  const _Tokens({required this.accessToken, required this.refreshToken, required this.role, this.scope, final  List<String> radioInvitesApplied = const []}): _radioInvitesApplied = radioInvitesApplied;
  factory _Tokens.fromJson(Map<String, dynamic> json) => _$TokensFromJson(json);

@override final  String accessToken;
@override final  String refreshToken;
@override final  UserRole role;
/// 009: `support` en la sesión de un usuario suspendido: solo abre soporte.
@override final  String? scope;
/// 011: conversaciones de Radio a las que llevaron invitaciones enviadas a este teléfono.
 final  List<String> _radioInvitesApplied;
/// 011: conversaciones de Radio a las que llevaron invitaciones enviadas a este teléfono.
@override@JsonKey() List<String> get radioInvitesApplied {
  if (_radioInvitesApplied is EqualUnmodifiableListView) return _radioInvitesApplied;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_radioInvitesApplied);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tokens&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.role, role) || other.role == role)&&(identical(other.scope, scope) || other.scope == scope)&&const DeepCollectionEquality().equals(other._radioInvitesApplied, _radioInvitesApplied));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,role,scope,const DeepCollectionEquality().hash(_radioInvitesApplied));

@override
String toString() {
  return 'Tokens(accessToken: $accessToken, refreshToken: $refreshToken, role: $role, scope: $scope, radioInvitesApplied: $radioInvitesApplied)';
}


}

/// @nodoc
abstract mixin class _$TokensCopyWith<$Res> implements $TokensCopyWith<$Res> {
  factory _$TokensCopyWith(_Tokens value, $Res Function(_Tokens) _then) = __$TokensCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String refreshToken, UserRole role, String? scope, List<String> radioInvitesApplied
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
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? role = null,Object? scope = freezed,Object? radioInvitesApplied = null,}) {
  return _then(_Tokens(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String?,radioInvitesApplied: null == radioInvitesApplied ? _self._radioInvitesApplied : radioInvitesApplied // ignore: cast_nullable_to_non_nullable
as List<String>,
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

 DocType get docType; String? get expiresAt; bool get approved;
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
 DocType docType, String? expiresAt, bool approved
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
@pragma('vm:prefer-inline') @override $Res call({Object? docType = null,Object? expiresAt = freezed,Object? approved = null,}) {
  return _then(_self.copyWith(
docType: null == docType ? _self.docType : docType // ignore: cast_nullable_to_non_nullable
as DocType,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DocType docType,  String? expiresAt,  bool approved)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DocType docType,  String? expiresAt,  bool approved)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DocType docType,  String? expiresAt,  bool approved)?  $default,) {final _that = this;
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
  const _DriverDocument({required this.docType, this.expiresAt, required this.approved});
  factory _DriverDocument.fromJson(Map<String, dynamic> json) => _$DriverDocumentFromJson(json);

@override final  DocType docType;
@override final  String? expiresAt;
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
 DocType docType, String? expiresAt, bool approved
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
@override @pragma('vm:prefer-inline') $Res call({Object? docType = null,Object? expiresAt = freezed,Object? approved = null,}) {
  return _then(_DriverDocument(
docType: null == docType ? _self.docType : docType // ignore: cast_nullable_to_non_nullable
as DocType,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$BlockedDocument {

 DocType get docType; BlockedDocumentProblem get problem;
/// Create a copy of BlockedDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlockedDocumentCopyWith<BlockedDocument> get copyWith => _$BlockedDocumentCopyWithImpl<BlockedDocument>(this as BlockedDocument, _$identity);

  /// Serializes this BlockedDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlockedDocument&&(identical(other.docType, docType) || other.docType == docType)&&(identical(other.problem, problem) || other.problem == problem));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,docType,problem);

@override
String toString() {
  return 'BlockedDocument(docType: $docType, problem: $problem)';
}


}

/// @nodoc
abstract mixin class $BlockedDocumentCopyWith<$Res>  {
  factory $BlockedDocumentCopyWith(BlockedDocument value, $Res Function(BlockedDocument) _then) = _$BlockedDocumentCopyWithImpl;
@useResult
$Res call({
 DocType docType, BlockedDocumentProblem problem
});




}
/// @nodoc
class _$BlockedDocumentCopyWithImpl<$Res>
    implements $BlockedDocumentCopyWith<$Res> {
  _$BlockedDocumentCopyWithImpl(this._self, this._then);

  final BlockedDocument _self;
  final $Res Function(BlockedDocument) _then;

/// Create a copy of BlockedDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docType = null,Object? problem = null,}) {
  return _then(_self.copyWith(
docType: null == docType ? _self.docType : docType // ignore: cast_nullable_to_non_nullable
as DocType,problem: null == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as BlockedDocumentProblem,
  ));
}

}


/// Adds pattern-matching-related methods to [BlockedDocument].
extension BlockedDocumentPatterns on BlockedDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BlockedDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BlockedDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BlockedDocument value)  $default,){
final _that = this;
switch (_that) {
case _BlockedDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BlockedDocument value)?  $default,){
final _that = this;
switch (_that) {
case _BlockedDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DocType docType,  BlockedDocumentProblem problem)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BlockedDocument() when $default != null:
return $default(_that.docType,_that.problem);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DocType docType,  BlockedDocumentProblem problem)  $default,) {final _that = this;
switch (_that) {
case _BlockedDocument():
return $default(_that.docType,_that.problem);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DocType docType,  BlockedDocumentProblem problem)?  $default,) {final _that = this;
switch (_that) {
case _BlockedDocument() when $default != null:
return $default(_that.docType,_that.problem);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BlockedDocument implements BlockedDocument {
  const _BlockedDocument({required this.docType, required this.problem});
  factory _BlockedDocument.fromJson(Map<String, dynamic> json) => _$BlockedDocumentFromJson(json);

@override final  DocType docType;
@override final  BlockedDocumentProblem problem;

/// Create a copy of BlockedDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlockedDocumentCopyWith<_BlockedDocument> get copyWith => __$BlockedDocumentCopyWithImpl<_BlockedDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlockedDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlockedDocument&&(identical(other.docType, docType) || other.docType == docType)&&(identical(other.problem, problem) || other.problem == problem));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,docType,problem);

@override
String toString() {
  return 'BlockedDocument(docType: $docType, problem: $problem)';
}


}

/// @nodoc
abstract mixin class _$BlockedDocumentCopyWith<$Res> implements $BlockedDocumentCopyWith<$Res> {
  factory _$BlockedDocumentCopyWith(_BlockedDocument value, $Res Function(_BlockedDocument) _then) = __$BlockedDocumentCopyWithImpl;
@override @useResult
$Res call({
 DocType docType, BlockedDocumentProblem problem
});




}
/// @nodoc
class __$BlockedDocumentCopyWithImpl<$Res>
    implements _$BlockedDocumentCopyWith<$Res> {
  __$BlockedDocumentCopyWithImpl(this._self, this._then);

  final _BlockedDocument _self;
  final $Res Function(_BlockedDocument) _then;

/// Create a copy of BlockedDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docType = null,Object? problem = null,}) {
  return _then(_BlockedDocument(
docType: null == docType ? _self.docType : docType // ignore: cast_nullable_to_non_nullable
as DocType,problem: null == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as BlockedDocumentProblem,
  ));
}


}


/// @nodoc
mixin _$DriverMe {

 String get driverId; String get qrToken; DriverPresence get presence; SubscriptionStatus get subscriptionStatus; DateTime? get paidUntil; bool get canGoOnline; String? get blockReason; List<BlockedDocument> get blockedDocuments; List<DriverDocument> get documents;
/// Create a copy of DriverMe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverMeCopyWith<DriverMe> get copyWith => _$DriverMeCopyWithImpl<DriverMe>(this as DriverMe, _$identity);

  /// Serializes this DriverMe to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverMe&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.qrToken, qrToken) || other.qrToken == qrToken)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.subscriptionStatus, subscriptionStatus) || other.subscriptionStatus == subscriptionStatus)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.canGoOnline, canGoOnline) || other.canGoOnline == canGoOnline)&&(identical(other.blockReason, blockReason) || other.blockReason == blockReason)&&const DeepCollectionEquality().equals(other.blockedDocuments, blockedDocuments)&&const DeepCollectionEquality().equals(other.documents, documents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,qrToken,presence,subscriptionStatus,paidUntil,canGoOnline,blockReason,const DeepCollectionEquality().hash(blockedDocuments),const DeepCollectionEquality().hash(documents));

@override
String toString() {
  return 'DriverMe(driverId: $driverId, qrToken: $qrToken, presence: $presence, subscriptionStatus: $subscriptionStatus, paidUntil: $paidUntil, canGoOnline: $canGoOnline, blockReason: $blockReason, blockedDocuments: $blockedDocuments, documents: $documents)';
}


}

/// @nodoc
abstract mixin class $DriverMeCopyWith<$Res>  {
  factory $DriverMeCopyWith(DriverMe value, $Res Function(DriverMe) _then) = _$DriverMeCopyWithImpl;
@useResult
$Res call({
 String driverId, String qrToken, DriverPresence presence, SubscriptionStatus subscriptionStatus, DateTime? paidUntil, bool canGoOnline, String? blockReason, List<BlockedDocument> blockedDocuments, List<DriverDocument> documents
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
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? qrToken = null,Object? presence = null,Object? subscriptionStatus = null,Object? paidUntil = freezed,Object? canGoOnline = null,Object? blockReason = freezed,Object? blockedDocuments = null,Object? documents = null,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,qrToken: null == qrToken ? _self.qrToken : qrToken // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as DriverPresence,subscriptionStatus: null == subscriptionStatus ? _self.subscriptionStatus : subscriptionStatus // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,paidUntil: freezed == paidUntil ? _self.paidUntil : paidUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,canGoOnline: null == canGoOnline ? _self.canGoOnline : canGoOnline // ignore: cast_nullable_to_non_nullable
as bool,blockReason: freezed == blockReason ? _self.blockReason : blockReason // ignore: cast_nullable_to_non_nullable
as String?,blockedDocuments: null == blockedDocuments ? _self.blockedDocuments : blockedDocuments // ignore: cast_nullable_to_non_nullable
as List<BlockedDocument>,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String qrToken,  DriverPresence presence,  SubscriptionStatus subscriptionStatus,  DateTime? paidUntil,  bool canGoOnline,  String? blockReason,  List<BlockedDocument> blockedDocuments,  List<DriverDocument> documents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverMe() when $default != null:
return $default(_that.driverId,_that.qrToken,_that.presence,_that.subscriptionStatus,_that.paidUntil,_that.canGoOnline,_that.blockReason,_that.blockedDocuments,_that.documents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String qrToken,  DriverPresence presence,  SubscriptionStatus subscriptionStatus,  DateTime? paidUntil,  bool canGoOnline,  String? blockReason,  List<BlockedDocument> blockedDocuments,  List<DriverDocument> documents)  $default,) {final _that = this;
switch (_that) {
case _DriverMe():
return $default(_that.driverId,_that.qrToken,_that.presence,_that.subscriptionStatus,_that.paidUntil,_that.canGoOnline,_that.blockReason,_that.blockedDocuments,_that.documents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String qrToken,  DriverPresence presence,  SubscriptionStatus subscriptionStatus,  DateTime? paidUntil,  bool canGoOnline,  String? blockReason,  List<BlockedDocument> blockedDocuments,  List<DriverDocument> documents)?  $default,) {final _that = this;
switch (_that) {
case _DriverMe() when $default != null:
return $default(_that.driverId,_that.qrToken,_that.presence,_that.subscriptionStatus,_that.paidUntil,_that.canGoOnline,_that.blockReason,_that.blockedDocuments,_that.documents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverMe implements DriverMe {
  const _DriverMe({required this.driverId, required this.qrToken, required this.presence, required this.subscriptionStatus, this.paidUntil, required this.canGoOnline, this.blockReason, final  List<BlockedDocument> blockedDocuments = const <BlockedDocument>[], final  List<DriverDocument> documents = const <DriverDocument>[]}): _blockedDocuments = blockedDocuments,_documents = documents;
  factory _DriverMe.fromJson(Map<String, dynamic> json) => _$DriverMeFromJson(json);

@override final  String driverId;
@override final  String qrToken;
@override final  DriverPresence presence;
@override final  SubscriptionStatus subscriptionStatus;
@override final  DateTime? paidUntil;
@override final  bool canGoOnline;
@override final  String? blockReason;
 final  List<BlockedDocument> _blockedDocuments;
@override@JsonKey() List<BlockedDocument> get blockedDocuments {
  if (_blockedDocuments is EqualUnmodifiableListView) return _blockedDocuments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blockedDocuments);
}

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverMe&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.qrToken, qrToken) || other.qrToken == qrToken)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.subscriptionStatus, subscriptionStatus) || other.subscriptionStatus == subscriptionStatus)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.canGoOnline, canGoOnline) || other.canGoOnline == canGoOnline)&&(identical(other.blockReason, blockReason) || other.blockReason == blockReason)&&const DeepCollectionEquality().equals(other._blockedDocuments, _blockedDocuments)&&const DeepCollectionEquality().equals(other._documents, _documents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,qrToken,presence,subscriptionStatus,paidUntil,canGoOnline,blockReason,const DeepCollectionEquality().hash(_blockedDocuments),const DeepCollectionEquality().hash(_documents));

@override
String toString() {
  return 'DriverMe(driverId: $driverId, qrToken: $qrToken, presence: $presence, subscriptionStatus: $subscriptionStatus, paidUntil: $paidUntil, canGoOnline: $canGoOnline, blockReason: $blockReason, blockedDocuments: $blockedDocuments, documents: $documents)';
}


}

/// @nodoc
abstract mixin class _$DriverMeCopyWith<$Res> implements $DriverMeCopyWith<$Res> {
  factory _$DriverMeCopyWith(_DriverMe value, $Res Function(_DriverMe) _then) = __$DriverMeCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String qrToken, DriverPresence presence, SubscriptionStatus subscriptionStatus, DateTime? paidUntil, bool canGoOnline, String? blockReason, List<BlockedDocument> blockedDocuments, List<DriverDocument> documents
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
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? qrToken = null,Object? presence = null,Object? subscriptionStatus = null,Object? paidUntil = freezed,Object? canGoOnline = null,Object? blockReason = freezed,Object? blockedDocuments = null,Object? documents = null,}) {
  return _then(_DriverMe(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,qrToken: null == qrToken ? _self.qrToken : qrToken // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as DriverPresence,subscriptionStatus: null == subscriptionStatus ? _self.subscriptionStatus : subscriptionStatus // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,paidUntil: freezed == paidUntil ? _self.paidUntil : paidUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,canGoOnline: null == canGoOnline ? _self.canGoOnline : canGoOnline // ignore: cast_nullable_to_non_nullable
as bool,blockReason: freezed == blockReason ? _self.blockReason : blockReason // ignore: cast_nullable_to_non_nullable
as String?,blockedDocuments: null == blockedDocuments ? _self._blockedDocuments : blockedDocuments // ignore: cast_nullable_to_non_nullable
as List<BlockedDocument>,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<DriverDocument>,
  ));
}


}


/// @nodoc
mixin _$AdminDriver {

 String get driverId; String get phoneE164; String get displayName; String get qrToken; String get vehiclePlate; String get vehicleDescription; DriverPresence get presence; DateTime? get paidUntil; SubscriptionStatus get subscriptionStatus; bool get canGoOnline; String? get blockReason; List<BlockedDocument> get blockedDocuments; List<DriverDocument> get documents;
/// Create a copy of AdminDriver
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminDriverCopyWith<AdminDriver> get copyWith => _$AdminDriverCopyWithImpl<AdminDriver>(this as AdminDriver, _$identity);

  /// Serializes this AdminDriver to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.qrToken, qrToken) || other.qrToken == qrToken)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleDescription, vehicleDescription) || other.vehicleDescription == vehicleDescription)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.subscriptionStatus, subscriptionStatus) || other.subscriptionStatus == subscriptionStatus)&&(identical(other.canGoOnline, canGoOnline) || other.canGoOnline == canGoOnline)&&(identical(other.blockReason, blockReason) || other.blockReason == blockReason)&&const DeepCollectionEquality().equals(other.blockedDocuments, blockedDocuments)&&const DeepCollectionEquality().equals(other.documents, documents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,phoneE164,displayName,qrToken,vehiclePlate,vehicleDescription,presence,paidUntil,subscriptionStatus,canGoOnline,blockReason,const DeepCollectionEquality().hash(blockedDocuments),const DeepCollectionEquality().hash(documents));

@override
String toString() {
  return 'AdminDriver(driverId: $driverId, phoneE164: $phoneE164, displayName: $displayName, qrToken: $qrToken, vehiclePlate: $vehiclePlate, vehicleDescription: $vehicleDescription, presence: $presence, paidUntil: $paidUntil, subscriptionStatus: $subscriptionStatus, canGoOnline: $canGoOnline, blockReason: $blockReason, blockedDocuments: $blockedDocuments, documents: $documents)';
}


}

/// @nodoc
abstract mixin class $AdminDriverCopyWith<$Res>  {
  factory $AdminDriverCopyWith(AdminDriver value, $Res Function(AdminDriver) _then) = _$AdminDriverCopyWithImpl;
@useResult
$Res call({
 String driverId, String phoneE164, String displayName, String qrToken, String vehiclePlate, String vehicleDescription, DriverPresence presence, DateTime? paidUntil, SubscriptionStatus subscriptionStatus, bool canGoOnline, String? blockReason, List<BlockedDocument> blockedDocuments, List<DriverDocument> documents
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
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? phoneE164 = null,Object? displayName = null,Object? qrToken = null,Object? vehiclePlate = null,Object? vehicleDescription = null,Object? presence = null,Object? paidUntil = freezed,Object? subscriptionStatus = null,Object? canGoOnline = null,Object? blockReason = freezed,Object? blockedDocuments = null,Object? documents = null,}) {
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
as String?,blockedDocuments: null == blockedDocuments ? _self.blockedDocuments : blockedDocuments // ignore: cast_nullable_to_non_nullable
as List<BlockedDocument>,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String phoneE164,  String displayName,  String qrToken,  String vehiclePlate,  String vehicleDescription,  DriverPresence presence,  DateTime? paidUntil,  SubscriptionStatus subscriptionStatus,  bool canGoOnline,  String? blockReason,  List<BlockedDocument> blockedDocuments,  List<DriverDocument> documents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminDriver() when $default != null:
return $default(_that.driverId,_that.phoneE164,_that.displayName,_that.qrToken,_that.vehiclePlate,_that.vehicleDescription,_that.presence,_that.paidUntil,_that.subscriptionStatus,_that.canGoOnline,_that.blockReason,_that.blockedDocuments,_that.documents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String phoneE164,  String displayName,  String qrToken,  String vehiclePlate,  String vehicleDescription,  DriverPresence presence,  DateTime? paidUntil,  SubscriptionStatus subscriptionStatus,  bool canGoOnline,  String? blockReason,  List<BlockedDocument> blockedDocuments,  List<DriverDocument> documents)  $default,) {final _that = this;
switch (_that) {
case _AdminDriver():
return $default(_that.driverId,_that.phoneE164,_that.displayName,_that.qrToken,_that.vehiclePlate,_that.vehicleDescription,_that.presence,_that.paidUntil,_that.subscriptionStatus,_that.canGoOnline,_that.blockReason,_that.blockedDocuments,_that.documents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String phoneE164,  String displayName,  String qrToken,  String vehiclePlate,  String vehicleDescription,  DriverPresence presence,  DateTime? paidUntil,  SubscriptionStatus subscriptionStatus,  bool canGoOnline,  String? blockReason,  List<BlockedDocument> blockedDocuments,  List<DriverDocument> documents)?  $default,) {final _that = this;
switch (_that) {
case _AdminDriver() when $default != null:
return $default(_that.driverId,_that.phoneE164,_that.displayName,_that.qrToken,_that.vehiclePlate,_that.vehicleDescription,_that.presence,_that.paidUntil,_that.subscriptionStatus,_that.canGoOnline,_that.blockReason,_that.blockedDocuments,_that.documents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminDriver implements AdminDriver {
  const _AdminDriver({required this.driverId, required this.phoneE164, required this.displayName, required this.qrToken, required this.vehiclePlate, required this.vehicleDescription, required this.presence, this.paidUntil, required this.subscriptionStatus, required this.canGoOnline, this.blockReason, final  List<BlockedDocument> blockedDocuments = const <BlockedDocument>[], final  List<DriverDocument> documents = const <DriverDocument>[]}): _blockedDocuments = blockedDocuments,_documents = documents;
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
 final  List<BlockedDocument> _blockedDocuments;
@override@JsonKey() List<BlockedDocument> get blockedDocuments {
  if (_blockedDocuments is EqualUnmodifiableListView) return _blockedDocuments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blockedDocuments);
}

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.qrToken, qrToken) || other.qrToken == qrToken)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleDescription, vehicleDescription) || other.vehicleDescription == vehicleDescription)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.subscriptionStatus, subscriptionStatus) || other.subscriptionStatus == subscriptionStatus)&&(identical(other.canGoOnline, canGoOnline) || other.canGoOnline == canGoOnline)&&(identical(other.blockReason, blockReason) || other.blockReason == blockReason)&&const DeepCollectionEquality().equals(other._blockedDocuments, _blockedDocuments)&&const DeepCollectionEquality().equals(other._documents, _documents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,phoneE164,displayName,qrToken,vehiclePlate,vehicleDescription,presence,paidUntil,subscriptionStatus,canGoOnline,blockReason,const DeepCollectionEquality().hash(_blockedDocuments),const DeepCollectionEquality().hash(_documents));

@override
String toString() {
  return 'AdminDriver(driverId: $driverId, phoneE164: $phoneE164, displayName: $displayName, qrToken: $qrToken, vehiclePlate: $vehiclePlate, vehicleDescription: $vehicleDescription, presence: $presence, paidUntil: $paidUntil, subscriptionStatus: $subscriptionStatus, canGoOnline: $canGoOnline, blockReason: $blockReason, blockedDocuments: $blockedDocuments, documents: $documents)';
}


}

/// @nodoc
abstract mixin class _$AdminDriverCopyWith<$Res> implements $AdminDriverCopyWith<$Res> {
  factory _$AdminDriverCopyWith(_AdminDriver value, $Res Function(_AdminDriver) _then) = __$AdminDriverCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String phoneE164, String displayName, String qrToken, String vehiclePlate, String vehicleDescription, DriverPresence presence, DateTime? paidUntil, SubscriptionStatus subscriptionStatus, bool canGoOnline, String? blockReason, List<BlockedDocument> blockedDocuments, List<DriverDocument> documents
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
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? phoneE164 = null,Object? displayName = null,Object? qrToken = null,Object? vehiclePlate = null,Object? vehicleDescription = null,Object? presence = null,Object? paidUntil = freezed,Object? subscriptionStatus = null,Object? canGoOnline = null,Object? blockReason = freezed,Object? blockedDocuments = null,Object? documents = null,}) {
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
as String?,blockedDocuments: null == blockedDocuments ? _self._blockedDocuments : blockedDocuments // ignore: cast_nullable_to_non_nullable
as List<BlockedDocument>,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<DriverDocument>,
  ));
}


}


/// @nodoc
mixin _$DriverZone {

 String get cell; double get lat; double get lng;
/// Create a copy of DriverZone
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverZoneCopyWith<DriverZone> get copyWith => _$DriverZoneCopyWithImpl<DriverZone>(this as DriverZone, _$identity);

  /// Serializes this DriverZone to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverZone&&(identical(other.cell, cell) || other.cell == cell)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cell,lat,lng);

@override
String toString() {
  return 'DriverZone(cell: $cell, lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class $DriverZoneCopyWith<$Res>  {
  factory $DriverZoneCopyWith(DriverZone value, $Res Function(DriverZone) _then) = _$DriverZoneCopyWithImpl;
@useResult
$Res call({
 String cell, double lat, double lng
});




}
/// @nodoc
class _$DriverZoneCopyWithImpl<$Res>
    implements $DriverZoneCopyWith<$Res> {
  _$DriverZoneCopyWithImpl(this._self, this._then);

  final DriverZone _self;
  final $Res Function(DriverZone) _then;

/// Create a copy of DriverZone
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cell = null,Object? lat = null,Object? lng = null,}) {
  return _then(_self.copyWith(
cell: null == cell ? _self.cell : cell // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [DriverZone].
extension DriverZonePatterns on DriverZone {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverZone value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverZone() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverZone value)  $default,){
final _that = this;
switch (_that) {
case _DriverZone():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverZone value)?  $default,){
final _that = this;
switch (_that) {
case _DriverZone() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String cell,  double lat,  double lng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverZone() when $default != null:
return $default(_that.cell,_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String cell,  double lat,  double lng)  $default,) {final _that = this;
switch (_that) {
case _DriverZone():
return $default(_that.cell,_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String cell,  double lat,  double lng)?  $default,) {final _that = this;
switch (_that) {
case _DriverZone() when $default != null:
return $default(_that.cell,_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverZone implements DriverZone {
  const _DriverZone({required this.cell, required this.lat, required this.lng});
  factory _DriverZone.fromJson(Map<String, dynamic> json) => _$DriverZoneFromJson(json);

@override final  String cell;
@override final  double lat;
@override final  double lng;

/// Create a copy of DriverZone
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverZoneCopyWith<_DriverZone> get copyWith => __$DriverZoneCopyWithImpl<_DriverZone>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverZoneToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverZone&&(identical(other.cell, cell) || other.cell == cell)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cell,lat,lng);

@override
String toString() {
  return 'DriverZone(cell: $cell, lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$DriverZoneCopyWith<$Res> implements $DriverZoneCopyWith<$Res> {
  factory _$DriverZoneCopyWith(_DriverZone value, $Res Function(_DriverZone) _then) = __$DriverZoneCopyWithImpl;
@override @useResult
$Res call({
 String cell, double lat, double lng
});




}
/// @nodoc
class __$DriverZoneCopyWithImpl<$Res>
    implements _$DriverZoneCopyWith<$Res> {
  __$DriverZoneCopyWithImpl(this._self, this._then);

  final _DriverZone _self;
  final $Res Function(_DriverZone) _then;

/// Create a copy of DriverZone
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cell = null,Object? lat = null,Object? lng = null,}) {
  return _then(_DriverZone(
cell: null == cell ? _self.cell : cell // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ChosenDriver {

 String get driverId; String get displayName; String get vehicleDescription; DriverPresence get presence; DateTime? get busyUntilEstimate;/// 006: cooperativa activa del conductor, si tiene (selector de despacho).
 CooperativeRef? get cooperative;/// 010: zona aproximada (centro de su hexágono) si está libre; nunca su posición.
 DriverZone? get zone;
/// Create a copy of ChosenDriver
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChosenDriverCopyWith<ChosenDriver> get copyWith => _$ChosenDriverCopyWithImpl<ChosenDriver>(this as ChosenDriver, _$identity);

  /// Serializes this ChosenDriver to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChosenDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.vehicleDescription, vehicleDescription) || other.vehicleDescription == vehicleDescription)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.busyUntilEstimate, busyUntilEstimate) || other.busyUntilEstimate == busyUntilEstimate)&&(identical(other.cooperative, cooperative) || other.cooperative == cooperative)&&(identical(other.zone, zone) || other.zone == zone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,vehicleDescription,presence,busyUntilEstimate,cooperative,zone);

@override
String toString() {
  return 'ChosenDriver(driverId: $driverId, displayName: $displayName, vehicleDescription: $vehicleDescription, presence: $presence, busyUntilEstimate: $busyUntilEstimate, cooperative: $cooperative, zone: $zone)';
}


}

/// @nodoc
abstract mixin class $ChosenDriverCopyWith<$Res>  {
  factory $ChosenDriverCopyWith(ChosenDriver value, $Res Function(ChosenDriver) _then) = _$ChosenDriverCopyWithImpl;
@useResult
$Res call({
 String driverId, String displayName, String vehicleDescription, DriverPresence presence, DateTime? busyUntilEstimate, CooperativeRef? cooperative, DriverZone? zone
});


$CooperativeRefCopyWith<$Res>? get cooperative;$DriverZoneCopyWith<$Res>? get zone;

}
/// @nodoc
class _$ChosenDriverCopyWithImpl<$Res>
    implements $ChosenDriverCopyWith<$Res> {
  _$ChosenDriverCopyWithImpl(this._self, this._then);

  final ChosenDriver _self;
  final $Res Function(ChosenDriver) _then;

/// Create a copy of ChosenDriver
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? displayName = null,Object? vehicleDescription = null,Object? presence = null,Object? busyUntilEstimate = freezed,Object? cooperative = freezed,Object? zone = freezed,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,vehicleDescription: null == vehicleDescription ? _self.vehicleDescription : vehicleDescription // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as DriverPresence,busyUntilEstimate: freezed == busyUntilEstimate ? _self.busyUntilEstimate : busyUntilEstimate // ignore: cast_nullable_to_non_nullable
as DateTime?,cooperative: freezed == cooperative ? _self.cooperative : cooperative // ignore: cast_nullable_to_non_nullable
as CooperativeRef?,zone: freezed == zone ? _self.zone : zone // ignore: cast_nullable_to_non_nullable
as DriverZone?,
  ));
}
/// Create a copy of ChosenDriver
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CooperativeRefCopyWith<$Res>? get cooperative {
    if (_self.cooperative == null) {
    return null;
  }

  return $CooperativeRefCopyWith<$Res>(_self.cooperative!, (value) {
    return _then(_self.copyWith(cooperative: value));
  });
}/// Create a copy of ChosenDriver
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverZoneCopyWith<$Res>? get zone {
    if (_self.zone == null) {
    return null;
  }

  return $DriverZoneCopyWith<$Res>(_self.zone!, (value) {
    return _then(_self.copyWith(zone: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String displayName,  String vehicleDescription,  DriverPresence presence,  DateTime? busyUntilEstimate,  CooperativeRef? cooperative,  DriverZone? zone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChosenDriver() when $default != null:
return $default(_that.driverId,_that.displayName,_that.vehicleDescription,_that.presence,_that.busyUntilEstimate,_that.cooperative,_that.zone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String displayName,  String vehicleDescription,  DriverPresence presence,  DateTime? busyUntilEstimate,  CooperativeRef? cooperative,  DriverZone? zone)  $default,) {final _that = this;
switch (_that) {
case _ChosenDriver():
return $default(_that.driverId,_that.displayName,_that.vehicleDescription,_that.presence,_that.busyUntilEstimate,_that.cooperative,_that.zone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String displayName,  String vehicleDescription,  DriverPresence presence,  DateTime? busyUntilEstimate,  CooperativeRef? cooperative,  DriverZone? zone)?  $default,) {final _that = this;
switch (_that) {
case _ChosenDriver() when $default != null:
return $default(_that.driverId,_that.displayName,_that.vehicleDescription,_that.presence,_that.busyUntilEstimate,_that.cooperative,_that.zone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChosenDriver implements ChosenDriver {
  const _ChosenDriver({required this.driverId, required this.displayName, required this.vehicleDescription, required this.presence, this.busyUntilEstimate, this.cooperative, this.zone});
  factory _ChosenDriver.fromJson(Map<String, dynamic> json) => _$ChosenDriverFromJson(json);

@override final  String driverId;
@override final  String displayName;
@override final  String vehicleDescription;
@override final  DriverPresence presence;
@override final  DateTime? busyUntilEstimate;
/// 006: cooperativa activa del conductor, si tiene (selector de despacho).
@override final  CooperativeRef? cooperative;
/// 010: zona aproximada (centro de su hexágono) si está libre; nunca su posición.
@override final  DriverZone? zone;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChosenDriver&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.vehicleDescription, vehicleDescription) || other.vehicleDescription == vehicleDescription)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.busyUntilEstimate, busyUntilEstimate) || other.busyUntilEstimate == busyUntilEstimate)&&(identical(other.cooperative, cooperative) || other.cooperative == cooperative)&&(identical(other.zone, zone) || other.zone == zone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,vehicleDescription,presence,busyUntilEstimate,cooperative,zone);

@override
String toString() {
  return 'ChosenDriver(driverId: $driverId, displayName: $displayName, vehicleDescription: $vehicleDescription, presence: $presence, busyUntilEstimate: $busyUntilEstimate, cooperative: $cooperative, zone: $zone)';
}


}

/// @nodoc
abstract mixin class _$ChosenDriverCopyWith<$Res> implements $ChosenDriverCopyWith<$Res> {
  factory _$ChosenDriverCopyWith(_ChosenDriver value, $Res Function(_ChosenDriver) _then) = __$ChosenDriverCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String displayName, String vehicleDescription, DriverPresence presence, DateTime? busyUntilEstimate, CooperativeRef? cooperative, DriverZone? zone
});


@override $CooperativeRefCopyWith<$Res>? get cooperative;@override $DriverZoneCopyWith<$Res>? get zone;

}
/// @nodoc
class __$ChosenDriverCopyWithImpl<$Res>
    implements _$ChosenDriverCopyWith<$Res> {
  __$ChosenDriverCopyWithImpl(this._self, this._then);

  final _ChosenDriver _self;
  final $Res Function(_ChosenDriver) _then;

/// Create a copy of ChosenDriver
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? displayName = null,Object? vehicleDescription = null,Object? presence = null,Object? busyUntilEstimate = freezed,Object? cooperative = freezed,Object? zone = freezed,}) {
  return _then(_ChosenDriver(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,vehicleDescription: null == vehicleDescription ? _self.vehicleDescription : vehicleDescription // ignore: cast_nullable_to_non_nullable
as String,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as DriverPresence,busyUntilEstimate: freezed == busyUntilEstimate ? _self.busyUntilEstimate : busyUntilEstimate // ignore: cast_nullable_to_non_nullable
as DateTime?,cooperative: freezed == cooperative ? _self.cooperative : cooperative // ignore: cast_nullable_to_non_nullable
as CooperativeRef?,zone: freezed == zone ? _self.zone : zone // ignore: cast_nullable_to_non_nullable
as DriverZone?,
  ));
}

/// Create a copy of ChosenDriver
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CooperativeRefCopyWith<$Res>? get cooperative {
    if (_self.cooperative == null) {
    return null;
  }

  return $CooperativeRefCopyWith<$Res>(_self.cooperative!, (value) {
    return _then(_self.copyWith(cooperative: value));
  });
}/// Create a copy of ChosenDriver
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DriverZoneCopyWith<$Res>? get zone {
    if (_self.zone == null) {
    return null;
  }

  return $DriverZoneCopyWith<$Res>(_self.zone!, (value) {
    return _then(_self.copyWith(zone: value));
  });
}
}


/// @nodoc
mixin _$FareTableInput {

 String get currency; int get baseMinor; int get perKmMinor; int get perMinuteMinor; int get minimumMinor; int get roundingMinor;
/// Create a copy of FareTableInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FareTableInputCopyWith<FareTableInput> get copyWith => _$FareTableInputCopyWithImpl<FareTableInput>(this as FareTableInput, _$identity);

  /// Serializes this FareTableInput to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FareTableInput&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.baseMinor, baseMinor) || other.baseMinor == baseMinor)&&(identical(other.perKmMinor, perKmMinor) || other.perKmMinor == perKmMinor)&&(identical(other.perMinuteMinor, perMinuteMinor) || other.perMinuteMinor == perMinuteMinor)&&(identical(other.minimumMinor, minimumMinor) || other.minimumMinor == minimumMinor)&&(identical(other.roundingMinor, roundingMinor) || other.roundingMinor == roundingMinor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currency,baseMinor,perKmMinor,perMinuteMinor,minimumMinor,roundingMinor);

@override
String toString() {
  return 'FareTableInput(currency: $currency, baseMinor: $baseMinor, perKmMinor: $perKmMinor, perMinuteMinor: $perMinuteMinor, minimumMinor: $minimumMinor, roundingMinor: $roundingMinor)';
}


}

/// @nodoc
abstract mixin class $FareTableInputCopyWith<$Res>  {
  factory $FareTableInputCopyWith(FareTableInput value, $Res Function(FareTableInput) _then) = _$FareTableInputCopyWithImpl;
@useResult
$Res call({
 String currency, int baseMinor, int perKmMinor, int perMinuteMinor, int minimumMinor, int roundingMinor
});




}
/// @nodoc
class _$FareTableInputCopyWithImpl<$Res>
    implements $FareTableInputCopyWith<$Res> {
  _$FareTableInputCopyWithImpl(this._self, this._then);

  final FareTableInput _self;
  final $Res Function(FareTableInput) _then;

/// Create a copy of FareTableInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currency = null,Object? baseMinor = null,Object? perKmMinor = null,Object? perMinuteMinor = null,Object? minimumMinor = null,Object? roundingMinor = null,}) {
  return _then(_self.copyWith(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,baseMinor: null == baseMinor ? _self.baseMinor : baseMinor // ignore: cast_nullable_to_non_nullable
as int,perKmMinor: null == perKmMinor ? _self.perKmMinor : perKmMinor // ignore: cast_nullable_to_non_nullable
as int,perMinuteMinor: null == perMinuteMinor ? _self.perMinuteMinor : perMinuteMinor // ignore: cast_nullable_to_non_nullable
as int,minimumMinor: null == minimumMinor ? _self.minimumMinor : minimumMinor // ignore: cast_nullable_to_non_nullable
as int,roundingMinor: null == roundingMinor ? _self.roundingMinor : roundingMinor // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FareTableInput].
extension FareTableInputPatterns on FareTableInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FareTableInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FareTableInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FareTableInput value)  $default,){
final _that = this;
switch (_that) {
case _FareTableInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FareTableInput value)?  $default,){
final _that = this;
switch (_that) {
case _FareTableInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currency,  int baseMinor,  int perKmMinor,  int perMinuteMinor,  int minimumMinor,  int roundingMinor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FareTableInput() when $default != null:
return $default(_that.currency,_that.baseMinor,_that.perKmMinor,_that.perMinuteMinor,_that.minimumMinor,_that.roundingMinor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currency,  int baseMinor,  int perKmMinor,  int perMinuteMinor,  int minimumMinor,  int roundingMinor)  $default,) {final _that = this;
switch (_that) {
case _FareTableInput():
return $default(_that.currency,_that.baseMinor,_that.perKmMinor,_that.perMinuteMinor,_that.minimumMinor,_that.roundingMinor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currency,  int baseMinor,  int perKmMinor,  int perMinuteMinor,  int minimumMinor,  int roundingMinor)?  $default,) {final _that = this;
switch (_that) {
case _FareTableInput() when $default != null:
return $default(_that.currency,_that.baseMinor,_that.perKmMinor,_that.perMinuteMinor,_that.minimumMinor,_that.roundingMinor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FareTableInput implements FareTableInput {
  const _FareTableInput({required this.currency, required this.baseMinor, required this.perKmMinor, required this.perMinuteMinor, required this.minimumMinor, this.roundingMinor = 1});
  factory _FareTableInput.fromJson(Map<String, dynamic> json) => _$FareTableInputFromJson(json);

@override final  String currency;
@override final  int baseMinor;
@override final  int perKmMinor;
@override final  int perMinuteMinor;
@override final  int minimumMinor;
@override@JsonKey() final  int roundingMinor;

/// Create a copy of FareTableInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FareTableInputCopyWith<_FareTableInput> get copyWith => __$FareTableInputCopyWithImpl<_FareTableInput>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FareTableInputToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FareTableInput&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.baseMinor, baseMinor) || other.baseMinor == baseMinor)&&(identical(other.perKmMinor, perKmMinor) || other.perKmMinor == perKmMinor)&&(identical(other.perMinuteMinor, perMinuteMinor) || other.perMinuteMinor == perMinuteMinor)&&(identical(other.minimumMinor, minimumMinor) || other.minimumMinor == minimumMinor)&&(identical(other.roundingMinor, roundingMinor) || other.roundingMinor == roundingMinor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currency,baseMinor,perKmMinor,perMinuteMinor,minimumMinor,roundingMinor);

@override
String toString() {
  return 'FareTableInput(currency: $currency, baseMinor: $baseMinor, perKmMinor: $perKmMinor, perMinuteMinor: $perMinuteMinor, minimumMinor: $minimumMinor, roundingMinor: $roundingMinor)';
}


}

/// @nodoc
abstract mixin class _$FareTableInputCopyWith<$Res> implements $FareTableInputCopyWith<$Res> {
  factory _$FareTableInputCopyWith(_FareTableInput value, $Res Function(_FareTableInput) _then) = __$FareTableInputCopyWithImpl;
@override @useResult
$Res call({
 String currency, int baseMinor, int perKmMinor, int perMinuteMinor, int minimumMinor, int roundingMinor
});




}
/// @nodoc
class __$FareTableInputCopyWithImpl<$Res>
    implements _$FareTableInputCopyWith<$Res> {
  __$FareTableInputCopyWithImpl(this._self, this._then);

  final _FareTableInput _self;
  final $Res Function(_FareTableInput) _then;

/// Create a copy of FareTableInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currency = null,Object? baseMinor = null,Object? perKmMinor = null,Object? perMinuteMinor = null,Object? minimumMinor = null,Object? roundingMinor = null,}) {
  return _then(_FareTableInput(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,baseMinor: null == baseMinor ? _self.baseMinor : baseMinor // ignore: cast_nullable_to_non_nullable
as int,perKmMinor: null == perKmMinor ? _self.perKmMinor : perKmMinor // ignore: cast_nullable_to_non_nullable
as int,perMinuteMinor: null == perMinuteMinor ? _self.perMinuteMinor : perMinuteMinor // ignore: cast_nullable_to_non_nullable
as int,minimumMinor: null == minimumMinor ? _self.minimumMinor : minimumMinor // ignore: cast_nullable_to_non_nullable
as int,roundingMinor: null == roundingMinor ? _self.roundingMinor : roundingMinor // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DispatchSettings {

 bool get acceptsZonePool; int get preferentialDiscountPct; String get affiliateLink;
/// Create a copy of DispatchSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DispatchSettingsCopyWith<DispatchSettings> get copyWith => _$DispatchSettingsCopyWithImpl<DispatchSettings>(this as DispatchSettings, _$identity);

  /// Serializes this DispatchSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DispatchSettings&&(identical(other.acceptsZonePool, acceptsZonePool) || other.acceptsZonePool == acceptsZonePool)&&(identical(other.preferentialDiscountPct, preferentialDiscountPct) || other.preferentialDiscountPct == preferentialDiscountPct)&&(identical(other.affiliateLink, affiliateLink) || other.affiliateLink == affiliateLink));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,acceptsZonePool,preferentialDiscountPct,affiliateLink);

@override
String toString() {
  return 'DispatchSettings(acceptsZonePool: $acceptsZonePool, preferentialDiscountPct: $preferentialDiscountPct, affiliateLink: $affiliateLink)';
}


}

/// @nodoc
abstract mixin class $DispatchSettingsCopyWith<$Res>  {
  factory $DispatchSettingsCopyWith(DispatchSettings value, $Res Function(DispatchSettings) _then) = _$DispatchSettingsCopyWithImpl;
@useResult
$Res call({
 bool acceptsZonePool, int preferentialDiscountPct, String affiliateLink
});




}
/// @nodoc
class _$DispatchSettingsCopyWithImpl<$Res>
    implements $DispatchSettingsCopyWith<$Res> {
  _$DispatchSettingsCopyWithImpl(this._self, this._then);

  final DispatchSettings _self;
  final $Res Function(DispatchSettings) _then;

/// Create a copy of DispatchSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? acceptsZonePool = null,Object? preferentialDiscountPct = null,Object? affiliateLink = null,}) {
  return _then(_self.copyWith(
acceptsZonePool: null == acceptsZonePool ? _self.acceptsZonePool : acceptsZonePool // ignore: cast_nullable_to_non_nullable
as bool,preferentialDiscountPct: null == preferentialDiscountPct ? _self.preferentialDiscountPct : preferentialDiscountPct // ignore: cast_nullable_to_non_nullable
as int,affiliateLink: null == affiliateLink ? _self.affiliateLink : affiliateLink // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DispatchSettings].
extension DispatchSettingsPatterns on DispatchSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DispatchSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DispatchSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DispatchSettings value)  $default,){
final _that = this;
switch (_that) {
case _DispatchSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DispatchSettings value)?  $default,){
final _that = this;
switch (_that) {
case _DispatchSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool acceptsZonePool,  int preferentialDiscountPct,  String affiliateLink)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DispatchSettings() when $default != null:
return $default(_that.acceptsZonePool,_that.preferentialDiscountPct,_that.affiliateLink);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool acceptsZonePool,  int preferentialDiscountPct,  String affiliateLink)  $default,) {final _that = this;
switch (_that) {
case _DispatchSettings():
return $default(_that.acceptsZonePool,_that.preferentialDiscountPct,_that.affiliateLink);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool acceptsZonePool,  int preferentialDiscountPct,  String affiliateLink)?  $default,) {final _that = this;
switch (_that) {
case _DispatchSettings() when $default != null:
return $default(_that.acceptsZonePool,_that.preferentialDiscountPct,_that.affiliateLink);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DispatchSettings implements DispatchSettings {
  const _DispatchSettings({this.acceptsZonePool = false, this.preferentialDiscountPct = 0, this.affiliateLink = ''});
  factory _DispatchSettings.fromJson(Map<String, dynamic> json) => _$DispatchSettingsFromJson(json);

@override@JsonKey() final  bool acceptsZonePool;
@override@JsonKey() final  int preferentialDiscountPct;
@override@JsonKey() final  String affiliateLink;

/// Create a copy of DispatchSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DispatchSettingsCopyWith<_DispatchSettings> get copyWith => __$DispatchSettingsCopyWithImpl<_DispatchSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DispatchSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DispatchSettings&&(identical(other.acceptsZonePool, acceptsZonePool) || other.acceptsZonePool == acceptsZonePool)&&(identical(other.preferentialDiscountPct, preferentialDiscountPct) || other.preferentialDiscountPct == preferentialDiscountPct)&&(identical(other.affiliateLink, affiliateLink) || other.affiliateLink == affiliateLink));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,acceptsZonePool,preferentialDiscountPct,affiliateLink);

@override
String toString() {
  return 'DispatchSettings(acceptsZonePool: $acceptsZonePool, preferentialDiscountPct: $preferentialDiscountPct, affiliateLink: $affiliateLink)';
}


}

/// @nodoc
abstract mixin class _$DispatchSettingsCopyWith<$Res> implements $DispatchSettingsCopyWith<$Res> {
  factory _$DispatchSettingsCopyWith(_DispatchSettings value, $Res Function(_DispatchSettings) _then) = __$DispatchSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool acceptsZonePool, int preferentialDiscountPct, String affiliateLink
});




}
/// @nodoc
class __$DispatchSettingsCopyWithImpl<$Res>
    implements _$DispatchSettingsCopyWith<$Res> {
  __$DispatchSettingsCopyWithImpl(this._self, this._then);

  final _DispatchSettings _self;
  final $Res Function(_DispatchSettings) _then;

/// Create a copy of DispatchSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? acceptsZonePool = null,Object? preferentialDiscountPct = null,Object? affiliateLink = null,}) {
  return _then(_DispatchSettings(
acceptsZonePool: null == acceptsZonePool ? _self.acceptsZonePool : acceptsZonePool // ignore: cast_nullable_to_non_nullable
as bool,preferentialDiscountPct: null == preferentialDiscountPct ? _self.preferentialDiscountPct : preferentialDiscountPct // ignore: cast_nullable_to_non_nullable
as int,affiliateLink: null == affiliateLink ? _self.affiliateLink : affiliateLink // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DriverClient {

 String get passengerId; String get displayName; DateTime get affiliatedAt;/// 008: cómo llegó a la cartera.
 AffiliationSource get source;
/// Create a copy of DriverClient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverClientCopyWith<DriverClient> get copyWith => _$DriverClientCopyWithImpl<DriverClient>(this as DriverClient, _$identity);

  /// Serializes this DriverClient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverClient&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.affiliatedAt, affiliatedAt) || other.affiliatedAt == affiliatedAt)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,passengerId,displayName,affiliatedAt,source);

@override
String toString() {
  return 'DriverClient(passengerId: $passengerId, displayName: $displayName, affiliatedAt: $affiliatedAt, source: $source)';
}


}

/// @nodoc
abstract mixin class $DriverClientCopyWith<$Res>  {
  factory $DriverClientCopyWith(DriverClient value, $Res Function(DriverClient) _then) = _$DriverClientCopyWithImpl;
@useResult
$Res call({
 String passengerId, String displayName, DateTime affiliatedAt, AffiliationSource source
});




}
/// @nodoc
class _$DriverClientCopyWithImpl<$Res>
    implements $DriverClientCopyWith<$Res> {
  _$DriverClientCopyWithImpl(this._self, this._then);

  final DriverClient _self;
  final $Res Function(DriverClient) _then;

/// Create a copy of DriverClient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? passengerId = null,Object? displayName = null,Object? affiliatedAt = null,Object? source = null,}) {
  return _then(_self.copyWith(
passengerId: null == passengerId ? _self.passengerId : passengerId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,affiliatedAt: null == affiliatedAt ? _self.affiliatedAt : affiliatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AffiliationSource,
  ));
}

}


/// Adds pattern-matching-related methods to [DriverClient].
extension DriverClientPatterns on DriverClient {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverClient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverClient() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverClient value)  $default,){
final _that = this;
switch (_that) {
case _DriverClient():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverClient value)?  $default,){
final _that = this;
switch (_that) {
case _DriverClient() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String passengerId,  String displayName,  DateTime affiliatedAt,  AffiliationSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverClient() when $default != null:
return $default(_that.passengerId,_that.displayName,_that.affiliatedAt,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String passengerId,  String displayName,  DateTime affiliatedAt,  AffiliationSource source)  $default,) {final _that = this;
switch (_that) {
case _DriverClient():
return $default(_that.passengerId,_that.displayName,_that.affiliatedAt,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String passengerId,  String displayName,  DateTime affiliatedAt,  AffiliationSource source)?  $default,) {final _that = this;
switch (_that) {
case _DriverClient() when $default != null:
return $default(_that.passengerId,_that.displayName,_that.affiliatedAt,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverClient implements DriverClient {
  const _DriverClient({required this.passengerId, required this.displayName, required this.affiliatedAt, this.source = AffiliationSource.qrScan});
  factory _DriverClient.fromJson(Map<String, dynamic> json) => _$DriverClientFromJson(json);

@override final  String passengerId;
@override final  String displayName;
@override final  DateTime affiliatedAt;
/// 008: cómo llegó a la cartera.
@override@JsonKey() final  AffiliationSource source;

/// Create a copy of DriverClient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverClientCopyWith<_DriverClient> get copyWith => __$DriverClientCopyWithImpl<_DriverClient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverClientToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverClient&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.affiliatedAt, affiliatedAt) || other.affiliatedAt == affiliatedAt)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,passengerId,displayName,affiliatedAt,source);

@override
String toString() {
  return 'DriverClient(passengerId: $passengerId, displayName: $displayName, affiliatedAt: $affiliatedAt, source: $source)';
}


}

/// @nodoc
abstract mixin class _$DriverClientCopyWith<$Res> implements $DriverClientCopyWith<$Res> {
  factory _$DriverClientCopyWith(_DriverClient value, $Res Function(_DriverClient) _then) = __$DriverClientCopyWithImpl;
@override @useResult
$Res call({
 String passengerId, String displayName, DateTime affiliatedAt, AffiliationSource source
});




}
/// @nodoc
class __$DriverClientCopyWithImpl<$Res>
    implements _$DriverClientCopyWith<$Res> {
  __$DriverClientCopyWithImpl(this._self, this._then);

  final _DriverClient _self;
  final $Res Function(_DriverClient) _then;

/// Create a copy of DriverClient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? passengerId = null,Object? displayName = null,Object? affiliatedAt = null,Object? source = null,}) {
  return _then(_DriverClient(
passengerId: null == passengerId ? _self.passengerId : passengerId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,affiliatedAt: null == affiliatedAt ? _self.affiliatedAt : affiliatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AffiliationSource,
  ));
}


}


/// @nodoc
mixin _$FareQuote {

 int get distanceM; int get durationS; int get suggestedFareMinor; String get currency;/// 008: tarifa sin descuento; con [preferentialDiscountPct] > 0, [suggestedFareMinor] ya lo aplica.
 int? get listFareMinor; int get preferentialDiscountPct;
/// Create a copy of FareQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FareQuoteCopyWith<FareQuote> get copyWith => _$FareQuoteCopyWithImpl<FareQuote>(this as FareQuote, _$identity);

  /// Serializes this FareQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FareQuote&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.suggestedFareMinor, suggestedFareMinor) || other.suggestedFareMinor == suggestedFareMinor)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.listFareMinor, listFareMinor) || other.listFareMinor == listFareMinor)&&(identical(other.preferentialDiscountPct, preferentialDiscountPct) || other.preferentialDiscountPct == preferentialDiscountPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,distanceM,durationS,suggestedFareMinor,currency,listFareMinor,preferentialDiscountPct);

@override
String toString() {
  return 'FareQuote(distanceM: $distanceM, durationS: $durationS, suggestedFareMinor: $suggestedFareMinor, currency: $currency, listFareMinor: $listFareMinor, preferentialDiscountPct: $preferentialDiscountPct)';
}


}

/// @nodoc
abstract mixin class $FareQuoteCopyWith<$Res>  {
  factory $FareQuoteCopyWith(FareQuote value, $Res Function(FareQuote) _then) = _$FareQuoteCopyWithImpl;
@useResult
$Res call({
 int distanceM, int durationS, int suggestedFareMinor, String currency, int? listFareMinor, int preferentialDiscountPct
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
@pragma('vm:prefer-inline') @override $Res call({Object? distanceM = null,Object? durationS = null,Object? suggestedFareMinor = null,Object? currency = null,Object? listFareMinor = freezed,Object? preferentialDiscountPct = null,}) {
  return _then(_self.copyWith(
distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int,durationS: null == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as int,suggestedFareMinor: null == suggestedFareMinor ? _self.suggestedFareMinor : suggestedFareMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,listFareMinor: freezed == listFareMinor ? _self.listFareMinor : listFareMinor // ignore: cast_nullable_to_non_nullable
as int?,preferentialDiscountPct: null == preferentialDiscountPct ? _self.preferentialDiscountPct : preferentialDiscountPct // ignore: cast_nullable_to_non_nullable
as int,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int distanceM,  int durationS,  int suggestedFareMinor,  String currency,  int? listFareMinor,  int preferentialDiscountPct)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FareQuote() when $default != null:
return $default(_that.distanceM,_that.durationS,_that.suggestedFareMinor,_that.currency,_that.listFareMinor,_that.preferentialDiscountPct);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int distanceM,  int durationS,  int suggestedFareMinor,  String currency,  int? listFareMinor,  int preferentialDiscountPct)  $default,) {final _that = this;
switch (_that) {
case _FareQuote():
return $default(_that.distanceM,_that.durationS,_that.suggestedFareMinor,_that.currency,_that.listFareMinor,_that.preferentialDiscountPct);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int distanceM,  int durationS,  int suggestedFareMinor,  String currency,  int? listFareMinor,  int preferentialDiscountPct)?  $default,) {final _that = this;
switch (_that) {
case _FareQuote() when $default != null:
return $default(_that.distanceM,_that.durationS,_that.suggestedFareMinor,_that.currency,_that.listFareMinor,_that.preferentialDiscountPct);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FareQuote implements FareQuote {
  const _FareQuote({required this.distanceM, required this.durationS, required this.suggestedFareMinor, required this.currency, this.listFareMinor, this.preferentialDiscountPct = 0});
  factory _FareQuote.fromJson(Map<String, dynamic> json) => _$FareQuoteFromJson(json);

@override final  int distanceM;
@override final  int durationS;
@override final  int suggestedFareMinor;
@override final  String currency;
/// 008: tarifa sin descuento; con [preferentialDiscountPct] > 0, [suggestedFareMinor] ya lo aplica.
@override final  int? listFareMinor;
@override@JsonKey() final  int preferentialDiscountPct;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FareQuote&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.suggestedFareMinor, suggestedFareMinor) || other.suggestedFareMinor == suggestedFareMinor)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.listFareMinor, listFareMinor) || other.listFareMinor == listFareMinor)&&(identical(other.preferentialDiscountPct, preferentialDiscountPct) || other.preferentialDiscountPct == preferentialDiscountPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,distanceM,durationS,suggestedFareMinor,currency,listFareMinor,preferentialDiscountPct);

@override
String toString() {
  return 'FareQuote(distanceM: $distanceM, durationS: $durationS, suggestedFareMinor: $suggestedFareMinor, currency: $currency, listFareMinor: $listFareMinor, preferentialDiscountPct: $preferentialDiscountPct)';
}


}

/// @nodoc
abstract mixin class _$FareQuoteCopyWith<$Res> implements $FareQuoteCopyWith<$Res> {
  factory _$FareQuoteCopyWith(_FareQuote value, $Res Function(_FareQuote) _then) = __$FareQuoteCopyWithImpl;
@override @useResult
$Res call({
 int distanceM, int durationS, int suggestedFareMinor, String currency, int? listFareMinor, int preferentialDiscountPct
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
@override @pragma('vm:prefer-inline') $Res call({Object? distanceM = null,Object? durationS = null,Object? suggestedFareMinor = null,Object? currency = null,Object? listFareMinor = freezed,Object? preferentialDiscountPct = null,}) {
  return _then(_FareQuote(
distanceM: null == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int,durationS: null == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as int,suggestedFareMinor: null == suggestedFareMinor ? _self.suggestedFareMinor : suggestedFareMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,listFareMinor: freezed == listFareMinor ? _self.listFareMinor : listFareMinor // ignore: cast_nullable_to_non_nullable
as int?,preferentialDiscountPct: null == preferentialDiscountPct ? _self.preferentialDiscountPct : preferentialDiscountPct // ignore: cast_nullable_to_non_nullable
as int,
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

 String get id; TripStatus get status; String get passengerId; String get driverId; GeoPoint get pickup; GeoPoint get dropoff; int get distanceM; int get durationS; String get currency; int get suggestedFareMinor; int? get agreedFareMinor; int? get driverPayoutMinor; int get platformCommissionMinor; FareProposal? get openProposal; DateTime? get offerExpiresAt; DateTime? get negotiationExpiresAt; String? get cancelReason; TripDispatch get dispatch; String? get requestedDriverId;/// Nombre del conductor actual; cambia si la solicitud pasa a un compañero.
 String? get driverName; String? get cooperativeId; String? get cooperativeName; bool get allowDelegation; int get handoverCount; bool get canDelegate; int? get listFareMinor; int get preferentialDiscountPct;
/// Create a copy of Trip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripCopyWith<Trip> get copyWith => _$TripCopyWithImpl<Trip>(this as Trip, _$identity);

  /// Serializes this Trip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.suggestedFareMinor, suggestedFareMinor) || other.suggestedFareMinor == suggestedFareMinor)&&(identical(other.agreedFareMinor, agreedFareMinor) || other.agreedFareMinor == agreedFareMinor)&&(identical(other.driverPayoutMinor, driverPayoutMinor) || other.driverPayoutMinor == driverPayoutMinor)&&(identical(other.platformCommissionMinor, platformCommissionMinor) || other.platformCommissionMinor == platformCommissionMinor)&&(identical(other.openProposal, openProposal) || other.openProposal == openProposal)&&(identical(other.offerExpiresAt, offerExpiresAt) || other.offerExpiresAt == offerExpiresAt)&&(identical(other.negotiationExpiresAt, negotiationExpiresAt) || other.negotiationExpiresAt == negotiationExpiresAt)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason)&&(identical(other.dispatch, dispatch) || other.dispatch == dispatch)&&(identical(other.requestedDriverId, requestedDriverId) || other.requestedDriverId == requestedDriverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.cooperativeId, cooperativeId) || other.cooperativeId == cooperativeId)&&(identical(other.cooperativeName, cooperativeName) || other.cooperativeName == cooperativeName)&&(identical(other.allowDelegation, allowDelegation) || other.allowDelegation == allowDelegation)&&(identical(other.handoverCount, handoverCount) || other.handoverCount == handoverCount)&&(identical(other.canDelegate, canDelegate) || other.canDelegate == canDelegate)&&(identical(other.listFareMinor, listFareMinor) || other.listFareMinor == listFareMinor)&&(identical(other.preferentialDiscountPct, preferentialDiscountPct) || other.preferentialDiscountPct == preferentialDiscountPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,status,passengerId,driverId,pickup,dropoff,distanceM,durationS,currency,suggestedFareMinor,agreedFareMinor,driverPayoutMinor,platformCommissionMinor,openProposal,offerExpiresAt,negotiationExpiresAt,cancelReason,dispatch,requestedDriverId,driverName,cooperativeId,cooperativeName,allowDelegation,handoverCount,canDelegate,listFareMinor,preferentialDiscountPct]);

@override
String toString() {
  return 'Trip(id: $id, status: $status, passengerId: $passengerId, driverId: $driverId, pickup: $pickup, dropoff: $dropoff, distanceM: $distanceM, durationS: $durationS, currency: $currency, suggestedFareMinor: $suggestedFareMinor, agreedFareMinor: $agreedFareMinor, driverPayoutMinor: $driverPayoutMinor, platformCommissionMinor: $platformCommissionMinor, openProposal: $openProposal, offerExpiresAt: $offerExpiresAt, negotiationExpiresAt: $negotiationExpiresAt, cancelReason: $cancelReason, dispatch: $dispatch, requestedDriverId: $requestedDriverId, driverName: $driverName, cooperativeId: $cooperativeId, cooperativeName: $cooperativeName, allowDelegation: $allowDelegation, handoverCount: $handoverCount, canDelegate: $canDelegate, listFareMinor: $listFareMinor, preferentialDiscountPct: $preferentialDiscountPct)';
}


}

/// @nodoc
abstract mixin class $TripCopyWith<$Res>  {
  factory $TripCopyWith(Trip value, $Res Function(Trip) _then) = _$TripCopyWithImpl;
@useResult
$Res call({
 String id, TripStatus status, String passengerId, String driverId, GeoPoint pickup, GeoPoint dropoff, int distanceM, int durationS, String currency, int suggestedFareMinor, int? agreedFareMinor, int? driverPayoutMinor, int platformCommissionMinor, FareProposal? openProposal, DateTime? offerExpiresAt, DateTime? negotiationExpiresAt, String? cancelReason, TripDispatch dispatch, String? requestedDriverId, String? driverName, String? cooperativeId, String? cooperativeName, bool allowDelegation, int handoverCount, bool canDelegate, int? listFareMinor, int preferentialDiscountPct
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? passengerId = null,Object? driverId = null,Object? pickup = null,Object? dropoff = null,Object? distanceM = null,Object? durationS = null,Object? currency = null,Object? suggestedFareMinor = null,Object? agreedFareMinor = freezed,Object? driverPayoutMinor = freezed,Object? platformCommissionMinor = null,Object? openProposal = freezed,Object? offerExpiresAt = freezed,Object? negotiationExpiresAt = freezed,Object? cancelReason = freezed,Object? dispatch = null,Object? requestedDriverId = freezed,Object? driverName = freezed,Object? cooperativeId = freezed,Object? cooperativeName = freezed,Object? allowDelegation = null,Object? handoverCount = null,Object? canDelegate = null,Object? listFareMinor = freezed,Object? preferentialDiscountPct = null,}) {
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
as String?,dispatch: null == dispatch ? _self.dispatch : dispatch // ignore: cast_nullable_to_non_nullable
as TripDispatch,requestedDriverId: freezed == requestedDriverId ? _self.requestedDriverId : requestedDriverId // ignore: cast_nullable_to_non_nullable
as String?,driverName: freezed == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String?,cooperativeId: freezed == cooperativeId ? _self.cooperativeId : cooperativeId // ignore: cast_nullable_to_non_nullable
as String?,cooperativeName: freezed == cooperativeName ? _self.cooperativeName : cooperativeName // ignore: cast_nullable_to_non_nullable
as String?,allowDelegation: null == allowDelegation ? _self.allowDelegation : allowDelegation // ignore: cast_nullable_to_non_nullable
as bool,handoverCount: null == handoverCount ? _self.handoverCount : handoverCount // ignore: cast_nullable_to_non_nullable
as int,canDelegate: null == canDelegate ? _self.canDelegate : canDelegate // ignore: cast_nullable_to_non_nullable
as bool,listFareMinor: freezed == listFareMinor ? _self.listFareMinor : listFareMinor // ignore: cast_nullable_to_non_nullable
as int?,preferentialDiscountPct: null == preferentialDiscountPct ? _self.preferentialDiscountPct : preferentialDiscountPct // ignore: cast_nullable_to_non_nullable
as int,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  TripStatus status,  String passengerId,  String driverId,  GeoPoint pickup,  GeoPoint dropoff,  int distanceM,  int durationS,  String currency,  int suggestedFareMinor,  int? agreedFareMinor,  int? driverPayoutMinor,  int platformCommissionMinor,  FareProposal? openProposal,  DateTime? offerExpiresAt,  DateTime? negotiationExpiresAt,  String? cancelReason,  TripDispatch dispatch,  String? requestedDriverId,  String? driverName,  String? cooperativeId,  String? cooperativeName,  bool allowDelegation,  int handoverCount,  bool canDelegate,  int? listFareMinor,  int preferentialDiscountPct)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.status,_that.passengerId,_that.driverId,_that.pickup,_that.dropoff,_that.distanceM,_that.durationS,_that.currency,_that.suggestedFareMinor,_that.agreedFareMinor,_that.driverPayoutMinor,_that.platformCommissionMinor,_that.openProposal,_that.offerExpiresAt,_that.negotiationExpiresAt,_that.cancelReason,_that.dispatch,_that.requestedDriverId,_that.driverName,_that.cooperativeId,_that.cooperativeName,_that.allowDelegation,_that.handoverCount,_that.canDelegate,_that.listFareMinor,_that.preferentialDiscountPct);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  TripStatus status,  String passengerId,  String driverId,  GeoPoint pickup,  GeoPoint dropoff,  int distanceM,  int durationS,  String currency,  int suggestedFareMinor,  int? agreedFareMinor,  int? driverPayoutMinor,  int platformCommissionMinor,  FareProposal? openProposal,  DateTime? offerExpiresAt,  DateTime? negotiationExpiresAt,  String? cancelReason,  TripDispatch dispatch,  String? requestedDriverId,  String? driverName,  String? cooperativeId,  String? cooperativeName,  bool allowDelegation,  int handoverCount,  bool canDelegate,  int? listFareMinor,  int preferentialDiscountPct)  $default,) {final _that = this;
switch (_that) {
case _Trip():
return $default(_that.id,_that.status,_that.passengerId,_that.driverId,_that.pickup,_that.dropoff,_that.distanceM,_that.durationS,_that.currency,_that.suggestedFareMinor,_that.agreedFareMinor,_that.driverPayoutMinor,_that.platformCommissionMinor,_that.openProposal,_that.offerExpiresAt,_that.negotiationExpiresAt,_that.cancelReason,_that.dispatch,_that.requestedDriverId,_that.driverName,_that.cooperativeId,_that.cooperativeName,_that.allowDelegation,_that.handoverCount,_that.canDelegate,_that.listFareMinor,_that.preferentialDiscountPct);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  TripStatus status,  String passengerId,  String driverId,  GeoPoint pickup,  GeoPoint dropoff,  int distanceM,  int durationS,  String currency,  int suggestedFareMinor,  int? agreedFareMinor,  int? driverPayoutMinor,  int platformCommissionMinor,  FareProposal? openProposal,  DateTime? offerExpiresAt,  DateTime? negotiationExpiresAt,  String? cancelReason,  TripDispatch dispatch,  String? requestedDriverId,  String? driverName,  String? cooperativeId,  String? cooperativeName,  bool allowDelegation,  int handoverCount,  bool canDelegate,  int? listFareMinor,  int preferentialDiscountPct)?  $default,) {final _that = this;
switch (_that) {
case _Trip() when $default != null:
return $default(_that.id,_that.status,_that.passengerId,_that.driverId,_that.pickup,_that.dropoff,_that.distanceM,_that.durationS,_that.currency,_that.suggestedFareMinor,_that.agreedFareMinor,_that.driverPayoutMinor,_that.platformCommissionMinor,_that.openProposal,_that.offerExpiresAt,_that.negotiationExpiresAt,_that.cancelReason,_that.dispatch,_that.requestedDriverId,_that.driverName,_that.cooperativeId,_that.cooperativeName,_that.allowDelegation,_that.handoverCount,_that.canDelegate,_that.listFareMinor,_that.preferentialDiscountPct);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Trip implements Trip {
  const _Trip({required this.id, required this.status, required this.passengerId, required this.driverId, required this.pickup, required this.dropoff, required this.distanceM, required this.durationS, required this.currency, required this.suggestedFareMinor, this.agreedFareMinor, this.driverPayoutMinor, this.platformCommissionMinor = 0, this.openProposal, this.offerExpiresAt, this.negotiationExpiresAt, this.cancelReason, this.dispatch = TripDispatch.chosenDriver, this.requestedDriverId, this.driverName, this.cooperativeId, this.cooperativeName, this.allowDelegation = false, this.handoverCount = 0, this.canDelegate = false, this.listFareMinor, this.preferentialDiscountPct = 0});
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
@override@JsonKey() final  TripDispatch dispatch;
@override final  String? requestedDriverId;
/// Nombre del conductor actual; cambia si la solicitud pasa a un compañero.
@override final  String? driverName;
@override final  String? cooperativeId;
@override final  String? cooperativeName;
@override@JsonKey() final  bool allowDelegation;
@override@JsonKey() final  int handoverCount;
@override@JsonKey() final  bool canDelegate;
@override final  int? listFareMinor;
@override@JsonKey() final  int preferentialDiscountPct;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trip&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.passengerId, passengerId) || other.passengerId == passengerId)&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.pickup, pickup) || other.pickup == pickup)&&(identical(other.dropoff, dropoff) || other.dropoff == dropoff)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.suggestedFareMinor, suggestedFareMinor) || other.suggestedFareMinor == suggestedFareMinor)&&(identical(other.agreedFareMinor, agreedFareMinor) || other.agreedFareMinor == agreedFareMinor)&&(identical(other.driverPayoutMinor, driverPayoutMinor) || other.driverPayoutMinor == driverPayoutMinor)&&(identical(other.platformCommissionMinor, platformCommissionMinor) || other.platformCommissionMinor == platformCommissionMinor)&&(identical(other.openProposal, openProposal) || other.openProposal == openProposal)&&(identical(other.offerExpiresAt, offerExpiresAt) || other.offerExpiresAt == offerExpiresAt)&&(identical(other.negotiationExpiresAt, negotiationExpiresAt) || other.negotiationExpiresAt == negotiationExpiresAt)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason)&&(identical(other.dispatch, dispatch) || other.dispatch == dispatch)&&(identical(other.requestedDriverId, requestedDriverId) || other.requestedDriverId == requestedDriverId)&&(identical(other.driverName, driverName) || other.driverName == driverName)&&(identical(other.cooperativeId, cooperativeId) || other.cooperativeId == cooperativeId)&&(identical(other.cooperativeName, cooperativeName) || other.cooperativeName == cooperativeName)&&(identical(other.allowDelegation, allowDelegation) || other.allowDelegation == allowDelegation)&&(identical(other.handoverCount, handoverCount) || other.handoverCount == handoverCount)&&(identical(other.canDelegate, canDelegate) || other.canDelegate == canDelegate)&&(identical(other.listFareMinor, listFareMinor) || other.listFareMinor == listFareMinor)&&(identical(other.preferentialDiscountPct, preferentialDiscountPct) || other.preferentialDiscountPct == preferentialDiscountPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,status,passengerId,driverId,pickup,dropoff,distanceM,durationS,currency,suggestedFareMinor,agreedFareMinor,driverPayoutMinor,platformCommissionMinor,openProposal,offerExpiresAt,negotiationExpiresAt,cancelReason,dispatch,requestedDriverId,driverName,cooperativeId,cooperativeName,allowDelegation,handoverCount,canDelegate,listFareMinor,preferentialDiscountPct]);

@override
String toString() {
  return 'Trip(id: $id, status: $status, passengerId: $passengerId, driverId: $driverId, pickup: $pickup, dropoff: $dropoff, distanceM: $distanceM, durationS: $durationS, currency: $currency, suggestedFareMinor: $suggestedFareMinor, agreedFareMinor: $agreedFareMinor, driverPayoutMinor: $driverPayoutMinor, platformCommissionMinor: $platformCommissionMinor, openProposal: $openProposal, offerExpiresAt: $offerExpiresAt, negotiationExpiresAt: $negotiationExpiresAt, cancelReason: $cancelReason, dispatch: $dispatch, requestedDriverId: $requestedDriverId, driverName: $driverName, cooperativeId: $cooperativeId, cooperativeName: $cooperativeName, allowDelegation: $allowDelegation, handoverCount: $handoverCount, canDelegate: $canDelegate, listFareMinor: $listFareMinor, preferentialDiscountPct: $preferentialDiscountPct)';
}


}

/// @nodoc
abstract mixin class _$TripCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$TripCopyWith(_Trip value, $Res Function(_Trip) _then) = __$TripCopyWithImpl;
@override @useResult
$Res call({
 String id, TripStatus status, String passengerId, String driverId, GeoPoint pickup, GeoPoint dropoff, int distanceM, int durationS, String currency, int suggestedFareMinor, int? agreedFareMinor, int? driverPayoutMinor, int platformCommissionMinor, FareProposal? openProposal, DateTime? offerExpiresAt, DateTime? negotiationExpiresAt, String? cancelReason, TripDispatch dispatch, String? requestedDriverId, String? driverName, String? cooperativeId, String? cooperativeName, bool allowDelegation, int handoverCount, bool canDelegate, int? listFareMinor, int preferentialDiscountPct
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? passengerId = null,Object? driverId = null,Object? pickup = null,Object? dropoff = null,Object? distanceM = null,Object? durationS = null,Object? currency = null,Object? suggestedFareMinor = null,Object? agreedFareMinor = freezed,Object? driverPayoutMinor = freezed,Object? platformCommissionMinor = null,Object? openProposal = freezed,Object? offerExpiresAt = freezed,Object? negotiationExpiresAt = freezed,Object? cancelReason = freezed,Object? dispatch = null,Object? requestedDriverId = freezed,Object? driverName = freezed,Object? cooperativeId = freezed,Object? cooperativeName = freezed,Object? allowDelegation = null,Object? handoverCount = null,Object? canDelegate = null,Object? listFareMinor = freezed,Object? preferentialDiscountPct = null,}) {
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
as String?,dispatch: null == dispatch ? _self.dispatch : dispatch // ignore: cast_nullable_to_non_nullable
as TripDispatch,requestedDriverId: freezed == requestedDriverId ? _self.requestedDriverId : requestedDriverId // ignore: cast_nullable_to_non_nullable
as String?,driverName: freezed == driverName ? _self.driverName : driverName // ignore: cast_nullable_to_non_nullable
as String?,cooperativeId: freezed == cooperativeId ? _self.cooperativeId : cooperativeId // ignore: cast_nullable_to_non_nullable
as String?,cooperativeName: freezed == cooperativeName ? _self.cooperativeName : cooperativeName // ignore: cast_nullable_to_non_nullable
as String?,allowDelegation: null == allowDelegation ? _self.allowDelegation : allowDelegation // ignore: cast_nullable_to_non_nullable
as bool,handoverCount: null == handoverCount ? _self.handoverCount : handoverCount // ignore: cast_nullable_to_non_nullable
as int,canDelegate: null == canDelegate ? _self.canDelegate : canDelegate // ignore: cast_nullable_to_non_nullable
as bool,listFareMinor: freezed == listFareMinor ? _self.listFareMinor : listFareMinor // ignore: cast_nullable_to_non_nullable
as int?,preferentialDiscountPct: null == preferentialDiscountPct ? _self.preferentialDiscountPct : preferentialDiscountPct // ignore: cast_nullable_to_non_nullable
as int,
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


/// @nodoc
mixin _$PttCredentials {

 String get url; String get token; String get room; DateTime? get closesAt;
/// Create a copy of PttCredentials
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PttCredentialsCopyWith<PttCredentials> get copyWith => _$PttCredentialsCopyWithImpl<PttCredentials>(this as PttCredentials, _$identity);

  /// Serializes this PttCredentials to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PttCredentials&&(identical(other.url, url) || other.url == url)&&(identical(other.token, token) || other.token == token)&&(identical(other.room, room) || other.room == room)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,token,room,closesAt);

@override
String toString() {
  return 'PttCredentials(url: $url, token: $token, room: $room, closesAt: $closesAt)';
}


}

/// @nodoc
abstract mixin class $PttCredentialsCopyWith<$Res>  {
  factory $PttCredentialsCopyWith(PttCredentials value, $Res Function(PttCredentials) _then) = _$PttCredentialsCopyWithImpl;
@useResult
$Res call({
 String url, String token, String room, DateTime? closesAt
});




}
/// @nodoc
class _$PttCredentialsCopyWithImpl<$Res>
    implements $PttCredentialsCopyWith<$Res> {
  _$PttCredentialsCopyWithImpl(this._self, this._then);

  final PttCredentials _self;
  final $Res Function(PttCredentials) _then;

/// Create a copy of PttCredentials
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? token = null,Object? room = null,Object? closesAt = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PttCredentials].
extension PttCredentialsPatterns on PttCredentials {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PttCredentials value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PttCredentials() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PttCredentials value)  $default,){
final _that = this;
switch (_that) {
case _PttCredentials():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PttCredentials value)?  $default,){
final _that = this;
switch (_that) {
case _PttCredentials() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String token,  String room,  DateTime? closesAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PttCredentials() when $default != null:
return $default(_that.url,_that.token,_that.room,_that.closesAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String token,  String room,  DateTime? closesAt)  $default,) {final _that = this;
switch (_that) {
case _PttCredentials():
return $default(_that.url,_that.token,_that.room,_that.closesAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String token,  String room,  DateTime? closesAt)?  $default,) {final _that = this;
switch (_that) {
case _PttCredentials() when $default != null:
return $default(_that.url,_that.token,_that.room,_that.closesAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PttCredentials implements PttCredentials {
  const _PttCredentials({required this.url, required this.token, required this.room, this.closesAt});
  factory _PttCredentials.fromJson(Map<String, dynamic> json) => _$PttCredentialsFromJson(json);

@override final  String url;
@override final  String token;
@override final  String room;
@override final  DateTime? closesAt;

/// Create a copy of PttCredentials
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PttCredentialsCopyWith<_PttCredentials> get copyWith => __$PttCredentialsCopyWithImpl<_PttCredentials>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PttCredentialsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PttCredentials&&(identical(other.url, url) || other.url == url)&&(identical(other.token, token) || other.token == token)&&(identical(other.room, room) || other.room == room)&&(identical(other.closesAt, closesAt) || other.closesAt == closesAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,token,room,closesAt);

@override
String toString() {
  return 'PttCredentials(url: $url, token: $token, room: $room, closesAt: $closesAt)';
}


}

/// @nodoc
abstract mixin class _$PttCredentialsCopyWith<$Res> implements $PttCredentialsCopyWith<$Res> {
  factory _$PttCredentialsCopyWith(_PttCredentials value, $Res Function(_PttCredentials) _then) = __$PttCredentialsCopyWithImpl;
@override @useResult
$Res call({
 String url, String token, String room, DateTime? closesAt
});




}
/// @nodoc
class __$PttCredentialsCopyWithImpl<$Res>
    implements _$PttCredentialsCopyWith<$Res> {
  __$PttCredentialsCopyWithImpl(this._self, this._then);

  final _PttCredentials _self;
  final $Res Function(_PttCredentials) _then;

/// Create a copy of PttCredentials
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? token = null,Object? room = null,Object? closesAt = freezed,}) {
  return _then(_PttCredentials(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,closesAt: freezed == closesAt ? _self.closesAt : closesAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
