/// The Cubit driving the dashboard.
///
/// Reads the library folder through the store and the index through the
/// repository, and holds neither: path arithmetic lives in [LibraryPath] and
/// the folder rules in the use cases.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/trash.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/features/document_library/application/usecases/bulk_document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/application/usecases/library_folder_usecases.dart';
import 'package:doc_scanly/features/document_library/application/usecases/trash_usecases.dart';
import 'package:doc_scanly/features/document_library/domain/bulk_document_action.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the dashboard.
class DashboardCubit extends Cubit<DashboardState> {
  /// Creates the Cubit over the library folder and its index.
  DashboardCubit({
    required this.store,
    required this.index,
    this.inspectTrashCandidate,
    this.moveFolderTreeToTrash,
    this.restoreTrashEntry,
    this.renameLibraryFolder,
    this.loadTrash,
    this.bulkArchiveDocuments,
    this.bulkTrashDocuments,
  }) : super(const DashboardState.initial());

  /// The library folder being browsed.
  final PublicFileStore store;

  /// The index supplying each file's metadata.
  ///
  /// Named for what it is rather than for what it holds: the folder is the
  /// source of truth, and this describes what is in it.
  final DocumentRepository index;

  /// Measures a candidate, when recoverable deletion is enabled.
  final InspectTrashCandidate? inspectTrashCandidate;

  /// Moves a folder tree, when recoverable deletion is enabled.
  final MoveFolderTreeToTrash? moveFolderTreeToTrash;

  /// Restores a just-moved entry for Undo.
  final RestoreTrashEntry? restoreTrashEntry;

  /// Renames a real child folder.
  final RenameLibraryFolder? renameLibraryFolder;

  /// Loads the root Collections count.
  final LoadTrash? loadTrash;

  /// Archives selected documents with per-item outcomes.
  final BulkArchiveDocuments? bulkArchiveDocuments;

  /// Moves selected documents to recoverable Trash with per-item outcomes.
  final BulkTrashDocuments? bulkTrashDocuments;

  /// Enters selection mode, optionally selecting [documentId].
  void enterSelection([DocumentId? documentId]) {
    if (state.isBulkWorking) return;
    emit(
      state.copyWith(
        selectionMode: true,
        selectedDocumentIds: documentId == null ? const [] : [documentId],
        bulkStatus: DashboardBulkStatus.idle,
      ),
    );
  }

  /// Toggles [documentId] while retaining current visible-list order.
  void toggleSelection(DocumentId documentId) {
    if (state.isBulkWorking) return;
    final selected = state.selectedDocumentIds.contains(documentId);
    final ids = selected
        ? [
            for (final id in state.selectedDocumentIds)
              if (id != documentId) id,
          ]
        : [
            for (final document in state.documents)
              if (state.selectedDocumentIds.contains(document.id) ||
                  document.id == documentId)
                document.id,
          ];
    emit(state.copyWith(selectionMode: true, selectedDocumentIds: ids));
  }

  /// Selects every currently visible eligible document.
  void selectAll() {
    if (state.isBulkWorking) return;
    emit(
      state.copyWith(
        selectionMode: true,
        selectedDocumentIds: [
          for (final document in state.documents) document.id,
        ],
      ),
    );
  }

  /// Leaves selection mode without mutating a document.
  void cancelSelection() {
    if (state.isBulkWorking) return;
    emit(
      state.copyWith(
        selectionMode: false,
        selectedDocumentIds: const [],
        bulkStatus: DashboardBulkStatus.idle,
      ),
    );
  }

  /// Archives selected documents once.
  Future<void> archiveSelected() async {
    final useCase = bulkArchiveDocuments;
    if (useCase == null || state.isBulkWorking || state.selectedCount == 0) {
      return;
    }
    await _runBulk(
      DashboardBulkAction.archive,
      () =>
          useCase(BulkDocumentRequest(documentIds: state.selectedDocumentIds)),
    );
  }

  /// Retries only the documents retained after a partial failure.
  Future<void> retrySelected() async {
    switch (state.bulkAction) {
      case DashboardBulkAction.archive:
        await archiveSelected();
      case DashboardBulkAction.trash:
        await trashSelected(confirmed: true);
      case null:
        return;
    }
  }

  /// Moves selected documents to Trash after the UI's reviewed confirmation.
  Future<void> trashSelected({required bool confirmed}) async {
    final useCase = bulkTrashDocuments;
    if (useCase == null || state.isBulkWorking || state.selectedCount == 0) {
      return;
    }
    await _runBulk(
      DashboardBulkAction.trash,
      () => useCase(
        BulkDocumentRequest(
          documentIds: state.selectedDocumentIds,
          destructiveActionConfirmed: confirmed,
        ),
      ),
    );
  }

  Future<void> _runBulk(
    DashboardBulkAction action,
    Future<BulkDocumentOutcome> Function() operation,
  ) async {
    emit(
      state.copyWith(
        bulkStatus: DashboardBulkStatus.working,
        bulkAction: action,
      ),
    );
    final outcome = await operation();
    if (isClosed) return;
    final succeeded = outcome.succeeded.toSet();
    final failedIds = [for (final item in outcome.failed) item.documentId];
    emit(
      state.copyWith(
        documents: [
          for (final document in state.documents)
            if (!succeeded.contains(document.id)) document,
        ],
        recents: [
          for (final document in state.recents)
            if (!succeeded.contains(document.id)) document,
        ],
        selectionMode: failedIds.isNotEmpty,
        selectedDocumentIds: failedIds,
        bulkStatus: failedIds.isEmpty
            ? DashboardBulkStatus.idle
            : DashboardBulkStatus.partialFailure,
        bulkOutcome: failedIds.isEmpty ? null : outcome,
        bulkAction: action,
        archiveCount: action == DashboardBulkAction.archive
            ? state.archiveCount + outcome.succeeded.length
            : state.archiveCount,
        trashCount: action == DashboardBulkAction.trash
            ? state.trashCount + outcome.succeeded.length
            : state.trashCount,
      ),
    );
  }

  /// Measures the named child folder for confirmation.
  Future<Result<TrashInventory>> inspectFolder(String name) =>
      inspectFolderPath([...state.path, name]);

  /// Measures a folder at an explicit library-relative [path].
  Future<Result<TrashInventory>> inspectFolderPath(List<String> path) {
    final useCase = inspectTrashCandidate;
    if (useCase == null) {
      return Future.value(
        const Result<TrashInventory>.failure(Failure.unexpected()),
      );
    }
    return useCase(folder: path);
  }

  /// Moves the named child folder to recoverable Trash and reloads.
  Future<Result<TrashEntry>> trashFolder(String name) =>
      trashFolderPath([...state.path, name]);

  /// Moves the folder at [path] into recoverable Trash and reloads.
  Future<Result<TrashEntry>> trashFolderPath(List<String> path) async {
    final useCase = moveFolderTreeToTrash;
    if (useCase == null) {
      return const Result<TrashEntry>.failure(Failure.unexpected());
    }
    final result = await useCase(path);
    if (result.isSuccess) await load();
    return result;
  }

  /// Undoes a just-completed move to Trash.
  Future<Result<String>> undoTrash(TrashId id) async {
    final useCase = restoreTrashEntry;
    if (useCase == null) {
      return const Result<String>.failure(Failure.unexpected());
    }
    final result = await useCase(id);
    if (result.isSuccess) await load();
    return result;
  }

  /// Renames the named child folder and reloads.
  Future<Result<void>> renameFolder(String name, String newName) =>
      renameFolderPath([...state.path, name], newName);

  /// Renames the folder at [path] and reloads its parent.
  Future<Result<void>> renameFolderPath(
    List<String> path,
    String newName,
  ) async {
    final useCase = renameLibraryFolder;
    if (useCase == null) {
      return const Result<void>.failure(Failure.unexpected());
    }
    final result = await useCase(path, newName);
    if (result.isSuccess) await _loadFolder(path.sublist(0, path.length - 1));
    return result;
  }

  /// How many recent documents the strip shows.
  ///
  /// Enough to be useful, few enough that it stays a strip rather than a
  /// second document list above the first.
  static const maxRecents = 5;

  /// Loads the folder currently open.
  Future<void> load() =>
      state.isSearching ? search(state.query) : _loadFolder(state.path);

  /// Opens the child folder [name] of the folder currently open.
  Future<void> openFolder(String name) => openPath([...state.path, name]);

  /// Opens the folder at [path], relative to the library root.
  ///
  /// Used by the breadcrumb, which can jump several levels at once.
  Future<void> openPath(List<String> path) async {
    emit(
      state.copyWith(
        query: '',
        selectionMode: false,
        selectedDocumentIds: const [],
        bulkStatus: DashboardBulkStatus.idle,
      ),
    );
    await _loadFolder(path);
  }

  /// Goes up one level, or does nothing at the root.
  Future<void> goUp() async {
    if (state.isAtRoot) return;
    await openPath(state.path.sublist(0, state.path.length - 1));
  }

  /// Records a search query and shows what matches.
  ///
  /// A search spans the whole library rather than the open folder: someone who
  /// remembers a document's name rarely remembers which folder it is in, which
  /// is why they are searching.
  Future<void> search(String query) async {
    emit(state.copyWith(query: query));

    if (query.trim().isEmpty) {
      await _loadFolder(state.path);
      return;
    }

    final results = await Future.wait([
      index.query(),
      store.listRecursive(const []),
    ]);
    if (isClosed) return;

    final needle = query.trim().toLowerCase();
    final found = results[0] as Result<List<Document>>;
    final walked = results[1] as Result<List<PublicEntry>>;
    if (found case Failed(:final failure)) {
      emit(state.copyWith(status: DashboardStatus.failure, failure: failure));
      return;
    }
    if (walked case Failed(:final failure)) {
      emit(state.copyWith(status: DashboardStatus.failure, failure: failure));
      return;
    }
    final documents = [
      for (final document in found.valueOrNull ?? const <Document>[])
        if (document.isVisibleInLibrary &&
            document.title.toLowerCase().contains(needle))
          document,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final allDocuments = found.valueOrNull ?? const <Document>[];
    final folders = [
      for (final entry in walked.valueOrNull ?? const <PublicEntry>[])
        if (entry.isFolder && entry.name.toLowerCase().contains(needle))
          DashboardFolder(
            name: entry.name,
            path: entry.folderSegments,
            documentCount: _countIn(entry.folderSegments, allDocuments),
            modifiedAt: entry.modifiedAt,
          ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final visibleIds = documents.map((document) => document.id).toSet();
    final retainedSelection = [
      for (final id in state.selectedDocumentIds)
        if (visibleIds.contains(id)) id,
    ];
    emit(
      state.copyWith(
        status: DashboardStatus.ready,
        folders: folders,
        documents: documents,
        selectedDocumentIds: retainedSelection,
      ),
    );
  }

  /// Clears the search and returns to the open folder.
  Future<void> clearSearch() => search('');

  /// Reads [path]'s contents and shows them.
  Future<void> _loadFolder(List<String> path) async {
    emit(state.copyWith(status: DashboardStatus.loading, path: path));

    final listed = await store.list(path);
    if (isClosed) return;

    if (listed case Failed(:final failure)) {
      emit(state.copyWith(status: DashboardStatus.failure, failure: failure));
      return;
    }

    final indexed = await index.query();
    if (isClosed) return;

    final byPath = <String, Document>{
      for (final document in indexed.valueOrNull ?? const <Document>[])
        document.relativePath: document,
    };

    final entries = listed.valueOrNull!;
    final folders = <DashboardFolder>[];
    final documents = <Document>[];

    for (final entry in entries) {
      if (entry.isFolder) {
        folders.add(
          DashboardFolder(
            name: entry.name,
            path: [...path, entry.name],
            documentCount: _countIn([...path, entry.name], byPath.values),
            modifiedAt: entry.modifiedAt,
          ),
        );
        continue;
      }

      // A file the index has not caught up with yet is skipped rather than
      // shown as a row with no metadata: reconciliation will index it, and a
      // half-described document is worse than one that appears a moment later.
      final document =
          byPath[LibraryPath.raw(folders: path, fileName: entry.name).relative];
      if (document != null && document.isVisibleInLibrary) {
        documents.add(document);
      }
    }

    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    documents.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final bytes = await store.totalBytes();
    if (isClosed) return;

    // Recents span the library rather than the open folder, and only matter at
    // the root: inside a folder the user has already said what they are
    // looking at.
    final recents = path.isEmpty
        ? (byPath.values.where((d) => d.isVisibleInLibrary).toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)))
        : const <Document>[];

    final favourites = await index.count(filter: DocumentFilter.favourites);
    final archived = await index.count(filter: DocumentFilter.archived);
    final trashEntries = path.isEmpty ? await loadTrash?.call() : null;
    final visibleIds = documents.map((document) => document.id).toSet();
    final retainedSelection = [
      for (final id in state.selectedDocumentIds)
        if (visibleIds.contains(id)) id,
    ];

    emit(
      state.copyWith(
        status: DashboardStatus.ready,
        folders: folders,
        documents: documents,
        selectionMode: state.selectionMode && retainedSelection.isNotEmpty,
        selectedDocumentIds: retainedSelection,
        recents: recents.take(maxRecents).toList(),
        storageBytes: bytes.valueOrNull ?? state.storageBytes,
        favouritesCount: favourites.valueOrNull ?? state.favouritesCount,
        archiveCount: archived.valueOrNull ?? state.archiveCount,
        trashCount: trashEntries?.valueOrNull?.length ?? state.trashCount,
      ),
    );
  }

  /// How many visible documents sit at or below [path].
  ///
  /// Counted recursively, because a folder showing zero while holding a
  /// subfolder full of documents would read as empty.
  static int _countIn(List<String> path, Iterable<Document> documents) {
    final prefix = '${path.join('/')}/';
    return documents
        .where(
          (document) =>
              document.isVisibleInLibrary &&
              document.relativePath.startsWith(prefix),
        )
        .length;
  }
}
