/// Widget previews for the shared state views.
///
/// Every reusable widget must preview its default, loading, empty, error and
/// long-content states. These four widgets are themselves the loading, empty
/// and error states, so each is previewed in the variants that are meaningful
/// for it, plus the long-content case that catches wrapping and truncation
/// bugs before they reach a screen.
///
/// Run with `flutter widget-preview start`. Every preview is fed by constants
/// or fixtures — no repository, camera, network or database.
library;

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/previews/preview_scaffold.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

// ---------------------------------------------------------------- loading

/// Default loading indicator.
@Preview(
  name: 'AppLoadingIndicator — default',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget loadingDefault() => const AppLoadingIndicator();

/// Loading indicator in dark mode.
@Preview(
  name: 'AppLoadingIndicator — dark',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
  brightness: Brightness.dark,
)
Widget loadingDark() => const AppLoadingIndicator();

// --------------------------------------------------------------- progress

/// Progress part-way through a multi-page operation.
@Preview(
  name: 'AppProgressIndicator — default',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget progressDefault() => const AppProgressIndicator(
  completed: 2,
  total: 5,
  label: 'Recognising text',
);

/// Progress with a cancel control.
@Preview(
  name: 'AppProgressIndicator — cancellable',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget progressCancellable() => AppProgressIndicator(
  completed: 3,
  total: 12,
  label: 'Enhancing pages',
  onCancel: () {},
);

/// Indeterminate progress, where the total is not yet known.
@Preview(
  name: 'AppProgressIndicator — indeterminate',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget progressIndeterminate() =>
    const AppProgressIndicator(completed: 0, total: 0);

/// Progress with a long label, to catch wrapping problems.
@Preview(
  name: 'AppProgressIndicator — long content',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget progressLongContent() => const AppProgressIndicator(
  completed: 7,
  total: 240,
  label:
      'Recognising text across every page of this unusually long scanned '
      'document, which may take a little while',
);

/// Progress in dark mode.
@Preview(
  name: 'AppProgressIndicator — dark',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
  brightness: Brightness.dark,
)
Widget progressDark() =>
    const AppProgressIndicator(completed: 4, total: 9, label: 'Compressing');

// ------------------------------------------------------------ empty state

/// Empty state with a title only.
@Preview(
  name: 'AppEmptyState — default',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget emptyDefault() => const AppEmptyState(title: 'Nothing here yet');

/// Empty state with an icon, message and call to action.
@Preview(
  name: 'AppEmptyState — with action',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget emptyWithAction() => AppEmptyState(
  title: 'No documents yet',
  message: 'Scan your first document to get started.',
  icon: Icons.document_scanner_outlined,
  actionLabel: 'Scan document',
  onAction: () {},
);

/// Empty state with long text, to catch overflow.
@Preview(
  name: 'AppEmptyState — long content',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget emptyLongContent() => AppEmptyState(
  title: 'No documents match the filters you have applied to this folder',
  message:
      'Try removing the date range, choosing a different folder, or searching '
      'for a shorter phrase. Archived documents are excluded unless you ask '
      'for them explicitly.',
  icon: Icons.search_off_outlined,
  actionLabel: 'Clear all filters',
  onAction: () {},
);

/// Empty state at the maximum system text scale.
///
/// The accessibility requirements demand that no content is lost at large text
/// sizes; this is the preview that shows whether that holds.
@Preview(
  name: 'AppEmptyState — large text',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
  textScaleFactor: 3,
)
Widget emptyLargeText() => AppEmptyState(
  title: 'No documents yet',
  message: 'Scan your first document to get started.',
  icon: Icons.document_scanner_outlined,
  actionLabel: 'Scan document',
  onAction: () {},
);

/// Empty state in dark mode.
@Preview(
  name: 'AppEmptyState — dark',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
  brightness: Brightness.dark,
)
Widget emptyDark() => AppEmptyState(
  title: 'No documents yet',
  message: 'Scan your first document to get started.',
  icon: Icons.document_scanner_outlined,
  actionLabel: 'Scan document',
  onAction: () {},
);

/// Empty state on a tablet viewport.
@Preview(
  name: 'AppEmptyState — tablet',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
  size: PreviewSize.tablet,
)
Widget emptyTablet() => AppEmptyState(
  title: 'No documents yet',
  message: 'Scan your first document to get started.',
  icon: Icons.document_scanner_outlined,
  actionLabel: 'Scan document',
  onAction: () {},
);

// ------------------------------------------------------------- error view

/// Error view offering a retry.
@Preview(
  name: 'AppErrorView — retry',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget errorRetry() =>
    AppErrorView(failure: const Failure.pdf(), onRetry: () {});

/// Error view for a permanently denied permission, offering system settings.
@Preview(
  name: 'AppErrorView — permission denied',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget errorPermission() => AppErrorView(
  failure: const Failure.permission(
    kind: PermissionKind.camera,
    permanentlyDenied: true,
  ),
  onOpenSettings: () {},
);

/// Error view for a full device, guiding the user to free space.
@Preview(
  name: 'AppErrorView — storage full',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget errorStorageFull() =>
    AppErrorView(failure: const Failure.storageFull(), onGoBack: () {});

/// Error view for a corrupt file, offering a way back.
@Preview(
  name: 'AppErrorView — corrupt file',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget errorCorruptFile() =>
    AppErrorView(failure: const Failure.corruptFile(), onGoBack: () {});

/// Error view with the longest message in the failure vocabulary.
@Preview(
  name: 'AppErrorView — long content',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget errorLongContent() =>
    AppErrorView(failure: const Failure.ocr(), onRetry: () {});

/// Error view in dark mode.
@Preview(
  name: 'AppErrorView — dark',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
  brightness: Brightness.dark,
)
Widget errorDark() =>
    AppErrorView(failure: const Failure.notFound(), onGoBack: () {});

/// Error view on a tablet viewport.
@Preview(
  name: 'AppErrorView — tablet',
  group: 'Core / State views',
  theme: appPreviewTheme,
  wrapper: previewSurface,
  size: PreviewSize.tablet,
)
Widget errorTablet() =>
    AppErrorView(failure: const Failure.pdf(), onRetry: () {});
