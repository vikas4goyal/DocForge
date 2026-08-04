/// Widget keys for the creation flow.
///
/// Every key an automated test binds to is declared here once, so a renamed
/// control is a compile error rather than a test that silently stops finding
/// anything.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
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

  /// The shared prefix of every page-row key.
  ///
  /// Distinct from the row *actions* below, which are `creation_row_*`: a
  /// finder matching on that prefix would count a row's three action buttons
  /// as three more rows, and report one page as four.
  static const rowPrefix = 'creation_page_row_';

  /// A page row, keyed by the page it shows.
  static Key row(PageId id) => Key('$rowPrefix${id.value}');

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

/// Semantics labels for the page table.
///
/// A page of a scan has no title, so every label here is built from the page's
/// *position*: "page 3 of 7" is what the user is actually tracking, and it is
/// the only thing that distinguishes one row from another.
abstract final class CreationSemantics {
  /// Announces a row as its position in the document.
  static String pageRow(int pageNumber, int pageCount) =>
      'Page $pageNumber of $pageCount';

  /// The row's value, which the reorder actions move between.
  ///
  /// Required whenever a node offers increase or decrease: the framework
  /// asserts on an action with nothing for the reader to announce moving to.
  static String pagePosition(int pageNumber) => 'Page $pageNumber';

  /// Names the crop action *and* the page it applies to.
  ///
  /// "Crop" alone tells a screen reader user nothing about which of seven rows
  /// they are on.
  static String cropPage(int pageNumber) => 'Crop and rotate page $pageNumber';

  /// Names the enhance action and its page.
  static String enhancePage(int pageNumber) => 'Enhance page $pageNumber';

  /// Names the delete action and its page.
  static String deletePage(int pageNumber) => 'Delete page $pageNumber';

  /// The action that restores a page the user has just deleted.
  static const undoDelete = 'Undo';

  /// The dialog that names the document before it is written.
  static const saveDialog = 'Save PDF';

  /// The document's name.
  ///
  /// The field's visible label *is* its spoken label — Flutter derives the
  /// field's semantics from the decoration — so this is one constant serving
  /// both rather than two that could disagree.
  static const saveNameField = 'Name';

  /// The control that turns password protection on.
  static const savePasswordToggle = 'Protect with password';

  /// The password itself.
  static const savePasswordField = 'Password';

  /// The password, entered a second time.
  static const savePasswordConfirmField = 'Confirm password';

  /// Writes the document.
  ///
  /// Names the object as well as the verb, because "Save" on its own is what a
  /// listener hears in every dialog the application has.
  static const saveConfirm = 'Save document';

  /// Leaves the dialog without writing anything.
  static const saveCancel = 'Cancel saving';

  /// Explains what protecting the document actually does.
  static const savePasswordHint =
      'Other apps will need this password to open the file';
}
