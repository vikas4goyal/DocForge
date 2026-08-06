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

/// A document ready to be displayed.
class ViewableDocument {
  /// Creates a viewable document.
  const ViewableDocument({
    required this.document,
    required this.filePath,
    required this.pageCount,
    this.password,
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

  /// Whether the file is password-protected.
  bool get isProtected => password != null;
}

/// Opens a document for viewing.
///
/// A protected document is opened with the password held in secure storage when
/// one is there, so a document the user protected on this device opens without
/// asking again. When there is none, or it no longer works, the caller is told
/// authentication is needed and prompts.
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
  /// [password] is what the user has just typed, when they have. It takes
  /// precedence over anything stored, because a user retyping a password is
  /// correcting something.
  Future<Result<ViewableDocument>> call(
    DocumentId id, {
    String? password,
  }) async {
    final found = await _documents.findById(id);

    return found.flatMapAsync((document) async {
      final stored = password ?? await _storedPassword(id);

      // The document is addressed by library path, not by device path: on
      // Android the file is a MediaStore item and the renderer needs a real
      // path, so it is materialised here and released when the viewer closes.
      final resolved = await _files.pathFor(document);
      if (resolved case Failed(:final failure)) {
        return Result<ViewableDocument>.failure(failure);
      }

      final opened = await _renderer.open(
        resolved.valueOrNull!,
        password: stored,
      );

      return opened.map(
        (opened) => ViewableDocument(
          document: document,
          filePath: resolved.valueOrNull!,
          pageCount: opened.pageCount,
          password: opened.isProtected ? stored : null,
        ),
      );
    });
  }

  /// The stored password for [id], or null.
  ///
  /// A secure store that cannot be read degrades to "no stored password", which
  /// prompts the user rather than failing the open: being asked for a password
  /// is recoverable, being unable to open your own document is not.
  Future<String?> _storedPassword(DocumentId id) async {
    final result = await _secrets.read(SecureStorageKeys.pdfPassword(id.value));
    return result.valueOrNull;
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
  Future<Result<void>> call(DocumentId id, String password) =>
      _secrets.write(SecureStorageKeys.pdfPassword(id.value), password);
}

/// Loads a document's recognised text for the viewer's text panel.
class LoadViewerText {
  /// Creates the use case.
  const LoadViewerText(this._text);

  final OcrTextSource _text;

  /// Returns the document's recognised text, or an empty string.
  ///
  /// A failure degrades to empty rather than propagating: the viewer's job is
  /// to show the document, and missing text must not stop it.
  Future<String> call(DocumentId id) async {
    final result = await _text.textForDocument(id);
    return result.valueOrNull ?? '';
  }
}

/// The failure a locked document produces.
///
/// Exposed so the viewer and its previews agree on what "needs a password"
/// looks like without either constructing it inline.
const documentLockedFailure = Failure.auth();
