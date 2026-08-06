/// Cross-feature access to scanned and PDF-backed document pages.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/document_page_handle.dart';
import 'package:doc_scanly/core/failures/result.dart';

/// Enumerates, renders, and reads text from document pages offline.
abstract interface class DocumentPageAccessRepository {
  /// Returns every page of [document] in document order.
  ///
  /// Stored image rows are preferred when present. A PDF without page rows is
  /// represented by deterministic virtual handles derived from its page count.
  Future<Result<List<DocumentPageHandle>>> pagesOf(Document document);

  /// Materialises [page] for [purpose].
  ///
  /// Returns an authoritative, cached, or temporary readable path. Callers
  /// must pass temporary results to [release] after their platform or OCR
  /// consumer has finished. Failures are typed and never thrown across this
  /// boundary.
  Future<Result<MaterializedDocumentPage>> materialize(
    Document document,
    DocumentPageHandle page,
    DocumentPageRenderPurpose purpose,
  );

  /// Returns embedded PDF text for [page], or successful null when absent.
  ///
  /// Stored-image pages always return null so the caller can choose on-device
  /// OCR. Protected PDF credentials are resolved inside the implementation.
  Future<Result<String?>> embeddedText(
    Document document,
    DocumentPageHandle page,
  );

  /// Releases a temporary [page] after its consumer has completed.
  ///
  /// Authoritative and reusable cached results are a successful no-op. Cleanup
  /// failure is returned for diagnostics but must not erase a successful share
  /// or recognition outcome.
  Future<Result<void>> release(MaterializedDocumentPage page);
}
