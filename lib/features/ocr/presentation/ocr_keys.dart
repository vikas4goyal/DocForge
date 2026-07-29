/// Widget keys for the OCR views.
///
/// The values are normative — they come from `specs/ocr/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the extracted-text view.
abstract final class OcrKeys {
  /// Root of the extracted-text view.
  static const textView = Key('ocr_text_view');

  /// The control that copies the recognised text.
  static const copyTextButton = Key('ocr_copy_text_button');

  /// The control that exports the recognised text as a file.
  static const exportTextButton = Key('ocr_export_text_button');

  /// The control that runs recognition again.
  static const rerunButton = Key('ocr_rerun_button');

  /// The progress indicator shown while recognition runs.
  static const progressIndicator = Key('ocr_progress_indicator');

  /// The control that stops a running recognition.
  static const cancelButton = Key('ocr_cancel_button');

  /// The view shown when recognition fails.
  static const errorView = Key('ocr_error_view');

  /// The control that retries a failed recognition.
  static const errorRetryButton = Key('ocr_error_retry_button');

  /// The state shown when recognition found no text.
  static const emptyState = Key('ocr_empty_state');

  /// The scrollable holding the recognised text.
  static const textScrollView = Key('ocr_text_scroll_view');

  /// The control that starts recognition on a document never recognised.
  static const recogniseButton = Key('ocr_recognise_button');
}

/// Semantics labels for text recognition.
abstract final class OcrSemantics {
  /// Announced while recognition is running.
  static const extractingText = 'Extracting text';
}
