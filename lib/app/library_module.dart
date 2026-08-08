/// Constructs the document-library object graph.
///
/// Split out of `main.dart` so the entry point stays a list of steps rather
/// than a wiring diagram, and so a test can build the same graph over a
/// temporary database.
///
/// Everything here is infrastructure construction, which the composition root
/// is the only place allowed to do (`design.md` §5).
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_scanly/features/document_library/application/usecases/document_thumbnails.dart';
import 'package:doc_scanly/features/document_library/application/usecases/folder_usecases.dart';
import 'package:doc_scanly/features/document_library/application/usecases/library_display_density_usecases.dart';
import 'package:doc_scanly/features/document_library/application/usecases/library_folder_usecases.dart';
import 'package:doc_scanly/features/document_library/application/usecases/reconcile_library.dart';
import 'package:doc_scanly/features/document_library/application/usecases/trash_usecases.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/document_file_store.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';
import 'package:doc_scanly/features/document_library/infrastructure/datasource/derived_thumbnail_cache.dart';
import 'package:doc_scanly/features/document_library/infrastructure/datasource/document_file_store.dart';
import 'package:doc_scanly/features/document_library/infrastructure/datasource/pdfrx_thumbnail_renderer.dart';
import 'package:doc_scanly/features/document_library/infrastructure/document_page_access_repository.dart';
import 'package:doc_scanly/features/document_library/infrastructure/document_title_index.dart';
import 'package:doc_scanly/features/document_library/infrastructure/library_contracts_impl.dart';
import 'package:doc_scanly/features/document_library/infrastructure/library_storage_migration.dart';
import 'package:doc_scanly/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:doc_scanly/features/document_library/infrastructure/preference_library_display_density_repository.dart';
import 'package:doc_scanly/features/document_library/infrastructure/repositories/isar_library_repositories.dart';
import 'package:doc_scanly/features/document_search/domain/repositories/search_repository.dart';
import 'package:doc_scanly/features/document_search/infrastructure/repositories/indexed_search_repository.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

/// Everything the library feature exposes to the rest of the application.
///
/// Holds the use cases, not the repositories: a screen that could reach a
/// repository directly could bypass the rules the use cases enforce.
class LibraryModule {
  /// Creates the module over an already-built object graph.
  const LibraryModule({
    required this.search,
    required this.isar,
    required this.documentsDirectory,
    required this.loadDocuments,
    required this.loadDocumentDetail,
    required this.loadDocumentPageThumbnail,
    required this.loadDocumentPagePreview,
    required this.pageAccess,
    required this.loadFolderOptions,
    required this.renameDocument,
    required this.moveDocument,
    required this.toggleFavourite,
    required this.archiveDocument,
    required this.restoreDocument,
    required this.duplicateDocument,
    required this.purgeDocument,
    required this.loadFolders,
    required this.createFolder,
    required this.renameFolder,
    required this.deleteFolder,
    required this.documentReader,
    required this.documentWriter,
    required this.folderReader,
    required this.storageSummaryReader,
    required this.reconcile,
    required this.documents,
    required this.folders,
    required this.pages,
    required this.publicStore,
    required this.createLibraryFolder,
    required this.renameLibraryFolder,
    required this.inspectTrashCandidate,
    required this.moveDocumentToTrash,
    required this.moveFolderTreeToTrash,
    required this.loadTrash,
    required this.restoreTrashEntry,
    required this.purgeTrashEntry,
    required this.emptyTrash,
    required this.expireTrash,
    required this.loadDisplayDensity,
    required this.saveDisplayDensity,
  });

  /// Loads a page of documents.
  final LoadDocuments loadDocuments;

  /// Loads metadata for one document.
  final LoadDocumentDetail loadDocumentDetail;

  /// Lazily derives one page preview from the authoritative PDF.
  final LoadDocumentPageThumbnail loadDocumentPageThumbnail;

  /// Loads a preview through unified scanned/PDF-backed page access.
  final LoadDocumentPagePreview loadDocumentPagePreview;

  /// Unified page access injected into OCR and sharing consumers.
  final DocumentPageAccessRepository pageAccess;

  /// Loads folders for the move picker.
  final LoadFolderOptions loadFolderOptions;

  /// Renames a document.
  final RenameDocument renameDocument;

  /// Moves a document between folders.
  final MoveDocument moveDocument;

  /// Toggles a document's favourite status.
  final ToggleFavourite toggleFavourite;

  /// Archives a document.
  final ArchiveDocument archiveDocument;

  /// Restores an archived document.
  final RestoreDocument restoreDocument;

  /// Duplicates a document.
  final DuplicateDocument duplicateDocument;

  /// Permanently removes a document.
  final PurgeDocument purgeDocument;

  /// Lists folders.
  final LoadFolders loadFolders;

  /// Creates a folder.
  final CreateFolder createFolder;

  /// Renames a folder.
  final RenameFolder renameFolder;

  /// Deletes a folder.
  final DeleteFolder deleteFolder;

  /// Read access for other capabilities.
  final DocumentReader documentReader;

  /// Write access for other capabilities.
  final DocumentWriter documentWriter;

  /// Folder read access for other capabilities.
  final FolderReader folderReader;

  /// Storage reporting for the dashboard and settings.
  final StorageSummaryReader storageSummaryReader;

  /// The document index, for screens that join it to the folder.
  final DocumentRepository documents;

  /// The folder index, exposed to the iOS-only cloud reconciler.
  final FolderRepository folders;

  /// Page rows removed when cloud reconciliation observes external deletion.
  final PageRepository pages;

  /// The user-visible library folder.
  final PublicFileStore publicStore;

  /// Creates a folder inside the library.
  final CreateLibraryFolder createLibraryFolder;

  /// Renames a real folder and re-paths its indexed documents.
  final RenameLibraryFolder renameLibraryFolder;

  /// Measures candidates before confirmation.
  final InspectTrashCandidate inspectTrashCandidate;

  /// Moves one document into recoverable Trash.
  final MoveDocumentToTrash moveDocumentToTrash;

  /// Moves a complete folder tree into recoverable Trash.
  final MoveFolderTreeToTrash moveFolderTreeToTrash;

  /// Loads recoverable Trash entries.
  final LoadTrash loadTrash;

  /// Restores one recoverable entry.
  final RestoreTrashEntry restoreTrashEntry;

  /// Permanently removes one Trash entry.
  final PurgeTrashEntry purgeTrashEntry;

  /// Permanently removes every Trash entry.
  final EmptyTrash emptyTrash;

  /// Purges entries at or beyond the retention boundary.
  final ExpireTrash expireTrash;

  /// Loads the persisted Dashboard thumbnail density.
  final LoadLibraryDisplayDensity loadDisplayDensity;

  /// Saves the Dashboard thumbnail density.
  final SaveLibraryDisplayDensity saveDisplayDensity;

  /// Brings the index back into step with the library folder.
  ///
  /// The folder is the user's: they can add, rename and delete files in it
  /// while the application is running, so this runs at launch and on resume.
  final ReconcileLibrary reconcile;

  /// The open database.
  ///
  /// Exposed so capabilities can share the same open library database.
  final Isar isar;

  /// Searches document titles.
  final SearchRepository search;

  /// Where document files are written.
  ///
  /// Exposed for the same reason: PDF generation writes into the directory the
  /// library reads from, and resolving it twice invites the two to disagree.
  final Directory documentsDirectory;
}

/// Opens the library database and builds the module over it.
///
/// The Isar instance and the documents directory are both resolved once here
/// and injected downwards, so no repository performs an ambient path lookup or
/// opens its own database connection.
Future<LibraryModule> buildLibraryModule({
  required PublicFileStore store,
  required PreferenceStore preferences,
  required PdfPageCountReader pageCountOf,
  required Clock clock,
  required IdGenerator ids,
  required SecureStore secureStorage,
  DocumentFileResolver? documentFileResolver,
}) async {
  // Application Support, not Documents: on iOS the Documents container is now
  // exposed to the Files app, so the database and the derived caches have to
  // live somewhere the user never sees (`design.md` D4).
  final supportDirectory = await getApplicationSupportDirectory();

  final isar = await Isar.open([
    DocumentEntitySchema,
    FolderEntitySchema,
    PageEntitySchema,
    TrashEntitySchema,
  ], directory: supportDirectory.path);

  // Before anything reads a document: layout-1 records address a private path
  // that no longer exists, so a screen built over an unmigrated library would
  // show documents it cannot open (`design.md` migration plan).
  await LibraryStorageMigration(
    isar: isar,
    store: store,
    legacyDocumentsDirectory: await getApplicationDocumentsDirectory(),
  ).run();

  return buildLibraryModuleOver(
    isar: isar,
    documentsDirectory: supportDirectory,
    store: store,
    preferences: preferences,
    pageCountOf: pageCountOf,
    clock: clock,
    ids: ids,
    secureStorage: secureStorage,
    documentFileResolver: documentFileResolver,
  );
}

/// Builds the module over an already-open [isar] and [documentsDirectory].
///
/// Separated from [buildLibraryModule] so an integration test can supply a
/// temporary database and directory without the plugin lookups that only work
/// on a real device.
LibraryModule buildLibraryModuleOver({
  required Isar isar,
  required Directory documentsDirectory,
  required PublicFileStore store,
  required PreferenceStore preferences,
  required PdfPageCountReader pageCountOf,
  required Clock clock,
  required IdGenerator ids,
  required SecureStore secureStorage,
  DocumentFileResolver? documentFileResolver,
  ThumbnailRenderer thumbnailRenderer = renderPdfrxThumbnail,
  DocumentPageTextExtractor pageTextExtractor = extractPdfrxPageText,
}) {
  final documents = IsarDocumentRepository(isar);
  final folders = IsarFolderRepository(isar);
  final pages = IsarPageRepository(isar);
  final trash = IsarTrashRepository(isar);
  // Narrowed to derived data: the PDFs themselves live in `store`, and this
  // holds only the thumbnails rendered from them (`design.md` D4a).
  final DocumentFileStore derived = LocalDocumentFileStore(documentsDirectory);
  final thumbnailCache = DerivedThumbnailCache(
    cacheDirectory: documentsDirectory,
    // PurgeDocument already removes this per-document directory, so previews
    // cannot outlive a permanent deletion.
    directoryName: LocalDocumentFileStore.documentsDirectoryName,
    render: thumbnailRenderer,
  );
  final fileResolver =
      documentFileResolver ?? PublicStoreDocumentFileResolver(store);
  final loadThumbnail = LoadDocumentPageThumbnail(thumbnailCache, fileResolver);
  final pageAccess = LibraryDocumentPageAccessRepository(
    pages,
    fileResolver,
    secureStorage,
    documentsDirectory,
    thumbnailRenderer,
    pageTextExtractor,
  );
  final displayDensity = PreferenceLibraryDisplayDensityRepository(preferences);

  final move = MoveDocument(documents, clock, store, folders);
  final purge = PurgeDocument(documents, pages, store, derived, secureStorage);
  final storageSummary = ComputeStorageSummary(documents, store);
  final purgeTrash = PurgeTrashEntry(trash, folders, store, purge);

  return LibraryModule(
    search: IndexedSearchRepository(IsarDocumentTitleIndex(isar)),
    isar: isar,
    documentsDirectory: documentsDirectory,
    loadDocuments: LoadDocuments(documents),
    loadDocumentDetail: LoadDocumentDetail(documents),
    loadDocumentPageThumbnail: loadThumbnail,
    loadDocumentPagePreview: LoadDocumentPagePreview(pageAccess),
    pageAccess: pageAccess,
    loadFolderOptions: LoadFolderOptions(folders),
    renameDocument: RenameDocument(documents, clock, store),
    moveDocument: move,
    toggleFavourite: ToggleFavourite(documents, clock),
    archiveDocument: ArchiveDocument(documents, clock),
    restoreDocument: RestoreDocument(documents, clock),
    duplicateDocument: DuplicateDocument(documents, pages, store, clock, ids),
    purgeDocument: purge,
    loadFolders: LoadFolders(folders),
    createFolder: CreateFolder(folders, clock, ids),
    renameFolder: RenameFolder(folders),
    deleteFolder: DeleteFolder(folders, documents, move, purge),
    documentReader: LibraryDocumentReader(documents, pages),
    documentWriter: LibraryDocumentWriter(documents, pages, clock),
    folderReader: LibraryFolderReader(folders),
    storageSummaryReader: LibraryStorageSummaryReader(storageSummary),
    documents: documents,
    folders: folders,
    pages: pages,
    publicStore: store,
    createLibraryFolder: CreateLibraryFolder(store, folders, clock, ids),
    renameLibraryFolder: RenameLibraryFolder(store, folders, documents),
    inspectTrashCandidate: InspectTrashCandidate(store),
    moveDocumentToTrash: MoveDocumentToTrash(
      documents,
      trash,
      store,
      clock,
      ids,
    ),
    moveFolderTreeToTrash: MoveFolderTreeToTrash(
      documents,
      folders,
      trash,
      store,
      clock,
      ids,
    ),
    loadTrash: LoadTrash(trash),
    restoreTrashEntry: RestoreTrashEntry(trash, documents, folders, store),
    purgeTrashEntry: purgeTrash,
    emptyTrash: EmptyTrash(trash, purgeTrash),
    expireTrash: ExpireTrash(trash, purgeTrash, clock),
    loadDisplayDensity: LoadLibraryDisplayDensity(displayDensity),
    saveDisplayDensity: SaveLibraryDisplayDensity(displayDensity),
    reconcile: ReconcileLibrary(
      store: store,
      documents: documents,
      pages: pages,
      preferences: preferences,
      clock: clock,
      ids: ids,
      pageCountOf: pageCountOf,
    ),
  );
}
