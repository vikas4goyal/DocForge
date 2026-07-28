/// Widget keys for the dashboard.
library;

import 'package:flutter/widgets.dart';

/// Keys the dashboard's automated tests bind to.
abstract final class DashboardKeys {
  /// Root of the dashboard.
  static const screen = Key('dashboard_screen');

  /// Searches across the whole library.
  static const searchField = Key('dashboard_search_field');

  /// The folders and documents of the open folder.
  static const contentList = Key('dashboard_content_list');

  /// The path from the library root to the open folder.
  static const breadcrumb = Key('dashboard_breadcrumb');

  /// Creates a folder inside the open folder.
  static const createFolderButton = Key('dashboard_create_folder_button');

  /// Brings an external PDF into the open folder.
  static const importPdfButton = Key('dashboard_import_pdf_button');

  /// How much space the library occupies.
  static const storageSummary = Key('dashboard_storage_summary');

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

  /// A folder row, keyed by name.
  static Key folderRow(String name) => Key('dashboard_folder_$name');
}
