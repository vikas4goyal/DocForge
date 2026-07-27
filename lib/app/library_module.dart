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

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_forge/features/document_library/application/usecases/folder_usecases.dart';
import 'package:doc_forge/features/document_library/domain/repositories/document_file_store.dart';
import 'package:doc_forge/features/document_library/infrastructure/datasource/document_file_store.dart';
import 'package:doc_forge/features/document_library/infrastructure/library_contracts_impl.dart';
import 'package:doc_forge/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:doc_forge/features/document_library/infrastructure/repositories/isar_library_repositories.dart';
import 'package:doc_forge/features/ocr/infrastructure/models/ocr_entities.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

/// Everything the library feature exposes to the rest of the application.
///
/// Holds the use cases, not the repositories: a screen that could reach a
/// repository directly could bypass the rules the use cases enforce.
class LibraryModule {
  /// Creates the module over an already-built object graph.
  const LibraryModule({
    required this.isar,
    required this.documentsDirectory,
    required this.loadDocuments,
    required this.loadDocumentDetail,
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
  });

  /// Loads a page of documents.
  final LoadDocuments loadDocuments;

  /// Loads one document with its pages.
  final LoadDocumentDetail loadDocumentDetail;

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

  /// Storage reporting for Home and settings.
  final StorageSummaryReader storageSummaryReader;

  /// The open database.
  ///
  /// Exposed so other capabilities can register their own collections against
  /// the same instance. Recognised text in particular has to live here: search
  /// queries the title and text indexes together, and two databases could not
  /// be kept consistent across a permanent deletion.
  final Isar isar;

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
  required Clock clock,
  required IdGenerator ids,
  required SecureStore secureStorage,
}) async {
  final supportDirectory = await getApplicationSupportDirectory();
  final documentsDirectory = await getApplicationDocumentsDirectory();

  final isar = await Isar.open([
    DocumentEntitySchema,
    FolderEntitySchema,
    PageEntitySchema,
    // Recognised text lives in the same database as the documents it belongs
    // to: search queries both indexes together, and two databases could not be
    // kept consistent across a permanent deletion.
    OcrTextEntitySchema,
  ], directory: supportDirectory.path);

  return buildLibraryModuleOver(
    isar: isar,
    documentsDirectory: documentsDirectory,
    clock: clock,
    ids: ids,
    secureStorage: secureStorage,
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
  required Clock clock,
  required IdGenerator ids,
  required SecureStore secureStorage,
}) {
  final documents = IsarDocumentRepository(isar);
  final folders = IsarFolderRepository(isar);
  final pages = IsarPageRepository(isar);
  final DocumentFileStore files = LocalDocumentFileStore(documentsDirectory);

  final move = MoveDocument(documents, clock);
  final purge = PurgeDocument(documents, pages, files, secureStorage);
  final storageSummary = ComputeStorageSummary(documents, files);

  return LibraryModule(
    isar: isar,
    documentsDirectory: documentsDirectory,
    loadDocuments: LoadDocuments(documents),
    loadDocumentDetail: LoadDocumentDetail(documents, pages),
    loadFolderOptions: LoadFolderOptions(folders),
    renameDocument: RenameDocument(documents, clock),
    moveDocument: move,
    toggleFavourite: ToggleFavourite(documents, clock),
    archiveDocument: ArchiveDocument(documents, clock),
    restoreDocument: RestoreDocument(documents, clock),
    duplicateDocument: DuplicateDocument(documents, pages, files, clock, ids),
    purgeDocument: purge,
    loadFolders: LoadFolders(folders),
    createFolder: CreateFolder(folders, clock, ids),
    renameFolder: RenameFolder(folders),
    deleteFolder: DeleteFolder(folders, documents, move, purge),
    documentReader: LibraryDocumentReader(documents, pages),
    documentWriter: LibraryDocumentWriter(documents, pages, clock),
    folderReader: LibraryFolderReader(folders),
    storageSummaryReader: LibraryStorageSummaryReader(storageSummary),
  );
}
