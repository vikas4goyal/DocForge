/// The seams between capabilities.
///
/// Features genuinely need each other — the viewer needs a document, search
/// needs OCR text, scanning hands pages to PDF generation — but a direct import
/// between two features is forbidden and enforced by `tool/check_layering.dart`.
/// Each seam is therefore an interface declared here, implemented by the owning
/// feature's infrastructure, and injected into the consuming feature's use case
/// by the composition root (`design.md` §2).
///
/// Every method returns a [Result] rather than throwing, so a consumer cannot
/// ignore the failure path of a capability it does not own.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/failures/result.dart';

/// Read access to stored documents.
///
/// Implemented by `document-library`. Consumed by the viewer, sharing, import,
/// PDF editing and PDF generation.
abstract interface class DocumentReader {
  /// Returns the document identified by [id].
  ///
  /// Fails with a not-found failure when no such document exists, which the
  /// router surfaces as the not-found state rather than crashing.
  Future<Result<Document>> findById(DocumentId id);

  /// Returns documents matching [filter], ordered by [sort].
  ///
  /// [folderId] is required when [filter] is [DocumentFilter.folder] and
  /// ignored otherwise. [limit] and [offset] drive incremental loading, so a
  /// library of several thousand documents never loads at once.
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  });

  /// Returns the pages of the document identified by [id], in page order.
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id);
}

/// Write access to stored documents.
///
/// Implemented by `document-library`. Consumed by PDF generation, import and
/// PDF editing — the capabilities that create or replace document content.
abstract interface class DocumentWriter {
  /// Persists [document] and its [pages], creating or replacing the record.
  Future<Result<Document>> save(Document document, List<DocumentPage> pages);

  /// Updates the metadata of an existing document.
  ///
  /// Refreshes the modified date; the creation date is never changed.
  Future<Result<Document>> updateMetadata(Document document);
}

/// Read access to folders.
///
/// Implemented by `document-library`. Consumed by the home shell and search.
abstract interface class FolderReader {
  /// Returns every folder with its current document count.
  Future<Result<List<Folder>>> all();

  /// Returns the folder identified by [id].
  Future<Result<Folder>> findById(FolderId id);
}

/// Access to recognised page text.
///
/// Implemented by `ocr`. Consumed by search, which indexes it, and by sharing,
/// which exports it.
abstract interface class OcrTextSource {
  /// Returns the stored recognition result for [pageId], if one exists.
  ///
  /// A page that has never been recognised yields a successful null rather than
  /// a failure — absence is a normal state, not an error.
  Future<Result<RecognisedText?>> textForPage(PageId pageId);

  /// Returns the combined recognised text of every page of [documentId].
  Future<Result<String>> textForDocument(DocumentId documentId);
}

/// Turns captured or imported pages into a stored document.
///
/// Implemented by `pdf-generation`. Consumed by scanning and import, so neither
/// needs to know how a PDF is composed.
abstract interface class PageBundleSink {
  /// Builds and stores a document from [bundle].
  ///
  /// [title] overrides the default naming pattern when supplied. Recognition
  /// failure never prevents the document being created — a PDF without a text
  /// layer is still a valid document.
  Future<Result<Document>> createDocument(
    ScannedPageBundle bundle, {
    String? title,
  });
}

/// Reports how much storage the library consumes.
///
/// Implemented by `document-library`. Consumed by the home shell and settings.
abstract interface class StorageSummaryReader {
  /// Returns the current storage summary.
  Future<Result<StorageSummary>> summary();
}

/// Decides whether the application is currently locked.
///
/// Implemented by `app-security`. Consumed by the router, which checks it
/// before any route builds so no document content renders behind the lock
/// screen (`design.md` §8).
abstract interface class AppLockGate {
  /// Whether the lock is enabled and the session is not yet authenticated.
  ///
  /// Synchronous because the router redirect runs on every navigation and
  /// cannot await; the underlying state is loaded once at startup and updated
  /// on authentication and on resume from background.
  bool get isLocked;

  /// Emits whenever the locked state changes, so the router can re-evaluate.
  Stream<bool> get lockChanges;
}

/// Reports whether first-launch onboarding has been completed.
///
/// Implemented by `onboarding`. Consumed by the router's onboarding gate.
abstract interface class OnboardingGate {
  /// Whether onboarding still needs to be shown.
  bool get needsOnboarding;

  /// Emits whenever onboarding completion changes.
  Stream<bool> get onboardingChanges;
}
