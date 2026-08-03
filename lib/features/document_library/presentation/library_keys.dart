/// Widget keys for the document library feature.
///
/// The values are normative — they come from `specs/document-library/spec.md`.
/// Declaring them as constants means implementation and tests share one source
/// of truth, so a rename is a compile error rather than a silently failing test.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the library and folder screens.
abstract final class LibraryKeys {
  /// Root of the document list screen.
  static const documentListScreen = Key('document_list_screen');

  /// A single row in a document list.
  ///
  /// Rows are distinguished by document identifier, because a widget test that
  /// acts on "the third row" breaks the moment the sort order changes.
  static Key documentListItem(String documentId) =>
      Key('document_list_item_$documentId');

  /// The shared prefix of every document row key.
  static const documentListItemPrefix = 'document_list_item';

  /// Empty state shown when a document list has nothing to show.
  static const documentListEmptyState = Key('document_list_empty_state');

  /// Marks a document whose PDF is password protected.
  ///
  /// Shown because the library folder is visible to other applications: this
  /// is what tells the user which of their documents another app could read.
  static const documentProtectedBadge = Key('document_protected_badge');

  /// Loading indicator shown while a document list loads.
  static const documentListLoading = Key('document_list_loading');

  /// Error view shown when a document list fails to load.
  static const documentListErrorView = Key('document_list_error_view');

  /// Root of the document detail screen.
  static const documentDetailScreen = Key('document_detail_screen');

  /// Control that starts renaming a document.
  static const documentRenameButton = Key('document_rename_button');

  /// Text field in the rename dialog.
  static const documentRenameField = Key('document_rename_field');

  /// Confirmation control in the rename dialog.
  static const documentRenameConfirm = Key('document_rename_confirm');

  /// Control that starts moving a document to a folder.
  static const documentMoveButton = Key('document_move_button');

  /// Control that archives a document.
  static const documentArchiveButton = Key('document_archive_button');

  /// Control that restores an archived document.
  static const documentRestoreButton = Key('document_restore_button');

  /// Control that duplicates a document.
  static const documentDuplicateButton = Key('document_duplicate_button');

  /// Control that starts permanent removal of a document.
  static const documentDeleteButton = Key('document_move_to_trash_button');

  /// Confirmation dialog shown before a document is permanently removed.
  static const documentDeleteConfirmDialog = Key(
    'document_delete_confirm_dialog',
  );

  /// The control inside the delete dialog that confirms the removal.
  static const documentDeleteConfirmButton = Key(
    'document_delete_confirm_button',
  );

  /// The control inside the delete dialog that abandons the removal.
  static const documentDeleteCancelButton = Key(
    'document_delete_cancel_button',
  );

  /// Control that toggles a document's favourite status.
  static const documentFavouriteToggle = Key('document_favourite_toggle');

  /// Root of the folder list screen.
  static const folderListScreen = Key('folder_list_screen');

  /// Control that creates a folder.
  static const folderCreateButton = Key('folder_create_button');

  /// Text field in the folder-name dialog.
  static const folderNameField = Key('folder_name_field');

  /// Confirmation control in the folder-name dialog.
  static const folderNameConfirm = Key('folder_name_confirm');

  /// A single row in the folder list.
  static Key folderListItem(String folderId) =>
      Key('folder_list_item_$folderId');

  /// Empty state shown when no folder exists.
  static const folderListEmptyState = Key('folder_list_empty_state');

  /// Loading indicator shown while folders load.
  static const folderListLoading = Key('folder_list_loading');

  /// Error view shown when the folder list fails to load.
  static const folderListErrorView = Key('folder_list_error_view');

  /// Dialog asking what happens to a deleted folder's documents.
  static const folderDeleteStrategyDialog = Key(
    'folder_delete_strategy_dialog',
  );

  /// Choice that moves the documents out of the folder being deleted.
  static const folderDeleteMoveOut = Key('folder_delete_move_out');

  /// Choice that deletes the documents along with the folder.
  static const folderDeleteWithDocuments = Key('folder_delete_with_documents');

  /// A page thumbnail on the document detail screen.
  static Key pageThumbnail(String pageId) => Key('page_thumbnail_$pageId');

  /// Loading indicator for a derived page thumbnail.
  static Key pageThumbnailLoading(String pageId) =>
      Key('page_thumbnail_loading_$pageId');

  /// Root of the folder detail screen.
  ///
  /// Distinct from [documentListScreen] even though the folder view is built
  /// from that screen: an end-to-end flow that navigated into a folder and
  /// found only a document list could not tell whether it had arrived or was
  /// still looking at the list it started from.
  static const folderDetailScreen = Key('library_folder_detail_screen');

  /// The action menu on a folder row, keyed by the folder it belongs to.
  ///
  /// Per folder rather than a single constant: a list of folders renders one
  /// menu each, and a flow renaming the second folder has to be able to say
  /// which menu it means.
  static Key folderMenuButton(String folderId) =>
      Key('folder_menu_button_$folderId');

  /// The rename entry inside a folder's action menu.
  ///
  /// A constant rather than per folder, because only one menu is open at a
  /// time: the entry is unambiguous once the menu it belongs to was opened.
  static const folderMenuRename = Key('folder_menu_rename');

  /// The delete entry inside a folder's action menu.
  static const folderMenuDelete = Key('folder_menu_delete');

  /// The dialog that picks a document's destination folder.
  static const documentMoveDialog = Key('document_move_dialog');

  /// The choice that leaves a document unfiled.
  static const documentMoveOptionNone = Key('document_move_option_none');

  /// One destination folder in the move dialog.
  static Key documentMoveOption(String folderId) =>
      Key('document_move_option_$folderId');

  /// The control that opens a document for reading from its detail screen.
  static const documentOpenButton = Key('document_open_button');

  /// The overflow menu on the document detail screen.
  static const documentDetailMenu = Key('document_detail_menu');

  /// The control that retries a failed document list load.
  static const documentListRetryButton = Key('document_list_retry_button');

  /// The indicator shown while the next page of documents loads.
  static const documentListLoadMore = Key('document_list_load_more');

  /// The control that retries a failed folder list load.
  static const folderListRetryButton = Key('folder_list_retry_button');

  /// The wrapper that reconciles the library folder when the app resumes.
  ///
  /// The library folder is visible in the user's file browser, so it can change
  /// while DocForge is in the background. Keyed so a flow can assert the
  /// reconciler is mounted rather than discover its absence as a stale list.
  static const libraryReconciler = Key('library_reconciler');
}

/// Semantics labels for the document library feature.
///
/// Declared beside [LibraryKeys] and for the same reason: a label an
/// accessibility test or an end-to-end flow asserts on is part of the contract,
/// and an inline literal is a contract nothing can check. A label that moves
/// becomes a compile error here rather than a test that quietly stops matching.
abstract final class LibrarySemantics {
  /// Announces the folder the user has opened.
  ///
  /// Names the folder rather than saying "folder contents", because a screen
  /// reader user arriving here needs to know *which* folder they opened.
  static String folderDetailScreen(String folderName) =>
      'Contents of folder $folderName';

  /// Announces how much space the library occupies.
  static String storageUsage(String formattedSize) =>
      'Library uses $formattedSize';

  /// Marks a document whose PDF is password protected.
  ///
  /// Announced because the library folder is visible to other applications:
  /// this is what tells the user which of their documents another app could
  /// read.
  static const passwordProtected = 'Password protected';

  /// Announces a page thumbnail by its position in the document.
  static String pageThumbnail(int pageNumber) => 'Page $pageNumber thumbnail';

  /// Announces a folder's action menu, naming the folder it acts on.
  static String folderActions(String folderName) => 'Actions for $folderName';

  /// The name field in the rename and folder-name dialogs.
  static const nameField = 'Name';

  /// Confirms permanent removal, naming what is about to be removed.
  ///
  /// "Delete" alone is the most dangerous label in the application to leave
  /// ambiguous: a listener who has lost track of which dialog is open cannot
  /// tell it from any other delete.
  static String deleteConfirm(String title) => 'Delete $title permanently';

  /// Abandons a permanent removal.
  static const deleteCancel = 'Keep this document';

  /// Deletes a folder but keeps the documents that were in it.
  static String folderDeleteMoveOut(String folderName) =>
      'Delete folder $folderName and keep its documents';

  /// Deletes a folder together with everything in it.
  static String folderDeleteWithDocuments(String folderName) =>
      'Delete folder $folderName and its documents';

  /// The folder picker.
  static const moveDialog = 'Move to folder';

  /// The choice that leaves a document unfiled.
  static const moveOptionNone = 'No folder';

  /// One destination in the folder picker.
  static String moveOption(String folderName) => 'Move to $folderName';
}
