/// Widget keys for the scanning flow.
///
/// The values are normative — they come from `specs/document-scanning/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the scanning screens.
abstract final class ScanKeys {
  /// Root of the camera capture screen.
  static const cameraScreen = Key('scan_camera_screen');

  /// The shutter control.
  static const shutterButton = Key('scan_shutter_button');

  /// Counter showing how many pages have been captured.
  static const pageCounter = Key('scan_page_counter');

  /// Toggle for batch mode.
  static const batchModeToggle = Key('scan_batch_mode_toggle');

  /// Toggle for the torch.
  static const flashToggle = Key('scan_flash_toggle');

  /// Control that finishes capturing and moves to review.
  static const doneButton = Key('scan_done_button');

  /// View shown when camera permission has been refused.
  static const permissionDeniedView = Key('scan_permission_denied_view');

  /// Control that opens the system settings from the permission view.
  static const permissionSettingsButton = Key(
    'scan_permission_settings_button',
  );

  /// Control that re-requests permission when it can still be granted.
  static const permissionRetryButton = Key('scan_permission_retry_button');

  /// View shown when the camera could not be started.
  static const cameraErrorView = Key('scan_camera_error_view');

  /// Control that retries opening the camera.
  static const cameraRetryButton = Key('scan_camera_retry_button');

  /// Control that offers importing from the gallery instead.
  static const importInsteadButton = Key('scan_import_instead_button');

  /// The list of captured pages on the review screen.
  static const pageList = Key('scan_page_list');

  /// Root of the page review screen.
  static const reviewScreen = Key('scan_review_screen');

  /// Empty state shown when every page has been deleted.
  static const reviewEmptyState = Key('scan_review_empty_state');

  /// Control that saves the session as a document.
  static const saveButton = Key('scan_save_button');

  /// Control that returns to the camera to capture more pages.
  static const addPagesButton = Key('scan_add_pages_button');

  /// Root of the crop screen.
  static const cropScreen = Key('scan_crop_screen');

  /// The draggable edge overlay.
  static const edgeOverlay = Key('scan_edge_overlay');

  /// Control that confirms the crop.
  static const cropConfirmButton = Key('scan_crop_confirm_button');

  /// Control that resets the crop to the whole page.
  static const cropResetButton = Key('scan_crop_reset_button');

  /// A page row in the review list, keyed by page identifier.
  static Key pageItem(String pageId) => Key('scan_page_item_$pageId');

  /// The delete control on a page row.
  static const pageDeleteButton = Key('scan_page_delete_button');

  /// The enhance control on a page row.
  static const pageEnhanceButton = Key('scan_page_enhance_button');

  /// The crop control on a page row.
  static const pageCropButton = Key('scan_page_crop_button');

  /// A corner handle on the edge overlay, numbered clockwise from top-left.
  static Key cropHandle(int corner) => Key('scan_crop_handle_$corner');

  /// An edge handle on the overlay, numbered clockwise from the top edge.
  ///
  /// Dragging one moves the whole edge, which is how a page is squared up
  /// against a margin without chasing both of its corners.
  static Key cropEdgeHandle(int edge) => Key('scan_crop_edge_handle_$edge');

  /// The slider that turns the page beneath the selection.
  static const cropRotationSlider = Key('scan_crop_rotation_slider');

  /// Returns the page to square.
  static const cropRotationReset = Key('scan_crop_rotation_reset');

  /// Mirrors the page left-to-right.
  static const cropFlipHorizontalButton = Key('scan_crop_flip_horizontal');

  /// Mirrors the page top-to-bottom.
  static const cropFlipVerticalButton = Key('scan_crop_flip_vertical');

}
