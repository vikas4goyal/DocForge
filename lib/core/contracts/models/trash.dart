/// Recoverable deletion vocabulary shared by the library and Trash UI.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trash.freezed.dart';
part 'trash.g.dart';

/// How long a deleted item remains recoverable.
const trashRetentionPeriod = Duration(days: 30);

/// The type of payload held by a Trash entry.
enum TrashEntryKind {
  /// One PDF document.
  document,

  /// A folder and its complete recursive tree.
  folderTree,
}

/// Recursive contents measured before a destructive action is confirmed.
@freezed
abstract class TrashInventory with _$TrashInventory {
  /// Creates an immutable inventory.
  const factory TrashInventory({
    @Default(0) int documentCount,
    @Default(0) int otherFileCount,
    @Default(0) int folderCount,
    @Default(0) int sizeInBytes,
  }) = _TrashInventory;

  /// Creates an inventory from JSON.
  factory TrashInventory.fromJson(Map<String, dynamic> json) =>
      _$TrashInventoryFromJson(json);

  const TrashInventory._();

  /// Total number of files, including files DocScanly does not index.
  int get fileCount => documentCount + otherFileCount;

  /// Whether moving this candidate also moves descendants or unknown files.
  bool get hasChildren => fileCount > 0 || folderCount > 0;
}

/// Metadata needed to show, restore, expire and permanently remove a payload.
@freezed
abstract class TrashEntry with _$TrashEntry {
  /// Creates a recoverable Trash entry.
  const factory TrashEntry({
    required TrashId id,
    required TrashEntryKind kind,
    required String displayName,
    required String originalRelativePath,
    required DateTime deletedAt,
    required DateTime expiresAt,
    required TrashInventory inventory,
    @Default(<DocumentId>[]) List<DocumentId> documentIds,
    @Default(<FolderId>[]) List<FolderId> folderIds,
  }) = _TrashEntry;

  /// Creates an entry from JSON.
  factory TrashEntry.fromJson(Map<String, dynamic> json) =>
      _$TrashEntryFromJson(json);

  const TrashEntry._();

  /// Whether this entry must be purged at [now].
  bool isExpiredAt(DateTime now) => !expiresAt.isAfter(now.toUtc());

  /// Creates the canonical expiry instant for [deletedAt].
  static DateTime expiryFor(DateTime deletedAt) =>
      deletedAt.toUtc().add(trashRetentionPeriod);
}

/// Returns a deterministic available recovered name.
///
/// The original is preferred; conflicts become `Name (Recovered N).ext`.
String recoveredName(String original, bool Function(String) exists) {
  if (!exists(original)) return original;
  final dot = original.lastIndexOf('.');
  final hasExtension = dot > 0;
  final stem = hasExtension ? original.substring(0, dot) : original;
  final extension = hasExtension ? original.substring(dot) : '';
  var suffix = 1;
  while (exists('$stem (Recovered $suffix)$extension')) {
    suffix++;
  }
  return '$stem (Recovered $suffix)$extension';
}
