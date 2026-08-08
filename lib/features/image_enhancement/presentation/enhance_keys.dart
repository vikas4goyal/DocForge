/// Widget keys for the enhancement screen.
///
/// The values are normative — they come from `specs/image-enhancement/spec.md`.
library;

import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:flutter/widgets.dart';

/// Keys used by the enhancement screen and its widgets.
abstract final class EnhanceKeys {
  /// Root of the enhancement screen.
  static const screen = Key('enhance_screen');

  /// The Original filter control.
  static const filterOriginal = Key('enhance_filter_original');

  /// The Auto Enhance filter control.
  static const filterAuto = Key('enhance_filter_auto');

  /// The Magic Colour filter control.
  static const filterMagicColour = Key('enhance_filter_magic_colour');

  /// The Black & White filter control.
  static const filterBlackWhite = Key('enhance_filter_black_white');

  /// The Grayscale filter control.
  static const filterGrayscale = Key('enhance_filter_grayscale');

  /// The brightness slider.
  static const brightnessSlider = Key('enhance_brightness_slider');

  /// The contrast slider.
  static const contrastSlider = Key('enhance_contrast_slider');

  /// The sharpen control.
  static const sharpenControl = Key('enhance_sharpen_control');

  /// The shadow-removal toggle.
  static const shadowRemovalToggle = Key('enhance_shadow_removal_toggle');

  /// The control that returns every setting to its default.
  static const resetButton = Key('enhance_revert_button');

  /// The control that steps back through one adjustment.
  static const undoButton = Key('enhance_undo_button');

  /// The view shown when an enhancement fails.
  static const errorView = Key('enhance_error_view');

  /// The control that retries a failed enhancement.
  static const errorRetryButton = Key('enhance_error_retry_button');

  /// The page preview.
  static const preview = Key('enhance_preview');

  /// The horizontally scrolling row of filter controls.
  static const filterList = Key('enhance_filter_list');

  /// The vertically scrolling list containing all adjustment controls.
  static const controlsList = Key('enhance_controls_list');

  /// The control that confirms the enhancement and leaves the screen.
  static const doneButton = Key('enhance_done_button');

  /// The key of the control for [filter].
  ///
  /// Exists so the filter row can be built by iterating the enum rather than
  /// listing five near-identical widgets, while each control keeps the exact
  /// key the spec names.
  static Key forFilter(EnhancementFilter filter) => switch (filter) {
    EnhancementFilter.original => filterOriginal,
    EnhancementFilter.autoEnhance => filterAuto,
    EnhancementFilter.magicColour => filterMagicColour,
    EnhancementFilter.blackAndWhite => filterBlackWhite,
    EnhancementFilter.grayscale => filterGrayscale,
  };
}

/// Human-facing names for the enhancement filters.
///
/// Kept beside the keys rather than inside the widget so the screen, its
/// previews, its semantics labels and its tests all name a filter identically.
extension EnhancementFilterLabel on EnhancementFilter {
  /// The name shown to the user.
  String get label => switch (this) {
    EnhancementFilter.original => 'Original',
    EnhancementFilter.autoEnhance => 'Auto Enhance',
    EnhancementFilter.magicColour => 'Magic Colour',
    EnhancementFilter.blackAndWhite => 'Black & White',
    EnhancementFilter.grayscale => 'Grayscale',
  };

  /// A short description of what the filter does.
  String get description => switch (this) {
    EnhancementFilter.original => 'The page exactly as captured',
    EnhancementFilter.autoEnhance => 'Corrects exposure and colour cast',
    EnhancementFilter.magicColour => 'Vivid colour for printed material',
    EnhancementFilter.blackAndWhite => 'High contrast, two tones',
    EnhancementFilter.grayscale => 'Shades of grey, no colour',
  };
}

/// Semantics labels for the enhancement screen.
///
/// The sliders announce their value as a percentage rather than as the raw
/// -1.0 to 1.0 offset: "brightness, 30%" is something a listener can act on,
/// where "brightness, 0.3" requires knowing the scale.
abstract final class EnhanceSemantics {
  /// The brightness adjustment.
  static const brightness = 'Brightness';

  /// The contrast adjustment.
  static const contrast = 'Contrast';

  /// The sharpen adjustment.
  static const sharpen = 'Sharpen';

  /// The page as the current settings would render it.
  static const pagePreview = 'Page preview';
}
