// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'compression_candidate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompressionDraft {

 String get sourceDocumentId; int get pageCount; int get originalBytes; PageQualityPlan get qualityPlan; CompressionDestination? get destination;
/// Create a copy of CompressionDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompressionDraftCopyWith<CompressionDraft> get copyWith => _$CompressionDraftCopyWithImpl<CompressionDraft>(this as CompressionDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompressionDraft&&(identical(other.sourceDocumentId, sourceDocumentId) || other.sourceDocumentId == sourceDocumentId)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.originalBytes, originalBytes) || other.originalBytes == originalBytes)&&(identical(other.qualityPlan, qualityPlan) || other.qualityPlan == qualityPlan)&&(identical(other.destination, destination) || other.destination == destination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sourceDocumentId,pageCount,originalBytes,qualityPlan,destination);

@override
String toString() {
  return 'CompressionDraft(sourceDocumentId: $sourceDocumentId, pageCount: $pageCount, originalBytes: $originalBytes, qualityPlan: $qualityPlan, destination: $destination)';
}


}

/// @nodoc
abstract mixin class $CompressionDraftCopyWith<$Res>  {
  factory $CompressionDraftCopyWith(CompressionDraft value, $Res Function(CompressionDraft) _then) = _$CompressionDraftCopyWithImpl;
@useResult
$Res call({
 String sourceDocumentId, int pageCount, int originalBytes, PageQualityPlan qualityPlan, CompressionDestination? destination
});




}
/// @nodoc
class _$CompressionDraftCopyWithImpl<$Res>
    implements $CompressionDraftCopyWith<$Res> {
  _$CompressionDraftCopyWithImpl(this._self, this._then);

  final CompressionDraft _self;
  final $Res Function(CompressionDraft) _then;

/// Create a copy of CompressionDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceDocumentId = null,Object? pageCount = null,Object? originalBytes = null,Object? qualityPlan = null,Object? destination = freezed,}) {
  return _then(CompressionDraft(
sourceDocumentId: null == sourceDocumentId ? _self.sourceDocumentId : sourceDocumentId // ignore: cast_nullable_to_non_nullable
as String,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,originalBytes: null == originalBytes ? _self.originalBytes : originalBytes // ignore: cast_nullable_to_non_nullable
as int,qualityPlan: null == qualityPlan ? _self.qualityPlan : qualityPlan // ignore: cast_nullable_to_non_nullable
as PageQualityPlan,destination: freezed == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as CompressionDestination?,
  ));
}

}


/// Adds pattern-matching-related methods to [CompressionDraft].
extension CompressionDraftPatterns on CompressionDraft {
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
mixin _$CompressionCommitResult {

 String get documentId; CompressionDestination get destination; int get originalBytes; int get resultBytes;
/// Create a copy of CompressionCommitResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompressionCommitResultCopyWith<CompressionCommitResult> get copyWith => _$CompressionCommitResultCopyWithImpl<CompressionCommitResult>(this as CompressionCommitResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompressionCommitResult&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.originalBytes, originalBytes) || other.originalBytes == originalBytes)&&(identical(other.resultBytes, resultBytes) || other.resultBytes == resultBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,destination,originalBytes,resultBytes);

@override
String toString() {
  return 'CompressionCommitResult(documentId: $documentId, destination: $destination, originalBytes: $originalBytes, resultBytes: $resultBytes)';
}


}

/// @nodoc
abstract mixin class $CompressionCommitResultCopyWith<$Res>  {
  factory $CompressionCommitResultCopyWith(CompressionCommitResult value, $Res Function(CompressionCommitResult) _then) = _$CompressionCommitResultCopyWithImpl;
@useResult
$Res call({
 String documentId, CompressionDestination destination, int originalBytes, int resultBytes
});




}
/// @nodoc
class _$CompressionCommitResultCopyWithImpl<$Res>
    implements $CompressionCommitResultCopyWith<$Res> {
  _$CompressionCommitResultCopyWithImpl(this._self, this._then);

  final CompressionCommitResult _self;
  final $Res Function(CompressionCommitResult) _then;

/// Create a copy of CompressionCommitResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? destination = null,Object? originalBytes = null,Object? resultBytes = null,}) {
  return _then(CompressionCommitResult(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as CompressionDestination,originalBytes: null == originalBytes ? _self.originalBytes : originalBytes // ignore: cast_nullable_to_non_nullable
as int,resultBytes: null == resultBytes ? _self.resultBytes : resultBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CompressionCommitResult].
extension CompressionCommitResultPatterns on CompressionCommitResult {
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

// dart format on
