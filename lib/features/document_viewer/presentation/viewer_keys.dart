/// Widget keys for the document viewer.
///
/// The values are normative — they come from `specs/document-viewer/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the viewer screen.
abstract final class ViewerKeys {
  /// Root of the viewer screen.
  static const screen = Key('viewer_screen');

  /// The indicator showing the current page and the total.
  static const pageIndicator = Key('viewer_page_indicator');

  /// Compact control that opens page-jump input.
  static const pageJumpButton = Key('viewer_page_jump_button');

  /// Dialog containing intentional numeric page input.
  static const pageJumpDialog = Key('viewer_page_jump_dialog');

  /// Numeric field shown only inside the jump dialog.
  static const pageJumpField = Key('viewer_page_jump_field');

  /// Backwards-compatible source alias for the intentional jump field.
  static const jumpToPageField = pageJumpField;

  /// Confirms a valid page jump.
  static const pageJumpConfirm = Key('viewer_page_jump_confirm');

  /// Cancels the jump dialog without changing page.
  static const pageJumpCancel = Key('viewer_page_jump_cancel');

  /// Responsive overflow containing secondary viewer actions.
  static const actionsMenu = Key('viewer_actions_menu');

  /// Toggles favourite status without leaving the open document.
  static const favouriteButton = Key('viewer_favourite_button');

  /// Opens the metadata-focused document Detail screen.
  static const documentDetailsButton = Key('viewer_document_details_button');

  /// The control that shares the document.
  static const shareButton = Key('viewer_share_button');

  /// The control that prints the document.
  static const printButton = Key('viewer_print_button');

  /// The control that opens PDF compression.
  static const compressButton = Key('viewer_compress_button');

  /// The control that opens PDF splitting.
  static const splitButton = Key('viewer_split_button');

  /// The control that opens watermark settings.
  static const watermarkButton = Key('viewer_watermark_button');

  /// The control that opens password settings.
  static const passwordButton = Key('viewer_password_button');

  /// Opens page selection and page-derived actions.
  static const managePagesButton = Key('viewer_manage_pages_button');

  /// The field for a protected document's password.
  static const passwordField = Key('viewer_password_field');

  /// The control that submits the password.
  static const unlockButton = Key('viewer_unlock_button');

  /// The indicator shown while the document is being opened.
  static const loadingIndicator = Key('viewer_loading_indicator');

  /// The view shown when a document cannot be opened.
  static const errorView = Key('viewer_error_view');

  /// The control that returns from the error view.
  static const errorBackButton = Key('viewer_error_back_button');

  /// The scrollable holding the document's pages.
  static const pageView = Key('viewer_page_view');
}

/// Semantics labels for the viewer.
abstract final class ViewerSemantics {
  /// Announces which page of how many the reader is on.
  static String pageIndicator(String pageLabel) => 'Page $pageLabel';

  /// Labels the Viewer favourite toggle with its resulting action.
  static String favourite(String title, {required bool isFavourite}) =>
      isFavourite
      ? 'Remove $title from favourites'
      : 'Add $title to favourites';

  /// Labels the Viewer action that opens metadata and lifecycle controls.
  static const documentDetails = 'Show document details';
}
