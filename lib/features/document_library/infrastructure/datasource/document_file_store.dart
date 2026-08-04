/// The on-disk layout for document files.
///
/// Binary content — page images, thumbnails and the generated PDF — lives on
/// the filesystem, never in Isar. A database holding blobs bloats, slows every
/// query and complicates backup, so Isar stores only paths.
///
/// Layout:
///
/// ```
/// <appDocuments>/documents/.layout-version   ← marker file
/// <appDocuments>/documents/<documentId>/document.pdf
/// <appDocuments>/documents/<documentId>/pages/<pageId>.jpg
/// <appDocuments>/documents/<documentId>/thumbnails/<pageId>.jpg
/// ```
///
/// Everything sits under the app's private documents directory, which other
/// applications cannot read — the local-only storage guarantee depends on it.
/// The marker file lets a future release detect an older layout and migrate it
/// rather than losing references.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/document_file_store.dart';

/// A [DocumentFileStore] over the real filesystem.
class LocalDocumentFileStore implements DocumentFileStore {
  /// Creates a store rooted at [_appDocumentsDirectory].
  ///
  /// The directory is resolved once by the composition root rather than looked
  /// up per call, so no ambient path lookup happens inside a repository.
  const LocalDocumentFileStore(this._appDocumentsDirectory);

  final Directory _appDocumentsDirectory;

  /// Version of the on-disk layout this build writes.
  static const layoutVersion = 1;

  /// Name of the file recording the layout version.
  static const markerFileName = '.layout-version';

  /// Name of the directory holding every document.
  static const documentsDirectoryName = 'documents';

  /// Root directory holding every document's files.
  Directory get _root =>
      Directory('${_appDocumentsDirectory.path}/$documentsDirectoryName');

  @override
  Future<Result<Directory>> initialise() async {
    try {
      await _root.create(recursive: true);

      final marker = File('${_root.path}/$markerFileName');
      if (!marker.existsSync()) {
        await marker.writeAsString('$layoutVersion');
      }

      return Result<Directory>.success(_root);
    } on Object catch (error) {
      return Result<Directory>.failure(_mapError(error));
    }
  }

  @override
  Future<Result<Directory>> directoryFor(DocumentId id) async {
    try {
      final directory = Directory('${_root.path}/${id.value}');
      await directory.create(recursive: true);
      return Result<Directory>.success(directory);
    } on Object catch (error) {
      return Result<Directory>.failure(_mapError(error));
    }
  }

  @override
  Future<Result<String>> pdfPathFor(DocumentId id) async {
    final directory = await directoryFor(id);
    return directory.map((d) => '${d.path}/document.pdf');
  }

  @override
  Future<Result<String>> pagePathFor(DocumentId documentId, PageId pageId) =>
      _pathInSubdirectory(documentId, 'pages', pageId);

  @override
  Future<Result<String>> thumbnailPathFor(
    DocumentId documentId,
    PageId pageId,
  ) => _pathInSubdirectory(documentId, 'thumbnails', pageId);

  @override
  Future<Result<void>> deleteDocument(DocumentId id) async {
    try {
      final directory = Directory('${_root.path}/${id.value}');
      // Already-absent is success: permanent removal has to be idempotent so a
      // retry after a partial failure can complete.
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(_mapError(error));
    }
  }

  @override
  Future<Result<void>> copyDocument(DocumentId from, DocumentId to) async {
    try {
      final source = Directory('${_root.path}/${from.value}');
      if (!source.existsSync()) {
        return const Result<void>.failure(Failure.notFound());
      }

      final destination = Directory('${_root.path}/${to.value}');
      await destination.create(recursive: true);

      await for (final entity in source.list(recursive: true)) {
        final relative = entity.path.substring(source.path.length + 1);
        final target = '${destination.path}/$relative';

        if (entity is Directory) {
          await Directory(target).create(recursive: true);
        } else if (entity is File) {
          await Directory(target).parent.create(recursive: true);
          await entity.copy(target);
        }
      }

      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(_mapError(error));
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
      return Result<int>.failure(_mapError(error));
    }
  }

  /// Builds a path inside a per-document subdirectory, creating it if needed.
  Future<Result<String>> _pathInSubdirectory(
    DocumentId documentId,
    String subdirectory,
    PageId pageId,
  ) async {
    try {
      final directory = Directory(
        '${_root.path}/${documentId.value}/$subdirectory',
      );
      await directory.create(recursive: true);
      return Result<String>.success('${directory.path}/${pageId.value}.jpg');
    } on Object catch (error) {
      return Result<String>.failure(_mapError(error));
    }
  }

  /// Maps a filesystem error onto the project's failure vocabulary.
  ///
  /// A full disk is distinguished from other I/O errors because the specs
  /// require a specific message and a "free up space" recovery for it, which a
  /// generic storage failure cannot offer.
  static Failure _mapError(Object error) {
    if (error is FileSystemException) {
      // errno 28 (ENOSPC) on both Android and iOS.
      if (error.osError?.errorCode == 28) {
        return Failure.storageFull(debugDetail: '$error');
      }
      return Failure.storage(debugDetail: '$error');
    }
    return Failure.unexpected(debugDetail: '$error');
  }
}
