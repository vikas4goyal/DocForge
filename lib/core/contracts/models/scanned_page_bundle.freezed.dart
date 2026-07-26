// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scanned_page_bundle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScannedPageBundle {

/// Pages in the order they will appear in the finished document.
 List<PageRef> get pages; PageSource get source;/// Title suggested by the source, when it has one — an imported file's
/// name, for example. Null means the default naming pattern applies.
 String? get suggestedTitle;
/// Create a copy of ScannedPageBundle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScannedPageBundleCopyWith<ScannedPageBundle> get copyWith => _$ScannedPageBundleCopyWithImpl<ScannedPageBundle>(this as ScannedPageBundle, _$identity);

  /// Serializes this ScannedPageBundle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScannedPageBundle&&const DeepCollectionEquality().equals(other.pages, pages)&&(identical(other.source, source) || other.source == source)&&(identical(other.suggestedTitle, suggestedTitle) || other.suggestedTitle == suggestedTitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(pages),source,suggestedTitle);

@override
String toString() {
  return 'ScannedPageBundle(pages: $pages, source: $source, suggestedTitle: $suggestedTitle)';
}


}

/// @nodoc
abstract mixin class $ScannedPageBundleCopyWith<$Res>  {
  factory $ScannedPageBundleCopyWith(ScannedPageBundle value, $Res Function(ScannedPageBundle) _then) = _$ScannedPageBundleCopyWithImpl;
@useResult
$Res call({
 List<PageRef> pages, PageSource source, String? suggestedTitle
});




}
/// @nodoc
class _$ScannedPageBundleCopyWithImpl<$Res>
    implements $ScannedPageBundleCopyWith<$Res> {
  _$ScannedPageBundleCopyWithImpl(this._self, this._then);

  final ScannedPageBundle _self;
  final $Res Function(ScannedPageBundle) _then;

/// Create a copy of ScannedPageBundle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pages = null,Object? source = null,Object? suggestedTitle = freezed,}) {
  return _then(_self.copyWith(
pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as List<PageRef>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PageSource,suggestedTitle: freezed == suggestedTitle ? _self.suggestedTitle : suggestedTitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScannedPageBundle].
extension ScannedPageBundlePatterns on ScannedPageBundle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScannedPageBundle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScannedPageBundle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScannedPageBundle value)  $default,){
final _that = this;
switch (_that) {
case _ScannedPageBundle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScannedPageBundle value)?  $default,){
final _that = this;
switch (_that) {
case _ScannedPageBundle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PageRef> pages,  PageSource source,  String? suggestedTitle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScannedPageBundle() when $default != null:
return $default(_that.pages,_that.source,_that.suggestedTitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PageRef> pages,  PageSource source,  String? suggestedTitle)  $default,) {final _that = this;
switch (_that) {
case _ScannedPageBundle():
return $default(_that.pages,_that.source,_that.suggestedTitle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PageRef> pages,  PageSource source,  String? suggestedTitle)?  $default,) {final _that = this;
switch (_that) {
case _ScannedPageBundle() when $default != null:
return $default(_that.pages,_that.source,_that.suggestedTitle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScannedPageBundle extends ScannedPageBundle {
  const _ScannedPageBundle({required final  List<PageRef> pages, required this.source, this.suggestedTitle}): _pages = pages,super._();
  factory _ScannedPageBundle.fromJson(Map<String, dynamic> json) => _$ScannedPageBundleFromJson(json);

/// Pages in the order they will appear in the finished document.
 final  List<PageRef> _pages;
/// Pages in the order they will appear in the finished document.
@override List<PageRef> get pages {
  if (_pages is EqualUnmodifiableListView) return _pages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pages);
}

@override final  PageSource source;
/// Title suggested by the source, when it has one — an imported file's
/// name, for example. Null means the default naming pattern applies.
@override final  String? suggestedTitle;

/// Create a copy of ScannedPageBundle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScannedPageBundleCopyWith<_ScannedPageBundle> get copyWith => __$ScannedPageBundleCopyWithImpl<_ScannedPageBundle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScannedPageBundleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScannedPageBundle&&const DeepCollectionEquality().equals(other._pages, _pages)&&(identical(other.source, source) || other.source == source)&&(identical(other.suggestedTitle, suggestedTitle) || other.suggestedTitle == suggestedTitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_pages),source,suggestedTitle);

@override
String toString() {
  return 'ScannedPageBundle(pages: $pages, source: $source, suggestedTitle: $suggestedTitle)';
}


}

/// @nodoc
abstract mixin class _$ScannedPageBundleCopyWith<$Res> implements $ScannedPageBundleCopyWith<$Res> {
  factory _$ScannedPageBundleCopyWith(_ScannedPageBundle value, $Res Function(_ScannedPageBundle) _then) = __$ScannedPageBundleCopyWithImpl;
@override @useResult
$Res call({
 List<PageRef> pages, PageSource source, String? suggestedTitle
});




}
/// @nodoc
class __$ScannedPageBundleCopyWithImpl<$Res>
    implements _$ScannedPageBundleCopyWith<$Res> {
  __$ScannedPageBundleCopyWithImpl(this._self, this._then);

  final _ScannedPageBundle _self;
  final $Res Function(_ScannedPageBundle) _then;

/// Create a copy of ScannedPageBundle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pages = null,Object? source = null,Object? suggestedTitle = freezed,}) {
  return _then(_ScannedPageBundle(
pages: null == pages ? _self._pages : pages // ignore: cast_nullable_to_non_nullable
as List<PageRef>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as PageSource,suggestedTitle: freezed == suggestedTitle ? _self.suggestedTitle : suggestedTitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
