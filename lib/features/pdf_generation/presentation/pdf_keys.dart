/// Widget keys for the document preview and save screen.
///
/// The values are normative — they come from `specs/pdf-generation/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the PDF preview screen.
abstract final class PdfKeys {
  /// Root of the dedicated Save PDF workflow.
  static const saveScreen = Key('pdf_save_screen');

  /// Document-level percentage slider.
  static const saveQualitySlider = Key('pdf_save_quality_slider');

  /// Exact candidate size, progress, failure, and Retry region.
  static const outputSizeStatus = Key('pdf_output_size_status');

  /// Retries a failed exact-size calculation.
  static const outputSizeRetry = Key('pdf_output_size_retry');

  /// Shared creation name field key used by the dedicated Save route.
  static const saveNameField = Key('creation_save_name_field');

  /// Shared password input key used only inside the focused dialog.
  static const savePasswordField = Key('creation_save_password_field');

  /// Shared confirmation input key used only inside the focused dialog.
  static const savePasswordConfirmField = Key(
    'creation_save_password_confirm_field',
  );

  /// Shared final Save action key.
  static const saveConfirmButton = Key('creation_save_confirm_button');

  /// Opens a read-only candidate preview.
  static const savePreviewButton = Key('pdf_save_preview_button');

  /// Resets every explicit page quality exception.
  static const pageQualityResetAll = Key('pdf_page_quality_reset_all');

  /// Percentage slider inside a page-quality dialog.
  static const pageQualitySlider = Key('pdf_page_quality_slider');

  /// Makes the selected page follow document quality.
  static const pageQualityUseDocument = Key('pdf_page_quality_use_document');

  /// Opens the password-entry dialog.
  static const saveSetPassword = Key('pdf_save_set_password');

  /// Non-secret status shown when password protection is configured.
  static const savePasswordEnabled = Key('pdf_save_password_enabled');

  /// Removes the route-scoped password draft.
  static const saveRemovePassword = Key('pdf_save_remove_password');

  /// Confirms matching password inputs without exposing their text to state.
  static const savePasswordDialogConfirm = Key(
    'pdf_save_password_dialog_confirm',
  );

  /// Modal progress and cancellation surface for preview or commit.
  static const jobProgressDialog = Key('pdf_job_progress_dialog');

  /// Determinate percentage inside [jobProgressDialog].
  static const jobProgressIndicator = Key('pdf_job_progress_indicator');

  /// Cancels the currently modal PDF operation.
  static const jobCancelButton = Key('pdf_job_cancel_button');

  /// Root of the read-only candidate preview.
  static const temporaryPreviewScreen = Key('pdf_temporary_preview_screen');

  /// Closes the temporary preview.
  static const temporaryPreviewClose = Key('pdf_temporary_preview_close');

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

  /// Page-specific quality row on Save PDF.
  static Key savePageQuality(String pageId) =>
      Key('pdf_save_page_quality_$pageId');
}

/// Semantics labels for generation and its preview.
abstract final class PdfSemantics {
  /// Opens read-only PDF preview.
  static const previewPdf = 'Preview PDF';

  /// Cancels candidate preparation or commit.
  static const cancelOperation = 'Cancel PDF operation';

  /// Closes the read-only candidate preview.
  static const closePreview = 'Close PDF preview';

  /// Opens secret entry.
  static const setPassword = 'Set PDF password';

  /// Removes configured protection.
  static const removePassword = 'Remove PDF password';

  /// Resets every explicit page exception.
  static const resetAllPageQuality = 'Reset all page quality overrides';

  /// Announces document quality at [percent].
  static String quality(int percent) => 'PDF quality, $percent percent';

  /// Announces a page and its effective quality.
  static String pageQuality(
    int page,
    int percent, {
    required bool overridden,
  }) => 'Page $page, $percent percent${overridden ? ', custom quality' : ''}';

  /// Announced while the document is being composed.
  static const creatingDocument = 'Creating your document';

  /// The quality selector.
  static const documentQuality = 'Document quality';

  /// Announces one page of the preview by its number.
  static String page(int number) => 'Page $number';
}
