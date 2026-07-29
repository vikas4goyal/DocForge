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

  /// The field for jumping to a page.
  static const jumpToPageField = Key('viewer_jump_to_page_field');

  /// The control that shares the document.
  static const shareButton = Key('viewer_share_button');

  /// The control that prints the document.
  static const printButton = Key('viewer_print_button');

  /// The control that opens the editing tools.
  static const editButton = Key('viewer_edit_button');

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

  /// The panel showing the document's recognised text, on wide layouts.
  static const textPanel = Key('viewer_text_panel');
}

/// Semantics labels for the viewer.
abstract final class ViewerSemantics {
  /// Announces which page of how many the reader is on.
  static String pageIndicator(String pageLabel) => 'Page $pageLabel';
}
