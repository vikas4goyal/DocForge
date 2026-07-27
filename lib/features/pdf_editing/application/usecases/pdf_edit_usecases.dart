/// Use cases for editing a stored PDF.
///
/// Two families, and the difference matters at every call site:
///
/// * **In-place edits** — rotate, delete, duplicate, compress, watermark,
///   protect, remove password — replace the document's own file and update its
///   record. They go through [AtomicPdfWrite], so a failure leaves the document
///   exactly as it was.
/// * **Deriving operations** — extract, merge, split — write a *new* document
///   and leave every source untouched. Nothing is deleted, so an unwanted
///   result is a document the user can throw away rather than a change they
///   cannot undo.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/storage_keys.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/pdf_editing/application/atomic_pdf_write.dart';
import 'package:doc_forge/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_forge/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';

/// Decides where a newly derived document's file is written.
typedef DerivedPdfDestination = String Function(DocumentId id);

/// The collaborators every editing use case needs.
///
/// Grouped into one object rather than threaded through eleven constructors:
/// the set is identical for all of them, and eleven copies of the same six
/// parameters is where a mismatched wiring bug comes from.
class PdfEditContext {
  /// Creates the context.
  const PdfEditContext({
    required this.documents,
    required this.writer,
    required this.editor,
    required this.atomic,
    required this.secrets,
    required this.destination,
    required this.clock,
    required this.ids,
  });

  /// Reads the documents being edited.
  final DocumentReader documents;

  /// Writes updated and newly derived document records.
  final DocumentWriter writer;

  /// Manipulates the PDF bytes.
  final PdfEditorRepository editor;

  /// The write-verify-replace sequence.
  final AtomicPdfWrite atomic;

  /// Where a document's password lives — and the only place it ever does.
  final SecureStore secrets;

  /// Where a newly derived document's file goes.
  final DerivedPdfDestination destination;

  /// The clock supplying modified dates.
  final Clock clock;

  /// Generates identifiers for derived documents.
  final IdGenerator ids;
}

/// Shared machinery for the editing use cases.
///
/// Not a base class for the sake of one: the load-edit-record sequence is
/// identical for every in-place operation and identical again for every
/// deriving one, and writing it eleven times is how the "leaves the document
/// unchanged" guarantee comes apart on the eleventh.
abstract class PdfEditUseCase {
  /// Creates the use case over [context].
  const PdfEditUseCase(this.context);

  /// The collaborators.
  final PdfEditContext context;

  /// Loads [id], or fails.
  Future<Result<Document>> loadDocument(DocumentId id) =>
      context.documents.findById(id);

  /// Reads the stored password for [document], if it has one.
  ///
  /// Only ever from secure storage, and the value is used and dropped — it is
  /// never put on a state object, in a log line, or on the document record.
  Future<String?> passwordFor(Document document) async {
    if (!document.isProtected) return null;
    final stored = await context.secrets.read(
      SecureStorageKeys.pdfPassword(document.id.value),
    );
    // A secure store that cannot be read degrades to "no password", which the
    // engine then reports as needing one — the user is asked rather than shown
    // a storage error they can do nothing about.
    return stored.valueOrNull;
  }

  /// Replaces [document]'s file with what [produce] writes, then its record.
  ///
  /// The record is updated *after* the file is in place, so a record can never
  /// describe a file that was never written. [isProtected] carries forward
  /// unless the operation changed it.
  /// [verifyPassword] is what the *produced* file needs, which differs from
  /// the source's password precisely when the operation changed it.
  Future<Result<Document>> replaceInPlace(
    Document document,
    PdfProducer produce, {
    int? expectedPageCount,
    bool? isProtected,
    String? verifyPassword,
  }) async {
    final written = await context.atomic.write(
      document.filePath,
      produce,
      expectedPageCount: expectedPageCount,
      verifyPassword: verifyPassword,
    );

    if (written case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }

    final result = written.valueOrNull!;

    return context.writer.updateMetadata(
      document.copyWith(
        pageCount: result.pageCount,
        sizeInBytes: result.sizeInBytes,
        updatedAt: context.clock.now(),
        isProtected: isProtected ?? document.isProtected,
      ),
    );
  }

  /// Writes a new document from what [produce] writes.
  ///
  /// Mirrors the import path: the file is produced and verified first, and the
  /// record written second — and if the record cannot be written the file is
  /// removed, because without a record it is unreachable.
  Future<Result<Document>> deriveDocument({
    required String title,
    required PdfProducer produce,
    int? expectedPageCount,
    FolderId? folderId,
    String? verifyPassword,
  }) async {
    final id = DocumentId(context.ids.generate());
    final path = context.destination(id);

    final written = await context.atomic.write(
      path,
      produce,
      expectedPageCount: expectedPageCount,
      verifyPassword: verifyPassword,
    );

    if (written case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }

    final result = written.valueOrNull!;
    final now = context.clock.now();

    final saved = await context.writer.save(
      Document(
        id: id,
        title: title,
        createdAt: now,
        updatedAt: now,
        pageCount: result.pageCount,
        sizeInBytes: result.sizeInBytes,
        filePath: result.filePath,
        folderId: folderId,
      ),
      const [],
    );

    if (saved case Failed(:final failure)) {
      final orphan = File(result.filePath);
      if (orphan.existsSync()) orphan.deleteSync();
      return Result<Document>.failure(failure);
    }

    return saved;
  }
}

/// Rotates one page a quarter turn clockwise.
class RotatePage extends PdfEditUseCase {
  /// Creates the use case.
  const RotatePage(super.context);

  /// Rotates zero-based [page] of [id].
  ///
  /// The page count is asserted to be unchanged, which is the spec's stated
  /// property for a rotation and the thing an engine bug would break silently.
  Future<Result<Document>> call(DocumentId id, int page) async {
    final found = await loadDocument(id);
    if (found case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }
    final document = found.valueOrNull!;
    final password = await passwordFor(document);

    return replaceInPlace(
      document,
      (destination) => context.editor.rotatePage(
        document.filePath,
        destination,
        page: page,
        degrees: 90,
        password: password,
      ),
      expectedPageCount: document.pageCount,
      verifyPassword: password,
    );
  }
}

/// Removes pages from a document.
class DeletePages extends PdfEditUseCase {
  /// Creates the use case.
  const DeletePages(super.context);

  /// Deletes the zero-based [pages] from [id].
  ///
  /// Refused before anything is written when it would empty the document — the
  /// spec's rule, and refusing up front means there is nothing to roll back.
  Future<Result<Document>> call(DocumentId id, Set<int> pages) async {
    final found = await loadDocument(id);
    if (found case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }
    final document = found.valueOrNull!;

    if (!PdfEditRules.canDelete(pages, pageCount: document.pageCount)) {
      return const Result<Document>.failure(PdfEditRules.wouldEmptyDocument);
    }

    final remaining = PdfEditRules.pagesAfterDeleting(
      pages,
      pageCount: document.pageCount,
    );
    final password = await passwordFor(document);

    return replaceInPlace(
      document,
      (destination) => context.editor.writePages(
        document.filePath,
        destination,
        remaining,
        password: password,
      ),
      expectedPageCount: remaining.length,
      verifyPassword: password,
    );
  }
}

/// Inserts a copy of a page immediately after it.
class DuplicatePage extends PdfEditUseCase {
  /// Creates the use case.
  const DuplicatePage(super.context);

  /// Duplicates zero-based [page] of [id].
  Future<Result<Document>> call(DocumentId id, int page) async {
    final found = await loadDocument(id);
    if (found case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }
    final document = found.valueOrNull!;

    if (page < 0 || page >= document.pageCount) {
      return const Result<Document>.failure(Failure.notFound());
    }

    final pages = PdfEditRules.pagesAfterDuplicating(
      page,
      pageCount: document.pageCount,
    );
    final password = await passwordFor(document);

    return replaceInPlace(
      document,
      (destination) => context.editor.writePages(
        document.filePath,
        destination,
        pages,
        password: password,
      ),
      expectedPageCount: document.pageCount + 1,
      verifyPassword: password,
    );
  }
}

/// Creates a new document from selected pages, leaving the source untouched.
class ExtractPages extends PdfEditUseCase {
  /// Creates the use case.
  const ExtractPages(super.context);

  /// Extracts the zero-based [pages] of [id] into a new document.
  Future<Result<Document>> call(DocumentId id, Set<int> pages) async {
    if (pages.isEmpty) {
      return const Result<Document>.failure(Failure.notFound());
    }

    final found = await loadDocument(id);
    if (found case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }
    final document = found.valueOrNull!;

    // Document order, not tap order: a selection made bottom-up would
    // otherwise produce a document whose pages run backwards.
    final ordered = PdfEditRules.orderedSelection(pages);
    final password = await passwordFor(document);

    return deriveDocument(
      title: PdfEditRules.extractedTitle(document.title, ordered.length),
      folderId: document.folderId,
      expectedPageCount: ordered.length,
      // An extracted document inherits its source's encryption, so verifying
      // it needs the same password.
      verifyPassword: password,
      produce: (destination) => context.editor.writePages(
        document.filePath,
        destination,
        ordered,
        password: password,
      ),
    );
  }
}

/// Joins several documents into a new one.
class MergeDocuments extends PdfEditUseCase {
  /// Creates the use case.
  const MergeDocuments(super.context);

  /// Merges [ids] in the order given.
  ///
  /// The order of [ids] *is* the order of the result — the list the user
  /// reordered on screen is passed straight through, which is the whole of the
  /// "merge order is user-controlled" requirement.
  Future<Result<Document>> call(List<DocumentId> ids) async {
    final documents = <Document>[];

    for (final id in ids) {
      final found = await loadDocument(id);
      if (found case Failed(:final failure)) {
        return Result<Document>.failure(failure);
      }
      documents.add(found.valueOrNull!);
    }

    if (!PdfEditRules.canMerge(documents)) {
      return const Result<Document>.failure(
        Failure.validation(issue: ValidationIssue.emptyName),
      );
    }

    final expected = documents.fold(0, (sum, d) => sum + d.pageCount);

    return deriveDocument(
      title: PdfEditRules.mergedTitle(documents),
      folderId: documents.first.folderId,
      expectedPageCount: expected,
      produce: (destination) => context.editor.merge([
        for (final document in documents) document.filePath,
      ], destination),
    );
  }
}

/// Divides a document into two new documents.
class SplitDocument extends PdfEditUseCase {
  /// Creates the use case.
  const SplitDocument(super.context);

  /// Splits [id] after one-based page [afterPage].
  ///
  /// Returns both halves. The source is left alone: the spec makes replacing it
  /// the user's separate choice, and a split that quietly consumed the original
  /// would be unrecoverable if they split at the wrong page.
  Future<Result<(Document, Document)>> call(
    DocumentId id, {
    required int afterPage,
  }) async {
    final found = await loadDocument(id);
    if (found case Failed(:final failure)) {
      return Result<(Document, Document)>.failure(failure);
    }
    final document = found.valueOrNull!;

    if (!PdfEditRules.canSplit(afterPage, pageCount: document.pageCount)) {
      return const Result<(Document, Document)>.failure(
        Failure.validation(issue: ValidationIssue.documentWouldHaveNoPages),
      );
    }

    final ranges = PdfEditRules.splitRanges(
      afterPage,
      pageCount: document.pageCount,
    );
    final titles = PdfEditRules.splitTitles(document.title);
    final password = await passwordFor(document);

    final first = await deriveDocument(
      title: titles.first,
      folderId: document.folderId,
      expectedPageCount: ranges.first.length,
      verifyPassword: password,
      produce: (destination) => context.editor.writePages(
        document.filePath,
        destination,
        ranges.first,
        password: password,
      ),
    );
    if (first case Failed(:final failure)) {
      return Result<(Document, Document)>.failure(failure);
    }

    final second = await deriveDocument(
      title: titles.second,
      folderId: document.folderId,
      expectedPageCount: ranges.second.length,
      verifyPassword: password,
      produce: (destination) => context.editor.writePages(
        document.filePath,
        destination,
        ranges.second,
        password: password,
      ),
    );

    if (second case Failed(:final failure)) {
      // The first half is removed rather than left as a document the user did
      // not ask for and cannot easily connect to what they did.
      await _discard(first.valueOrNull!);
      return Result<(Document, Document)>.failure(failure);
    }

    return Result<(Document, Document)>.success((
      first.valueOrNull!,
      second.valueOrNull!,
    ));
  }

  /// Removes a half that was created before the other one failed.
  Future<void> _discard(Document document) async {
    final file = File(document.filePath);
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } on Object {
        // Best-effort; the record is what makes it visible, and reporting a
        // cleanup failure would replace the real reason for the failure.
      }
    }
  }
}

/// The outcome of compressing a document.
class CompressionOutcome {
  /// Creates an outcome.
  const CompressionOutcome({
    required this.document,
    required this.originalBytes,
    required this.newBytes,
    required this.wasKept,
  });

  /// The document, unchanged when [wasKept] is false.
  final Document document;

  /// The size before compression.
  final int originalBytes;

  /// The size the compressed result came out at.
  final int newBytes;

  /// Whether the compressed result was kept.
  final bool wasKept;

  /// How the change is reported to the user.
  String get message => PdfEditRules.sizeChangeMessage(
    originalBytes: originalBytes,
    newBytes: newBytes,
  );
}

/// Re-encodes a document to make it smaller.
class CompressDocument extends PdfEditUseCase {
  /// Creates the use case.
  const CompressDocument(super.context);

  /// Compresses [id], reporting the size change.
  ///
  /// The result is written beside the original and measured *before* anything
  /// is replaced. A rewrite can legitimately come out larger — re-encoding
  /// already-optimal images adds overhead — and the spec requires the original
  /// to be kept in that case, which is only possible if the decision happens
  /// before the replace rather than after it.
  Future<Result<CompressionOutcome>> call(DocumentId id) async {
    final found = await loadDocument(id);
    if (found case Failed(:final failure)) {
      return Result<CompressionOutcome>.failure(failure);
    }
    final document = found.valueOrNull!;
    final password = await passwordFor(document);

    final candidatePath = '${document.filePath}.compressed';
    final produced = await context.editor.compress(
      document.filePath,
      candidatePath,
      password: password,
    );

    final candidate = File(candidatePath);

    if (produced case Failed(:final failure)) {
      if (candidate.existsSync()) candidate.deleteSync();
      return Result<CompressionOutcome>.failure(failure);
    }

    if (!candidate.existsSync()) {
      return const Result<CompressionOutcome>.failure(
        Failure.pdf(debugDetail: 'compression produced no file'),
      );
    }

    final originalBytes = document.sizeInBytes;
    final newBytes = candidate.lengthSync();

    if (!PdfEditRules.compressionWorthKeeping(
      originalBytes: originalBytes,
      compressedBytes: newBytes,
    )) {
      candidate.deleteSync();
      return Result<CompressionOutcome>.success(
        CompressionOutcome(
          document: document,
          originalBytes: originalBytes,
          newBytes: newBytes,
          wasKept: false,
        ),
      );
    }

    final replaced = await replaceInPlace(document, (destination) async {
      candidate.renameSync(destination);
      return const Result<void>.success(null);
    }, expectedPageCount: document.pageCount);

    if (replaced case Failed(:final failure)) {
      if (candidate.existsSync()) candidate.deleteSync();
      return Result<CompressionOutcome>.failure(failure);
    }

    return Result<CompressionOutcome>.success(
      CompressionOutcome(
        document: replaced.valueOrNull!,
        originalBytes: originalBytes,
        newBytes: newBytes,
        wasKept: true,
      ),
    );
  }
}

/// Stamps text across every page of a document.
class WatermarkDocument extends PdfEditUseCase {
  /// Creates the use case.
  const WatermarkDocument(super.context);

  /// Applies [text] to every page of [id].
  Future<Result<Document>> call(DocumentId id, String text) async {
    if (!PdfEditRules.isValidWatermark(text)) {
      return const Result<Document>.failure(
        Failure.validation(issue: ValidationIssue.emptyName),
      );
    }

    final found = await loadDocument(id);
    if (found case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }
    final document = found.valueOrNull!;
    final password = await passwordFor(document);

    return replaceInPlace(
      document,
      (destination) => context.editor.watermark(
        document.filePath,
        destination,
        text: text.trim(),
        password: password,
      ),
      expectedPageCount: document.pageCount,
      verifyPassword: password,
    );
  }
}

/// Protects a document with a password.
class ProtectDocument extends PdfEditUseCase {
  /// Creates the use case.
  const ProtectDocument(super.context);

  /// Protects [id] with [password].
  ///
  /// The password is written to secure storage **only after the encrypted file
  /// is in place**. The other order would leave a stored password for a file
  /// that is not encrypted, which is worse than no record at all: the viewer
  /// would offer it and the file would not want it.
  Future<Result<Document>> call(DocumentId id, String password) async {
    if (!PdfEditRules.isValidPassword(password)) {
      return const Result<Document>.failure(
        Failure.validation(issue: ValidationIssue.emptyName),
      );
    }

    final found = await loadDocument(id);
    if (found case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }
    final document = found.valueOrNull!;

    final replaced = await replaceInPlace(
      document,
      (destination) => context.editor.protect(
        document.filePath,
        destination,
        password: password,
      ),
      expectedPageCount: document.pageCount,
      isProtected: true,
      // The produced file needs the *new* password, which the source did not
      // have. Verifying with the source's would fail every time.
      verifyPassword: password,
    );

    if (replaced case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }

    final stored = await context.secrets.write(
      SecureStorageKeys.pdfPassword(id.value),
      password,
    );

    // A secret that could not be stored is not fatal: the file is protected and
    // the user knows the password. They will simply be asked for it.
    if (stored case Failed()) {
      return replaced;
    }

    return replaced;
  }
}

/// Removes a document's password.
class RemoveDocumentPassword extends PdfEditUseCase {
  /// Creates the use case.
  const RemoveDocumentPassword(super.context);

  /// Removes protection from [id] using [currentPassword].
  ///
  /// A wrong password leaves the document entirely unchanged — the file, the
  /// record and the stored secret — and returns an authentication failure the
  /// UI turns into "that password did not work" with a retry.
  Future<Result<Document>> call(DocumentId id, String currentPassword) async {
    final found = await loadDocument(id);
    if (found case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }
    final document = found.valueOrNull!;

    final replaced = await replaceInPlace(
      document,
      (destination) => context.editor.removePassword(
        document.filePath,
        destination,
        currentPassword: currentPassword,
      ),
      expectedPageCount: document.pageCount,
      isProtected: false,
      // The produced file needs no password at all — that is the point of the
      // operation — so it is verified without one.
    );

    if (replaced case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }

    // Deleted only once the file genuinely opens without it. Deleting first
    // would strand a still-encrypted document with no password anywhere.
    await context.secrets.delete(SecureStorageKeys.pdfPassword(id.value));

    return replaced;
  }
}

/// Reads a document's metadata.
class ReadPdfMetadata extends PdfEditUseCase {
  /// Creates the use case.
  const ReadPdfMetadata(super.context);

  /// Returns the metadata of [id].
  ///
  /// Read from the document record rather than from the file: the record is
  /// what the library shows everywhere else, and a metadata view that disagreed
  /// with the list it was opened from would be reporting a bug rather than
  /// information.
  Future<Result<PdfMetadata>> call(DocumentId id) async {
    final found = await loadDocument(id);
    if (found case Failed(:final failure)) {
      return Result<PdfMetadata>.failure(failure);
    }
    final document = found.valueOrNull!;

    return Result<PdfMetadata>.success(
      PdfMetadata(
        title: document.title,
        pageCount: document.pageCount,
        sizeInBytes: document.sizeInBytes,
        createdAt: document.createdAt,
        updatedAt: document.updatedAt,
        isProtected: document.isProtected,
      ),
    );
  }
}
