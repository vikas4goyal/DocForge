/// Builds the library's browsing screens.
///
/// Four of the six are the same screen under a different filter — all
/// documents, favourites, the archive and a folder's contents — so they are
/// built from one helper rather than four near-copies that could drift.
library;

import 'package:doc_forge/app/library_module.dart';
import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/app_routes.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/folder_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_detail_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/folder_detail_screen.dart';
import 'package:doc_forge/features/document_library/presentation/screens/folder_list_screen.dart';
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
      onOpenDocument: (id) => context.push(AppRoutes.documentDetail(id)),
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
      ),
      child: DocumentDetailScreen(
        onClose: () => context.pop(),
        // Replaces rather than pushes: the user asked for a copy, and leaving
        // the original underneath would make Back feel like an undo it is not.
        onOpenDocument: (document) =>
            context.pushReplacement(AppRoutes.documentDetail(document.id)),
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
        onOpenDocument: (documentId) =>
            context.push(AppRoutes.documentDetail(documentId)),
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
  );
}
