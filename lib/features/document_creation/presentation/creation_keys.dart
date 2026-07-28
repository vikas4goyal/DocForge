/// Widget keys for the creation flow.
///
/// Every key an automated test binds to is declared here once, so a renamed
/// control is a compile error rather than a test that silently stops finding
/// anything.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:flutter/widgets.dart';

/// Keys for the page table and its dialogs.
abstract final class CreationKeys {
  /// Root of the page table screen.
  static const pageTableScreen = Key('creation_page_table_screen');

  /// The reorderable list of pages.
  static const pageList = Key('creation_page_list');

  /// Opens the sources a page can be added from.
  static const addPageButton = Key('creation_add_page_button');

  /// The sheet offering the camera and the photo library.
  static const addPageSheet = Key('creation_add_page_sheet');

  /// Adds a page from the camera.
  static const addFromCamera = Key('creation_add_from_camera');

  /// Adds a page from the photo library.
  static const addFromGallery = Key('creation_add_from_gallery');

  /// Starts saving, in the navigation bar on the trailing side.
  static const saveButton = Key('creation_save_button');

  /// Shown when the table has no pages.
  static const emptyState = Key('creation_empty_state');

  /// Shown while a page is being added.
  static const loadingIndicator = Key('creation_loading_indicator');

  /// Shown when something went wrong.
  static const errorView = Key('creation_error_view');

  /// A page row, keyed by the page it shows.
  static Key row(PageId id) => Key('creation_row_${id.value}');

  /// Opens crop and rotate for a row.
  static const rowCropButton = Key('creation_row_crop_button');

  /// Opens enhancement for a row.
  static const rowEnhanceButton = Key('creation_row_enhance_button');

  /// Deletes a row.
  static const rowDeleteButton = Key('creation_row_delete_button');

  /// The handle a row is dragged by.
  static const dragHandle = Key('creation_drag_handle');

  /// The dialog that names the document.
  static const saveDialog = Key('creation_save_dialog');

  /// The document's name.
  static const saveNameField = Key('creation_save_name_field');

  /// Turns password protection on or off.
  static const savePasswordToggle = Key('creation_save_password_toggle');

  /// The password itself.
  static const savePasswordField = Key('creation_save_password_field');

  /// The password, entered a second time.
  static const savePasswordConfirmField = Key(
    'creation_save_password_confirm_field',
  );

  /// Dismisses the dialog without writing anything.
  static const saveCancelButton = Key('creation_save_cancel_button');

  /// Writes the document.
  static const saveConfirmButton = Key('creation_save_confirm_button');

  /// Asks whether to discard a session that still has pages.
  static const discardPrompt = Key('creation_discard_prompt');

  /// Confirms discarding.
  static const discardConfirmButton = Key('creation_discard_confirm_button');

  /// Returns to the table without discarding.
  static const discardCancelButton = Key('creation_discard_cancel_button');

  /// Asks whether to replace a document of the same name.
  static const replacePrompt = Key('creation_replace_prompt');

  /// Confirms replacing.
  static const replaceConfirmButton = Key('creation_replace_confirm_button');
}
