/// Widget previews for the enhancement feature.
///
/// Every preview is fed by fixtures through a seeded Cubit, so nothing here
/// decodes an image, writes a file or spawns an isolate (`design.md` §15).
///
/// The page preview shows its placeholder rather than a photograph: a preview
/// that read a real capture from disk would render differently on every machine
/// and would fail entirely in CI, where no such file exists.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/previews/fakes/fake_cubit.dart';
import 'package:doc_forge/core/previews/preview_scaffold.dart';
import 'package:doc_forge/features/document_creation/application/usecases/render_page.dart';
import 'package:doc_forge/features/document_creation/domain/page_draft.dart';
import 'package:doc_forge/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:doc_forge/features/image_enhancement/presentation/cubit/enhancement_cubit.dart';
import 'package:doc_forge/features/image_enhancement/presentation/cubit/enhancement_state.dart';
import 'package:doc_forge/features/image_enhancement/presentation/screens/enhancement_screen.dart';
import 'package:doc_forge/features/image_enhancement/presentation/widgets/enhancement_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// An enhancement job that touches no pixels.
String previewEnhancementJob(EnhancementRequest request) =>
    request.destinationPath;

/// An [EnhancementCubit] frozen at a chosen state.
///
/// Every method that would render a preview is left inert by seeding the state
/// directly: the real Cubit renders on construction of a new setting, which
/// would replace the seeded state and make every preview identical.
class _PreviewEnhancementCubit extends EnhancementCubit
    with SeededCubit<EnhancementState> {
  _PreviewEnhancementCubit(EnhancementState state)
    : super(state.page, _previewRenderer()) {
    seed(state);
  }
}

/// A renderer that touches no filesystem, so previews stay byte-stable.
RenderPage _previewRenderer() => RenderPage(
  cacheDirectory: Directory('/preview'),
  sizeOf: (path) async => const Result<({int width, int height})>.success((
    width: 800,
    height: 600,
  )),
  render: (plan, {required destinationPath, transform}) async =>
      const Result<void>.success(null),
);

Widget _screen(EnhancementState state) => BlocProvider<EnhancementCubit>(
  create: (_) => _PreviewEnhancementCubit(state),
  child: EnhancementScreen(onDone: (_) {}),
);

/// The base state every screen preview varies from.
EnhancementState _base() => EnhancementState.initial(
  const PageDraft(
    id: PageId('preview-page-0'),
    originalImagePath: '/preview/0.jpg',
  ),
);

// ---------------------------------------------------------------------------
// Enhancement screen
// ---------------------------------------------------------------------------

/// The screen as it opens, on an unmodified page.
@Preview(
  name: 'Enhance — default',
  group: 'Enhancement',
  theme: appPreviewTheme,
)
Widget enhanceDefault() => _screen(_base());

/// A filter selected and the preview rendered.
@Preview(
  name: 'Enhance — filter applied',
  group: 'Enhancement',
  theme: appPreviewTheme,
)
Widget enhanceFilterApplied() => _screen(
  _base().copyWith(
    settings: const EnhancementSettings(filter: EnhancementFilter.magicColour),
    previewPath: '/preview/rendered.jpg',
  ),
);

/// Every adjustment moved away from its default.
@Preview(
  name: 'Enhance — adjustments',
  group: 'Enhancement',
  theme: appPreviewTheme,
)
Widget enhanceAdjustments() => _screen(
  _base().copyWith(
    settings: const EnhancementSettings(
      filter: EnhancementFilter.autoEnhance,
      brightness: 0.35,
      contrast: -0.2,
      sharpen: 0.6,
      shadowRemoval: true,
    ),
  ),
);

/// The screen while a render is in flight — this screen's loading state.
///
/// The previous preview stays on screen underneath rather than being blanked:
/// the user is mid-adjustment, and an empty frame would read as data loss.
@Preview(
  name: 'Enhance — loading a preview',
  group: 'Enhancement',
  theme: appPreviewTheme,
)
Widget enhanceLoading() => _screen(
  _base().copyWith(
    status: EnhancementStatus.previewing,
    settings: const EnhancementSettings(
      filter: EnhancementFilter.blackAndWhite,
    ),
  ),
);

/// An enhancement that failed.
@Preview(name: 'Enhance — error', group: 'Enhancement', theme: appPreviewTheme)
Widget enhanceError() => _screen(
  _base().copyWith(
    status: EnhancementStatus.failure,
    failure: const Failure.unexpected(),
  ),
);

/// An enhancement that failed because the device is out of space.
@Preview(
  name: 'Enhance — storage full',
  group: 'Enhancement',
  theme: appPreviewTheme,
)
Widget enhanceStorageFull() => _screen(
  _base().copyWith(
    status: EnhancementStatus.failure,
    failure: const Failure.storageFull(),
  ),
);

/// The screen on a phone, light.
@Preview(
  name: 'Enhance — phone, light',
  group: 'Enhancement',
  size: PreviewSize.phone,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget enhancePhoneLight() => _screen(_base());

/// The screen on a phone, dark.
@Preview(
  name: 'Enhance — phone, dark',
  group: 'Enhancement',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget enhancePhoneDark() => _screen(_base());

/// The screen on a tablet, light, where the preview takes the extra width.
@Preview(
  name: 'Enhance — tablet, light',
  group: 'Enhancement',
  size: PreviewSize.tablet,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget enhanceTabletLight() => _screen(_base());

/// The screen on a tablet, dark.
@Preview(
  name: 'Enhance — tablet, dark',
  group: 'Enhancement',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget enhanceTabletDark() => _screen(_base());

// ---------------------------------------------------------------------------
// Filter chip
// ---------------------------------------------------------------------------

/// Every filter, unselected.
@Preview(
  name: 'FilterChip — default',
  group: 'Enhancement',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget filterChipDefault() => Wrap(
  spacing: 8,
  children: [
    for (final filter in EnhancementFilter.values)
      EnhancementFilterChip(
        filter: filter,
        selected: false,
        onSelected: (_) {},
      ),
  ],
);

/// The selected filter, which must be distinguishable at a glance.
@Preview(
  name: 'FilterChip — selected',
  group: 'Enhancement',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget filterChipSelected() => Wrap(
  spacing: 8,
  children: [
    for (final filter in EnhancementFilter.values)
      EnhancementFilterChip(
        filter: filter,
        selected: filter == EnhancementFilter.magicColour,
        onSelected: (_) {},
      ),
  ],
);

/// Filters with no handler, as they appear while a bulk apply runs.
@Preview(
  name: 'FilterChip — disabled',
  group: 'Enhancement',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget filterChipDisabled() => Wrap(
  spacing: 8,
  children: [
    for (final filter in EnhancementFilter.values)
      EnhancementFilterChip(filter: filter, selected: false),
  ],
);

/// The longest filter name, which is the one that can overflow a narrow chip.
@Preview(
  name: 'FilterChip — long content',
  group: 'Enhancement',
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget filterChipLongContent() => const EnhancementFilterChip(
  filter: EnhancementFilter.blackAndWhite,
  selected: true,
);

// ---------------------------------------------------------------------------
// Adjustment slider
// ---------------------------------------------------------------------------

/// A slider at its default, which is the middle of its range.
@Preview(
  name: 'AdjustmentSlider — default',
  group: 'Enhancement',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget adjustmentSliderDefault() =>
    AdjustmentSlider(label: 'Brightness', value: 0, onChanged: (_) {});

/// A slider at each end of its range and in between.
@Preview(
  name: 'AdjustmentSlider — range',
  group: 'Enhancement',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget adjustmentSliderRange() => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    AdjustmentSlider(
      label: 'Lowest',
      value: EnhancementRules.minAdjustment,
      onChanged: (_) {},
    ),
    AdjustmentSlider(label: 'Middle', value: 0, onChanged: (_) {}),
    AdjustmentSlider(
      label: 'Highest',
      value: EnhancementRules.maxAdjustment,
      onChanged: (_) {},
    ),
  ],
);

/// A one-sided slider, as sharpening is.
@Preview(
  name: 'AdjustmentSlider — one-sided',
  group: 'Enhancement',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget adjustmentSliderOneSided() =>
    AdjustmentSlider(label: 'Sharpen', value: 0.4, min: 0, onChanged: (_) {});

/// A slider that accepts no input, as during a bulk apply.
@Preview(
  name: 'AdjustmentSlider — disabled',
  group: 'Enhancement',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget adjustmentSliderDisabled() => AdjustmentSlider(
  label: 'Contrast',
  value: 0.3,
  enabled: false,
  onChanged: (_) {},
);

/// A label long enough to compete with the value for width.
@Preview(
  name: 'AdjustmentSlider — long content',
  group: 'Enhancement',
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget adjustmentSliderLongContent() => AdjustmentSlider(
  label: 'Shadow removal strength across the whole page',
  value: -0.85,
  onChanged: (_) {},
);

// ---------------------------------------------------------------------------
// Page preview
// ---------------------------------------------------------------------------

/// The preview surface with no image yet.
@Preview(
  name: 'EnhancementPreview — empty',
  group: 'Enhancement',
  theme: appPreviewTheme,
)
Widget enhancementPreviewEmpty() =>
    const SizedBox(height: 400, child: EnhancementPreview(imagePath: null));

/// The preview surface with an image that cannot be read.
///
/// The normal case inside a preview, and a real one on device: a render can
/// fail, and the screen must not go blank when it does.
@Preview(
  name: 'EnhancementPreview — default',
  group: 'Enhancement',
  theme: appPreviewTheme,
)
Widget enhancementPreviewDefault() => const SizedBox(
  height: 400,
  child: EnhancementPreview(imagePath: '/preview/page.jpg'),
);

/// The preview surface while a newer render is in flight.
@Preview(
  name: 'EnhancementPreview — rendering',
  group: 'Enhancement',
  theme: appPreviewTheme,
)
Widget enhancementPreviewRendering() => const SizedBox(
  height: 400,
  child: EnhancementPreview(imagePath: '/preview/page.jpg', isRendering: true),
);

/// The preview surface in dark mode, where its neutral surround matters most.
@Preview(
  name: 'EnhancementPreview — dark',
  group: 'Enhancement',
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget enhancementPreviewDark() => const SizedBox(
  height: 400,
  child: EnhancementPreview(imagePath: '/preview/page.jpg'),
);
