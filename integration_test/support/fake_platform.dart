/// The platform edges a Tier-3 flow substitutes, and nothing else.
///
/// The suite fakes exactly the seven things a device does that a test cannot
/// drive or predict: camera capture, edge detection, text recognition,
/// biometric authentication, the share sheet, the print dialogue, and the
/// file and gallery pickers. Isar, the filesystem and the public library folder
/// stay real, because most of what breaks in an offline-first document app
/// breaks precisely there — a suite that faked the database would prove the UI
/// is self-consistent and nothing about whether the user's document survives
/// (`design.md` D2).
///
/// Every fake here already ships in `lib/`, because the widget previews need
/// them. This file only *bundles* them, so a flow substitutes one set rather
/// than assembling eleven objects, and so `tool/check_layering.dart` has a
/// single boundary to enforce: nothing reachable from production `main.dart`
/// may name any of these.
///
/// Determinism is the point. Nothing here reads the wall clock, generates a
/// random number, or opens a socket. Two runs of the same flow put the same
/// bytes in the same places, which is what makes a failure a bug rather than a
/// coin toss.
library;

import 'dart:io';

import 'package:doc_scanly/features/app_security/domain/app_lock.dart';
import 'package:doc_scanly/features/app_security/infrastructure/repositories/local_auth_authenticator.dart';
import 'package:doc_scanly/features/document_import/infrastructure/repositories/fake_import_sources.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:doc_scanly/features/document_sharing/infrastructure/repositories/fake_share_repositories.dart';
import 'package:doc_scanly/features/ocr/infrastructure/repositories/fake_ocr_repository.dart';

/// Every substituted platform edge, held together so a flow can assert on them.
///
/// A flow reaches into this after acting: sharing is proved by what arrived at
/// [share], printing by what arrived at [printer]. Those are the boundaries the
/// Non-Goals name explicitly — the real share sheet and print dialogue are
/// outside anything the framework can drive, so "the right file and metadata
/// were handed over" is the strongest true assertion available.
class FakePlatform {
  /// Creates the bundle.
  const FakePlatform({
    required this.scanner,
    required this.detector,
    required this.recogniser,
    required this.authenticator,
    required this.share,
    required this.printer,
    required this.exportPicker,
    required this.gallery,
    required this.files,
    required this.sharedContent,
  });

  /// Stands in for the camera, writing a fixture image per capture.
  final FakeScannerRepository scanner;

  /// Stands in for OpenCV, which has no host-VM binding.
  ///
  /// The full page every time — which is also the behaviour the spec requires
  /// of a capture whose edges cannot be found, so a flow driving it is
  /// exercising a real code path rather than a test-only one.
  final FullPageEdgeDetector detector;

  /// Stands in for ML Kit, returning fixed blocks.
  final FakeOcrRepository recogniser;

  /// Stands in for the biometric prompt, which nothing in a test could answer.
  final FakeDeviceAuthenticator authenticator;

  /// Records what would have gone to the system share sheet.
  final FakeShareRepository share;

  /// Records what would have gone to the system print dialogue.
  final FakePrintRepository printer;

  /// Answers the export destination chooser with a fixed directory.
  final FakeExportDestinationPicker exportPicker;

  /// Answers the photo picker with fixture images.
  final FakeGalleryPicker gallery;

  /// Answers the file browser with a fixture document.
  final FakeFileBrowser files;

  /// Delivers content as if another application had shared it.
  final FakeSharedContentSource sharedContent;
}

/// Builds the substituted platform for one flow.
///
/// [captureDirectory] is where the fake scanner writes its captures — the
/// flow's own temporary directory, so captures from one flow cannot be found by
/// the next. [captureImageBytes] is what it writes there: a real fixture image,
/// because the flow goes on to compose a PDF from these captures and a
/// placeholder byte is not something the composer can decode.
///
/// [galleryImages] and [pickedFiles] are what the pickers answer with. They
/// default to empty, which stands for the user cancelling: a flow that means to
/// import something says so, and a flow that does not is not silently handed a
/// document it never asked for.
///
/// [exportDestination] is where an export lands. Null means the user dismissed
/// the destination chooser.
///
/// [unlocksSuccessfully] decides what the biometric prompt would have answered.
/// A flow proving the lock actually locks sets it false.
FakePlatform buildFakePlatform({
  required Directory captureDirectory,
  required List<int> captureImageBytes,
  List<String> galleryImages = const [],
  List<String> pickedFiles = const [],
  List<String> pendingSharedContent = const [],
  String? exportDestination,
  bool unlocksSuccessfully = true,
}) {
  return FakePlatform(
    // Writes a real file per capture, so the disk-first rule the scanning spec
    // states is genuinely exercised: a fake returning a path to nothing would
    // let a bug that never writes the image pass every flow.
    scanner: FakeScannerRepository(
      directory: captureDirectory,
      imageBytes: captureImageBytes,
    ),
    detector: const FullPageEdgeDetector(),
    recogniser: FakeOcrRepository(
      // Fixed rather than read from a clock, so the recognised-at stamp a flow
      // sees is the same on every run.
      recognisedAt: DateTime.utc(2026, 7, 26, 10, 30),
    ),
    authenticator: FakeDeviceAuthenticator(
      // `rejected` rather than a failure: a refused fingerprint is the lock
      // working, which is exactly what the flow proving it locks needs.
      outcome: unlocksSuccessfully
          ? AuthOutcome.succeeded
          : AuthOutcome.rejected,
    ),
    share: FakeShareRepository(),
    printer: FakePrintRepository(),
    exportPicker: FakeExportDestinationPicker(destination: exportDestination),
    gallery: FakeGalleryPicker(paths: galleryImages),
    files: FakeFileBrowser(paths: pickedFiles),
    sharedContent: FakeSharedContentSource(pendingPaths: pendingSharedContent),
  );
}
