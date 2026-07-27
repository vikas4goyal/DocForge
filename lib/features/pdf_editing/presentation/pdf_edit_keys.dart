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

  /// The thumbnail of the page at zero-based [index].
  static Key page(int index) => Key('pdf_edit_page_$index');

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

  /// The list of documents being merged, in the order chosen.
  static const mergeOrderList = Key('pdf_merge_order_list');

  /// The control that performs the merge.
  static const mergeConfirmButton = Key('pdf_merge_confirm_button');

  /// The control that performs the split.
  static const splitConfirmButton = Key('pdf_split_confirm_button');

  /// The field holding the watermark text.
  static const watermarkTextField = Key('pdf_watermark_text_field');

  /// The preview of how the watermark will appear.
  static const watermarkPreview = Key('pdf_watermark_preview');

  /// The control that applies the watermark.
  static const watermarkConfirmButton = Key('pdf_watermark_confirm_button');

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

  /// The control that abandons an in-progress operation.
  static const cancelButton = Key('pdf_edit_cancel_button');

  /// The view shown when an operation fails.
  static const errorView = Key('pdf_edit_error_view');

  /// The control that retries after a failure.
  static const errorRetryButton = Key('pdf_edit_error_retry_button');
}
