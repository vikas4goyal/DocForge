/// Turns a document's library address into a path a plugin can read.
///
/// [Document.libraryPath] is an address, not a device path — the same value
/// resolves to a real file on iOS and to a MediaStore item on Android. Every
/// consumer that needs actual bytes (the viewer, sharing, printing, editing)
/// goes through this rather than reading a path off the record, which is what
/// stops the platform difference reaching a use case (`design.md` D2).
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';

/// Resolves readable paths for documents.
///
/// An interface rather than the store itself so a use case declares the narrow
/// thing it needs, and so a test can hand one a fixed path without standing up
/// a filesystem.
abstract interface class DocumentFileResolver {
  /// Returns a readable device path for [document]'s PDF.
  ///
  /// On Android this may copy the file into the cache, so callers should
  /// [release] it when they are finished. Fails with `Failure.notFound` when
  /// the file is no longer there — which is now an ordinary occurrence, since
  /// the user can delete it from their file browser while the app is open.
  Future<Result<String>> pathFor(Document document);

  /// Releases a path previously returned by [pathFor].
  ///
  /// A no-op on iOS. Callers should not treat a failure here as fatal: a cache
  /// copy that will not delete is reclaimed by the operating system anyway.
  Future<Result<void>> release(Document document);
}

/// Ensures cloud-backed bytes are readable before a resolver exposes a path.
typedef EnsureReadableDocument =
    Future<Result<void>> Function(
      Document document, {
      void Function(double progress)? onProgress,
    });

/// A resolver decorator that lazily materialises remote iCloud documents.
///
/// Composition installs this only for the iOS iCloud authority. Android and
/// local iOS continue to use [PublicStoreDocumentFileResolver] directly.
class DownloadAwareDocumentFileResolver implements DocumentFileResolver {
  /// Creates a resolver around [delegate].
  const DownloadAwareDocumentFileResolver({
    required this.delegate,
    required this.ensureReadable,
    this.onProgress,
  });

  /// Resolves the final device-readable path.
  final DocumentFileResolver delegate;

  /// Materialises remote bytes when needed.
  final EnsureReadableDocument ensureReadable;

  /// Optional operation progress observer.
  final void Function(Document document, double progress)? onProgress;

  @override
  Future<Result<String>> pathFor(Document document) async {
    if (document.contentAvailability == DocumentContentAvailability.remote ||
        document.contentAvailability ==
            DocumentContentAvailability.downloading ||
        document.contentAvailability == DocumentContentAvailability.failed) {
      final ensured = await ensureReadable(
        document,
        onProgress: (progress) => onProgress?.call(document, progress),
      );
      if (ensured case Failed(:final failure)) {
        return Result<String>.failure(failure);
      }
    }
    return delegate.pathFor(document);
  }

  @override
  Future<Result<void>> release(Document document) => delegate.release(document);
}

/// A [DocumentFileResolver] over a [PublicFileStore].
class PublicStoreDocumentFileResolver implements DocumentFileResolver {
  /// Creates a resolver over [store].
  const PublicStoreDocumentFileResolver(this.store);

  /// The store documents are addressed in.
  final PublicFileStore store;

  @override
  Future<Result<String>> pathFor(Document document) =>
      store.materialise(document.libraryPath);

  @override
  Future<Result<void>> release(Document document) =>
      store.releaseMaterialised(document.libraryPath);
}
