/// A [DocumentFileResolver] that always succeeds with a fixed path.
///
/// For previews, widget tests and Cubit tests — anything that drives a screen
/// which *has* a document rather than one that reads its bytes. Those tests
/// care that the flow reaches the share sheet or the print dialogue, not what
/// the file contains, and standing up a store for them would be scenery.
///
/// Tests that assert on bytes use a real store over a temporary directory
/// instead; this deliberately cannot fail, so it must not be used to exercise a
/// missing-file path.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';

/// Resolves every document to [path].
class FakeDocumentFileResolver implements DocumentFileResolver {
  /// Creates a resolver answering [path] for every document.
  const FakeDocumentFileResolver({this.path = '/fake/library/document.pdf'});

  /// The path every document resolves to.
  ///
  /// Fixed rather than derived from a temporary directory, so a golden that
  /// renders it produces the same bytes on every machine.
  final String path;

  @override
  Future<Result<String>> pathFor(Document document) async =>
      Result<String>.success(path);

  @override
  Future<Result<void>> release(Document document) async =>
      const Result<void>.success(null);
}
