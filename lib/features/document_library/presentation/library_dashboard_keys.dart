/// Widget keys for the dashboard.
library;

import 'package:flutter/widgets.dart';

/// Keys the dashboard's automated tests bind to.
abstract final class DashboardKeys {
  /// Root of the dashboard.
  static const screen = Key('dashboard_screen');

  /// The single vertical scroll surface holding dashboard sections and items.
  static const scrollView = Key('dashboard_scroll_view');

  /// Searches across the whole library.
  static const searchField = Key('dashboard_search_field');

  /// The folders and documents of the open folder.
  static const contentList = Key('dashboard_content_list');

  /// The path from the library root to the open folder.
  static const breadcrumb = Key('dashboard_breadcrumb');

  /// Root breadcrumb control.
  static const breadcrumbRoot = Key('dashboard_breadcrumb_root');

  /// Creates a folder inside the open folder.
  static const createFolderButton = Key('dashboard_create_folder_button');

  /// Brings an external PDF into the open folder.
  static const importPdfButton = Key('dashboard_import_pdf_button');

  /// How much space the library occupies.
  static const storageSummary = Key('dashboard_storage_summary');

  /// The recently modified documents, shown at the library root.
  static const recents = Key('dashboard_recents');

  /// A recently modified document tile.
  static Key recentDocument(String documentId) =>
      Key('dashboard_recent_$documentId');

  /// Shown when the open folder holds nothing.
  static const emptyState = Key('dashboard_empty_state');

  /// Shown while the folder is being read.
  static const loadingIndicator = Key('dashboard_loading_indicator');

  /// Shown when the folder could not be read.
  static const errorView = Key('dashboard_error_view');

  /// Reloads after a failure.
  static const errorRetryButton = Key('dashboard_error_retry_button');

  /// The dialog that names a new folder.
  static const createFolderDialog = Key('dashboard_create_folder_dialog');

  /// The new folder's name.
  static const createFolderField = Key('dashboard_create_folder_field');

  /// Confirms creating the folder.
  static const createFolderConfirm = Key('dashboard_create_folder_confirm');

  /// Collections section at the library root.
  static const collections = Key('dashboard_collections');

  /// Opens favourites.
  static const favouritesCollection = Key('dashboard_collection_favourites');

  /// Opens Archive.
  static const archiveCollection = Key('dashboard_collection_archive');

  /// Opens recoverable Trash.
  static const trashCollection = Key('dashboard_trash_collection');

  /// Folder action menu.
  static Key folderMenu(String name) => Key('dashboard_folder_menu_$name');

  /// Rename action in an open folder menu.
  static const folderRename = Key('dashboard_folder_rename');

  /// Move-to-Trash action in an open folder menu.
  static const folderTrash = Key('dashboard_folder_trash');

  /// Recursive Trash confirmation dialog.
  static const trashConfirmDialog = Key('trash_move_confirmation');

  /// Confirms moving a folder tree to Trash.
  static const trashConfirm = Key('trash_move_confirm');

  /// Reports that a requested folder move could not be completed.
  static const trashMoveFailure = Key('dashboard_trash_move_failure');

  /// A folder row, keyed by name.
  static Key folderRow(String name) => Key('dashboard_folder_$name');
}
