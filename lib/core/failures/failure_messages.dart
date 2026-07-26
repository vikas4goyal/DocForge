/// Maps every [Failure] to the message and recovery action the user sees.
///
/// The specs require a clear message and a recovery option for every failure
/// path. Centralising the mapping here means a new [Failure] variant produces a
/// compile error in this one file rather than a silent blank error view, and it
/// gives the presentation layer a single, testable place to consult.
///
/// Strings are English-only for V1; when localisation arrives, this is the only
/// file that changes.
library;

import 'package:doc_forge/core/failures/failure.dart';

/// The recovery action offered alongside a failure message.
enum RecoveryAction {
  /// Retry the operation that failed.
  retry,

  /// Open the system settings so a permission can be granted.
  openSettings,

  /// Guide the user to free device storage.
  freeStorage,

  /// Offer exporting to device storage instead of sharing.
  exportInstead,

  /// Return to the previous screen; the operation cannot be retried usefully.
  goBack,

  /// Nothing to offer — used only for user-initiated cancellation.
  none,
}

/// A user-facing description of a failure and how to recover from it.
class FailurePresentation {
  /// Creates a presentation with [message] and [action].
  const FailurePresentation({required this.message, required this.action});

  /// The human-readable message. Never contains technical detail.
  final String message;

  /// The recovery action to offer.
  final RecoveryAction action;
}

/// Presentation mapping for [Failure] values.
extension FailurePresentationX on Failure {
  /// The message and recovery action to show for this failure.
  ///
  /// Exhaustive by construction: [Failure] is sealed, so adding a variant
  /// without extending this switch fails to compile.
  FailurePresentation get presentation => switch (this) {
    CameraFailure(:final inUseByAnotherApp) => FailurePresentation(
      message: inUseByAnotherApp
          ? 'The camera is being used by another app. Close it and try again.'
          : 'The camera could not be started. Please try again.',
      action: RecoveryAction.retry,
    ),

    PermissionFailure(:final kind, :final permanentlyDenied) =>
      FailurePresentation(
        message: switch (kind) {
          PermissionKind.camera =>
            'DocForge needs camera access to scan documents.',
          PermissionKind.photos =>
            'DocForge needs photo access to import images.',
          PermissionKind.files =>
            'DocForge needs file access to import documents.',
        },
        // A permanently denied permission cannot be re-requested in-app, so
        // offering a retry would silently do nothing.
        action: permanentlyDenied
            ? RecoveryAction.openSettings
            : RecoveryAction.retry,
      ),

    OcrFailure() => const FailurePresentation(
      message:
          'Text could not be recognised on this page. '
          'The document is still saved and can be used.',
      action: RecoveryAction.retry,
    ),

    PdfFailure() => const FailurePresentation(
      message: 'The PDF could not be processed. Please try again.',
      action: RecoveryAction.retry,
    ),

    StorageFullFailure() => const FailurePresentation(
      message:
          'There is not enough space on your device to finish. '
          'Free up some space and try again.',
      action: RecoveryAction.freeStorage,
    ),

    ImportFailure(:final unsupportedType) => FailurePresentation(
      message: unsupportedType
          ? 'That file type is not supported. Choose a PDF or an image.'
          : 'The file could not be imported. Please try again.',
      action: RecoveryAction.retry,
    ),

    ExportFailure(:final noReceivingApp) => FailurePresentation(
      message: noReceivingApp
          ? 'No app on this device can receive that content. '
                'You can save it to your device instead.'
          : 'The document could not be shared. Please try again.',
      action: noReceivingApp
          ? RecoveryAction.exportInstead
          : RecoveryAction.retry,
    ),

    AuthFailure(:final rejected, :final notEnrolled) => FailurePresentation(
      message: notEnrolled
          ? 'Set up a fingerprint, face unlock or device passcode to use the '
                'app lock.'
          : rejected
          ? 'Authentication failed. Please try again.'
          : 'Authentication is unavailable right now. Please try again.',
      action: notEnrolled ? RecoveryAction.openSettings : RecoveryAction.retry,
    ),

    // Correctable input: the message states what to change, and there is no
    // recovery action because the user is already on the screen that fixes it.
    ValidationFailure(:final issue) => FailurePresentation(
      message: switch (issue) {
        ValidationIssue.emptyName => 'Enter a name.',
        ValidationIssue.duplicateFolderName =>
          'A folder with this name already exists.',
        ValidationIssue.documentWouldHaveNoPages =>
          'A document must keep at least one page.',
      },
      action: RecoveryAction.none,
    ),

    NotFoundFailure() => const FailurePresentation(
      message: 'That item no longer exists.',
      action: RecoveryAction.goBack,
    ),

    CorruptFileFailure() => const FailurePresentation(
      message: 'This file is damaged and cannot be opened.',
      action: RecoveryAction.goBack,
    ),

    SecureStorageFailure() => const FailurePresentation(
      message: 'Secure storage is unavailable on this device right now.',
      action: RecoveryAction.retry,
    ),

    StorageFailure() => const FailurePresentation(
      message: 'Something went wrong reading your documents. Please try again.',
      action: RecoveryAction.retry,
    ),

    // Cancellation is a user decision, not an error. The UI shows nothing.
    CancelledFailure() => const FailurePresentation(
      message: '',
      action: RecoveryAction.none,
    ),

    UnexpectedFailure() => const FailurePresentation(
      message: 'Something went wrong. Please try again.',
      action: RecoveryAction.retry,
    ),
  };
}
