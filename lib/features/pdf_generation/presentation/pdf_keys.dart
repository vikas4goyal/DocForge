/// Widget keys for the document preview and save screen.
///
/// The values are normative — they come from `specs/pdf-generation/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the PDF preview screen.
abstract final class PdfKeys {
  /// Root of the document preview screen.
  static const previewScreen = Key('pdf_preview_screen');

  /// The field holding the document's name.
  static const documentNameField = Key('pdf_document_name_field');

  /// The control that saves the document.
  static const saveButton = Key('pdf_save_button');

  /// The progress indicator shown while the PDF is generated.
  static const generationProgress = Key('pdf_generation_progress');

  /// The control that stops generation.
  static const cancelButton = Key('pdf_generation_cancel_button');

  /// The view shown when generation fails.
  static const errorView = Key('pdf_generation_error_view');

  /// The control that retries a failed generation.
  static const errorRetryButton = Key('pdf_generation_retry_button');

  /// The list of pages as they will appear in the PDF.
  static const pageList = Key('pdf_preview_page_list');

  /// The control that chooses the output quality.
  static const qualitySelector = Key('pdf_quality_selector');

  /// One page in the preview list, keyed by page identifier.
  static Key pageItem(String pageId) => Key('pdf_preview_page_$pageId');
}

/// Semantics labels for generation and its preview.
abstract final class PdfSemantics {
  /// Announced while the document is being composed.
  static const creatingDocument = 'Creating your document';

  /// The quality selector.
  static const documentQuality = 'Document quality';

  /// Announces one page of the preview by its number.
  static String page(int number) => 'Page $number';
}
