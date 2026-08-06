/// Stable keys for Trash automation and accessibility tests.
library;

import 'package:flutter/widgets.dart';

/// Trash screen keys.
abstract final class TrashKeys {
  /// Screen root.
  static const screen = Key('trash_screen');

  /// Loading indicator.
  static const loading = Key('trash_loading');

  /// Empty state.
  static const empty = Key('trash_empty_state');

  /// Error state.
  static const error = Key('trash_error_view');

  /// Retry control.
  static const retry = Key('trash_retry_button');

  /// Empty Trash control.
  static const emptyButton = Key('trash_empty_button');

  /// Empty confirmation dialog.
  static const emptyDialog = Key('trash_empty_dialog');

  /// Confirms emptying Trash.
  static const emptyConfirm = Key('trash_empty_confirm');

  /// Row for one entry.
  static Key row(String id) => Key('trash_row_$id');

  /// Restores one entry.
  static Key restore(String id) => Key('trash_restore_$id');

  /// Permanently deletes one entry.
  static Key purge(String id) => Key('trash_delete_permanently_$id');

  /// Permanent-delete confirmation.
  static Key purgeDialog(String _) =>
      const Key('trash_permanent_delete_dialog');

  /// Confirms irreversible removal of one entry.
  static const purgeConfirm = Key('trash_permanent_delete_confirm');
}
