// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_page_handle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DocumentPageSource {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentPageSource);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DocumentPageSource()';
}


}

/// @nodoc
class $DocumentPageSourceCopyWith<$Res>  {
$DocumentPageSourceCopyWith(DocumentPageSource _, $Res Function(DocumentPageSource) __);
}


/// Adds pattern-matching-related methods to [DocumentPageSource].
extension DocumentPageSourcePatterns on DocumentPageSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StoredImageDocumentPageSource value)?  storedImage,TResult Function( PdfDocumentPageSource value)?  pdfPage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StoredImageDocumentPageSource() when storedImage != null:
return storedImage(_that);case PdfDocumentPageSource() when pdfPage != null:
return pdfPage(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StoredImageDocumentPageSource value)  storedImage,required TResult Function( PdfDocumentPageSource value)  pdfPage,}){
final _that = this;
switch (_that) {
case StoredImageDocumentPageSource():
return storedImage(_that);case PdfDocumentPageSource():
return pdfPage(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StoredImageDocumentPageSource value)?  storedImage,TResult? Function( PdfDocumentPageSource value)?  pdfPage,}){
final _that = this;
switch (_that) {
case StoredImageDocumentPageSource() when storedImage != null:
return storedImage(_that);case PdfDocumentPageSource() when pdfPage != null:
return pdfPage(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String imagePath,  String? thumbnailPath)?  storedImage,TResult Function()?  pdfPage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StoredImageDocumentPageSource() when storedImage != null:
return storedImage(_that.imagePath,_that.thumbnailPath);case PdfDocumentPageSource() when pdfPage != null:
return pdfPage();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String imagePath,  String? thumbnailPath)  storedImage,required TResult Function()  pdfPage,}) {final _that = this;
switch (_that) {
case StoredImageDocumentPageSource():
return storedImage(_that.imagePath,_that.thumbnailPath);case PdfDocumentPageSource():
return pdfPage();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String imagePath,  String? thumbnailPath)?  storedImage,TResult? Function()?  pdfPage,}) {final _that = this;
switch (_that) {
case StoredImageDocumentPageSource() when storedImage != null:
return storedImage(_that.imagePath,_that.thumbnailPath);case PdfDocumentPageSource() when pdfPage != null:
return pdfPage();case _:
  return null;

}
}

}

/// @nodoc


class StoredImageDocumentPageSource implements DocumentPageSource {
  const StoredImageDocumentPageSource({required this.imagePath, this.thumbnailPath});
  

 final  String imagePath;
 final  String? thumbnailPath;

/// Create a copy of DocumentPageSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoredImageDocumentPageSourceCopyWith<StoredImageDocumentPageSource> get copyWith => _$StoredImageDocumentPageSourceCopyWithImpl<StoredImageDocumentPageSource>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoredImageDocumentPageSource&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath));
}


@override
int get hashCode => Object.hash(runtimeType,imagePath,thumbnailPath);

@override
String toString() {
  return 'DocumentPageSource.storedImage(imagePath: $imagePath, thumbnailPath: $thumbnailPath)';
}


}

/// @nodoc
abstract mixin class $StoredImageDocumentPageSourceCopyWith<$Res> implements $DocumentPageSourceCopyWith<$Res> {
  factory $StoredImageDocumentPageSourceCopyWith(StoredImageDocumentPageSource value, $Res Function(StoredImageDocumentPageSource) _then) = _$StoredImageDocumentPageSourceCopyWithImpl;
@useResult
$Res call({
 String imagePath, String? thumbnailPath
});




}
/// @nodoc
class _$StoredImageDocumentPageSourceCopyWithImpl<$Res>
    implements $StoredImageDocumentPageSourceCopyWith<$Res> {
  _$StoredImageDocumentPageSourceCopyWithImpl(this._self, this._then);

  final StoredImageDocumentPageSource _self;
  final $Res Function(StoredImageDocumentPageSource) _then;

/// Create a copy of DocumentPageSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? imagePath = null,Object? thumbnailPath = freezed,}) {
  return _then(StoredImageDocumentPageSource(
imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PdfDocumentPageSource implements DocumentPageSource {
  const PdfDocumentPageSource();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PdfDocumentPageSource);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DocumentPageSource.pdfPage()';
}


}




/// @nodoc
mixin _$DocumentPageHandle {

 PageId get id; DocumentId get documentId; int get pageNumber; DocumentPageSource get source;
/// Create a copy of DocumentPageHandle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentPageHandleCopyWith<DocumentPageHandle> get copyWith => _$DocumentPageHandleCopyWithImpl<DocumentPageHandle>(this as DocumentPageHandle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentPageHandle&&(identical(other.id, id) || other.id == id)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,id,documentId,pageNumber,source);

@override
String toString() {
  return 'DocumentPageHandle(id: $id, documentId: $documentId, pageNumber: $pageNumber, source: $source)';
}


}

/// @nodoc
abstract mixin class $DocumentPageHandleCopyWith<$Res>  {
  factory $DocumentPageHandleCopyWith(DocumentPageHandle value, $Res Function(DocumentPageHandle) _then) = _$DocumentPageHandleCopyWithImpl;
@useResult
$Res call({
 PageId id, DocumentId documentId, int pageNumber, DocumentPageSource source
});


$DocumentPageSourceCopyWith<$Res> get source;

}
/// @nodoc
class _$DocumentPageHandleCopyWithImpl<$Res>
    implements $DocumentPageHandleCopyWith<$Res> {
  _$DocumentPageHandleCopyWithImpl(this._self, this._then);

  final DocumentPageHandle _self;
  final $Res Function(DocumentPageHandle) _then;

/// Create a copy of DocumentPageHandle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? documentId = null,Object? pageNumber = null,Object? source = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PageId,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as DocumentId,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DocumentPageSource,
  ));
}
/// Create a copy of DocumentPageHandle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentPageSourceCopyWith<$Res> get source {
  
  return $DocumentPageSourceCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}


/// Adds pattern-matching-related methods to [DocumentPageHandle].
extension DocumentPageHandlePatterns on DocumentPageHandle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentPageHandle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentPageHandle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentPageHandle value)  $default,){
final _that = this;
switch (_that) {
case _DocumentPageHandle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentPageHandle value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentPageHandle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PageId id,  DocumentId documentId,  int pageNumber,  DocumentPageSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentPageHandle() when $default != null:
return $default(_that.id,_that.documentId,_that.pageNumber,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PageId id,  DocumentId documentId,  int pageNumber,  DocumentPageSource source)  $default,) {final _that = this;
switch (_that) {
case _DocumentPageHandle():
return $default(_that.id,_that.documentId,_that.pageNumber,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PageId id,  DocumentId documentId,  int pageNumber,  DocumentPageSource source)?  $default,) {final _that = this;
switch (_that) {
case _DocumentPageHandle() when $default != null:
return $default(_that.id,_that.documentId,_that.pageNumber,_that.source);case _:
  return null;

}
}

}

/// @nodoc


class _DocumentPageHandle extends DocumentPageHandle {
  const _DocumentPageHandle({required this.id, required this.documentId, required this.pageNumber, required this.source}): super._();
  

@override final  PageId id;
@override final  DocumentId documentId;
@override final  int pageNumber;
@override final  DocumentPageSource source;

/// Create a copy of DocumentPageHandle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentPageHandleCopyWith<_DocumentPageHandle> get copyWith => __$DocumentPageHandleCopyWithImpl<_DocumentPageHandle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentPageHandle&&(identical(other.id, id) || other.id == id)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,id,documentId,pageNumber,source);

@override
String toString() {
  return 'DocumentPageHandle(id: $id, documentId: $documentId, pageNumber: $pageNumber, source: $source)';
}


}

/// @nodoc
abstract mixin class _$DocumentPageHandleCopyWith<$Res> implements $DocumentPageHandleCopyWith<$Res> {
  factory _$DocumentPageHandleCopyWith(_DocumentPageHandle value, $Res Function(_DocumentPageHandle) _then) = __$DocumentPageHandleCopyWithImpl;
@override @useResult
$Res call({
 PageId id, DocumentId documentId, int pageNumber, DocumentPageSource source
});


@override $DocumentPageSourceCopyWith<$Res> get source;

}
/// @nodoc
class __$DocumentPageHandleCopyWithImpl<$Res>
    implements _$DocumentPageHandleCopyWith<$Res> {
  __$DocumentPageHandleCopyWithImpl(this._self, this._then);

  final _DocumentPageHandle _self;
  final $Res Function(_DocumentPageHandle) _then;

/// Create a copy of DocumentPageHandle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? documentId = null,Object? pageNumber = null,Object? source = null,}) {
  return _then(_DocumentPageHandle(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PageId,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as DocumentId,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DocumentPageSource,
  ));
}

/// Create a copy of DocumentPageHandle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentPageSourceCopyWith<$Res> get source {
  
  return $DocumentPageSourceCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}

/// @nodoc
mixin _$MaterializedDocumentPage {

 String get path;
/// Create a copy of MaterializedDocumentPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaterializedDocumentPageCopyWith<MaterializedDocumentPage> get copyWith => _$MaterializedDocumentPageCopyWithImpl<MaterializedDocumentPage>(this as MaterializedDocumentPage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaterializedDocumentPage&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,path);

@override
String toString() {
  return 'MaterializedDocumentPage(path: $path)';
}


}

/// @nodoc
abstract mixin class $MaterializedDocumentPageCopyWith<$Res>  {
  factory $MaterializedDocumentPageCopyWith(MaterializedDocumentPage value, $Res Function(MaterializedDocumentPage) _then) = _$MaterializedDocumentPageCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$MaterializedDocumentPageCopyWithImpl<$Res>
    implements $MaterializedDocumentPageCopyWith<$Res> {
  _$MaterializedDocumentPageCopyWithImpl(this._self, this._then);

  final MaterializedDocumentPage _self;
  final $Res Function(MaterializedDocumentPage) _then;

/// Create a copy of MaterializedDocumentPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MaterializedDocumentPage].
extension MaterializedDocumentPagePatterns on MaterializedDocumentPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthoritativeDocumentPage value)?  authoritative,TResult Function( CachedDocumentPage value)?  cached,TResult Function( TemporaryDocumentPage value)?  temporary,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthoritativeDocumentPage() when authoritative != null:
return authoritative(_that);case CachedDocumentPage() when cached != null:
return cached(_that);case TemporaryDocumentPage() when temporary != null:
return temporary(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthoritativeDocumentPage value)  authoritative,required TResult Function( CachedDocumentPage value)  cached,required TResult Function( TemporaryDocumentPage value)  temporary,}){
final _that = this;
switch (_that) {
case AuthoritativeDocumentPage():
return authoritative(_that);case CachedDocumentPage():
return cached(_that);case TemporaryDocumentPage():
return temporary(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthoritativeDocumentPage value)?  authoritative,TResult? Function( CachedDocumentPage value)?  cached,TResult? Function( TemporaryDocumentPage value)?  temporary,}){
final _that = this;
switch (_that) {
case AuthoritativeDocumentPage() when authoritative != null:
return authoritative(_that);case CachedDocumentPage() when cached != null:
return cached(_that);case TemporaryDocumentPage() when temporary != null:
return temporary(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String path)?  authoritative,TResult Function( String path)?  cached,TResult Function( String path)?  temporary,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthoritativeDocumentPage() when authoritative != null:
return authoritative(_that.path);case CachedDocumentPage() when cached != null:
return cached(_that.path);case TemporaryDocumentPage() when temporary != null:
return temporary(_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String path)  authoritative,required TResult Function( String path)  cached,required TResult Function( String path)  temporary,}) {final _that = this;
switch (_that) {
case AuthoritativeDocumentPage():
return authoritative(_that.path);case CachedDocumentPage():
return cached(_that.path);case TemporaryDocumentPage():
return temporary(_that.path);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String path)?  authoritative,TResult? Function( String path)?  cached,TResult? Function( String path)?  temporary,}) {final _that = this;
switch (_that) {
case AuthoritativeDocumentPage() when authoritative != null:
return authoritative(_that.path);case CachedDocumentPage() when cached != null:
return cached(_that.path);case TemporaryDocumentPage() when temporary != null:
return temporary(_that.path);case _:
  return null;

}
}

}

/// @nodoc


class AuthoritativeDocumentPage implements MaterializedDocumentPage {
  const AuthoritativeDocumentPage({required this.path});
  

@override final  String path;

/// Create a copy of MaterializedDocumentPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthoritativeDocumentPageCopyWith<AuthoritativeDocumentPage> get copyWith => _$AuthoritativeDocumentPageCopyWithImpl<AuthoritativeDocumentPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoritativeDocumentPage&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,path);

@override
String toString() {
  return 'MaterializedDocumentPage.authoritative(path: $path)';
}


}

/// @nodoc
abstract mixin class $AuthoritativeDocumentPageCopyWith<$Res> implements $MaterializedDocumentPageCopyWith<$Res> {
  factory $AuthoritativeDocumentPageCopyWith(AuthoritativeDocumentPage value, $Res Function(AuthoritativeDocumentPage) _then) = _$AuthoritativeDocumentPageCopyWithImpl;
@override @useResult
$Res call({
 String path
});




}
/// @nodoc
class _$AuthoritativeDocumentPageCopyWithImpl<$Res>
    implements $AuthoritativeDocumentPageCopyWith<$Res> {
  _$AuthoritativeDocumentPageCopyWithImpl(this._self, this._then);

  final AuthoritativeDocumentPage _self;
  final $Res Function(AuthoritativeDocumentPage) _then;

/// Create a copy of MaterializedDocumentPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(AuthoritativeDocumentPage(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CachedDocumentPage implements MaterializedDocumentPage {
  const CachedDocumentPage({required this.path});
  

@override final  String path;

/// Create a copy of MaterializedDocumentPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CachedDocumentPageCopyWith<CachedDocumentPage> get copyWith => _$CachedDocumentPageCopyWithImpl<CachedDocumentPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CachedDocumentPage&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,path);

@override
String toString() {
  return 'MaterializedDocumentPage.cached(path: $path)';
}


}

/// @nodoc
abstract mixin class $CachedDocumentPageCopyWith<$Res> implements $MaterializedDocumentPageCopyWith<$Res> {
  factory $CachedDocumentPageCopyWith(CachedDocumentPage value, $Res Function(CachedDocumentPage) _then) = _$CachedDocumentPageCopyWithImpl;
@override @useResult
$Res call({
 String path
});




}
/// @nodoc
class _$CachedDocumentPageCopyWithImpl<$Res>
    implements $CachedDocumentPageCopyWith<$Res> {
  _$CachedDocumentPageCopyWithImpl(this._self, this._then);

  final CachedDocumentPage _self;
  final $Res Function(CachedDocumentPage) _then;

/// Create a copy of MaterializedDocumentPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(CachedDocumentPage(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TemporaryDocumentPage implements MaterializedDocumentPage {
  const TemporaryDocumentPage({required this.path});
  

@override final  String path;

/// Create a copy of MaterializedDocumentPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TemporaryDocumentPageCopyWith<TemporaryDocumentPage> get copyWith => _$TemporaryDocumentPageCopyWithImpl<TemporaryDocumentPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TemporaryDocumentPage&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,path);

@override
String toString() {
  return 'MaterializedDocumentPage.temporary(path: $path)';
}


}

/// @nodoc
abstract mixin class $TemporaryDocumentPageCopyWith<$Res> implements $MaterializedDocumentPageCopyWith<$Res> {
  factory $TemporaryDocumentPageCopyWith(TemporaryDocumentPage value, $Res Function(TemporaryDocumentPage) _then) = _$TemporaryDocumentPageCopyWithImpl;
@override @useResult
$Res call({
 String path
});




}
/// @nodoc
class _$TemporaryDocumentPageCopyWithImpl<$Res>
    implements $TemporaryDocumentPageCopyWith<$Res> {
  _$TemporaryDocumentPageCopyWithImpl(this._self, this._then);

  final TemporaryDocumentPage _self;
  final $Res Function(TemporaryDocumentPage) _then;

/// Create a copy of MaterializedDocumentPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(TemporaryDocumentPage(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
