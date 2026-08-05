// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pdf_operation_workflow.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PdfOperationDraft {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfOperationDraft);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PdfOperationDraft()';
}


}

/// @nodoc
class $PdfOperationDraftCopyWith<$Res>  {
$PdfOperationDraftCopyWith(PdfOperationDraft _, $Res Function(PdfOperationDraft) __);
}


/// Adds pattern-matching-related methods to [PdfOperationDraft].
extension PdfOperationDraftPatterns on PdfOperationDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PdfSplitDraft value)?  split,TResult Function( PdfMergeDraft value)?  merge,TResult Function( PdfCompressDraft value)?  compress,TResult Function( PdfWatermarkDraft value)?  watermark,TResult Function( PdfProtectionDraft value)?  protection,TResult Function( PdfPagesDraft value)?  pages,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PdfSplitDraft() when split != null:
return split(_that);case PdfMergeDraft() when merge != null:
return merge(_that);case PdfCompressDraft() when compress != null:
return compress(_that);case PdfWatermarkDraft() when watermark != null:
return watermark(_that);case PdfProtectionDraft() when protection != null:
return protection(_that);case PdfPagesDraft() when pages != null:
return pages(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PdfSplitDraft value)  split,required TResult Function( PdfMergeDraft value)  merge,required TResult Function( PdfCompressDraft value)  compress,required TResult Function( PdfWatermarkDraft value)  watermark,required TResult Function( PdfProtectionDraft value)  protection,required TResult Function( PdfPagesDraft value)  pages,}){
final _that = this;
switch (_that) {
case PdfSplitDraft():
return split(_that);case PdfMergeDraft():
return merge(_that);case PdfCompressDraft():
return compress(_that);case PdfWatermarkDraft():
return watermark(_that);case PdfProtectionDraft():
return protection(_that);case PdfPagesDraft():
return pages(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PdfSplitDraft value)?  split,TResult? Function( PdfMergeDraft value)?  merge,TResult? Function( PdfCompressDraft value)?  compress,TResult? Function( PdfWatermarkDraft value)?  watermark,TResult? Function( PdfProtectionDraft value)?  protection,TResult? Function( PdfPagesDraft value)?  pages,}){
final _that = this;
switch (_that) {
case PdfSplitDraft() when split != null:
return split(_that);case PdfMergeDraft() when merge != null:
return merge(_that);case PdfCompressDraft() when compress != null:
return compress(_that);case PdfWatermarkDraft() when watermark != null:
return watermark(_that);case PdfProtectionDraft() when protection != null:
return protection(_that);case PdfPagesDraft() when pages != null:
return pages(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int boundary,  String firstTitle,  String secondTitle)?  split,TResult Function( List<DocumentId> documentIds,  String outputTitle)?  merge,TResult Function( PdfSourceEffect sourceEffect)?  compress,TResult Function( String text)?  watermark,TResult Function( bool remove,  PdfSourceEffect sourceEffect)?  protection,TResult Function( PdfEditOperation operation,  List<int> pageIndices,  PdfSourceEffect sourceEffect)?  pages,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PdfSplitDraft() when split != null:
return split(_that.boundary,_that.firstTitle,_that.secondTitle);case PdfMergeDraft() when merge != null:
return merge(_that.documentIds,_that.outputTitle);case PdfCompressDraft() when compress != null:
return compress(_that.sourceEffect);case PdfWatermarkDraft() when watermark != null:
return watermark(_that.text);case PdfProtectionDraft() when protection != null:
return protection(_that.remove,_that.sourceEffect);case PdfPagesDraft() when pages != null:
return pages(_that.operation,_that.pageIndices,_that.sourceEffect);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int boundary,  String firstTitle,  String secondTitle)  split,required TResult Function( List<DocumentId> documentIds,  String outputTitle)  merge,required TResult Function( PdfSourceEffect sourceEffect)  compress,required TResult Function( String text)  watermark,required TResult Function( bool remove,  PdfSourceEffect sourceEffect)  protection,required TResult Function( PdfEditOperation operation,  List<int> pageIndices,  PdfSourceEffect sourceEffect)  pages,}) {final _that = this;
switch (_that) {
case PdfSplitDraft():
return split(_that.boundary,_that.firstTitle,_that.secondTitle);case PdfMergeDraft():
return merge(_that.documentIds,_that.outputTitle);case PdfCompressDraft():
return compress(_that.sourceEffect);case PdfWatermarkDraft():
return watermark(_that.text);case PdfProtectionDraft():
return protection(_that.remove,_that.sourceEffect);case PdfPagesDraft():
return pages(_that.operation,_that.pageIndices,_that.sourceEffect);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int boundary,  String firstTitle,  String secondTitle)?  split,TResult? Function( List<DocumentId> documentIds,  String outputTitle)?  merge,TResult? Function( PdfSourceEffect sourceEffect)?  compress,TResult? Function( String text)?  watermark,TResult? Function( bool remove,  PdfSourceEffect sourceEffect)?  protection,TResult? Function( PdfEditOperation operation,  List<int> pageIndices,  PdfSourceEffect sourceEffect)?  pages,}) {final _that = this;
switch (_that) {
case PdfSplitDraft() when split != null:
return split(_that.boundary,_that.firstTitle,_that.secondTitle);case PdfMergeDraft() when merge != null:
return merge(_that.documentIds,_that.outputTitle);case PdfCompressDraft() when compress != null:
return compress(_that.sourceEffect);case PdfWatermarkDraft() when watermark != null:
return watermark(_that.text);case PdfProtectionDraft() when protection != null:
return protection(_that.remove,_that.sourceEffect);case PdfPagesDraft() when pages != null:
return pages(_that.operation,_that.pageIndices,_that.sourceEffect);case _:
  return null;

}
}

}

/// @nodoc


class PdfSplitDraft implements PdfOperationDraft {
  const PdfSplitDraft({required this.boundary, required this.firstTitle, required this.secondTitle});
  

 final  int boundary;
 final  String firstTitle;
 final  String secondTitle;

/// Create a copy of PdfOperationDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfSplitDraftCopyWith<PdfSplitDraft> get copyWith => _$PdfSplitDraftCopyWithImpl<PdfSplitDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfSplitDraft&&(identical(other.boundary, boundary) || other.boundary == boundary)&&(identical(other.firstTitle, firstTitle) || other.firstTitle == firstTitle)&&(identical(other.secondTitle, secondTitle) || other.secondTitle == secondTitle));
}


@override
int get hashCode => Object.hash(runtimeType,boundary,firstTitle,secondTitle);

@override
String toString() {
  return 'PdfOperationDraft.split(boundary: $boundary, firstTitle: $firstTitle, secondTitle: $secondTitle)';
}


}

/// @nodoc
abstract mixin class $PdfSplitDraftCopyWith<$Res> implements $PdfOperationDraftCopyWith<$Res> {
  factory $PdfSplitDraftCopyWith(PdfSplitDraft value, $Res Function(PdfSplitDraft) _then) = _$PdfSplitDraftCopyWithImpl;
@useResult
$Res call({
 int boundary, String firstTitle, String secondTitle
});




}
/// @nodoc
class _$PdfSplitDraftCopyWithImpl<$Res>
    implements $PdfSplitDraftCopyWith<$Res> {
  _$PdfSplitDraftCopyWithImpl(this._self, this._then);

  final PdfSplitDraft _self;
  final $Res Function(PdfSplitDraft) _then;

/// Create a copy of PdfOperationDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? boundary = null,Object? firstTitle = null,Object? secondTitle = null,}) {
  return _then(PdfSplitDraft(
boundary: null == boundary ? _self.boundary : boundary // ignore: cast_nullable_to_non_nullable
as int,firstTitle: null == firstTitle ? _self.firstTitle : firstTitle // ignore: cast_nullable_to_non_nullable
as String,secondTitle: null == secondTitle ? _self.secondTitle : secondTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PdfMergeDraft implements PdfOperationDraft {
  const PdfMergeDraft({required final  List<DocumentId> documentIds, required this.outputTitle}): _documentIds = documentIds;
  

 final  List<DocumentId> _documentIds;
 List<DocumentId> get documentIds {
  if (_documentIds is EqualUnmodifiableListView) return _documentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documentIds);
}

 final  String outputTitle;

/// Create a copy of PdfOperationDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfMergeDraftCopyWith<PdfMergeDraft> get copyWith => _$PdfMergeDraftCopyWithImpl<PdfMergeDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfMergeDraft&&const DeepCollectionEquality().equals(other._documentIds, _documentIds)&&(identical(other.outputTitle, outputTitle) || other.outputTitle == outputTitle));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_documentIds),outputTitle);

@override
String toString() {
  return 'PdfOperationDraft.merge(documentIds: $documentIds, outputTitle: $outputTitle)';
}


}

/// @nodoc
abstract mixin class $PdfMergeDraftCopyWith<$Res> implements $PdfOperationDraftCopyWith<$Res> {
  factory $PdfMergeDraftCopyWith(PdfMergeDraft value, $Res Function(PdfMergeDraft) _then) = _$PdfMergeDraftCopyWithImpl;
@useResult
$Res call({
 List<DocumentId> documentIds, String outputTitle
});




}
/// @nodoc
class _$PdfMergeDraftCopyWithImpl<$Res>
    implements $PdfMergeDraftCopyWith<$Res> {
  _$PdfMergeDraftCopyWithImpl(this._self, this._then);

  final PdfMergeDraft _self;
  final $Res Function(PdfMergeDraft) _then;

/// Create a copy of PdfOperationDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? documentIds = null,Object? outputTitle = null,}) {
  return _then(PdfMergeDraft(
documentIds: null == documentIds ? _self._documentIds : documentIds // ignore: cast_nullable_to_non_nullable
as List<DocumentId>,outputTitle: null == outputTitle ? _self.outputTitle : outputTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PdfCompressDraft implements PdfOperationDraft {
  const PdfCompressDraft({this.sourceEffect = PdfSourceEffect.replace});
  

@JsonKey() final  PdfSourceEffect sourceEffect;

/// Create a copy of PdfOperationDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfCompressDraftCopyWith<PdfCompressDraft> get copyWith => _$PdfCompressDraftCopyWithImpl<PdfCompressDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfCompressDraft&&(identical(other.sourceEffect, sourceEffect) || other.sourceEffect == sourceEffect));
}


@override
int get hashCode => Object.hash(runtimeType,sourceEffect);

@override
String toString() {
  return 'PdfOperationDraft.compress(sourceEffect: $sourceEffect)';
}


}

/// @nodoc
abstract mixin class $PdfCompressDraftCopyWith<$Res> implements $PdfOperationDraftCopyWith<$Res> {
  factory $PdfCompressDraftCopyWith(PdfCompressDraft value, $Res Function(PdfCompressDraft) _then) = _$PdfCompressDraftCopyWithImpl;
@useResult
$Res call({
 PdfSourceEffect sourceEffect
});




}
/// @nodoc
class _$PdfCompressDraftCopyWithImpl<$Res>
    implements $PdfCompressDraftCopyWith<$Res> {
  _$PdfCompressDraftCopyWithImpl(this._self, this._then);

  final PdfCompressDraft _self;
  final $Res Function(PdfCompressDraft) _then;

/// Create a copy of PdfOperationDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sourceEffect = null,}) {
  return _then(PdfCompressDraft(
sourceEffect: null == sourceEffect ? _self.sourceEffect : sourceEffect // ignore: cast_nullable_to_non_nullable
as PdfSourceEffect,
  ));
}


}

/// @nodoc


class PdfWatermarkDraft implements PdfOperationDraft {
  const PdfWatermarkDraft({required this.text});
  

 final  String text;

/// Create a copy of PdfOperationDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfWatermarkDraftCopyWith<PdfWatermarkDraft> get copyWith => _$PdfWatermarkDraftCopyWithImpl<PdfWatermarkDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfWatermarkDraft&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'PdfOperationDraft.watermark(text: $text)';
}


}

/// @nodoc
abstract mixin class $PdfWatermarkDraftCopyWith<$Res> implements $PdfOperationDraftCopyWith<$Res> {
  factory $PdfWatermarkDraftCopyWith(PdfWatermarkDraft value, $Res Function(PdfWatermarkDraft) _then) = _$PdfWatermarkDraftCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$PdfWatermarkDraftCopyWithImpl<$Res>
    implements $PdfWatermarkDraftCopyWith<$Res> {
  _$PdfWatermarkDraftCopyWithImpl(this._self, this._then);

  final PdfWatermarkDraft _self;
  final $Res Function(PdfWatermarkDraft) _then;

/// Create a copy of PdfOperationDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(PdfWatermarkDraft(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PdfProtectionDraft implements PdfOperationDraft {
  const PdfProtectionDraft({required this.remove, this.sourceEffect = PdfSourceEffect.replace});
  

 final  bool remove;
@JsonKey() final  PdfSourceEffect sourceEffect;

/// Create a copy of PdfOperationDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfProtectionDraftCopyWith<PdfProtectionDraft> get copyWith => _$PdfProtectionDraftCopyWithImpl<PdfProtectionDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfProtectionDraft&&(identical(other.remove, remove) || other.remove == remove)&&(identical(other.sourceEffect, sourceEffect) || other.sourceEffect == sourceEffect));
}


@override
int get hashCode => Object.hash(runtimeType,remove,sourceEffect);

@override
String toString() {
  return 'PdfOperationDraft.protection(remove: $remove, sourceEffect: $sourceEffect)';
}


}

/// @nodoc
abstract mixin class $PdfProtectionDraftCopyWith<$Res> implements $PdfOperationDraftCopyWith<$Res> {
  factory $PdfProtectionDraftCopyWith(PdfProtectionDraft value, $Res Function(PdfProtectionDraft) _then) = _$PdfProtectionDraftCopyWithImpl;
@useResult
$Res call({
 bool remove, PdfSourceEffect sourceEffect
});




}
/// @nodoc
class _$PdfProtectionDraftCopyWithImpl<$Res>
    implements $PdfProtectionDraftCopyWith<$Res> {
  _$PdfProtectionDraftCopyWithImpl(this._self, this._then);

  final PdfProtectionDraft _self;
  final $Res Function(PdfProtectionDraft) _then;

/// Create a copy of PdfOperationDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? remove = null,Object? sourceEffect = null,}) {
  return _then(PdfProtectionDraft(
remove: null == remove ? _self.remove : remove // ignore: cast_nullable_to_non_nullable
as bool,sourceEffect: null == sourceEffect ? _self.sourceEffect : sourceEffect // ignore: cast_nullable_to_non_nullable
as PdfSourceEffect,
  ));
}


}

/// @nodoc


class PdfPagesDraft implements PdfOperationDraft {
  const PdfPagesDraft({required this.operation, required final  List<int> pageIndices, required this.sourceEffect}): _pageIndices = pageIndices;
  

 final  PdfEditOperation operation;
 final  List<int> _pageIndices;
 List<int> get pageIndices {
  if (_pageIndices is EqualUnmodifiableListView) return _pageIndices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pageIndices);
}

 final  PdfSourceEffect sourceEffect;

/// Create a copy of PdfOperationDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfPagesDraftCopyWith<PdfPagesDraft> get copyWith => _$PdfPagesDraftCopyWithImpl<PdfPagesDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfPagesDraft&&(identical(other.operation, operation) || other.operation == operation)&&const DeepCollectionEquality().equals(other._pageIndices, _pageIndices)&&(identical(other.sourceEffect, sourceEffect) || other.sourceEffect == sourceEffect));
}


@override
int get hashCode => Object.hash(runtimeType,operation,const DeepCollectionEquality().hash(_pageIndices),sourceEffect);

@override
String toString() {
  return 'PdfOperationDraft.pages(operation: $operation, pageIndices: $pageIndices, sourceEffect: $sourceEffect)';
}


}

/// @nodoc
abstract mixin class $PdfPagesDraftCopyWith<$Res> implements $PdfOperationDraftCopyWith<$Res> {
  factory $PdfPagesDraftCopyWith(PdfPagesDraft value, $Res Function(PdfPagesDraft) _then) = _$PdfPagesDraftCopyWithImpl;
@useResult
$Res call({
 PdfEditOperation operation, List<int> pageIndices, PdfSourceEffect sourceEffect
});




}
/// @nodoc
class _$PdfPagesDraftCopyWithImpl<$Res>
    implements $PdfPagesDraftCopyWith<$Res> {
  _$PdfPagesDraftCopyWithImpl(this._self, this._then);

  final PdfPagesDraft _self;
  final $Res Function(PdfPagesDraft) _then;

/// Create a copy of PdfOperationDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? pageIndices = null,Object? sourceEffect = null,}) {
  return _then(PdfPagesDraft(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as PdfEditOperation,pageIndices: null == pageIndices ? _self._pageIndices : pageIndices // ignore: cast_nullable_to_non_nullable
as List<int>,sourceEffect: null == sourceEffect ? _self.sourceEffect : sourceEffect // ignore: cast_nullable_to_non_nullable
as PdfSourceEffect,
  ));
}


}

/// @nodoc
mixin _$PdfOperationReview {

 PdfOperationDraft get draft; String get title; String get summary; String get confirmLabel;
/// Create a copy of PdfOperationReview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfOperationReviewCopyWith<PdfOperationReview> get copyWith => _$PdfOperationReviewCopyWithImpl<PdfOperationReview>(this as PdfOperationReview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfOperationReview&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.confirmLabel, confirmLabel) || other.confirmLabel == confirmLabel));
}


@override
int get hashCode => Object.hash(runtimeType,draft,title,summary,confirmLabel);

@override
String toString() {
  return 'PdfOperationReview(draft: $draft, title: $title, summary: $summary, confirmLabel: $confirmLabel)';
}


}

/// @nodoc
abstract mixin class $PdfOperationReviewCopyWith<$Res>  {
  factory $PdfOperationReviewCopyWith(PdfOperationReview value, $Res Function(PdfOperationReview) _then) = _$PdfOperationReviewCopyWithImpl;
@useResult
$Res call({
 PdfOperationDraft draft, String title, String summary, String confirmLabel
});


$PdfOperationDraftCopyWith<$Res> get draft;

}
/// @nodoc
class _$PdfOperationReviewCopyWithImpl<$Res>
    implements $PdfOperationReviewCopyWith<$Res> {
  _$PdfOperationReviewCopyWithImpl(this._self, this._then);

  final PdfOperationReview _self;
  final $Res Function(PdfOperationReview) _then;

/// Create a copy of PdfOperationReview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? draft = null,Object? title = null,Object? summary = null,Object? confirmLabel = null,}) {
  return _then(_self.copyWith(
draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as PdfOperationDraft,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,confirmLabel: null == confirmLabel ? _self.confirmLabel : confirmLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of PdfOperationReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PdfOperationDraftCopyWith<$Res> get draft {
  
  return $PdfOperationDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}


/// Adds pattern-matching-related methods to [PdfOperationReview].
extension PdfOperationReviewPatterns on PdfOperationReview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PdfOperationReview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PdfOperationReview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PdfOperationReview value)  $default,){
final _that = this;
switch (_that) {
case _PdfOperationReview():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PdfOperationReview value)?  $default,){
final _that = this;
switch (_that) {
case _PdfOperationReview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PdfOperationDraft draft,  String title,  String summary,  String confirmLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PdfOperationReview() when $default != null:
return $default(_that.draft,_that.title,_that.summary,_that.confirmLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PdfOperationDraft draft,  String title,  String summary,  String confirmLabel)  $default,) {final _that = this;
switch (_that) {
case _PdfOperationReview():
return $default(_that.draft,_that.title,_that.summary,_that.confirmLabel);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PdfOperationDraft draft,  String title,  String summary,  String confirmLabel)?  $default,) {final _that = this;
switch (_that) {
case _PdfOperationReview() when $default != null:
return $default(_that.draft,_that.title,_that.summary,_that.confirmLabel);case _:
  return null;

}
}

}

/// @nodoc


class _PdfOperationReview implements PdfOperationReview {
  const _PdfOperationReview({required this.draft, required this.title, required this.summary, required this.confirmLabel});
  

@override final  PdfOperationDraft draft;
@override final  String title;
@override final  String summary;
@override final  String confirmLabel;

/// Create a copy of PdfOperationReview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PdfOperationReviewCopyWith<_PdfOperationReview> get copyWith => __$PdfOperationReviewCopyWithImpl<_PdfOperationReview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PdfOperationReview&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.confirmLabel, confirmLabel) || other.confirmLabel == confirmLabel));
}


@override
int get hashCode => Object.hash(runtimeType,draft,title,summary,confirmLabel);

@override
String toString() {
  return 'PdfOperationReview(draft: $draft, title: $title, summary: $summary, confirmLabel: $confirmLabel)';
}


}

/// @nodoc
abstract mixin class _$PdfOperationReviewCopyWith<$Res> implements $PdfOperationReviewCopyWith<$Res> {
  factory _$PdfOperationReviewCopyWith(_PdfOperationReview value, $Res Function(_PdfOperationReview) _then) = __$PdfOperationReviewCopyWithImpl;
@override @useResult
$Res call({
 PdfOperationDraft draft, String title, String summary, String confirmLabel
});


@override $PdfOperationDraftCopyWith<$Res> get draft;

}
/// @nodoc
class __$PdfOperationReviewCopyWithImpl<$Res>
    implements _$PdfOperationReviewCopyWith<$Res> {
  __$PdfOperationReviewCopyWithImpl(this._self, this._then);

  final _PdfOperationReview _self;
  final $Res Function(_PdfOperationReview) _then;

/// Create a copy of PdfOperationReview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,Object? title = null,Object? summary = null,Object? confirmLabel = null,}) {
  return _then(_PdfOperationReview(
draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as PdfOperationDraft,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,confirmLabel: null == confirmLabel ? _self.confirmLabel : confirmLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of PdfOperationReview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PdfOperationDraftCopyWith<$Res> get draft {
  
  return $PdfOperationDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}

/// @nodoc
mixin _$PdfOperationResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfOperationResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PdfOperationResult()';
}


}

/// @nodoc
class $PdfOperationResultCopyWith<$Res>  {
$PdfOperationResultCopyWith(PdfOperationResult _, $Res Function(PdfOperationResult) __);
}


/// Adds pattern-matching-related methods to [PdfOperationResult].
extension PdfOperationResultPatterns on PdfOperationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PdfInPlaceOperationResult value)?  inPlace,TResult Function( PdfDerivedOperationResult value)?  derived,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PdfInPlaceOperationResult() when inPlace != null:
return inPlace(_that);case PdfDerivedOperationResult() when derived != null:
return derived(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PdfInPlaceOperationResult value)  inPlace,required TResult Function( PdfDerivedOperationResult value)  derived,}){
final _that = this;
switch (_that) {
case PdfInPlaceOperationResult():
return inPlace(_that);case PdfDerivedOperationResult():
return derived(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PdfInPlaceOperationResult value)?  inPlace,TResult? Function( PdfDerivedOperationResult value)?  derived,}){
final _that = this;
switch (_that) {
case PdfInPlaceOperationResult() when inPlace != null:
return inPlace(_that);case PdfDerivedOperationResult() when derived != null:
return derived(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Document document,  String? message)?  inPlace,TResult Function( List<Document> documents)?  derived,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PdfInPlaceOperationResult() when inPlace != null:
return inPlace(_that.document,_that.message);case PdfDerivedOperationResult() when derived != null:
return derived(_that.documents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Document document,  String? message)  inPlace,required TResult Function( List<Document> documents)  derived,}) {final _that = this;
switch (_that) {
case PdfInPlaceOperationResult():
return inPlace(_that.document,_that.message);case PdfDerivedOperationResult():
return derived(_that.documents);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Document document,  String? message)?  inPlace,TResult? Function( List<Document> documents)?  derived,}) {final _that = this;
switch (_that) {
case PdfInPlaceOperationResult() when inPlace != null:
return inPlace(_that.document,_that.message);case PdfDerivedOperationResult() when derived != null:
return derived(_that.documents);case _:
  return null;

}
}

}

/// @nodoc


class PdfInPlaceOperationResult implements PdfOperationResult {
  const PdfInPlaceOperationResult({required this.document, this.message});
  

 final  Document document;
 final  String? message;

/// Create a copy of PdfOperationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfInPlaceOperationResultCopyWith<PdfInPlaceOperationResult> get copyWith => _$PdfInPlaceOperationResultCopyWithImpl<PdfInPlaceOperationResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfInPlaceOperationResult&&(identical(other.document, document) || other.document == document)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,document,message);

@override
String toString() {
  return 'PdfOperationResult.inPlace(document: $document, message: $message)';
}


}

/// @nodoc
abstract mixin class $PdfInPlaceOperationResultCopyWith<$Res> implements $PdfOperationResultCopyWith<$Res> {
  factory $PdfInPlaceOperationResultCopyWith(PdfInPlaceOperationResult value, $Res Function(PdfInPlaceOperationResult) _then) = _$PdfInPlaceOperationResultCopyWithImpl;
@useResult
$Res call({
 Document document, String? message
});


$DocumentCopyWith<$Res> get document;

}
/// @nodoc
class _$PdfInPlaceOperationResultCopyWithImpl<$Res>
    implements $PdfInPlaceOperationResultCopyWith<$Res> {
  _$PdfInPlaceOperationResultCopyWithImpl(this._self, this._then);

  final PdfInPlaceOperationResult _self;
  final $Res Function(PdfInPlaceOperationResult) _then;

/// Create a copy of PdfOperationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? document = null,Object? message = freezed,}) {
  return _then(PdfInPlaceOperationResult(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as Document,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PdfOperationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentCopyWith<$Res> get document {
  
  return $DocumentCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}

/// @nodoc


class PdfDerivedOperationResult implements PdfOperationResult {
  const PdfDerivedOperationResult({required final  List<Document> documents}): _documents = documents;
  

 final  List<Document> _documents;
 List<Document> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}


/// Create a copy of PdfOperationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PdfDerivedOperationResultCopyWith<PdfDerivedOperationResult> get copyWith => _$PdfDerivedOperationResultCopyWithImpl<PdfDerivedOperationResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfDerivedOperationResult&&const DeepCollectionEquality().equals(other._documents, _documents));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_documents));

@override
String toString() {
  return 'PdfOperationResult.derived(documents: $documents)';
}


}

/// @nodoc
abstract mixin class $PdfDerivedOperationResultCopyWith<$Res> implements $PdfOperationResultCopyWith<$Res> {
  factory $PdfDerivedOperationResultCopyWith(PdfDerivedOperationResult value, $Res Function(PdfDerivedOperationResult) _then) = _$PdfDerivedOperationResultCopyWithImpl;
@useResult
$Res call({
 List<Document> documents
});




}
/// @nodoc
class _$PdfDerivedOperationResultCopyWithImpl<$Res>
    implements $PdfDerivedOperationResultCopyWith<$Res> {
  _$PdfDerivedOperationResultCopyWithImpl(this._self, this._then);

  final PdfDerivedOperationResult _self;
  final $Res Function(PdfDerivedOperationResult) _then;

/// Create a copy of PdfOperationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? documents = null,}) {
  return _then(PdfDerivedOperationResult(
documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,
  ));
}


}

// dart format on
