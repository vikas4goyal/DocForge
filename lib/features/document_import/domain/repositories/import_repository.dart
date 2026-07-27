/// The seams between importing and the platform's content sources.
///
/// Separate interfaces per source, because each is granted by a different
/// permission, fails in a different way and is substituted independently — a
/// test for the share-sheet path has no interest in the photo library.
library;

import 'package:doc_forge/core/failures/result.dart';

/// Offers the photo library.
abstract interface class GalleryPicker {
  /// Asks the user to choose images, returning their paths in selection order.
  ///
  /// Returns an empty list when the user cancelled. Cancellation is a
  /// successful empty result rather than a failure: nothing went wrong and the
  /// spec requires the application to return to the previous screen with
  /// nothing said.
  ///
  /// Fails with a permission failure when photo access was refused, which the
  /// UI turns into the permission-denied view rather than an error.
  Future<Result<List<String>>> pickImages();
}

/// Offers the device's file browser.
abstract interface class FileBrowser {
  /// Asks the user to choose PDFs or images, returning their paths in order.
  ///
  /// As with [GalleryPicker.pickImages], an empty list means cancelled.
  Future<Result<List<String>>> pickFiles();
}

/// Content handed to DocForge by another application.
///
/// Covers both cases the spec names: a file shared while DocForge was closed,
/// which is waiting at launch, and one shared while it was already running.
abstract interface class SharedContentSource {
  /// Content that was shared before the application finished launching.
  ///
  /// Empty when DocForge was opened normally. Read once, at startup, so a
  /// cold-launch share is not lost before anything is listening.
  Future<Result<List<String>>> pending();

  /// Content shared while the application is running.
  ///
  /// A broadcast stream, so both the router and a screen can listen without
  /// one of them consuming the other's events.
  Stream<List<String>> get incoming;

  /// Releases the platform listener.
  Future<void> dispose();
}

/// Reports what a PDF file is, without rendering it.
///
/// Declared here rather than reused from the viewer because a feature may not
/// import another feature; the implementation is supplied by the composition
/// root (`design.md` §2).
abstract interface class ImportedPdfInspector {
  /// Returns the page count of the PDF at [filePath].
  ///
  /// Fails with a corrupt-file failure when it cannot be parsed and with an
  /// authentication failure when it is password-protected and [password] does
  /// not open it — which is what the import flow turns into its password
  /// prompt.
  Future<Result<int>> pageCountOf(String filePath, {String? password});
}
