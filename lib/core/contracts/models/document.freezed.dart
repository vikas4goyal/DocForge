// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Document {

 DocumentId get id; String get title; DateTime get createdAt; DateTime get updatedAt;/// Number of pages in the document. Always at least one.
 int get pageCount;/// Size of the stored PDF in bytes.
 int get sizeInBytes;/// Path to the PDF inside app-private storage.
 String get filePath;/// The folder this document belongs to, or null when unfiled.
 FolderId? get folderId; bool get isFavourite; bool get isArchived;/// Whether the stored PDF is password-protected.
///
/// The password itself is never held here — it lives in secure storage.
 bool get isProtected;/// Whether text recognition has been run and produced a stored result.
 bool get hasRecognisedText;
/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentCopyWith<Document> get copyWith => _$DocumentCopyWithImpl<Document>(this as Document, _$identity);

  /// Serializes this Document to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Document&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.isFavourite, isFavourite) || other.isFavourite == isFavourite)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.isProtected, isProtected) || other.isProtected == isProtected)&&(identical(other.hasRecognisedText, hasRecognisedText) || other.hasRecognisedText == hasRecognisedText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,createdAt,updatedAt,pageCount,sizeInBytes,filePath,folderId,isFavourite,isArchived,isProtected,hasRecognisedText);

@override
String toString() {
  return 'Document(id: $id, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, pageCount: $pageCount, sizeInBytes: $sizeInBytes, filePath: $filePath, folderId: $folderId, isFavourite: $isFavourite, isArchived: $isArchived, isProtected: $isProtected, hasRecognisedText: $hasRecognisedText)';
}


}

/// @nodoc
abstract mixin class $DocumentCopyWith<$Res>  {
  factory $DocumentCopyWith(Document value, $Res Function(Document) _then) = _$DocumentCopyWithImpl;
@useResult
$Res call({
 DocumentId id, String title, DateTime createdAt, DateTime updatedAt, int pageCount, int sizeInBytes, String filePath, FolderId? folderId, bool isFavourite, bool isArchived, bool isProtected, bool hasRecognisedText
});




}
/// @nodoc
class _$DocumentCopyWithImpl<$Res>
    implements $DocumentCopyWith<$Res> {
  _$DocumentCopyWithImpl(this._self, this._then);

  final Document _self;
  final $Res Function(Document) _then;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? createdAt = null,Object? updatedAt = null,Object? pageCount = null,Object? sizeInBytes = null,Object? filePath = null,Object? folderId = freezed,Object? isFavourite = null,Object? isArchived = null,Object? isProtected = null,Object? hasRecognisedText = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as DocumentId,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,sizeInBytes: null == sizeInBytes ? _self.sizeInBytes : sizeInBytes // ignore: cast_nullable_to_non_nullable
as int,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as FolderId?,isFavourite: null == isFavourite ? _self.isFavourite : isFavourite // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,isProtected: null == isProtected ? _self.isProtected : isProtected // ignore: cast_nullable_to_non_nullable
as bool,hasRecognisedText: null == hasRecognisedText ? _self.hasRecognisedText : hasRecognisedText // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Document].
extension DocumentPatterns on Document {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Document value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Document() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Document value)  $default,){
final _that = this;
switch (_that) {
case _Document():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Document value)?  $default,){
final _that = this;
switch (_that) {
case _Document() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DocumentId id,  String title,  DateTime createdAt,  DateTime updatedAt,  int pageCount,  int sizeInBytes,  String filePath,  FolderId? folderId,  bool isFavourite,  bool isArchived,  bool isProtected,  bool hasRecognisedText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that.id,_that.title,_that.createdAt,_that.updatedAt,_that.pageCount,_that.sizeInBytes,_that.filePath,_that.folderId,_that.isFavourite,_that.isArchived,_that.isProtected,_that.hasRecognisedText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DocumentId id,  String title,  DateTime createdAt,  DateTime updatedAt,  int pageCount,  int sizeInBytes,  String filePath,  FolderId? folderId,  bool isFavourite,  bool isArchived,  bool isProtected,  bool hasRecognisedText)  $default,) {final _that = this;
switch (_that) {
case _Document():
return $default(_that.id,_that.title,_that.createdAt,_that.updatedAt,_that.pageCount,_that.sizeInBytes,_that.filePath,_that.folderId,_that.isFavourite,_that.isArchived,_that.isProtected,_that.hasRecognisedText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DocumentId id,  String title,  DateTime createdAt,  DateTime updatedAt,  int pageCount,  int sizeInBytes,  String filePath,  FolderId? folderId,  bool isFavourite,  bool isArchived,  bool isProtected,  bool hasRecognisedText)?  $default,) {final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that.id,_that.title,_that.createdAt,_that.updatedAt,_that.pageCount,_that.sizeInBytes,_that.filePath,_that.folderId,_that.isFavourite,_that.isArchived,_that.isProtected,_that.hasRecognisedText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Document extends Document {
  const _Document({required this.id, required this.title, required this.createdAt, required this.updatedAt, required this.pageCount, required this.sizeInBytes, required this.filePath, this.folderId, this.isFavourite = false, this.isArchived = false, this.isProtected = false, this.hasRecognisedText = false}): super._();
  factory _Document.fromJson(Map<String, dynamic> json) => _$DocumentFromJson(json);

@override final  DocumentId id;
@override final  String title;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Number of pages in the document. Always at least one.
@override final  int pageCount;
/// Size of the stored PDF in bytes.
@override final  int sizeInBytes;
/// Path to the PDF inside app-private storage.
@override final  String filePath;
/// The folder this document belongs to, or null when unfiled.
@override final  FolderId? folderId;
@override@JsonKey() final  bool isFavourite;
@override@JsonKey() final  bool isArchived;
/// Whether the stored PDF is password-protected.
///
/// The password itself is never held here — it lives in secure storage.
@override@JsonKey() final  bool isProtected;
/// Whether text recognition has been run and produced a stored result.
@override@JsonKey() final  bool hasRecognisedText;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentCopyWith<_Document> get copyWith => __$DocumentCopyWithImpl<_Document>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Document&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.isFavourite, isFavourite) || other.isFavourite == isFavourite)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.isProtected, isProtected) || other.isProtected == isProtected)&&(identical(other.hasRecognisedText, hasRecognisedText) || other.hasRecognisedText == hasRecognisedText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,createdAt,updatedAt,pageCount,sizeInBytes,filePath,folderId,isFavourite,isArchived,isProtected,hasRecognisedText);

@override
String toString() {
  return 'Document(id: $id, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, pageCount: $pageCount, sizeInBytes: $sizeInBytes, filePath: $filePath, folderId: $folderId, isFavourite: $isFavourite, isArchived: $isArchived, isProtected: $isProtected, hasRecognisedText: $hasRecognisedText)';
}


}

/// @nodoc
abstract mixin class _$DocumentCopyWith<$Res> implements $DocumentCopyWith<$Res> {
  factory _$DocumentCopyWith(_Document value, $Res Function(_Document) _then) = __$DocumentCopyWithImpl;
@override @useResult
$Res call({
 DocumentId id, String title, DateTime createdAt, DateTime updatedAt, int pageCount, int sizeInBytes, String filePath, FolderId? folderId, bool isFavourite, bool isArchived, bool isProtected, bool hasRecognisedText
});




}
/// @nodoc
class __$DocumentCopyWithImpl<$Res>
    implements _$DocumentCopyWith<$Res> {
  __$DocumentCopyWithImpl(this._self, this._then);

  final _Document _self;
  final $Res Function(_Document) _then;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? createdAt = null,Object? updatedAt = null,Object? pageCount = null,Object? sizeInBytes = null,Object? filePath = null,Object? folderId = freezed,Object? isFavourite = null,Object? isArchived = null,Object? isProtected = null,Object? hasRecognisedText = null,}) {
  return _then(_Document(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as DocumentId,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,sizeInBytes: null == sizeInBytes ? _self.sizeInBytes : sizeInBytes // ignore: cast_nullable_to_non_nullable
as int,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as FolderId?,isFavourite: null == isFavourite ? _self.isFavourite : isFavourite // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,isProtected: null == isProtected ? _self.isProtected : isProtected // ignore: cast_nullable_to_non_nullable
as bool,hasRecognisedText: null == hasRecognisedText ? _self.hasRecognisedText : hasRecognisedText // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Folder {

 FolderId get id; String get name; DateTime get createdAt;/// Number of non-archived documents the folder currently contains.
///
/// Computed at read time rather than stored, so it cannot drift out of
/// sync with the documents themselves.
 int get documentCount;
/// Create a copy of Folder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderCopyWith<Folder> get copyWith => _$FolderCopyWithImpl<Folder>(this as Folder, _$identity);

  /// Serializes this Folder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Folder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.documentCount, documentCount) || other.documentCount == documentCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,createdAt,documentCount);

@override
String toString() {
  return 'Folder(id: $id, name: $name, createdAt: $createdAt, documentCount: $documentCount)';
}


}

/// @nodoc
abstract mixin class $FolderCopyWith<$Res>  {
  factory $FolderCopyWith(Folder value, $Res Function(Folder) _then) = _$FolderCopyWithImpl;
@useResult
$Res call({
 FolderId id, String name, DateTime createdAt, int documentCount
});




}
/// @nodoc
class _$FolderCopyWithImpl<$Res>
    implements $FolderCopyWith<$Res> {
  _$FolderCopyWithImpl(this._self, this._then);

  final Folder _self;
  final $Res Function(Folder) _then;

/// Create a copy of Folder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? createdAt = null,Object? documentCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as FolderId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,documentCount: null == documentCount ? _self.documentCount : documentCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Folder].
extension FolderPatterns on Folder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Folder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Folder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Folder value)  $default,){
final _that = this;
switch (_that) {
case _Folder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Folder value)?  $default,){
final _that = this;
switch (_that) {
case _Folder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FolderId id,  String name,  DateTime createdAt,  int documentCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Folder() when $default != null:
return $default(_that.id,_that.name,_that.createdAt,_that.documentCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FolderId id,  String name,  DateTime createdAt,  int documentCount)  $default,) {final _that = this;
switch (_that) {
case _Folder():
return $default(_that.id,_that.name,_that.createdAt,_that.documentCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FolderId id,  String name,  DateTime createdAt,  int documentCount)?  $default,) {final _that = this;
switch (_that) {
case _Folder() when $default != null:
return $default(_that.id,_that.name,_that.createdAt,_that.documentCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Folder extends Folder {
  const _Folder({required this.id, required this.name, required this.createdAt, this.documentCount = 0}): super._();
  factory _Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);

@override final  FolderId id;
@override final  String name;
@override final  DateTime createdAt;
/// Number of non-archived documents the folder currently contains.
///
/// Computed at read time rather than stored, so it cannot drift out of
/// sync with the documents themselves.
@override@JsonKey() final  int documentCount;

/// Create a copy of Folder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderCopyWith<_Folder> get copyWith => __$FolderCopyWithImpl<_Folder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FolderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Folder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.documentCount, documentCount) || other.documentCount == documentCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,createdAt,documentCount);

@override
String toString() {
  return 'Folder(id: $id, name: $name, createdAt: $createdAt, documentCount: $documentCount)';
}


}

/// @nodoc
abstract mixin class _$FolderCopyWith<$Res> implements $FolderCopyWith<$Res> {
  factory _$FolderCopyWith(_Folder value, $Res Function(_Folder) _then) = __$FolderCopyWithImpl;
@override @useResult
$Res call({
 FolderId id, String name, DateTime createdAt, int documentCount
});




}
/// @nodoc
class __$FolderCopyWithImpl<$Res>
    implements _$FolderCopyWith<$Res> {
  __$FolderCopyWithImpl(this._self, this._then);

  final _Folder _self;
  final $Res Function(_Folder) _then;

/// Create a copy of Folder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? createdAt = null,Object? documentCount = null,}) {
  return _then(_Folder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as FolderId,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,documentCount: null == documentCount ? _self.documentCount : documentCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StorageSummary {

/// Total bytes used by stored PDFs, page images and thumbnails.
 int get totalBytes;/// Number of stored documents, including archived ones.
 int get documentCount;
/// Create a copy of StorageSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorageSummaryCopyWith<StorageSummary> get copyWith => _$StorageSummaryCopyWithImpl<StorageSummary>(this as StorageSummary, _$identity);

  /// Serializes this StorageSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageSummary&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.documentCount, documentCount) || other.documentCount == documentCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalBytes,documentCount);

@override
String toString() {
  return 'StorageSummary(totalBytes: $totalBytes, documentCount: $documentCount)';
}


}

/// @nodoc
abstract mixin class $StorageSummaryCopyWith<$Res>  {
  factory $StorageSummaryCopyWith(StorageSummary value, $Res Function(StorageSummary) _then) = _$StorageSummaryCopyWithImpl;
@useResult
$Res call({
 int totalBytes, int documentCount
});




}
/// @nodoc
class _$StorageSummaryCopyWithImpl<$Res>
    implements $StorageSummaryCopyWith<$Res> {
  _$StorageSummaryCopyWithImpl(this._self, this._then);

  final StorageSummary _self;
  final $Res Function(StorageSummary) _then;

/// Create a copy of StorageSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalBytes = null,Object? documentCount = null,}) {
  return _then(_self.copyWith(
totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,documentCount: null == documentCount ? _self.documentCount : documentCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StorageSummary].
extension StorageSummaryPatterns on StorageSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StorageSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StorageSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StorageSummary value)  $default,){
final _that = this;
switch (_that) {
case _StorageSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StorageSummary value)?  $default,){
final _that = this;
switch (_that) {
case _StorageSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalBytes,  int documentCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StorageSummary() when $default != null:
return $default(_that.totalBytes,_that.documentCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalBytes,  int documentCount)  $default,) {final _that = this;
switch (_that) {
case _StorageSummary():
return $default(_that.totalBytes,_that.documentCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalBytes,  int documentCount)?  $default,) {final _that = this;
switch (_that) {
case _StorageSummary() when $default != null:
return $default(_that.totalBytes,_that.documentCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StorageSummary extends StorageSummary {
  const _StorageSummary({required this.totalBytes, required this.documentCount}): super._();
  factory _StorageSummary.fromJson(Map<String, dynamic> json) => _$StorageSummaryFromJson(json);

/// Total bytes used by stored PDFs, page images and thumbnails.
@override final  int totalBytes;
/// Number of stored documents, including archived ones.
@override final  int documentCount;

/// Create a copy of StorageSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StorageSummaryCopyWith<_StorageSummary> get copyWith => __$StorageSummaryCopyWithImpl<_StorageSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StorageSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StorageSummary&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.documentCount, documentCount) || other.documentCount == documentCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalBytes,documentCount);

@override
String toString() {
  return 'StorageSummary(totalBytes: $totalBytes, documentCount: $documentCount)';
}


}

/// @nodoc
abstract mixin class _$StorageSummaryCopyWith<$Res> implements $StorageSummaryCopyWith<$Res> {
  factory _$StorageSummaryCopyWith(_StorageSummary value, $Res Function(_StorageSummary) _then) = __$StorageSummaryCopyWithImpl;
@override @useResult
$Res call({
 int totalBytes, int documentCount
});




}
/// @nodoc
class __$StorageSummaryCopyWithImpl<$Res>
    implements _$StorageSummaryCopyWith<$Res> {
  __$StorageSummaryCopyWithImpl(this._self, this._then);

  final _StorageSummary _self;
  final $Res Function(_StorageSummary) _then;

/// Create a copy of StorageSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalBytes = null,Object? documentCount = null,}) {
  return _then(_StorageSummary(
totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,documentCount: null == documentCount ? _self.documentCount : documentCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
