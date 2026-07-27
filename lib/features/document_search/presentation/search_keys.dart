/// Widget keys for the search screen.
///
/// The values are normative — they come from `specs/document-search/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the search screen.
abstract final class SearchKeys {
  /// Root of the search screen.
  static const screen = Key('search_screen');

  /// The field the user types into.
  static const inputField = Key('search_input_field');

  /// The control that clears the search.
  static const clearButton = Key('search_clear_button');

  /// The list of results.
  static const resultsList = Key('search_results_list');

  /// The folder filter control.
  static const filterFolder = Key('search_filter_folder');

  /// The date filter control.
  static const filterDate = Key('search_filter_date');

  /// The state shown when nothing matched.
  static const emptyState = Key('search_empty_state');

  /// The state shown before anything has been searched for.
  static const initialState = Key('search_initial_state');

  /// The indicator shown while a search runs.
  static const loadingIndicator = Key('search_loading_indicator');

  /// The view shown when a search fails.
  static const errorView = Key('search_error_view');

  /// The control that retries a failed search.
  static const errorRetryButton = Key('search_error_retry_button');

  /// One result row, keyed by document identifier.
  static Key resultRow(String documentId) => Key('search_result_$documentId');
}
