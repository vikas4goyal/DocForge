import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_forge/features/document_scanning/domain/perspective_transform.dart';
import 'package:doc_forge/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_forge/features/document_scanning/domain/scan_session.dart';
import 'package:doc_forge/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:doc_forge/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_forge/features/document_scanning/presentation/cubit/scan_states.dart';
import 'package:flutter_test/flutter_test.dart';

/// A correction job that pretends to write and reports the destination.
String passthroughCorrectionJob(PageCorrectionRequest request) =>
    request.destinationPath;

/// A correction job that always fails.
String brokenCorrectionJob(PageCorrectionRequest request) =>
    throw const FormatException('unreadable');

/// A crop that is not the full page, so correction is genuinely required.
const skewedQuad = PageQuad(
  topLeft: NormalisedPoint(x: 0.1, y: 0.08),
  topRight: NormalisedPoint(x: 0.9, y: 0.14),
  bottomRight: NormalisedPoint(x: 0.87, y: 0.92),
  bottomLeft: NormalisedPoint(x: 0.12, y: 0.86),
);

/// Builds [count] captured pages with stable identifiers.
List<CapturedPage> pages(int count) => List.generate(
  count,
  (index) => CapturedPage(
    id: PageId('page-$index'),
    imagePath: '/scan/page-$index.jpg',
    quad: PageQuad.full,
  ),
);

void main() {
  late Directory workspace;
  late FakeScannerRepository scanner;
  late FakeScanStagingArea staging;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('docforge_scan_cubit');
    scanner = FakeScannerRepository(
      directory: workspace,
      ids: SequentialIdGenerator(prefix: 'page'),
    );
    staging = FakeScanStagingArea(workspace);
  });

  tearDown(() {
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  ScanCaptureCubit buildCapture() => ScanCaptureCubit(
    scanner,
    CapturePage(scanner, const FullPageEdgeDetector()),
    DiscardScanSession(staging, scanner),
  );

  CropCubit buildCrop(
    CapturedPage page, {
    String Function(PageCorrectionRequest)? job,
  }) => CropCubit(
    page,
    ApplyPerspectiveCorrection(
      const InlineBackgroundWorker(),
      job ?? passthroughCorrectionJob,
    ),
  );

  group('ScanCaptureCubit', () {
    test('starts idle with nothing captured', () {
      final cubit = buildCapture();

      expect(cubit.state.status, ScanCaptureStatus.idle);
      expect(cubit.state.pageCount, 0);
      expect(cubit.state.canCapture, isFalse);
    });

    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'opening the camera goes through preparing to ready',
      build: buildCapture,
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<ScanCaptureState>().having(
          (s) => s.status,
          'status',
          ScanCaptureStatus.preparing,
        ),
        isA<ScanCaptureState>()
            .having((s) => s.status, 'status', ScanCaptureStatus.ready)
            .having((s) => s.canCapture, 'canCapture', isTrue),
      ],
    );

    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'a refused permission is distinguishable from a camera fault',
      setUp: () => scanner.initialiseFailure = const Failure.permission(
        kind: PermissionKind.camera,
        permanentlyDenied: true,
      ),
      build: buildCapture,
      act: (cubit) => cubit.start(),
      skip: 1,
      expect: () => [
        isA<ScanCaptureState>()
            .having((s) => s.status, 'status', ScanCaptureStatus.failure)
            .having((s) => s.isPermissionDenied, 'permissionDenied', isTrue)
            // Decides between offering settings and offering a retry.
            .having((s) => s.isPermanentlyDenied, 'permanentlyDenied', isTrue),
      ],
    );

    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'an unavailable camera fails without claiming a permission problem',
      setUp: () => scanner.initialiseFailure = const Failure.camera(
        inUseByAnotherApp: true,
      ),
      build: buildCapture,
      act: (cubit) => cubit.start(),
      skip: 1,
      expect: () => [
        isA<ScanCaptureState>()
            .having((s) => s.status, 'status', ScanCaptureStatus.failure)
            .having((s) => s.isPermissionDenied, 'permissionDenied', isFalse)
            .having((s) => s.message, 'message', isNotEmpty),
      ],
    );

    test('a retry after a camera failure recovers', () async {
      scanner.initialiseFailure = const Failure.camera();
      final cubit = buildCapture();
      await cubit.start();
      expect(cubit.state.status, ScanCaptureStatus.failure);

      scanner.initialiseFailure = null;
      await cubit.start();

      expect(cubit.state.status, ScanCaptureStatus.ready);
      // The stale error is gone, not carried into the recovered state.
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test('capturing increments the page counter', () async {
      final cubit = buildCapture();
      await cubit.start();

      await cubit.capture();
      await cubit.capture();
      await cubit.capture();

      expect(cubit.state.pageCount, 3);
      expect(cubit.pages, hasLength(3));
      await cubit.close();
    });

    test('pages are kept in capture order', () async {
      final cubit = buildCapture();
      await cubit.start();

      await cubit.capture();
      await cubit.capture();

      // Compared against what the scanner actually produced rather than
      // against literal identifiers, so the assertion is about ordering rather
      // than about how the generator happens to number things.
      expect(cubit.pages.map((p) => p.id), scanner.captures.map((c) => c.id));
      await cubit.close();
    });

    test('the shutter is ignored while a capture is in flight', () async {
      final cubit = buildCapture();
      await cubit.start();

      // Both taps issued before either completes, which is what a double tap
      // on the shutter actually looks like.
      await Future.wait([cubit.capture(), cubit.capture()]);

      expect(cubit.state.pageCount, 1);
      await cubit.close();
    });

    test('storage full keeps the pages already captured', () async {
      final cubit = buildCapture();
      await cubit.start();
      await cubit.capture();

      scanner.captureFailure = const Failure.storageFull();
      await cubit.capture();

      // Back to ready with a message, not to a failure screen: the spec
      // requires the captured pages to survive and the user to be able to retry.
      expect(cubit.state.status, ScanCaptureStatus.ready);
      expect(cubit.state.pageCount, 1);
      expect(cubit.state.message, isNotEmpty);
      await cubit.close();
    });

    blocTest<ScanCaptureCubit, ScanCaptureState>(
      'batch mode is recorded on the state',
      build: buildCapture,
      act: (cubit) => cubit.setBatchMode(enabled: true),
      expect: () => [
        isA<ScanCaptureState>().having((s) => s.batchMode, 'batchMode', isTrue),
      ],
    );

    test('batch mode survives a capture', () async {
      final cubit = buildCapture();
      await cubit.start();
      cubit.setBatchMode(enabled: true);

      await cubit.capture();

      // Losing the mode after each shot would defeat the point of batch mode.
      expect(cubit.state.batchMode, isTrue);
      await cubit.close();
    });

    test('the torch toggles once the camera is ready', () async {
      final cubit = buildCapture();
      await cubit.start();

      await cubit.setTorch(on: true);

      expect(cubit.state.torchOn, isTrue);
      await cubit.close();
    });

    test('a torch failure leaves the state saying it is off', () async {
      final cubit = buildCapture();

      // Never initialised, so the fake refuses.
      await cubit.setTorch(on: true);

      expect(cubit.state.torchOn, isFalse);
      expect(cubit.state.message, isNotEmpty);
      await cubit.close();
    });

    test('releasing gives the camera back but keeps the pages', () async {
      final cubit = buildCapture();
      await cubit.start();
      await cubit.capture();

      await cubit.release();

      expect(scanner.disposeCount, 1);
      expect(scanner.isReady, isFalse);
      // The captures are still wanted: the user is moving on to review them.
      expect(cubit.pages, hasLength(1));
      await cubit.close();
    });

    test('abandoning gives the camera back and deletes the captures', () async {
      final cubit = buildCapture();
      await cubit.start();
      await cubit.capture();

      await cubit.abandon();

      expect(cubit.pages, isEmpty);
      expect(workspace.existsSync(), isFalse);
      await cubit.close();
    });

    test('closing the cubit releases the camera', () async {
      final cubit = buildCapture();
      await cubit.start();

      await cubit.close();

      // The last line of defence for "released on every exit path": however the
      // screen goes away, its Cubit closes and the device comes back.
      expect(scanner.disposeCount, greaterThanOrEqualTo(1));
      expect(scanner.isReady, isFalse);
    });

    test('the camera is released exactly once per exit path', () async {
      final cubit = buildCapture();
      await cubit.start();

      await cubit.release();
      await cubit.close();

      // Two paths, two releases, and neither throws — dispose must tolerate
      // being called on a camera that is already given up.
      expect(scanner.disposeCount, 2);
    });
  });

  group('PageReviewCubit', () {
    test('starts with the pages it was given', () {
      final cubit = PageReviewCubit(pages(3));

      expect(cubit.state.pages, hasLength(3));
      expect(cubit.state.canSave, isTrue);
      expect(cubit.state.isEmpty, isFalse);
    });

    blocTest<PageReviewCubit, PageReviewState>(
      'rotating turns one page and leaves the rest',
      build: () => PageReviewCubit(pages(3)),
      act: (cubit) => cubit.rotate(1),
      expect: () => [
        isA<PageReviewState>()
            .having((s) => s.pages[1].rotation, 'rotated', PageRotation.quarter)
            .having((s) => s.pages[0].rotation, 'first', PageRotation.none),
      ],
    );

    blocTest<PageReviewCubit, PageReviewState>(
      'reordering moves a page and keeps every other',
      build: () => PageReviewCubit(pages(3)),
      act: (cubit) => cubit.reorder(0, 2),
      expect: () => [
        isA<PageReviewState>()
            .having((s) => s.pages.map((p) => p.id.value).toList(), 'order', [
              'page-1',
              'page-2',
              'page-0',
            ])
            .having((s) => s.pages, 'count', hasLength(3)),
      ],
    );

    blocTest<PageReviewCubit, PageReviewState>(
      'deleting removes the page and offers an undo',
      build: () => PageReviewCubit(pages(3)),
      act: (cubit) => cubit.delete(1),
      expect: () => [
        isA<PageReviewState>()
            .having((s) => s.pages, 'remaining', hasLength(2))
            .having((s) => s.canUndo, 'canUndo', isTrue),
      ],
    );

    test('undo puts the page back where it was', () {
      final cubit = PageReviewCubit(pages(3))..delete(1);

      cubit.undoDelete();

      // Appending instead would silently reorder the document as a side effect
      // of an undo, which is the opposite of what undo means.
      expect(cubit.state.pages.map((p) => p.id.value), [
        'page-0',
        'page-1',
        'page-2',
      ]);
      expect(cubit.state.canUndo, isFalse);
    });

    test('deleting the last page leaves an empty session', () {
      final cubit = PageReviewCubit(pages(1))..delete(0);

      expect(cubit.state.isEmpty, isTrue);
      // The library forbids a document with no pages, so saving is off.
      expect(cubit.state.canSave, isFalse);
      // The undo is what makes the empty state recoverable.
      expect(cubit.state.canUndo, isTrue);
    });

    test('undo from an empty session restores the page', () {
      final cubit = PageReviewCubit(pages(1))..delete(0);

      cubit.undoDelete();

      expect(cubit.state.pages, hasLength(1));
      expect(cubit.state.canSave, isTrue);
    });

    test('a further edit withdraws the undo offer', () {
      final cubit = PageReviewCubit(pages(3))
        ..delete(1)
        ..rotate(0);

      // An undo offered after further changes would put the page back into a
      // list it no longer belongs to.
      expect(cubit.state.canUndo, isFalse);
    });

    test('undo does nothing when nothing was deleted', () {
      final cubit = PageReviewCubit(pages(2));
      final before = cubit.state;

      cubit.undoDelete();

      expect(cubit.state, before);
    });

    test('an out-of-range delete changes nothing', () {
      final cubit = PageReviewCubit(pages(2));
      final before = cubit.state;

      cubit
        ..delete(9)
        ..delete(-1);

      expect(cubit.state, before);
    });

    test('replacing swaps in a corrected page at the same position', () {
      final cubit = PageReviewCubit(pages(3));
      final corrected = pages(1).single.copyWith(
        id: const PageId('page-1'),
        imagePath: '/scan/page-1-corrected.jpg',
        isCorrected: true,
      );

      cubit.replace(1, corrected);

      expect(cubit.state.pages[1].imagePath, '/scan/page-1-corrected.jpg');
      expect(cubit.state.pages, hasLength(3));
    });

    test('pages captured after returning to the camera are appended', () {
      final cubit = PageReviewCubit(pages(2));

      cubit.addAll([
        const CapturedPage(
          id: PageId('page-new'),
          imagePath: '/scan/page-new.jpg',
          quad: PageQuad.full,
        ),
      ]);

      expect(cubit.state.pages, hasLength(3));
      expect(cubit.state.pages.last.id.value, 'page-new');
    });
  });

  group('CropCubit', () {
    test('starts adjusting, seeded with the page current crop', () {
      final page = pages(1).single.copyWith(quad: skewedQuad);
      final cubit = buildCrop(page);

      expect(cubit.state.status, CropStatus.adjusting);
      expect(cubit.state.quad, skewedQuad);
      expect(cubit.state.hasChanges, isFalse);
    });

    blocTest<CropCubit, CropState>(
      'dragging a handle updates the crop',
      build: () => buildCrop(pages(1).single),
      act: (cubit) => cubit.adjust(skewedQuad),
      expect: () => [
        isA<CropState>()
            .having((s) => s.quad, 'quad', skewedQuad)
            .having((s) => s.hasChanges, 'hasChanges', isTrue),
      ],
    );

    blocTest<CropCubit, CropState>(
      'resetting returns the crop to the whole page',
      build: () => buildCrop(pages(1).single.copyWith(quad: skewedQuad)),
      act: (cubit) => cubit.reset(),
      expect: () => [
        isA<CropState>().having((s) => s.quad, 'quad', PageQuad.full),
      ],
    );

    test('confirming a skewed crop corrects the page', () async {
      final cubit = buildCrop(pages(1).single)..adjust(skewedQuad);

      final corrected = await cubit.confirm(
        destinationPath: '/scan/corrected.jpg',
      );

      expect(corrected, isNotNull);
      expect(corrected!.imagePath, '/scan/corrected.jpg');
      expect(corrected.isCorrected, isTrue);
      expect(cubit.state.status, CropStatus.done);
      await cubit.close();
    });

    test('confirming a full-page crop does no work at all', () async {
      final cubit = buildCrop(pages(1).single, job: brokenCorrectionJob);

      final result = await cubit.confirm(
        destinationPath: '/scan/corrected.jpg',
      );

      // The job would have thrown if it ran. There is nothing to straighten,
      // and running the transform anyway would re-encode for no benefit.
      expect(result, isNotNull);
      expect(result!.imagePath, '/scan/page-0.jpg');
      expect(result.isCorrected, isFalse);
      await cubit.close();
    });

    test(
      'a failed correction returns to adjusting with the original intact',
      () async {
        final cubit = buildCrop(pages(1).single, job: brokenCorrectionJob)
          ..adjust(skewedQuad);

        final result = await cubit.confirm(
          destinationPath: '/scan/corrected.jpg',
        );

        expect(result, isNull);
        // Not a dead end: the capture is untouched, so the user can change the
        // crop and try again.
        expect(cubit.state.status, CropStatus.adjusting);
        expect(cubit.state.page.imagePath, '/scan/page-0.jpg');
        expect(cubit.state.page.isCorrected, isFalse);
        expect(cubit.state.message, isNotEmpty);
        await cubit.close();
      },
    );

    test('a retry after a failed correction can succeed', () async {
      final failing = buildCrop(pages(1).single, job: brokenCorrectionJob)
        ..adjust(skewedQuad);
      await failing.confirm(destinationPath: '/scan/corrected.jpg');
      await failing.close();

      final working = buildCrop(pages(1).single)..adjust(skewedQuad);
      final corrected = await working.confirm(
        destinationPath: '/scan/corrected.jpg',
      );

      expect(corrected, isNotNull);
      await working.close();
    });

    test('correction runs through the background worker', () async {
      final cubit = buildCrop(pages(1).single)..adjust(skewedQuad);

      await cubit.confirm(destinationPath: '/scan/corrected.jpg');

      // The use case owns the worker, so a Cubit that did the maths itself
      // would not compile — but this pins that the corrected path came back
      // through it rather than being fabricated.
      expect(cubit.state.page.isCorrected, isTrue);
      await cubit.close();
    });
  });
}
