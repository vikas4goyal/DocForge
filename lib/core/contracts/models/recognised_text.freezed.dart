// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recognised_text.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NormalisedRect {

 double get left; double get top; double get right; double get bottom;
/// Create a copy of NormalisedRect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NormalisedRectCopyWith<NormalisedRect> get copyWith => _$NormalisedRectCopyWithImpl<NormalisedRect>(this as NormalisedRect, _$identity);

  /// Serializes this NormalisedRect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NormalisedRect&&(identical(other.left, left) || other.left == left)&&(identical(other.top, top) || other.top == top)&&(identical(other.right, right) || other.right == right)&&(identical(other.bottom, bottom) || other.bottom == bottom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,left,top,right,bottom);

@override
String toString() {
  return 'NormalisedRect(left: $left, top: $top, right: $right, bottom: $bottom)';
}


}

/// @nodoc
abstract mixin class $NormalisedRectCopyWith<$Res>  {
  factory $NormalisedRectCopyWith(NormalisedRect value, $Res Function(NormalisedRect) _then) = _$NormalisedRectCopyWithImpl;
@useResult
$Res call({
 double left, double top, double right, double bottom
});




}
/// @nodoc
class _$NormalisedRectCopyWithImpl<$Res>
    implements $NormalisedRectCopyWith<$Res> {
  _$NormalisedRectCopyWithImpl(this._self, this._then);

  final NormalisedRect _self;
  final $Res Function(NormalisedRect) _then;

/// Create a copy of NormalisedRect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? left = null,Object? top = null,Object? right = null,Object? bottom = null,}) {
  return _then(_self.copyWith(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as double,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [NormalisedRect].
extension NormalisedRectPatterns on NormalisedRect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NormalisedRect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NormalisedRect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NormalisedRect value)  $default,){
final _that = this;
switch (_that) {
case _NormalisedRect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NormalisedRect value)?  $default,){
final _that = this;
switch (_that) {
case _NormalisedRect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double left,  double top,  double right,  double bottom)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NormalisedRect() when $default != null:
return $default(_that.left,_that.top,_that.right,_that.bottom);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double left,  double top,  double right,  double bottom)  $default,) {final _that = this;
switch (_that) {
case _NormalisedRect():
return $default(_that.left,_that.top,_that.right,_that.bottom);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double left,  double top,  double right,  double bottom)?  $default,) {final _that = this;
switch (_that) {
case _NormalisedRect() when $default != null:
return $default(_that.left,_that.top,_that.right,_that.bottom);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NormalisedRect extends NormalisedRect {
  const _NormalisedRect({required this.left, required this.top, required this.right, required this.bottom}): super._();
  factory _NormalisedRect.fromJson(Map<String, dynamic> json) => _$NormalisedRectFromJson(json);

@override final  double left;
@override final  double top;
@override final  double right;
@override final  double bottom;

/// Create a copy of NormalisedRect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NormalisedRectCopyWith<_NormalisedRect> get copyWith => __$NormalisedRectCopyWithImpl<_NormalisedRect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NormalisedRectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NormalisedRect&&(identical(other.left, left) || other.left == left)&&(identical(other.top, top) || other.top == top)&&(identical(other.right, right) || other.right == right)&&(identical(other.bottom, bottom) || other.bottom == bottom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,left,top,right,bottom);

@override
String toString() {
  return 'NormalisedRect(left: $left, top: $top, right: $right, bottom: $bottom)';
}


}

/// @nodoc
abstract mixin class _$NormalisedRectCopyWith<$Res> implements $NormalisedRectCopyWith<$Res> {
  factory _$NormalisedRectCopyWith(_NormalisedRect value, $Res Function(_NormalisedRect) _then) = __$NormalisedRectCopyWithImpl;
@override @useResult
$Res call({
 double left, double top, double right, double bottom
});




}
/// @nodoc
class __$NormalisedRectCopyWithImpl<$Res>
    implements _$NormalisedRectCopyWith<$Res> {
  __$NormalisedRectCopyWithImpl(this._self, this._then);

  final _NormalisedRect _self;
  final $Res Function(_NormalisedRect) _then;

/// Create a copy of NormalisedRect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? left = null,Object? top = null,Object? right = null,Object? bottom = null,}) {
  return _then(_NormalisedRect(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as double,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$TextBlock {

 String get text; NormalisedRect get bounds;
/// Create a copy of TextBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextBlockCopyWith<TextBlock> get copyWith => _$TextBlockCopyWithImpl<TextBlock>(this as TextBlock, _$identity);

  /// Serializes this TextBlock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextBlock&&(identical(other.text, text) || other.text == text)&&(identical(other.bounds, bounds) || other.bounds == bounds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,bounds);

@override
String toString() {
  return 'TextBlock(text: $text, bounds: $bounds)';
}


}

/// @nodoc
abstract mixin class $TextBlockCopyWith<$Res>  {
  factory $TextBlockCopyWith(TextBlock value, $Res Function(TextBlock) _then) = _$TextBlockCopyWithImpl;
@useResult
$Res call({
 String text, NormalisedRect bounds
});


$NormalisedRectCopyWith<$Res> get bounds;

}
/// @nodoc
class _$TextBlockCopyWithImpl<$Res>
    implements $TextBlockCopyWith<$Res> {
  _$TextBlockCopyWithImpl(this._self, this._then);

  final TextBlock _self;
  final $Res Function(TextBlock) _then;

/// Create a copy of TextBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? bounds = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,bounds: null == bounds ? _self.bounds : bounds // ignore: cast_nullable_to_non_nullable
as NormalisedRect,
  ));
}
/// Create a copy of TextBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NormalisedRectCopyWith<$Res> get bounds {
  
  return $NormalisedRectCopyWith<$Res>(_self.bounds, (value) {
    return _then(_self.copyWith(bounds: value));
  });
}
}


/// Adds pattern-matching-related methods to [TextBlock].
extension TextBlockPatterns on TextBlock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TextBlock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TextBlock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TextBlock value)  $default,){
final _that = this;
switch (_that) {
case _TextBlock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TextBlock value)?  $default,){
final _that = this;
switch (_that) {
case _TextBlock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  NormalisedRect bounds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TextBlock() when $default != null:
return $default(_that.text,_that.bounds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  NormalisedRect bounds)  $default,) {final _that = this;
switch (_that) {
case _TextBlock():
return $default(_that.text,_that.bounds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  NormalisedRect bounds)?  $default,) {final _that = this;
switch (_that) {
case _TextBlock() when $default != null:
return $default(_that.text,_that.bounds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TextBlock extends TextBlock {
  const _TextBlock({required this.text, required this.bounds}): super._();
  factory _TextBlock.fromJson(Map<String, dynamic> json) => _$TextBlockFromJson(json);

@override final  String text;
@override final  NormalisedRect bounds;

/// Create a copy of TextBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TextBlockCopyWith<_TextBlock> get copyWith => __$TextBlockCopyWithImpl<_TextBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TextBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TextBlock&&(identical(other.text, text) || other.text == text)&&(identical(other.bounds, bounds) || other.bounds == bounds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,bounds);

@override
String toString() {
  return 'TextBlock(text: $text, bounds: $bounds)';
}


}

/// @nodoc
abstract mixin class _$TextBlockCopyWith<$Res> implements $TextBlockCopyWith<$Res> {
  factory _$TextBlockCopyWith(_TextBlock value, $Res Function(_TextBlock) _then) = __$TextBlockCopyWithImpl;
@override @useResult
$Res call({
 String text, NormalisedRect bounds
});


@override $NormalisedRectCopyWith<$Res> get bounds;

}
/// @nodoc
class __$TextBlockCopyWithImpl<$Res>
    implements _$TextBlockCopyWith<$Res> {
  __$TextBlockCopyWithImpl(this._self, this._then);

  final _TextBlock _self;
  final $Res Function(_TextBlock) _then;

/// Create a copy of TextBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? bounds = null,}) {
  return _then(_TextBlock(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,bounds: null == bounds ? _self.bounds : bounds // ignore: cast_nullable_to_non_nullable
as NormalisedRect,
  ));
}

/// Create a copy of TextBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NormalisedRectCopyWith<$Res> get bounds {
  
  return $NormalisedRectCopyWith<$Res>(_self.bounds, (value) {
    return _then(_self.copyWith(bounds: value));
  });
}
}


/// @nodoc
mixin _$RecognisedText {

 PageId get pageId; List<TextBlock> get blocks;/// BCP-47 tag of the language recognition ran with.
 String get languageTag;/// When recognition ran, so a re-run can be distinguished from a cached
/// result.
 DateTime get recognisedAt;
/// Create a copy of RecognisedText
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecognisedTextCopyWith<RecognisedText> get copyWith => _$RecognisedTextCopyWithImpl<RecognisedText>(this as RecognisedText, _$identity);

  /// Serializes this RecognisedText to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecognisedText&&(identical(other.pageId, pageId) || other.pageId == pageId)&&const DeepCollectionEquality().equals(other.blocks, blocks)&&(identical(other.languageTag, languageTag) || other.languageTag == languageTag)&&(identical(other.recognisedAt, recognisedAt) || other.recognisedAt == recognisedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pageId,const DeepCollectionEquality().hash(blocks),languageTag,recognisedAt);

@override
String toString() {
  return 'RecognisedText(pageId: $pageId, blocks: $blocks, languageTag: $languageTag, recognisedAt: $recognisedAt)';
}


}

/// @nodoc
abstract mixin class $RecognisedTextCopyWith<$Res>  {
  factory $RecognisedTextCopyWith(RecognisedText value, $Res Function(RecognisedText) _then) = _$RecognisedTextCopyWithImpl;
@useResult
$Res call({
 PageId pageId, List<TextBlock> blocks, String languageTag, DateTime recognisedAt
});




}
/// @nodoc
class _$RecognisedTextCopyWithImpl<$Res>
    implements $RecognisedTextCopyWith<$Res> {
  _$RecognisedTextCopyWithImpl(this._self, this._then);

  final RecognisedText _self;
  final $Res Function(RecognisedText) _then;

/// Create a copy of RecognisedText
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pageId = null,Object? blocks = null,Object? languageTag = null,Object? recognisedAt = null,}) {
  return _then(_self.copyWith(
pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as PageId,blocks: null == blocks ? _self.blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<TextBlock>,languageTag: null == languageTag ? _self.languageTag : languageTag // ignore: cast_nullable_to_non_nullable
as String,recognisedAt: null == recognisedAt ? _self.recognisedAt : recognisedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RecognisedText].
extension RecognisedTextPatterns on RecognisedText {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecognisedText value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecognisedText() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecognisedText value)  $default,){
final _that = this;
switch (_that) {
case _RecognisedText():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecognisedText value)?  $default,){
final _that = this;
switch (_that) {
case _RecognisedText() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PageId pageId,  List<TextBlock> blocks,  String languageTag,  DateTime recognisedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecognisedText() when $default != null:
return $default(_that.pageId,_that.blocks,_that.languageTag,_that.recognisedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PageId pageId,  List<TextBlock> blocks,  String languageTag,  DateTime recognisedAt)  $default,) {final _that = this;
switch (_that) {
case _RecognisedText():
return $default(_that.pageId,_that.blocks,_that.languageTag,_that.recognisedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PageId pageId,  List<TextBlock> blocks,  String languageTag,  DateTime recognisedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecognisedText() when $default != null:
return $default(_that.pageId,_that.blocks,_that.languageTag,_that.recognisedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecognisedText extends RecognisedText {
  const _RecognisedText({required this.pageId, final  List<TextBlock> blocks = const <TextBlock>[], required this.languageTag, required this.recognisedAt}): _blocks = blocks,super._();
  factory _RecognisedText.fromJson(Map<String, dynamic> json) => _$RecognisedTextFromJson(json);

@override final  PageId pageId;
 final  List<TextBlock> _blocks;
@override@JsonKey() List<TextBlock> get blocks {
  if (_blocks is EqualUnmodifiableListView) return _blocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blocks);
}

/// BCP-47 tag of the language recognition ran with.
@override final  String languageTag;
/// When recognition ran, so a re-run can be distinguished from a cached
/// result.
@override final  DateTime recognisedAt;

/// Create a copy of RecognisedText
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecognisedTextCopyWith<_RecognisedText> get copyWith => __$RecognisedTextCopyWithImpl<_RecognisedText>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecognisedTextToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecognisedText&&(identical(other.pageId, pageId) || other.pageId == pageId)&&const DeepCollectionEquality().equals(other._blocks, _blocks)&&(identical(other.languageTag, languageTag) || other.languageTag == languageTag)&&(identical(other.recognisedAt, recognisedAt) || other.recognisedAt == recognisedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pageId,const DeepCollectionEquality().hash(_blocks),languageTag,recognisedAt);

@override
String toString() {
  return 'RecognisedText(pageId: $pageId, blocks: $blocks, languageTag: $languageTag, recognisedAt: $recognisedAt)';
}


}

/// @nodoc
abstract mixin class _$RecognisedTextCopyWith<$Res> implements $RecognisedTextCopyWith<$Res> {
  factory _$RecognisedTextCopyWith(_RecognisedText value, $Res Function(_RecognisedText) _then) = __$RecognisedTextCopyWithImpl;
@override @useResult
$Res call({
 PageId pageId, List<TextBlock> blocks, String languageTag, DateTime recognisedAt
});




}
/// @nodoc
class __$RecognisedTextCopyWithImpl<$Res>
    implements _$RecognisedTextCopyWith<$Res> {
  __$RecognisedTextCopyWithImpl(this._self, this._then);

  final _RecognisedText _self;
  final $Res Function(_RecognisedText) _then;

/// Create a copy of RecognisedText
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pageId = null,Object? blocks = null,Object? languageTag = null,Object? recognisedAt = null,}) {
  return _then(_RecognisedText(
pageId: null == pageId ? _self.pageId : pageId // ignore: cast_nullable_to_non_nullable
as PageId,blocks: null == blocks ? _self._blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<TextBlock>,languageTag: null == languageTag ? _self.languageTag : languageTag // ignore: cast_nullable_to_non_nullable
as String,recognisedAt: null == recognisedAt ? _self.recognisedAt : recognisedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
