/// A [PublicFileStore] over a real directory on the filesystem.
///
/// Used on iOS, where the application's `Documents` container is exposed to the
/// Files app by `UIFileSharingEnabled` and files inside it have ordinary paths
/// that every plugin can read. Nothing here is iOS-specific in code — it is
/// plain `dart:io` — which is also what lets the host test VM exercise it
/// against a temporary directory rather than a device.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/public_storage/public_file_store.dart';

/// The user-visible library folder, backed by a directory.
class FilesystemPublicFileStore implements PublicFileStore {
  /// Creates a store rooted at [libraryFolderName] inside [containerDirectory].
  ///
  /// The container is resolved once by the composition root rather than looked
  /// up per call, so no ambient path lookup happens inside a repository — the
  /// same shape the previous `LocalDocumentFileStore` used.
  const FilesystemPublicFileStore(
    this.containerDirectory, {
    this.libraryFolderName = defaultLibraryFolderName,
  });

  /// The name of the library folder as the user sees it in the file browser.
  static const defaultLibraryFolderName = 'DocForge';

  /// The directory the library folder sits in.
  ///
  /// On iOS this is the application's `Documents` container, which after this
  /// change contains nothing but the library folder — see `design.md` D4.
  final Directory containerDirectory;

  /// The library folder's name.
  final String libraryFolderName;

  /// The root of the library tree.
  Directory get _root =>
      Directory('${containerDirectory.path}/$libraryFolderName');

  @override
  Future<Result<void>> initialise() async {
    try {
      await _root.create(recursive: true);
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(mapFileSystemError(error));
    }
  }

  @override
  Future<Result<List<PublicEntry>>> list(List<String> folders) async {
    try {
      final directory = _directoryFor(folders);
      if (!directory.existsSync()) {
        return const Result<List<PublicEntry>>.failure(Failure.notFound());
      }

      final entries = <PublicEntry>[];
      await for (final entity in directory.list()) {
        final entry = _entryFor(entity, folders);
        if (entry != null) entries.add(entry);
      }
      return Result<List<PublicEntry>>.success(entries);
    } on Object catch (error) {
      return Result<List<PublicEntry>>.failure(mapFileSystemError(error));
    }
  }

  @override
  Future<Result<List<PublicEntry>>> listRecursive(List<String> folders) async {
    try {
      final directory = _directoryFor(folders);
      if (!directory.existsSync()) {
        return const Result<List<PublicEntry>>.failure(Failure.notFound());
      }

      final entries = <PublicEntry>[];
      await for (final entity in directory.list(recursive: true)) {
        // The segments between the walk root and this entity's parent, which
        // is what a caller needs to address it — the absolute path is a device
        // detail no library path is allowed to carry.
        final relative = entity.path.substring(directory.path.length + 1);
        final parts = relative.split(Platform.pathSeparator);
        final parents = [...folders, ...parts.sublist(0, parts.length - 1)];

        final entry = _entryFor(entity, parents);
        if (entry != null) entries.add(entry);
      }
      return Result<List<PublicEntry>>.success(entries);
    } on Object catch (error) {
      return Result<List<PublicEntry>>.failure(mapFileSystemError(error));
    }
  }

  @override
  Future<Result<void>> createFolder(List<String> folders) async {
    final invalid = _firstInvalidSegment(folders);
    if (invalid != null) {
      return Result<void>.failure(
        Failure.validation(
          issue: ValidationIssue.illegalName,
          debugDetail: 'illegal folder segment "$invalid"',
        ),
      );
    }

    try {
      await _directoryFor(folders).create(recursive: true);
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(mapFileSystemError(error));
    }
  }

  @override
  Future<Result<void>> deleteFolder(List<String> folders) async {
    try {
      final directory = _directoryFor(folders);
      // Already-absent is success: removal has to be idempotent so a retry
      // after a partial failure can complete.
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(mapFileSystemError(error));
    }
  }

  @override
  Future<Result<void>> renameFolder(
    List<String> folders,
    String newName,
  ) async {
    if (!LibraryPath.isValidName(newName)) {
      return Result<void>.failure(
        Failure.validation(
          issue: ValidationIssue.illegalName,
          debugDetail: 'illegal folder name "$newName"',
        ),
      );
    }
    if (folders.isEmpty) {
      return const Result<void>.failure(
        Failure.validation(
          issue: ValidationIssue.illegalName,
          debugDetail: 'the library root cannot be renamed',
        ),
      );
    }

    try {
      final source = _directoryFor(folders);
      if (!source.existsSync()) {
        return const Result<void>.failure(Failure.notFound());
      }

      final destination = _directoryFor([
        ...folders.sublist(0, folders.length - 1),
        newName,
      ]);
      await source.rename(destination.path);
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(mapFileSystemError(error));
    }
  }

  @override
  Future<Result<String>> writeFile(LibraryPath path, String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) {
        return const Result<String>.failure(Failure.notFound());
      }

      final destination = _fileFor(path);
      // Synchronous: `Directory.exists` is the slow async form the analyzer
      // warns about, and creating a directory is cheap enough that the await
      // costs more than the call.
      destination.parent.createSync(recursive: true);
      await source.copy(destination.path);
      return Result<String>.success(destination.path);
    } on Object catch (error) {
      return Result<String>.failure(mapFileSystemError(error));
    }
  }

  @override
  Future<Result<String>> materialise(LibraryPath path) async {
    final file = _fileFor(path);
    // Nothing to materialise: the file already has a path every plugin can
    // read. The Android store is where this method earns its keep.
    if (!file.existsSync()) {
      return const Result<String>.failure(Failure.notFound());
    }
    return Result<String>.success(file.path);
  }

  @override
  Future<Result<void>> releaseMaterialised(LibraryPath path) async =>
      // A no-op: nothing was copied, so there is nothing to release.
      const Result<void>.success(null);

  @override
  Future<Result<void>> rename(LibraryPath from, LibraryPath to) async {
    try {
      final source = _fileFor(from);
      if (!source.existsSync()) {
        return const Result<void>.failure(Failure.notFound());
      }

      final destination = _fileFor(to);
      destination.parent.createSync(recursive: true);
      await source.rename(destination.path);
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(mapFileSystemError(error));
    }
  }

  @override
  Future<Result<void>> delete(LibraryPath path) async {
    try {
      final file = _fileFor(path);
      if (file.existsSync()) await file.delete();
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(mapFileSystemError(error));
    }
  }

  @override
  Future<Result<bool>> exists(LibraryPath path) async {
    try {
      return Result<bool>.success(_fileFor(path).existsSync());
    } on Object catch (error) {
      return Result<bool>.failure(mapFileSystemError(error));
    }
  }

  @override
  Future<Result<int>> totalBytes() async {
    try {
      if (!_root.existsSync()) return const Result<int>.success(0);

      var total = 0;
      await for (final entity in _root.list(recursive: true)) {
        if (entity is File) total += await entity.length();
      }
      return Result<int>.success(total);
    } on Object catch (error) {
      return Result<int>.failure(mapFileSystemError(error));
    }
  }

  /// The directory for [folders], without creating it.
  Directory _directoryFor(List<String> folders) =>
      folders.isEmpty ? _root : Directory([_root.path, ...folders].join('/'));

  /// The file at [path], without creating it.
  File _fileFor(LibraryPath path) =>
      File([_root.path, ...path.folders, path.fileName].join('/'));

  /// Builds an entry for [entity], or null when it should not be listed.
  ///
  /// Dot-files are skipped: they are the platform's own bookkeeping — the
  /// `.DS_Store` an iOS file provider leaves behind, for one — and surfacing
  /// them as documents would put junk in the user's library.
  PublicEntry? _entryFor(FileSystemEntity entity, List<String> folders) {
    final name = entity.path.split(Platform.pathSeparator).last;
    if (name.startsWith('.')) return null;

    if (entity is Directory) {
      return PublicEntry(
        kind: PublicEntryKind.folder,
        name: name,
        folders: List.unmodifiable(folders),
      );
    }
    if (entity is File) {
      // Synchronous by design: the async form spawns a worker per call, and a
      // recursive walk of a large library makes one call per file. See
      // `avoid_slow_async_io`, which recommends exactly this.
      final stat = entity.statSync();
      return PublicEntry(
        kind: PublicEntryKind.file,
        name: name,
        folders: List.unmodifiable(folders),
        sizeBytes: stat.size,
        modifiedAt: stat.modified,
      );
    }
    // A link or a socket: not something the library can represent.
    return null;
  }

  /// The first segment of [folders] that is not a legal name, or null.
  String? _firstInvalidSegment(List<String> folders) {
    for (final folder in folders) {
      if (!LibraryPath.isValidName(folder)) return folder;
    }
    return null;
  }
}

/// Maps a filesystem error onto the project's failure vocabulary.
///
/// A full disk is distinguished from other I/O errors because the specs require
/// a specific message and a "free up space" recovery for it, which a generic
/// storage failure cannot offer. Shared with the Android store, whose channel
/// surfaces the same errno.
Failure mapFileSystemError(Object error) {
  if (error is InvalidLibraryPath) {
    return Failure.validation(
      issue: ValidationIssue.illegalName,
      debugDetail: '$error',
    );
  }
  if (error is FileSystemException) {
    // errno 28 (ENOSPC) on both Android and iOS.
    if (error.osError?.errorCode == 28) {
      return Failure.storageFull(debugDetail: '$error');
    }
    // errno 2 (ENOENT): the file was removed between the check and the use,
    // which happens routinely now that the folder is user-visible.
    if (error.osError?.errorCode == 2) {
      return Failure.notFound(debugDetail: '$error');
    }
    return Failure.storage(debugDetail: '$error');
  }
  return Failure.unexpected(debugDetail: '$error');
}
