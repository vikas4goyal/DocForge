/// Use cases for the document viewer.
library;

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/document_viewer/domain/repositories/pdf_renderer.dart';

/// Loads current metadata for the document identified by [id].
///
/// Returns the stored [Document], or a typed failure when it is unavailable.
/// The function boundary lets Viewer receive library behavior without importing
/// another feature.
typedef LoadViewerMetadata = Future<Result<Document>> Function(DocumentId id);

/// Toggles favourite state for the document identified by [id].
///
/// Returns the updated [Document], or a typed persistence failure. The app
/// composition root adapts the library use case to this viewer-owned contract.
typedef ToggleViewerFavourite =
    Future<Result<Document>> Function(DocumentId id);

/// A document ready to be displayed.
class ViewableDocument {
  /// Creates a viewable document.
  const ViewableDocument({
    required this.document,
    required this.filePath,
    required this.pageCount,
    this.password,
    this.passwordRemembered = false,
  });

  /// The document's metadata.
  final Document document;

  /// A readable device path for the opened file.
  ///
  /// Resolved when the document was opened rather than read off the record:
  /// [Document.libraryPath] is an address, and on Android the readable path is
  /// a cache copy that only exists while the document is open.
  final String filePath;

  /// How many pages the file actually contains.
  ///
  /// Taken from the opened file rather than from the record, because the two
  /// can disagree after an edit and the file is the truth about what will be
  /// rendered.
  final int pageCount;

  /// The password the file was opened with, when it needed one.
  ///
  /// Held only for as long as the viewer is on screen, and never written
  /// anywhere by this layer.
  final String? password;

  /// Whether automatic unlocking was explicitly enabled for this document.
  final bool passwordRemembered;

  /// Whether the file is password-protected.
  bool get isProtected => password != null;
}

/// Opens a document for viewing.
///
/// A protected document requires an entered password unless the user explicitly
/// opted into automatic unlocking for this document.
///
/// Editing workflows may retain a credential in secure storage so they can
/// safely transform encrypted bytes, but viewing is an access boundary: a
/// stored credential must never silently reveal the document or its pages.
class OpenDocumentForViewing {
  /// Creates the use case.
  const OpenDocumentForViewing(
    this._documents,
    this._renderer,
    this._secrets,
    this._files,
  );

  final DocumentReader _documents;
  final PdfRenderer _renderer;
  final SecureStore _secrets;
  final DocumentFileResolver _files;

  /// Opens the document identified by [id].
  ///
  /// [password] is what the user has just typed. A protected document returns
  /// an authentication failure until one is supplied.
  Future<Result<ViewableDocument>> call(
    DocumentId id, {
    String? password,
  }) async {
    final found = await _documents.findById(id);

    return found.flatMapAsync((document) async {
      final remembered = password == null && document.isProtected
          ? await _rememberedPassword(id)
          : null;
      final offered = password ?? remembered;
      if (document.isProtected && offered == null) {
        return const Result<ViewableDocument>.failure(documentLockedFailure);
      }

      // The document is addressed by library path, not by device path: on
      // Android the file is a MediaStore item and the renderer needs a real
      // path, so it is materialised here and released when the viewer closes.
      final resolved = await _files.pathFor(document);
      if (resolved case Failed(:final failure)) {
        return Result<ViewableDocument>.failure(failure);
      }

      final opened = await _renderer.open(
        resolved.valueOrNull!,
        password: offered,
      );

      return opened.map(
        (opened) => ViewableDocument(
          document: document,
          filePath: resolved.valueOrNull!,
          pageCount: opened.pageCount,
          password: opened.isProtected ? offered : null,
          passwordRemembered: opened.isProtected && remembered != null,
        ),
      );
    });
  }

  Future<String?> _rememberedPassword(DocumentId id) async {
    final consent = await _secrets.read(
      SecureStorageKeys.pdfPasswordRemembered(id.value),
    );
    if (consent.valueOrNull != 'true') return null;
    return (await _secrets.read(
      SecureStorageKeys.pdfPassword(id.value),
    )).valueOrNull;
  }
}

/// Remembers a password the user has just entered.
///
/// Secure storage only — never preferences, never the database, never a log.
/// Called after a successful unlock so the user is not asked again on this
/// device.
class RememberDocumentPassword {
  /// Creates the use case.
  const RememberDocumentPassword(this._secrets);

  final SecureStore _secrets;

  /// Stores [password] against [id].
  ///
  /// A failure is returned rather than swallowed, but the caller treats it as
  /// non-fatal: the document is already open, and the only consequence is being
  /// asked again next time.
  Future<Result<void>> call(
    DocumentId id,
    String password, {
    bool autoUnlock = true,
  }) async {
    final saved = await _secrets.write(
      SecureStorageKeys.pdfPassword(id.value),
      password,
    );
    if (saved case Failed(:final failure)) return Result<void>.failure(failure);

    final consent = autoUnlock
        ? await _secrets.write(
            SecureStorageKeys.pdfPasswordRemembered(id.value),
            'true',
          )
        : await _secrets.delete(
            SecureStorageKeys.pdfPasswordRemembered(id.value),
          );
    if (consent case Failed(:final failure)) {
      await _secrets.delete(SecureStorageKeys.pdfPassword(id.value));
      return Result<void>.failure(failure);
    }
    return const Result<void>.success(null);
  }
}

/// Deletes a document's saved automatic-unlock credential.
class ForgetDocumentPassword {
  /// Creates the use case.
  const ForgetDocumentPassword(this._secrets);

  final SecureStore _secrets;

  /// Forgets both the secret and the automatic-unlock consent marker.
  Future<Result<void>> call(DocumentId id) async {
    final password = await _secrets.delete(
      SecureStorageKeys.pdfPassword(id.value),
    );
    final consent = await _secrets.delete(
      SecureStorageKeys.pdfPasswordRemembered(id.value),
    );
    if (password case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    return consent;
  }
}

/// The failure a locked document produces.
///
/// Exposed so the viewer and its previews agree on what "needs a password"
/// looks like without either constructing it inline.
const documentLockedFailure = Failure.auth();
