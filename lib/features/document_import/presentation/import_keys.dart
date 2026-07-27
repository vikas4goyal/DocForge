/// Widget keys for importing.
///
/// The values are normative — they come from `specs/document-import/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the import options and their progress, permission and error
/// views.
abstract final class ImportKeys {
  /// Root of the import options sheet.
  static const sheet = Key('import_options_sheet');

  /// The camera source, which starts the scanning flow.
  static const sourceCamera = Key('import_source_camera');

  /// The photo gallery source.
  static const sourceGallery = Key('import_source_gallery');

  /// The device files source.
  static const sourceFiles = Key('import_source_files');

  /// The indicator shown while files are copied.
  static const progressIndicator = Key('import_progress_indicator');

  /// The control that abandons an in-progress import.
  static const cancelButton = Key('import_cancel_button');

  /// The view shown when photo or file access was refused.
  static const permissionDeniedView = Key('import_permission_denied_view');

  /// The control that opens the system settings from the permission view.
  static const openSettingsButton = Key('import_open_settings_button');

  /// The view shown when an import fails.
  static const errorView = Key('import_error_view');

  /// The control that retries after a failure.
  static const errorRetryButton = Key('import_error_retry_button');

  /// The prompt for a protected PDF's password.
  static const passwordField = Key('import_password_field');

  /// The control that submits the password.
  static const passwordSubmitButton = Key('import_password_submit_button');

  /// The control that abandons a protected import.
  static const passwordCancelButton = Key('import_password_cancel_button');
}
