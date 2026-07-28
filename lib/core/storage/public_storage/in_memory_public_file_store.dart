/// An in-memory [PublicFileStore] for previews, goldens and tests.
///
/// Ships in `lib/` rather than in `test/` for the same reason the other fakes
/// in `core/previews/` do: a `@Preview()` has to construct one, and a preview
/// cannot import a test file. Nothing here touches the filesystem, the platform
/// or the clock, so a golden rendered over it is byte-stable.
library;

import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/public_storage/public_file_store.dart';

/// A library folder held entirely in memory.
class InMemoryPublicFileStore implements PublicFileStore {
  /// Creates an empty store.
  InMemoryPublicFileStore({this.materialisedPathPrefix = '/fake/library'});

  /// What [materialise] prefixes returned paths with.
  ///
  /// Fixed rather than a temporary directory so a golden that renders a path
  /// produces the same bytes on every machine.
  final String materialisedPathPrefix;

  /// File contents by library path.
  final Map<String, String> files = {};

  /// Folders that exist, by relative path.
  final Set<String> folderPaths = {''};

  /// A failure the next operation should return, for exercising error paths.
  ///
  /// One-shot: consumed by whichever operation runs next. Use [failures] when
  /// the test means a *specific* operation to fail, which is usually what it
  /// means — the first store call an operation makes is rarely the interesting
  /// one.
  Failure? nextFailure;

  /// Failures keyed by method name, returned every time that method is called.
  final Map<String, Failure> failures = {};

  /// Paths currently materialised, so a test can assert they were released.
  final Set<String> materialised = {};

  Result<T>? _pendingFailure<T>([String? method]) {
    final configured = method == null ? null : failures[method];
    if (configured != null) return Result<T>.failure(configured);

    final failure = nextFailure;
    if (failure == null) return null;
    nextFailure = null;
    return Result<T>.failure(failure);
  }

  @override
  Future<Result<void>> initialise() async =>
      _pendingFailure<void>('initialise') ?? const Result<void>.success(null);

  @override
  Future<Result<List<PublicEntry>>> list(List<String> folders) async {
    final pending = _pendingFailure<List<PublicEntry>>('list');
    if (pending != null) return pending;

    final prefix = folders.join('/');
    if (!folderPaths.contains(prefix)) {
      return const Result<List<PublicEntry>>.failure(Failure.notFound());
    }

    return Result<List<PublicEntry>>.success([
      for (final folder in folderPaths)
        if (folder.isNotEmpty && _isChildOf(folder, prefix))
          PublicEntry(
            kind: PublicEntryKind.folder,
            name: folder.split('/').last,
            folders: List.unmodifiable(folders),
          ),
      for (final entry in files.entries)
        if (_folderOf(entry.key) == prefix)
          PublicEntry(
            kind: PublicEntryKind.file,
            name: entry.key.split('/').last,
            folders: List.unmodifiable(folders),
            sizeBytes: entry.value.length,
            modifiedAt: DateTime.utc(2026),
          ),
    ]);
  }

  @override
  Future<Result<List<PublicEntry>>> listRecursive(List<String> folders) async {
    final pending = _pendingFailure<List<PublicEntry>>('listRecursive');
    if (pending != null) return pending;

    final prefix = folders.join('/');
    return Result<List<PublicEntry>>.success([
      for (final folder in folderPaths)
        if (folder.isNotEmpty && folder.startsWith(prefix))
          PublicEntry(
            kind: PublicEntryKind.folder,
            name: folder.split('/').last,
            folders: List.unmodifiable(_segmentsOf(folder)),
          ),
      for (final entry in files.entries)
        if (entry.key.startsWith(prefix))
          PublicEntry(
            kind: PublicEntryKind.file,
            name: entry.key.split('/').last,
            folders: List.unmodifiable(_segmentsOf(_folderOf(entry.key))),
            sizeBytes: entry.value.length,
            modifiedAt: DateTime.utc(2026),
          ),
    ]);
  }

  @override
  Future<Result<void>> createFolder(List<String> folders) async {
    final pending = _pendingFailure<void>('createFolder');
    if (pending != null) return pending;

    for (final folder in folders) {
      if (!LibraryPath.isValidName(folder)) {
        return Result<void>.failure(
          Failure.validation(
            issue: ValidationIssue.illegalName,
            debugDetail: 'illegal folder segment "$folder"',
          ),
        );
      }
    }

    // Every ancestor too, so a nested create leaves a browsable tree.
    for (var depth = 1; depth <= folders.length; depth++) {
      folderPaths.add(folders.sublist(0, depth).join('/'));
    }
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> deleteFolder(List<String> folders) async {
    final pending = _pendingFailure<void>('deleteFolder');
    if (pending != null) return pending;

    final prefix = folders.join('/');
    folderPaths.removeWhere((folder) => folder.startsWith(prefix));
    files.removeWhere((path, _) => path.startsWith('$prefix/'));
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> renameFolder(
    List<String> folders,
    String newName,
  ) async {
    final pending = _pendingFailure<void>('renameFolder');
    if (pending != null) return pending;

    if (!LibraryPath.isValidName(newName) || folders.isEmpty) {
      return Result<void>.failure(
        Failure.validation(
          issue: ValidationIssue.illegalName,
          debugDetail: 'illegal folder name "$newName"',
        ),
      );
    }

    final from = folders.join('/');
    final to = [...folders.sublist(0, folders.length - 1), newName].join('/');

    for (final folder in folderPaths.toList()) {
      if (folder.startsWith(from)) {
        folderPaths
          ..remove(folder)
          ..add(folder.replaceFirst(from, to));
      }
    }
    for (final path in files.keys.toList()) {
      if (path.startsWith('$from/')) {
        files[path.replaceFirst(from, to)] = files.remove(path)!;
      }
    }
    return const Result<void>.success(null);
  }

  @override
  Future<Result<String>> writeFile(LibraryPath path, String sourcePath) async {
    final pending = _pendingFailure<String>('writeFile');
    if (pending != null) return pending;

    files[path.relative] = 'contents-of:$sourcePath';
    for (var depth = 1; depth <= path.folders.length; depth++) {
      folderPaths.add(path.folders.sublist(0, depth).join('/'));
    }
    return Result<String>.success(_materialisedPathFor(path));
  }

  @override
  Future<Result<String>> materialise(LibraryPath path) async {
    final pending = _pendingFailure<String>('materialise');
    if (pending != null) return pending;

    if (!files.containsKey(path.relative)) {
      return const Result<String>.failure(Failure.notFound());
    }
    materialised.add(path.relative);
    return Result<String>.success(_materialisedPathFor(path));
  }

  @override
  Future<Result<void>> releaseMaterialised(LibraryPath path) async {
    materialised.remove(path.relative);
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> rename(LibraryPath from, LibraryPath to) async {
    final pending = _pendingFailure<void>('rename');
    if (pending != null) return pending;

    final contents = files.remove(from.relative);
    if (contents == null) {
      return const Result<void>.failure(Failure.notFound());
    }
    files[to.relative] = contents;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> delete(LibraryPath path) async {
    final pending = _pendingFailure<void>('delete');
    if (pending != null) return pending;

    files.remove(path.relative);
    return const Result<void>.success(null);
  }

  @override
  Future<Result<bool>> exists(LibraryPath path) async =>
      _pendingFailure<bool>('exists') ??
      Result<bool>.success(files.containsKey(path.relative));

  @override
  Future<Result<int>> totalBytes() async =>
      _pendingFailure<int>('totalBytes') ??
      Result<int>.success(
        files.values.fold(0, (total, contents) => total + contents.length),
      );

  String _materialisedPathFor(LibraryPath path) =>
      '$materialisedPathPrefix/${path.relative}';

  String _folderOf(String relative) {
    final index = relative.lastIndexOf('/');
    return index < 0 ? '' : relative.substring(0, index);
  }

  List<String> _segmentsOf(String folder) =>
      folder.isEmpty ? const [] : folder.split('/');

  /// Whether [folder] sits directly inside [parent].
  bool _isChildOf(String folder, String parent) {
    if (parent.isEmpty) return !folder.contains('/');
    if (!folder.startsWith('$parent/')) return false;
    return !folder.substring(parent.length + 1).contains('/');
  }
}
