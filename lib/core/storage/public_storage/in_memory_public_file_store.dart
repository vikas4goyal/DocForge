/// An in-memory [PublicFileStore] for previews, goldens and tests.
///
/// Ships in `lib/` rather than in `test/` for the same reason the other fakes
/// in `core/previews/` do: a `@Preview()` has to construct one, and a preview
/// cannot import a test file. Nothing here touches the filesystem, the platform
/// or the clock, so a golden rendered over it is byte-stable.
library;

import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';

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
        if (folder.isNotEmpty &&
            !_isReserved(folder) &&
            _isChildOf(folder, prefix))
          PublicEntry(
            kind: PublicEntryKind.folder,
            name: folder.split('/').last,
            folders: List.unmodifiable(folders),
          ),
      for (final entry in files.entries)
        if (!_isReserved(entry.key) && _folderOf(entry.key) == prefix)
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
        if (folder.isNotEmpty &&
            !_isReserved(folder) &&
            _atOrBelow(folder, prefix))
          PublicEntry(
            kind: PublicEntryKind.folder,
            name: folder.split('/').last,
            folders: List.unmodifiable(_segmentsOf(_folderOf(folder))),
          ),
      for (final entry in files.entries)
        if (!_isReserved(entry.key) && _atOrBelow(entry.key, prefix))
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
  Future<Result<PublicTreeInventory>> inventory({
    LibraryPath? file,
    List<String>? folder,
  }) async {
    final pending = _pendingFailure<PublicTreeInventory>('inventory');
    if (pending != null) return pending;
    if ((file == null) == (folder == null)) {
      return const Result<PublicTreeInventory>.failure(
        Failure.validation(
          issue: ValidationIssue.illegalName,
          debugDetail: 'choose exactly one inventory target',
        ),
      );
    }
    if (file != null) {
      final contents = files[file.relative];
      if (contents == null) {
        return const Result<PublicTreeInventory>.failure(Failure.notFound());
      }
      return Result<PublicTreeInventory>.success(
        PublicTreeInventory(
          documentCount: file.fileName.toLowerCase().endsWith('.pdf') ? 1 : 0,
          otherFileCount: file.fileName.toLowerCase().endsWith('.pdf') ? 0 : 1,
          sizeInBytes: contents.length,
        ),
      );
    }
    final prefix = folder!.join('/');
    if (!folderPaths.contains(prefix)) {
      return const Result<PublicTreeInventory>.failure(Failure.notFound());
    }
    final matchingFiles = files.entries.where(
      (entry) => _atOrBelow(entry.key, prefix),
    );
    var documents = 0;
    var others = 0;
    var bytes = 0;
    for (final entry in matchingFiles) {
      if (entry.key.toLowerCase().endsWith('.pdf')) {
        documents++;
      } else {
        others++;
      }
      bytes += entry.value.length;
    }
    return Result<PublicTreeInventory>.success(
      PublicTreeInventory(
        documentCount: documents,
        otherFileCount: others,
        folderCount: folderPaths
            .where((path) => path != prefix && _atOrBelow(path, prefix))
            .length,
        sizeInBytes: bytes,
      ),
    );
  }

  @override
  Future<Result<void>> moveFileToTrash(String trashId, LibraryPath path) async {
    final pending = _pendingFailure<void>('moveFileToTrash');
    if (pending != null) return pending;
    final contents = files.remove(path.relative);
    if (contents == null) {
      if (files.containsKey(_trashFile(trashId, path.fileName))) {
        return const Result<void>.success(null);
      }
      return const Result<void>.failure(Failure.notFound());
    }
    _ensureTrashParents(trashId);
    files[_trashFile(trashId, path.fileName)] = contents;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> moveFolderToTrash(
    String trashId,
    List<String> folders,
  ) async {
    final pending = _pendingFailure<void>('moveFolderToTrash');
    if (pending != null) return pending;
    final source = folders.join('/');
    final name = folders.last;
    final destination = '${_trashPayload(trashId)}/$name';
    if (!folderPaths.contains(source)) {
      return folderPaths.contains(destination)
          ? const Result<void>.success(null)
          : const Result<void>.failure(Failure.notFound());
    }
    _ensureTrashParents(trashId);
    _moveTree(source, destination);
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> restoreFileFromTrash(
    String trashId,
    String originalName,
    LibraryPath destination,
  ) async {
    final pending = _pendingFailure<void>('restoreFileFromTrash');
    if (pending != null) return pending;
    final source = _trashFile(trashId, originalName);
    final contents = files.remove(source);
    if (contents == null) {
      return files.containsKey(destination.relative)
          ? const Result<void>.success(null)
          : const Result<void>.failure(Failure.notFound());
    }
    for (var depth = 1; depth <= destination.folders.length; depth++) {
      folderPaths.add(destination.folders.sublist(0, depth).join('/'));
    }
    files[destination.relative] = contents;
    _removeEmptyTrash(trashId);
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> restoreFolderFromTrash(
    String trashId,
    String originalName,
    List<String> destinationFolders,
  ) async {
    final pending = _pendingFailure<void>('restoreFolderFromTrash');
    if (pending != null) return pending;
    final source = '${_trashPayload(trashId)}/$originalName';
    final destination = destinationFolders.join('/');
    if (!folderPaths.contains(source)) {
      return folderPaths.contains(destination)
          ? const Result<void>.success(null)
          : const Result<void>.failure(Failure.notFound());
    }
    for (var depth = 1; depth < destinationFolders.length; depth++) {
      folderPaths.add(destinationFolders.sublist(0, depth).join('/'));
    }
    _moveTree(source, destination);
    _removeEmptyTrash(trashId);
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> purgeTrashPayload(String trashId) async {
    final prefix = '$publicTrashFolderName/$trashId';
    folderPaths.removeWhere((path) => _atOrBelow(path, prefix));
    files.removeWhere((path, _) => _atOrBelow(path, prefix));
    return const Result<void>.success(null);
  }

  @override
  Future<Result<bool>> trashPayloadExists(String trashId) async {
    final prefix = '$publicTrashFolderName/$trashId';
    return Result<bool>.success(
      folderPaths.any((path) => _atOrBelow(path, prefix)) ||
          files.keys.any((path) => _atOrBelow(path, prefix)),
    );
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

  bool _isReserved(String path) =>
      path == publicTrashFolderName ||
      path.startsWith('$publicTrashFolderName/');

  bool _atOrBelow(String path, String prefix) =>
      prefix.isEmpty || path == prefix || path.startsWith('$prefix/');

  String _trashPayload(String trashId) =>
      '$publicTrashFolderName/$trashId/payload';

  String _trashFile(String trashId, String name) =>
      '${_trashPayload(trashId)}/$name';

  void _ensureTrashParents(String trashId) {
    folderPaths
      ..add(publicTrashFolderName)
      ..add('$publicTrashFolderName/$trashId')
      ..add(_trashPayload(trashId));
  }

  void _moveTree(String source, String destination) {
    for (final folder in folderPaths.toList()) {
      if (_atOrBelow(folder, source)) {
        folderPaths
          ..remove(folder)
          ..add('$destination${folder.substring(source.length)}');
      }
    }
    for (final path in files.keys.toList()) {
      if (_atOrBelow(path, source)) {
        files['$destination${path.substring(source.length)}'] = files.remove(
          path,
        )!;
      }
    }
  }

  void _removeEmptyTrash(String trashId) {
    final root = '$publicTrashFolderName/$trashId';
    final occupied =
        files.keys.any((path) => _atOrBelow(path, root)) ||
        folderPaths.any((path) => path != root && _atOrBelow(path, root));
    if (!occupied) folderPaths.remove(root);
  }
}
