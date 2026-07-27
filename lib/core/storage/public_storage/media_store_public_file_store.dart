/// A [PublicFileStore] over Android's MediaStore.
///
/// Scoped storage forbids writing arbitrary paths into shared `Documents/`, so
/// every operation crosses a [MediaStoreChannel] and files are addressed by
/// content URI rather than by path. Since `pdfrx`, `pdf_manipulator` and
/// `printing` all require a real path, `materialise` copies an item into the
/// cache and hands back the copy — see `design.md` D3.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/public_storage/media_store_channel.dart';
import 'package:doc_forge/core/storage/public_storage/public_file_store.dart';

/// The user-visible library folder, backed by MediaStore.
class MediaStorePublicFileStore implements PublicFileStore {
  /// Creates a store over [channel], caching materialised copies in
  /// [cacheDirectory].
  MediaStorePublicFileStore({
    required this.channel,
    required this.cacheDirectory,
    this.collection = defaultCollection,
    this.libraryFolderName = defaultLibraryFolderName,
    this.materialisedCacheLimit = defaultMaterialisedCacheLimit,
  });

  /// The shared collection the library folder sits in.
  static const defaultCollection = 'Documents';

  /// The name of the library folder as the user sees it in a file manager.
  static const defaultLibraryFolderName = 'DocForge';

  /// How many materialised copies are kept before the oldest is evicted.
  ///
  /// A cap rather than unbounded growth: a session of opening documents would
  /// otherwise leave a cached copy of every one of them, which on a large
  /// library is most of the library duplicated.
  static const defaultMaterialisedCacheLimit = 8;

  /// The bridge to the Android host.
  ///
  /// Injected rather than constructed here so a test can assert exactly which
  /// MediaStore arguments were sent without a device.
  final MediaStoreChannel channel;

  /// Where copies made by `materialise` are written.
  final Directory cacheDirectory;

  /// The shared collection, e.g. `Documents`.
  final String collection;

  /// The library folder's name.
  final String libraryFolderName;

  /// The materialised-copy cache limit.
  final int materialisedCacheLimit;

  /// Paths materialised so far, least recently used first.
  ///
  /// An instance field rather than a static, so two stores in a test cannot
  /// interfere and nothing here is global mutable state.
  final List<LibraryPath> _materialised = [];

  /// Whether this device refused a nested `RELATIVE_PATH`.
  ///
  /// Latched after the first refusal so the fallback is taken directly rather
  /// than re-attempting the nested insert on every later save. Some OEM builds
  /// reject an insert naming a folder below the collection; the specs require
  /// the document be saved flat in that case rather than the save failing.
  bool _nestedFoldersUnsupported = false;

  /// Whether this device is known not to support nested folders.
  ///
  /// Exposed so the presentation layer can tell the user where a file actually
  /// landed, which the specs require.
  bool get nestedFoldersUnsupported => _nestedFoldersUnsupported;

  @override
  Future<Result<void>> initialise() => _guard(() async {
    await channel.createFolder(_relativePathFor(const []));
  });

  @override
  Future<Result<List<PublicEntry>>> list(List<String> folders) => _guardValue(
    () async {
      final items = await channel.list(_relativePathFor(folders));
      final folderNames = await channel.listFolders(_relativePathFor(folders));

      return [
        for (final name in folderNames)
          PublicEntry(
            kind: PublicEntryKind.folder,
            name: name,
            folders: List.unmodifiable(folders),
          ),
        for (final item in items)
          if (!item.displayName.startsWith('.'))
            PublicEntry(
              kind: PublicEntryKind.file,
              name: item.displayName,
              folders: List.unmodifiable(folders),
              sizeBytes: item.sizeBytes,
              modifiedAt: item.modifiedAt,
            ),
      ];
    },
  );

  @override
  Future<Result<List<PublicEntry>>> listRecursive(List<String> folders) =>
      _guardValue(() async {
        final items = await channel.list(
          _relativePathFor(folders),
          recursive: true,
        );

        final entries = <PublicEntry>[];
        final seenFolders = <String>{};

        for (final item in items) {
          if (item.displayName.startsWith('.')) continue;

          final segments = _segmentsOf(item.relativePath);
          entries.add(
            PublicEntry(
              kind: PublicEntryKind.file,
              name: item.displayName,
              folders: List.unmodifiable(segments),
              sizeBytes: item.sizeBytes,
              modifiedAt: item.modifiedAt,
            ),
          );

          // MediaStore has no folder rows, so every ancestor is inferred from
          // the paths of the files inside it. Without this a nested folder
          // would never appear in the reconciler's view of the tree.
          for (var depth = folders.length; depth < segments.length; depth++) {
            final parents = segments.sublist(0, depth);
            final name = segments[depth];
            if (seenFolders.add([...parents, name].join('/'))) {
              entries.add(
                PublicEntry(
                  kind: PublicEntryKind.folder,
                  name: name,
                  folders: List.unmodifiable(parents),
                ),
              );
            }
          }
        }

        return entries;
      });

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

    return _guard(() async {
      try {
        await channel.createFolder(_relativePathFor(folders));
      } on MediaStoreException catch (error) {
        if (!error.isNestedFolderUnsupported || folders.isEmpty) rethrow;
        // The device will not create a folder below the collection. Latch it
        // and succeed: the specs require the document to be saved flat with
        // its intended folder kept in the index, not the operation to fail.
        _nestedFoldersUnsupported = true;
      }
    });
  }

  @override
  Future<Result<void>> deleteFolder(List<String> folders) =>
      _guard(() => channel.deleteFolder(_relativePathFor(folders)));

  @override
  Future<Result<void>> renameFolder(List<String> folders, String newName) {
    if (!LibraryPath.isValidName(newName)) {
      return Future.value(
        Result<void>.failure(
          Failure.validation(
            issue: ValidationIssue.illegalName,
            debugDetail: 'illegal folder name "$newName"',
          ),
        ),
      );
    }
    if (folders.isEmpty) {
      return Future.value(
        const Result<void>.failure(
          Failure.validation(
            issue: ValidationIssue.illegalName,
            debugDetail: 'the library root cannot be renamed',
          ),
        ),
      );
    }

    return _guard(
      () => channel.renameFolder(_relativePathFor(folders), newName),
    );
  }

  @override
  Future<Result<String>> writeFile(LibraryPath path, String sourcePath) =>
      _guardValue(() async {
        final folders = _effectiveFolders(path.folders);
        await channel.writeFile(
          relativePath: _relativePathFor(folders),
          displayName: path.fileName,
          sourcePath: sourcePath,
        );
        // The caller gets a readable path, exactly as the filesystem store
        // would return, so no consumer has to know which store it holds.
        final materialised = await materialise(path);
        return materialised.valueOrNull ?? sourcePath;
      });

  @override
  Future<Result<String>> materialise(LibraryPath path) => _guardValue(() async {
    final destination = _cachePathFor(path);
    await channel.copyToCache(
      relativePath: _relativePathFor(_effectiveFolders(path.folders)),
      displayName: path.fileName,
      destinationPath: destination,
    );

    _materialised
      ..remove(path)
      ..add(path);
    await _evictMaterialisedBeyondLimit();

    return destination;
  });

  @override
  Future<Result<void>> releaseMaterialised(LibraryPath path) async {
    _materialised.remove(path);
    try {
      final file = File(_cachePathFor(path));
      if (file.existsSync()) await file.delete();
      return const Result<void>.success(null);
    } on Object catch (error) {
      // A cache copy that will not delete is not worth failing an operation
      // for: the OS reclaims the cache directory under pressure anyway.
      return Result<void>.failure(Failure.storage(debugDetail: '$error'));
    }
  }

  @override
  Future<Result<void>> rename(LibraryPath from, LibraryPath to) => _guard(
    () async {
      await channel.moveFile(
        fromRelativePath: _relativePathFor(_effectiveFolders(from.folders)),
        fromDisplayName: from.fileName,
        toRelativePath: _relativePathFor(_effectiveFolders(to.folders)),
        toDisplayName: to.fileName,
      );
      // The cached copy is now named after a file that no longer exists there.
      await releaseMaterialised(from);
    },
  );

  @override
  Future<Result<void>> delete(LibraryPath path) => _guard(() async {
    await channel.deleteFile(
      relativePath: _relativePathFor(_effectiveFolders(path.folders)),
      displayName: path.fileName,
    );
    await releaseMaterialised(path);
  });

  @override
  Future<Result<bool>> exists(LibraryPath path) => _guardValue(
    () => channel.exists(
      relativePath: _relativePathFor(_effectiveFolders(path.folders)),
      displayName: path.fileName,
    ),
  );

  @override
  Future<Result<int>> totalBytes() => _guardValue(() async {
    final items = await channel.list(
      _relativePathFor(const []),
      recursive: true,
    );
    return items.fold<int>(0, (total, item) => total + item.sizeBytes);
  });

  /// The MediaStore `RELATIVE_PATH` for [folders], with a trailing separator.
  String _relativePathFor(List<String> folders) =>
      '${[collection, libraryFolderName, ...folders].join('/')}/';

  /// Splits a MediaStore relative path back into library folder segments.
  List<String> _segmentsOf(String relativePath) {
    final parts = [
      for (final part in relativePath.split('/'))
        if (part.isNotEmpty) part,
    ];
    // Drop the collection and the library folder; what remains addresses the
    // entry inside the library, which is all a LibraryPath may carry.
    return parts.length <= 2 ? const [] : parts.sublist(2);
  }

  /// The folders to write to, honouring the flat fallback.
  ///
  /// When the device refused a nested folder, everything is written into the
  /// library root; the folder the user chose is still recorded in the index, so
  /// the dashboard shows the document where they put it.
  List<String> _effectiveFolders(List<String> folders) =>
      _nestedFoldersUnsupported ? const [] : folders;

  /// Where a materialised copy of [path] lives.
  ///
  /// Named from the full relative path rather than the file name alone, so two
  /// documents of the same name in different folders cannot collide.
  String _cachePathFor(LibraryPath path) {
    final key = path.relative.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');
    return '${cacheDirectory.path}/materialised/$key';
  }

  /// Deletes the oldest materialised copies beyond the cache limit.
  Future<void> _evictMaterialisedBeyondLimit() async {
    while (_materialised.length > materialisedCacheLimit) {
      final oldest = _materialised.removeAt(0);
      final file = File(_cachePathFor(oldest));
      if (file.existsSync()) await file.delete();
    }
  }

  /// The first segment of [folders] that is not a legal name, or null.
  String? _firstInvalidSegment(List<String> folders) {
    for (final folder in folders) {
      if (!LibraryPath.isValidName(folder)) return folder;
    }
    return null;
  }

  /// Runs [action], mapping any platform refusal onto a [Failure].
  Future<Result<void>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(mapMediaStoreError(error));
    }
  }

  /// Runs [action] and wraps its value, mapping any platform refusal.
  Future<Result<T>> _guardValue<T>(Future<T> Function() action) async {
    try {
      return Result<T>.success(await action());
    } on Object catch (error) {
      return Result<T>.failure(mapMediaStoreError(error));
    }
  }
}

/// Maps a MediaStore or I/O error onto the project's failure vocabulary.
///
/// Kept beside the store rather than inside the channel so the channel stays a
/// transport concern and the failure vocabulary stays a domain one.
Failure mapMediaStoreError(Object error) {
  if (error is MediaStoreException) {
    if (error.isStorageFull) {
      return Failure.storageFull(debugDetail: '$error');
    }
    if (error.isNotFound) {
      return Failure.notFound(debugDetail: '$error');
    }
    return Failure.storage(debugDetail: '$error');
  }
  if (error is InvalidLibraryPath) {
    return Failure.validation(
      issue: ValidationIssue.illegalName,
      debugDetail: '$error',
    );
  }
  if (error is FileSystemException) {
    if (error.osError?.errorCode == 28) {
      return Failure.storageFull(debugDetail: '$error');
    }
    return Failure.storage(debugDetail: '$error');
  }
  return Failure.unexpected(debugDetail: '$error');
}
