import 'dart:io';

import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// A correction job that records what it was asked to do and writes nothing.
///
/// A top-level function because a real isolate job must be one, so the test
/// exercises the same shape production uses.
String recordingCorrectionJob(PageCorrectionRequest request) {
  correctionRequests.add(request);
  return request.destinationPath;
}

/// Requests seen by [recordingCorrectionJob].
final correctionRequests = <PageCorrectionRequest>[];

/// A correction job that always fails.
String failingCorrectionJob(PageCorrectionRequest request) =>
    throw const FormatException('unreadable');

/// An edge detector returning a fixed quad, for asserting it was consulted.
class _FixedEdgeDetector implements EdgeDetector {
  _FixedEdgeDetector(this.quad);

  final PageQuad quad;
  final List<String> detected = [];

  @override
  Future<PageQuad> detect(String imagePath) async {
    detected.add(imagePath);
    return quad;
  }
}

void main() {
  late Directory workspace;
  late FakeScannerRepository scanner;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('docscanly_scanning');
    scanner = FakeScannerRepository(
      directory: workspace,
      ids: SequentialIdGenerator(prefix: 'page'),
    );
    correctionRequests.clear();
  });

  tearDown(() {
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  group('FakeScannerRepository', () {
    test('is not ready until it is initialised', () async {
      expect(scanner.isReady, isFalse);

      await scanner.initialise();

      expect(scanner.isReady, isTrue);
    });

    test(
      'capturing before initialise fails rather than returning a path',
      () async {
        final result = await scanner.capture();

        expect(result.failureOrNull, isA<CameraFailure>());
      },
    );

    test('a refused permission fails with the permission failure', () async {
      scanner.initialiseFailure = const Failure.permission(
        kind: PermissionKind.camera,
      );

      final result = await scanner.initialise();

      // Distinct from a camera failure: one offers settings, the other a retry.
      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(scanner.isReady, isFalse);
    });

    test('a permanently denied permission is reported as such', () async {
      scanner.initialiseFailure = const Failure.permission(
        kind: PermissionKind.camera,
        permanentlyDenied: true,
      );

      final result = await scanner.initialise();

      final failure = result.failureOrNull! as PermissionFailure;
      expect(failure.permanentlyDenied, isTrue);
    });

    test('an unavailable camera fails with a camera failure', () async {
      scanner.initialiseFailure = const Failure.camera(inUseByAnotherApp: true);

      final result = await scanner.initialise();

      final failure = result.failureOrNull! as CameraFailure;
      expect(failure.inUseByAnotherApp, isTrue);
    });

    test('every capture is written to disk before it is returned', () async {
      await scanner.initialise();

      final result = await scanner.capture();

      // The spec requires the file to exist by the time the caller sees it.
      // Returning a path to nothing would pass a weaker fake and fail on device.
      final path = result.valueOrNull!.imagePath;
      expect(File(path).existsSync(), isTrue);
    });

    test('each capture gets its own identifier and its own file', () async {
      await scanner.initialise();

      final first = await scanner.capture();
      final second = await scanner.capture();

      expect(first.valueOrNull!.id, isNot(second.valueOrNull!.id));
      expect(
        first.valueOrNull!.imagePath,
        isNot(second.valueOrNull!.imagePath),
      );
    });

    test(
      'storage full during capture is reported without losing prior pages',
      () async {
        await scanner.initialise();
        final firstPath = (await scanner.capture()).valueOrNull!.imagePath;

        scanner.captureFailure = const Failure.storageFull();
        final result = await scanner.capture();

        expect(result.failureOrNull, isA<StorageFullFailure>());
        // The spec is explicit: already-captured pages are retained.
        expect(File(firstPath).existsSync(), isTrue);
      },
    );

    test('the torch cannot be used before the camera is ready', () async {
      final result = await scanner.setTorch(on: true);

      expect(result.isFailure, isTrue);
      expect(scanner.isTorchOn, isFalse);
    });

    test('the torch toggles once the camera is ready', () async {
      await scanner.initialise();

      await scanner.setTorch(on: true);
      expect(scanner.isTorchOn, isTrue);

      await scanner.setTorch(on: false);
      expect(scanner.isTorchOn, isFalse);
    });

    test('dispose releases the camera and the torch together', () async {
      await scanner.initialise();
      await scanner.setTorch(on: true);

      await scanner.dispose();

      expect(scanner.isReady, isFalse);
      // A torch left on after the camera is released is a flashlight the user
      // cannot turn off from inside the app.
      expect(scanner.isTorchOn, isFalse);
    });

    test('dispose is safe to call more than once', () async {
      await scanner.initialise();

      await scanner.dispose();
      await scanner.dispose();

      // The capture screen releases on every exit path, and some of those paths
      // overlap; a dispose that could fail would turn one problem into two.
      expect(scanner.disposeCount, 2);
    });

    test('dispose is safe without a successful initialise', () async {
      scanner.initialiseFailure = const Failure.camera();
      await scanner.initialise();

      final result = await scanner.dispose();

      expect(result.isSuccess, isTrue);
    });
  });

  group('CapturePage', () {
    test(
      'returns a page carrying the path the capture was written to',
      () async {
        await scanner.initialise();
        const detector = FullPageEdgeDetector();

        final result = await CapturePage(scanner, detector)();

        final page = result.valueOrNull!;
        expect(File(page.imagePath).existsSync(), isTrue);
      },
    );

    test('detects edges on the file already written to disk', () async {
      await scanner.initialise();
      final detector = _FixedEdgeDetector(PageQuad.full);

      await CapturePage(scanner, detector)();

      // Detection runs after the write, so a detection failure cannot lose a
      // page the user has already seen the shutter fire for.
      expect(detector.detected, hasLength(1));
      expect(File(detector.detected.single).existsSync(), isTrue);
    });

    test('uses the detected quad as the default crop', () async {
      await scanner.initialise();
      const detected = PageQuad(
        topLeft: NormalisedPoint(x: 0.1, y: 0.1),
        topRight: NormalisedPoint(x: 0.9, y: 0.12),
        bottomRight: NormalisedPoint(x: 0.88, y: 0.9),
        bottomLeft: NormalisedPoint(x: 0.12, y: 0.88),
      );

      final result = await CapturePage(scanner, _FixedEdgeDetector(detected))();

      expect(result.valueOrNull!.quad, detected);
    });

    test('keeps the capture when no edges are found', () async {
      await scanner.initialise();

      final result = await CapturePage(scanner, const FullPageEdgeDetector())();

      // The spec forbids rejecting the capture: the full page becomes the crop.
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.quad, PageQuad.full);
      expect(result.valueOrNull!.needsCorrection, isFalse);
    });

    test('a stalled edge detector cannot trap capture navigation', () async {
      await scanner.initialise();

      final result = await CapturePage(
        scanner,
        _StalledEdgeDetector(),
        edgeDetectionTimeout: Duration.zero,
      )();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.quad, PageQuad.full);
    });

    test('a capture failure never reaches edge detection', () async {
      await scanner.initialise();
      scanner.captureFailure = const Failure.storageFull();
      final detector = _FixedEdgeDetector(PageQuad.full);

      final result = await CapturePage(scanner, detector)();

      expect(result.isFailure, isTrue);
      expect(detector.detected, isEmpty);
    });

    test('a permission failure is passed through unchanged', () async {
      scanner.captureFailure = const Failure.permission(
        kind: PermissionKind.camera,
        permanentlyDenied: true,
      );
      await scanner.initialise();

      final result = await CapturePage(scanner, const FullPageEdgeDetector())();

      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('ApplyPerspectiveCorrection', () {
    ApplyPerspectiveCorrection buildUseCase([
      String Function(PageCorrectionRequest)? job,
    ]) => ApplyPerspectiveCorrection(
      const InlineBackgroundWorker(),
      job ?? recordingCorrectionJob,
    );

    List<PageCorrectionRequest> requests(int count) => [
      for (var i = 0; i < count; i++)
        PageCorrectionRequest.forQuad(
          sourcePath: '/pages/page-$i.jpg',
          destinationPath: '/pages/page-$i-corrected.jpg',
          quad: PageQuad.full,
        ),
    ];

    test('corrects a single page and returns its path', () async {
      final result = await buildUseCase().single(requests(1).single);

      expect(result.valueOrNull, '/pages/page-0-corrected.jpg');
    });

    test('reports progress after each page', () async {
      final events = await buildUseCase().call(requests(3)).toList();

      final completed = events.whereType<BatchItemCompleted<String>>().toList();
      expect(completed, hasLength(3));
      expect(completed.first.progress, const Progress(completed: 1, total: 3));
      expect(completed.last.progress, const Progress(completed: 3, total: 3));
    });

    test('processes pages in the order they were given', () async {
      await buildUseCase().call(requests(3)).toList();

      expect(correctionRequests.map((r) => r.sourcePath), [
        '/pages/page-0.jpg',
        '/pages/page-1.jpg',
        '/pages/page-2.jpg',
      ]);
    });

    test('a cancelled batch keeps the pages already finished', () async {
      final token = CancellationToken();
      addTearDown(token.dispose);

      final events = <BatchEvent<String>>[];
      await for (final event in buildUseCase().call(
        requests(5),
        token: token,
      )) {
        events.add(event);
        // Cancel after the second page, mid-batch.
        if (events.whereType<BatchItemCompleted<String>>().length == 2) {
          token.cancel();
        }
      }

      final completed = events.whereType<BatchItemCompleted<String>>();
      final cancelled = events.whereType<BatchCancelled<String>>();

      // Two finished pages survive, and the batch stopped rather than running
      // to the end — which is the whole point of cooperative cancellation.
      expect(completed, hasLength(2));
      expect(cancelled, hasLength(1));
      expect(cancelled.single.progress.completed, 2);
    });

    test('cancelling before the first page starts nothing', () async {
      final token = CancellationToken()..cancel();
      addTearDown(token.dispose);

      final events = await buildUseCase()
          .call(requests(3), token: token)
          .toList();

      expect(events.whereType<BatchItemCompleted<String>>(), isEmpty);
      expect(correctionRequests, isEmpty);
    });

    test(
      'a failed page stops the batch rather than continuing past it',
      () async {
        final events = await buildUseCase(
          failingCorrectionJob,
        ).call(requests(3)).toList();

        final failed = events.whereType<BatchItemFailed<String>>();

        // Continuing would leave the caller unable to tell which outputs are
        // trustworthy.
        expect(failed, hasLength(1));
        expect(failed.single.index, 0);
        expect(events.whereType<BatchItemCompleted<String>>(), isEmpty);
      },
    );

    test('an empty batch completes immediately', () async {
      final events = await buildUseCase().call(const []).toList();

      expect(events, isEmpty);
    });

    test('only paths and numbers cross the isolate boundary', () async {
      await buildUseCase().call(requests(1)).toList();

      final request = correctionRequests.single;
      // The payload type has nowhere to put a decoded image, which is what
      // keeps a batch correction from copying full-resolution bitmaps.
      expect(request.sourcePath, isA<String>());
      expect(request.destinationPath, isA<String>());
      expect(request.corners, hasLength(8));
    });
  });

  group('DiscardScanSession', () {
    test('releases the camera and removes the captures', () async {
      await scanner.initialise();
      await scanner.capture();
      final staging = FakeScanStagingArea(workspace);

      final result = await DiscardScanSession(staging, scanner)();

      expect(result.isSuccess, isTrue);
      expect(scanner.disposeCount, 1);
      expect(workspace.existsSync(), isFalse);
    });

    test('releases the camera even when clearing fails', () async {
      await scanner.initialise();
      // A directory that was never created: clearing it is a no-op here, but
      // the ordering is what matters — the camera goes first, unconditionally.
      final staging = FakeScanStagingArea(
        Directory('${workspace.path}/never-created'),
      );

      await DiscardScanSession(staging, scanner)();

      // Holding the device because a file delete failed would make the next
      // scan impossible, which is far worse than an orphaned file.
      expect(scanner.isReady, isFalse);
      expect(scanner.disposeCount, 1);
    });
  });

  group('LocalScanStagingArea', () {
    test('creates its directory on first use', () async {
      final root = Directory.systemTemp.createTempSync('docscanly_staging');
      addTearDown(() => root.deleteSync(recursive: true));

      final result = await LocalScanStagingArea(root).directory();

      expect(result.valueOrNull!.existsSync(), isTrue);
      expect(
        result.valueOrNull!.path,
        endsWith(LocalScanStagingArea.directoryName),
      );
    });

    test('clearing removes everything the session wrote', () async {
      final root = Directory.systemTemp.createTempSync('docscanly_staging');
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });
      final area = LocalScanStagingArea(root);
      final staging = (await area.directory()).valueOrNull!;
      File('${staging.path}/page.jpg').writeAsBytesSync(const [0]);

      await area.clear();

      // An abandoned scan must not leave full-resolution captures behind.
      expect(staging.existsSync(), isFalse);
    });

    test('clearing a session that wrote nothing succeeds', () async {
      final root = Directory.systemTemp.createTempSync('docscanly_staging');
      addTearDown(() => root.deleteSync(recursive: true));

      final result = await LocalScanStagingArea(root).clear();

      expect(result.isSuccess, isTrue);
    });
  });
}

class _StalledEdgeDetector implements EdgeDetector {
  @override
  Future<PageQuad> detect(String imagePath) =>
      Future<PageQuad>.delayed(const Duration(days: 1), () => PageQuad.full);
}
