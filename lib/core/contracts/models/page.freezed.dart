// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NormalisedPoint {

 double get x; double get y;
/// Create a copy of NormalisedPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NormalisedPointCopyWith<NormalisedPoint> get copyWith => _$NormalisedPointCopyWithImpl<NormalisedPoint>(this as NormalisedPoint, _$identity);

  /// Serializes this NormalisedPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NormalisedPoint&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'NormalisedPoint(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $NormalisedPointCopyWith<$Res>  {
  factory $NormalisedPointCopyWith(NormalisedPoint value, $Res Function(NormalisedPoint) _then) = _$NormalisedPointCopyWithImpl;
@useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class _$NormalisedPointCopyWithImpl<$Res>
    implements $NormalisedPointCopyWith<$Res> {
  _$NormalisedPointCopyWithImpl(this._self, this._then);

  final NormalisedPoint _self;
  final $Res Function(NormalisedPoint) _then;

/// Create a copy of NormalisedPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [NormalisedPoint].
extension NormalisedPointPatterns on NormalisedPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NormalisedPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NormalisedPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NormalisedPoint value)  $default,){
final _that = this;
switch (_that) {
case _NormalisedPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NormalisedPoint value)?  $default,){
final _that = this;
switch (_that) {
case _NormalisedPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NormalisedPoint() when $default != null:
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double y)  $default,) {final _that = this;
switch (_that) {
case _NormalisedPoint():
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double y)?  $default,) {final _that = this;
switch (_that) {
case _NormalisedPoint() when $default != null:
return $default(_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NormalisedPoint extends NormalisedPoint {
  const _NormalisedPoint({required this.x, required this.y}): super._();
  factory _NormalisedPoint.fromJson(Map<String, dynamic> json) => _$NormalisedPointFromJson(json);

@override final  double x;
@override final  double y;

/// Create a copy of NormalisedPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NormalisedPointCopyWith<_NormalisedPoint> get copyWith => __$NormalisedPointCopyWithImpl<_NormalisedPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NormalisedPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NormalisedPoint&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'NormalisedPoint(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class _$NormalisedPointCopyWith<$Res> implements $NormalisedPointCopyWith<$Res> {
  factory _$NormalisedPointCopyWith(_NormalisedPoint value, $Res Function(_NormalisedPoint) _then) = __$NormalisedPointCopyWithImpl;
@override @useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class __$NormalisedPointCopyWithImpl<$Res>
    implements _$NormalisedPointCopyWith<$Res> {
  __$NormalisedPointCopyWithImpl(this._self, this._then);

  final _NormalisedPoint _self;
  final $Res Function(_NormalisedPoint) _then;

/// Create a copy of NormalisedPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,}) {
  return _then(_NormalisedPoint(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PageQuad {

 NormalisedPoint get topLeft; NormalisedPoint get topRight; NormalisedPoint get bottomRight; NormalisedPoint get bottomLeft;
/// Create a copy of PageQuad
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageQuadCopyWith<PageQuad> get copyWith => _$PageQuadCopyWithImpl<PageQuad>(this as PageQuad, _$identity);

  /// Serializes this PageQuad to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageQuad&&(identical(other.topLeft, topLeft) || other.topLeft == topLeft)&&(identical(other.topRight, topRight) || other.topRight == topRight)&&(identical(other.bottomRight, bottomRight) || other.bottomRight == bottomRight)&&(identical(other.bottomLeft, bottomLeft) || other.bottomLeft == bottomLeft));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,topLeft,topRight,bottomRight,bottomLeft);

@override
String toString() {
  return 'PageQuad(topLeft: $topLeft, topRight: $topRight, bottomRight: $bottomRight, bottomLeft: $bottomLeft)';
}


}

/// @nodoc
abstract mixin class $PageQuadCopyWith<$Res>  {
  factory $PageQuadCopyWith(PageQuad value, $Res Function(PageQuad) _then) = _$PageQuadCopyWithImpl;
@useResult
$Res call({
 NormalisedPoint topLeft, NormalisedPoint topRight, NormalisedPoint bottomRight, NormalisedPoint bottomLeft
});


$NormalisedPointCopyWith<$Res> get topLeft;$NormalisedPointCopyWith<$Res> get topRight;$NormalisedPointCopyWith<$Res> get bottomRight;$NormalisedPointCopyWith<$Res> get bottomLeft;

}
/// @nodoc
class _$PageQuadCopyWithImpl<$Res>
    implements $PageQuadCopyWith<$Res> {
  _$PageQuadCopyWithImpl(this._self, this._then);

  final PageQuad _self;
  final $Res Function(PageQuad) _then;

/// Create a copy of PageQuad
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? topLeft = null,Object? topRight = null,Object? bottomRight = null,Object? bottomLeft = null,}) {
  return _then(_self.copyWith(
topLeft: null == topLeft ? _self.topLeft : topLeft // ignore: cast_nullable_to_non_nullable
as NormalisedPoint,topRight: null == topRight ? _self.topRight : topRight // ignore: cast_nullable_to_non_nullable
as NormalisedPoint,bottomRight: null == bottomRight ? _self.bottomRight : bottomRight // ignore: cast_nullable_to_non_nullable
as NormalisedPoint,bottomLeft: null == bottomLeft ? _self.bottomLeft : bottomLeft // ignore: cast_nullable_to_non_nullable
as NormalisedPoint,
  ));
}
/// Create a copy of PageQuad
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NormalisedPointCopyWith<$Res> get topLeft {
  
  return $NormalisedPointCopyWith<$Res>(_self.topLeft, (value) {
    return _then(_self.copyWith(topLeft: value));
  });
}/// Create a copy of PageQuad
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NormalisedPointCopyWith<$Res> get topRight {
  
  return $NormalisedPointCopyWith<$Res>(_self.topRight, (value) {
    return _then(_self.copyWith(topRight: value));
  });
}/// Create a copy of PageQuad
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NormalisedPointCopyWith<$Res> get bottomRight {
  
  return $NormalisedPointCopyWith<$Res>(_self.bottomRight, (value) {
    return _then(_self.copyWith(bottomRight: value));
  });
}/// Create a copy of PageQuad
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NormalisedPointCopyWith<$Res> get bottomLeft {
  
  return $NormalisedPointCopyWith<$Res>(_self.bottomLeft, (value) {
    return _then(_self.copyWith(bottomLeft: value));
  });
}
}


/// Adds pattern-matching-related methods to [PageQuad].
extension PageQuadPatterns on PageQuad {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageQuad value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageQuad() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageQuad value)  $default,){
final _that = this;
switch (_that) {
case _PageQuad():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageQuad value)?  $default,){
final _that = this;
switch (_that) {
case _PageQuad() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( NormalisedPoint topLeft,  NormalisedPoint topRight,  NormalisedPoint bottomRight,  NormalisedPoint bottomLeft)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageQuad() when $default != null:
return $default(_that.topLeft,_that.topRight,_that.bottomRight,_that.bottomLeft);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( NormalisedPoint topLeft,  NormalisedPoint topRight,  NormalisedPoint bottomRight,  NormalisedPoint bottomLeft)  $default,) {final _that = this;
switch (_that) {
case _PageQuad():
return $default(_that.topLeft,_that.topRight,_that.bottomRight,_that.bottomLeft);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( NormalisedPoint topLeft,  NormalisedPoint topRight,  NormalisedPoint bottomRight,  NormalisedPoint bottomLeft)?  $default,) {final _that = this;
switch (_that) {
case _PageQuad() when $default != null:
return $default(_that.topLeft,_that.topRight,_that.bottomRight,_that.bottomLeft);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PageQuad extends PageQuad {
  const _PageQuad({required this.topLeft, required this.topRight, required this.bottomRight, required this.bottomLeft}): super._();
  factory _PageQuad.fromJson(Map<String, dynamic> json) => _$PageQuadFromJson(json);

@override final  NormalisedPoint topLeft;
@override final  NormalisedPoint topRight;
@override final  NormalisedPoint bottomRight;
@override final  NormalisedPoint bottomLeft;

/// Create a copy of PageQuad
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageQuadCopyWith<_PageQuad> get copyWith => __$PageQuadCopyWithImpl<_PageQuad>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageQuadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageQuad&&(identical(other.topLeft, topLeft) || other.topLeft == topLeft)&&(identical(other.topRight, topRight) || other.topRight == topRight)&&(identical(other.bottomRight, bottomRight) || other.bottomRight == bottomRight)&&(identical(other.bottomLeft, bottomLeft) || other.bottomLeft == bottomLeft));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,topLeft,topRight,bottomRight,bottomLeft);

@override
String toString() {
  return 'PageQuad(topLeft: $topLeft, topRight: $topRight, bottomRight: $bottomRight, bottomLeft: $bottomLeft)';
}


}

/// @nodoc
abstract mixin class _$PageQuadCopyWith<$Res> implements $PageQuadCopyWith<$Res> {
  factory _$PageQuadCopyWith(_PageQuad value, $Res Function(_PageQuad) _then) = __$PageQuadCopyWithImpl;
@override @useResult
$Res call({
 NormalisedPoint topLeft, NormalisedPoint topRight, NormalisedPoint bottomRight, NormalisedPoint bottomLeft
});


@override $NormalisedPointCopyWith<$Res> get topLeft;@override $NormalisedPointCopyWith<$Res> get topRight;@override $NormalisedPointCopyWith<$Res> get bottomRight;@override $NormalisedPointCopyWith<$Res> get bottomLeft;

}
/// @nodoc
class __$PageQuadCopyWithImpl<$Res>
    implements _$PageQuadCopyWith<$Res> {
  __$PageQuadCopyWithImpl(this._self, this._then);

  final _PageQuad _self;
  final $Res Function(_PageQuad) _then;

/// Create a copy of PageQuad
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? topLeft = null,Object? topRight = null,Object? bottomRight = null,Object? bottomLeft = null,}) {
  return _then(_PageQuad(
topLeft: null == topLeft ? _self.topLeft : topLeft // ignore: cast_nullable_to_non_nullable
as NormalisedPoint,topRight: null == topRight ? _self.topRight : topRight // ignore: cast_nullable_to_non_nullable
as NormalisedPoint,bottomRight: null == bottomRight ? _self.bottomRight : bottomRight // ignore: cast_nullable_to_non_nullable
as NormalisedPoint,bottomLeft: null == bottomLeft ? _self.bottomLeft : bottomLeft // ignore: cast_nullable_to_non_nullable
as NormalisedPoint,
  ));
}

/// Create a copy of PageQuad
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NormalisedPointCopyWith<$Res> get topLeft {
  
  return $NormalisedPointCopyWith<$Res>(_self.topLeft, (value) {
    return _then(_self.copyWith(topLeft: value));
  });
}/// Create a copy of PageQuad
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NormalisedPointCopyWith<$Res> get topRight {
  
  return $NormalisedPointCopyWith<$Res>(_self.topRight, (value) {
    return _then(_self.copyWith(topRight: value));
  });
}/// Create a copy of PageQuad
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NormalisedPointCopyWith<$Res> get bottomRight {
  
  return $NormalisedPointCopyWith<$Res>(_self.bottomRight, (value) {
    return _then(_self.copyWith(bottomRight: value));
  });
}/// Create a copy of PageQuad
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NormalisedPointCopyWith<$Res> get bottomLeft {
  
  return $NormalisedPointCopyWith<$Res>(_self.bottomLeft, (value) {
    return _then(_self.copyWith(bottomLeft: value));
  });
}
}


/// @nodoc
mixin _$EnhancementSettings {

 EnhancementFilter get filter;/// Brightness offset in the range -0.35 to 0.35; 0.0 is unchanged.
 double get brightness;/// Contrast offset in the range -0.5 to 0.5; 0.0 is unchanged.
 double get contrast;/// Sharpening amount in the range 0.0 to 0.6; 0.0 is unchanged.
 double get sharpen;/// Whether uneven shadowing is removed.
 bool get shadowRemoval;
/// Create a copy of EnhancementSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnhancementSettingsCopyWith<EnhancementSettings> get copyWith => _$EnhancementSettingsCopyWithImpl<EnhancementSettings>(this as EnhancementSettings, _$identity);

  /// Serializes this EnhancementSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnhancementSettings&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.contrast, contrast) || other.contrast == contrast)&&(identical(other.sharpen, sharpen) || other.sharpen == sharpen)&&(identical(other.shadowRemoval, shadowRemoval) || other.shadowRemoval == shadowRemoval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,filter,brightness,contrast,sharpen,shadowRemoval);

@override
String toString() {
  return 'EnhancementSettings(filter: $filter, brightness: $brightness, contrast: $contrast, sharpen: $sharpen, shadowRemoval: $shadowRemoval)';
}


}

/// @nodoc
abstract mixin class $EnhancementSettingsCopyWith<$Res>  {
  factory $EnhancementSettingsCopyWith(EnhancementSettings value, $Res Function(EnhancementSettings) _then) = _$EnhancementSettingsCopyWithImpl;
@useResult
$Res call({
 EnhancementFilter filter, double brightness, double contrast, double sharpen, bool shadowRemoval
});




}
/// @nodoc
class _$EnhancementSettingsCopyWithImpl<$Res>
    implements $EnhancementSettingsCopyWith<$Res> {
  _$EnhancementSettingsCopyWithImpl(this._self, this._then);

  final EnhancementSettings _self;
  final $Res Function(EnhancementSettings) _then;

/// Create a copy of EnhancementSettings
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


/// Adds pattern-matching-related methods to [EnhancementSettings].
extension EnhancementSettingsPatterns on EnhancementSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnhancementSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnhancementSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnhancementSettings value)  $default,){
final _that = this;
switch (_that) {
case _EnhancementSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnhancementSettings value)?  $default,){
final _that = this;
switch (_that) {
case _EnhancementSettings() when $default != null:
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
case _EnhancementSettings() when $default != null:
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
case _EnhancementSettings():
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
case _EnhancementSettings() when $default != null:
return $default(_that.filter,_that.brightness,_that.contrast,_that.sharpen,_that.shadowRemoval);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnhancementSettings extends EnhancementSettings {
  const _EnhancementSettings({this.filter = EnhancementFilter.original, this.brightness = 0.0, this.contrast = 0.0, this.sharpen = 0.0, this.shadowRemoval = false}): super._();
  factory _EnhancementSettings.fromJson(Map<String, dynamic> json) => _$EnhancementSettingsFromJson(json);

@override@JsonKey() final  EnhancementFilter filter;
/// Brightness offset in the range -0.35 to 0.35; 0.0 is unchanged.
@override@JsonKey() final  double brightness;
/// Contrast offset in the range -0.5 to 0.5; 0.0 is unchanged.
@override@JsonKey() final  double contrast;
/// Sharpening amount in the range 0.0 to 0.6; 0.0 is unchanged.
@override@JsonKey() final  double sharpen;
/// Whether uneven shadowing is removed.
@override@JsonKey() final  bool shadowRemoval;

/// Create a copy of EnhancementSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnhancementSettingsCopyWith<_EnhancementSettings> get copyWith => __$EnhancementSettingsCopyWithImpl<_EnhancementSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnhancementSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnhancementSettings&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.contrast, contrast) || other.contrast == contrast)&&(identical(other.sharpen, sharpen) || other.sharpen == sharpen)&&(identical(other.shadowRemoval, shadowRemoval) || other.shadowRemoval == shadowRemoval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,filter,brightness,contrast,sharpen,shadowRemoval);

@override
String toString() {
  return 'EnhancementSettings(filter: $filter, brightness: $brightness, contrast: $contrast, sharpen: $sharpen, shadowRemoval: $shadowRemoval)';
}


}

/// @nodoc
abstract mixin class _$EnhancementSettingsCopyWith<$Res> implements $EnhancementSettingsCopyWith<$Res> {
  factory _$EnhancementSettingsCopyWith(_EnhancementSettings value, $Res Function(_EnhancementSettings) _then) = __$EnhancementSettingsCopyWithImpl;
@override @useResult
$Res call({
 EnhancementFilter filter, double brightness, double contrast, double sharpen, bool shadowRemoval
});




}
/// @nodoc
class __$EnhancementSettingsCopyWithImpl<$Res>
    implements _$EnhancementSettingsCopyWith<$Res> {
  __$EnhancementSettingsCopyWithImpl(this._self, this._then);

  final _EnhancementSettings _self;
  final $Res Function(_EnhancementSettings) _then;

/// Create a copy of EnhancementSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? filter = null,Object? brightness = null,Object? contrast = null,Object? sharpen = null,Object? shadowRemoval = null,}) {
  return _then(_EnhancementSettings(
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
mixin _$DocumentPage {

 PageId get id; DocumentId get documentId;/// Zero-based position of this page within its document.
 int get order;/// Path to the page image on disk, inside app-private storage.
 String get imagePath; PageRotation get rotation; EnhancementSettings get enhancement;/// Path to a cached display-resolution thumbnail, when one exists.
 String? get thumbnailPath;
/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentPageCopyWith<DocumentPage> get copyWith => _$DocumentPageCopyWithImpl<DocumentPage>(this as DocumentPage, _$identity);

  /// Serializes this DocumentPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentPage&&(identical(other.id, id) || other.id == id)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.order, order) || other.order == order)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.rotation, rotation) || other.rotation == rotation)&&(identical(other.enhancement, enhancement) || other.enhancement == enhancement)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,documentId,order,imagePath,rotation,enhancement,thumbnailPath);

@override
String toString() {
  return 'DocumentPage(id: $id, documentId: $documentId, order: $order, imagePath: $imagePath, rotation: $rotation, enhancement: $enhancement, thumbnailPath: $thumbnailPath)';
}


}

/// @nodoc
abstract mixin class $DocumentPageCopyWith<$Res>  {
  factory $DocumentPageCopyWith(DocumentPage value, $Res Function(DocumentPage) _then) = _$DocumentPageCopyWithImpl;
@useResult
$Res call({
 PageId id, DocumentId documentId, int order, String imagePath, PageRotation rotation, EnhancementSettings enhancement, String? thumbnailPath
});


$EnhancementSettingsCopyWith<$Res> get enhancement;

}
/// @nodoc
class _$DocumentPageCopyWithImpl<$Res>
    implements $DocumentPageCopyWith<$Res> {
  _$DocumentPageCopyWithImpl(this._self, this._then);

  final DocumentPage _self;
  final $Res Function(DocumentPage) _then;

/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? documentId = null,Object? order = null,Object? imagePath = null,Object? rotation = null,Object? enhancement = null,Object? thumbnailPath = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PageId,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as DocumentId,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,rotation: null == rotation ? _self.rotation : rotation // ignore: cast_nullable_to_non_nullable
as PageRotation,enhancement: null == enhancement ? _self.enhancement : enhancement // ignore: cast_nullable_to_non_nullable
as EnhancementSettings,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnhancementSettingsCopyWith<$Res> get enhancement {
  
  return $EnhancementSettingsCopyWith<$Res>(_self.enhancement, (value) {
    return _then(_self.copyWith(enhancement: value));
  });
}
}


/// Adds pattern-matching-related methods to [DocumentPage].
extension DocumentPagePatterns on DocumentPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentPage value)  $default,){
final _that = this;
switch (_that) {
case _DocumentPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentPage value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PageId id,  DocumentId documentId,  int order,  String imagePath,  PageRotation rotation,  EnhancementSettings enhancement,  String? thumbnailPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentPage() when $default != null:
return $default(_that.id,_that.documentId,_that.order,_that.imagePath,_that.rotation,_that.enhancement,_that.thumbnailPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PageId id,  DocumentId documentId,  int order,  String imagePath,  PageRotation rotation,  EnhancementSettings enhancement,  String? thumbnailPath)  $default,) {final _that = this;
switch (_that) {
case _DocumentPage():
return $default(_that.id,_that.documentId,_that.order,_that.imagePath,_that.rotation,_that.enhancement,_that.thumbnailPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PageId id,  DocumentId documentId,  int order,  String imagePath,  PageRotation rotation,  EnhancementSettings enhancement,  String? thumbnailPath)?  $default,) {final _that = this;
switch (_that) {
case _DocumentPage() when $default != null:
return $default(_that.id,_that.documentId,_that.order,_that.imagePath,_that.rotation,_that.enhancement,_that.thumbnailPath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentPage extends DocumentPage {
  const _DocumentPage({required this.id, required this.documentId, required this.order, required this.imagePath, this.rotation = PageRotation.none, this.enhancement = const EnhancementSettings(), this.thumbnailPath}): super._();
  factory _DocumentPage.fromJson(Map<String, dynamic> json) => _$DocumentPageFromJson(json);

@override final  PageId id;
@override final  DocumentId documentId;
/// Zero-based position of this page within its document.
@override final  int order;
/// Path to the page image on disk, inside app-private storage.
@override final  String imagePath;
@override@JsonKey() final  PageRotation rotation;
@override@JsonKey() final  EnhancementSettings enhancement;
/// Path to a cached display-resolution thumbnail, when one exists.
@override final  String? thumbnailPath;

/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentPageCopyWith<_DocumentPage> get copyWith => __$DocumentPageCopyWithImpl<_DocumentPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentPage&&(identical(other.id, id) || other.id == id)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.order, order) || other.order == order)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.rotation, rotation) || other.rotation == rotation)&&(identical(other.enhancement, enhancement) || other.enhancement == enhancement)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,documentId,order,imagePath,rotation,enhancement,thumbnailPath);

@override
String toString() {
  return 'DocumentPage(id: $id, documentId: $documentId, order: $order, imagePath: $imagePath, rotation: $rotation, enhancement: $enhancement, thumbnailPath: $thumbnailPath)';
}


}

/// @nodoc
abstract mixin class _$DocumentPageCopyWith<$Res> implements $DocumentPageCopyWith<$Res> {
  factory _$DocumentPageCopyWith(_DocumentPage value, $Res Function(_DocumentPage) _then) = __$DocumentPageCopyWithImpl;
@override @useResult
$Res call({
 PageId id, DocumentId documentId, int order, String imagePath, PageRotation rotation, EnhancementSettings enhancement, String? thumbnailPath
});


@override $EnhancementSettingsCopyWith<$Res> get enhancement;

}
/// @nodoc
class __$DocumentPageCopyWithImpl<$Res>
    implements _$DocumentPageCopyWith<$Res> {
  __$DocumentPageCopyWithImpl(this._self, this._then);

  final _DocumentPage _self;
  final $Res Function(_DocumentPage) _then;

/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? documentId = null,Object? order = null,Object? imagePath = null,Object? rotation = null,Object? enhancement = null,Object? thumbnailPath = freezed,}) {
  return _then(_DocumentPage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PageId,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as DocumentId,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,rotation: null == rotation ? _self.rotation : rotation // ignore: cast_nullable_to_non_nullable
as PageRotation,enhancement: null == enhancement ? _self.enhancement : enhancement // ignore: cast_nullable_to_non_nullable
as EnhancementSettings,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of DocumentPage
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
mixin _$PageRef {

 PageId get id; String get imagePath; PageRotation get rotation; EnhancementSettings get enhancement;
/// Create a copy of PageRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageRefCopyWith<PageRef> get copyWith => _$PageRefCopyWithImpl<PageRef>(this as PageRef, _$identity);

  /// Serializes this PageRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageRef&&(identical(other.id, id) || other.id == id)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.rotation, rotation) || other.rotation == rotation)&&(identical(other.enhancement, enhancement) || other.enhancement == enhancement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,imagePath,rotation,enhancement);

@override
String toString() {
  return 'PageRef(id: $id, imagePath: $imagePath, rotation: $rotation, enhancement: $enhancement)';
}


}

/// @nodoc
abstract mixin class $PageRefCopyWith<$Res>  {
  factory $PageRefCopyWith(PageRef value, $Res Function(PageRef) _then) = _$PageRefCopyWithImpl;
@useResult
$Res call({
 PageId id, String imagePath, PageRotation rotation, EnhancementSettings enhancement
});


$EnhancementSettingsCopyWith<$Res> get enhancement;

}
/// @nodoc
class _$PageRefCopyWithImpl<$Res>
    implements $PageRefCopyWith<$Res> {
  _$PageRefCopyWithImpl(this._self, this._then);

  final PageRef _self;
  final $Res Function(PageRef) _then;

/// Create a copy of PageRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? imagePath = null,Object? rotation = null,Object? enhancement = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PageId,imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,rotation: null == rotation ? _self.rotation : rotation // ignore: cast_nullable_to_non_nullable
as PageRotation,enhancement: null == enhancement ? _self.enhancement : enhancement // ignore: cast_nullable_to_non_nullable
as EnhancementSettings,
  ));
}
/// Create a copy of PageRef
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnhancementSettingsCopyWith<$Res> get enhancement {
  
  return $EnhancementSettingsCopyWith<$Res>(_self.enhancement, (value) {
    return _then(_self.copyWith(enhancement: value));
  });
}
}


/// Adds pattern-matching-related methods to [PageRef].
extension PageRefPatterns on PageRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageRef value)  $default,){
final _that = this;
switch (_that) {
case _PageRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageRef value)?  $default,){
final _that = this;
switch (_that) {
case _PageRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PageId id,  String imagePath,  PageRotation rotation,  EnhancementSettings enhancement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageRef() when $default != null:
return $default(_that.id,_that.imagePath,_that.rotation,_that.enhancement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PageId id,  String imagePath,  PageRotation rotation,  EnhancementSettings enhancement)  $default,) {final _that = this;
switch (_that) {
case _PageRef():
return $default(_that.id,_that.imagePath,_that.rotation,_that.enhancement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PageId id,  String imagePath,  PageRotation rotation,  EnhancementSettings enhancement)?  $default,) {final _that = this;
switch (_that) {
case _PageRef() when $default != null:
return $default(_that.id,_that.imagePath,_that.rotation,_that.enhancement);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PageRef extends PageRef {
  const _PageRef({required this.id, required this.imagePath, this.rotation = PageRotation.none, this.enhancement = const EnhancementSettings()}): super._();
  factory _PageRef.fromJson(Map<String, dynamic> json) => _$PageRefFromJson(json);

@override final  PageId id;
@override final  String imagePath;
@override@JsonKey() final  PageRotation rotation;
@override@JsonKey() final  EnhancementSettings enhancement;

/// Create a copy of PageRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageRefCopyWith<_PageRef> get copyWith => __$PageRefCopyWithImpl<_PageRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageRef&&(identical(other.id, id) || other.id == id)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.rotation, rotation) || other.rotation == rotation)&&(identical(other.enhancement, enhancement) || other.enhancement == enhancement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,imagePath,rotation,enhancement);

@override
String toString() {
  return 'PageRef(id: $id, imagePath: $imagePath, rotation: $rotation, enhancement: $enhancement)';
}


}

/// @nodoc
abstract mixin class _$PageRefCopyWith<$Res> implements $PageRefCopyWith<$Res> {
  factory _$PageRefCopyWith(_PageRef value, $Res Function(_PageRef) _then) = __$PageRefCopyWithImpl;
@override @useResult
$Res call({
 PageId id, String imagePath, PageRotation rotation, EnhancementSettings enhancement
});


@override $EnhancementSettingsCopyWith<$Res> get enhancement;

}
/// @nodoc
class __$PageRefCopyWithImpl<$Res>
    implements _$PageRefCopyWith<$Res> {
  __$PageRefCopyWithImpl(this._self, this._then);

  final _PageRef _self;
  final $Res Function(_PageRef) _then;

/// Create a copy of PageRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? imagePath = null,Object? rotation = null,Object? enhancement = null,}) {
  return _then(_PageRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PageId,imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,rotation: null == rotation ? _self.rotation : rotation // ignore: cast_nullable_to_non_nullable
as PageRotation,enhancement: null == enhancement ? _self.enhancement : enhancement // ignore: cast_nullable_to_non_nullable
as EnhancementSettings,
  ));
}

/// Create a copy of PageRef
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EnhancementSettingsCopyWith<$Res> get enhancement {
  
  return $EnhancementSettingsCopyWith<$Res>(_self.enhancement, (value) {
    return _then(_self.copyWith(enhancement: value));
  });
}
}

// dart format on
