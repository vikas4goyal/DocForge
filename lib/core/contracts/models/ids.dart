/// Typed identifiers for the entities that cross feature boundaries.
///
/// A bare `String` id is easy to pass to the wrong parameter — a folder id
/// where a document id belongs compiles fine and fails at runtime. Wrapping
/// each in its own type makes that a compile error instead, which matters here
/// because ids are threaded through routes, repositories and isolates.
///
/// Values are UUIDs rather than database keys so records created independently
/// on two devices can be reconciled by a future sync layer (see `design.md` §6).
///
/// These are hand-written rather than Freezed on purpose. A Freezed wrapper
/// around a single field serialises asymmetrically under json_serializable —
/// `toJson` emits the object itself while `fromJson` expects a `Map` — and it
/// nests every id as `{"value": "..."}` in stored JSON. Writing them out keeps
/// the wire format a plain string, which also maps directly onto an Isar
/// indexed `String` column.
library;

import 'package:meta/meta.dart';

/// Base class for string-backed typed identifiers.
///
/// Equality is by both runtime type and value, so two different id types
/// holding the same string are never equal.
@immutable
abstract class EntityId {
  /// Creates an identifier wrapping [value].
  const EntityId(this.value);

  /// The underlying identifier text, normally a UUID v4.
  final String value;

  /// Returns [value] so the id serialises as a plain JSON string.
  String toJson() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityId &&
          other.runtimeType == runtimeType &&
          other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => value;
}

/// Identifies a document.
@immutable
class DocumentId extends EntityId {
  /// Creates a document identifier wrapping [value].
  const DocumentId(super.value);

  /// Creates a document identifier from its JSON string form.
  factory DocumentId.fromJson(String json) => DocumentId(json);
}

/// Identifies a folder.
@immutable
class FolderId extends EntityId {
  /// Creates a folder identifier wrapping [value].
  const FolderId(super.value);

  /// Creates a folder identifier from its JSON string form.
  factory FolderId.fromJson(String json) => FolderId(json);
}

/// Identifies a single page within a document.
@immutable
class PageId extends EntityId {
  /// Creates a page identifier wrapping [value].
  const PageId(super.value);

  /// Creates a page identifier from its JSON string form.
  factory PageId.fromJson(String json) => PageId(json);
}

/// Identifies one recoverable Trash entry.
@immutable
class TrashId extends EntityId {
  /// Creates a Trash identifier wrapping [value].
  const TrashId(super.value);

  /// Creates a Trash identifier from its JSON string form.
  factory TrashId.fromJson(String json) => TrashId(json);
}
