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

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_editing/application/atomic_pdf_write.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';

/// Produces a PDF at [destinationPath] from the file at [sourcePath].
///
/// Two paths rather than one because a document is no longer addressed by a
/// device path: the source is materialised from the library on demand, and on
/// Android that is a cache copy whose location the use case cannot predict.
typedef PdfEditProducer =
    Future<Result<void>> Function(String sourcePath, String destinationPath);

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
    required this.store,
    required this.files,
    required this.workingDirectory,
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

  /// The user-visible library every edit reads from and writes back to.
  final PublicFileStore store;

  /// Resolves readable bytes, including lazy iCloud download when installed.
  final DocumentFileResolver files;

  /// Where an edit's working file is written before it is published.
  ///
  /// Private cache, not the library folder: a half-written PDF must never be
  /// visible to the user's file browser, and on Android the library is not a
  /// directory a file can be written into by path at all.
  final Directory workingDirectory;

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

  /// Returns a readable path for [document]'s current file.
  ///
  /// The file lives in the user-visible library, which on Android is not
  /// reachable by path, so it is materialised into the cache first. Callers
  /// release it through [releaseSource] once the edit is done.
  Future<Result<String>> sourcePathFor(Document document) =>
      context.files.pathFor(document);

  /// Releases a path returned by [sourcePathFor].
  Future<void> releaseSource(Document document) async {
    await context.files.release(document);
  }

  /// A private working path an edit can write to before publishing.
  String workingPathFor(DocumentId id) =>
      '${context.workingDirectory.path}/${id.value}.edit.pdf';

  /// Deletes a working file, ignoring a failure to do so.
  ///
  /// Best-effort: the file is in the cache, which the operating system
  /// reclaims anyway, and reporting a cleanup failure would replace the real
  /// reason an operation failed.
  void discardWorkingFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } on Object {
      // Intentionally ignored; see above.
    }
  }

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
    PdfEditProducer produce, {
    int? expectedPageCount,
    bool? isProtected,
    String? verifyPassword,
  }) async {
    final source = await sourcePathFor(document);
    if (source case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }

    final working = workingPathFor(document.id);

    final written = await context.atomic.write(
      working,
      (destination) => produce(source.valueOrNull!, destination),
      expectedPageCount: expectedPageCount,
      verifyPassword: verifyPassword,
    );

    if (written case Failed(:final failure)) {
      discardWorkingFile(working);
      return Result<Document>.failure(failure);
    }

    final result = written.valueOrNull!;

    // Published only after the working file has been written *and* verified,
    // so the file the user can see in their file browser is never a partial
    // one — the same guarantee the atomic rename gave when the library was a
    // private directory.
    final published = await context.store.writeFile(
      document.libraryPath,
      result.filePath,
    );
    discardWorkingFile(working);
    await releaseSource(document);

    if (published case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }

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
    required Future<Result<void>> Function(String destinationPath) produce,
    int? expectedPageCount,
    FolderId? folderId,
    List<String> folders = const [],
    String? verifyPassword,
    bool isProtected = false,
    String? storedPassword,
  }) async {
    final id = DocumentId(context.ids.generate());
    final working = workingPathFor(id);

    final written = await context.atomic.write(
      working,
      produce,
      expectedPageCount: expectedPageCount,
      verifyPassword: verifyPassword,
    );

    if (written case Failed(:final failure)) {
      discardWorkingFile(working);
      return Result<Document>.failure(failure);
    }

    final result = written.valueOrNull!;
    final now = context.clock.now();

    // The derived document lands beside its source in the library, under a
    // name taken from its title, de-duplicated against what is already there
    // so a second extract does not overwrite the first.
    final libraryPath = await _availablePathFor(title, folders);
    if (libraryPath case Failed(:final failure)) {
      discardWorkingFile(working);
      return Result<Document>.failure(failure);
    }

    final published = await context.store.writeFile(
      libraryPath.valueOrNull!,
      result.filePath,
    );
    discardWorkingFile(working);

    if (published case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }

    final saved = await context.writer.save(
      Document(
        id: id,
        title: title,
        createdAt: now,
        updatedAt: now,
        pageCount: result.pageCount,
        sizeInBytes: result.sizeInBytes,
        libraryPath: libraryPath.valueOrNull!,
        folderId: folderId,
        isProtected: isProtected,
      ),
      const [],
    );

    if (saved case Failed(:final failure)) {
      // Without a record the file is unreachable from the app but *visible* in
      // the user's file browser, which is worse than not writing it at all.
      await context.store.delete(libraryPath.valueOrNull!);
      return Result<Document>.failure(failure);
    }

    if (storedPassword != null) {
      await context.secrets.write(
        SecureStorageKeys.pdfPassword(id.value),
        storedPassword,
      );
    }

    return saved;
  }

  /// A library path for [title] in [folders] that nothing already occupies.
  Future<Result<LibraryPath>> _availablePathFor(
    String title,
    List<String> folders,
  ) async {
    final existing = await context.store.list(folders);
    // Propagated, not defaulted to empty: without the listing there is no way
    // to know whether the name is free, and writing anyway would silently
    // overwrite a document the user still has.
    if (existing case Failed(:final failure)) {
      return Result<LibraryPath>.failure(failure);
    }

    final taken = <String>{
      for (final entry in existing.valueOrNull!)
        if (!entry.isFolder) entry.name,
    };

    final desired = LibraryPath.pdfFileName(LibraryPath.sanitiseName(title));

    try {
      return Result<LibraryPath>.success(
        LibraryPath.inFolder(folders, LibraryPath.deduplicate(desired, taken)),
      );
    } on InvalidLibraryPath catch (error) {
      return Result<LibraryPath>.failure(
        Failure.validation(
          issue: ValidationIssue.illegalName,
          debugDetail: '$error',
        ),
      );
    }
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
      (source, destination) => context.editor.rotatePage(
        source,
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
      (source, destination) => context.editor.writePages(
        source,
        destination,
        remaining,
        password: password,
      ),
      expectedPageCount: remaining.length,
      verifyPassword: password,
    );
  }
}

/// Moves one page to another position in the same document.
class ReorderPage extends PdfEditUseCase {
  /// Creates the use case.
  const ReorderPage(super.context);

  /// Moves zero-based [from] to [to], preserving every page exactly once.
  Future<Result<Document>> call(DocumentId id, int from, int to) async {
    final found = await loadDocument(id);
    if (found case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }
    final document = found.valueOrNull!;
    if (from < 0 ||
        from >= document.pageCount ||
        to < 0 ||
        to >= document.pageCount ||
        from == to) {
      return const Result<Document>.failure(
        Failure.notFound(debugDetail: 'invalid page move'),
      );
    }
    final order = List<int>.generate(document.pageCount, (index) => index);
    final page = order.removeAt(from);
    order.insert(to, page);
    final password = await passwordFor(document);
    return replaceInPlace(
      document,
      (source, destination) => context.editor.writePages(
        source,
        destination,
        order,
        password: password,
      ),
      expectedPageCount: document.pageCount,
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
      (source, destination) => context.editor.writePages(
        source,
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

    final source = await sourcePathFor(document);
    if (source case Failed(:final failure)) {
      return Result<Document>.failure(failure);
    }

    final derived = await deriveDocument(
      title: PdfEditRules.extractedTitle(document.title, ordered.length),
      folderId: document.folderId,
      folders: document.libraryPath.folders,
      expectedPageCount: ordered.length,
      // An extracted document inherits its source's encryption, so verifying
      // it needs the same password.
      verifyPassword: password,
      produce: (destination) => context.editor.writePages(
        source.valueOrNull!,
        destination,
        ordered,
        password: password,
      ),
    );

    await releaseSource(document);
    return derived;
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
  Future<Result<Document>> call(
    List<DocumentId> ids, {
    String? outputTitle,
  }) async {
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

    // Every source has to be readable at once, so all of them are materialised
    // before the merge and all released after it.
    final sources = <String>[];
    for (final document in documents) {
      final resolved = await sourcePathFor(document);
      if (resolved case Failed(:final failure)) {
        for (final done in documents) {
          await releaseSource(done);
        }
        return Result<Document>.failure(failure);
      }
      sources.add(resolved.valueOrNull!);
    }

    final derived = await deriveDocument(
      title: outputTitle?.trim().isNotEmpty ?? false
          ? outputTitle!.trim()
          : PdfEditRules.mergedTitle(documents),
      folderId: documents.first.folderId,
      folders: documents.first.libraryPath.folders,
      expectedPageCount: expected,
      produce: (destination) => context.editor.merge(sources, destination),
    );

    for (final document in documents) {
      await releaseSource(document);
    }

    return derived;
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
    ({String first, String second})? outputTitles,
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
    final proposedTitles =
        outputTitles ?? PdfEditRules.splitTitles(document.title);
    final titles = (
      first: proposedTitles.first.trim(),
      second: proposedTitles.second.trim(),
    );
    if (titles.first.isEmpty ||
        titles.second.isEmpty ||
        titles.first == titles.second) {
      return const Result<(Document, Document)>.failure(
        Failure.validation(issue: ValidationIssue.emptyName),
      );
    }
    final password = await passwordFor(document);

    final source = await sourcePathFor(document);
    if (source case Failed(:final failure)) {
      return Result<(Document, Document)>.failure(failure);
    }
    final sourcePath = source.valueOrNull!;

    final first = await deriveDocument(
      title: titles.first,
      folderId: document.folderId,
      folders: document.libraryPath.folders,
      expectedPageCount: ranges.first.length,
      verifyPassword: password,
      produce: (destination) => context.editor.writePages(
        sourcePath,
        destination,
        ranges.first,
        password: password,
      ),
    );
    if (first case Failed(:final failure)) {
      await releaseSource(document);
      return Result<(Document, Document)>.failure(failure);
    }

    final second = await deriveDocument(
      title: titles.second,
      folderId: document.folderId,
      folders: document.libraryPath.folders,
      expectedPageCount: ranges.second.length,
      verifyPassword: password,
      produce: (destination) => context.editor.writePages(
        sourcePath,
        destination,
        ranges.second,
        password: password,
      ),
    );

    await releaseSource(document);

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
  ///
  /// Deleted from the library, not merely unrecorded: the folder is visible in
  /// the user's file browser now, so an orphaned file is something they would
  /// actually see.
  Future<void> _discard(Document document) async {
    // Best-effort; reporting a cleanup failure would replace the real reason
    // for the failure the user is being shown.
    await context.store.delete(document.libraryPath);
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
  Future<Result<CompressionOutcome>> call(
    DocumentId id, {
    bool saveAsCopy = false,
  }) async {
    final found = await loadDocument(id);
    if (found case Failed(:final failure)) {
      return Result<CompressionOutcome>.failure(failure);
    }
    final document = found.valueOrNull!;
    final password = await passwordFor(document);

    final source = await sourcePathFor(document);
    if (source case Failed(:final failure)) {
      return Result<CompressionOutcome>.failure(failure);
    }

    // Beside the materialised source in the cache, never in the library: a
    // candidate that turns out larger is thrown away, and the user must never
    // see it appear in their folder in the meantime.
    final candidatePath = '${source.valueOrNull!}.compressed';
    final produced = await context.editor.compress(
      source.valueOrNull!,
      candidatePath,
      password: password,
    );

    final candidate = File(candidatePath);

    if (produced case Failed(:final failure)) {
      if (candidate.existsSync()) candidate.deleteSync();
      await releaseSource(document);
      return Result<CompressionOutcome>.failure(failure);
    }

    if (!candidate.existsSync()) {
      await releaseSource(document);
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
      await releaseSource(document);
      return Result<CompressionOutcome>.success(
        CompressionOutcome(
          document: document,
          originalBytes: originalBytes,
          newBytes: newBytes,
          wasKept: false,
        ),
      );
    }

    if (saveAsCopy) {
      final derived = await deriveDocument(
        title: '${document.title} (compressed)',
        folderId: document.folderId,
        folders: document.libraryPath.folders,
        expectedPageCount: document.pageCount,
        verifyPassword: password,
        isProtected: document.isProtected,
        storedPassword: password,
        produce: (destination) async {
          candidate.copySync(destination);
          return const Result<void>.success(null);
        },
      );
      if (candidate.existsSync()) candidate.deleteSync();
      await releaseSource(document);
      if (derived case Failed(:final failure)) {
        return Result<CompressionOutcome>.failure(failure);
      }
      return Result<CompressionOutcome>.success(
        CompressionOutcome(
          document: derived.valueOrNull!,
          originalBytes: originalBytes,
          newBytes: newBytes,
          wasKept: true,
        ),
      );
    }

    final replaced = await replaceInPlace(document, (_, destination) async {
      candidate.renameSync(destination);
      return const Result<void>.success(null);
    }, expectedPageCount: document.pageCount);

    if (replaced case Failed(:final failure)) {
      if (candidate.existsSync()) candidate.deleteSync();
      return Result<CompressionOutcome>.failure(failure);
    }
    await releaseSource(document);

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
  Future<Result<Document>> call(
    DocumentId id,
    String text, {
    bool saveAsCopy = false,
  }) async {
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

    if (saveAsCopy) {
      final source = await sourcePathFor(document);
      if (source case Failed(:final failure)) {
        return Result<Document>.failure(failure);
      }
      final derived = await deriveDocument(
        title: '${document.title} (watermarked)',
        folderId: document.folderId,
        folders: document.libraryPath.folders,
        expectedPageCount: document.pageCount,
        verifyPassword: password,
        isProtected: document.isProtected,
        storedPassword: password,
        produce: (destination) => context.editor.watermark(
          source.valueOrNull!,
          destination,
          text: text.trim(),
          password: password,
        ),
      );
      await releaseSource(document);
      return derived;
    }

    return replaceInPlace(
      document,
      (source, destination) => context.editor.watermark(
        source,
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
      (source, destination) =>
          context.editor.protect(source, destination, password: password),
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
    // Setting or changing protection never grants automatic viewing consent.
    await context.secrets.delete(
      SecureStorageKeys.pdfPasswordRemembered(id.value),
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
      (source, destination) => context.editor.removePassword(
        source,
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
    await context.secrets.delete(
      SecureStorageKeys.pdfPasswordRemembered(id.value),
    );

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
