// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_duplicate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DuplicateDocumentRequest {

 DocumentId get sourceDocumentId; String get title; List<String> get destinationFolders; FolderId? get destinationFolderId;
/// Create a copy of DuplicateDocumentRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuplicateDocumentRequestCopyWith<DuplicateDocumentRequest> get copyWith => _$DuplicateDocumentRequestCopyWithImpl<DuplicateDocumentRequest>(this as DuplicateDocumentRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuplicateDocumentRequest&&(identical(other.sourceDocumentId, sourceDocumentId) || other.sourceDocumentId == sourceDocumentId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.destinationFolders, destinationFolders)&&(identical(other.destinationFolderId, destinationFolderId) || other.destinationFolderId == destinationFolderId));
}


@override
int get hashCode => Object.hash(runtimeType,sourceDocumentId,title,const DeepCollectionEquality().hash(destinationFolders),destinationFolderId);

@override
String toString() {
  return 'DuplicateDocumentRequest(sourceDocumentId: $sourceDocumentId, title: $title, destinationFolders: $destinationFolders, destinationFolderId: $destinationFolderId)';
}


}

/// @nodoc
abstract mixin class $DuplicateDocumentRequestCopyWith<$Res>  {
  factory $DuplicateDocumentRequestCopyWith(DuplicateDocumentRequest value, $Res Function(DuplicateDocumentRequest) _then) = _$DuplicateDocumentRequestCopyWithImpl;
@useResult
$Res call({
 DocumentId sourceDocumentId, String title, List<String> destinationFolders, FolderId? destinationFolderId
});




}
/// @nodoc
class _$DuplicateDocumentRequestCopyWithImpl<$Res>
    implements $DuplicateDocumentRequestCopyWith<$Res> {
  _$DuplicateDocumentRequestCopyWithImpl(this._self, this._then);

  final DuplicateDocumentRequest _self;
  final $Res Function(DuplicateDocumentRequest) _then;

/// Create a copy of DuplicateDocumentRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceDocumentId = null,Object? title = null,Object? destinationFolders = null,Object? destinationFolderId = freezed,}) {
  return _then(_self.copyWith(
sourceDocumentId: null == sourceDocumentId ? _self.sourceDocumentId : sourceDocumentId // ignore: cast_nullable_to_non_nullable
as DocumentId,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,destinationFolders: null == destinationFolders ? _self.destinationFolders : destinationFolders // ignore: cast_nullable_to_non_nullable
as List<String>,destinationFolderId: freezed == destinationFolderId ? _self.destinationFolderId : destinationFolderId // ignore: cast_nullable_to_non_nullable
as FolderId?,
  ));
}

}


/// Adds pattern-matching-related methods to [DuplicateDocumentRequest].
extension DuplicateDocumentRequestPatterns on DuplicateDocumentRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuplicateDocumentRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuplicateDocumentRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuplicateDocumentRequest value)  $default,){
final _that = this;
switch (_that) {
case _DuplicateDocumentRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuplicateDocumentRequest value)?  $default,){
final _that = this;
switch (_that) {
case _DuplicateDocumentRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DocumentId sourceDocumentId,  String title,  List<String> destinationFolders,  FolderId? destinationFolderId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuplicateDocumentRequest() when $default != null:
return $default(_that.sourceDocumentId,_that.title,_that.destinationFolders,_that.destinationFolderId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DocumentId sourceDocumentId,  String title,  List<String> destinationFolders,  FolderId? destinationFolderId)  $default,) {final _that = this;
switch (_that) {
case _DuplicateDocumentRequest():
return $default(_that.sourceDocumentId,_that.title,_that.destinationFolders,_that.destinationFolderId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DocumentId sourceDocumentId,  String title,  List<String> destinationFolders,  FolderId? destinationFolderId)?  $default,) {final _that = this;
switch (_that) {
case _DuplicateDocumentRequest() when $default != null:
return $default(_that.sourceDocumentId,_that.title,_that.destinationFolders,_that.destinationFolderId);case _:
  return null;

}
}

}

/// @nodoc


class _DuplicateDocumentRequest implements DuplicateDocumentRequest {
  const _DuplicateDocumentRequest({required this.sourceDocumentId, required this.title, required final  List<String> destinationFolders, this.destinationFolderId}): _destinationFolders = destinationFolders;
  

@override final  DocumentId sourceDocumentId;
@override final  String title;
 final  List<String> _destinationFolders;
@override List<String> get destinationFolders {
  if (_destinationFolders is EqualUnmodifiableListView) return _destinationFolders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_destinationFolders);
}

@override final  FolderId? destinationFolderId;

/// Create a copy of DuplicateDocumentRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuplicateDocumentRequestCopyWith<_DuplicateDocumentRequest> get copyWith => __$DuplicateDocumentRequestCopyWithImpl<_DuplicateDocumentRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuplicateDocumentRequest&&(identical(other.sourceDocumentId, sourceDocumentId) || other.sourceDocumentId == sourceDocumentId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._destinationFolders, _destinationFolders)&&(identical(other.destinationFolderId, destinationFolderId) || other.destinationFolderId == destinationFolderId));
}


@override
int get hashCode => Object.hash(runtimeType,sourceDocumentId,title,const DeepCollectionEquality().hash(_destinationFolders),destinationFolderId);

@override
String toString() {
  return 'DuplicateDocumentRequest(sourceDocumentId: $sourceDocumentId, title: $title, destinationFolders: $destinationFolders, destinationFolderId: $destinationFolderId)';
}


}

/// @nodoc
abstract mixin class _$DuplicateDocumentRequestCopyWith<$Res> implements $DuplicateDocumentRequestCopyWith<$Res> {
  factory _$DuplicateDocumentRequestCopyWith(_DuplicateDocumentRequest value, $Res Function(_DuplicateDocumentRequest) _then) = __$DuplicateDocumentRequestCopyWithImpl;
@override @useResult
$Res call({
 DocumentId sourceDocumentId, String title, List<String> destinationFolders, FolderId? destinationFolderId
});




}
/// @nodoc
class __$DuplicateDocumentRequestCopyWithImpl<$Res>
    implements _$DuplicateDocumentRequestCopyWith<$Res> {
  __$DuplicateDocumentRequestCopyWithImpl(this._self, this._then);

  final _DuplicateDocumentRequest _self;
  final $Res Function(_DuplicateDocumentRequest) _then;

/// Create a copy of DuplicateDocumentRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceDocumentId = null,Object? title = null,Object? destinationFolders = null,Object? destinationFolderId = freezed,}) {
  return _then(_DuplicateDocumentRequest(
sourceDocumentId: null == sourceDocumentId ? _self.sourceDocumentId : sourceDocumentId // ignore: cast_nullable_to_non_nullable
as DocumentId,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,destinationFolders: null == destinationFolders ? _self._destinationFolders : destinationFolders // ignore: cast_nullable_to_non_nullable
as List<String>,destinationFolderId: freezed == destinationFolderId ? _self.destinationFolderId : destinationFolderId // ignore: cast_nullable_to_non_nullable
as FolderId?,
  ));
}


}

/// @nodoc
mixin _$DuplicateDocumentOutcome {

 Document get document;
/// Create a copy of DuplicateDocumentOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuplicateDocumentOutcomeCopyWith<DuplicateDocumentOutcome> get copyWith => _$DuplicateDocumentOutcomeCopyWithImpl<DuplicateDocumentOutcome>(this as DuplicateDocumentOutcome, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuplicateDocumentOutcome&&(identical(other.document, document) || other.document == document));
}


@override
int get hashCode => Object.hash(runtimeType,document);

@override
String toString() {
  return 'DuplicateDocumentOutcome(document: $document)';
}


}

/// @nodoc
abstract mixin class $DuplicateDocumentOutcomeCopyWith<$Res>  {
  factory $DuplicateDocumentOutcomeCopyWith(DuplicateDocumentOutcome value, $Res Function(DuplicateDocumentOutcome) _then) = _$DuplicateDocumentOutcomeCopyWithImpl;
@useResult
$Res call({
 Document document
});


$DocumentCopyWith<$Res> get document;

}
/// @nodoc
class _$DuplicateDocumentOutcomeCopyWithImpl<$Res>
    implements $DuplicateDocumentOutcomeCopyWith<$Res> {
  _$DuplicateDocumentOutcomeCopyWithImpl(this._self, this._then);

  final DuplicateDocumentOutcome _self;
  final $Res Function(DuplicateDocumentOutcome) _then;

/// Create a copy of DuplicateDocumentOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? document = null,}) {
  return _then(_self.copyWith(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as Document,
  ));
}
/// Create a copy of DuplicateDocumentOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentCopyWith<$Res> get document {
  
  return $DocumentCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// Adds pattern-matching-related methods to [DuplicateDocumentOutcome].
extension DuplicateDocumentOutcomePatterns on DuplicateDocumentOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DuplicateDocumentOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DuplicateDocumentOutcome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DuplicateDocumentOutcome value)  $default,){
final _that = this;
switch (_that) {
case _DuplicateDocumentOutcome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DuplicateDocumentOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _DuplicateDocumentOutcome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Document document)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DuplicateDocumentOutcome() when $default != null:
return $default(_that.document);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Document document)  $default,) {final _that = this;
switch (_that) {
case _DuplicateDocumentOutcome():
return $default(_that.document);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Document document)?  $default,) {final _that = this;
switch (_that) {
case _DuplicateDocumentOutcome() when $default != null:
return $default(_that.document);case _:
  return null;

}
}

}

/// @nodoc


class _DuplicateDocumentOutcome implements DuplicateDocumentOutcome {
  const _DuplicateDocumentOutcome({required this.document});
  

@override final  Document document;

/// Create a copy of DuplicateDocumentOutcome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DuplicateDocumentOutcomeCopyWith<_DuplicateDocumentOutcome> get copyWith => __$DuplicateDocumentOutcomeCopyWithImpl<_DuplicateDocumentOutcome>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DuplicateDocumentOutcome&&(identical(other.document, document) || other.document == document));
}


@override
int get hashCode => Object.hash(runtimeType,document);

@override
String toString() {
  return 'DuplicateDocumentOutcome(document: $document)';
}


}

/// @nodoc
abstract mixin class _$DuplicateDocumentOutcomeCopyWith<$Res> implements $DuplicateDocumentOutcomeCopyWith<$Res> {
  factory _$DuplicateDocumentOutcomeCopyWith(_DuplicateDocumentOutcome value, $Res Function(_DuplicateDocumentOutcome) _then) = __$DuplicateDocumentOutcomeCopyWithImpl;
@override @useResult
$Res call({
 Document document
});


@override $DocumentCopyWith<$Res> get document;

}
/// @nodoc
class __$DuplicateDocumentOutcomeCopyWithImpl<$Res>
    implements _$DuplicateDocumentOutcomeCopyWith<$Res> {
  __$DuplicateDocumentOutcomeCopyWithImpl(this._self, this._then);

  final _DuplicateDocumentOutcome _self;
  final $Res Function(_DuplicateDocumentOutcome) _then;

/// Create a copy of DuplicateDocumentOutcome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? document = null,}) {
  return _then(_DuplicateDocumentOutcome(
document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as Document,
  ));
}

/// Create a copy of DuplicateDocumentOutcome
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentCopyWith<$Res> get document {
  
  return $DocumentCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}

// dart format on
