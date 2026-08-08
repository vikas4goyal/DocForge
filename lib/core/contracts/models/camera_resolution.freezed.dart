// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'camera_resolution.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CameraResolutionTier {

 String get id; String get label; int get shortEdge; int get longEdge; int get rank;
/// Create a copy of CameraResolutionTier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CameraResolutionTierCopyWith<CameraResolutionTier> get copyWith => _$CameraResolutionTierCopyWithImpl<CameraResolutionTier>(this as CameraResolutionTier, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CameraResolutionTier&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.shortEdge, shortEdge) || other.shortEdge == shortEdge)&&(identical(other.longEdge, longEdge) || other.longEdge == longEdge)&&(identical(other.rank, rank) || other.rank == rank));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,shortEdge,longEdge,rank);

@override
String toString() {
  return 'CameraResolutionTier(id: $id, label: $label, shortEdge: $shortEdge, longEdge: $longEdge, rank: $rank)';
}


}

/// @nodoc
abstract mixin class $CameraResolutionTierCopyWith<$Res>  {
  factory $CameraResolutionTierCopyWith(CameraResolutionTier value, $Res Function(CameraResolutionTier) _then) = _$CameraResolutionTierCopyWithImpl;
@useResult
$Res call({
 String id, String label, int shortEdge, int longEdge, int rank
});




}
/// @nodoc
class _$CameraResolutionTierCopyWithImpl<$Res>
    implements $CameraResolutionTierCopyWith<$Res> {
  _$CameraResolutionTierCopyWithImpl(this._self, this._then);

  final CameraResolutionTier _self;
  final $Res Function(CameraResolutionTier) _then;

/// Create a copy of CameraResolutionTier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? shortEdge = null,Object? longEdge = null,Object? rank = null,}) {
  return _then(CameraResolutionTier(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,shortEdge: null == shortEdge ? _self.shortEdge : shortEdge // ignore: cast_nullable_to_non_nullable
as int,longEdge: null == longEdge ? _self.longEdge : longEdge // ignore: cast_nullable_to_non_nullable
as int,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CameraResolutionTier].
extension CameraResolutionTierPatterns on CameraResolutionTier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}


/// @nodoc
mixin _$SupportedCameraResolution {

 CameraResolutionTier get tier; int get width; int get height;
/// Create a copy of SupportedCameraResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportedCameraResolutionCopyWith<SupportedCameraResolution> get copyWith => _$SupportedCameraResolutionCopyWithImpl<SupportedCameraResolution>(this as SupportedCameraResolution, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportedCameraResolution&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tier,width,height);

@override
String toString() {
  return 'SupportedCameraResolution(tier: $tier, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $SupportedCameraResolutionCopyWith<$Res>  {
  factory $SupportedCameraResolutionCopyWith(SupportedCameraResolution value, $Res Function(SupportedCameraResolution) _then) = _$SupportedCameraResolutionCopyWithImpl;
@useResult
$Res call({
 CameraResolutionTier tier, int width, int height
});




}
/// @nodoc
class _$SupportedCameraResolutionCopyWithImpl<$Res>
    implements $SupportedCameraResolutionCopyWith<$Res> {
  _$SupportedCameraResolutionCopyWithImpl(this._self, this._then);

  final SupportedCameraResolution _self;
  final $Res Function(SupportedCameraResolution) _then;

/// Create a copy of SupportedCameraResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tier = null,Object? width = null,Object? height = null,}) {
  return _then(SupportedCameraResolution(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as CameraResolutionTier,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportedCameraResolution].
extension SupportedCameraResolutionPatterns on SupportedCameraResolution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

DesiredCameraResolution _$DesiredCameraResolutionFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'fullResolution':
          return FullCameraResolution.fromJson(
            json
          );
                case 'tier':
          return TierCameraResolution.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'DesiredCameraResolution',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$DesiredCameraResolution {



  /// Serializes this DesiredCameraResolution to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesiredCameraResolution);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DesiredCameraResolution()';
}


}

/// @nodoc
class $DesiredCameraResolutionCopyWith<$Res>  {
$DesiredCameraResolutionCopyWith(DesiredCameraResolution _, $Res Function(DesiredCameraResolution) __);
}


/// Adds pattern-matching-related methods to [DesiredCameraResolution].
extension DesiredCameraResolutionPatterns on DesiredCameraResolution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FullCameraResolution value)?  fullResolution,TResult Function( TierCameraResolution value)?  tier,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FullCameraResolution() when fullResolution != null:
return fullResolution(_that);case TierCameraResolution() when tier != null:
return tier(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FullCameraResolution value)  fullResolution,required TResult Function( TierCameraResolution value)  tier,}){
final _that = this;
switch (_that) {
case FullCameraResolution():
return fullResolution(_that);case TierCameraResolution():
return tier(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FullCameraResolution value)?  fullResolution,TResult? Function( TierCameraResolution value)?  tier,}){
final _that = this;
switch (_that) {
case FullCameraResolution() when fullResolution != null:
return fullResolution(_that);case TierCameraResolution() when tier != null:
return tier(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  fullResolution,TResult Function( CameraResolutionTier value)?  tier,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FullCameraResolution() when fullResolution != null:
return fullResolution();case TierCameraResolution() when tier != null:
return tier(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  fullResolution,required TResult Function( CameraResolutionTier value)  tier,}) {final _that = this;
switch (_that) {
case FullCameraResolution():
return fullResolution();case TierCameraResolution():
return tier(_that.value);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  fullResolution,TResult? Function( CameraResolutionTier value)?  tier,}) {final _that = this;
switch (_that) {
case FullCameraResolution() when fullResolution != null:
return fullResolution();case TierCameraResolution() when tier != null:
return tier(_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class FullCameraResolution extends DesiredCameraResolution {
  const FullCameraResolution({final  String? $type}): $type = $type ?? 'fullResolution',super._();
  factory FullCameraResolution.fromJson(Map<String, dynamic> json) => _$FullCameraResolutionFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$FullCameraResolutionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FullCameraResolution);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DesiredCameraResolution.fullResolution()';
}


}




/// @nodoc
@JsonSerializable()

class TierCameraResolution extends DesiredCameraResolution {
  const TierCameraResolution(this.value, {final  String? $type}): $type = $type ?? 'tier',super._();
  factory TierCameraResolution.fromJson(Map<String, dynamic> json) => _$TierCameraResolutionFromJson(json);

 final  CameraResolutionTier value;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of DesiredCameraResolution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TierCameraResolutionCopyWith<TierCameraResolution> get copyWith => _$TierCameraResolutionCopyWithImpl<TierCameraResolution>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TierCameraResolutionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TierCameraResolution&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'DesiredCameraResolution.tier(value: $value)';
}


}

/// @nodoc
abstract mixin class $TierCameraResolutionCopyWith<$Res> implements $DesiredCameraResolutionCopyWith<$Res> {
  factory $TierCameraResolutionCopyWith(TierCameraResolution value, $Res Function(TierCameraResolution) _then) = _$TierCameraResolutionCopyWithImpl;
@useResult
$Res call({
 CameraResolutionTier value
});


$CameraResolutionTierCopyWith<$Res> get value;

}
/// @nodoc
class _$TierCameraResolutionCopyWithImpl<$Res>
    implements $TierCameraResolutionCopyWith<$Res> {
  _$TierCameraResolutionCopyWithImpl(this._self, this._then);

  final TierCameraResolution _self;
  final $Res Function(TierCameraResolution) _then;

/// Create a copy of DesiredCameraResolution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(TierCameraResolution(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as CameraResolutionTier,
  ));
}

/// Create a copy of DesiredCameraResolution
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CameraResolutionTierCopyWith<$Res> get value {
  
  return $CameraResolutionTierCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

// dart format on
