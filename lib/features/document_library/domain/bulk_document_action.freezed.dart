// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bulk_document_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BulkDocumentRequest {

 List<DocumentId> get documentIds; bool get destructiveActionConfirmed;
/// Create a copy of BulkDocumentRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BulkDocumentRequestCopyWith<BulkDocumentRequest> get copyWith => _$BulkDocumentRequestCopyWithImpl<BulkDocumentRequest>(this as BulkDocumentRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BulkDocumentRequest&&const DeepCollectionEquality().equals(other.documentIds, documentIds)&&(identical(other.destructiveActionConfirmed, destructiveActionConfirmed) || other.destructiveActionConfirmed == destructiveActionConfirmed));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(documentIds),destructiveActionConfirmed);

@override
String toString() {
  return 'BulkDocumentRequest(documentIds: $documentIds, destructiveActionConfirmed: $destructiveActionConfirmed)';
}


}

/// @nodoc
abstract mixin class $BulkDocumentRequestCopyWith<$Res>  {
  factory $BulkDocumentRequestCopyWith(BulkDocumentRequest value, $Res Function(BulkDocumentRequest) _then) = _$BulkDocumentRequestCopyWithImpl;
@useResult
$Res call({
 List<DocumentId> documentIds, bool destructiveActionConfirmed
});




}
/// @nodoc
class _$BulkDocumentRequestCopyWithImpl<$Res>
    implements $BulkDocumentRequestCopyWith<$Res> {
  _$BulkDocumentRequestCopyWithImpl(this._self, this._then);

  final BulkDocumentRequest _self;
  final $Res Function(BulkDocumentRequest) _then;

/// Create a copy of BulkDocumentRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentIds = null,Object? destructiveActionConfirmed = null,}) {
  return _then(_self.copyWith(
documentIds: null == documentIds ? _self.documentIds : documentIds // ignore: cast_nullable_to_non_nullable
as List<DocumentId>,destructiveActionConfirmed: null == destructiveActionConfirmed ? _self.destructiveActionConfirmed : destructiveActionConfirmed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BulkDocumentRequest].
extension BulkDocumentRequestPatterns on BulkDocumentRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BulkDocumentRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BulkDocumentRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BulkDocumentRequest value)  $default,){
final _that = this;
switch (_that) {
case _BulkDocumentRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BulkDocumentRequest value)?  $default,){
final _that = this;
switch (_that) {
case _BulkDocumentRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DocumentId> documentIds,  bool destructiveActionConfirmed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BulkDocumentRequest() when $default != null:
return $default(_that.documentIds,_that.destructiveActionConfirmed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DocumentId> documentIds,  bool destructiveActionConfirmed)  $default,) {final _that = this;
switch (_that) {
case _BulkDocumentRequest():
return $default(_that.documentIds,_that.destructiveActionConfirmed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DocumentId> documentIds,  bool destructiveActionConfirmed)?  $default,) {final _that = this;
switch (_that) {
case _BulkDocumentRequest() when $default != null:
return $default(_that.documentIds,_that.destructiveActionConfirmed);case _:
  return null;

}
}

}

/// @nodoc


class _BulkDocumentRequest implements BulkDocumentRequest {
  const _BulkDocumentRequest({required final  List<DocumentId> documentIds, this.destructiveActionConfirmed = false}): _documentIds = documentIds;
  

 final  List<DocumentId> _documentIds;
@override List<DocumentId> get documentIds {
  if (_documentIds is EqualUnmodifiableListView) return _documentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documentIds);
}

@override@JsonKey() final  bool destructiveActionConfirmed;

/// Create a copy of BulkDocumentRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BulkDocumentRequestCopyWith<_BulkDocumentRequest> get copyWith => __$BulkDocumentRequestCopyWithImpl<_BulkDocumentRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BulkDocumentRequest&&const DeepCollectionEquality().equals(other._documentIds, _documentIds)&&(identical(other.destructiveActionConfirmed, destructiveActionConfirmed) || other.destructiveActionConfirmed == destructiveActionConfirmed));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_documentIds),destructiveActionConfirmed);

@override
String toString() {
  return 'BulkDocumentRequest(documentIds: $documentIds, destructiveActionConfirmed: $destructiveActionConfirmed)';
}


}

/// @nodoc
abstract mixin class _$BulkDocumentRequestCopyWith<$Res> implements $BulkDocumentRequestCopyWith<$Res> {
  factory _$BulkDocumentRequestCopyWith(_BulkDocumentRequest value, $Res Function(_BulkDocumentRequest) _then) = __$BulkDocumentRequestCopyWithImpl;
@override @useResult
$Res call({
 List<DocumentId> documentIds, bool destructiveActionConfirmed
});




}
/// @nodoc
class __$BulkDocumentRequestCopyWithImpl<$Res>
    implements _$BulkDocumentRequestCopyWith<$Res> {
  __$BulkDocumentRequestCopyWithImpl(this._self, this._then);

  final _BulkDocumentRequest _self;
  final $Res Function(_BulkDocumentRequest) _then;

/// Create a copy of BulkDocumentRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentIds = null,Object? destructiveActionConfirmed = null,}) {
  return _then(_BulkDocumentRequest(
documentIds: null == documentIds ? _self._documentIds : documentIds // ignore: cast_nullable_to_non_nullable
as List<DocumentId>,destructiveActionConfirmed: null == destructiveActionConfirmed ? _self.destructiveActionConfirmed : destructiveActionConfirmed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$BulkDocumentFailure {

 DocumentId get documentId; Failure get failure;
/// Create a copy of BulkDocumentFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BulkDocumentFailureCopyWith<BulkDocumentFailure> get copyWith => _$BulkDocumentFailureCopyWithImpl<BulkDocumentFailure>(this as BulkDocumentFailure, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BulkDocumentFailure&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,documentId,failure);

@override
String toString() {
  return 'BulkDocumentFailure(documentId: $documentId, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $BulkDocumentFailureCopyWith<$Res>  {
  factory $BulkDocumentFailureCopyWith(BulkDocumentFailure value, $Res Function(BulkDocumentFailure) _then) = _$BulkDocumentFailureCopyWithImpl;
@useResult
$Res call({
 DocumentId documentId, Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$BulkDocumentFailureCopyWithImpl<$Res>
    implements $BulkDocumentFailureCopyWith<$Res> {
  _$BulkDocumentFailureCopyWithImpl(this._self, this._then);

  final BulkDocumentFailure _self;
  final $Res Function(BulkDocumentFailure) _then;

/// Create a copy of BulkDocumentFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? failure = null,}) {
  return _then(_self.copyWith(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as DocumentId,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}
/// Create a copy of BulkDocumentFailure
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [BulkDocumentFailure].
extension BulkDocumentFailurePatterns on BulkDocumentFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BulkDocumentFailure value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BulkDocumentFailure() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BulkDocumentFailure value)  $default,){
final _that = this;
switch (_that) {
case _BulkDocumentFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BulkDocumentFailure value)?  $default,){
final _that = this;
switch (_that) {
case _BulkDocumentFailure() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DocumentId documentId,  Failure failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BulkDocumentFailure() when $default != null:
return $default(_that.documentId,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DocumentId documentId,  Failure failure)  $default,) {final _that = this;
switch (_that) {
case _BulkDocumentFailure():
return $default(_that.documentId,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DocumentId documentId,  Failure failure)?  $default,) {final _that = this;
switch (_that) {
case _BulkDocumentFailure() when $default != null:
return $default(_that.documentId,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _BulkDocumentFailure implements BulkDocumentFailure {
  const _BulkDocumentFailure({required this.documentId, required this.failure});
  

@override final  DocumentId documentId;
@override final  Failure failure;

/// Create a copy of BulkDocumentFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BulkDocumentFailureCopyWith<_BulkDocumentFailure> get copyWith => __$BulkDocumentFailureCopyWithImpl<_BulkDocumentFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BulkDocumentFailure&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,documentId,failure);

@override
String toString() {
  return 'BulkDocumentFailure(documentId: $documentId, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$BulkDocumentFailureCopyWith<$Res> implements $BulkDocumentFailureCopyWith<$Res> {
  factory _$BulkDocumentFailureCopyWith(_BulkDocumentFailure value, $Res Function(_BulkDocumentFailure) _then) = __$BulkDocumentFailureCopyWithImpl;
@override @useResult
$Res call({
 DocumentId documentId, Failure failure
});


@override $FailureCopyWith<$Res> get failure;

}
/// @nodoc
class __$BulkDocumentFailureCopyWithImpl<$Res>
    implements _$BulkDocumentFailureCopyWith<$Res> {
  __$BulkDocumentFailureCopyWithImpl(this._self, this._then);

  final _BulkDocumentFailure _self;
  final $Res Function(_BulkDocumentFailure) _then;

/// Create a copy of BulkDocumentFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentId = null,Object? failure = null,}) {
  return _then(_BulkDocumentFailure(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as DocumentId,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of BulkDocumentFailure
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc
mixin _$BulkDocumentOutcome {

 List<DocumentId> get succeeded; List<BulkDocumentFailure> get failed;
/// Create a copy of BulkDocumentOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BulkDocumentOutcomeCopyWith<BulkDocumentOutcome> get copyWith => _$BulkDocumentOutcomeCopyWithImpl<BulkDocumentOutcome>(this as BulkDocumentOutcome, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BulkDocumentOutcome&&const DeepCollectionEquality().equals(other.succeeded, succeeded)&&const DeepCollectionEquality().equals(other.failed, failed));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(succeeded),const DeepCollectionEquality().hash(failed));

@override
String toString() {
  return 'BulkDocumentOutcome(succeeded: $succeeded, failed: $failed)';
}


}

/// @nodoc
abstract mixin class $BulkDocumentOutcomeCopyWith<$Res>  {
  factory $BulkDocumentOutcomeCopyWith(BulkDocumentOutcome value, $Res Function(BulkDocumentOutcome) _then) = _$BulkDocumentOutcomeCopyWithImpl;
@useResult
$Res call({
 List<DocumentId> succeeded, List<BulkDocumentFailure> failed
});




}
/// @nodoc
class _$BulkDocumentOutcomeCopyWithImpl<$Res>
    implements $BulkDocumentOutcomeCopyWith<$Res> {
  _$BulkDocumentOutcomeCopyWithImpl(this._self, this._then);

  final BulkDocumentOutcome _self;
  final $Res Function(BulkDocumentOutcome) _then;

/// Create a copy of BulkDocumentOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? succeeded = null,Object? failed = null,}) {
  return _then(_self.copyWith(
succeeded: null == succeeded ? _self.succeeded : succeeded // ignore: cast_nullable_to_non_nullable
as List<DocumentId>,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as List<BulkDocumentFailure>,
  ));
}

}


/// Adds pattern-matching-related methods to [BulkDocumentOutcome].
extension BulkDocumentOutcomePatterns on BulkDocumentOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BulkDocumentOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BulkDocumentOutcome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BulkDocumentOutcome value)  $default,){
final _that = this;
switch (_that) {
case _BulkDocumentOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BulkDocumentOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _BulkDocumentOutcome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DocumentId> succeeded,  List<BulkDocumentFailure> failed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BulkDocumentOutcome() when $default != null:
return $default(_that.succeeded,_that.failed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DocumentId> succeeded,  List<BulkDocumentFailure> failed)  $default,) {final _that = this;
switch (_that) {
case _BulkDocumentOutcome():
return $default(_that.succeeded,_that.failed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DocumentId> succeeded,  List<BulkDocumentFailure> failed)?  $default,) {final _that = this;
switch (_that) {
case _BulkDocumentOutcome() when $default != null:
return $default(_that.succeeded,_that.failed);case _:
  return null;

}
}

}

/// @nodoc


class _BulkDocumentOutcome extends BulkDocumentOutcome {
  const _BulkDocumentOutcome({final  List<DocumentId> succeeded = const <DocumentId>[], final  List<BulkDocumentFailure> failed = const <BulkDocumentFailure>[]}): _succeeded = succeeded,_failed = failed,super._();
  

 final  List<DocumentId> _succeeded;
@override@JsonKey() List<DocumentId> get succeeded {
  if (_succeeded is EqualUnmodifiableListView) return _succeeded;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_succeeded);
}

 final  List<BulkDocumentFailure> _failed;
@override@JsonKey() List<BulkDocumentFailure> get failed {
  if (_failed is EqualUnmodifiableListView) return _failed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_failed);
}


/// Create a copy of BulkDocumentOutcome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BulkDocumentOutcomeCopyWith<_BulkDocumentOutcome> get copyWith => __$BulkDocumentOutcomeCopyWithImpl<_BulkDocumentOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BulkDocumentOutcome&&const DeepCollectionEquality().equals(other._succeeded, _succeeded)&&const DeepCollectionEquality().equals(other._failed, _failed));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_succeeded),const DeepCollectionEquality().hash(_failed));

@override
String toString() {
  return 'BulkDocumentOutcome(succeeded: $succeeded, failed: $failed)';
}


}

/// @nodoc
abstract mixin class _$BulkDocumentOutcomeCopyWith<$Res> implements $BulkDocumentOutcomeCopyWith<$Res> {
  factory _$BulkDocumentOutcomeCopyWith(_BulkDocumentOutcome value, $Res Function(_BulkDocumentOutcome) _then) = __$BulkDocumentOutcomeCopyWithImpl;
@override @useResult
$Res call({
 List<DocumentId> succeeded, List<BulkDocumentFailure> failed
});




}
/// @nodoc
class __$BulkDocumentOutcomeCopyWithImpl<$Res>
    implements _$BulkDocumentOutcomeCopyWith<$Res> {
  __$BulkDocumentOutcomeCopyWithImpl(this._self, this._then);

  final _BulkDocumentOutcome _self;
  final $Res Function(_BulkDocumentOutcome) _then;

/// Create a copy of BulkDocumentOutcome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? succeeded = null,Object? failed = null,}) {
  return _then(_BulkDocumentOutcome(
succeeded: null == succeeded ? _self._succeeded : succeeded // ignore: cast_nullable_to_non_nullable
as List<DocumentId>,failed: null == failed ? _self._failed : failed // ignore: cast_nullable_to_non_nullable
as List<BulkDocumentFailure>,
  ));
}


}

// dart format on
