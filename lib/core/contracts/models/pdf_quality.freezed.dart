// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pdf_quality.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PdfQualityPercent {


/// Create a copy of PdfQualityPercent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfQualityPercentCopyWith<PdfQualityPercent> get copyWith => _$PdfQualityPercentCopyWithImpl<PdfQualityPercent>(this as PdfQualityPercent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PdfQualityPercent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfQualityPercent&&(identical(other.value, _this.value) || other.value == _this.value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PdfQualityPercent;
  return Object.hash(runtimeType,_this.value);
}

@override
String toString() {
  final _this = this as PdfQualityPercent;
  return 'PdfQualityPercent(value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $PdfQualityPercentCopyWith<$Res>  {
  factory $PdfQualityPercentCopyWith(PdfQualityPercent value, $Res Function(PdfQualityPercent) _then) = _$PdfQualityPercentCopyWithImpl;
@useResult
$Res call({
 int value
});




}
/// @nodoc
class _$PdfQualityPercentCopyWithImpl<$Res>
    implements $PdfQualityPercentCopyWith<$Res> {
  _$PdfQualityPercentCopyWithImpl(this._self, this._then);

  final PdfQualityPercent _self;
  final $Res Function(PdfQualityPercent) _then;

/// Create a copy of PdfQualityPercent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(PdfQualityPercent(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PdfQualityPercent].
extension PdfQualityPercentPatterns on PdfQualityPercent {
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
mixin _$PageQualityPlan {

 PdfQualityPercent get documentQuality; Map<String, PdfQualityPercent> get pageOverrides;
/// Create a copy of PageQualityPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageQualityPlanCopyWith<PageQualityPlan> get copyWith => _$PageQualityPlanCopyWithImpl<PageQualityPlan>(this as PageQualityPlan, _$identity);

  /// Serializes this PageQualityPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PageQualityPlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageQualityPlan&&(identical(other.documentQuality, _this.documentQuality) || other.documentQuality == _this.documentQuality)&&const DeepCollectionEquality().equals(other.pageOverrides, _this.pageOverrides));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PageQualityPlan;
  return Object.hash(runtimeType,_this.documentQuality,const DeepCollectionEquality().hash(_this.pageOverrides));
}

@override
String toString() {
  final _this = this as PageQualityPlan;
  return 'PageQualityPlan(documentQuality: ${_this.documentQuality}, pageOverrides: ${_this.pageOverrides})';
}


}

/// @nodoc
abstract mixin class $PageQualityPlanCopyWith<$Res>  {
  factory $PageQualityPlanCopyWith(PageQualityPlan value, $Res Function(PageQualityPlan) _then) = _$PageQualityPlanCopyWithImpl;
@useResult
$Res call({
 PdfQualityPercent documentQuality, Map<String, PdfQualityPercent> pageOverrides
});


$PdfQualityPercentCopyWith<$Res> get documentQuality;

}
/// @nodoc
class _$PageQualityPlanCopyWithImpl<$Res>
    implements $PageQualityPlanCopyWith<$Res> {
  _$PageQualityPlanCopyWithImpl(this._self, this._then);

  final PageQualityPlan _self;
  final $Res Function(PageQualityPlan) _then;

/// Create a copy of PageQualityPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentQuality = null,Object? pageOverrides = null,}) {
  return _then(PageQualityPlan(
documentQuality: null == documentQuality ? _self.documentQuality : documentQuality // ignore: cast_nullable_to_non_nullable
as PdfQualityPercent,pageOverrides: null == pageOverrides ? _self.pageOverrides : pageOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, PdfQualityPercent>,
  ));
}
/// Create a copy of PageQualityPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PdfQualityPercentCopyWith<$Res> get documentQuality {
  
  return $PdfQualityPercentCopyWith<$Res>(_self.documentQuality, (value) {
    return _then(_self.copyWith(documentQuality: value));
  });
}
}


/// Adds pattern-matching-related methods to [PageQualityPlan].
extension PageQualityPlanPatterns on PageQualityPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageQualityPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageQualityPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageQualityPlan value)  $default,){
final _that = this;
switch (_that) {
case _PageQualityPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageQualityPlan value)?  $default,){
final _that = this;
switch (_that) {
case _PageQualityPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PdfQualityPercent documentQuality,  Map<String, PdfQualityPercent> pageOverrides)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageQualityPlan() when $default != null:
return $default(_that.documentQuality,_that.pageOverrides);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PdfQualityPercent documentQuality,  Map<String, PdfQualityPercent> pageOverrides)  $default,) {final _that = this;
switch (_that) {
case _PageQualityPlan():
return $default(_that.documentQuality,_that.pageOverrides);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PdfQualityPercent documentQuality,  Map<String, PdfQualityPercent> pageOverrides)?  $default,) {final _that = this;
switch (_that) {
case _PageQualityPlan() when $default != null:
return $default(_that.documentQuality,_that.pageOverrides);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PageQualityPlan extends PageQualityPlan {
  const _PageQualityPlan({required this.documentQuality,  Map<String, PdfQualityPercent> pageOverrides = const <String, PdfQualityPercent>{}}): _pageOverrides = pageOverrides,super._();
  factory _PageQualityPlan.fromJson(Map<String, dynamic> json) => _$PageQualityPlanFromJson(json);

@override final  PdfQualityPercent documentQuality;
 final  Map<String, PdfQualityPercent> _pageOverrides;
@override@JsonKey() Map<String, PdfQualityPercent> get pageOverrides {
  if (_pageOverrides is EqualUnmodifiableMapView) return _pageOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pageOverrides);
}


/// Create a copy of PageQualityPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageQualityPlanCopyWith<_PageQualityPlan> get copyWith => __$PageQualityPlanCopyWithImpl<_PageQualityPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageQualityPlanToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageQualityPlan&&(identical(other.documentQuality, documentQuality) || other.documentQuality == documentQuality)&&const DeepCollectionEquality().equals(other.pageOverrides, _pageOverrides));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,documentQuality,const DeepCollectionEquality().hash(_pageOverrides));
}

@override
String toString() {
    return 'PageQualityPlan(documentQuality: $documentQuality, pageOverrides: $pageOverrides)';
}


}

/// @nodoc
abstract mixin class _$PageQualityPlanCopyWith<$Res> implements $PageQualityPlanCopyWith<$Res> {
  factory _$PageQualityPlanCopyWith(_PageQualityPlan value, $Res Function(_PageQualityPlan) _then) = __$PageQualityPlanCopyWithImpl;
@override @useResult
$Res call({
 PdfQualityPercent documentQuality, Map<String, PdfQualityPercent> pageOverrides
});


@override $PdfQualityPercentCopyWith<$Res> get documentQuality;

}
/// @nodoc
class __$PageQualityPlanCopyWithImpl<$Res>
    implements _$PageQualityPlanCopyWith<$Res> {
  __$PageQualityPlanCopyWithImpl(this._self, this._then);

  final _PageQualityPlan _self;
  final $Res Function(_PageQualityPlan) _then;

/// Create a copy of PageQualityPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentQuality = null,Object? pageOverrides = null,}) {
  return _then(_PageQualityPlan(
documentQuality: null == documentQuality ? _self.documentQuality : documentQuality // ignore: cast_nullable_to_non_nullable
as PdfQualityPercent,pageOverrides: null == pageOverrides ? _self._pageOverrides : pageOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, PdfQualityPercent>,
  ));
}

/// Create a copy of PageQualityPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PdfQualityPercentCopyWith<$Res> get documentQuality {
  
  return $PdfQualityPercentCopyWith<$Res>(_self.documentQuality, (value) {
    return _then(_self.copyWith(documentQuality: value));
  });
}
}

// dart format on
