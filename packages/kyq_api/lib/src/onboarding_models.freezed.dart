// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Vehicle {

 String? get plate; String? get brand; String? get model; String? get color; int? get year;
/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleCopyWith<Vehicle> get copyWith => _$VehicleCopyWithImpl<Vehicle>(this as Vehicle, _$identity);

  /// Serializes this Vehicle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Vehicle&&(identical(other.plate, plate) || other.plate == plate)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.model, model) || other.model == model)&&(identical(other.color, color) || other.color == color)&&(identical(other.year, year) || other.year == year));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plate,brand,model,color,year);

@override
String toString() {
  return 'Vehicle(plate: $plate, brand: $brand, model: $model, color: $color, year: $year)';
}


}

/// @nodoc
abstract mixin class $VehicleCopyWith<$Res>  {
  factory $VehicleCopyWith(Vehicle value, $Res Function(Vehicle) _then) = _$VehicleCopyWithImpl;
@useResult
$Res call({
 String? plate, String? brand, String? model, String? color, int? year
});




}
/// @nodoc
class _$VehicleCopyWithImpl<$Res>
    implements $VehicleCopyWith<$Res> {
  _$VehicleCopyWithImpl(this._self, this._then);

  final Vehicle _self;
  final $Res Function(Vehicle) _then;

/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plate = freezed,Object? brand = freezed,Object? model = freezed,Object? color = freezed,Object? year = freezed,}) {
  return _then(_self.copyWith(
plate: freezed == plate ? _self.plate : plate // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Vehicle].
extension VehiclePatterns on Vehicle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Vehicle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Vehicle value)  $default,){
final _that = this;
switch (_that) {
case _Vehicle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Vehicle value)?  $default,){
final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? plate,  String? brand,  String? model,  String? color,  int? year)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
return $default(_that.plate,_that.brand,_that.model,_that.color,_that.year);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? plate,  String? brand,  String? model,  String? color,  int? year)  $default,) {final _that = this;
switch (_that) {
case _Vehicle():
return $default(_that.plate,_that.brand,_that.model,_that.color,_that.year);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? plate,  String? brand,  String? model,  String? color,  int? year)?  $default,) {final _that = this;
switch (_that) {
case _Vehicle() when $default != null:
return $default(_that.plate,_that.brand,_that.model,_that.color,_that.year);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Vehicle implements Vehicle {
  const _Vehicle({this.plate, this.brand, this.model, this.color, this.year});
  factory _Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);

@override final  String? plate;
@override final  String? brand;
@override final  String? model;
@override final  String? color;
@override final  int? year;

/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleCopyWith<_Vehicle> get copyWith => __$VehicleCopyWithImpl<_Vehicle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Vehicle&&(identical(other.plate, plate) || other.plate == plate)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.model, model) || other.model == model)&&(identical(other.color, color) || other.color == color)&&(identical(other.year, year) || other.year == year));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plate,brand,model,color,year);

@override
String toString() {
  return 'Vehicle(plate: $plate, brand: $brand, model: $model, color: $color, year: $year)';
}


}

/// @nodoc
abstract mixin class _$VehicleCopyWith<$Res> implements $VehicleCopyWith<$Res> {
  factory _$VehicleCopyWith(_Vehicle value, $Res Function(_Vehicle) _then) = __$VehicleCopyWithImpl;
@override @useResult
$Res call({
 String? plate, String? brand, String? model, String? color, int? year
});




}
/// @nodoc
class __$VehicleCopyWithImpl<$Res>
    implements _$VehicleCopyWith<$Res> {
  __$VehicleCopyWithImpl(this._self, this._then);

  final _Vehicle _self;
  final $Res Function(_Vehicle) _then;

/// Create a copy of Vehicle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plate = freezed,Object? brand = freezed,Object? model = freezed,Object? color = freezed,Object? year = freezed,}) {
  return _then(_Vehicle(
plate: freezed == plate ? _self.plate : plate // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$DocumentPhoto {

 DocSide get side; String get url;
/// Create a copy of DocumentPhoto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentPhotoCopyWith<DocumentPhoto> get copyWith => _$DocumentPhotoCopyWithImpl<DocumentPhoto>(this as DocumentPhoto, _$identity);

  /// Serializes this DocumentPhoto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentPhoto&&(identical(other.side, side) || other.side == side)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,side,url);

@override
String toString() {
  return 'DocumentPhoto(side: $side, url: $url)';
}


}

/// @nodoc
abstract mixin class $DocumentPhotoCopyWith<$Res>  {
  factory $DocumentPhotoCopyWith(DocumentPhoto value, $Res Function(DocumentPhoto) _then) = _$DocumentPhotoCopyWithImpl;
@useResult
$Res call({
 DocSide side, String url
});




}
/// @nodoc
class _$DocumentPhotoCopyWithImpl<$Res>
    implements $DocumentPhotoCopyWith<$Res> {
  _$DocumentPhotoCopyWithImpl(this._self, this._then);

  final DocumentPhoto _self;
  final $Res Function(DocumentPhoto) _then;

/// Create a copy of DocumentPhoto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? side = null,Object? url = null,}) {
  return _then(_self.copyWith(
side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as DocSide,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentPhoto].
extension DocumentPhotoPatterns on DocumentPhoto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentPhoto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentPhoto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentPhoto value)  $default,){
final _that = this;
switch (_that) {
case _DocumentPhoto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentPhoto value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentPhoto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DocSide side,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentPhoto() when $default != null:
return $default(_that.side,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DocSide side,  String url)  $default,) {final _that = this;
switch (_that) {
case _DocumentPhoto():
return $default(_that.side,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DocSide side,  String url)?  $default,) {final _that = this;
switch (_that) {
case _DocumentPhoto() when $default != null:
return $default(_that.side,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentPhoto implements DocumentPhoto {
  const _DocumentPhoto({required this.side, required this.url});
  factory _DocumentPhoto.fromJson(Map<String, dynamic> json) => _$DocumentPhotoFromJson(json);

@override final  DocSide side;
@override final  String url;

/// Create a copy of DocumentPhoto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentPhotoCopyWith<_DocumentPhoto> get copyWith => __$DocumentPhotoCopyWithImpl<_DocumentPhoto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentPhotoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentPhoto&&(identical(other.side, side) || other.side == side)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,side,url);

@override
String toString() {
  return 'DocumentPhoto(side: $side, url: $url)';
}


}

/// @nodoc
abstract mixin class _$DocumentPhotoCopyWith<$Res> implements $DocumentPhotoCopyWith<$Res> {
  factory _$DocumentPhotoCopyWith(_DocumentPhoto value, $Res Function(_DocumentPhoto) _then) = __$DocumentPhotoCopyWithImpl;
@override @useResult
$Res call({
 DocSide side, String url
});




}
/// @nodoc
class __$DocumentPhotoCopyWithImpl<$Res>
    implements _$DocumentPhotoCopyWith<$Res> {
  __$DocumentPhotoCopyWithImpl(this._self, this._then);

  final _DocumentPhoto _self;
  final $Res Function(_DocumentPhoto) _then;

/// Create a copy of DocumentPhoto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? side = null,Object? url = null,}) {
  return _then(_DocumentPhoto(
side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as DocSide,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$KycDocument {

 String get id; DocType get docType; String? get number; DateTime? get expiresAt; DateTime? get exemptUntil; DocumentStatus get status; bool get expired;/// Migrado de 001 o marcador sin fotos: sigue valiendo, pero hay que subir el real.
 bool get legacy; String? get rejectReason; DateTime? get submittedAt; DateTime? get reviewedAt; List<DocumentPhoto> get photos;
/// Create a copy of KycDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KycDocumentCopyWith<KycDocument> get copyWith => _$KycDocumentCopyWithImpl<KycDocument>(this as KycDocument, _$identity);

  /// Serializes this KycDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KycDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.docType, docType) || other.docType == docType)&&(identical(other.number, number) || other.number == number)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.exemptUntil, exemptUntil) || other.exemptUntil == exemptUntil)&&(identical(other.status, status) || other.status == status)&&(identical(other.expired, expired) || other.expired == expired)&&(identical(other.legacy, legacy) || other.legacy == legacy)&&(identical(other.rejectReason, rejectReason) || other.rejectReason == rejectReason)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&const DeepCollectionEquality().equals(other.photos, photos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,docType,number,expiresAt,exemptUntil,status,expired,legacy,rejectReason,submittedAt,reviewedAt,const DeepCollectionEquality().hash(photos));

@override
String toString() {
  return 'KycDocument(id: $id, docType: $docType, number: $number, expiresAt: $expiresAt, exemptUntil: $exemptUntil, status: $status, expired: $expired, legacy: $legacy, rejectReason: $rejectReason, submittedAt: $submittedAt, reviewedAt: $reviewedAt, photos: $photos)';
}


}

/// @nodoc
abstract mixin class $KycDocumentCopyWith<$Res>  {
  factory $KycDocumentCopyWith(KycDocument value, $Res Function(KycDocument) _then) = _$KycDocumentCopyWithImpl;
@useResult
$Res call({
 String id, DocType docType, String? number, DateTime? expiresAt, DateTime? exemptUntil, DocumentStatus status, bool expired, bool legacy, String? rejectReason, DateTime? submittedAt, DateTime? reviewedAt, List<DocumentPhoto> photos
});




}
/// @nodoc
class _$KycDocumentCopyWithImpl<$Res>
    implements $KycDocumentCopyWith<$Res> {
  _$KycDocumentCopyWithImpl(this._self, this._then);

  final KycDocument _self;
  final $Res Function(KycDocument) _then;

/// Create a copy of KycDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? docType = null,Object? number = freezed,Object? expiresAt = freezed,Object? exemptUntil = freezed,Object? status = null,Object? expired = null,Object? legacy = null,Object? rejectReason = freezed,Object? submittedAt = freezed,Object? reviewedAt = freezed,Object? photos = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,docType: null == docType ? _self.docType : docType // ignore: cast_nullable_to_non_nullable
as DocType,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,exemptUntil: freezed == exemptUntil ? _self.exemptUntil : exemptUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DocumentStatus,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as bool,legacy: null == legacy ? _self.legacy : legacy // ignore: cast_nullable_to_non_nullable
as bool,rejectReason: freezed == rejectReason ? _self.rejectReason : rejectReason // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<DocumentPhoto>,
  ));
}

}


/// Adds pattern-matching-related methods to [KycDocument].
extension KycDocumentPatterns on KycDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KycDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KycDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KycDocument value)  $default,){
final _that = this;
switch (_that) {
case _KycDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KycDocument value)?  $default,){
final _that = this;
switch (_that) {
case _KycDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DocType docType,  String? number,  DateTime? expiresAt,  DateTime? exemptUntil,  DocumentStatus status,  bool expired,  bool legacy,  String? rejectReason,  DateTime? submittedAt,  DateTime? reviewedAt,  List<DocumentPhoto> photos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KycDocument() when $default != null:
return $default(_that.id,_that.docType,_that.number,_that.expiresAt,_that.exemptUntil,_that.status,_that.expired,_that.legacy,_that.rejectReason,_that.submittedAt,_that.reviewedAt,_that.photos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DocType docType,  String? number,  DateTime? expiresAt,  DateTime? exemptUntil,  DocumentStatus status,  bool expired,  bool legacy,  String? rejectReason,  DateTime? submittedAt,  DateTime? reviewedAt,  List<DocumentPhoto> photos)  $default,) {final _that = this;
switch (_that) {
case _KycDocument():
return $default(_that.id,_that.docType,_that.number,_that.expiresAt,_that.exemptUntil,_that.status,_that.expired,_that.legacy,_that.rejectReason,_that.submittedAt,_that.reviewedAt,_that.photos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DocType docType,  String? number,  DateTime? expiresAt,  DateTime? exemptUntil,  DocumentStatus status,  bool expired,  bool legacy,  String? rejectReason,  DateTime? submittedAt,  DateTime? reviewedAt,  List<DocumentPhoto> photos)?  $default,) {final _that = this;
switch (_that) {
case _KycDocument() when $default != null:
return $default(_that.id,_that.docType,_that.number,_that.expiresAt,_that.exemptUntil,_that.status,_that.expired,_that.legacy,_that.rejectReason,_that.submittedAt,_that.reviewedAt,_that.photos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KycDocument implements KycDocument {
  const _KycDocument({required this.id, required this.docType, this.number, this.expiresAt, this.exemptUntil, required this.status, this.expired = false, this.legacy = false, this.rejectReason, this.submittedAt, this.reviewedAt, final  List<DocumentPhoto> photos = const <DocumentPhoto>[]}): _photos = photos;
  factory _KycDocument.fromJson(Map<String, dynamic> json) => _$KycDocumentFromJson(json);

@override final  String id;
@override final  DocType docType;
@override final  String? number;
@override final  DateTime? expiresAt;
@override final  DateTime? exemptUntil;
@override final  DocumentStatus status;
@override@JsonKey() final  bool expired;
/// Migrado de 001 o marcador sin fotos: sigue valiendo, pero hay que subir el real.
@override@JsonKey() final  bool legacy;
@override final  String? rejectReason;
@override final  DateTime? submittedAt;
@override final  DateTime? reviewedAt;
 final  List<DocumentPhoto> _photos;
@override@JsonKey() List<DocumentPhoto> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}


/// Create a copy of KycDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KycDocumentCopyWith<_KycDocument> get copyWith => __$KycDocumentCopyWithImpl<_KycDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KycDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KycDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.docType, docType) || other.docType == docType)&&(identical(other.number, number) || other.number == number)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.exemptUntil, exemptUntil) || other.exemptUntil == exemptUntil)&&(identical(other.status, status) || other.status == status)&&(identical(other.expired, expired) || other.expired == expired)&&(identical(other.legacy, legacy) || other.legacy == legacy)&&(identical(other.rejectReason, rejectReason) || other.rejectReason == rejectReason)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&const DeepCollectionEquality().equals(other._photos, _photos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,docType,number,expiresAt,exemptUntil,status,expired,legacy,rejectReason,submittedAt,reviewedAt,const DeepCollectionEquality().hash(_photos));

@override
String toString() {
  return 'KycDocument(id: $id, docType: $docType, number: $number, expiresAt: $expiresAt, exemptUntil: $exemptUntil, status: $status, expired: $expired, legacy: $legacy, rejectReason: $rejectReason, submittedAt: $submittedAt, reviewedAt: $reviewedAt, photos: $photos)';
}


}

/// @nodoc
abstract mixin class _$KycDocumentCopyWith<$Res> implements $KycDocumentCopyWith<$Res> {
  factory _$KycDocumentCopyWith(_KycDocument value, $Res Function(_KycDocument) _then) = __$KycDocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, DocType docType, String? number, DateTime? expiresAt, DateTime? exemptUntil, DocumentStatus status, bool expired, bool legacy, String? rejectReason, DateTime? submittedAt, DateTime? reviewedAt, List<DocumentPhoto> photos
});




}
/// @nodoc
class __$KycDocumentCopyWithImpl<$Res>
    implements _$KycDocumentCopyWith<$Res> {
  __$KycDocumentCopyWithImpl(this._self, this._then);

  final _KycDocument _self;
  final $Res Function(_KycDocument) _then;

/// Create a copy of KycDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? docType = null,Object? number = freezed,Object? expiresAt = freezed,Object? exemptUntil = freezed,Object? status = null,Object? expired = null,Object? legacy = null,Object? rejectReason = freezed,Object? submittedAt = freezed,Object? reviewedAt = freezed,Object? photos = null,}) {
  return _then(_KycDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,docType: null == docType ? _self.docType : docType // ignore: cast_nullable_to_non_nullable
as DocType,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,exemptUntil: freezed == exemptUntil ? _self.exemptUntil : exemptUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DocumentStatus,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as bool,legacy: null == legacy ? _self.legacy : legacy // ignore: cast_nullable_to_non_nullable
as bool,rejectReason: freezed == rejectReason ? _self.rejectReason : rejectReason // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<DocumentPhoto>,
  ));
}


}


/// @nodoc
mixin _$OnboardingDocument {

 DocType get docType; String? get label; KycDocument? get current; KycDocument? get latest; int get rejectedCount;/// Tras 3 rechazos del mismo documento.
 bool get suggestSupport;
/// Create a copy of OnboardingDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingDocumentCopyWith<OnboardingDocument> get copyWith => _$OnboardingDocumentCopyWithImpl<OnboardingDocument>(this as OnboardingDocument, _$identity);

  /// Serializes this OnboardingDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingDocument&&(identical(other.docType, docType) || other.docType == docType)&&(identical(other.label, label) || other.label == label)&&(identical(other.current, current) || other.current == current)&&(identical(other.latest, latest) || other.latest == latest)&&(identical(other.rejectedCount, rejectedCount) || other.rejectedCount == rejectedCount)&&(identical(other.suggestSupport, suggestSupport) || other.suggestSupport == suggestSupport));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,docType,label,current,latest,rejectedCount,suggestSupport);

@override
String toString() {
  return 'OnboardingDocument(docType: $docType, label: $label, current: $current, latest: $latest, rejectedCount: $rejectedCount, suggestSupport: $suggestSupport)';
}


}

/// @nodoc
abstract mixin class $OnboardingDocumentCopyWith<$Res>  {
  factory $OnboardingDocumentCopyWith(OnboardingDocument value, $Res Function(OnboardingDocument) _then) = _$OnboardingDocumentCopyWithImpl;
@useResult
$Res call({
 DocType docType, String? label, KycDocument? current, KycDocument? latest, int rejectedCount, bool suggestSupport
});


$KycDocumentCopyWith<$Res>? get current;$KycDocumentCopyWith<$Res>? get latest;

}
/// @nodoc
class _$OnboardingDocumentCopyWithImpl<$Res>
    implements $OnboardingDocumentCopyWith<$Res> {
  _$OnboardingDocumentCopyWithImpl(this._self, this._then);

  final OnboardingDocument _self;
  final $Res Function(OnboardingDocument) _then;

/// Create a copy of OnboardingDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docType = null,Object? label = freezed,Object? current = freezed,Object? latest = freezed,Object? rejectedCount = null,Object? suggestSupport = null,}) {
  return _then(_self.copyWith(
docType: null == docType ? _self.docType : docType // ignore: cast_nullable_to_non_nullable
as DocType,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as KycDocument?,latest: freezed == latest ? _self.latest : latest // ignore: cast_nullable_to_non_nullable
as KycDocument?,rejectedCount: null == rejectedCount ? _self.rejectedCount : rejectedCount // ignore: cast_nullable_to_non_nullable
as int,suggestSupport: null == suggestSupport ? _self.suggestSupport : suggestSupport // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of OnboardingDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KycDocumentCopyWith<$Res>? get current {
    if (_self.current == null) {
    return null;
  }

  return $KycDocumentCopyWith<$Res>(_self.current!, (value) {
    return _then(_self.copyWith(current: value));
  });
}/// Create a copy of OnboardingDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KycDocumentCopyWith<$Res>? get latest {
    if (_self.latest == null) {
    return null;
  }

  return $KycDocumentCopyWith<$Res>(_self.latest!, (value) {
    return _then(_self.copyWith(latest: value));
  });
}
}


/// Adds pattern-matching-related methods to [OnboardingDocument].
extension OnboardingDocumentPatterns on OnboardingDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingDocument value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingDocument value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DocType docType,  String? label,  KycDocument? current,  KycDocument? latest,  int rejectedCount,  bool suggestSupport)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingDocument() when $default != null:
return $default(_that.docType,_that.label,_that.current,_that.latest,_that.rejectedCount,_that.suggestSupport);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DocType docType,  String? label,  KycDocument? current,  KycDocument? latest,  int rejectedCount,  bool suggestSupport)  $default,) {final _that = this;
switch (_that) {
case _OnboardingDocument():
return $default(_that.docType,_that.label,_that.current,_that.latest,_that.rejectedCount,_that.suggestSupport);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DocType docType,  String? label,  KycDocument? current,  KycDocument? latest,  int rejectedCount,  bool suggestSupport)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingDocument() when $default != null:
return $default(_that.docType,_that.label,_that.current,_that.latest,_that.rejectedCount,_that.suggestSupport);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OnboardingDocument implements OnboardingDocument {
  const _OnboardingDocument({required this.docType, this.label, this.current, this.latest, this.rejectedCount = 0, this.suggestSupport = false});
  factory _OnboardingDocument.fromJson(Map<String, dynamic> json) => _$OnboardingDocumentFromJson(json);

@override final  DocType docType;
@override final  String? label;
@override final  KycDocument? current;
@override final  KycDocument? latest;
@override@JsonKey() final  int rejectedCount;
/// Tras 3 rechazos del mismo documento.
@override@JsonKey() final  bool suggestSupport;

/// Create a copy of OnboardingDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingDocumentCopyWith<_OnboardingDocument> get copyWith => __$OnboardingDocumentCopyWithImpl<_OnboardingDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OnboardingDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingDocument&&(identical(other.docType, docType) || other.docType == docType)&&(identical(other.label, label) || other.label == label)&&(identical(other.current, current) || other.current == current)&&(identical(other.latest, latest) || other.latest == latest)&&(identical(other.rejectedCount, rejectedCount) || other.rejectedCount == rejectedCount)&&(identical(other.suggestSupport, suggestSupport) || other.suggestSupport == suggestSupport));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,docType,label,current,latest,rejectedCount,suggestSupport);

@override
String toString() {
  return 'OnboardingDocument(docType: $docType, label: $label, current: $current, latest: $latest, rejectedCount: $rejectedCount, suggestSupport: $suggestSupport)';
}


}

/// @nodoc
abstract mixin class _$OnboardingDocumentCopyWith<$Res> implements $OnboardingDocumentCopyWith<$Res> {
  factory _$OnboardingDocumentCopyWith(_OnboardingDocument value, $Res Function(_OnboardingDocument) _then) = __$OnboardingDocumentCopyWithImpl;
@override @useResult
$Res call({
 DocType docType, String? label, KycDocument? current, KycDocument? latest, int rejectedCount, bool suggestSupport
});


@override $KycDocumentCopyWith<$Res>? get current;@override $KycDocumentCopyWith<$Res>? get latest;

}
/// @nodoc
class __$OnboardingDocumentCopyWithImpl<$Res>
    implements _$OnboardingDocumentCopyWith<$Res> {
  __$OnboardingDocumentCopyWithImpl(this._self, this._then);

  final _OnboardingDocument _self;
  final $Res Function(_OnboardingDocument) _then;

/// Create a copy of OnboardingDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docType = null,Object? label = freezed,Object? current = freezed,Object? latest = freezed,Object? rejectedCount = null,Object? suggestSupport = null,}) {
  return _then(_OnboardingDocument(
docType: null == docType ? _self.docType : docType // ignore: cast_nullable_to_non_nullable
as DocType,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as KycDocument?,latest: freezed == latest ? _self.latest : latest // ignore: cast_nullable_to_non_nullable
as KycDocument?,rejectedCount: null == rejectedCount ? _self.rejectedCount : rejectedCount // ignore: cast_nullable_to_non_nullable
as int,suggestSupport: null == suggestSupport ? _self.suggestSupport : suggestSupport // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of OnboardingDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KycDocumentCopyWith<$Res>? get current {
    if (_self.current == null) {
    return null;
  }

  return $KycDocumentCopyWith<$Res>(_self.current!, (value) {
    return _then(_self.copyWith(current: value));
  });
}/// Create a copy of OnboardingDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KycDocumentCopyWith<$Res>? get latest {
    if (_self.latest == null) {
    return null;
  }

  return $KycDocumentCopyWith<$Res>(_self.latest!, (value) {
    return _then(_self.copyWith(latest: value));
  });
}
}


/// @nodoc
mixin _$Onboarding {

 OnboardingStatus get status; Vehicle? get vehicle; List<OnboardingDocument> get documents; List<BlockedDocument> get blockedDocuments; BillingStatus? get subscriptionStatus; DateTime? get paidUntil; bool? get canGoOnline;
/// Create a copy of Onboarding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingCopyWith<Onboarding> get copyWith => _$OnboardingCopyWithImpl<Onboarding>(this as Onboarding, _$identity);

  /// Serializes this Onboarding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Onboarding&&(identical(other.status, status) || other.status == status)&&(identical(other.vehicle, vehicle) || other.vehicle == vehicle)&&const DeepCollectionEquality().equals(other.documents, documents)&&const DeepCollectionEquality().equals(other.blockedDocuments, blockedDocuments)&&(identical(other.subscriptionStatus, subscriptionStatus) || other.subscriptionStatus == subscriptionStatus)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.canGoOnline, canGoOnline) || other.canGoOnline == canGoOnline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,vehicle,const DeepCollectionEquality().hash(documents),const DeepCollectionEquality().hash(blockedDocuments),subscriptionStatus,paidUntil,canGoOnline);

@override
String toString() {
  return 'Onboarding(status: $status, vehicle: $vehicle, documents: $documents, blockedDocuments: $blockedDocuments, subscriptionStatus: $subscriptionStatus, paidUntil: $paidUntil, canGoOnline: $canGoOnline)';
}


}

/// @nodoc
abstract mixin class $OnboardingCopyWith<$Res>  {
  factory $OnboardingCopyWith(Onboarding value, $Res Function(Onboarding) _then) = _$OnboardingCopyWithImpl;
@useResult
$Res call({
 OnboardingStatus status, Vehicle? vehicle, List<OnboardingDocument> documents, List<BlockedDocument> blockedDocuments, BillingStatus? subscriptionStatus, DateTime? paidUntil, bool? canGoOnline
});


$VehicleCopyWith<$Res>? get vehicle;

}
/// @nodoc
class _$OnboardingCopyWithImpl<$Res>
    implements $OnboardingCopyWith<$Res> {
  _$OnboardingCopyWithImpl(this._self, this._then);

  final Onboarding _self;
  final $Res Function(Onboarding) _then;

/// Create a copy of Onboarding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? vehicle = freezed,Object? documents = null,Object? blockedDocuments = null,Object? subscriptionStatus = freezed,Object? paidUntil = freezed,Object? canGoOnline = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OnboardingStatus,vehicle: freezed == vehicle ? _self.vehicle : vehicle // ignore: cast_nullable_to_non_nullable
as Vehicle?,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<OnboardingDocument>,blockedDocuments: null == blockedDocuments ? _self.blockedDocuments : blockedDocuments // ignore: cast_nullable_to_non_nullable
as List<BlockedDocument>,subscriptionStatus: freezed == subscriptionStatus ? _self.subscriptionStatus : subscriptionStatus // ignore: cast_nullable_to_non_nullable
as BillingStatus?,paidUntil: freezed == paidUntil ? _self.paidUntil : paidUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,canGoOnline: freezed == canGoOnline ? _self.canGoOnline : canGoOnline // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of Onboarding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VehicleCopyWith<$Res>? get vehicle {
    if (_self.vehicle == null) {
    return null;
  }

  return $VehicleCopyWith<$Res>(_self.vehicle!, (value) {
    return _then(_self.copyWith(vehicle: value));
  });
}
}


/// Adds pattern-matching-related methods to [Onboarding].
extension OnboardingPatterns on Onboarding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Onboarding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Onboarding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Onboarding value)  $default,){
final _that = this;
switch (_that) {
case _Onboarding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Onboarding value)?  $default,){
final _that = this;
switch (_that) {
case _Onboarding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OnboardingStatus status,  Vehicle? vehicle,  List<OnboardingDocument> documents,  List<BlockedDocument> blockedDocuments,  BillingStatus? subscriptionStatus,  DateTime? paidUntil,  bool? canGoOnline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Onboarding() when $default != null:
return $default(_that.status,_that.vehicle,_that.documents,_that.blockedDocuments,_that.subscriptionStatus,_that.paidUntil,_that.canGoOnline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OnboardingStatus status,  Vehicle? vehicle,  List<OnboardingDocument> documents,  List<BlockedDocument> blockedDocuments,  BillingStatus? subscriptionStatus,  DateTime? paidUntil,  bool? canGoOnline)  $default,) {final _that = this;
switch (_that) {
case _Onboarding():
return $default(_that.status,_that.vehicle,_that.documents,_that.blockedDocuments,_that.subscriptionStatus,_that.paidUntil,_that.canGoOnline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OnboardingStatus status,  Vehicle? vehicle,  List<OnboardingDocument> documents,  List<BlockedDocument> blockedDocuments,  BillingStatus? subscriptionStatus,  DateTime? paidUntil,  bool? canGoOnline)?  $default,) {final _that = this;
switch (_that) {
case _Onboarding() when $default != null:
return $default(_that.status,_that.vehicle,_that.documents,_that.blockedDocuments,_that.subscriptionStatus,_that.paidUntil,_that.canGoOnline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Onboarding implements Onboarding {
  const _Onboarding({required this.status, this.vehicle, final  List<OnboardingDocument> documents = const <OnboardingDocument>[], final  List<BlockedDocument> blockedDocuments = const <BlockedDocument>[], this.subscriptionStatus, this.paidUntil, this.canGoOnline}): _documents = documents,_blockedDocuments = blockedDocuments;
  factory _Onboarding.fromJson(Map<String, dynamic> json) => _$OnboardingFromJson(json);

@override final  OnboardingStatus status;
@override final  Vehicle? vehicle;
 final  List<OnboardingDocument> _documents;
@override@JsonKey() List<OnboardingDocument> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}

 final  List<BlockedDocument> _blockedDocuments;
@override@JsonKey() List<BlockedDocument> get blockedDocuments {
  if (_blockedDocuments is EqualUnmodifiableListView) return _blockedDocuments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blockedDocuments);
}

@override final  BillingStatus? subscriptionStatus;
@override final  DateTime? paidUntil;
@override final  bool? canGoOnline;

/// Create a copy of Onboarding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingCopyWith<_Onboarding> get copyWith => __$OnboardingCopyWithImpl<_Onboarding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OnboardingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Onboarding&&(identical(other.status, status) || other.status == status)&&(identical(other.vehicle, vehicle) || other.vehicle == vehicle)&&const DeepCollectionEquality().equals(other._documents, _documents)&&const DeepCollectionEquality().equals(other._blockedDocuments, _blockedDocuments)&&(identical(other.subscriptionStatus, subscriptionStatus) || other.subscriptionStatus == subscriptionStatus)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.canGoOnline, canGoOnline) || other.canGoOnline == canGoOnline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,vehicle,const DeepCollectionEquality().hash(_documents),const DeepCollectionEquality().hash(_blockedDocuments),subscriptionStatus,paidUntil,canGoOnline);

@override
String toString() {
  return 'Onboarding(status: $status, vehicle: $vehicle, documents: $documents, blockedDocuments: $blockedDocuments, subscriptionStatus: $subscriptionStatus, paidUntil: $paidUntil, canGoOnline: $canGoOnline)';
}


}

/// @nodoc
abstract mixin class _$OnboardingCopyWith<$Res> implements $OnboardingCopyWith<$Res> {
  factory _$OnboardingCopyWith(_Onboarding value, $Res Function(_Onboarding) _then) = __$OnboardingCopyWithImpl;
@override @useResult
$Res call({
 OnboardingStatus status, Vehicle? vehicle, List<OnboardingDocument> documents, List<BlockedDocument> blockedDocuments, BillingStatus? subscriptionStatus, DateTime? paidUntil, bool? canGoOnline
});


@override $VehicleCopyWith<$Res>? get vehicle;

}
/// @nodoc
class __$OnboardingCopyWithImpl<$Res>
    implements _$OnboardingCopyWith<$Res> {
  __$OnboardingCopyWithImpl(this._self, this._then);

  final _Onboarding _self;
  final $Res Function(_Onboarding) _then;

/// Create a copy of Onboarding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? vehicle = freezed,Object? documents = null,Object? blockedDocuments = null,Object? subscriptionStatus = freezed,Object? paidUntil = freezed,Object? canGoOnline = freezed,}) {
  return _then(_Onboarding(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OnboardingStatus,vehicle: freezed == vehicle ? _self.vehicle : vehicle // ignore: cast_nullable_to_non_nullable
as Vehicle?,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<OnboardingDocument>,blockedDocuments: null == blockedDocuments ? _self._blockedDocuments : blockedDocuments // ignore: cast_nullable_to_non_nullable
as List<BlockedDocument>,subscriptionStatus: freezed == subscriptionStatus ? _self.subscriptionStatus : subscriptionStatus // ignore: cast_nullable_to_non_nullable
as BillingStatus?,paidUntil: freezed == paidUntil ? _self.paidUntil : paidUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,canGoOnline: freezed == canGoOnline ? _self.canGoOnline : canGoOnline // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of Onboarding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VehicleCopyWith<$Res>? get vehicle {
    if (_self.vehicle == null) {
    return null;
  }

  return $VehicleCopyWith<$Res>(_self.vehicle!, (value) {
    return _then(_self.copyWith(vehicle: value));
  });
}
}


/// @nodoc
mixin _$DocumentUpload {

 DocSide get side; String get url;
/// Create a copy of DocumentUpload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentUploadCopyWith<DocumentUpload> get copyWith => _$DocumentUploadCopyWithImpl<DocumentUpload>(this as DocumentUpload, _$identity);

  /// Serializes this DocumentUpload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentUpload&&(identical(other.side, side) || other.side == side)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,side,url);

@override
String toString() {
  return 'DocumentUpload(side: $side, url: $url)';
}


}

/// @nodoc
abstract mixin class $DocumentUploadCopyWith<$Res>  {
  factory $DocumentUploadCopyWith(DocumentUpload value, $Res Function(DocumentUpload) _then) = _$DocumentUploadCopyWithImpl;
@useResult
$Res call({
 DocSide side, String url
});




}
/// @nodoc
class _$DocumentUploadCopyWithImpl<$Res>
    implements $DocumentUploadCopyWith<$Res> {
  _$DocumentUploadCopyWithImpl(this._self, this._then);

  final DocumentUpload _self;
  final $Res Function(DocumentUpload) _then;

/// Create a copy of DocumentUpload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? side = null,Object? url = null,}) {
  return _then(_self.copyWith(
side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as DocSide,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentUpload].
extension DocumentUploadPatterns on DocumentUpload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentUpload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentUpload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentUpload value)  $default,){
final _that = this;
switch (_that) {
case _DocumentUpload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentUpload value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentUpload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DocSide side,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentUpload() when $default != null:
return $default(_that.side,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DocSide side,  String url)  $default,) {final _that = this;
switch (_that) {
case _DocumentUpload():
return $default(_that.side,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DocSide side,  String url)?  $default,) {final _that = this;
switch (_that) {
case _DocumentUpload() when $default != null:
return $default(_that.side,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentUpload implements DocumentUpload {
  const _DocumentUpload({required this.side, required this.url});
  factory _DocumentUpload.fromJson(Map<String, dynamic> json) => _$DocumentUploadFromJson(json);

@override final  DocSide side;
@override final  String url;

/// Create a copy of DocumentUpload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentUploadCopyWith<_DocumentUpload> get copyWith => __$DocumentUploadCopyWithImpl<_DocumentUpload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentUploadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentUpload&&(identical(other.side, side) || other.side == side)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,side,url);

@override
String toString() {
  return 'DocumentUpload(side: $side, url: $url)';
}


}

/// @nodoc
abstract mixin class _$DocumentUploadCopyWith<$Res> implements $DocumentUploadCopyWith<$Res> {
  factory _$DocumentUploadCopyWith(_DocumentUpload value, $Res Function(_DocumentUpload) _then) = __$DocumentUploadCopyWithImpl;
@override @useResult
$Res call({
 DocSide side, String url
});




}
/// @nodoc
class __$DocumentUploadCopyWithImpl<$Res>
    implements _$DocumentUploadCopyWith<$Res> {
  __$DocumentUploadCopyWithImpl(this._self, this._then);

  final _DocumentUpload _self;
  final $Res Function(_DocumentUpload) _then;

/// Create a copy of DocumentUpload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? side = null,Object? url = null,}) {
  return _then(_DocumentUpload(
side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as DocSide,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CreatedDocument {

 KycDocument get document; List<DocumentUpload> get uploads;
/// Create a copy of CreatedDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatedDocumentCopyWith<CreatedDocument> get copyWith => _$CreatedDocumentCopyWithImpl<CreatedDocument>(this as CreatedDocument, _$identity);

  /// Serializes this CreatedDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatedDocument&&(identical(other.document, document) || other.document == document)&&const DeepCollectionEquality().equals(other.uploads, uploads));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,document,const DeepCollectionEquality().hash(uploads));

@override
String toString() {
  return 'CreatedDocument(document: $document, uploads: $uploads)';
}


}

/// @nodoc
abstract mixin class $CreatedDocumentCopyWith<$Res>  {
  factory $CreatedDocumentCopyWith(CreatedDocument value, $Res Function(CreatedDocument) _then) = _$CreatedDocumentCopyWithImpl;
@useResult
$Res call({
 KycDocument document, List<DocumentUpload> uploads
});


$KycDocumentCopyWith<$Res> get document;

}
/// @nodoc
class _$CreatedDocumentCopyWithImpl<$Res>
    implements $CreatedDocumentCopyWith<$Res> {
  _$CreatedDocumentCopyWithImpl(this._self, this._then);

  final CreatedDocument _self;
  final $Res Function(CreatedDocument) _then;

/// Create a copy of CreatedDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? document = null,Object? uploads = null,}) {
  return _then(_self.copyWith(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as KycDocument,uploads: null == uploads ? _self.uploads : uploads // ignore: cast_nullable_to_non_nullable
as List<DocumentUpload>,
  ));
}
/// Create a copy of CreatedDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KycDocumentCopyWith<$Res> get document {
  
  return $KycDocumentCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// Adds pattern-matching-related methods to [CreatedDocument].
extension CreatedDocumentPatterns on CreatedDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatedDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatedDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatedDocument value)  $default,){
final _that = this;
switch (_that) {
case _CreatedDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatedDocument value)?  $default,){
final _that = this;
switch (_that) {
case _CreatedDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( KycDocument document,  List<DocumentUpload> uploads)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatedDocument() when $default != null:
return $default(_that.document,_that.uploads);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( KycDocument document,  List<DocumentUpload> uploads)  $default,) {final _that = this;
switch (_that) {
case _CreatedDocument():
return $default(_that.document,_that.uploads);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( KycDocument document,  List<DocumentUpload> uploads)?  $default,) {final _that = this;
switch (_that) {
case _CreatedDocument() when $default != null:
return $default(_that.document,_that.uploads);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreatedDocument implements CreatedDocument {
  const _CreatedDocument({required this.document, final  List<DocumentUpload> uploads = const <DocumentUpload>[]}): _uploads = uploads;
  factory _CreatedDocument.fromJson(Map<String, dynamic> json) => _$CreatedDocumentFromJson(json);

@override final  KycDocument document;
 final  List<DocumentUpload> _uploads;
@override@JsonKey() List<DocumentUpload> get uploads {
  if (_uploads is EqualUnmodifiableListView) return _uploads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_uploads);
}


/// Create a copy of CreatedDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatedDocumentCopyWith<_CreatedDocument> get copyWith => __$CreatedDocumentCopyWithImpl<_CreatedDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreatedDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatedDocument&&(identical(other.document, document) || other.document == document)&&const DeepCollectionEquality().equals(other._uploads, _uploads));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,document,const DeepCollectionEquality().hash(_uploads));

@override
String toString() {
  return 'CreatedDocument(document: $document, uploads: $uploads)';
}


}

/// @nodoc
abstract mixin class _$CreatedDocumentCopyWith<$Res> implements $CreatedDocumentCopyWith<$Res> {
  factory _$CreatedDocumentCopyWith(_CreatedDocument value, $Res Function(_CreatedDocument) _then) = __$CreatedDocumentCopyWithImpl;
@override @useResult
$Res call({
 KycDocument document, List<DocumentUpload> uploads
});


@override $KycDocumentCopyWith<$Res> get document;

}
/// @nodoc
class __$CreatedDocumentCopyWithImpl<$Res>
    implements _$CreatedDocumentCopyWith<$Res> {
  __$CreatedDocumentCopyWithImpl(this._self, this._then);

  final _CreatedDocument _self;
  final $Res Function(_CreatedDocument) _then;

/// Create a copy of CreatedDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? document = null,Object? uploads = null,}) {
  return _then(_CreatedDocument(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as KycDocument,uploads: null == uploads ? _self._uploads : uploads // ignore: cast_nullable_to_non_nullable
as List<DocumentUpload>,
  ));
}

/// Create a copy of CreatedDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KycDocumentCopyWith<$Res> get document {
  
  return $KycDocumentCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// @nodoc
mixin _$Payment {

 String get id; int get amountMinor; String get currency; PaymentMethod get method; PaymentStatus get status; String? get checkoutUrl; String? get paymentMethodDetail; String? get manualReference;/// Solo en el panel: por qué quedó en `needs_review`.
 String? get reviewNote; DateTime? get coversFrom; DateTime? get coversUntil; String? get voidReason; DateTime get createdAt;
/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentCopyWith<Payment> get copyWith => _$PaymentCopyWithImpl<Payment>(this as Payment, _$identity);

  /// Serializes this Payment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Payment&&(identical(other.id, id) || other.id == id)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.method, method) || other.method == method)&&(identical(other.status, status) || other.status == status)&&(identical(other.checkoutUrl, checkoutUrl) || other.checkoutUrl == checkoutUrl)&&(identical(other.paymentMethodDetail, paymentMethodDetail) || other.paymentMethodDetail == paymentMethodDetail)&&(identical(other.manualReference, manualReference) || other.manualReference == manualReference)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.coversFrom, coversFrom) || other.coversFrom == coversFrom)&&(identical(other.coversUntil, coversUntil) || other.coversUntil == coversUntil)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amountMinor,currency,method,status,checkoutUrl,paymentMethodDetail,manualReference,reviewNote,coversFrom,coversUntil,voidReason,createdAt);

@override
String toString() {
  return 'Payment(id: $id, amountMinor: $amountMinor, currency: $currency, method: $method, status: $status, checkoutUrl: $checkoutUrl, paymentMethodDetail: $paymentMethodDetail, manualReference: $manualReference, reviewNote: $reviewNote, coversFrom: $coversFrom, coversUntil: $coversUntil, voidReason: $voidReason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PaymentCopyWith<$Res>  {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) _then) = _$PaymentCopyWithImpl;
@useResult
$Res call({
 String id, int amountMinor, String currency, PaymentMethod method, PaymentStatus status, String? checkoutUrl, String? paymentMethodDetail, String? manualReference, String? reviewNote, DateTime? coversFrom, DateTime? coversUntil, String? voidReason, DateTime createdAt
});




}
/// @nodoc
class _$PaymentCopyWithImpl<$Res>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._self, this._then);

  final Payment _self;
  final $Res Function(Payment) _then;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amountMinor = null,Object? currency = null,Object? method = null,Object? status = null,Object? checkoutUrl = freezed,Object? paymentMethodDetail = freezed,Object? manualReference = freezed,Object? reviewNote = freezed,Object? coversFrom = freezed,Object? coversUntil = freezed,Object? voidReason = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethod,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PaymentStatus,checkoutUrl: freezed == checkoutUrl ? _self.checkoutUrl : checkoutUrl // ignore: cast_nullable_to_non_nullable
as String?,paymentMethodDetail: freezed == paymentMethodDetail ? _self.paymentMethodDetail : paymentMethodDetail // ignore: cast_nullable_to_non_nullable
as String?,manualReference: freezed == manualReference ? _self.manualReference : manualReference // ignore: cast_nullable_to_non_nullable
as String?,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,coversFrom: freezed == coversFrom ? _self.coversFrom : coversFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,coversUntil: freezed == coversUntil ? _self.coversUntil : coversUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Payment].
extension PaymentPatterns on Payment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Payment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Payment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Payment value)  $default,){
final _that = this;
switch (_that) {
case _Payment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Payment value)?  $default,){
final _that = this;
switch (_that) {
case _Payment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int amountMinor,  String currency,  PaymentMethod method,  PaymentStatus status,  String? checkoutUrl,  String? paymentMethodDetail,  String? manualReference,  String? reviewNote,  DateTime? coversFrom,  DateTime? coversUntil,  String? voidReason,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that.id,_that.amountMinor,_that.currency,_that.method,_that.status,_that.checkoutUrl,_that.paymentMethodDetail,_that.manualReference,_that.reviewNote,_that.coversFrom,_that.coversUntil,_that.voidReason,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int amountMinor,  String currency,  PaymentMethod method,  PaymentStatus status,  String? checkoutUrl,  String? paymentMethodDetail,  String? manualReference,  String? reviewNote,  DateTime? coversFrom,  DateTime? coversUntil,  String? voidReason,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Payment():
return $default(_that.id,_that.amountMinor,_that.currency,_that.method,_that.status,_that.checkoutUrl,_that.paymentMethodDetail,_that.manualReference,_that.reviewNote,_that.coversFrom,_that.coversUntil,_that.voidReason,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int amountMinor,  String currency,  PaymentMethod method,  PaymentStatus status,  String? checkoutUrl,  String? paymentMethodDetail,  String? manualReference,  String? reviewNote,  DateTime? coversFrom,  DateTime? coversUntil,  String? voidReason,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that.id,_that.amountMinor,_that.currency,_that.method,_that.status,_that.checkoutUrl,_that.paymentMethodDetail,_that.manualReference,_that.reviewNote,_that.coversFrom,_that.coversUntil,_that.voidReason,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Payment implements Payment {
  const _Payment({required this.id, required this.amountMinor, required this.currency, required this.method, required this.status, this.checkoutUrl, this.paymentMethodDetail, this.manualReference, this.reviewNote, this.coversFrom, this.coversUntil, this.voidReason, required this.createdAt});
  factory _Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);

@override final  String id;
@override final  int amountMinor;
@override final  String currency;
@override final  PaymentMethod method;
@override final  PaymentStatus status;
@override final  String? checkoutUrl;
@override final  String? paymentMethodDetail;
@override final  String? manualReference;
/// Solo en el panel: por qué quedó en `needs_review`.
@override final  String? reviewNote;
@override final  DateTime? coversFrom;
@override final  DateTime? coversUntil;
@override final  String? voidReason;
@override final  DateTime createdAt;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentCopyWith<_Payment> get copyWith => __$PaymentCopyWithImpl<_Payment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Payment&&(identical(other.id, id) || other.id == id)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.method, method) || other.method == method)&&(identical(other.status, status) || other.status == status)&&(identical(other.checkoutUrl, checkoutUrl) || other.checkoutUrl == checkoutUrl)&&(identical(other.paymentMethodDetail, paymentMethodDetail) || other.paymentMethodDetail == paymentMethodDetail)&&(identical(other.manualReference, manualReference) || other.manualReference == manualReference)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.coversFrom, coversFrom) || other.coversFrom == coversFrom)&&(identical(other.coversUntil, coversUntil) || other.coversUntil == coversUntil)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amountMinor,currency,method,status,checkoutUrl,paymentMethodDetail,manualReference,reviewNote,coversFrom,coversUntil,voidReason,createdAt);

@override
String toString() {
  return 'Payment(id: $id, amountMinor: $amountMinor, currency: $currency, method: $method, status: $status, checkoutUrl: $checkoutUrl, paymentMethodDetail: $paymentMethodDetail, manualReference: $manualReference, reviewNote: $reviewNote, coversFrom: $coversFrom, coversUntil: $coversUntil, voidReason: $voidReason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PaymentCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$PaymentCopyWith(_Payment value, $Res Function(_Payment) _then) = __$PaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, int amountMinor, String currency, PaymentMethod method, PaymentStatus status, String? checkoutUrl, String? paymentMethodDetail, String? manualReference, String? reviewNote, DateTime? coversFrom, DateTime? coversUntil, String? voidReason, DateTime createdAt
});




}
/// @nodoc
class __$PaymentCopyWithImpl<$Res>
    implements _$PaymentCopyWith<$Res> {
  __$PaymentCopyWithImpl(this._self, this._then);

  final _Payment _self;
  final $Res Function(_Payment) _then;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amountMinor = null,Object? currency = null,Object? method = null,Object? status = null,Object? checkoutUrl = freezed,Object? paymentMethodDetail = freezed,Object? manualReference = freezed,Object? reviewNote = freezed,Object? coversFrom = freezed,Object? coversUntil = freezed,Object? voidReason = freezed,Object? createdAt = null,}) {
  return _then(_Payment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethod,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PaymentStatus,checkoutUrl: freezed == checkoutUrl ? _self.checkoutUrl : checkoutUrl // ignore: cast_nullable_to_non_nullable
as String?,paymentMethodDetail: freezed == paymentMethodDetail ? _self.paymentMethodDetail : paymentMethodDetail // ignore: cast_nullable_to_non_nullable
as String?,manualReference: freezed == manualReference ? _self.manualReference : manualReference // ignore: cast_nullable_to_non_nullable
as String?,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,coversFrom: freezed == coversFrom ? _self.coversFrom : coversFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,coversUntil: freezed == coversUntil ? _self.coversUntil : coversUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$Price {

 int get amountMinor; String get currency;
/// Create a copy of Price
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceCopyWith<Price> get copyWith => _$PriceCopyWithImpl<Price>(this as Price, _$identity);

  /// Serializes this Price to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Price&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amountMinor,currency);

@override
String toString() {
  return 'Price(amountMinor: $amountMinor, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $PriceCopyWith<$Res>  {
  factory $PriceCopyWith(Price value, $Res Function(Price) _then) = _$PriceCopyWithImpl;
@useResult
$Res call({
 int amountMinor, String currency
});




}
/// @nodoc
class _$PriceCopyWithImpl<$Res>
    implements $PriceCopyWith<$Res> {
  _$PriceCopyWithImpl(this._self, this._then);

  final Price _self;
  final $Res Function(Price) _then;

/// Create a copy of Price
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amountMinor = null,Object? currency = null,}) {
  return _then(_self.copyWith(
amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Price].
extension PricePatterns on Price {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Price value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Price() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Price value)  $default,){
final _that = this;
switch (_that) {
case _Price():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Price value)?  $default,){
final _that = this;
switch (_that) {
case _Price() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int amountMinor,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Price() when $default != null:
return $default(_that.amountMinor,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int amountMinor,  String currency)  $default,) {final _that = this;
switch (_that) {
case _Price():
return $default(_that.amountMinor,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int amountMinor,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _Price() when $default != null:
return $default(_that.amountMinor,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Price implements Price {
  const _Price({required this.amountMinor, required this.currency});
  factory _Price.fromJson(Map<String, dynamic> json) => _$PriceFromJson(json);

@override final  int amountMinor;
@override final  String currency;

/// Create a copy of Price
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceCopyWith<_Price> get copyWith => __$PriceCopyWithImpl<_Price>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Price&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amountMinor,currency);

@override
String toString() {
  return 'Price(amountMinor: $amountMinor, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$PriceCopyWith<$Res> implements $PriceCopyWith<$Res> {
  factory _$PriceCopyWith(_Price value, $Res Function(_Price) _then) = __$PriceCopyWithImpl;
@override @useResult
$Res call({
 int amountMinor, String currency
});




}
/// @nodoc
class __$PriceCopyWithImpl<$Res>
    implements _$PriceCopyWith<$Res> {
  __$PriceCopyWithImpl(this._self, this._then);

  final _Price _self;
  final $Res Function(_Price) _then;

/// Create a copy of Price
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amountMinor = null,Object? currency = null,}) {
  return _then(_Price(
amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SubscriptionView {

 BillingStatus get status; DateTime? get paidUntil; DateTime? get graceUntil; Price? get price;/// Documentos al día, precio definido y Bold activo.
 bool get canPay; List<Payment> get payments;
/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionViewCopyWith<SubscriptionView> get copyWith => _$SubscriptionViewCopyWithImpl<SubscriptionView>(this as SubscriptionView, _$identity);

  /// Serializes this SubscriptionView to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionView&&(identical(other.status, status) || other.status == status)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.graceUntil, graceUntil) || other.graceUntil == graceUntil)&&(identical(other.price, price) || other.price == price)&&(identical(other.canPay, canPay) || other.canPay == canPay)&&const DeepCollectionEquality().equals(other.payments, payments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,paidUntil,graceUntil,price,canPay,const DeepCollectionEquality().hash(payments));

@override
String toString() {
  return 'SubscriptionView(status: $status, paidUntil: $paidUntil, graceUntil: $graceUntil, price: $price, canPay: $canPay, payments: $payments)';
}


}

/// @nodoc
abstract mixin class $SubscriptionViewCopyWith<$Res>  {
  factory $SubscriptionViewCopyWith(SubscriptionView value, $Res Function(SubscriptionView) _then) = _$SubscriptionViewCopyWithImpl;
@useResult
$Res call({
 BillingStatus status, DateTime? paidUntil, DateTime? graceUntil, Price? price, bool canPay, List<Payment> payments
});


$PriceCopyWith<$Res>? get price;

}
/// @nodoc
class _$SubscriptionViewCopyWithImpl<$Res>
    implements $SubscriptionViewCopyWith<$Res> {
  _$SubscriptionViewCopyWithImpl(this._self, this._then);

  final SubscriptionView _self;
  final $Res Function(SubscriptionView) _then;

/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? paidUntil = freezed,Object? graceUntil = freezed,Object? price = freezed,Object? canPay = null,Object? payments = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BillingStatus,paidUntil: freezed == paidUntil ? _self.paidUntil : paidUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,graceUntil: freezed == graceUntil ? _self.graceUntil : graceUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Price?,canPay: null == canPay ? _self.canPay : canPay // ignore: cast_nullable_to_non_nullable
as bool,payments: null == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as List<Payment>,
  ));
}
/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceCopyWith<$Res>? get price {
    if (_self.price == null) {
    return null;
  }

  return $PriceCopyWith<$Res>(_self.price!, (value) {
    return _then(_self.copyWith(price: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubscriptionView].
extension SubscriptionViewPatterns on SubscriptionView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionView value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionView value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BillingStatus status,  DateTime? paidUntil,  DateTime? graceUntil,  Price? price,  bool canPay,  List<Payment> payments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionView() when $default != null:
return $default(_that.status,_that.paidUntil,_that.graceUntil,_that.price,_that.canPay,_that.payments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BillingStatus status,  DateTime? paidUntil,  DateTime? graceUntil,  Price? price,  bool canPay,  List<Payment> payments)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionView():
return $default(_that.status,_that.paidUntil,_that.graceUntil,_that.price,_that.canPay,_that.payments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BillingStatus status,  DateTime? paidUntil,  DateTime? graceUntil,  Price? price,  bool canPay,  List<Payment> payments)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionView() when $default != null:
return $default(_that.status,_that.paidUntil,_that.graceUntil,_that.price,_that.canPay,_that.payments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionView implements SubscriptionView {
  const _SubscriptionView({required this.status, this.paidUntil, this.graceUntil, this.price, this.canPay = false, final  List<Payment> payments = const <Payment>[]}): _payments = payments;
  factory _SubscriptionView.fromJson(Map<String, dynamic> json) => _$SubscriptionViewFromJson(json);

@override final  BillingStatus status;
@override final  DateTime? paidUntil;
@override final  DateTime? graceUntil;
@override final  Price? price;
/// Documentos al día, precio definido y Bold activo.
@override@JsonKey() final  bool canPay;
 final  List<Payment> _payments;
@override@JsonKey() List<Payment> get payments {
  if (_payments is EqualUnmodifiableListView) return _payments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_payments);
}


/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionViewCopyWith<_SubscriptionView> get copyWith => __$SubscriptionViewCopyWithImpl<_SubscriptionView>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionViewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionView&&(identical(other.status, status) || other.status == status)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.graceUntil, graceUntil) || other.graceUntil == graceUntil)&&(identical(other.price, price) || other.price == price)&&(identical(other.canPay, canPay) || other.canPay == canPay)&&const DeepCollectionEquality().equals(other._payments, _payments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,paidUntil,graceUntil,price,canPay,const DeepCollectionEquality().hash(_payments));

@override
String toString() {
  return 'SubscriptionView(status: $status, paidUntil: $paidUntil, graceUntil: $graceUntil, price: $price, canPay: $canPay, payments: $payments)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionViewCopyWith<$Res> implements $SubscriptionViewCopyWith<$Res> {
  factory _$SubscriptionViewCopyWith(_SubscriptionView value, $Res Function(_SubscriptionView) _then) = __$SubscriptionViewCopyWithImpl;
@override @useResult
$Res call({
 BillingStatus status, DateTime? paidUntil, DateTime? graceUntil, Price? price, bool canPay, List<Payment> payments
});


@override $PriceCopyWith<$Res>? get price;

}
/// @nodoc
class __$SubscriptionViewCopyWithImpl<$Res>
    implements _$SubscriptionViewCopyWith<$Res> {
  __$SubscriptionViewCopyWithImpl(this._self, this._then);

  final _SubscriptionView _self;
  final $Res Function(_SubscriptionView) _then;

/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? paidUntil = freezed,Object? graceUntil = freezed,Object? price = freezed,Object? canPay = null,Object? payments = null,}) {
  return _then(_SubscriptionView(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BillingStatus,paidUntil: freezed == paidUntil ? _self.paidUntil : paidUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,graceUntil: freezed == graceUntil ? _self.graceUntil : graceUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Price?,canPay: null == canPay ? _self.canPay : canPay // ignore: cast_nullable_to_non_nullable
as bool,payments: null == payments ? _self._payments : payments // ignore: cast_nullable_to_non_nullable
as List<Payment>,
  ));
}

/// Create a copy of SubscriptionView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceCopyWith<$Res>? get price {
    if (_self.price == null) {
    return null;
  }

  return $PriceCopyWith<$Res>(_self.price!, (value) {
    return _then(_self.copyWith(price: value));
  });
}
}


/// @nodoc
mixin _$CostItem {

 String get concept; double get usage; double get costMinor;
/// Create a copy of CostItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CostItemCopyWith<CostItem> get copyWith => _$CostItemCopyWithImpl<CostItem>(this as CostItem, _$identity);

  /// Serializes this CostItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CostItem&&(identical(other.concept, concept) || other.concept == concept)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.costMinor, costMinor) || other.costMinor == costMinor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,concept,usage,costMinor);

@override
String toString() {
  return 'CostItem(concept: $concept, usage: $usage, costMinor: $costMinor)';
}


}

/// @nodoc
abstract mixin class $CostItemCopyWith<$Res>  {
  factory $CostItemCopyWith(CostItem value, $Res Function(CostItem) _then) = _$CostItemCopyWithImpl;
@useResult
$Res call({
 String concept, double usage, double costMinor
});




}
/// @nodoc
class _$CostItemCopyWithImpl<$Res>
    implements $CostItemCopyWith<$Res> {
  _$CostItemCopyWithImpl(this._self, this._then);

  final CostItem _self;
  final $Res Function(CostItem) _then;

/// Create a copy of CostItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? concept = null,Object? usage = null,Object? costMinor = null,}) {
  return _then(_self.copyWith(
concept: null == concept ? _self.concept : concept // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as double,costMinor: null == costMinor ? _self.costMinor : costMinor // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CostItem].
extension CostItemPatterns on CostItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CostItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CostItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CostItem value)  $default,){
final _that = this;
switch (_that) {
case _CostItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CostItem value)?  $default,){
final _that = this;
switch (_that) {
case _CostItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String concept,  double usage,  double costMinor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CostItem() when $default != null:
return $default(_that.concept,_that.usage,_that.costMinor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String concept,  double usage,  double costMinor)  $default,) {final _that = this;
switch (_that) {
case _CostItem():
return $default(_that.concept,_that.usage,_that.costMinor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String concept,  double usage,  double costMinor)?  $default,) {final _that = this;
switch (_that) {
case _CostItem() when $default != null:
return $default(_that.concept,_that.usage,_that.costMinor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CostItem implements CostItem {
  const _CostItem({required this.concept, this.usage = 0, this.costMinor = 0});
  factory _CostItem.fromJson(Map<String, dynamic> json) => _$CostItemFromJson(json);

@override final  String concept;
@override@JsonKey() final  double usage;
@override@JsonKey() final  double costMinor;

/// Create a copy of CostItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CostItemCopyWith<_CostItem> get copyWith => __$CostItemCopyWithImpl<_CostItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CostItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CostItem&&(identical(other.concept, concept) || other.concept == concept)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.costMinor, costMinor) || other.costMinor == costMinor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,concept,usage,costMinor);

@override
String toString() {
  return 'CostItem(concept: $concept, usage: $usage, costMinor: $costMinor)';
}


}

/// @nodoc
abstract mixin class _$CostItemCopyWith<$Res> implements $CostItemCopyWith<$Res> {
  factory _$CostItemCopyWith(_CostItem value, $Res Function(_CostItem) _then) = __$CostItemCopyWithImpl;
@override @useResult
$Res call({
 String concept, double usage, double costMinor
});




}
/// @nodoc
class __$CostItemCopyWithImpl<$Res>
    implements _$CostItemCopyWith<$Res> {
  __$CostItemCopyWithImpl(this._self, this._then);

  final _CostItem _self;
  final $Res Function(_CostItem) _then;

/// Create a copy of CostItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? concept = null,Object? usage = null,Object? costMinor = null,}) {
  return _then(_CostItem(
concept: null == concept ? _self.concept : concept // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as double,costMinor: null == costMinor ? _self.costMinor : costMinor // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$CostBreakdown {

 String? get driverId; String? get displayName; String get month; String get currency; int get paidMinor; List<CostItem> get items; double get totalCostMinor; double get marginMinor; bool? get negativeMargin;
/// Create a copy of CostBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CostBreakdownCopyWith<CostBreakdown> get copyWith => _$CostBreakdownCopyWithImpl<CostBreakdown>(this as CostBreakdown, _$identity);

  /// Serializes this CostBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CostBreakdown&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.month, month) || other.month == month)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.paidMinor, paidMinor) || other.paidMinor == paidMinor)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalCostMinor, totalCostMinor) || other.totalCostMinor == totalCostMinor)&&(identical(other.marginMinor, marginMinor) || other.marginMinor == marginMinor)&&(identical(other.negativeMargin, negativeMargin) || other.negativeMargin == negativeMargin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,month,currency,paidMinor,const DeepCollectionEquality().hash(items),totalCostMinor,marginMinor,negativeMargin);

@override
String toString() {
  return 'CostBreakdown(driverId: $driverId, displayName: $displayName, month: $month, currency: $currency, paidMinor: $paidMinor, items: $items, totalCostMinor: $totalCostMinor, marginMinor: $marginMinor, negativeMargin: $negativeMargin)';
}


}

/// @nodoc
abstract mixin class $CostBreakdownCopyWith<$Res>  {
  factory $CostBreakdownCopyWith(CostBreakdown value, $Res Function(CostBreakdown) _then) = _$CostBreakdownCopyWithImpl;
@useResult
$Res call({
 String? driverId, String? displayName, String month, String currency, int paidMinor, List<CostItem> items, double totalCostMinor, double marginMinor, bool? negativeMargin
});




}
/// @nodoc
class _$CostBreakdownCopyWithImpl<$Res>
    implements $CostBreakdownCopyWith<$Res> {
  _$CostBreakdownCopyWithImpl(this._self, this._then);

  final CostBreakdown _self;
  final $Res Function(CostBreakdown) _then;

/// Create a copy of CostBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = freezed,Object? displayName = freezed,Object? month = null,Object? currency = null,Object? paidMinor = null,Object? items = null,Object? totalCostMinor = null,Object? marginMinor = null,Object? negativeMargin = freezed,}) {
  return _then(_self.copyWith(
driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,paidMinor: null == paidMinor ? _self.paidMinor : paidMinor // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CostItem>,totalCostMinor: null == totalCostMinor ? _self.totalCostMinor : totalCostMinor // ignore: cast_nullable_to_non_nullable
as double,marginMinor: null == marginMinor ? _self.marginMinor : marginMinor // ignore: cast_nullable_to_non_nullable
as double,negativeMargin: freezed == negativeMargin ? _self.negativeMargin : negativeMargin // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [CostBreakdown].
extension CostBreakdownPatterns on CostBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CostBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CostBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CostBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _CostBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CostBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _CostBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? driverId,  String? displayName,  String month,  String currency,  int paidMinor,  List<CostItem> items,  double totalCostMinor,  double marginMinor,  bool? negativeMargin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CostBreakdown() when $default != null:
return $default(_that.driverId,_that.displayName,_that.month,_that.currency,_that.paidMinor,_that.items,_that.totalCostMinor,_that.marginMinor,_that.negativeMargin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? driverId,  String? displayName,  String month,  String currency,  int paidMinor,  List<CostItem> items,  double totalCostMinor,  double marginMinor,  bool? negativeMargin)  $default,) {final _that = this;
switch (_that) {
case _CostBreakdown():
return $default(_that.driverId,_that.displayName,_that.month,_that.currency,_that.paidMinor,_that.items,_that.totalCostMinor,_that.marginMinor,_that.negativeMargin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? driverId,  String? displayName,  String month,  String currency,  int paidMinor,  List<CostItem> items,  double totalCostMinor,  double marginMinor,  bool? negativeMargin)?  $default,) {final _that = this;
switch (_that) {
case _CostBreakdown() when $default != null:
return $default(_that.driverId,_that.displayName,_that.month,_that.currency,_that.paidMinor,_that.items,_that.totalCostMinor,_that.marginMinor,_that.negativeMargin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CostBreakdown implements CostBreakdown {
  const _CostBreakdown({this.driverId, this.displayName, this.month = '', this.currency = 'COP', this.paidMinor = 0, final  List<CostItem> items = const <CostItem>[], this.totalCostMinor = 0, this.marginMinor = 0, this.negativeMargin}): _items = items;
  factory _CostBreakdown.fromJson(Map<String, dynamic> json) => _$CostBreakdownFromJson(json);

@override final  String? driverId;
@override final  String? displayName;
@override@JsonKey() final  String month;
@override@JsonKey() final  String currency;
@override@JsonKey() final  int paidMinor;
 final  List<CostItem> _items;
@override@JsonKey() List<CostItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  double totalCostMinor;
@override@JsonKey() final  double marginMinor;
@override final  bool? negativeMargin;

/// Create a copy of CostBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CostBreakdownCopyWith<_CostBreakdown> get copyWith => __$CostBreakdownCopyWithImpl<_CostBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CostBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CostBreakdown&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.month, month) || other.month == month)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.paidMinor, paidMinor) || other.paidMinor == paidMinor)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalCostMinor, totalCostMinor) || other.totalCostMinor == totalCostMinor)&&(identical(other.marginMinor, marginMinor) || other.marginMinor == marginMinor)&&(identical(other.negativeMargin, negativeMargin) || other.negativeMargin == negativeMargin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,month,currency,paidMinor,const DeepCollectionEquality().hash(_items),totalCostMinor,marginMinor,negativeMargin);

@override
String toString() {
  return 'CostBreakdown(driverId: $driverId, displayName: $displayName, month: $month, currency: $currency, paidMinor: $paidMinor, items: $items, totalCostMinor: $totalCostMinor, marginMinor: $marginMinor, negativeMargin: $negativeMargin)';
}


}

/// @nodoc
abstract mixin class _$CostBreakdownCopyWith<$Res> implements $CostBreakdownCopyWith<$Res> {
  factory _$CostBreakdownCopyWith(_CostBreakdown value, $Res Function(_CostBreakdown) _then) = __$CostBreakdownCopyWithImpl;
@override @useResult
$Res call({
 String? driverId, String? displayName, String month, String currency, int paidMinor, List<CostItem> items, double totalCostMinor, double marginMinor, bool? negativeMargin
});




}
/// @nodoc
class __$CostBreakdownCopyWithImpl<$Res>
    implements _$CostBreakdownCopyWith<$Res> {
  __$CostBreakdownCopyWithImpl(this._self, this._then);

  final _CostBreakdown _self;
  final $Res Function(_CostBreakdown) _then;

/// Create a copy of CostBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = freezed,Object? displayName = freezed,Object? month = null,Object? currency = null,Object? paidMinor = null,Object? items = null,Object? totalCostMinor = null,Object? marginMinor = null,Object? negativeMargin = freezed,}) {
  return _then(_CostBreakdown(
driverId: freezed == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,paidMinor: null == paidMinor ? _self.paidMinor : paidMinor // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CostItem>,totalCostMinor: null == totalCostMinor ? _self.totalCostMinor : totalCostMinor // ignore: cast_nullable_to_non_nullable
as double,marginMinor: null == marginMinor ? _self.marginMinor : marginMinor // ignore: cast_nullable_to_non_nullable
as double,negativeMargin: freezed == negativeMargin ? _self.negativeMargin : negativeMargin // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$Notice {

 String get id; String get kind; String get title; String get body; DateTime get createdAt; DateTime? get readAt;
/// Create a copy of Notice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoticeCopyWith<Notice> get copyWith => _$NoticeCopyWithImpl<Notice>(this as Notice, _$identity);

  /// Serializes this Notice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Notice&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,body,createdAt,readAt);

@override
String toString() {
  return 'Notice(id: $id, kind: $kind, title: $title, body: $body, createdAt: $createdAt, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class $NoticeCopyWith<$Res>  {
  factory $NoticeCopyWith(Notice value, $Res Function(Notice) _then) = _$NoticeCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String title, String body, DateTime createdAt, DateTime? readAt
});




}
/// @nodoc
class _$NoticeCopyWithImpl<$Res>
    implements $NoticeCopyWith<$Res> {
  _$NoticeCopyWithImpl(this._self, this._then);

  final Notice _self;
  final $Res Function(Notice) _then;

/// Create a copy of Notice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? body = null,Object? createdAt = null,Object? readAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Notice].
extension NoticePatterns on Notice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Notice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Notice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Notice value)  $default,){
final _that = this;
switch (_that) {
case _Notice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Notice value)?  $default,){
final _that = this;
switch (_that) {
case _Notice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String title,  String body,  DateTime createdAt,  DateTime? readAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Notice() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.body,_that.createdAt,_that.readAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String title,  String body,  DateTime createdAt,  DateTime? readAt)  $default,) {final _that = this;
switch (_that) {
case _Notice():
return $default(_that.id,_that.kind,_that.title,_that.body,_that.createdAt,_that.readAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String title,  String body,  DateTime createdAt,  DateTime? readAt)?  $default,) {final _that = this;
switch (_that) {
case _Notice() when $default != null:
return $default(_that.id,_that.kind,_that.title,_that.body,_that.createdAt,_that.readAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Notice implements Notice {
  const _Notice({required this.id, required this.kind, required this.title, this.body = '', required this.createdAt, this.readAt});
  factory _Notice.fromJson(Map<String, dynamic> json) => _$NoticeFromJson(json);

@override final  String id;
@override final  String kind;
@override final  String title;
@override@JsonKey() final  String body;
@override final  DateTime createdAt;
@override final  DateTime? readAt;

/// Create a copy of Notice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoticeCopyWith<_Notice> get copyWith => __$NoticeCopyWithImpl<_Notice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoticeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Notice&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,title,body,createdAt,readAt);

@override
String toString() {
  return 'Notice(id: $id, kind: $kind, title: $title, body: $body, createdAt: $createdAt, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class _$NoticeCopyWith<$Res> implements $NoticeCopyWith<$Res> {
  factory _$NoticeCopyWith(_Notice value, $Res Function(_Notice) _then) = __$NoticeCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String title, String body, DateTime createdAt, DateTime? readAt
});




}
/// @nodoc
class __$NoticeCopyWithImpl<$Res>
    implements _$NoticeCopyWith<$Res> {
  __$NoticeCopyWithImpl(this._self, this._then);

  final _Notice _self;
  final $Res Function(_Notice) _then;

/// Create a copy of Notice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? title = null,Object? body = null,Object? createdAt = null,Object? readAt = freezed,}) {
  return _then(_Notice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$KycQueueEntry {

 String get driverId; String get displayName; String? get vehiclePlate;@JsonKey(name: 'pending_documents') int get pendingCount; DateTime? get oldestSubmittedAt;
/// Create a copy of KycQueueEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KycQueueEntryCopyWith<KycQueueEntry> get copyWith => _$KycQueueEntryCopyWithImpl<KycQueueEntry>(this as KycQueueEntry, _$identity);

  /// Serializes this KycQueueEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KycQueueEntry&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.pendingCount, pendingCount) || other.pendingCount == pendingCount)&&(identical(other.oldestSubmittedAt, oldestSubmittedAt) || other.oldestSubmittedAt == oldestSubmittedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,vehiclePlate,pendingCount,oldestSubmittedAt);

@override
String toString() {
  return 'KycQueueEntry(driverId: $driverId, displayName: $displayName, vehiclePlate: $vehiclePlate, pendingCount: $pendingCount, oldestSubmittedAt: $oldestSubmittedAt)';
}


}

/// @nodoc
abstract mixin class $KycQueueEntryCopyWith<$Res>  {
  factory $KycQueueEntryCopyWith(KycQueueEntry value, $Res Function(KycQueueEntry) _then) = _$KycQueueEntryCopyWithImpl;
@useResult
$Res call({
 String driverId, String displayName, String? vehiclePlate,@JsonKey(name: 'pending_documents') int pendingCount, DateTime? oldestSubmittedAt
});




}
/// @nodoc
class _$KycQueueEntryCopyWithImpl<$Res>
    implements $KycQueueEntryCopyWith<$Res> {
  _$KycQueueEntryCopyWithImpl(this._self, this._then);

  final KycQueueEntry _self;
  final $Res Function(KycQueueEntry) _then;

/// Create a copy of KycQueueEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? displayName = null,Object? vehiclePlate = freezed,Object? pendingCount = null,Object? oldestSubmittedAt = freezed,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: freezed == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String?,pendingCount: null == pendingCount ? _self.pendingCount : pendingCount // ignore: cast_nullable_to_non_nullable
as int,oldestSubmittedAt: freezed == oldestSubmittedAt ? _self.oldestSubmittedAt : oldestSubmittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [KycQueueEntry].
extension KycQueueEntryPatterns on KycQueueEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KycQueueEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KycQueueEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KycQueueEntry value)  $default,){
final _that = this;
switch (_that) {
case _KycQueueEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KycQueueEntry value)?  $default,){
final _that = this;
switch (_that) {
case _KycQueueEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String displayName,  String? vehiclePlate, @JsonKey(name: 'pending_documents')  int pendingCount,  DateTime? oldestSubmittedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KycQueueEntry() when $default != null:
return $default(_that.driverId,_that.displayName,_that.vehiclePlate,_that.pendingCount,_that.oldestSubmittedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String displayName,  String? vehiclePlate, @JsonKey(name: 'pending_documents')  int pendingCount,  DateTime? oldestSubmittedAt)  $default,) {final _that = this;
switch (_that) {
case _KycQueueEntry():
return $default(_that.driverId,_that.displayName,_that.vehiclePlate,_that.pendingCount,_that.oldestSubmittedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String displayName,  String? vehiclePlate, @JsonKey(name: 'pending_documents')  int pendingCount,  DateTime? oldestSubmittedAt)?  $default,) {final _that = this;
switch (_that) {
case _KycQueueEntry() when $default != null:
return $default(_that.driverId,_that.displayName,_that.vehiclePlate,_that.pendingCount,_that.oldestSubmittedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KycQueueEntry implements KycQueueEntry {
  const _KycQueueEntry({required this.driverId, required this.displayName, this.vehiclePlate, @JsonKey(name: 'pending_documents') this.pendingCount = 0, this.oldestSubmittedAt});
  factory _KycQueueEntry.fromJson(Map<String, dynamic> json) => _$KycQueueEntryFromJson(json);

@override final  String driverId;
@override final  String displayName;
@override final  String? vehiclePlate;
@override@JsonKey(name: 'pending_documents') final  int pendingCount;
@override final  DateTime? oldestSubmittedAt;

/// Create a copy of KycQueueEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KycQueueEntryCopyWith<_KycQueueEntry> get copyWith => __$KycQueueEntryCopyWithImpl<_KycQueueEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KycQueueEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KycQueueEntry&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.pendingCount, pendingCount) || other.pendingCount == pendingCount)&&(identical(other.oldestSubmittedAt, oldestSubmittedAt) || other.oldestSubmittedAt == oldestSubmittedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,vehiclePlate,pendingCount,oldestSubmittedAt);

@override
String toString() {
  return 'KycQueueEntry(driverId: $driverId, displayName: $displayName, vehiclePlate: $vehiclePlate, pendingCount: $pendingCount, oldestSubmittedAt: $oldestSubmittedAt)';
}


}

/// @nodoc
abstract mixin class _$KycQueueEntryCopyWith<$Res> implements $KycQueueEntryCopyWith<$Res> {
  factory _$KycQueueEntryCopyWith(_KycQueueEntry value, $Res Function(_KycQueueEntry) _then) = __$KycQueueEntryCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String displayName, String? vehiclePlate,@JsonKey(name: 'pending_documents') int pendingCount, DateTime? oldestSubmittedAt
});




}
/// @nodoc
class __$KycQueueEntryCopyWithImpl<$Res>
    implements _$KycQueueEntryCopyWith<$Res> {
  __$KycQueueEntryCopyWithImpl(this._self, this._then);

  final _KycQueueEntry _self;
  final $Res Function(_KycQueueEntry) _then;

/// Create a copy of KycQueueEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? displayName = null,Object? vehiclePlate = freezed,Object? pendingCount = null,Object? oldestSubmittedAt = freezed,}) {
  return _then(_KycQueueEntry(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,vehiclePlate: freezed == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String?,pendingCount: null == pendingCount ? _self.pendingCount : pendingCount // ignore: cast_nullable_to_non_nullable
as int,oldestSubmittedAt: freezed == oldestSubmittedAt ? _self.oldestSubmittedAt : oldestSubmittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$KycDriverFile {

 String get driverId; String get displayName; String? get phoneE164; OnboardingStatus? get status; Vehicle? get vehicle; List<OnboardingDocument> get documents; List<BlockedDocument> get blockedDocuments;
/// Create a copy of KycDriverFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KycDriverFileCopyWith<KycDriverFile> get copyWith => _$KycDriverFileCopyWithImpl<KycDriverFile>(this as KycDriverFile, _$identity);

  /// Serializes this KycDriverFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KycDriverFile&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164)&&(identical(other.status, status) || other.status == status)&&(identical(other.vehicle, vehicle) || other.vehicle == vehicle)&&const DeepCollectionEquality().equals(other.documents, documents)&&const DeepCollectionEquality().equals(other.blockedDocuments, blockedDocuments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,phoneE164,status,vehicle,const DeepCollectionEquality().hash(documents),const DeepCollectionEquality().hash(blockedDocuments));

@override
String toString() {
  return 'KycDriverFile(driverId: $driverId, displayName: $displayName, phoneE164: $phoneE164, status: $status, vehicle: $vehicle, documents: $documents, blockedDocuments: $blockedDocuments)';
}


}

/// @nodoc
abstract mixin class $KycDriverFileCopyWith<$Res>  {
  factory $KycDriverFileCopyWith(KycDriverFile value, $Res Function(KycDriverFile) _then) = _$KycDriverFileCopyWithImpl;
@useResult
$Res call({
 String driverId, String displayName, String? phoneE164, OnboardingStatus? status, Vehicle? vehicle, List<OnboardingDocument> documents, List<BlockedDocument> blockedDocuments
});


$VehicleCopyWith<$Res>? get vehicle;

}
/// @nodoc
class _$KycDriverFileCopyWithImpl<$Res>
    implements $KycDriverFileCopyWith<$Res> {
  _$KycDriverFileCopyWithImpl(this._self, this._then);

  final KycDriverFile _self;
  final $Res Function(KycDriverFile) _then;

/// Create a copy of KycDriverFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? displayName = null,Object? phoneE164 = freezed,Object? status = freezed,Object? vehicle = freezed,Object? documents = null,Object? blockedDocuments = null,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,phoneE164: freezed == phoneE164 ? _self.phoneE164 : phoneE164 // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OnboardingStatus?,vehicle: freezed == vehicle ? _self.vehicle : vehicle // ignore: cast_nullable_to_non_nullable
as Vehicle?,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<OnboardingDocument>,blockedDocuments: null == blockedDocuments ? _self.blockedDocuments : blockedDocuments // ignore: cast_nullable_to_non_nullable
as List<BlockedDocument>,
  ));
}
/// Create a copy of KycDriverFile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VehicleCopyWith<$Res>? get vehicle {
    if (_self.vehicle == null) {
    return null;
  }

  return $VehicleCopyWith<$Res>(_self.vehicle!, (value) {
    return _then(_self.copyWith(vehicle: value));
  });
}
}


/// Adds pattern-matching-related methods to [KycDriverFile].
extension KycDriverFilePatterns on KycDriverFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KycDriverFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KycDriverFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KycDriverFile value)  $default,){
final _that = this;
switch (_that) {
case _KycDriverFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KycDriverFile value)?  $default,){
final _that = this;
switch (_that) {
case _KycDriverFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String displayName,  String? phoneE164,  OnboardingStatus? status,  Vehicle? vehicle,  List<OnboardingDocument> documents,  List<BlockedDocument> blockedDocuments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KycDriverFile() when $default != null:
return $default(_that.driverId,_that.displayName,_that.phoneE164,_that.status,_that.vehicle,_that.documents,_that.blockedDocuments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String displayName,  String? phoneE164,  OnboardingStatus? status,  Vehicle? vehicle,  List<OnboardingDocument> documents,  List<BlockedDocument> blockedDocuments)  $default,) {final _that = this;
switch (_that) {
case _KycDriverFile():
return $default(_that.driverId,_that.displayName,_that.phoneE164,_that.status,_that.vehicle,_that.documents,_that.blockedDocuments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String displayName,  String? phoneE164,  OnboardingStatus? status,  Vehicle? vehicle,  List<OnboardingDocument> documents,  List<BlockedDocument> blockedDocuments)?  $default,) {final _that = this;
switch (_that) {
case _KycDriverFile() when $default != null:
return $default(_that.driverId,_that.displayName,_that.phoneE164,_that.status,_that.vehicle,_that.documents,_that.blockedDocuments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KycDriverFile implements KycDriverFile {
  const _KycDriverFile({required this.driverId, required this.displayName, this.phoneE164, this.status, this.vehicle, final  List<OnboardingDocument> documents = const <OnboardingDocument>[], final  List<BlockedDocument> blockedDocuments = const <BlockedDocument>[]}): _documents = documents,_blockedDocuments = blockedDocuments;
  factory _KycDriverFile.fromJson(Map<String, dynamic> json) => _$KycDriverFileFromJson(json);

@override final  String driverId;
@override final  String displayName;
@override final  String? phoneE164;
@override final  OnboardingStatus? status;
@override final  Vehicle? vehicle;
 final  List<OnboardingDocument> _documents;
@override@JsonKey() List<OnboardingDocument> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}

 final  List<BlockedDocument> _blockedDocuments;
@override@JsonKey() List<BlockedDocument> get blockedDocuments {
  if (_blockedDocuments is EqualUnmodifiableListView) return _blockedDocuments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blockedDocuments);
}


/// Create a copy of KycDriverFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KycDriverFileCopyWith<_KycDriverFile> get copyWith => __$KycDriverFileCopyWithImpl<_KycDriverFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KycDriverFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KycDriverFile&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164)&&(identical(other.status, status) || other.status == status)&&(identical(other.vehicle, vehicle) || other.vehicle == vehicle)&&const DeepCollectionEquality().equals(other._documents, _documents)&&const DeepCollectionEquality().equals(other._blockedDocuments, _blockedDocuments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,phoneE164,status,vehicle,const DeepCollectionEquality().hash(_documents),const DeepCollectionEquality().hash(_blockedDocuments));

@override
String toString() {
  return 'KycDriverFile(driverId: $driverId, displayName: $displayName, phoneE164: $phoneE164, status: $status, vehicle: $vehicle, documents: $documents, blockedDocuments: $blockedDocuments)';
}


}

/// @nodoc
abstract mixin class _$KycDriverFileCopyWith<$Res> implements $KycDriverFileCopyWith<$Res> {
  factory _$KycDriverFileCopyWith(_KycDriverFile value, $Res Function(_KycDriverFile) _then) = __$KycDriverFileCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String displayName, String? phoneE164, OnboardingStatus? status, Vehicle? vehicle, List<OnboardingDocument> documents, List<BlockedDocument> blockedDocuments
});


@override $VehicleCopyWith<$Res>? get vehicle;

}
/// @nodoc
class __$KycDriverFileCopyWithImpl<$Res>
    implements _$KycDriverFileCopyWith<$Res> {
  __$KycDriverFileCopyWithImpl(this._self, this._then);

  final _KycDriverFile _self;
  final $Res Function(_KycDriverFile) _then;

/// Create a copy of KycDriverFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? displayName = null,Object? phoneE164 = freezed,Object? status = freezed,Object? vehicle = freezed,Object? documents = null,Object? blockedDocuments = null,}) {
  return _then(_KycDriverFile(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,phoneE164: freezed == phoneE164 ? _self.phoneE164 : phoneE164 // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OnboardingStatus?,vehicle: freezed == vehicle ? _self.vehicle : vehicle // ignore: cast_nullable_to_non_nullable
as Vehicle?,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<OnboardingDocument>,blockedDocuments: null == blockedDocuments ? _self._blockedDocuments : blockedDocuments // ignore: cast_nullable_to_non_nullable
as List<BlockedDocument>,
  ));
}

/// Create a copy of KycDriverFile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VehicleCopyWith<$Res>? get vehicle {
    if (_self.vehicle == null) {
    return null;
  }

  return $VehicleCopyWith<$Res>(_self.vehicle!, (value) {
    return _then(_self.copyWith(vehicle: value));
  });
}
}


/// @nodoc
mixin _$AdminSubscription {

 String get driverId; String get displayName; String? get phoneE164; String? get vehiclePlate; BillingStatus get status; DateTime? get paidUntil; DateTime? get graceUntil;/// Resumen del último pago (sin periodo ni checkout).
 Payment? get lastPayment;
/// Create a copy of AdminSubscription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminSubscriptionCopyWith<AdminSubscription> get copyWith => _$AdminSubscriptionCopyWithImpl<AdminSubscription>(this as AdminSubscription, _$identity);

  /// Serializes this AdminSubscription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminSubscription&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.graceUntil, graceUntil) || other.graceUntil == graceUntil)&&(identical(other.lastPayment, lastPayment) || other.lastPayment == lastPayment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,phoneE164,vehiclePlate,status,paidUntil,graceUntil,lastPayment);

@override
String toString() {
  return 'AdminSubscription(driverId: $driverId, displayName: $displayName, phoneE164: $phoneE164, vehiclePlate: $vehiclePlate, status: $status, paidUntil: $paidUntil, graceUntil: $graceUntil, lastPayment: $lastPayment)';
}


}

/// @nodoc
abstract mixin class $AdminSubscriptionCopyWith<$Res>  {
  factory $AdminSubscriptionCopyWith(AdminSubscription value, $Res Function(AdminSubscription) _then) = _$AdminSubscriptionCopyWithImpl;
@useResult
$Res call({
 String driverId, String displayName, String? phoneE164, String? vehiclePlate, BillingStatus status, DateTime? paidUntil, DateTime? graceUntil, Payment? lastPayment
});


$PaymentCopyWith<$Res>? get lastPayment;

}
/// @nodoc
class _$AdminSubscriptionCopyWithImpl<$Res>
    implements $AdminSubscriptionCopyWith<$Res> {
  _$AdminSubscriptionCopyWithImpl(this._self, this._then);

  final AdminSubscription _self;
  final $Res Function(AdminSubscription) _then;

/// Create a copy of AdminSubscription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverId = null,Object? displayName = null,Object? phoneE164 = freezed,Object? vehiclePlate = freezed,Object? status = null,Object? paidUntil = freezed,Object? graceUntil = freezed,Object? lastPayment = freezed,}) {
  return _then(_self.copyWith(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,phoneE164: freezed == phoneE164 ? _self.phoneE164 : phoneE164 // ignore: cast_nullable_to_non_nullable
as String?,vehiclePlate: freezed == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BillingStatus,paidUntil: freezed == paidUntil ? _self.paidUntil : paidUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,graceUntil: freezed == graceUntil ? _self.graceUntil : graceUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,lastPayment: freezed == lastPayment ? _self.lastPayment : lastPayment // ignore: cast_nullable_to_non_nullable
as Payment?,
  ));
}
/// Create a copy of AdminSubscription
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentCopyWith<$Res>? get lastPayment {
    if (_self.lastPayment == null) {
    return null;
  }

  return $PaymentCopyWith<$Res>(_self.lastPayment!, (value) {
    return _then(_self.copyWith(lastPayment: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdminSubscription].
extension AdminSubscriptionPatterns on AdminSubscription {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminSubscription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminSubscription() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminSubscription value)  $default,){
final _that = this;
switch (_that) {
case _AdminSubscription():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminSubscription value)?  $default,){
final _that = this;
switch (_that) {
case _AdminSubscription() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String driverId,  String displayName,  String? phoneE164,  String? vehiclePlate,  BillingStatus status,  DateTime? paidUntil,  DateTime? graceUntil,  Payment? lastPayment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminSubscription() when $default != null:
return $default(_that.driverId,_that.displayName,_that.phoneE164,_that.vehiclePlate,_that.status,_that.paidUntil,_that.graceUntil,_that.lastPayment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String driverId,  String displayName,  String? phoneE164,  String? vehiclePlate,  BillingStatus status,  DateTime? paidUntil,  DateTime? graceUntil,  Payment? lastPayment)  $default,) {final _that = this;
switch (_that) {
case _AdminSubscription():
return $default(_that.driverId,_that.displayName,_that.phoneE164,_that.vehiclePlate,_that.status,_that.paidUntil,_that.graceUntil,_that.lastPayment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String driverId,  String displayName,  String? phoneE164,  String? vehiclePlate,  BillingStatus status,  DateTime? paidUntil,  DateTime? graceUntil,  Payment? lastPayment)?  $default,) {final _that = this;
switch (_that) {
case _AdminSubscription() when $default != null:
return $default(_that.driverId,_that.displayName,_that.phoneE164,_that.vehiclePlate,_that.status,_that.paidUntil,_that.graceUntil,_that.lastPayment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminSubscription implements AdminSubscription {
  const _AdminSubscription({required this.driverId, required this.displayName, this.phoneE164, this.vehiclePlate, required this.status, this.paidUntil, this.graceUntil, this.lastPayment});
  factory _AdminSubscription.fromJson(Map<String, dynamic> json) => _$AdminSubscriptionFromJson(json);

@override final  String driverId;
@override final  String displayName;
@override final  String? phoneE164;
@override final  String? vehiclePlate;
@override final  BillingStatus status;
@override final  DateTime? paidUntil;
@override final  DateTime? graceUntil;
/// Resumen del último pago (sin periodo ni checkout).
@override final  Payment? lastPayment;

/// Create a copy of AdminSubscription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminSubscriptionCopyWith<_AdminSubscription> get copyWith => __$AdminSubscriptionCopyWithImpl<_AdminSubscription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminSubscriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminSubscription&&(identical(other.driverId, driverId) || other.driverId == driverId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.phoneE164, phoneE164) || other.phoneE164 == phoneE164)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidUntil, paidUntil) || other.paidUntil == paidUntil)&&(identical(other.graceUntil, graceUntil) || other.graceUntil == graceUntil)&&(identical(other.lastPayment, lastPayment) || other.lastPayment == lastPayment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,driverId,displayName,phoneE164,vehiclePlate,status,paidUntil,graceUntil,lastPayment);

@override
String toString() {
  return 'AdminSubscription(driverId: $driverId, displayName: $displayName, phoneE164: $phoneE164, vehiclePlate: $vehiclePlate, status: $status, paidUntil: $paidUntil, graceUntil: $graceUntil, lastPayment: $lastPayment)';
}


}

/// @nodoc
abstract mixin class _$AdminSubscriptionCopyWith<$Res> implements $AdminSubscriptionCopyWith<$Res> {
  factory _$AdminSubscriptionCopyWith(_AdminSubscription value, $Res Function(_AdminSubscription) _then) = __$AdminSubscriptionCopyWithImpl;
@override @useResult
$Res call({
 String driverId, String displayName, String? phoneE164, String? vehiclePlate, BillingStatus status, DateTime? paidUntil, DateTime? graceUntil, Payment? lastPayment
});


@override $PaymentCopyWith<$Res>? get lastPayment;

}
/// @nodoc
class __$AdminSubscriptionCopyWithImpl<$Res>
    implements _$AdminSubscriptionCopyWith<$Res> {
  __$AdminSubscriptionCopyWithImpl(this._self, this._then);

  final _AdminSubscription _self;
  final $Res Function(_AdminSubscription) _then;

/// Create a copy of AdminSubscription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverId = null,Object? displayName = null,Object? phoneE164 = freezed,Object? vehiclePlate = freezed,Object? status = null,Object? paidUntil = freezed,Object? graceUntil = freezed,Object? lastPayment = freezed,}) {
  return _then(_AdminSubscription(
driverId: null == driverId ? _self.driverId : driverId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,phoneE164: freezed == phoneE164 ? _self.phoneE164 : phoneE164 // ignore: cast_nullable_to_non_nullable
as String?,vehiclePlate: freezed == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BillingStatus,paidUntil: freezed == paidUntil ? _self.paidUntil : paidUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,graceUntil: freezed == graceUntil ? _self.graceUntil : graceUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,lastPayment: freezed == lastPayment ? _self.lastPayment : lastPayment // ignore: cast_nullable_to_non_nullable
as Payment?,
  ));
}

/// Create a copy of AdminSubscription
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentCopyWith<$Res>? get lastPayment {
    if (_self.lastPayment == null) {
    return null;
  }

  return $PaymentCopyWith<$Res>(_self.lastPayment!, (value) {
    return _then(_self.copyWith(lastPayment: value));
  });
}
}


/// @nodoc
mixin _$CostRate {

 String get concept; String get currency; int get unitCostMicro; DateTime get effectiveFrom;
/// Create a copy of CostRate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CostRateCopyWith<CostRate> get copyWith => _$CostRateCopyWithImpl<CostRate>(this as CostRate, _$identity);

  /// Serializes this CostRate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CostRate&&(identical(other.concept, concept) || other.concept == concept)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.unitCostMicro, unitCostMicro) || other.unitCostMicro == unitCostMicro)&&(identical(other.effectiveFrom, effectiveFrom) || other.effectiveFrom == effectiveFrom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,concept,currency,unitCostMicro,effectiveFrom);

@override
String toString() {
  return 'CostRate(concept: $concept, currency: $currency, unitCostMicro: $unitCostMicro, effectiveFrom: $effectiveFrom)';
}


}

/// @nodoc
abstract mixin class $CostRateCopyWith<$Res>  {
  factory $CostRateCopyWith(CostRate value, $Res Function(CostRate) _then) = _$CostRateCopyWithImpl;
@useResult
$Res call({
 String concept, String currency, int unitCostMicro, DateTime effectiveFrom
});




}
/// @nodoc
class _$CostRateCopyWithImpl<$Res>
    implements $CostRateCopyWith<$Res> {
  _$CostRateCopyWithImpl(this._self, this._then);

  final CostRate _self;
  final $Res Function(CostRate) _then;

/// Create a copy of CostRate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? concept = null,Object? currency = null,Object? unitCostMicro = null,Object? effectiveFrom = null,}) {
  return _then(_self.copyWith(
concept: null == concept ? _self.concept : concept // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,unitCostMicro: null == unitCostMicro ? _self.unitCostMicro : unitCostMicro // ignore: cast_nullable_to_non_nullable
as int,effectiveFrom: null == effectiveFrom ? _self.effectiveFrom : effectiveFrom // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CostRate].
extension CostRatePatterns on CostRate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CostRate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CostRate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CostRate value)  $default,){
final _that = this;
switch (_that) {
case _CostRate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CostRate value)?  $default,){
final _that = this;
switch (_that) {
case _CostRate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String concept,  String currency,  int unitCostMicro,  DateTime effectiveFrom)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CostRate() when $default != null:
return $default(_that.concept,_that.currency,_that.unitCostMicro,_that.effectiveFrom);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String concept,  String currency,  int unitCostMicro,  DateTime effectiveFrom)  $default,) {final _that = this;
switch (_that) {
case _CostRate():
return $default(_that.concept,_that.currency,_that.unitCostMicro,_that.effectiveFrom);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String concept,  String currency,  int unitCostMicro,  DateTime effectiveFrom)?  $default,) {final _that = this;
switch (_that) {
case _CostRate() when $default != null:
return $default(_that.concept,_that.currency,_that.unitCostMicro,_that.effectiveFrom);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CostRate implements CostRate {
  const _CostRate({required this.concept, required this.currency, required this.unitCostMicro, required this.effectiveFrom});
  factory _CostRate.fromJson(Map<String, dynamic> json) => _$CostRateFromJson(json);

@override final  String concept;
@override final  String currency;
@override final  int unitCostMicro;
@override final  DateTime effectiveFrom;

/// Create a copy of CostRate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CostRateCopyWith<_CostRate> get copyWith => __$CostRateCopyWithImpl<_CostRate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CostRateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CostRate&&(identical(other.concept, concept) || other.concept == concept)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.unitCostMicro, unitCostMicro) || other.unitCostMicro == unitCostMicro)&&(identical(other.effectiveFrom, effectiveFrom) || other.effectiveFrom == effectiveFrom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,concept,currency,unitCostMicro,effectiveFrom);

@override
String toString() {
  return 'CostRate(concept: $concept, currency: $currency, unitCostMicro: $unitCostMicro, effectiveFrom: $effectiveFrom)';
}


}

/// @nodoc
abstract mixin class _$CostRateCopyWith<$Res> implements $CostRateCopyWith<$Res> {
  factory _$CostRateCopyWith(_CostRate value, $Res Function(_CostRate) _then) = __$CostRateCopyWithImpl;
@override @useResult
$Res call({
 String concept, String currency, int unitCostMicro, DateTime effectiveFrom
});




}
/// @nodoc
class __$CostRateCopyWithImpl<$Res>
    implements _$CostRateCopyWith<$Res> {
  __$CostRateCopyWithImpl(this._self, this._then);

  final _CostRate _self;
  final $Res Function(_CostRate) _then;

/// Create a copy of CostRate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? concept = null,Object? currency = null,Object? unitCostMicro = null,Object? effectiveFrom = null,}) {
  return _then(_CostRate(
concept: null == concept ? _self.concept : concept // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,unitCostMicro: null == unitCostMicro ? _self.unitCostMicro : unitCostMicro // ignore: cast_nullable_to_non_nullable
as int,effectiveFrom: null == effectiveFrom ? _self.effectiveFrom : effectiveFrom // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
