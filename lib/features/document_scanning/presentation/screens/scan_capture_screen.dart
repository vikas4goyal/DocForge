/// The camera capture screen.
library;

import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/document_scanning/domain/scan_session.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_states.dart';
import 'package:doc_scanly/features/document_scanning/presentation/scan_keys.dart';
import 'package:doc_scanly/features/document_scanning/presentation/widgets/scan_error_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Builds the live camera preview.
///
/// Injected rather than built here because a `CameraPreview` needs the plugin's
/// controller, which a widget test cannot create — and a screen that reached
/// for one directly could not be tested or previewed at all.
typedef CameraPreviewBuilder = Widget Function(BuildContext context);

/// Captures pages with the device camera.
///
/// Releases the camera on every exit path: moving on to review, abandoning the
/// scan, and — as the backstop — the Cubit closing when the route is popped.
class ScanCaptureScreen extends StatefulWidget {
  /// Creates the capture screen.
  const ScanCaptureScreen({
    required this.previewBuilder,
    required this.onFinished,
    required this.onPageCaptured,
    required this.onCancelled,
    required this.onOpenSettings,
    required this.onImportInstead,
    super.key,
  });

  /// Builds the live preview.
  final CameraPreviewBuilder previewBuilder;

  /// Called with the captured pages once the user is done.
  final VoidCallback onFinished;

  /// Called with each page as it is captured, before the flow moves on.
  ///
  /// Gives the page straight to the editors while the document is still in
  /// front of the user: edges are never more obviously wrong than in the second
  /// after the shot, and correcting there saves finding the page again in a
  /// list later.
  final Future<void> Function(int index, CapturedPage page) onPageCaptured;

  /// Called when the user abandons the scan.
  final VoidCallback onCancelled;

  /// Opens the system settings so camera access can be granted.
  final VoidCallback onOpenSettings;

  /// Offers the photo library instead of the camera.
  final VoidCallback onImportInstead;

  @override
  State<ScanCaptureScreen> createState() => _ScanCaptureScreenState();
}

class _ScanCaptureScreenState extends State<ScanCaptureScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ScanCaptureCubit>().start(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanCaptureCubit, ScanCaptureState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure && current.failure != null,
      listener: (context, state) {
        // A failure while the preview is running — a failed capture, a failed
        // torch — is transient: the camera still works and the captured pages
        // are intact, so it belongs in a snackbar rather than on a full screen.
        if (state.status != ScanCaptureStatus.failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message ?? '')));
        }
      },
      builder: (context, state) => Scaffold(
        key: ScanKeys.cameraScreen,
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: _PageCounter(count: state.pageCount),
          leading: IconButton(
            key: ScanKeys.captureCancelButton,
            tooltip: 'Cancel scanning',
            onPressed: () async {
              await context.read<ScanCaptureCubit>().abandon();
              widget.onCancelled();
            },
            icon: const Icon(Icons.close),
          ),
          actions: [
            if (state.status == ScanCaptureStatus.ready)
              _TorchToggle(isOn: state.torchOn),
          ],
        ),
        body: switch (state.status) {
          ScanCaptureStatus.failure when state.isPermissionDenied =>
            ScanPermissionDeniedView(
              permanentlyDenied: state.isPermanentlyDenied,
              onOpenSettings: widget.onOpenSettings,
              onRetry: () => context.read<ScanCaptureCubit>().start(),
            ),
          ScanCaptureStatus.failure => ScanCameraErrorView(
            failure: state.failure ?? cameraUnavailableFailure,
            onRetry: () => context.read<ScanCaptureCubit>().start(),
            onImportInstead: widget.onImportInstead,
          ),
          ScanCaptureStatus.idle || ScanCaptureStatus.preparing => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          ScanCaptureStatus.ready || ScanCaptureStatus.capturing => Stack(
            fit: StackFit.expand,
            children: [
              widget.previewBuilder(context),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Center(
                  child: Semantics(
                    label: state.resolutionLabel,
                    liveRegion: true,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        key: ScanKeys.cameraResolutionStatus,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          state.resolutionLabel.replaceAll(', ', ' • '),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (state.status == ScanCaptureStatus.capturing)
                const ColoredBox(
                  color: Color(0x66000000),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 14),
                            Text('Processing capture…'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        },
        bottomNavigationBar: state.status == ScanCaptureStatus.failure
            ? null
            : _CaptureControls(
                state: state,
                onFinished: widget.onFinished,
                onPageCaptured: widget.onPageCaptured,
              ),
      ),
    );
  }
}

/// The shutter, batch toggle and done control.
class _CaptureControls extends StatelessWidget {
  const _CaptureControls({
    required this.state,
    required this.onFinished,
    required this.onPageCaptured,
  });

  final ScanCaptureState state;
  final VoidCallback onFinished;
  final Future<void> Function(int index, CapturedPage page) onPageCaptured;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ScanCaptureCubit>();

    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BatchModeToggle(enabled: state.batchMode),
              _ShutterButton(
                enabled: state.canCapture,
                onPressed: () async {
                  final before = cubit.pages.length;
                  await cubit.capture();

                  // Only when a page actually landed: a refused permission or a
                  // full disk leaves the count unchanged, and opening an editor
                  // over nothing would turn a failed shot into a puzzle.
                  if (cubit.pages.length > before) {
                    await onPageCaptured(
                      cubit.pages.length - 1,
                      cubit.pages.last,
                    );
                  }

                  // In batch mode the preview stays put for the next page,
                  // which is exactly what batch mode means.
                  if (!cubit.state.batchMode && cubit.pages.isNotEmpty) {
                    await cubit.release();
                    onFinished();
                  }
                },
              ),
              _DoneButton(
                enabled: state.pageCount > 0,
                onPressed: () async {
                  await cubit.release();
                  onFinished();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shutter.
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: ScanSemantics.capturePage,
      child: ExcludeSemantics(
        child: IconButton.filled(
          key: ScanKeys.shutterButton,
          onPressed: enabled ? onPressed : null,
          iconSize: 40,
          // Comfortably beyond the 48dp minimum: the shutter is the control
          // the user reaches for one-handed while holding a page steady.
          constraints: const BoxConstraints(minWidth: 72, minHeight: 72),
          icon: const Icon(Icons.camera_alt),
        ),
      ),
    );
  }
}

/// The batch-mode toggle.
class _BatchModeToggle extends StatelessWidget {
  const _BatchModeToggle({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: enabled,
      label: enabled ? 'Batch mode on' : 'Batch mode off',
      child: ExcludeSemantics(
        child: IconButton(
          key: ScanKeys.batchModeToggle,
          onPressed: () =>
              context.read<ScanCaptureCubit>().setBatchMode(enabled: !enabled),
          color: enabled ? Theme.of(context).colorScheme.primary : Colors.white,
          constraints: const BoxConstraints(
            minWidth: AppTheme.minimumTouchTarget,
            minHeight: AppTheme.minimumTouchTarget,
          ),
          icon: Icon(enabled ? Icons.burst_mode : Icons.burst_mode_outlined),
        ),
      ),
    );
  }
}

/// The torch toggle.
class _TorchToggle extends StatelessWidget {
  const _TorchToggle({required this.isOn});

  final bool isOn;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isOn,
      label: isOn ? 'Flash on' : 'Flash off',
      child: ExcludeSemantics(
        child: IconButton(
          key: ScanKeys.flashToggle,
          onPressed: () => context.read<ScanCaptureCubit>().setTorch(on: !isOn),
          constraints: const BoxConstraints(
            minWidth: AppTheme.minimumTouchTarget,
            minHeight: AppTheme.minimumTouchTarget,
          ),
          icon: Icon(isOn ? Icons.flash_on : Icons.flash_off),
        ),
      ),
    );
  }
}

/// The control that finishes capturing.
class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: ScanSemantics.reviewCaptured,
      child: ExcludeSemantics(
        child: IconButton(
          key: ScanKeys.doneButton,
          onPressed: enabled ? onPressed : null,
          color: Colors.white,
          constraints: const BoxConstraints(
            minWidth: AppTheme.minimumTouchTarget,
            minHeight: AppTheme.minimumTouchTarget,
          ),
          icon: const Icon(Icons.check_circle_outline),
        ),
      ),
    );
  }
}

/// How many pages have been captured so far.
class _PageCounter extends StatelessWidget {
  const _PageCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 page captured' : '$count pages captured';

    return Semantics(
      // Announced as it changes, so a screen-reader user gets confirmation
      // that the shutter actually fired.
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Text(
          key: ScanKeys.pageCounter,
          '$count',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
