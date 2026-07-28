/// Keeps the index in step with the library folder.
///
/// The folder is the user's now: they can add, rename and delete files in it
/// from their file browser while the application is running. Reconciliation is
/// what makes those changes appear inside the app rather than leaving it
/// showing documents that are not there (`design.md` D5).
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/public_file_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/domain/library_reconciliation.dart';
import 'package:doc_forge/features/document_library/domain/repositories/library_repositories.dart';

/// Reads the page count of a PDF, so a newly discovered file can be indexed.
///
/// A function rather than the renderer itself: the library has no business
/// depending on the viewer, and this is the only thing it needs from one.
typedef PdfPageCountReader =
    Future<Result<int>> Function(String filePath, {String? password});

/// What a reconcile run changed.
class ReconcileOutcome {
  /// Creates an outcome.
  const ReconcileOutcome({
    this.diff = const LibraryDiff(),
    this.skipped = false,
  });

  /// What the diff found.
  final LibraryDiff diff;

  /// Whether the run was throttled away without walking the tree.
  final bool skipped;

  /// Whether anything was actually applied.
  bool get changedAnything => !skipped && !diff.isEmpty;
}

/// Reconciles the index with the library folder.
class ReconcileLibrary {
  /// Creates the use case.
  const ReconcileLibrary({
    required this.store,
    required this.documents,
    required this.pages,
    required this.preferences,
    required this.clock,
    required this.ids,
    required this.pageCountOf,
    this.throttle = defaultThrottle,
  });

  /// How long a run suppresses the next one.
  ///
  /// A resume within this window does not re-walk. Without it, switching to
  /// another application and back — which iOS does on every share sheet — would
  /// walk the whole tree each time.
  static const defaultThrottle = Duration(seconds: 60);

  /// The preference recording when the tree was last walked.
  static const lastRunKey = 'library.reconcile.lastRunAt';

  /// The user-visible library folder being reconciled against.
  final PublicFileStore store;

  /// The index being brought back into step with it.
  final DocumentRepository documents;

  /// Page rows, removed alongside a document whose file is gone.
  final PageRepository pages;

  /// Where the last run's timestamp is kept, so resume can be throttled.
  final PreferenceStore preferences;

  /// Supplies the timestamps the throttle compares.
  final Clock clock;

  /// Generates identifiers for files discovered from outside the application.
  final IdGenerator ids;

  /// Reads the page count of a newly discovered file.
  final PdfPageCountReader pageCountOf;

  /// How long a run suppresses the next.
  final Duration throttle;

  /// Reconciles, unless a run happened within [throttle].
  ///
  /// [force] runs regardless, which is what a pull-to-refresh means.
  Future<Result<ReconcileOutcome>> call({bool force = false}) async {
    if (!force && await _isThrottled()) {
      return const Result<ReconcileOutcome>.success(
        ReconcileOutcome(skipped: true),
      );
    }

    final walked = await store.listRecursive(const []);
    if (walked case Failed(:final failure)) {
      return Result<ReconcileOutcome>.failure(failure);
    }

    final indexed = await documents.query();
    if (indexed case Failed(:final failure)) {
      return Result<ReconcileOutcome>.failure(failure);
    }

    final entries = walked.valueOrNull!;
    final diff = LibraryReconciliation.diff(
      indexed: indexed.valueOrNull!,
      found: [
        for (final entry in entries)
          if (!entry.isFolder && _isPdf(entry.name))
            LibraryFile(
              path: entry.path!,
              sizeBytes: entry.sizeBytes,
              modifiedAt: entry.modifiedAt,
            ),
      ],
      folders: [
        for (final entry in entries)
          if (entry.isFolder) entry.folderSegments.join('/'),
      ],
    );

    await _apply(diff);
    await _recordRun();

    return Result<ReconcileOutcome>.success(ReconcileOutcome(diff: diff));
  }

  /// Writes the diff into the index.
  Future<void> _apply(LibraryDiff diff) async {
    final now = clock.now().toUtc();

    for (final rename in diff.renamed) {
      await documents.save(LibraryReconciliation.applyRename(rename));
    }

    for (final change in diff.modified) {
      await documents.save(
        LibraryReconciliation.applyModification(change, now),
      );
    }

    for (final document in diff.removed) {
      // Page rows go with the record. Recognised text and any stored password
      // are removed by the purge path; here the file is already gone, so there
      // is nothing to delete from the folder.
      await pages.deleteForDocument(document.id);
      await documents.delete(document.id);
    }

    for (final file in diff.added) {
      await _index(file, now);
    }
  }

  /// Indexes a file that appeared in the folder from outside the application.
  Future<void> _index(LibraryFile file, DateTime now) async {
    final resolved = await store.materialise(file.path);
    if (resolved case Failed()) return;

    final counted = await pageCountOf(resolved.valueOrNull!);
    await store.releaseMaterialised(file.path);

    // A file that will not open is left unindexed rather than recorded as a
    // zero-page document: it is still in the user's folder, and the next run
    // will try again once whatever wrote it has finished.
    if (counted case Failed()) return;

    await documents.save(
      Document(
        id: DocumentId(ids.generate()),
        title: file.path.baseName,
        createdAt: file.modifiedAt ?? now,
        updatedAt: file.modifiedAt ?? now,
        pageCount: counted.valueOrNull!,
        sizeInBytes: file.sizeBytes,
        libraryPath: file.path,
      ),
    );
  }

  /// Whether a run happened recently enough to skip this one.
  Future<bool> _isThrottled() async {
    final stored = await preferences.readString(lastRunKey);
    final last = stored.valueOrNull;
    if (last == null) return false;

    final parsed = DateTime.tryParse(last);
    if (parsed == null) return false;

    return clock.now().toUtc().difference(parsed.toUtc()) < throttle;
  }

  Future<void> _recordRun() => preferences.writeString(
    lastRunKey,
    clock.now().toUtc().toIso8601String(),
  );

  /// Whether a file name is one the library represents.
  ///
  /// Only PDFs. The user's folder may hold anything they put there, and a text
  /// file listed as a document would be one they could not open.
  static bool _isPdf(String name) => name.toLowerCase().endsWith('.pdf');
}
