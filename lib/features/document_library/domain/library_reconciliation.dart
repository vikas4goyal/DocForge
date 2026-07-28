/// The diff between the library folder and the index over it.
///
/// Pure functions over value objects: no filesystem, no database, no Flutter.
/// The walk that produces the inputs is I/O and lives in the application layer;
/// deciding what changed is a rule, and rules belong here where they can be
/// tested exhaustively without a device (`design.md` D5).
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:meta/meta.dart';

/// A file as the library folder currently holds it.
///
/// Deliberately not a [Document]: a file found in the folder has no title,
/// favourite status or recognised text until the index gives it one.
@immutable
class LibraryFile {
  /// Creates a description of a file in the library folder.
  const LibraryFile({
    required this.path,
    required this.sizeBytes,
    this.modifiedAt,
  });

  /// Where the file sits, relative to the library root.
  final LibraryPath path;

  /// The file's size in bytes.
  final int sizeBytes;

  /// When the file was last modified, when the platform reports it.
  final DateTime? modifiedAt;

  /// The identity used to recognise this file after it has been renamed.
  ///
  /// Size alone. A rename changes neither the bytes nor the length, so size
  /// survives it; the modification time would too, but the *record* has no
  /// file mtime to compare against — `updatedAt` is stamped from the clock when
  /// the document is saved, not from the file, so the two would almost never
  /// agree and every rename would look like a deletion.
  ///
  /// Size alone is ambiguous when two documents happen to be the same length,
  /// which is why [LibraryReconciliation.diff] pairs on it only when the match
  /// is unique — see there.
  ///
  /// A content hash would be exact, but it means reading every byte of every
  /// file on every resume, which on a large library is the difference between
  /// a reconcile the user never notices and one they do.
  int get fingerprint => sizeBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryFile &&
          other.path == path &&
          other.sizeBytes == sizeBytes &&
          other.modifiedAt == modifiedAt;

  @override
  int get hashCode => Object.hash(path, sizeBytes, modifiedAt);

  @override
  String toString() => 'LibraryFile(${path.relative}, $sizeBytes bytes)';
}

/// A document that has been renamed or moved outside the application.
@immutable
class RenamedDocument {
  /// Creates a rename.
  const RenamedDocument({required this.document, required this.file});

  /// The indexed document, still carrying its old path.
  final Document document;

  /// Where the file actually is now.
  final LibraryFile file;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenamedDocument &&
          other.document == document &&
          other.file == file;

  @override
  int get hashCode => Object.hash(document, file);
}

/// A document whose file changed in place.
@immutable
class ModifiedDocument {
  /// Creates a modification.
  const ModifiedDocument({required this.document, required this.file});

  /// The indexed document.
  final Document document;

  /// The file as it now is.
  final LibraryFile file;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModifiedDocument &&
          other.document == document &&
          other.file == file;

  @override
  int get hashCode => Object.hash(document, file);
}

/// What reconciling the index against the folder found.
@immutable
class LibraryDiff {
  /// Creates a diff.
  const LibraryDiff({
    this.added = const [],
    this.removed = const [],
    this.modified = const [],
    this.renamed = const [],
    this.folders = const [],
  });

  /// Files in the folder that the index does not know about.
  final List<LibraryFile> added;

  /// Documents in the index whose file is no longer there.
  final List<Document> removed;

  /// Documents whose file changed where it stands.
  final List<ModifiedDocument> modified;

  /// Documents whose file was renamed or moved outside the application.
  final List<RenamedDocument> renamed;

  /// Folder paths present in the folder tree.
  final List<String> folders;

  /// Whether anything at all changed.
  bool get isEmpty =>
      added.isEmpty && removed.isEmpty && modified.isEmpty && renamed.isEmpty;

  /// How many documents this diff touches.
  int get changeCount =>
      added.length + removed.length + modified.length + renamed.length;

  @override
  String toString() =>
      'LibraryDiff(added: ${added.length}, removed: ${removed.length}, '
      'modified: ${modified.length}, renamed: ${renamed.length})';
}

/// Decides what changed between the index and the folder.
abstract final class LibraryReconciliation {
  /// Diffs [indexed] documents against the [found] files.
  ///
  /// The order of the checks is what makes a rename keep its metadata:
  ///
  /// 1. Files at a path the index already knows are matched by path. Same
  ///    fingerprint means nothing happened; a different one means the file was
  ///    edited in place.
  /// 2. Whatever is left over on each side is matched by size, and *only when
  ///    that match is unique* — exactly one orphaned document and exactly one
  ///    unclaimed file of that length. Then it is the same document under a new
  ///    name. Two documents of identical length renamed in the same pass are
  ///    genuinely indistinguishable, so they are reported as removals and
  ///    additions rather than paired by guesswork.
  /// 3. Only then is the remainder called added and removed.
  ///
  /// Reversing 2 and 3 would make every rename look like a delete followed by
  /// an unrelated arrival, which throws away the favourite status, the archive
  /// state and the recognised text the user built up.
  static LibraryDiff diff({
    required List<Document> indexed,
    required List<LibraryFile> found,
    List<String> folders = const [],
  }) {
    final byPath = <String, Document>{
      for (final document in indexed) document.relativePath: document,
    };
    final foundByPath = <String, LibraryFile>{
      for (final file in found) file.path.relative: file,
    };

    final modified = <ModifiedDocument>[];
    final matchedPaths = <String>{};

    // 1. Same path on both sides.
    for (final entry in foundByPath.entries) {
      final document = byPath[entry.key];
      if (document == null) continue;

      matchedPaths.add(entry.key);
      if (!_matches(document, entry.value)) {
        modified.add(ModifiedDocument(document: document, file: entry.value));
      }
    }

    final unmatchedDocuments = [
      for (final document in indexed)
        if (!matchedPaths.contains(document.relativePath)) document,
    ];
    final unmatchedFiles = [
      for (final file in found)
        if (!matchedPaths.contains(file.path.relative)) file,
    ];

    // 2. Unique size match across what is left: a rename.
    final filesBySize = <int, List<LibraryFile>>{};
    for (final file in unmatchedFiles) {
      filesBySize.putIfAbsent(file.fingerprint, () => []).add(file);
    }
    final documentsBySize = <int, List<Document>>{};
    for (final document in unmatchedDocuments) {
      documentsBySize.putIfAbsent(document.sizeInBytes, () => []).add(document);
    }

    final renamed = <RenamedDocument>[];
    final claimedFiles = <String>{};
    final stillMissing = <Document>[];

    for (final document in unmatchedDocuments) {
      final files = filesBySize[document.sizeInBytes] ?? const <LibraryFile>[];
      final peers = documentsBySize[document.sizeInBytes] ?? const <Document>[];

      // Unique on both sides or not at all. Pairing one of three same-sized
      // documents with one of three same-sized files would be a coin toss
      // whose loser silently inherits another document's history.
      if (files.length != 1 || peers.length != 1) {
        stillMissing.add(document);
        continue;
      }

      claimedFiles.add(files.single.path.relative);
      renamed.add(RenamedDocument(document: document, file: files.single));
    }

    // 3. What nothing claimed.
    return LibraryDiff(
      added: [
        for (final file in unmatchedFiles)
          if (!claimedFiles.contains(file.path.relative)) file,
      ],
      removed: stillMissing,
      modified: modified,
      renamed: renamed,
      folders: folders,
    );
  }

  /// Whether [document] already describes [file].
  static bool _matches(Document document, LibraryFile file) =>
      document.sizeInBytes == file.sizeBytes;

  /// Applies [rename] to its document, producing the updated record.
  static Document applyRename(RenamedDocument rename) =>
      rename.document.copyWith(
        libraryPath: rename.file.path,
        // The title follows the file name: the user renamed the file, and a
        // list still showing the old title would be showing something that no
        // longer exists anywhere.
        title: rename.file.path.baseName,
      );

  /// Applies [change] to its document, producing the updated record.
  static Document applyModification(ModifiedDocument change, DateTime now) =>
      change.document.copyWith(
        sizeInBytes: change.file.sizeBytes,
        updatedAt: change.file.modifiedAt ?? now,
      );
}
