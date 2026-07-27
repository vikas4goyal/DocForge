/// Widget keys for sharing, printing and export.
///
/// The values are normative — they come from `specs/document-sharing/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the sharing options and their progress and error views.
abstract final class ShareKeys {
  /// Root of the share options sheet.
  static const sheet = Key('share_options_sheet');

  /// The control that shares the document as a PDF.
  static const pdfButton = Key('share_pdf_button');

  /// The control that shares selected pages as images.
  static const imagesButton = Key('share_images_button');

  /// The control that shares the recognised text.
  static const textButton = Key('share_text_button');

  /// The control that opens the system print dialogue.
  static const printButton = Key('share_print_button');

  /// The control that exports the document to device storage.
  static const exportButton = Key('share_export_button');

  /// The indicator shown while content is being prepared.
  static const progressIndicator = Key('share_progress_indicator');

  /// The control that abandons preparation.
  static const cancelButton = Key('share_cancel_button');

  /// The view shown when sharing, printing or exporting fails.
  static const errorView = Key('share_error_view');

  /// The control that retries after a failure.
  static const errorRetryButton = Key('share_error_retry_button');

  /// The control that offers export after no application could receive a share.
  static const errorExportButton = Key('share_error_export_button');

  /// The message shown when a document has no recognised text.
  static const noTextMessage = Key('share_no_text_message');

  /// The control that offers to run recognition from the no-text message.
  static const runRecognitionButton = Key('share_run_recognition_button');
}
