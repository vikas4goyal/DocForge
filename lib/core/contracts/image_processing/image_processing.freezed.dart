// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_processing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImageProcessingCapability {

 ImageProcessingBackendKind get backend; bool get isSupported; int get maximumTextureSize; bool get supportsTiling;
/// Create a copy of ImageProcessingCapability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageProcessingCapabilityCopyWith<ImageProcessingCapability> get copyWith => _$ImageProcessingCapabilityCopyWithImpl<ImageProcessingCapability>(this as ImageProcessingCapability, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageProcessingCapability&&(identical(other.backend, backend) || other.backend == backend)&&(identical(other.isSupported, isSupported) || other.isSupported == isSupported)&&(identical(other.maximumTextureSize, maximumTextureSize) || other.maximumTextureSize == maximumTextureSize)&&(identical(other.supportsTiling, supportsTiling) || other.supportsTiling == supportsTiling));
}


@override
int get hashCode => Object.hash(runtimeType,backend,isSupported,maximumTextureSize,supportsTiling);

@override
String toString() {
  return 'ImageProcessingCapability(backend: $backend, isSupported: $isSupported, maximumTextureSize: $maximumTextureSize, supportsTiling: $supportsTiling)';
}


}

/// @nodoc
abstract mixin class $ImageProcessingCapabilityCopyWith<$Res>  {
  factory $ImageProcessingCapabilityCopyWith(ImageProcessingCapability value, $Res Function(ImageProcessingCapability) _then) = _$ImageProcessingCapabilityCopyWithImpl;
@useResult
$Res call({
 ImageProcessingBackendKind backend, bool isSupported, int maximumTextureSize, bool supportsTiling
});




}
/// @nodoc
class _$ImageProcessingCapabilityCopyWithImpl<$Res>
    implements $ImageProcessingCapabilityCopyWith<$Res> {
  _$ImageProcessingCapabilityCopyWithImpl(this._self, this._then);

  final ImageProcessingCapability _self;
  final $Res Function(ImageProcessingCapability) _then;

/// Create a copy of ImageProcessingCapability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backend = null,Object? isSupported = null,Object? maximumTextureSize = null,Object? supportsTiling = null,}) {
  return _then(_self.copyWith(
backend: null == backend ? _self.backend : backend // ignore: cast_nullable_to_non_nullable
as ImageProcessingBackendKind,isSupported: null == isSupported ? _self.isSupported : isSupported // ignore: cast_nullable_to_non_nullable
as bool,maximumTextureSize: null == maximumTextureSize ? _self.maximumTextureSize : maximumTextureSize // ignore: cast_nullable_to_non_nullable
as int,supportsTiling: null == supportsTiling ? _self.supportsTiling : supportsTiling // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageProcessingCapability].
extension ImageProcessingCapabilityPatterns on ImageProcessingCapability {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageProcessingCapability value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageProcessingCapability() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageProcessingCapability value)  $default,){
final _that = this;
switch (_that) {
case _ImageProcessingCapability():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageProcessingCapability value)?  $default,){
final _that = this;
switch (_that) {
case _ImageProcessingCapability() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ImageProcessingBackendKind backend,  bool isSupported,  int maximumTextureSize,  bool supportsTiling)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageProcessingCapability() when $default != null:
return $default(_that.backend,_that.isSupported,_that.maximumTextureSize,_that.supportsTiling);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ImageProcessingBackendKind backend,  bool isSupported,  int maximumTextureSize,  bool supportsTiling)  $default,) {final _that = this;
switch (_that) {
case _ImageProcessingCapability():
return $default(_that.backend,_that.isSupported,_that.maximumTextureSize,_that.supportsTiling);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ImageProcessingBackendKind backend,  bool isSupported,  int maximumTextureSize,  bool supportsTiling)?  $default,) {final _that = this;
switch (_that) {
case _ImageProcessingCapability() when $default != null:
return $default(_that.backend,_that.isSupported,_that.maximumTextureSize,_that.supportsTiling);case _:
  return null;

}
}

}

/// @nodoc


class _ImageProcessingCapability extends ImageProcessingCapability {
  const _ImageProcessingCapability({required this.backend, required this.isSupported, required this.maximumTextureSize, required this.supportsTiling}): super._();
  

@override final  ImageProcessingBackendKind backend;
@override final  bool isSupported;
@override final  int maximumTextureSize;
@override final  bool supportsTiling;

/// Create a copy of ImageProcessingCapability
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageProcessingCapabilityCopyWith<_ImageProcessingCapability> get copyWith => __$ImageProcessingCapabilityCopyWithImpl<_ImageProcessingCapability>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageProcessingCapability&&(identical(other.backend, backend) || other.backend == backend)&&(identical(other.isSupported, isSupported) || other.isSupported == isSupported)&&(identical(other.maximumTextureSize, maximumTextureSize) || other.maximumTextureSize == maximumTextureSize)&&(identical(other.supportsTiling, supportsTiling) || other.supportsTiling == supportsTiling));
}


@override
int get hashCode => Object.hash(runtimeType,backend,isSupported,maximumTextureSize,supportsTiling);

@override
String toString() {
  return 'ImageProcessingCapability(backend: $backend, isSupported: $isSupported, maximumTextureSize: $maximumTextureSize, supportsTiling: $supportsTiling)';
}


}

/// @nodoc
abstract mixin class _$ImageProcessingCapabilityCopyWith<$Res> implements $ImageProcessingCapabilityCopyWith<$Res> {
  factory _$ImageProcessingCapabilityCopyWith(_ImageProcessingCapability value, $Res Function(_ImageProcessingCapability) _then) = __$ImageProcessingCapabilityCopyWithImpl;
@override @useResult
$Res call({
 ImageProcessingBackendKind backend, bool isSupported, int maximumTextureSize, bool supportsTiling
});




}
/// @nodoc
class __$ImageProcessingCapabilityCopyWithImpl<$Res>
    implements _$ImageProcessingCapabilityCopyWith<$Res> {
  __$ImageProcessingCapabilityCopyWithImpl(this._self, this._then);

  final _ImageProcessingCapability _self;
  final $Res Function(_ImageProcessingCapability) _then;

/// Create a copy of ImageProcessingCapability
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? backend = null,Object? isSupported = null,Object? maximumTextureSize = null,Object? supportsTiling = null,}) {
  return _then(_ImageProcessingCapability(
backend: null == backend ? _self.backend : backend // ignore: cast_nullable_to_non_nullable
as ImageProcessingBackendKind,isSupported: null == isSupported ? _self.isSupported : isSupported // ignore: cast_nullable_to_non_nullable
as bool,maximumTextureSize: null == maximumTextureSize ? _self.maximumTextureSize : maximumTextureSize // ignore: cast_nullable_to_non_nullable
as int,supportsTiling: null == supportsTiling ? _self.supportsTiling : supportsTiling // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$ImageProcessingTimings {

 int get decodeMicroseconds; int get transformMicroseconds; int get encodeMicroseconds; int get totalMicroseconds;
/// Create a copy of ImageProcessingTimings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageProcessingTimingsCopyWith<ImageProcessingTimings> get copyWith => _$ImageProcessingTimingsCopyWithImpl<ImageProcessingTimings>(this as ImageProcessingTimings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageProcessingTimings&&(identical(other.decodeMicroseconds, decodeMicroseconds) || other.decodeMicroseconds == decodeMicroseconds)&&(identical(other.transformMicroseconds, transformMicroseconds) || other.transformMicroseconds == transformMicroseconds)&&(identical(other.encodeMicroseconds, encodeMicroseconds) || other.encodeMicroseconds == encodeMicroseconds)&&(identical(other.totalMicroseconds, totalMicroseconds) || other.totalMicroseconds == totalMicroseconds));
}


@override
int get hashCode => Object.hash(runtimeType,decodeMicroseconds,transformMicroseconds,encodeMicroseconds,totalMicroseconds);

@override
String toString() {
  return 'ImageProcessingTimings(decodeMicroseconds: $decodeMicroseconds, transformMicroseconds: $transformMicroseconds, encodeMicroseconds: $encodeMicroseconds, totalMicroseconds: $totalMicroseconds)';
}


}

/// @nodoc
abstract mixin class $ImageProcessingTimingsCopyWith<$Res>  {
  factory $ImageProcessingTimingsCopyWith(ImageProcessingTimings value, $Res Function(ImageProcessingTimings) _then) = _$ImageProcessingTimingsCopyWithImpl;
@useResult
$Res call({
 int decodeMicroseconds, int transformMicroseconds, int encodeMicroseconds, int totalMicroseconds
});




}
/// @nodoc
class _$ImageProcessingTimingsCopyWithImpl<$Res>
    implements $ImageProcessingTimingsCopyWith<$Res> {
  _$ImageProcessingTimingsCopyWithImpl(this._self, this._then);

  final ImageProcessingTimings _self;
  final $Res Function(ImageProcessingTimings) _then;

/// Create a copy of ImageProcessingTimings
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


/// Adds pattern-matching-related methods to [ImageProcessingTimings].
extension ImageProcessingTimingsPatterns on ImageProcessingTimings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageProcessingTimings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageProcessingTimings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageProcessingTimings value)  $default,){
final _that = this;
switch (_that) {
case _ImageProcessingTimings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageProcessingTimings value)?  $default,){
final _that = this;
switch (_that) {
case _ImageProcessingTimings() when $default != null:
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
case _ImageProcessingTimings() when $default != null:
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
case _ImageProcessingTimings():
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
case _ImageProcessingTimings() when $default != null:
return $default(_that.decodeMicroseconds,_that.transformMicroseconds,_that.encodeMicroseconds,_that.totalMicroseconds);case _:
  return null;

}
}

}

/// @nodoc


class _ImageProcessingTimings extends ImageProcessingTimings {
  const _ImageProcessingTimings({this.decodeMicroseconds = 0, this.transformMicroseconds = 0, this.encodeMicroseconds = 0, required this.totalMicroseconds}): super._();
  

@override@JsonKey() final  int decodeMicroseconds;
@override@JsonKey() final  int transformMicroseconds;
@override@JsonKey() final  int encodeMicroseconds;
@override final  int totalMicroseconds;

/// Create a copy of ImageProcessingTimings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageProcessingTimingsCopyWith<_ImageProcessingTimings> get copyWith => __$ImageProcessingTimingsCopyWithImpl<_ImageProcessingTimings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageProcessingTimings&&(identical(other.decodeMicroseconds, decodeMicroseconds) || other.decodeMicroseconds == decodeMicroseconds)&&(identical(other.transformMicroseconds, transformMicroseconds) || other.transformMicroseconds == transformMicroseconds)&&(identical(other.encodeMicroseconds, encodeMicroseconds) || other.encodeMicroseconds == encodeMicroseconds)&&(identical(other.totalMicroseconds, totalMicroseconds) || other.totalMicroseconds == totalMicroseconds));
}


@override
int get hashCode => Object.hash(runtimeType,decodeMicroseconds,transformMicroseconds,encodeMicroseconds,totalMicroseconds);

@override
String toString() {
  return 'ImageProcessingTimings(decodeMicroseconds: $decodeMicroseconds, transformMicroseconds: $transformMicroseconds, encodeMicroseconds: $encodeMicroseconds, totalMicroseconds: $totalMicroseconds)';
}


}

/// @nodoc
abstract mixin class _$ImageProcessingTimingsCopyWith<$Res> implements $ImageProcessingTimingsCopyWith<$Res> {
  factory _$ImageProcessingTimingsCopyWith(_ImageProcessingTimings value, $Res Function(_ImageProcessingTimings) _then) = __$ImageProcessingTimingsCopyWithImpl;
@override @useResult
$Res call({
 int decodeMicroseconds, int transformMicroseconds, int encodeMicroseconds, int totalMicroseconds
});




}
/// @nodoc
class __$ImageProcessingTimingsCopyWithImpl<$Res>
    implements _$ImageProcessingTimingsCopyWith<$Res> {
  __$ImageProcessingTimingsCopyWithImpl(this._self, this._then);

  final _ImageProcessingTimings _self;
  final $Res Function(_ImageProcessingTimings) _then;

/// Create a copy of ImageProcessingTimings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? decodeMicroseconds = null,Object? transformMicroseconds = null,Object? encodeMicroseconds = null,Object? totalMicroseconds = null,}) {
  return _then(_ImageProcessingTimings(
decodeMicroseconds: null == decodeMicroseconds ? _self.decodeMicroseconds : decodeMicroseconds // ignore: cast_nullable_to_non_nullable
as int,transformMicroseconds: null == transformMicroseconds ? _self.transformMicroseconds : transformMicroseconds // ignore: cast_nullable_to_non_nullable
as int,encodeMicroseconds: null == encodeMicroseconds ? _self.encodeMicroseconds : encodeMicroseconds // ignore: cast_nullable_to_non_nullable
as int,totalMicroseconds: null == totalMicroseconds ? _self.totalMicroseconds : totalMicroseconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ImageRenderRequest {

 String get requestId; String get sourcePath; String get destinationPath; ImageRenderScale get scale; EnhancementSettings get enhancement; int get jpegQuality; int get colourPipelineVersion; Homography? get transform; int? get outputWidth; int? get outputHeight; int? get maximumPreviewDimension;
/// Create a copy of ImageRenderRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageRenderRequestCopyWith<ImageRenderRequest> get copyWith => _$ImageRenderRequestCopyWithImpl<ImageRenderRequest>(this as ImageRenderRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageRenderRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.destinationPath, destinationPath) || other.destinationPath == destinationPath)&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.enhancement, enhancement) || other.enhancement == enhancement)&&(identical(other.jpegQuality, jpegQuality) || other.jpegQuality == jpegQuality)&&(identical(other.colourPipelineVersion, colourPipelineVersion) || other.colourPipelineVersion == colourPipelineVersion)&&(identical(other.transform, transform) || other.transform == transform)&&(identical(other.outputWidth, outputWidth) || other.outputWidth == outputWidth)&&(identical(other.outputHeight, outputHeight) || other.outputHeight == outputHeight)&&(identical(other.maximumPreviewDimension, maximumPreviewDimension) || other.maximumPreviewDimension == maximumPreviewDimension));
}


@override
int get hashCode => Object.hash(runtimeType,requestId,sourcePath,destinationPath,scale,enhancement,jpegQuality,colourPipelineVersion,transform,outputWidth,outputHeight,maximumPreviewDimension);

@override
String toString() {
  return 'ImageRenderRequest(requestId: $requestId, sourcePath: $sourcePath, destinationPath: $destinationPath, scale: $scale, enhancement: $enhancement, jpegQuality: $jpegQuality, colourPipelineVersion: $colourPipelineVersion, transform: $transform, outputWidth: $outputWidth, outputHeight: $outputHeight, maximumPreviewDimension: $maximumPreviewDimension)';
}


}

/// @nodoc
abstract mixin class $ImageRenderRequestCopyWith<$Res>  {
  factory $ImageRenderRequestCopyWith(ImageRenderRequest value, $Res Function(ImageRenderRequest) _then) = _$ImageRenderRequestCopyWithImpl;
@useResult
$Res call({
 String requestId, String sourcePath, String destinationPath, ImageRenderScale scale, EnhancementSettings enhancement, int jpegQuality, int colourPipelineVersion, Homography? transform, int? outputWidth, int? outputHeight, int? maximumPreviewDimension
});


$EnhancementSettingsCopyWith<$Res> get enhancement;

}
/// @nodoc
class _$ImageRenderRequestCopyWithImpl<$Res>
    implements $ImageRenderRequestCopyWith<$Res> {
  _$ImageRenderRequestCopyWithImpl(this._self, this._then);

  final ImageRenderRequest _self;
  final $Res Function(ImageRenderRequest) _then;

/// Create a copy of ImageRenderRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? sourcePath = null,Object? destinationPath = null,Object? scale = null,Object? enhancement = null,Object? jpegQuality = null,Object? colourPipelineVersion = null,Object? transform = freezed,Object? outputWidth = freezed,Object? outputHeight = freezed,Object? maximumPreviewDimension = freezed,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,destinationPath: null == destinationPath ? _self.destinationPath : destinationPath // ignore: cast_nullable_to_non_nullable
as String,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as ImageRenderScale,enhancement: null == enhancement ? _self.enhancement : enhancement // ignore: cast_nullable_to_non_nullable
as EnhancementSettings,jpegQuality: null == jpegQuality ? _self.jpegQuality : jpegQuality // ignore: cast_nullable_to_non_nullable
as int,colourPipelineVersion: null == colourPipelineVersion ? _self.colourPipelineVersion : colourPipelineVersion // ignore: cast_nullable_to_non_nullable
as int,transform: freezed == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as Homography?,outputWidth: freezed == outputWidth ? _self.outputWidth : outputWidth // ignore: cast_nullable_to_non_nullable
as int?,outputHeight: freezed == outputHeight ? _self.outputHeight : outputHeight // ignore: cast_nullable_to_non_nullable
as int?,maximumPreviewDimension: freezed == maximumPreviewDimension ? _self.maximumPreviewDimension : maximumPreviewDimension // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of ImageRenderRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnhancementSettingsCopyWith<$Res> get enhancement {
  
  return $EnhancementSettingsCopyWith<$Res>(_self.enhancement, (value) {
    return _then(_self.copyWith(enhancement: value));
  });
}
}


/// Adds pattern-matching-related methods to [ImageRenderRequest].
extension ImageRenderRequestPatterns on ImageRenderRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageRenderRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageRenderRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageRenderRequest value)  $default,){
final _that = this;
switch (_that) {
case _ImageRenderRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageRenderRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ImageRenderRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String requestId,  String sourcePath,  String destinationPath,  ImageRenderScale scale,  EnhancementSettings enhancement,  int jpegQuality,  int colourPipelineVersion,  Homography? transform,  int? outputWidth,  int? outputHeight,  int? maximumPreviewDimension)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageRenderRequest() when $default != null:
return $default(_that.requestId,_that.sourcePath,_that.destinationPath,_that.scale,_that.enhancement,_that.jpegQuality,_that.colourPipelineVersion,_that.transform,_that.outputWidth,_that.outputHeight,_that.maximumPreviewDimension);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String requestId,  String sourcePath,  String destinationPath,  ImageRenderScale scale,  EnhancementSettings enhancement,  int jpegQuality,  int colourPipelineVersion,  Homography? transform,  int? outputWidth,  int? outputHeight,  int? maximumPreviewDimension)  $default,) {final _that = this;
switch (_that) {
case _ImageRenderRequest():
return $default(_that.requestId,_that.sourcePath,_that.destinationPath,_that.scale,_that.enhancement,_that.jpegQuality,_that.colourPipelineVersion,_that.transform,_that.outputWidth,_that.outputHeight,_that.maximumPreviewDimension);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String requestId,  String sourcePath,  String destinationPath,  ImageRenderScale scale,  EnhancementSettings enhancement,  int jpegQuality,  int colourPipelineVersion,  Homography? transform,  int? outputWidth,  int? outputHeight,  int? maximumPreviewDimension)?  $default,) {final _that = this;
switch (_that) {
case _ImageRenderRequest() when $default != null:
return $default(_that.requestId,_that.sourcePath,_that.destinationPath,_that.scale,_that.enhancement,_that.jpegQuality,_that.colourPipelineVersion,_that.transform,_that.outputWidth,_that.outputHeight,_that.maximumPreviewDimension);case _:
  return null;

}
}

}

/// @nodoc


class _ImageRenderRequest extends ImageRenderRequest {
  const _ImageRenderRequest({required this.requestId, required this.sourcePath, required this.destinationPath, required this.scale, required this.enhancement, required this.jpegQuality, this.colourPipelineVersion = 1, this.transform, this.outputWidth, this.outputHeight, this.maximumPreviewDimension}): super._();
  

@override final  String requestId;
@override final  String sourcePath;
@override final  String destinationPath;
@override final  ImageRenderScale scale;
@override final  EnhancementSettings enhancement;
@override final  int jpegQuality;
@override@JsonKey() final  int colourPipelineVersion;
@override final  Homography? transform;
@override final  int? outputWidth;
@override final  int? outputHeight;
@override final  int? maximumPreviewDimension;

/// Create a copy of ImageRenderRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageRenderRequestCopyWith<_ImageRenderRequest> get copyWith => __$ImageRenderRequestCopyWithImpl<_ImageRenderRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageRenderRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.sourcePath, sourcePath) || other.sourcePath == sourcePath)&&(identical(other.destinationPath, destinationPath) || other.destinationPath == destinationPath)&&(identical(other.scale, scale) || other.scale == scale)&&(identical(other.enhancement, enhancement) || other.enhancement == enhancement)&&(identical(other.jpegQuality, jpegQuality) || other.jpegQuality == jpegQuality)&&(identical(other.colourPipelineVersion, colourPipelineVersion) || other.colourPipelineVersion == colourPipelineVersion)&&(identical(other.transform, transform) || other.transform == transform)&&(identical(other.outputWidth, outputWidth) || other.outputWidth == outputWidth)&&(identical(other.outputHeight, outputHeight) || other.outputHeight == outputHeight)&&(identical(other.maximumPreviewDimension, maximumPreviewDimension) || other.maximumPreviewDimension == maximumPreviewDimension));
}


@override
int get hashCode => Object.hash(runtimeType,requestId,sourcePath,destinationPath,scale,enhancement,jpegQuality,colourPipelineVersion,transform,outputWidth,outputHeight,maximumPreviewDimension);

@override
String toString() {
  return 'ImageRenderRequest(requestId: $requestId, sourcePath: $sourcePath, destinationPath: $destinationPath, scale: $scale, enhancement: $enhancement, jpegQuality: $jpegQuality, colourPipelineVersion: $colourPipelineVersion, transform: $transform, outputWidth: $outputWidth, outputHeight: $outputHeight, maximumPreviewDimension: $maximumPreviewDimension)';
}


}

/// @nodoc
abstract mixin class _$ImageRenderRequestCopyWith<$Res> implements $ImageRenderRequestCopyWith<$Res> {
  factory _$ImageRenderRequestCopyWith(_ImageRenderRequest value, $Res Function(_ImageRenderRequest) _then) = __$ImageRenderRequestCopyWithImpl;
@override @useResult
$Res call({
 String requestId, String sourcePath, String destinationPath, ImageRenderScale scale, EnhancementSettings enhancement, int jpegQuality, int colourPipelineVersion, Homography? transform, int? outputWidth, int? outputHeight, int? maximumPreviewDimension
});


@override $EnhancementSettingsCopyWith<$Res> get enhancement;

}
/// @nodoc
class __$ImageRenderRequestCopyWithImpl<$Res>
    implements _$ImageRenderRequestCopyWith<$Res> {
  __$ImageRenderRequestCopyWithImpl(this._self, this._then);

  final _ImageRenderRequest _self;
  final $Res Function(_ImageRenderRequest) _then;

/// Create a copy of ImageRenderRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? sourcePath = null,Object? destinationPath = null,Object? scale = null,Object? enhancement = null,Object? jpegQuality = null,Object? colourPipelineVersion = null,Object? transform = freezed,Object? outputWidth = freezed,Object? outputHeight = freezed,Object? maximumPreviewDimension = freezed,}) {
  return _then(_ImageRenderRequest(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,sourcePath: null == sourcePath ? _self.sourcePath : sourcePath // ignore: cast_nullable_to_non_nullable
as String,destinationPath: null == destinationPath ? _self.destinationPath : destinationPath // ignore: cast_nullable_to_non_nullable
as String,scale: null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as ImageRenderScale,enhancement: null == enhancement ? _self.enhancement : enhancement // ignore: cast_nullable_to_non_nullable
as EnhancementSettings,jpegQuality: null == jpegQuality ? _self.jpegQuality : jpegQuality // ignore: cast_nullable_to_non_nullable
as int,colourPipelineVersion: null == colourPipelineVersion ? _self.colourPipelineVersion : colourPipelineVersion // ignore: cast_nullable_to_non_nullable
as int,transform: freezed == transform ? _self.transform : transform // ignore: cast_nullable_to_non_nullable
as Homography?,outputWidth: freezed == outputWidth ? _self.outputWidth : outputWidth // ignore: cast_nullable_to_non_nullable
as int?,outputHeight: freezed == outputHeight ? _self.outputHeight : outputHeight // ignore: cast_nullable_to_non_nullable
as int?,maximumPreviewDimension: freezed == maximumPreviewDimension ? _self.maximumPreviewDimension : maximumPreviewDimension // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of ImageRenderRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnhancementSettingsCopyWith<$Res> get enhancement {
  
  return $EnhancementSettingsCopyWith<$Res>(_self.enhancement, (value) {
    return _then(_self.copyWith(enhancement: value));
  });
}
}

/// @nodoc
mixin _$ImageProcessingResult {

 String get destinationPath; int get sourceWidth; int get sourceHeight; int get outputWidth; int get outputHeight; ImageProcessingBackendKind get backend; ImageProcessingTimings get timings;
/// Create a copy of ImageProcessingResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageProcessingResultCopyWith<ImageProcessingResult> get copyWith => _$ImageProcessingResultCopyWithImpl<ImageProcessingResult>(this as ImageProcessingResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageProcessingResult&&(identical(other.destinationPath, destinationPath) || other.destinationPath == destinationPath)&&(identical(other.sourceWidth, sourceWidth) || other.sourceWidth == sourceWidth)&&(identical(other.sourceHeight, sourceHeight) || other.sourceHeight == sourceHeight)&&(identical(other.outputWidth, outputWidth) || other.outputWidth == outputWidth)&&(identical(other.outputHeight, outputHeight) || other.outputHeight == outputHeight)&&(identical(other.backend, backend) || other.backend == backend)&&(identical(other.timings, timings) || other.timings == timings));
}


@override
int get hashCode => Object.hash(runtimeType,destinationPath,sourceWidth,sourceHeight,outputWidth,outputHeight,backend,timings);

@override
String toString() {
  return 'ImageProcessingResult(destinationPath: $destinationPath, sourceWidth: $sourceWidth, sourceHeight: $sourceHeight, outputWidth: $outputWidth, outputHeight: $outputHeight, backend: $backend, timings: $timings)';
}


}

/// @nodoc
abstract mixin class $ImageProcessingResultCopyWith<$Res>  {
  factory $ImageProcessingResultCopyWith(ImageProcessingResult value, $Res Function(ImageProcessingResult) _then) = _$ImageProcessingResultCopyWithImpl;
@useResult
$Res call({
 String destinationPath, int sourceWidth, int sourceHeight, int outputWidth, int outputHeight, ImageProcessingBackendKind backend, ImageProcessingTimings timings
});


$ImageProcessingTimingsCopyWith<$Res> get timings;

}
/// @nodoc
class _$ImageProcessingResultCopyWithImpl<$Res>
    implements $ImageProcessingResultCopyWith<$Res> {
  _$ImageProcessingResultCopyWithImpl(this._self, this._then);

  final ImageProcessingResult _self;
  final $Res Function(ImageProcessingResult) _then;

/// Create a copy of ImageProcessingResult
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
as ImageProcessingTimings,
  ));
}
/// Create a copy of ImageProcessingResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageProcessingTimingsCopyWith<$Res> get timings {
  
  return $ImageProcessingTimingsCopyWith<$Res>(_self.timings, (value) {
    return _then(_self.copyWith(timings: value));
  });
}
}


/// Adds pattern-matching-related methods to [ImageProcessingResult].
extension ImageProcessingResultPatterns on ImageProcessingResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageProcessingResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageProcessingResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageProcessingResult value)  $default,){
final _that = this;
switch (_that) {
case _ImageProcessingResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageProcessingResult value)?  $default,){
final _that = this;
switch (_that) {
case _ImageProcessingResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String destinationPath,  int sourceWidth,  int sourceHeight,  int outputWidth,  int outputHeight,  ImageProcessingBackendKind backend,  ImageProcessingTimings timings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageProcessingResult() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String destinationPath,  int sourceWidth,  int sourceHeight,  int outputWidth,  int outputHeight,  ImageProcessingBackendKind backend,  ImageProcessingTimings timings)  $default,) {final _that = this;
switch (_that) {
case _ImageProcessingResult():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String destinationPath,  int sourceWidth,  int sourceHeight,  int outputWidth,  int outputHeight,  ImageProcessingBackendKind backend,  ImageProcessingTimings timings)?  $default,) {final _that = this;
switch (_that) {
case _ImageProcessingResult() when $default != null:
return $default(_that.destinationPath,_that.sourceWidth,_that.sourceHeight,_that.outputWidth,_that.outputHeight,_that.backend,_that.timings);case _:
  return null;

}
}

}

/// @nodoc


class _ImageProcessingResult extends ImageProcessingResult {
  const _ImageProcessingResult({required this.destinationPath, required this.sourceWidth, required this.sourceHeight, required this.outputWidth, required this.outputHeight, required this.backend, required this.timings}): super._();
  

@override final  String destinationPath;
@override final  int sourceWidth;
@override final  int sourceHeight;
@override final  int outputWidth;
@override final  int outputHeight;
@override final  ImageProcessingBackendKind backend;
@override final  ImageProcessingTimings timings;

/// Create a copy of ImageProcessingResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageProcessingResultCopyWith<_ImageProcessingResult> get copyWith => __$ImageProcessingResultCopyWithImpl<_ImageProcessingResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageProcessingResult&&(identical(other.destinationPath, destinationPath) || other.destinationPath == destinationPath)&&(identical(other.sourceWidth, sourceWidth) || other.sourceWidth == sourceWidth)&&(identical(other.sourceHeight, sourceHeight) || other.sourceHeight == sourceHeight)&&(identical(other.outputWidth, outputWidth) || other.outputWidth == outputWidth)&&(identical(other.outputHeight, outputHeight) || other.outputHeight == outputHeight)&&(identical(other.backend, backend) || other.backend == backend)&&(identical(other.timings, timings) || other.timings == timings));
}


@override
int get hashCode => Object.hash(runtimeType,destinationPath,sourceWidth,sourceHeight,outputWidth,outputHeight,backend,timings);

@override
String toString() {
  return 'ImageProcessingResult(destinationPath: $destinationPath, sourceWidth: $sourceWidth, sourceHeight: $sourceHeight, outputWidth: $outputWidth, outputHeight: $outputHeight, backend: $backend, timings: $timings)';
}


}

/// @nodoc
abstract mixin class _$ImageProcessingResultCopyWith<$Res> implements $ImageProcessingResultCopyWith<$Res> {
  factory _$ImageProcessingResultCopyWith(_ImageProcessingResult value, $Res Function(_ImageProcessingResult) _then) = __$ImageProcessingResultCopyWithImpl;
@override @useResult
$Res call({
 String destinationPath, int sourceWidth, int sourceHeight, int outputWidth, int outputHeight, ImageProcessingBackendKind backend, ImageProcessingTimings timings
});


@override $ImageProcessingTimingsCopyWith<$Res> get timings;

}
/// @nodoc
class __$ImageProcessingResultCopyWithImpl<$Res>
    implements _$ImageProcessingResultCopyWith<$Res> {
  __$ImageProcessingResultCopyWithImpl(this._self, this._then);

  final _ImageProcessingResult _self;
  final $Res Function(_ImageProcessingResult) _then;

/// Create a copy of ImageProcessingResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? destinationPath = null,Object? sourceWidth = null,Object? sourceHeight = null,Object? outputWidth = null,Object? outputHeight = null,Object? backend = null,Object? timings = null,}) {
  return _then(_ImageProcessingResult(
destinationPath: null == destinationPath ? _self.destinationPath : destinationPath // ignore: cast_nullable_to_non_nullable
as String,sourceWidth: null == sourceWidth ? _self.sourceWidth : sourceWidth // ignore: cast_nullable_to_non_nullable
as int,sourceHeight: null == sourceHeight ? _self.sourceHeight : sourceHeight // ignore: cast_nullable_to_non_nullable
as int,outputWidth: null == outputWidth ? _self.outputWidth : outputWidth // ignore: cast_nullable_to_non_nullable
as int,outputHeight: null == outputHeight ? _self.outputHeight : outputHeight // ignore: cast_nullable_to_non_nullable
as int,backend: null == backend ? _self.backend : backend // ignore: cast_nullable_to_non_nullable
as ImageProcessingBackendKind,timings: null == timings ? _self.timings : timings // ignore: cast_nullable_to_non_nullable
as ImageProcessingTimings,
  ));
}

/// Create a copy of ImageProcessingResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageProcessingTimingsCopyWith<$Res> get timings {
  
  return $ImageProcessingTimingsCopyWith<$Res>(_self.timings, (value) {
    return _then(_self.copyWith(timings: value));
  });
}
}

/// @nodoc
mixin _$ImageProcessingBackendResponse {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageProcessingBackendResponse);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ImageProcessingBackendResponse()';
}


}

/// @nodoc
class $ImageProcessingBackendResponseCopyWith<$Res>  {
$ImageProcessingBackendResponseCopyWith(ImageProcessingBackendResponse _, $Res Function(ImageProcessingBackendResponse) __);
}


/// Adds pattern-matching-related methods to [ImageProcessingBackendResponse].
extension ImageProcessingBackendResponsePatterns on ImageProcessingBackendResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ImageProcessingBackendSuccess value)?  success,TResult Function( ImageProcessingBackendFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ImageProcessingBackendSuccess() when success != null:
return success(_that);case ImageProcessingBackendFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ImageProcessingBackendSuccess value)  success,required TResult Function( ImageProcessingBackendFailure value)  failure,}){
final _that = this;
switch (_that) {
case ImageProcessingBackendSuccess():
return success(_that);case ImageProcessingBackendFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ImageProcessingBackendSuccess value)?  success,TResult? Function( ImageProcessingBackendFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ImageProcessingBackendSuccess() when success != null:
return success(_that);case ImageProcessingBackendFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ImageProcessingResult result)?  success,TResult Function( ImageProcessingFailureKind kind,  String? debugDetail)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ImageProcessingBackendSuccess() when success != null:
return success(_that.result);case ImageProcessingBackendFailure() when failure != null:
return failure(_that.kind,_that.debugDetail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ImageProcessingResult result)  success,required TResult Function( ImageProcessingFailureKind kind,  String? debugDetail)  failure,}) {final _that = this;
switch (_that) {
case ImageProcessingBackendSuccess():
return success(_that.result);case ImageProcessingBackendFailure():
return failure(_that.kind,_that.debugDetail);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ImageProcessingResult result)?  success,TResult? Function( ImageProcessingFailureKind kind,  String? debugDetail)?  failure,}) {final _that = this;
switch (_that) {
case ImageProcessingBackendSuccess() when success != null:
return success(_that.result);case ImageProcessingBackendFailure() when failure != null:
return failure(_that.kind,_that.debugDetail);case _:
  return null;

}
}

}

/// @nodoc


class ImageProcessingBackendSuccess implements ImageProcessingBackendResponse {
  const ImageProcessingBackendSuccess(this.result);
  

 final  ImageProcessingResult result;

/// Create a copy of ImageProcessingBackendResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageProcessingBackendSuccessCopyWith<ImageProcessingBackendSuccess> get copyWith => _$ImageProcessingBackendSuccessCopyWithImpl<ImageProcessingBackendSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageProcessingBackendSuccess&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,result);

@override
String toString() {
  return 'ImageProcessingBackendResponse.success(result: $result)';
}


}

/// @nodoc
abstract mixin class $ImageProcessingBackendSuccessCopyWith<$Res> implements $ImageProcessingBackendResponseCopyWith<$Res> {
  factory $ImageProcessingBackendSuccessCopyWith(ImageProcessingBackendSuccess value, $Res Function(ImageProcessingBackendSuccess) _then) = _$ImageProcessingBackendSuccessCopyWithImpl;
@useResult
$Res call({
 ImageProcessingResult result
});


$ImageProcessingResultCopyWith<$Res> get result;

}
/// @nodoc
class _$ImageProcessingBackendSuccessCopyWithImpl<$Res>
    implements $ImageProcessingBackendSuccessCopyWith<$Res> {
  _$ImageProcessingBackendSuccessCopyWithImpl(this._self, this._then);

  final ImageProcessingBackendSuccess _self;
  final $Res Function(ImageProcessingBackendSuccess) _then;

/// Create a copy of ImageProcessingBackendResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? result = null,}) {
  return _then(ImageProcessingBackendSuccess(
null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ImageProcessingResult,
  ));
}

/// Create a copy of ImageProcessingBackendResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageProcessingResultCopyWith<$Res> get result {
  
  return $ImageProcessingResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc


class ImageProcessingBackendFailure implements ImageProcessingBackendResponse {
  const ImageProcessingBackendFailure({required this.kind, this.debugDetail});
  

 final  ImageProcessingFailureKind kind;
 final  String? debugDetail;

/// Create a copy of ImageProcessingBackendResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageProcessingBackendFailureCopyWith<ImageProcessingBackendFailure> get copyWith => _$ImageProcessingBackendFailureCopyWithImpl<ImageProcessingBackendFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageProcessingBackendFailure&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.debugDetail, debugDetail) || other.debugDetail == debugDetail));
}


@override
int get hashCode => Object.hash(runtimeType,kind,debugDetail);

@override
String toString() {
  return 'ImageProcessingBackendResponse.failure(kind: $kind, debugDetail: $debugDetail)';
}


}

/// @nodoc
abstract mixin class $ImageProcessingBackendFailureCopyWith<$Res> implements $ImageProcessingBackendResponseCopyWith<$Res> {
  factory $ImageProcessingBackendFailureCopyWith(ImageProcessingBackendFailure value, $Res Function(ImageProcessingBackendFailure) _then) = _$ImageProcessingBackendFailureCopyWithImpl;
@useResult
$Res call({
 ImageProcessingFailureKind kind, String? debugDetail
});




}
/// @nodoc
class _$ImageProcessingBackendFailureCopyWithImpl<$Res>
    implements $ImageProcessingBackendFailureCopyWith<$Res> {
  _$ImageProcessingBackendFailureCopyWithImpl(this._self, this._then);

  final ImageProcessingBackendFailure _self;
  final $Res Function(ImageProcessingBackendFailure) _then;

/// Create a copy of ImageProcessingBackendResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? debugDetail = freezed,}) {
  return _then(ImageProcessingBackendFailure(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ImageProcessingFailureKind,debugDetail: freezed == debugDetail ? _self.debugDetail : debugDetail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
