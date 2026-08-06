// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trash.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrashInventory {

 int get documentCount; int get otherFileCount; int get folderCount; int get sizeInBytes;
/// Create a copy of TrashInventory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrashInventoryCopyWith<TrashInventory> get copyWith => _$TrashInventoryCopyWithImpl<TrashInventory>(this as TrashInventory, _$identity);

  /// Serializes this TrashInventory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrashInventory&&(identical(other.documentCount, documentCount) || other.documentCount == documentCount)&&(identical(other.otherFileCount, otherFileCount) || other.otherFileCount == otherFileCount)&&(identical(other.folderCount, folderCount) || other.folderCount == folderCount)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentCount,otherFileCount,folderCount,sizeInBytes);

@override
String toString() {
  return 'TrashInventory(documentCount: $documentCount, otherFileCount: $otherFileCount, folderCount: $folderCount, sizeInBytes: $sizeInBytes)';
}


}

/// @nodoc
abstract mixin class $TrashInventoryCopyWith<$Res>  {
  factory $TrashInventoryCopyWith(TrashInventory value, $Res Function(TrashInventory) _then) = _$TrashInventoryCopyWithImpl;
@useResult
$Res call({
 int documentCount, int otherFileCount, int folderCount, int sizeInBytes
});




}
/// @nodoc
class _$TrashInventoryCopyWithImpl<$Res>
    implements $TrashInventoryCopyWith<$Res> {
  _$TrashInventoryCopyWithImpl(this._self, this._then);

  final TrashInventory _self;
  final $Res Function(TrashInventory) _then;

/// Create a copy of TrashInventory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentCount = null,Object? otherFileCount = null,Object? folderCount = null,Object? sizeInBytes = null,}) {
  return _then(_self.copyWith(
documentCount: null == documentCount ? _self.documentCount : documentCount // ignore: cast_nullable_to_non_nullable
as int,otherFileCount: null == otherFileCount ? _self.otherFileCount : otherFileCount // ignore: cast_nullable_to_non_nullable
as int,folderCount: null == folderCount ? _self.folderCount : folderCount // ignore: cast_nullable_to_non_nullable
as int,sizeInBytes: null == sizeInBytes ? _self.sizeInBytes : sizeInBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TrashInventory].
extension TrashInventoryPatterns on TrashInventory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrashInventory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrashInventory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrashInventory value)  $default,){
final _that = this;
switch (_that) {
case _TrashInventory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrashInventory value)?  $default,){
final _that = this;
switch (_that) {
case _TrashInventory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int documentCount,  int otherFileCount,  int folderCount,  int sizeInBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrashInventory() when $default != null:
return $default(_that.documentCount,_that.otherFileCount,_that.folderCount,_that.sizeInBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int documentCount,  int otherFileCount,  int folderCount,  int sizeInBytes)  $default,) {final _that = this;
switch (_that) {
case _TrashInventory():
return $default(_that.documentCount,_that.otherFileCount,_that.folderCount,_that.sizeInBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int documentCount,  int otherFileCount,  int folderCount,  int sizeInBytes)?  $default,) {final _that = this;
switch (_that) {
case _TrashInventory() when $default != null:
return $default(_that.documentCount,_that.otherFileCount,_that.folderCount,_that.sizeInBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrashInventory extends TrashInventory {
  const _TrashInventory({this.documentCount = 0, this.otherFileCount = 0, this.folderCount = 0, this.sizeInBytes = 0}): super._();
  factory _TrashInventory.fromJson(Map<String, dynamic> json) => _$TrashInventoryFromJson(json);

@override@JsonKey() final  int documentCount;
@override@JsonKey() final  int otherFileCount;
@override@JsonKey() final  int folderCount;
@override@JsonKey() final  int sizeInBytes;

/// Create a copy of TrashInventory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrashInventoryCopyWith<_TrashInventory> get copyWith => __$TrashInventoryCopyWithImpl<_TrashInventory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrashInventoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrashInventory&&(identical(other.documentCount, documentCount) || other.documentCount == documentCount)&&(identical(other.otherFileCount, otherFileCount) || other.otherFileCount == otherFileCount)&&(identical(other.folderCount, folderCount) || other.folderCount == folderCount)&&(identical(other.sizeInBytes, sizeInBytes) || other.sizeInBytes == sizeInBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentCount,otherFileCount,folderCount,sizeInBytes);

@override
String toString() {
  return 'TrashInventory(documentCount: $documentCount, otherFileCount: $otherFileCount, folderCount: $folderCount, sizeInBytes: $sizeInBytes)';
}


}

/// @nodoc
abstract mixin class _$TrashInventoryCopyWith<$Res> implements $TrashInventoryCopyWith<$Res> {
  factory _$TrashInventoryCopyWith(_TrashInventory value, $Res Function(_TrashInventory) _then) = __$TrashInventoryCopyWithImpl;
@override @useResult
$Res call({
 int documentCount, int otherFileCount, int folderCount, int sizeInBytes
});




}
/// @nodoc
class __$TrashInventoryCopyWithImpl<$Res>
    implements _$TrashInventoryCopyWith<$Res> {
  __$TrashInventoryCopyWithImpl(this._self, this._then);

  final _TrashInventory _self;
  final $Res Function(_TrashInventory) _then;

/// Create a copy of TrashInventory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentCount = null,Object? otherFileCount = null,Object? folderCount = null,Object? sizeInBytes = null,}) {
  return _then(_TrashInventory(
documentCount: null == documentCount ? _self.documentCount : documentCount // ignore: cast_nullable_to_non_nullable
as int,otherFileCount: null == otherFileCount ? _self.otherFileCount : otherFileCount // ignore: cast_nullable_to_non_nullable
as int,folderCount: null == folderCount ? _self.folderCount : folderCount // ignore: cast_nullable_to_non_nullable
as int,sizeInBytes: null == sizeInBytes ? _self.sizeInBytes : sizeInBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TrashEntry {

 TrashId get id; TrashEntryKind get kind; String get displayName; String get originalRelativePath; DateTime get deletedAt; DateTime get expiresAt; TrashInventory get inventory; List<DocumentId> get documentIds; List<FolderId> get folderIds;
/// Create a copy of TrashEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrashEntryCopyWith<TrashEntry> get copyWith => _$TrashEntryCopyWithImpl<TrashEntry>(this as TrashEntry, _$identity);

  /// Serializes this TrashEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrashEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.originalRelativePath, originalRelativePath) || other.originalRelativePath == originalRelativePath)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.inventory, inventory) || other.inventory == inventory)&&const DeepCollectionEquality().equals(other.documentIds, documentIds)&&const DeepCollectionEquality().equals(other.folderIds, folderIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,displayName,originalRelativePath,deletedAt,expiresAt,inventory,const DeepCollectionEquality().hash(documentIds),const DeepCollectionEquality().hash(folderIds));

@override
String toString() {
  return 'TrashEntry(id: $id, kind: $kind, displayName: $displayName, originalRelativePath: $originalRelativePath, deletedAt: $deletedAt, expiresAt: $expiresAt, inventory: $inventory, documentIds: $documentIds, folderIds: $folderIds)';
}


}

/// @nodoc
abstract mixin class $TrashEntryCopyWith<$Res>  {
  factory $TrashEntryCopyWith(TrashEntry value, $Res Function(TrashEntry) _then) = _$TrashEntryCopyWithImpl;
@useResult
$Res call({
 TrashId id, TrashEntryKind kind, String displayName, String originalRelativePath, DateTime deletedAt, DateTime expiresAt, TrashInventory inventory, List<DocumentId> documentIds, List<FolderId> folderIds
});


$TrashInventoryCopyWith<$Res> get inventory;

}
/// @nodoc
class _$TrashEntryCopyWithImpl<$Res>
    implements $TrashEntryCopyWith<$Res> {
  _$TrashEntryCopyWithImpl(this._self, this._then);

  final TrashEntry _self;
  final $Res Function(TrashEntry) _then;

/// Create a copy of TrashEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? displayName = null,Object? originalRelativePath = null,Object? deletedAt = null,Object? expiresAt = null,Object? inventory = null,Object? documentIds = null,Object? folderIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as TrashId,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TrashEntryKind,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,originalRelativePath: null == originalRelativePath ? _self.originalRelativePath : originalRelativePath // ignore: cast_nullable_to_non_nullable
as String,deletedAt: null == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,inventory: null == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as TrashInventory,documentIds: null == documentIds ? _self.documentIds : documentIds // ignore: cast_nullable_to_non_nullable
as List<DocumentId>,folderIds: null == folderIds ? _self.folderIds : folderIds // ignore: cast_nullable_to_non_nullable
as List<FolderId>,
  ));
}
/// Create a copy of TrashEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrashInventoryCopyWith<$Res> get inventory {
  
  return $TrashInventoryCopyWith<$Res>(_self.inventory, (value) {
    return _then(_self.copyWith(inventory: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrashEntry].
extension TrashEntryPatterns on TrashEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrashEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrashEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrashEntry value)  $default,){
final _that = this;
switch (_that) {
case _TrashEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrashEntry value)?  $default,){
final _that = this;
switch (_that) {
case _TrashEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TrashId id,  TrashEntryKind kind,  String displayName,  String originalRelativePath,  DateTime deletedAt,  DateTime expiresAt,  TrashInventory inventory,  List<DocumentId> documentIds,  List<FolderId> folderIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrashEntry() when $default != null:
return $default(_that.id,_that.kind,_that.displayName,_that.originalRelativePath,_that.deletedAt,_that.expiresAt,_that.inventory,_that.documentIds,_that.folderIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TrashId id,  TrashEntryKind kind,  String displayName,  String originalRelativePath,  DateTime deletedAt,  DateTime expiresAt,  TrashInventory inventory,  List<DocumentId> documentIds,  List<FolderId> folderIds)  $default,) {final _that = this;
switch (_that) {
case _TrashEntry():
return $default(_that.id,_that.kind,_that.displayName,_that.originalRelativePath,_that.deletedAt,_that.expiresAt,_that.inventory,_that.documentIds,_that.folderIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TrashId id,  TrashEntryKind kind,  String displayName,  String originalRelativePath,  DateTime deletedAt,  DateTime expiresAt,  TrashInventory inventory,  List<DocumentId> documentIds,  List<FolderId> folderIds)?  $default,) {final _that = this;
switch (_that) {
case _TrashEntry() when $default != null:
return $default(_that.id,_that.kind,_that.displayName,_that.originalRelativePath,_that.deletedAt,_that.expiresAt,_that.inventory,_that.documentIds,_that.folderIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrashEntry extends TrashEntry {
  const _TrashEntry({required this.id, required this.kind, required this.displayName, required this.originalRelativePath, required this.deletedAt, required this.expiresAt, required this.inventory, final  List<DocumentId> documentIds = const <DocumentId>[], final  List<FolderId> folderIds = const <FolderId>[]}): _documentIds = documentIds,_folderIds = folderIds,super._();
  factory _TrashEntry.fromJson(Map<String, dynamic> json) => _$TrashEntryFromJson(json);

@override final  TrashId id;
@override final  TrashEntryKind kind;
@override final  String displayName;
@override final  String originalRelativePath;
@override final  DateTime deletedAt;
@override final  DateTime expiresAt;
@override final  TrashInventory inventory;
 final  List<DocumentId> _documentIds;
@override@JsonKey() List<DocumentId> get documentIds {
  if (_documentIds is EqualUnmodifiableListView) return _documentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documentIds);
}

 final  List<FolderId> _folderIds;
@override@JsonKey() List<FolderId> get folderIds {
  if (_folderIds is EqualUnmodifiableListView) return _folderIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_folderIds);
}


/// Create a copy of TrashEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrashEntryCopyWith<_TrashEntry> get copyWith => __$TrashEntryCopyWithImpl<_TrashEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrashEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrashEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.originalRelativePath, originalRelativePath) || other.originalRelativePath == originalRelativePath)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.inventory, inventory) || other.inventory == inventory)&&const DeepCollectionEquality().equals(other._documentIds, _documentIds)&&const DeepCollectionEquality().equals(other._folderIds, _folderIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,displayName,originalRelativePath,deletedAt,expiresAt,inventory,const DeepCollectionEquality().hash(_documentIds),const DeepCollectionEquality().hash(_folderIds));

@override
String toString() {
  return 'TrashEntry(id: $id, kind: $kind, displayName: $displayName, originalRelativePath: $originalRelativePath, deletedAt: $deletedAt, expiresAt: $expiresAt, inventory: $inventory, documentIds: $documentIds, folderIds: $folderIds)';
}


}

/// @nodoc
abstract mixin class _$TrashEntryCopyWith<$Res> implements $TrashEntryCopyWith<$Res> {
  factory _$TrashEntryCopyWith(_TrashEntry value, $Res Function(_TrashEntry) _then) = __$TrashEntryCopyWithImpl;
@override @useResult
$Res call({
 TrashId id, TrashEntryKind kind, String displayName, String originalRelativePath, DateTime deletedAt, DateTime expiresAt, TrashInventory inventory, List<DocumentId> documentIds, List<FolderId> folderIds
});


@override $TrashInventoryCopyWith<$Res> get inventory;

}
/// @nodoc
class __$TrashEntryCopyWithImpl<$Res>
    implements _$TrashEntryCopyWith<$Res> {
  __$TrashEntryCopyWithImpl(this._self, this._then);

  final _TrashEntry _self;
  final $Res Function(_TrashEntry) _then;

/// Create a copy of TrashEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? displayName = null,Object? originalRelativePath = null,Object? deletedAt = null,Object? expiresAt = null,Object? inventory = null,Object? documentIds = null,Object? folderIds = null,}) {
  return _then(_TrashEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as TrashId,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TrashEntryKind,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,originalRelativePath: null == originalRelativePath ? _self.originalRelativePath : originalRelativePath // ignore: cast_nullable_to_non_nullable
as String,deletedAt: null == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,inventory: null == inventory ? _self.inventory : inventory // ignore: cast_nullable_to_non_nullable
as TrashInventory,documentIds: null == documentIds ? _self._documentIds : documentIds // ignore: cast_nullable_to_non_nullable
as List<DocumentId>,folderIds: null == folderIds ? _self._folderIds : folderIds // ignore: cast_nullable_to_non_nullable
as List<FolderId>,
  ));
}

/// Create a copy of TrashEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrashInventoryCopyWith<$Res> get inventory {
  
  return $TrashInventoryCopyWith<$Res>(_self.inventory, (value) {
    return _then(_self.copyWith(inventory: value));
  });
}
}

// dart format on
