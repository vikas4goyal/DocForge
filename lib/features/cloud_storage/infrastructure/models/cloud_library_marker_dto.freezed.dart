// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cloud_library_marker_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CloudLibraryMarkerDto {

 int get schemaVersion; String get libraryIdentifier;
/// Create a copy of CloudLibraryMarkerDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CloudLibraryMarkerDtoCopyWith<CloudLibraryMarkerDto> get copyWith => _$CloudLibraryMarkerDtoCopyWithImpl<CloudLibraryMarkerDto>(this as CloudLibraryMarkerDto, _$identity);

  /// Serializes this CloudLibraryMarkerDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CloudLibraryMarkerDto&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.libraryIdentifier, libraryIdentifier) || other.libraryIdentifier == libraryIdentifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,libraryIdentifier);

@override
String toString() {
  return 'CloudLibraryMarkerDto(schemaVersion: $schemaVersion, libraryIdentifier: $libraryIdentifier)';
}


}

/// @nodoc
abstract mixin class $CloudLibraryMarkerDtoCopyWith<$Res>  {
  factory $CloudLibraryMarkerDtoCopyWith(CloudLibraryMarkerDto value, $Res Function(CloudLibraryMarkerDto) _then) = _$CloudLibraryMarkerDtoCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, String libraryIdentifier
});




}
/// @nodoc
class _$CloudLibraryMarkerDtoCopyWithImpl<$Res>
    implements $CloudLibraryMarkerDtoCopyWith<$Res> {
  _$CloudLibraryMarkerDtoCopyWithImpl(this._self, this._then);

  final CloudLibraryMarkerDto _self;
  final $Res Function(CloudLibraryMarkerDto) _then;

/// Create a copy of CloudLibraryMarkerDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? libraryIdentifier = null,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,libraryIdentifier: null == libraryIdentifier ? _self.libraryIdentifier : libraryIdentifier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CloudLibraryMarkerDto].
extension CloudLibraryMarkerDtoPatterns on CloudLibraryMarkerDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CloudLibraryMarkerDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CloudLibraryMarkerDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CloudLibraryMarkerDto value)  $default,){
final _that = this;
switch (_that) {
case _CloudLibraryMarkerDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CloudLibraryMarkerDto value)?  $default,){
final _that = this;
switch (_that) {
case _CloudLibraryMarkerDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  String libraryIdentifier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CloudLibraryMarkerDto() when $default != null:
return $default(_that.schemaVersion,_that.libraryIdentifier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  String libraryIdentifier)  $default,) {final _that = this;
switch (_that) {
case _CloudLibraryMarkerDto():
return $default(_that.schemaVersion,_that.libraryIdentifier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  String libraryIdentifier)?  $default,) {final _that = this;
switch (_that) {
case _CloudLibraryMarkerDto() when $default != null:
return $default(_that.schemaVersion,_that.libraryIdentifier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CloudLibraryMarkerDto extends CloudLibraryMarkerDto {
  const _CloudLibraryMarkerDto({required this.schemaVersion, required this.libraryIdentifier}): super._();
  factory _CloudLibraryMarkerDto.fromJson(Map<String, dynamic> json) => _$CloudLibraryMarkerDtoFromJson(json);

@override final  int schemaVersion;
@override final  String libraryIdentifier;

/// Create a copy of CloudLibraryMarkerDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CloudLibraryMarkerDtoCopyWith<_CloudLibraryMarkerDto> get copyWith => __$CloudLibraryMarkerDtoCopyWithImpl<_CloudLibraryMarkerDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CloudLibraryMarkerDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CloudLibraryMarkerDto&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.libraryIdentifier, libraryIdentifier) || other.libraryIdentifier == libraryIdentifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,libraryIdentifier);

@override
String toString() {
  return 'CloudLibraryMarkerDto(schemaVersion: $schemaVersion, libraryIdentifier: $libraryIdentifier)';
}


}

/// @nodoc
abstract mixin class _$CloudLibraryMarkerDtoCopyWith<$Res> implements $CloudLibraryMarkerDtoCopyWith<$Res> {
  factory _$CloudLibraryMarkerDtoCopyWith(_CloudLibraryMarkerDto value, $Res Function(_CloudLibraryMarkerDto) _then) = __$CloudLibraryMarkerDtoCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, String libraryIdentifier
});




}
/// @nodoc
class __$CloudLibraryMarkerDtoCopyWithImpl<$Res>
    implements _$CloudLibraryMarkerDtoCopyWith<$Res> {
  __$CloudLibraryMarkerDtoCopyWithImpl(this._self, this._then);

  final _CloudLibraryMarkerDto _self;
  final $Res Function(_CloudLibraryMarkerDto) _then;

/// Create a copy of CloudLibraryMarkerDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? libraryIdentifier = null,}) {
  return _then(_CloudLibraryMarkerDto(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,libraryIdentifier: null == libraryIdentifier ? _self.libraryIdentifier : libraryIdentifier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
