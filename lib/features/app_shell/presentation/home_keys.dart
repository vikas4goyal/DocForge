/// Widget keys for the app shell.
///
/// The values are normative — they come from `specs/app-shell/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the Home screen.
abstract final class HomeKeys {
  /// Root of the tab scaffold.
  static const tabScaffold = Key('app_tab_scaffold');

  /// The dashboard destination.
  static const dashboardTab = Key('app_tab_dashboard');

  /// The create-PDF control, in the middle.
  static const createTab = Key('app_tab_create');

  /// The settings destination.
  static const settingsTab = Key('app_tab_settings');

  /// Root of the Home screen.
  static const screen = Key('home_screen');

  /// The search entry point.
  static const searchBar = Key('home_search_bar');

  /// The primary Scan Document action.
  static const scanButton = Key('home_scan_button');

  /// The recent documents section.
  static const recentDocuments = Key('home_recent_documents');

  /// Shortcut to the full document list.
  static const allDocumentsShortcut = Key('home_all_documents_shortcut');

  /// The folders section.
  static const foldersSection = Key('home_folders_section');

  /// Shortcut to favourites.
  static const favouritesShortcut = Key('home_favourites_shortcut');

  /// Shortcut to the archive.
  static const archiveShortcut = Key('home_archive_shortcut');

  /// The storage summary card.
  static const storageSummary = Key('home_storage_summary');

  /// Empty state shown when no document exists.
  static const emptyState = Key('home_empty_state');

  /// Loading indicator shown while Home loads.
  static const loadingIndicator = Key('home_loading_indicator');

  /// Error view shown when Home fails to load.
  static const errorView = Key('home_error_view');

  /// Retry control inside the error view.
  static const errorRetryButton = Key('home_error_retry_button');

  /// A recent-document row, keyed by document identifier.
  static Key recentDocument(String documentId) =>
      Key('home_recent_document_$documentId');

  /// A folder chip in the folders section, keyed by folder identifier.
  static Key folderChip(String folderId) => Key('home_folder_$folderId');
}
