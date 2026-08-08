// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'native_image_processing_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NativeHomographyDto {

 double get h00; double get h01; double get h02; double get h10; double get h11; double get h12; double get h20; double get h21;
/// Create a copy of NativeHomographyDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeHomographyDtoCopyWith<NativeHomographyDto> get copyWith => _$NativeHomographyDtoCopyWithImpl<NativeHomographyDto>(this as NativeHomographyDto, _$identity);

  /// Serializes this NativeHomographyDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeHomographyDto&&(identical(other.h00, h00) || other.h00 == h00)&&(identical(other.h01, h01) || other.h01 == h01)&&(identical(other.h02, h02) || other.h02 == h02)&&(identical(other.h10, h10) || other.h10 == h10)&&(identical(other.h11, h11) || other.h11 == h11)&&(identical(other.h12, h12) || other.h12 == h12)&&(identical(other.h20, h20) || other.h20 == h20)&&(identical(other.h21, h21) || other.h21 == h21));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,h00,h01,h02,h10,h11,h12,h20,h21);

@override
String toString() {
  return 'NativeHomographyDto(h00: $h00, h01: $h01, h02: $h02, h10: $h10, h11: $h11, h12: $h12, h20: $h20, h21: $h21)';
}


}

/// @nodoc
abstract mixin class $NativeHomographyDtoCopyWith<$Res>  {
  factory $NativeHomographyDtoCopyWith(NativeHomographyDto value, $Res Function(NativeHomographyDto) _then) = _$NativeHomographyDtoCopyWithImpl;
@useResult
$Res call({
 double h00, double h01, double h02, double h10, double h11, double h12, double h20, double h21
});




}
/// @nodoc
class _$NativeHomographyDtoCopyWithImpl<$Res>
    implements $NativeHomographyDtoCopyWith<$Res> {
  _$NativeHomographyDtoCopyWithImpl(this._self, this._then);

  final NativeHomographyDto _self;
  final $Res Function(NativeHomographyDto) _then;

/// Create a copy of NativeHomographyDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? h00 = null,Object? h01 = null,Object? h02 = null,Object? h10 = null,Object? h11 = null,Object? h12 = null,Object? h20 = null,Object? h21 = null,}) {
  return _then(_self.copyWith(
h00: null == h00 ? _self.h00 : h00 // ignore: cast_nullable_to_non_nullable
as double,h01: null == h01 ? _self.h01 : h01 // ignore: cast_nullable_to_non_nullable
as double,h02: null == h02 ? _self.h02 : h02 // ignore: cast_nullable_to_non_nullable
as double,h10: null == h10 ? _self.h10 : h10 // ignore: cast_nullable_to_non_nullable
as double,h11: null == h11 ? _self.h11 : h11 // ignore: cast_nullable_to_non_nullable
as double,h12: null == h12 ? _self.h12 : h12 // ignore: cast_nullable_to_non_nullable
as double,h20: null == h20 ? _self.h20 : h20 // ignore: cast_nullable_to_non_nullable
as double,h21: null == h21 ? _self.h21 : h21 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeHomographyDto].
extension NativeHomographyDtoPatterns on NativeHomographyDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeHomographyDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeHomographyDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeHomographyDto value)  $default,){
final _that = this;
switch (_that) {
case _NativeHomographyDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeHomographyDto value)?  $default,){
final _that = this;
switch (_that) {
case _NativeHomographyDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double h00,  double h01,  double h02,  double h10,  double h11,  double h12,  double h20,  double h21)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeHomographyDto() when $default != null:
return $default(_that.h00,_that.h01,_that.h02,_that.h10,_that.h11,_that.h12,_that.h20,_that.h21);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double h00,  double h01,  double h02,  double h10,  double h11,  double h12,  double h20,  double h21)  $default,) {final _that = this;
switch (_that) {
case _NativeHomographyDto():
return $default(_that.h00,_that.h01,_that.h02,_that.h10,_that.h11,_that.h12,_that.h20,_that.h21);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double h00,  double h01,  double h02,  double h10,  double h11,  double h12,  double h20,  double h21)?  $default,) {final _that = this;
switch (_that) {
case _NativeHomographyDto() when $default != null:
return $default(_that.h00,_that.h01,_that.h02,_that.h10,_that.h11,_that.h12,_that.h20,_that.h21);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NativeHomographyDto extends NativeHomographyDto {
  const _NativeHomographyDto({required this.h00, required this.h01, required this.h02, required this.h10, required this.h11, required this.h12, required this.h20, required this.h21}): super._();
  factory _NativeHomographyDto.fromJson(Map<String, dynamic> json) => _$NativeHomographyDtoFromJson(json);

@override final  double h00;
@override final  double h01;
@override final  double h02;
@override final  double h10;
@override final  double h11;
@override final  double h12;
@override final  double h20;
@override final  double h21;

/// Create a copy of NativeHomographyDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeHomographyDtoCopyWith<_NativeHomographyDto> get copyWith => __$NativeHomographyDtoCopyWithImpl<_NativeHomographyDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NativeHomographyDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeHomographyDto&&(identical(other.h00, h00) || other.h00 == h00)&&(identical(other.h01, h01) || other.h01 == h01)&&(identical(other.h02, h02) || other.h02 == h02)&&(identical(other.h10, h10) || other.h10 == h10)&&(identical(other.h11, h11) || other.h11 == h11)&&(identical(other.h12, h12) || other.h12 == h12)&&(identical(other.h20, h20) || other.h20 == h20)&&(identical(other.h21, h21) || other.h21 == h21));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,h00,h01,h02,h10,h11,h12,h20,h21);

@override
String toString() {
  return 'NativeHomographyDto(h00: $h00, h01: $h01, h02: $h02, h10: $h10, h11: $h11, h12: $h12, h20: $h20, h21: $h21)';
}


}

/// @nodoc
abstract mixin class _$NativeHomographyDtoCopyWith<$Res> implements $NativeHomographyDtoCopyWith<$Res> {
  factory _$NativeHomographyDtoCopyWith(_NativeHomographyDto value, $Res Function(_NativeHomographyDto) _then) = __$NativeHomographyDtoCopyWithImpl;
@override @useResult
$Res call({
 double h00, double h01, double h02, double h10, double h11, double h12, double h20, double h21
});




}
/// @nodoc
class __$NativeHomographyDtoCopyWithImpl<$Res>
    implements _$NativeHomographyDtoCopyWith<$Res> {
  __$NativeHomographyDtoCopyWithImpl(this._self, this._then);

  final _NativeHomographyDto _self;
  final $Res Function(_NativeHomographyDto) _then;

/// Create a copy of NativeHomographyDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? h00 = null,Object? h01 = null,Object? h02 = null,Object? h10 = null,Object? h11 = null,Object? h12 = null,Object? h20 = null,Object? h21 = null,}) {
  return _then(_NativeHomographyDto(
h00: null == h00 ? _self.h00 : h00 // ignore: cast_nullable_to_non_nullable
as double,h01: null == h01 ? _self.h01 : h01 // ignore: cast_nullable_to_non_nullable
as double,h02: null == h02 ? _self.h02 : h02 // ignore: cast_nullable_to_non_nullable
as double,h10: null == h10 ? _self.h10 : h10 // ignore: cast_nullable_to_non_nullable
as double,h11: null == h11 ? _self.h11 : h11 // ignore: cast_nullable_to_non_nullable
as double,h12: null == h12 ? _self.h12 : h12 // ignore: cast_nullable_to_non_nullable
as double,h20: null == h20 ? _self.h20 : h20 // ignore: cast_nullable_to_non_nullable
as double,h21: null == h21 ? _self.h21 : h21 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$NativeEnhancementSettingsDto {

 EnhancementFilter get filter; double get brightness; double get contrast; double get sharpen; bool get shadowRemoval;
/// Create a copy of NativeEnhancementSettingsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeEnhancementSettingsDtoCopyWith<NativeEnhancementSettingsDto> get copyWith => _$NativeEnhancementSettingsDtoCopyWithImpl<NativeEnhancementSettingsDto>(this as NativeEnhancementSettingsDto, _$identity);

  /// Serializes this NativeEnhancementSettingsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeEnhancementSettingsDto&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.contrast, contrast) || other.contrast == contrast)&&(identical(other.sharpen, sharpen) || other.sharpen == sharpen)&&(identical(other.shadowRemoval, shadowRemoval) || other.shadowRemoval == shadowRemoval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,filter,brightness,contrast,sharpen,shadowRemoval);

@override
String toString() {
  return 'NativeEnhancementSettingsDto(filter: $filter, brightness: $brightness, contrast: $contrast, sharpen: $sharpen, shadowRemoval: $shadowRemoval)';
}


}

/// @nodoc
abstract mixin class $NativeEnhancementSettingsDtoCopyWith<$Res>  {
  factory $NativeEnhancementSettingsDtoCopyWith(NativeEnhancementSettingsDto value, $Res Function(NativeEnhancementSettingsDto) _then) = _$NativeEnhancementSettingsDtoCopyWithImpl;
@useResult
$Res call({
 EnhancementFilter filter, double brightness, double contrast, double sharpen, bool shadowRemoval
});




}
/// @nodoc
class _$NativeEnhancementSettingsDtoCopyWithImpl<$Res>
    implements $NativeEnhancementSettingsDtoCopyWith<$Res> {
  _$NativeEnhancementSettingsDtoCopyWithImpl(this._self, this._then);

  final NativeEnhancementSettingsDto _self;
  final $Res Function(NativeEnhancementSettingsDto) _then;

/// Create a copy of NativeEnhancementSettingsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? filter = null,Object? brightness = null,Object? contrast = null,Object? sharpen = null,Object? shadowRemoval = null,}) {
  return _then(_self.copyWith(
filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as EnhancementFilter,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as double,contrast: null == contrast ? _self.contrast : contrast // ignore: cast_nullable_to_non_nullable
as double,sharpen: null == sharpen ? _self.sharpen : sharpen // ignore: cast_nullable_to_non_nullable
as double,shadowRemoval: null == shadowRemoval ? _self.shadowRemoval : shadowRemoval // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeEnhancementSettingsDto].
extension NativeEnhancementSettingsDtoPatterns on NativeEnhancementSettingsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeEnhancementSettingsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeEnhancementSettingsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeEnhancementSettingsDto value)  $default,){
final _that = this;
switch (_that) {
case _NativeEnhancementSettingsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeEnhancementSettingsDto value)?  $default,){
final _that = this;
switch (_that) {
case _NativeEnhancementSettingsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EnhancementFilter filter,  double brightness,  double contrast,  double sharpen,  bool shadowRemoval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeEnhancementSettingsDto() when $default != null:
return $default(_that.filter,_that.brightness,_that.contrast,_that.sharpen,_that.shadowRemoval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EnhancementFilter filter,  double brightness,  double contrast,  double sharpen,  bool shadowRemoval)  $default,) {final _that = this;
switch (_that) {
case _NativeEnhancementSettingsDto():
return $default(_that.filter,_that.brightness,_that.contrast,_that.sharpen,_that.shadowRemoval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EnhancementFilter filter,  double brightness,  double contrast,  double sharpen,  bool shadowRemoval)?  $default,) {final _that = this;
switch (_that) {
case _NativeEnhancementSettingsDto() when $default != null:
return $default(_that.filter,_that.brightness,_that.contrast,_that.sharpen,_that.shadowRemoval);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NativeEnhancementSettingsDto extends NativeEnhancementSettingsDto {
  const _NativeEnhancementSettingsDto({required this.filter, required this.brightness, required this.contrast, required this.sharpen, required this.shadowRemoval}): super._();
  factory _NativeEnhancementSettingsDto.fromJson(Map<String, dynamic> json) => _$NativeEnhancementSettingsDtoFromJson(json);

@override final  EnhancementFilter filter;
@override final  double brightness;
@override final  double contrast;
@override final  double sharpen;
@override final  bool shadowRemoval;

/// Create a copy of NativeEnhancementSettingsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeEnhancementSettingsDtoCopyWith<_NativeEnhancementSettingsDto> get copyWith => __$NativeEnhancementSettingsDtoCopyWithImpl<_NativeEnhancementSettingsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NativeEnhancementSettingsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeEnhancementSettingsDto&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.contrast, contrast) || other.contrast == contrast)&&(identical(other.sharpen, sharpen) || other.sharpen == sharpen)&&(identical(other.shadowRemoval, shadowRemoval) || other.shadowRemoval == shadowRemoval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,filter,brightness,contrast,sharpen,shadowRemoval);

@override
String toString() {
  return 'NativeEnhancementSettingsDto(filter: $filter, brightness: $brightness, contrast: $contrast, sharpen: $sharpen, shadowRemoval: $shadowRemoval)';
}


}

/// @nodoc
abstract mixin class _$NativeEnhancementSettingsDtoCopyWith<$Res> implements $NativeEnhancementSettingsDtoCopyWith<$Res> {
  factory _$NativeEnhancementSettingsDtoCopyWith(_NativeEnhancementSettingsDto value, $Res Function(_NativeEnhancementSettingsDto) _then) = __$NativeEnhancementSettingsDtoCopyWithImpl;
@override @useResult
$Res call({
 EnhancementFilter filter, double brightness, double contrast, double sharpen, bool shadowRemoval
});




}
/// @nodoc
class __$NativeEnhancementSettingsDtoCopyWithImpl<$Res>
    implements _$NativeEnhancementSettingsDtoCopyWith<$Res> {
  __$NativeEnhancementSettingsDtoCopyWithImpl(this._self, this._then);

  final _NativeEnhancementSettingsDto _self;
  final $Res Function(_NativeEnhancementSettingsDto) _then;

/// Create a copy of NativeEnhancementSettingsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? filter = null,Object? brightness = null,Object? contrast = null,Object? sharpen = null,Object? shadowRemoval = null,}) {
  return _then(_NativeEnhancementSettingsDto(
filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as EnhancementFilter,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as double,contrast: null == contrast ? _self.contrast : contrast // ignore: cast_nullable_to_non_nullable
as double,sharpen: null == sharpen ? _self.sharpen : sharpen // ignore: cast_nullable_to_non_nullable
as double,shadowRemoval: null == shadowRemoval ? _self.shadowRemoval : shadowRemoval // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$NativeImageRenderRequestDto {

 int get schemaVersion; String get requestId; String get sourcePath; String get destinationPath; ImageRenderScale get scale; NativeEnhancementSettingsDto get enhancement; int get jpegQuality; int get colourPipelineVersion; NativeHomographyDto? get transform; int? get outputWidth; int? get outputHeight; int? get maximumPreviewDimension;
/// Create a copy of NativeImageRenderRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeImageRenderRequestDtoCopyWith<NativeImageRenderRequestDto> get copyWith => _$NativeImageRenderRequestDtoCopyWithImpl<NativeImageRenderRequestDto>(this as NativeImageRenderRequestDto, _$identity);

  /// Serializes this NativeImageRenderRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeImageRenderRequestDto&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.destinationPath, destinationPath) || other.destinationPath == destinationPath)&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.enhancement, enhancement) || other.enhancement == enhancement)&&(identical(other.jpegQuality, jpegQuality) || other.jpegQuality == jpegQuality)&&(identical(other.colourPipelineVersion, colourPipelineVersion) || other.colourPipelineVersion == colourPipelineVersion)&&(identical(other.transform, transform) || other.transform == transform)&&(identical(other.outputWidth, outputWidth) || other.outputWidth == outputWidth)&&(identical(other.outputHeight, outputHeight) || other.outputHeight == outputHeight)&&(identical(other.maximumPreviewDimension, maximumPreviewDimension) || other.maximumPreviewDimension == maximumPreviewDimension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,requestId,sourcePath,destinationPath,scale,enhancement,jpegQuality,colourPipelineVersion,transform,outputWidth,outputHeight,maximumPreviewDimension);

@override
String toString() {
  return 'NativeImageRenderRequestDto(schemaVersion: $schemaVersion, requestId: $requestId, sourcePath: $sourcePath, destinationPath: $destinationPath, scale: $scale, enhancement: $enhancement, jpegQuality: $jpegQuality, colourPipelineVersion: $colourPipelineVersion, transform: $transform, outputWidth: $outputWidth, outputHeight: $outputHeight, maximumPreviewDimension: $maximumPreviewDimension)';
}


}

/// @nodoc
abstract mixin class $NativeImageRenderRequestDtoCopyWith<$Res>  {
  factory $NativeImageRenderRequestDtoCopyWith(NativeImageRenderRequestDto value, $Res Function(NativeImageRenderRequestDto) _then) = _$NativeImageRenderRequestDtoCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, String requestId, String sourcePath, String destinationPath, ImageRenderScale scale, NativeEnhancementSettingsDto enhancement, int jpegQuality, int colourPipelineVersion, NativeHomographyDto? transform, int? outputWidth, int? outputHeight, int? maximumPreviewDimension
});


$NativeEnhancementSettingsDtoCopyWith<$Res> get enhancement;$NativeHomographyDtoCopyWith<$Res>? get transform;

}
/// @nodoc
class _$NativeImageRenderRequestDtoCopyWithImpl<$Res>
    implements $NativeImageRenderRequestDtoCopyWith<$Res> {
  _$NativeImageRenderRequestDtoCopyWithImpl(this._self, this._then);

  final NativeImageRenderRequestDto _self;
  final $Res Function(NativeImageRenderRequestDto) _then;

/// Create a copy of NativeImageRenderRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? requestId = null,Object? sourcePath = null,Object? destinationPath = null,Object? scale = null,Object? enhancement = null,Object? jpegQuality = null,Object? colourPipelineVersion = null,Object? transform = freezed,Object? outputWidth = freezed,Object? outputHeight = freezed,Object? maximumPreviewDimension = freezed,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,destinationPath: null == destinationPath ? _self.destinationPath : destinationPath // ignore: cast_nullable_to_non_nullable
as String,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as ImageRenderScale,enhancement: null == enhancement ? _self.enhancement : enhancement // ignore: cast_nullable_to_non_nullable
as NativeEnhancementSettingsDto,jpegQuality: null == jpegQuality ? _self.jpegQuality : jpegQuality // ignore: cast_nullable_to_non_nullable
as int,colourPipelineVersion: null == colourPipelineVersion ? _self.colourPipelineVersion : colourPipelineVersion // ignore: cast_nullable_to_non_nullable
as int,transform: freezed == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as NativeHomographyDto?,outputWidth: freezed == outputWidth ? _self.outputWidth : outputWidth // ignore: cast_nullable_to_non_nullable
as int?,outputHeight: freezed == outputHeight ? _self.outputHeight : outputHeight // ignore: cast_nullable_to_non_nullable
as int?,maximumPreviewDimension: freezed == maximumPreviewDimension ? _self.maximumPreviewDimension : maximumPreviewDimension // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of NativeImageRenderRequestDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeEnhancementSettingsDtoCopyWith<$Res> get enhancement {
  
  return $NativeEnhancementSettingsDtoCopyWith<$Res>(_self.enhancement, (value) {
    return _then(_self.copyWith(enhancement: value));
  });
}/// Create a copy of NativeImageRenderRequestDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeHomographyDtoCopyWith<$Res>? get transform {
    if (_self.transform == null) {
    return null;
  }

  return $NativeHomographyDtoCopyWith<$Res>(_self.transform!, (value) {
    return _then(_self.copyWith(transform: value));
  });
}
}


/// Adds pattern-matching-related methods to [NativeImageRenderRequestDto].
extension NativeImageRenderRequestDtoPatterns on NativeImageRenderRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeImageRenderRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeImageRenderRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeImageRenderRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _NativeImageRenderRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeImageRenderRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _NativeImageRenderRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  String requestId,  String sourcePath,  String destinationPath,  ImageRenderScale scale,  NativeEnhancementSettingsDto enhancement,  int jpegQuality,  int colourPipelineVersion,  NativeHomographyDto? transform,  int? outputWidth,  int? outputHeight,  int? maximumPreviewDimension)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeImageRenderRequestDto() when $default != null:
return $default(_that.schemaVersion,_that.requestId,_that.sourcePath,_that.destinationPath,_that.scale,_that.enhancement,_that.jpegQuality,_that.colourPipelineVersion,_that.transform,_that.outputWidth,_that.outputHeight,_that.maximumPreviewDimension);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  String requestId,  String sourcePath,  String destinationPath,  ImageRenderScale scale,  NativeEnhancementSettingsDto enhancement,  int jpegQuality,  int colourPipelineVersion,  NativeHomographyDto? transform,  int? outputWidth,  int? outputHeight,  int? maximumPreviewDimension)  $default,) {final _that = this;
switch (_that) {
case _NativeImageRenderRequestDto():
return $default(_that.schemaVersion,_that.requestId,_that.sourcePath,_that.destinationPath,_that.scale,_that.enhancement,_that.jpegQuality,_that.colourPipelineVersion,_that.transform,_that.outputWidth,_that.outputHeight,_that.maximumPreviewDimension);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  String requestId,  String sourcePath,  String destinationPath,  ImageRenderScale scale,  NativeEnhancementSettingsDto enhancement,  int jpegQuality,  int colourPipelineVersion,  NativeHomographyDto? transform,  int? outputWidth,  int? outputHeight,  int? maximumPreviewDimension)?  $default,) {final _that = this;
switch (_that) {
case _NativeImageRenderRequestDto() when $default != null:
return $default(_that.schemaVersion,_that.requestId,_that.sourcePath,_that.destinationPath,_that.scale,_that.enhancement,_that.jpegQuality,_that.colourPipelineVersion,_that.transform,_that.outputWidth,_that.outputHeight,_that.maximumPreviewDimension);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NativeImageRenderRequestDto extends NativeImageRenderRequestDto {
  const _NativeImageRenderRequestDto({required this.schemaVersion, required this.requestId, required this.sourcePath, required this.destinationPath, required this.scale, required this.enhancement, required this.jpegQuality, required this.colourPipelineVersion, this.transform, this.outputWidth, this.outputHeight, this.maximumPreviewDimension}): super._();
  factory _NativeImageRenderRequestDto.fromJson(Map<String, dynamic> json) => _$NativeImageRenderRequestDtoFromJson(json);

@override final  int schemaVersion;
@override final  String requestId;
@override final  String sourcePath;
@override final  String destinationPath;
@override final  ImageRenderScale scale;
@override final  NativeEnhancementSettingsDto enhancement;
@override final  int jpegQuality;
@override final  int colourPipelineVersion;
@override final  NativeHomographyDto? transform;
@override final  int? outputWidth;
@override final  int? outputHeight;
@override final  int? maximumPreviewDimension;

/// Create a copy of NativeImageRenderRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeImageRenderRequestDtoCopyWith<_NativeImageRenderRequestDto> get copyWith => __$NativeImageRenderRequestDtoCopyWithImpl<_NativeImageRenderRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NativeImageRenderRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeImageRenderRequestDto&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.destinationPath, destinationPath) || other.destinationPath == destinationPath)&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.enhancement, enhancement) || other.enhancement == enhancement)&&(identical(other.jpegQuality, jpegQuality) || other.jpegQuality == jpegQuality)&&(identical(other.colourPipelineVersion, colourPipelineVersion) || other.colourPipelineVersion == colourPipelineVersion)&&(identical(other.transform, transform) || other.transform == transform)&&(identical(other.outputWidth, outputWidth) || other.outputWidth == outputWidth)&&(identical(other.outputHeight, outputHeight) || other.outputHeight == outputHeight)&&(identical(other.maximumPreviewDimension, maximumPreviewDimension) || other.maximumPreviewDimension == maximumPreviewDimension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,requestId,sourcePath,destinationPath,scale,enhancement,jpegQuality,colourPipelineVersion,transform,outputWidth,outputHeight,maximumPreviewDimension);

@override
String toString() {
  return 'NativeImageRenderRequestDto(schemaVersion: $schemaVersion, requestId: $requestId, sourcePath: $sourcePath, destinationPath: $destinationPath, scale: $scale, enhancement: $enhancement, jpegQuality: $jpegQuality, colourPipelineVersion: $colourPipelineVersion, transform: $transform, outputWidth: $outputWidth, outputHeight: $outputHeight, maximumPreviewDimension: $maximumPreviewDimension)';
}


}

/// @nodoc
abstract mixin class _$NativeImageRenderRequestDtoCopyWith<$Res> implements $NativeImageRenderRequestDtoCopyWith<$Res> {
  factory _$NativeImageRenderRequestDtoCopyWith(_NativeImageRenderRequestDto value, $Res Function(_NativeImageRenderRequestDto) _then) = __$NativeImageRenderRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, String requestId, String sourcePath, String destinationPath, ImageRenderScale scale, NativeEnhancementSettingsDto enhancement, int jpegQuality, int colourPipelineVersion, NativeHomographyDto? transform, int? outputWidth, int? outputHeight, int? maximumPreviewDimension
});


@override $NativeEnhancementSettingsDtoCopyWith<$Res> get enhancement;@override $NativeHomographyDtoCopyWith<$Res>? get transform;

}
/// @nodoc
class __$NativeImageRenderRequestDtoCopyWithImpl<$Res>
    implements _$NativeImageRenderRequestDtoCopyWith<$Res> {
  __$NativeImageRenderRequestDtoCopyWithImpl(this._self, this._then);

  final _NativeImageRenderRequestDto _self;
  final $Res Function(_NativeImageRenderRequestDto) _then;

/// Create a copy of NativeImageRenderRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? requestId = null,Object? sourcePath = null,Object? destinationPath = null,Object? scale = null,Object? enhancement = null,Object? jpegQuality = null,Object? colourPipelineVersion = null,Object? transform = freezed,Object? outputWidth = freezed,Object? outputHeight = freezed,Object? maximumPreviewDimension = freezed,}) {
  return _then(_NativeImageRenderRequestDto(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,destinationPath: null == destinationPath ? _self.destinationPath : destinationPath // ignore: cast_nullable_to_non_nullable
as String,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as ImageRenderScale,enhancement: null == enhancement ? _self.enhancement : enhancement // ignore: cast_nullable_to_non_nullable
as NativeEnhancementSettingsDto,jpegQuality: null == jpegQuality ? _self.jpegQuality : jpegQuality // ignore: cast_nullable_to_non_nullable
as int,colourPipelineVersion: null == colourPipelineVersion ? _self.colourPipelineVersion : colourPipelineVersion // ignore: cast_nullable_to_non_nullable
as int,transform: freezed == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as NativeHomographyDto?,outputWidth: freezed == outputWidth ? _self.outputWidth : outputWidth // ignore: cast_nullable_to_non_nullable
as int?,outputHeight: freezed == outputHeight ? _self.outputHeight : outputHeight // ignore: cast_nullable_to_non_nullable
as int?,maximumPreviewDimension: freezed == maximumPreviewDimension ? _self.maximumPreviewDimension : maximumPreviewDimension // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of NativeImageRenderRequestDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeEnhancementSettingsDtoCopyWith<$Res> get enhancement {
  
  return $NativeEnhancementSettingsDtoCopyWith<$Res>(_self.enhancement, (value) {
    return _then(_self.copyWith(enhancement: value));
  });
}/// Create a copy of NativeImageRenderRequestDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeHomographyDtoCopyWith<$Res>? get transform {
    if (_self.transform == null) {
    return null;
  }

  return $NativeHomographyDtoCopyWith<$Res>(_self.transform!, (value) {
    return _then(_self.copyWith(transform: value));
  });
}
}


/// @nodoc
mixin _$NativeImageProcessingCapabilityDto {

 int get schemaVersion; ImageProcessingBackendKind get backend; bool get isSupported; int get maximumTextureSize; bool get supportsTiling;
/// Create a copy of NativeImageProcessingCapabilityDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeImageProcessingCapabilityDtoCopyWith<NativeImageProcessingCapabilityDto> get copyWith => _$NativeImageProcessingCapabilityDtoCopyWithImpl<NativeImageProcessingCapabilityDto>(this as NativeImageProcessingCapabilityDto, _$identity);

  /// Serializes this NativeImageProcessingCapabilityDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeImageProcessingCapabilityDto&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.backend, backend) || other.backend == backend)&&(identical(other.isSupported, isSupported) || other.isSupported == isSupported)&&(identical(other.maximumTextureSize, maximumTextureSize) || other.maximumTextureSize == maximumTextureSize)&&(identical(other.supportsTiling, supportsTiling) || other.supportsTiling == supportsTiling));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,backend,isSupported,maximumTextureSize,supportsTiling);

@override
String toString() {
  return 'NativeImageProcessingCapabilityDto(schemaVersion: $schemaVersion, backend: $backend, isSupported: $isSupported, maximumTextureSize: $maximumTextureSize, supportsTiling: $supportsTiling)';
}


}

/// @nodoc
abstract mixin class $NativeImageProcessingCapabilityDtoCopyWith<$Res>  {
  factory $NativeImageProcessingCapabilityDtoCopyWith(NativeImageProcessingCapabilityDto value, $Res Function(NativeImageProcessingCapabilityDto) _then) = _$NativeImageProcessingCapabilityDtoCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, ImageProcessingBackendKind backend, bool isSupported, int maximumTextureSize, bool supportsTiling
});




}
/// @nodoc
class _$NativeImageProcessingCapabilityDtoCopyWithImpl<$Res>
    implements $NativeImageProcessingCapabilityDtoCopyWith<$Res> {
  _$NativeImageProcessingCapabilityDtoCopyWithImpl(this._self, this._then);

  final NativeImageProcessingCapabilityDto _self;
  final $Res Function(NativeImageProcessingCapabilityDto) _then;

/// Create a copy of NativeImageProcessingCapabilityDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? backend = null,Object? isSupported = null,Object? maximumTextureSize = null,Object? supportsTiling = null,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,backend: null == backend ? _self.backend : backend // ignore: cast_nullable_to_non_nullable
as ImageProcessingBackendKind,isSupported: null == isSupported ? _self.isSupported : isSupported // ignore: cast_nullable_to_non_nullable
as bool,maximumTextureSize: null == maximumTextureSize ? _self.maximumTextureSize : maximumTextureSize // ignore: cast_nullable_to_non_nullable
as int,supportsTiling: null == supportsTiling ? _self.supportsTiling : supportsTiling // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeImageProcessingCapabilityDto].
extension NativeImageProcessingCapabilityDtoPatterns on NativeImageProcessingCapabilityDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeImageProcessingCapabilityDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeImageProcessingCapabilityDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeImageProcessingCapabilityDto value)  $default,){
final _that = this;
switch (_that) {
case _NativeImageProcessingCapabilityDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeImageProcessingCapabilityDto value)?  $default,){
final _that = this;
switch (_that) {
case _NativeImageProcessingCapabilityDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  ImageProcessingBackendKind backend,  bool isSupported,  int maximumTextureSize,  bool supportsTiling)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeImageProcessingCapabilityDto() when $default != null:
return $default(_that.schemaVersion,_that.backend,_that.isSupported,_that.maximumTextureSize,_that.supportsTiling);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  ImageProcessingBackendKind backend,  bool isSupported,  int maximumTextureSize,  bool supportsTiling)  $default,) {final _that = this;
switch (_that) {
case _NativeImageProcessingCapabilityDto():
return $default(_that.schemaVersion,_that.backend,_that.isSupported,_that.maximumTextureSize,_that.supportsTiling);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  ImageProcessingBackendKind backend,  bool isSupported,  int maximumTextureSize,  bool supportsTiling)?  $default,) {final _that = this;
switch (_that) {
case _NativeImageProcessingCapabilityDto() when $default != null:
return $default(_that.schemaVersion,_that.backend,_that.isSupported,_that.maximumTextureSize,_that.supportsTiling);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NativeImageProcessingCapabilityDto extends NativeImageProcessingCapabilityDto {
  const _NativeImageProcessingCapabilityDto({required this.schemaVersion, required this.backend, required this.isSupported, required this.maximumTextureSize, required this.supportsTiling}): super._();
  factory _NativeImageProcessingCapabilityDto.fromJson(Map<String, dynamic> json) => _$NativeImageProcessingCapabilityDtoFromJson(json);

@override final  int schemaVersion;
@override final  ImageProcessingBackendKind backend;
@override final  bool isSupported;
@override final  int maximumTextureSize;
@override final  bool supportsTiling;

/// Create a copy of NativeImageProcessingCapabilityDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeImageProcessingCapabilityDtoCopyWith<_NativeImageProcessingCapabilityDto> get copyWith => __$NativeImageProcessingCapabilityDtoCopyWithImpl<_NativeImageProcessingCapabilityDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NativeImageProcessingCapabilityDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeImageProcessingCapabilityDto&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.backend, backend) || other.backend == backend)&&(identical(other.isSupported, isSupported) || other.isSupported == isSupported)&&(identical(other.maximumTextureSize, maximumTextureSize) || other.maximumTextureSize == maximumTextureSize)&&(identical(other.supportsTiling, supportsTiling) || other.supportsTiling == supportsTiling));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,backend,isSupported,maximumTextureSize,supportsTiling);

@override
String toString() {
  return 'NativeImageProcessingCapabilityDto(schemaVersion: $schemaVersion, backend: $backend, isSupported: $isSupported, maximumTextureSize: $maximumTextureSize, supportsTiling: $supportsTiling)';
}


}

/// @nodoc
abstract mixin class _$NativeImageProcessingCapabilityDtoCopyWith<$Res> implements $NativeImageProcessingCapabilityDtoCopyWith<$Res> {
  factory _$NativeImageProcessingCapabilityDtoCopyWith(_NativeImageProcessingCapabilityDto value, $Res Function(_NativeImageProcessingCapabilityDto) _then) = __$NativeImageProcessingCapabilityDtoCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, ImageProcessingBackendKind backend, bool isSupported, int maximumTextureSize, bool supportsTiling
});




}
/// @nodoc
class __$NativeImageProcessingCapabilityDtoCopyWithImpl<$Res>
    implements _$NativeImageProcessingCapabilityDtoCopyWith<$Res> {
  __$NativeImageProcessingCapabilityDtoCopyWithImpl(this._self, this._then);

  final _NativeImageProcessingCapabilityDto _self;
  final $Res Function(_NativeImageProcessingCapabilityDto) _then;

/// Create a copy of NativeImageProcessingCapabilityDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? backend = null,Object? isSupported = null,Object? maximumTextureSize = null,Object? supportsTiling = null,}) {
  return _then(_NativeImageProcessingCapabilityDto(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,backend: null == backend ? _self.backend : backend // ignore: cast_nullable_to_non_nullable
as ImageProcessingBackendKind,isSupported: null == isSupported ? _self.isSupported : isSupported // ignore: cast_nullable_to_non_nullable
as bool,maximumTextureSize: null == maximumTextureSize ? _self.maximumTextureSize : maximumTextureSize // ignore: cast_nullable_to_non_nullable
as int,supportsTiling: null == supportsTiling ? _self.supportsTiling : supportsTiling // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$NativeImageProcessingTimingsDto {

 int get decodeMicroseconds; int get transformMicroseconds; int get encodeMicroseconds; int get totalMicroseconds;
/// Create a copy of NativeImageProcessingTimingsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeImageProcessingTimingsDtoCopyWith<NativeImageProcessingTimingsDto> get copyWith => _$NativeImageProcessingTimingsDtoCopyWithImpl<NativeImageProcessingTimingsDto>(this as NativeImageProcessingTimingsDto, _$identity);

  /// Serializes this NativeImageProcessingTimingsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeImageProcessingTimingsDto&&(identical(other.decodeMicroseconds, decodeMicroseconds) || other.decodeMicroseconds == decodeMicroseconds)&&(identical(other.transformMicroseconds, transformMicroseconds) || other.transformMicroseconds == transformMicroseconds)&&(identical(other.encodeMicroseconds, encodeMicroseconds) || other.encodeMicroseconds == encodeMicroseconds)&&(identical(other.totalMicroseconds, totalMicroseconds) || other.totalMicroseconds == totalMicroseconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,decodeMicroseconds,transformMicroseconds,encodeMicroseconds,totalMicroseconds);

@override
String toString() {
  return 'NativeImageProcessingTimingsDto(decodeMicroseconds: $decodeMicroseconds, transformMicroseconds: $transformMicroseconds, encodeMicroseconds: $encodeMicroseconds, totalMicroseconds: $totalMicroseconds)';
}


}

/// @nodoc
abstract mixin class $NativeImageProcessingTimingsDtoCopyWith<$Res>  {
  factory $NativeImageProcessingTimingsDtoCopyWith(NativeImageProcessingTimingsDto value, $Res Function(NativeImageProcessingTimingsDto) _then) = _$NativeImageProcessingTimingsDtoCopyWithImpl;
@useResult
$Res call({
 int decodeMicroseconds, int transformMicroseconds, int encodeMicroseconds, int totalMicroseconds
});




}
/// @nodoc
class _$NativeImageProcessingTimingsDtoCopyWithImpl<$Res>
    implements $NativeImageProcessingTimingsDtoCopyWith<$Res> {
  _$NativeImageProcessingTimingsDtoCopyWithImpl(this._self, this._then);

  final NativeImageProcessingTimingsDto _self;
  final $Res Function(NativeImageProcessingTimingsDto) _then;

/// Create a copy of NativeImageProcessingTimingsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? decodeMicroseconds = null,Object? transformMicroseconds = null,Object? encodeMicroseconds = null,Object? totalMicroseconds = null,}) {
  return _then(_self.copyWith(
decodeMicroseconds: null == decodeMicroseconds ? _self.decodeMicroseconds : decodeMicroseconds // ignore: cast_nullable_to_non_nullable
as int,transformMicroseconds: null == transformMicroseconds ? _self.transformMicroseconds : transformMicroseconds // ignore: cast_nullable_to_non_nullable
as int,encodeMicroseconds: null == encodeMicroseconds ? _self.encodeMicroseconds : encodeMicroseconds // ignore: cast_nullable_to_non_nullable
as int,totalMicroseconds: null == totalMicroseconds ? _self.totalMicroseconds : totalMicroseconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NativeImageProcessingTimingsDto].
extension NativeImageProcessingTimingsDtoPatterns on NativeImageProcessingTimingsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeImageProcessingTimingsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeImageProcessingTimingsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeImageProcessingTimingsDto value)  $default,){
final _that = this;
switch (_that) {
case _NativeImageProcessingTimingsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeImageProcessingTimingsDto value)?  $default,){
final _that = this;
switch (_that) {
case _NativeImageProcessingTimingsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int decodeMicroseconds,  int transformMicroseconds,  int encodeMicroseconds,  int totalMicroseconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeImageProcessingTimingsDto() when $default != null:
return $default(_that.decodeMicroseconds,_that.transformMicroseconds,_that.encodeMicroseconds,_that.totalMicroseconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int decodeMicroseconds,  int transformMicroseconds,  int encodeMicroseconds,  int totalMicroseconds)  $default,) {final _that = this;
switch (_that) {
case _NativeImageProcessingTimingsDto():
return $default(_that.decodeMicroseconds,_that.transformMicroseconds,_that.encodeMicroseconds,_that.totalMicroseconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int decodeMicroseconds,  int transformMicroseconds,  int encodeMicroseconds,  int totalMicroseconds)?  $default,) {final _that = this;
switch (_that) {
case _NativeImageProcessingTimingsDto() when $default != null:
return $default(_that.decodeMicroseconds,_that.transformMicroseconds,_that.encodeMicroseconds,_that.totalMicroseconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NativeImageProcessingTimingsDto extends NativeImageProcessingTimingsDto {
  const _NativeImageProcessingTimingsDto({required this.decodeMicroseconds, required this.transformMicroseconds, required this.encodeMicroseconds, required this.totalMicroseconds}): super._();
  factory _NativeImageProcessingTimingsDto.fromJson(Map<String, dynamic> json) => _$NativeImageProcessingTimingsDtoFromJson(json);

@override final  int decodeMicroseconds;
@override final  int transformMicroseconds;
@override final  int encodeMicroseconds;
@override final  int totalMicroseconds;

/// Create a copy of NativeImageProcessingTimingsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeImageProcessingTimingsDtoCopyWith<_NativeImageProcessingTimingsDto> get copyWith => __$NativeImageProcessingTimingsDtoCopyWithImpl<_NativeImageProcessingTimingsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NativeImageProcessingTimingsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeImageProcessingTimingsDto&&(identical(other.decodeMicroseconds, decodeMicroseconds) || other.decodeMicroseconds == decodeMicroseconds)&&(identical(other.transformMicroseconds, transformMicroseconds) || other.transformMicroseconds == transformMicroseconds)&&(identical(other.encodeMicroseconds, encodeMicroseconds) || other.encodeMicroseconds == encodeMicroseconds)&&(identical(other.totalMicroseconds, totalMicroseconds) || other.totalMicroseconds == totalMicroseconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,decodeMicroseconds,transformMicroseconds,encodeMicroseconds,totalMicroseconds);

@override
String toString() {
  return 'NativeImageProcessingTimingsDto(decodeMicroseconds: $decodeMicroseconds, transformMicroseconds: $transformMicroseconds, encodeMicroseconds: $encodeMicroseconds, totalMicroseconds: $totalMicroseconds)';
}


}

/// @nodoc
abstract mixin class _$NativeImageProcessingTimingsDtoCopyWith<$Res> implements $NativeImageProcessingTimingsDtoCopyWith<$Res> {
  factory _$NativeImageProcessingTimingsDtoCopyWith(_NativeImageProcessingTimingsDto value, $Res Function(_NativeImageProcessingTimingsDto) _then) = __$NativeImageProcessingTimingsDtoCopyWithImpl;
@override @useResult
$Res call({
 int decodeMicroseconds, int transformMicroseconds, int encodeMicroseconds, int totalMicroseconds
});




}
/// @nodoc
class __$NativeImageProcessingTimingsDtoCopyWithImpl<$Res>
    implements _$NativeImageProcessingTimingsDtoCopyWith<$Res> {
  __$NativeImageProcessingTimingsDtoCopyWithImpl(this._self, this._then);

  final _NativeImageProcessingTimingsDto _self;
  final $Res Function(_NativeImageProcessingTimingsDto) _then;

/// Create a copy of NativeImageProcessingTimingsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? decodeMicroseconds = null,Object? transformMicroseconds = null,Object? encodeMicroseconds = null,Object? totalMicroseconds = null,}) {
  return _then(_NativeImageProcessingTimingsDto(
decodeMicroseconds: null == decodeMicroseconds ? _self.decodeMicroseconds : decodeMicroseconds // ignore: cast_nullable_to_non_nullable
as int,transformMicroseconds: null == transformMicroseconds ? _self.transformMicroseconds : transformMicroseconds // ignore: cast_nullable_to_non_nullable
as int,encodeMicroseconds: null == encodeMicroseconds ? _self.encodeMicroseconds : encodeMicroseconds // ignore: cast_nullable_to_non_nullable
as int,totalMicroseconds: null == totalMicroseconds ? _self.totalMicroseconds : totalMicroseconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NativeImageProcessingResultDto {

 String get destinationPath; int get sourceWidth; int get sourceHeight; int get outputWidth; int get outputHeight; ImageProcessingBackendKind get backend; NativeImageProcessingTimingsDto get timings;
/// Create a copy of NativeImageProcessingResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeImageProcessingResultDtoCopyWith<NativeImageProcessingResultDto> get copyWith => _$NativeImageProcessingResultDtoCopyWithImpl<NativeImageProcessingResultDto>(this as NativeImageProcessingResultDto, _$identity);

  /// Serializes this NativeImageProcessingResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeImageProcessingResultDto&&(identical(other.destinationPath, destinationPath) || other.destinationPath == destinationPath)&&(identical(other.sourceWidth, sourceWidth) || other.sourceWidth == sourceWidth)&&(identical(other.sourceHeight, sourceHeight) || other.sourceHeight == sourceHeight)&&(identical(other.outputWidth, outputWidth) || other.outputWidth == outputWidth)&&(identical(other.outputHeight, outputHeight) || other.outputHeight == outputHeight)&&(identical(other.backend, backend) || other.backend == backend)&&(identical(other.timings, timings) || other.timings == timings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,destinationPath,sourceWidth,sourceHeight,outputWidth,outputHeight,backend,timings);

@override
String toString() {
  return 'NativeImageProcessingResultDto(destinationPath: $destinationPath, sourceWidth: $sourceWidth, sourceHeight: $sourceHeight, outputWidth: $outputWidth, outputHeight: $outputHeight, backend: $backend, timings: $timings)';
}


}

/// @nodoc
abstract mixin class $NativeImageProcessingResultDtoCopyWith<$Res>  {
  factory $NativeImageProcessingResultDtoCopyWith(NativeImageProcessingResultDto value, $Res Function(NativeImageProcessingResultDto) _then) = _$NativeImageProcessingResultDtoCopyWithImpl;
@useResult
$Res call({
 String destinationPath, int sourceWidth, int sourceHeight, int outputWidth, int outputHeight, ImageProcessingBackendKind backend, NativeImageProcessingTimingsDto timings
});


$NativeImageProcessingTimingsDtoCopyWith<$Res> get timings;

}
/// @nodoc
class _$NativeImageProcessingResultDtoCopyWithImpl<$Res>
    implements $NativeImageProcessingResultDtoCopyWith<$Res> {
  _$NativeImageProcessingResultDtoCopyWithImpl(this._self, this._then);

  final NativeImageProcessingResultDto _self;
  final $Res Function(NativeImageProcessingResultDto) _then;

/// Create a copy of NativeImageProcessingResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? destinationPath = null,Object? sourceWidth = null,Object? sourceHeight = null,Object? outputWidth = null,Object? outputHeight = null,Object? backend = null,Object? timings = null,}) {
  return _then(_self.copyWith(
destinationPath: null == destinationPath ? _self.destinationPath : destinationPath // ignore: cast_nullable_to_non_nullable
as String,sourceWidth: null == sourceWidth ? _self.sourceWidth : sourceWidth // ignore: cast_nullable_to_non_nullable
as int,sourceHeight: null == sourceHeight ? _self.sourceHeight : sourceHeight // ignore: cast_nullable_to_non_nullable
as int,outputWidth: null == outputWidth ? _self.outputWidth : outputWidth // ignore: cast_nullable_to_non_nullable
as int,outputHeight: null == outputHeight ? _self.outputHeight : outputHeight // ignore: cast_nullable_to_non_nullable
as int,backend: null == backend ? _self.backend : backend // ignore: cast_nullable_to_non_nullable
as ImageProcessingBackendKind,timings: null == timings ? _self.timings : timings // ignore: cast_nullable_to_non_nullable
as NativeImageProcessingTimingsDto,
  ));
}
/// Create a copy of NativeImageProcessingResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeImageProcessingTimingsDtoCopyWith<$Res> get timings {
  
  return $NativeImageProcessingTimingsDtoCopyWith<$Res>(_self.timings, (value) {
    return _then(_self.copyWith(timings: value));
  });
}
}


/// Adds pattern-matching-related methods to [NativeImageProcessingResultDto].
extension NativeImageProcessingResultDtoPatterns on NativeImageProcessingResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeImageProcessingResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeImageProcessingResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeImageProcessingResultDto value)  $default,){
final _that = this;
switch (_that) {
case _NativeImageProcessingResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeImageProcessingResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _NativeImageProcessingResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String destinationPath,  int sourceWidth,  int sourceHeight,  int outputWidth,  int outputHeight,  ImageProcessingBackendKind backend,  NativeImageProcessingTimingsDto timings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeImageProcessingResultDto() when $default != null:
return $default(_that.destinationPath,_that.sourceWidth,_that.sourceHeight,_that.outputWidth,_that.outputHeight,_that.backend,_that.timings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String destinationPath,  int sourceWidth,  int sourceHeight,  int outputWidth,  int outputHeight,  ImageProcessingBackendKind backend,  NativeImageProcessingTimingsDto timings)  $default,) {final _that = this;
switch (_that) {
case _NativeImageProcessingResultDto():
return $default(_that.destinationPath,_that.sourceWidth,_that.sourceHeight,_that.outputWidth,_that.outputHeight,_that.backend,_that.timings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String destinationPath,  int sourceWidth,  int sourceHeight,  int outputWidth,  int outputHeight,  ImageProcessingBackendKind backend,  NativeImageProcessingTimingsDto timings)?  $default,) {final _that = this;
switch (_that) {
case _NativeImageProcessingResultDto() when $default != null:
return $default(_that.destinationPath,_that.sourceWidth,_that.sourceHeight,_that.outputWidth,_that.outputHeight,_that.backend,_that.timings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NativeImageProcessingResultDto extends NativeImageProcessingResultDto {
  const _NativeImageProcessingResultDto({required this.destinationPath, required this.sourceWidth, required this.sourceHeight, required this.outputWidth, required this.outputHeight, required this.backend, required this.timings}): super._();
  factory _NativeImageProcessingResultDto.fromJson(Map<String, dynamic> json) => _$NativeImageProcessingResultDtoFromJson(json);

@override final  String destinationPath;
@override final  int sourceWidth;
@override final  int sourceHeight;
@override final  int outputWidth;
@override final  int outputHeight;
@override final  ImageProcessingBackendKind backend;
@override final  NativeImageProcessingTimingsDto timings;

/// Create a copy of NativeImageProcessingResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeImageProcessingResultDtoCopyWith<_NativeImageProcessingResultDto> get copyWith => __$NativeImageProcessingResultDtoCopyWithImpl<_NativeImageProcessingResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NativeImageProcessingResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeImageProcessingResultDto&&(identical(other.destinationPath, destinationPath) || other.destinationPath == destinationPath)&&(identical(other.sourceWidth, sourceWidth) || other.sourceWidth == sourceWidth)&&(identical(other.sourceHeight, sourceHeight) || other.sourceHeight == sourceHeight)&&(identical(other.outputWidth, outputWidth) || other.outputWidth == outputWidth)&&(identical(other.outputHeight, outputHeight) || other.outputHeight == outputHeight)&&(identical(other.backend, backend) || other.backend == backend)&&(identical(other.timings, timings) || other.timings == timings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,destinationPath,sourceWidth,sourceHeight,outputWidth,outputHeight,backend,timings);

@override
String toString() {
  return 'NativeImageProcessingResultDto(destinationPath: $destinationPath, sourceWidth: $sourceWidth, sourceHeight: $sourceHeight, outputWidth: $outputWidth, outputHeight: $outputHeight, backend: $backend, timings: $timings)';
}


}

/// @nodoc
abstract mixin class _$NativeImageProcessingResultDtoCopyWith<$Res> implements $NativeImageProcessingResultDtoCopyWith<$Res> {
  factory _$NativeImageProcessingResultDtoCopyWith(_NativeImageProcessingResultDto value, $Res Function(_NativeImageProcessingResultDto) _then) = __$NativeImageProcessingResultDtoCopyWithImpl;
@override @useResult
$Res call({
 String destinationPath, int sourceWidth, int sourceHeight, int outputWidth, int outputHeight, ImageProcessingBackendKind backend, NativeImageProcessingTimingsDto timings
});


@override $NativeImageProcessingTimingsDtoCopyWith<$Res> get timings;

}
/// @nodoc
class __$NativeImageProcessingResultDtoCopyWithImpl<$Res>
    implements _$NativeImageProcessingResultDtoCopyWith<$Res> {
  __$NativeImageProcessingResultDtoCopyWithImpl(this._self, this._then);

  final _NativeImageProcessingResultDto _self;
  final $Res Function(_NativeImageProcessingResultDto) _then;

/// Create a copy of NativeImageProcessingResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? destinationPath = null,Object? sourceWidth = null,Object? sourceHeight = null,Object? outputWidth = null,Object? outputHeight = null,Object? backend = null,Object? timings = null,}) {
  return _then(_NativeImageProcessingResultDto(
destinationPath: null == destinationPath ? _self.destinationPath : destinationPath // ignore: cast_nullable_to_non_nullable
as String,sourceWidth: null == sourceWidth ? _self.sourceWidth : sourceWidth // ignore: cast_nullable_to_non_nullable
as int,sourceHeight: null == sourceHeight ? _self.sourceHeight : sourceHeight // ignore: cast_nullable_to_non_nullable
as int,outputWidth: null == outputWidth ? _self.outputWidth : outputWidth // ignore: cast_nullable_to_non_nullable
as int,outputHeight: null == outputHeight ? _self.outputHeight : outputHeight // ignore: cast_nullable_to_non_nullable
as int,backend: null == backend ? _self.backend : backend // ignore: cast_nullable_to_non_nullable
as ImageProcessingBackendKind,timings: null == timings ? _self.timings : timings // ignore: cast_nullable_to_non_nullable
as NativeImageProcessingTimingsDto,
  ));
}

/// Create a copy of NativeImageProcessingResultDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeImageProcessingTimingsDtoCopyWith<$Res> get timings {
  
  return $NativeImageProcessingTimingsDtoCopyWith<$Res>(_self.timings, (value) {
    return _then(_self.copyWith(timings: value));
  });
}
}


/// @nodoc
mixin _$NativeImageProcessingResponseDto {

 int get schemaVersion; NativeImageProcessingResultDto? get result; ImageProcessingFailureKind? get failureKind; String? get debugDetail;
/// Create a copy of NativeImageProcessingResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativeImageProcessingResponseDtoCopyWith<NativeImageProcessingResponseDto> get copyWith => _$NativeImageProcessingResponseDtoCopyWithImpl<NativeImageProcessingResponseDto>(this as NativeImageProcessingResponseDto, _$identity);

  /// Serializes this NativeImageProcessingResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativeImageProcessingResponseDto&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.result, result) || other.result == result)&&(identical(other.failureKind, failureKind) || other.failureKind == failureKind)&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,result,failureKind,debugDetail);

@override
String toString() {
  return 'NativeImageProcessingResponseDto(schemaVersion: $schemaVersion, result: $result, failureKind: $failureKind, debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $NativeImageProcessingResponseDtoCopyWith<$Res>  {
  factory $NativeImageProcessingResponseDtoCopyWith(NativeImageProcessingResponseDto value, $Res Function(NativeImageProcessingResponseDto) _then) = _$NativeImageProcessingResponseDtoCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, NativeImageProcessingResultDto? result, ImageProcessingFailureKind? failureKind, String? debugDetail
});


$NativeImageProcessingResultDtoCopyWith<$Res>? get result;

}
/// @nodoc
class _$NativeImageProcessingResponseDtoCopyWithImpl<$Res>
    implements $NativeImageProcessingResponseDtoCopyWith<$Res> {
  _$NativeImageProcessingResponseDtoCopyWithImpl(this._self, this._then);

  final NativeImageProcessingResponseDto _self;
  final $Res Function(NativeImageProcessingResponseDto) _then;

/// Create a copy of NativeImageProcessingResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? result = freezed,Object? failureKind = freezed,Object? debugDetail = freezed,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as NativeImageProcessingResultDto?,failureKind: freezed == failureKind ? _self.failureKind : failureKind // ignore: cast_nullable_to_non_nullable
as ImageProcessingFailureKind?,debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of NativeImageProcessingResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeImageProcessingResultDtoCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $NativeImageProcessingResultDtoCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [NativeImageProcessingResponseDto].
extension NativeImageProcessingResponseDtoPatterns on NativeImageProcessingResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativeImageProcessingResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativeImageProcessingResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativeImageProcessingResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _NativeImageProcessingResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativeImageProcessingResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _NativeImageProcessingResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  NativeImageProcessingResultDto? result,  ImageProcessingFailureKind? failureKind,  String? debugDetail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativeImageProcessingResponseDto() when $default != null:
return $default(_that.schemaVersion,_that.result,_that.failureKind,_that.debugDetail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  NativeImageProcessingResultDto? result,  ImageProcessingFailureKind? failureKind,  String? debugDetail)  $default,) {final _that = this;
switch (_that) {
case _NativeImageProcessingResponseDto():
return $default(_that.schemaVersion,_that.result,_that.failureKind,_that.debugDetail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  NativeImageProcessingResultDto? result,  ImageProcessingFailureKind? failureKind,  String? debugDetail)?  $default,) {final _that = this;
switch (_that) {
case _NativeImageProcessingResponseDto() when $default != null:
return $default(_that.schemaVersion,_that.result,_that.failureKind,_that.debugDetail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NativeImageProcessingResponseDto extends NativeImageProcessingResponseDto {
  const _NativeImageProcessingResponseDto({required this.schemaVersion, this.result, this.failureKind, this.debugDetail}): super._();
  factory _NativeImageProcessingResponseDto.fromJson(Map<String, dynamic> json) => _$NativeImageProcessingResponseDtoFromJson(json);

@override final  int schemaVersion;
@override final  NativeImageProcessingResultDto? result;
@override final  ImageProcessingFailureKind? failureKind;
@override final  String? debugDetail;

/// Create a copy of NativeImageProcessingResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativeImageProcessingResponseDtoCopyWith<_NativeImageProcessingResponseDto> get copyWith => __$NativeImageProcessingResponseDtoCopyWithImpl<_NativeImageProcessingResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NativeImageProcessingResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativeImageProcessingResponseDto&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.result, result) || other.result == result)&&(identical(other.failureKind, failureKind) || other.failureKind == failureKind)&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,result,failureKind,debugDetail);

@override
String toString() {
  return 'NativeImageProcessingResponseDto(schemaVersion: $schemaVersion, result: $result, failureKind: $failureKind, debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class _$NativeImageProcessingResponseDtoCopyWith<$Res> implements $NativeImageProcessingResponseDtoCopyWith<$Res> {
  factory _$NativeImageProcessingResponseDtoCopyWith(_NativeImageProcessingResponseDto value, $Res Function(_NativeImageProcessingResponseDto) _then) = __$NativeImageProcessingResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, NativeImageProcessingResultDto? result, ImageProcessingFailureKind? failureKind, String? debugDetail
});


@override $NativeImageProcessingResultDtoCopyWith<$Res>? get result;

}
/// @nodoc
class __$NativeImageProcessingResponseDtoCopyWithImpl<$Res>
    implements _$NativeImageProcessingResponseDtoCopyWith<$Res> {
  __$NativeImageProcessingResponseDtoCopyWithImpl(this._self, this._then);

  final _NativeImageProcessingResponseDto _self;
  final $Res Function(_NativeImageProcessingResponseDto) _then;

/// Create a copy of NativeImageProcessingResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? result = freezed,Object? failureKind = freezed,Object? debugDetail = freezed,}) {
  return _then(_NativeImageProcessingResponseDto(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as NativeImageProcessingResultDto?,failureKind: freezed == failureKind ? _self.failureKind : failureKind // ignore: cast_nullable_to_non_nullable
as ImageProcessingFailureKind?,debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of NativeImageProcessingResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NativeImageProcessingResultDtoCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $NativeImageProcessingResultDtoCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

// dart format on
