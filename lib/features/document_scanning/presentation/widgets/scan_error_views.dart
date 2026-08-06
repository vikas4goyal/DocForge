/// The two blocking states a scan can start in.
///
/// Both are full-screen rather than a banner: neither leaves anything usable
/// behind them, and the spec requires each to carry its own specific recovery
/// rather than a generic retry.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/features/document_scanning/presentation/scan_keys.dart';
import 'package:flutter/material.dart';

/// Shown when camera permission has been refused.
class ScanPermissionDeniedView extends StatelessWidget {
  /// Creates the permission-denied view.
  const ScanPermissionDeniedView({
    required this.permanentlyDenied,
    required this.onOpenSettings,
    super.key,
    this.onRetry,
  });

  /// Whether the user chose "don't ask again".
  ///
  /// Decides which control is offered: re-requesting a permanently denied
  /// permission shows no system prompt, so a retry button would do nothing at
  /// all — the worst kind of control.
  final bool permanentlyDenied;

  /// Opens the system settings.
  final VoidCallback onOpenSettings;

  /// Re-requests the permission. Ignored when [permanentlyDenied].
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ScanBlockingView(
      viewKey: ScanKeys.permissionDeniedView,
      icon: Icons.no_photography_outlined,
      title: 'Camera access is needed to scan',
      // States what the permission is for, not merely that it is missing. A
      // user deciding whether to grant it needs the reason.
      message:
          'DocScanly uses the camera only to capture the pages you scan. '
          'Nothing is uploaded, and images stay on this device.',
      colour: theme.colorScheme.primary,
      actions: [
        if (permanentlyDenied)
          FilledButton(
            key: ScanKeys.permissionSettingsButton,
            onPressed: onOpenSettings,
            child: const Text('Open settings'),
          )
        else ...[
          FilledButton(
            key: ScanKeys.permissionRetryButton,
            onPressed: onRetry,
            child: const Text('Allow camera access'),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: ScanKeys.permissionSettingsButton,
            onPressed: onOpenSettings,
            child: const Text('Open settings'),
          ),
        ],
      ],
    );
  }
}

/// Shown when the camera could not be started.
class ScanCameraErrorView extends StatelessWidget {
  /// Creates the camera-error view.
  const ScanCameraErrorView({
    required this.failure,
    required this.onRetry,
    required this.onImportInstead,
    super.key,
  });

  /// Why the camera is unusable.
  final Failure failure;

  /// Tries to open the camera again.
  final VoidCallback onRetry;

  /// Offers the photo library instead.
  ///
  /// Required by the spec: a camera that another app is holding may stay held,
  /// and a user with a photo of the document already taken should not be stuck.
  final VoidCallback onImportInstead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ScanBlockingView(
      viewKey: ScanKeys.cameraErrorView,
      icon: Icons.videocam_off_outlined,
      title: 'The camera is unavailable',
      message: failure.presentation.message,
      colour: theme.colorScheme.error,
      actions: [
        FilledButton(
          key: ScanKeys.cameraRetryButton,
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: ScanKeys.importInsteadButton,
          onPressed: onImportInstead,
          child: const Text('Choose from gallery instead'),
        ),
      ],
    );
  }
}

/// Shared layout for the two blocking scan states.
class _ScanBlockingView extends StatelessWidget {
  const _ScanBlockingView({
    required this.viewKey,
    required this.icon,
    required this.title,
    required this.message,
    required this.colour,
    required this.actions,
  });

  final Key viewKey;
  final IconData icon;
  final String title;
  final String message;
  final Color colour;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      key: viewKey,
      child: SingleChildScrollView(
        // Scrollable so every control stays reachable at the maximum system
        // text scale rather than being clipped off the bottom.
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative: the heading below carries the meaning, so announcing
            // an icon name would only add noise for a screen reader.
            ExcludeSemantics(child: Icon(icon, size: 48, color: colour)),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...actions,
          ],
        ),
      ),
    );
  }
}
