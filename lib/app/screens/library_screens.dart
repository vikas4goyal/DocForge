/// Builds the library's browsing screens.
///
/// Four of the six are the same screen under a different filter — all
/// documents, favourites, the archive and a folder's contents — so they are
/// built from one helper rather than four near-copies that could drift.
library;

import 'package:doc_scanly/app/library_module.dart';
import 'package:doc_scanly/app/router/app_router.dart';
import 'package:doc_scanly/app/router/app_routes.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/folder_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/trash_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/document_detail_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/folder_detail_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/folder_list_screen.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/trash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The library screens reachable as routes.
class LibraryScreens {
  /// Creates the group.
  const LibraryScreens({
    required this.documents,
    required this.documentDetail,
    required this.folders,
    required this.folderDetail,
    required this.favourites,
    required this.archive,
    required this.trash,
  });

  /// Every document.
  final ScreenBuilder documents;

  /// One document.
  final DocumentScreenBuilder documentDetail;

  /// Every folder.
  final ScreenBuilder folders;

  /// One folder's contents.
  final FolderScreenBuilder folderDetail;

  /// Documents the user marked as favourites.
  final ScreenBuilder favourites;

  /// Documents the user archived.
  final ScreenBuilder archive;

  /// Recoverable Trash.
  final ScreenBuilder trash;
}

/// Builds the library screens over an already-constructed [library] module.
///
/// Takes the module rather than its individual use cases because every screen
/// here needs a different subset of the same eight, and listing them
/// separately would put the burden of assembling them correctly on every
/// caller — which is the problem this split exists to remove.
LibraryScreens buildLibraryScreens({required LibraryModule library}) {
  /// Builds a document list scoped to [filter]; four routes differ only here.
  Widget documentList(
    BuildContext context, {
    required String title,
    DocumentFilter filter = DocumentFilter.all,
    FolderId? folderId,
    String? emptyTitle,
    String? emptyMessage,
    bool offerScan = true,
  }) => BlocProvider(
    create: (_) => DocumentListCubit(
      library.loadDocuments,
      library.toggleFavourite,
      library.archiveDocument,
      library.restoreDocument,
      filter: filter,
      folderId: folderId,
    ),
    child: DocumentListScreen(
      title: title,
      emptyTitle: emptyTitle,
      emptyMessage: emptyMessage,
      // The archive and favourites deliberately offer no scan action: "scan
      // your first document" is not what an empty archive should suggest.
      onScan: offerScan ? () => context.push(AppRoutes.scan) : null,
      onOpenDocument: (id) => context.push(AppRoutes.documentView(id)),
      loadThumbnail: library.loadDocumentPageThumbnail.call,
    ),
  );

  return LibraryScreens(
    documents: (context) => documentList(context, title: 'Documents'),
    documentDetail: (context, id) => BlocProvider(
      create: (_) => DocumentDetailCubit(
        id,
        library.loadDocumentDetail,
        library.renameDocument,
        library.moveDocument,
        library.toggleFavourite,
        library.archiveDocument,
        library.restoreDocument,
        library.duplicateDocument,
        library.purgeDocument,
        moveToTrash: library.moveDocumentToTrash,
        loadFolderOptions: library.loadFolderOptions,
      ),
      child: DocumentDetailScreen(
        // Detail only invokes this callback when its record is unavailable or
        // has moved to Trash. The typed result lets an underlying Viewer close
        // exactly once even if a platform store exposes that mutation late.
        onClose: () => context.pop(true),
        // Replaces rather than pushes: the user asked for a copy, and leaving
        // the original underneath would make Back feel like an undo it is not.
        onOpenDocument: (document) =>
            context.pushReplacement(AppRoutes.documentView(document.id)),
      ),
    ),
    folders: (context) => BlocProvider(
      create: (_) => FolderCubit(
        library.loadFolders,
        library.createFolder,
        library.renameFolder,
        library.deleteFolder,
      ),
      child: FolderListScreen(
        onOpenFolder: (id) => context.push(AppRoutes.folderDetail(id)),
      ),
    ),
    folderDetail: (context, id) => BlocProvider(
      create: (_) => DocumentListCubit(
        library.loadDocuments,
        library.toggleFavourite,
        library.archiveDocument,
        library.restoreDocument,
        filter: DocumentFilter.folder,
        folderId: id,
      ),
      child: FolderDetailScreen(
        folderName: 'Folder',
        loadThumbnail: library.loadDocumentPageThumbnail.call,
        onOpenDocument: (documentId) =>
            context.push(AppRoutes.documentView(documentId)),
      ),
    ),
    favourites: (context) => documentList(
      context,
      title: 'Favourites',
      filter: DocumentFilter.favourites,
      emptyTitle: 'No favourites yet',
      emptyMessage: 'Mark a document as a favourite to find it here.',
      offerScan: false,
    ),
    archive: (context) => documentList(
      context,
      title: 'Archive',
      filter: DocumentFilter.archived,
      emptyTitle: 'Nothing archived',
      emptyMessage: 'Archived documents are kept here, out of your main list.',
      offerScan: false,
    ),
    trash: (context) => BlocProvider(
      create: (_) => TrashCubit(
        loadTrash: library.loadTrash,
        restoreTrash: library.restoreTrashEntry,
        purgeTrash: library.purgeTrashEntry,
        emptyTrash: library.emptyTrash,
      )..load(),
      child: const TrashScreen(),
    ),
  );
}
