/// Widget keys for PDF editing.
///
/// The values are normative — they come from `specs/pdf-editing/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the PDF editor and its dialogues.
abstract final class PdfEditKeys {
  /// Root of the editor screen.
  static const screen = Key('pdf_edit_screen');

  /// The grid of page thumbnails.
  static const pageGrid = Key('pdf_edit_page_grid');

  /// The thumbnail list used by Manage Pages.
  static const pageList = Key('pdf_edit_page_list');

  /// Enters row editing and drag-to-reorder mode.
  static const editPagesButton = Key('pdf_edit_pages_edit');

  /// Atomically saves the dragged page order.
  static const savePageOrderButton = Key('pdf_edit_pages_save_order');

  /// Leaves editing mode and discards an unsaved dragged order.
  static const cancelPageEditingButton = Key('pdf_edit_pages_cancel');

  /// The thumbnail of the page at zero-based [index].
  static Key page(int index) => Key('pdf_edit_page_$index');

  /// Drag handle for the page currently at [index].
  static Key pageDragHandle(int index) => Key('pdf_edit_page_drag_$index');

  /// Extract action for page [index] in normal mode.
  static Key pageExtract(int index) => Key('pdf_edit_page_extract_$index');

  /// Rotate action for page [index] in edit mode.
  static Key pageRotate(int index) => Key('pdf_edit_page_rotate_$index');

  /// Duplicate action for page [index] in edit mode.
  static Key pageDuplicate(int index) => Key('pdf_edit_page_duplicate_$index');

  /// Delete action for page [index] in edit mode.
  static Key pageDelete(int index) => Key('pdf_edit_page_delete_$index');

  /// The control that rotates the selected page.
  static const rotateButton = Key('pdf_edit_rotate_button');

  /// The control that deletes the selected pages.
  static const deleteButton = Key('pdf_edit_delete_button');

  /// The control that confirms a deletion.
  static const deleteConfirmButton = Key('pdf_edit_delete_confirm_button');

  /// The control that extracts the selected pages into a new document.
  static const extractButton = Key('pdf_edit_extract_button');

  /// The control that duplicates the selected page.
  static const duplicateButton = Key('pdf_edit_duplicate_button');

  /// The control that compresses the document.
  static const compressButton = Key('pdf_compress_button');

  /// Compresses into a new document while preserving the source.
  static const compressCopyButton = Key('pdf_compress_copy_button');

  /// The list of documents being merged, in the order chosen.
  static const mergeOrderList = Key('pdf_merge_order_list');

  /// The control that performs the merge.
  static const mergeConfirmButton = Key('pdf_merge_confirm_button');

  /// The control that performs the split.
  static const splitConfirmButton = Key('pdf_split_confirm_button');

  /// One-based page after which the split occurs.
  static const splitBoundaryField = Key('pdf_split_boundary_field');

  /// Name of the first split output.
  static const splitFirstNameField = Key('pdf_split_first_name');

  /// Name of the second split output.
  static const splitSecondNameField = Key('pdf_split_second_name');

  /// Dedicated screen used to review and name split outputs.
  static const pageNamingScreen = Key('page_naming_screen');

  /// Name reviewed for the merged output.
  static const mergeOutputNameField = Key('pdf_merge_output_name');

  /// Continues from operation-specific input to effect review.
  static const inputContinue = Key('pdf_edit_input_continue');

  /// The field holding the watermark text.
  static const watermarkTextField = Key('pdf_watermark_text_field');

  /// The preview of how the watermark will appear.
  static const watermarkPreview = Key('pdf_watermark_preview');

  /// The control that applies the watermark.
  static const watermarkConfirmButton = Key('pdf_watermark_confirm_button');

  /// Applies a watermark to a new copy while preserving the source.
  static const watermarkCopyButton = Key('pdf_watermark_copy_button');

  /// The field holding a new password.
  static const protectPasswordField = Key('pdf_protect_password_field');

  /// The control that applies password protection.
  static const protectConfirmButton = Key('pdf_protect_confirm_button');

  /// The control that removes an existing password.
  static const removePasswordButton = Key('pdf_remove_password_button');

  /// The view showing the document's metadata.
  static const metadataView = Key('pdf_metadata_view');

  /// The indicator shown while an operation runs.
  static const progress = Key('pdf_edit_progress');

  /// Responsive overflow holding contextual page actions.
  static const actionsMenu = Key('pdf_edit_actions_menu');

  /// Shared adaptive operation input/review surface.
  static const operationSheet = Key('pdf_edit_operation_sheet');

  /// Summary of the effect awaiting confirmation.
  static const review = Key('pdf_edit_review');

  /// Confirms one reviewed operation.
  static const confirm = Key('pdf_edit_confirm');

  /// Cancels review without mutation.
  static const cancel = Key('pdf_edit_cancel');

  /// Visible result of a completed operation.
  static const result = Key('pdf_edit_result');

  /// Finishes a result flow and returns to Dashboard.
  static const resultDone = Key('pdf_edit_result_done');

  /// The view shown when an operation fails.
  static const errorView = Key('pdf_edit_error_view');

  /// The control that retries after a failure.
  static const errorRetryButton = Key('pdf_edit_error_retry_button');
}

/// Semantics labels for the PDF editor.
abstract final class PdfEditSemantics {
  /// Announces a metadata row as its name and its value together, for the same
  /// reason the settings tiles do: two separately announced items leave the
  /// listener to pair them.
  static String metadataRow(String label, String value) => '$label, $value';
}
