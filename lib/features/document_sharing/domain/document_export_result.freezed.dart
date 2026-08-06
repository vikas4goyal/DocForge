// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_export_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DocumentExportResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentExportResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DocumentExportResult()';
}


}

/// @nodoc
class $DocumentExportResultCopyWith<$Res>  {
$DocumentExportResultCopyWith(DocumentExportResult _, $Res Function(DocumentExportResult) __);
}


/// Adds pattern-matching-related methods to [DocumentExportResult].
extension DocumentExportResultPatterns on DocumentExportResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DocumentExportCompleted value)?  completed,TResult Function( DocumentExportCancelled value)?  cancelled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DocumentExportCompleted() when completed != null:
return completed(_that);case DocumentExportCancelled() when cancelled != null:
return cancelled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DocumentExportCompleted value)  completed,required TResult Function( DocumentExportCancelled value)  cancelled,}){
final _that = this;
switch (_that) {
case DocumentExportCompleted():
return completed(_that);case DocumentExportCancelled():
return cancelled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DocumentExportCompleted value)?  completed,TResult? Function( DocumentExportCancelled value)?  cancelled,}){
final _that = this;
switch (_that) {
case DocumentExportCompleted() when completed != null:
return completed(_that);case DocumentExportCancelled() when cancelled != null:
return cancelled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String destinationLabel)?  completed,TResult Function()?  cancelled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DocumentExportCompleted() when completed != null:
return completed(_that.destinationLabel);case DocumentExportCancelled() when cancelled != null:
return cancelled();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String destinationLabel)  completed,required TResult Function()  cancelled,}) {final _that = this;
switch (_that) {
case DocumentExportCompleted():
return completed(_that.destinationLabel);case DocumentExportCancelled():
return cancelled();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String destinationLabel)?  completed,TResult? Function()?  cancelled,}) {final _that = this;
switch (_that) {
case DocumentExportCompleted() when completed != null:
return completed(_that.destinationLabel);case DocumentExportCancelled() when cancelled != null:
return cancelled();case _:
  return null;

}
}

}

/// @nodoc


class DocumentExportCompleted implements DocumentExportResult {
  const DocumentExportCompleted({required this.destinationLabel});
  

 final  String destinationLabel;

/// Create a copy of DocumentExportResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentExportCompletedCopyWith<DocumentExportCompleted> get copyWith => _$DocumentExportCompletedCopyWithImpl<DocumentExportCompleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentExportCompleted&&(identical(other.destinationLabel, destinationLabel) || other.destinationLabel == destinationLabel));
}


@override
int get hashCode => Object.hash(runtimeType,destinationLabel);

@override
String toString() {
  return 'DocumentExportResult.completed(destinationLabel: $destinationLabel)';
}


}

/// @nodoc
abstract mixin class $DocumentExportCompletedCopyWith<$Res> implements $DocumentExportResultCopyWith<$Res> {
  factory $DocumentExportCompletedCopyWith(DocumentExportCompleted value, $Res Function(DocumentExportCompleted) _then) = _$DocumentExportCompletedCopyWithImpl;
@useResult
$Res call({
 String destinationLabel
});




}
/// @nodoc
class _$DocumentExportCompletedCopyWithImpl<$Res>
    implements $DocumentExportCompletedCopyWith<$Res> {
  _$DocumentExportCompletedCopyWithImpl(this._self, this._then);

  final DocumentExportCompleted _self;
  final $Res Function(DocumentExportCompleted) _then;

/// Create a copy of DocumentExportResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? destinationLabel = null,}) {
  return _then(DocumentExportCompleted(
destinationLabel: null == destinationLabel ? _self.destinationLabel : destinationLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DocumentExportCancelled implements DocumentExportResult {
  const DocumentExportCancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentExportCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DocumentExportResult.cancelled()';
}


}




// dart format on
