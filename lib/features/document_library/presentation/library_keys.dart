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
  static const documentDeleteButton = Key('document_delete_button');

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
}
