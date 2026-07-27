/// Turns a document's library address into a path a plugin can read.
///
/// [Document.libraryPath] is an address, not a device path — the same value
/// resolves to a real file on iOS and to a MediaStore item on Android. Every
/// consumer that needs actual bytes (the viewer, sharing, printing, editing)
/// goes through this rather than reading a path off the record, which is what
/// stops the platform difference reaching a use case (`design.md` D2).
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/public_storage/public_file_store.dart';

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
