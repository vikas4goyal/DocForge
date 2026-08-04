/// Tests the enhancement use cases.
///
/// The job is faked throughout: what these tests are about is progress,
/// cancellation and which pages get work, none of which involve a pixel. The
/// real job is covered in `enhancement_job_test.dart`.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/features/image_enhancement/application/usecases/enhancement_usecases.dart';
import 'package:doc_scanly/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every request it is given and returns the destination path.
///
/// A top-level function because the real worker sends its job to an isolate,
/// and this has to be substitutable for it without changing the signature.
String recordingJob(EnhancementRequest request) {
  recordedRequests.add(request);
  return request.destinationPath;
}

/// Requests seen by [recordingJob], in order.
final recordedRequests = <EnhancementRequest>[];

/// Fails on the request whose source path contains `fail`.
String failingJob(EnhancementRequest request) {
  recordedRequests.add(request);
  if (request.sourcePath.contains('fail')) {
    throw const FormatException('the page image could not be decoded');
  }
  return request.destinationPath;
}

/// Cancels [cancelOnFirst] as soon as the first page is processed.
///
/// Set by the cancellation test so the token is cancelled from inside the
/// batch, which is the only way to exercise the between-items check.
CancellationToken? cancelOnFirst;

/// Records its request, cancelling the token after the first one.
String cancellingJob(EnhancementRequest request) {
  recordedRequests.add(request);
  cancelOnFirst?.cancel();
  return request.destinationPath;
}

/// A page reference with [settings].
PageRef page(String id, EnhancementSettings settings) =>
    PageRef(id: PageId(id), imagePath: '/$id.jpg', enhancement: settings);

void main() {
  setUp(recordedRequests.clear);
  tearDown(() => cancelOnFirst = null);

  const magic = EnhancementSettings(filter: EnhancementFilter.magicColour);

  group('ApplyEnhancement.preview', () {
    test('requests a downscaled render', () async {
      const apply = ApplyEnhancement(InlineBackgroundWorker(), recordingJob);

      final result = await apply.preview(
        sourcePath: '/a.jpg',
        destinationPath: '/a-preview.jpg',
        settings: magic,
      );

      expect(result, isA<Success<String>>());
      expect(recordedRequests.single.isPreview, isTrue);
      expect(
        recordedRequests.single.maxDimension,
        EnhancementRules.previewMaxDimension,
      );
    });

    test('reports a job failure rather than throwing', () async {
      const apply = ApplyEnhancement(InlineBackgroundWorker(), failingJob);

      final result = await apply.preview(
        sourcePath: '/fail.jpg',
        destinationPath: '/out.jpg',
        settings: magic,
      );

      expect(result, isA<Failed<String>>());
    });
  });

  group('ApplyEnhancement.single', () {
    test('requests a full-resolution render', () async {
      const apply = ApplyEnhancement(InlineBackgroundWorker(), recordingJob);

      await apply.single(
        sourcePath: '/a.jpg',
        destinationPath: '/a-out.jpg',
        settings: magic,
      );

      expect(recordedRequests.single.isPreview, isFalse);
      expect(recordedRequests.single.maxDimension, isNull);
    });
  });

  group('ApplyEnhancement.batch', () {
    List<EnhancementRequest> requestsFor(List<String> ids) => [
      for (final id in ids)
        EnhancementRequest(
          sourcePath: '/$id.jpg',
          destinationPath: '/$id-out.jpg',
          settings: magic,
        ),
    ];

    test('reports progress after each page', () async {
      const apply = ApplyEnhancement(InlineBackgroundWorker(), recordingJob);

      final events = await apply.batch(requestsFor(['a', 'b', 'c'])).toList();

      expect(events, hasLength(3));
      expect(
        events.whereType<BatchItemCompleted<String>>().map(
          (event) => event.progress.completed,
        ),
        [1, 2, 3],
      );
    });

    test('processes pages in the order given', () async {
      const apply = ApplyEnhancement(InlineBackgroundWorker(), recordingJob);

      await apply.batch(requestsFor(['a', 'b', 'c'])).toList();

      expect(recordedRequests.map((request) => request.sourcePath), [
        '/a.jpg',
        '/b.jpg',
        '/c.jpg',
      ]);
    });

    test('stops at a failure rather than continuing past it', () async {
      const apply = ApplyEnhancement(InlineBackgroundWorker(), failingJob);

      final events = await apply
          .batch(requestsFor(['a', 'fail', 'c']))
          .toList();

      expect(events.last, isA<BatchItemFailed<String>>());
      // The third page is never attempted: continuing past a failure would
      // leave the caller unable to say which outputs are trustworthy.
      expect(recordedRequests, hasLength(2));
    });

    test(
      'cancellation leaves processed pages intact and stops the rest',
      () async {
        final token = CancellationToken();
        cancelOnFirst = token;
        const apply = ApplyEnhancement(InlineBackgroundWorker(), cancellingJob);

        final events = await apply
            .batch(requestsFor(['a', 'b', 'c']), token: token)
            .toList();

        // The first page completed and keeps its result.
        expect(events.first, isA<BatchItemCompleted<String>>());
        expect(events.last, isA<BatchCancelled<String>>());
        // The second and third never started, so no half-written file exists.
        expect(recordedRequests, hasLength(1));
      },
    );

    test('a token cancelled before the batch starts runs nothing', () async {
      final token = CancellationToken()..cancel();
      const apply = ApplyEnhancement(InlineBackgroundWorker(), recordingJob);

      final events = await apply
          .batch(requestsFor(['a', 'b']), token: token)
          .toList();

      expect(events.single, isA<BatchCancelled<String>>());
      expect(recordedRequests, isEmpty);
    });

    test('an empty batch completes without work', () async {
      const apply = ApplyEnhancement(InlineBackgroundWorker(), recordingJob);

      expect(await apply.batch(const []).toList(), isEmpty);
      expect(recordedRequests, isEmpty);
    });
  });

  group('PlanSessionEnhancement', () {
    const plan = PlanSessionEnhancement();

    String destination(PageRef page) => '${page.imagePath}.enhanced.jpg';

    test('produces one request per page that needs work', () {
      final requests = plan([
        page('a', magic),
        page('b', magic),
      ], destinationFor: destination);

      expect(requests, hasLength(2));
      expect(requests.first.sourcePath, '/a.jpg');
      expect(requests.first.destinationPath, '/a.jpg.enhanced.jpg');
    });

    test('omits pages whose settings would change nothing', () {
      // Re-encoding an untouched page costs it a generation of JPEG loss and
      // buys nothing, so it is skipped rather than copied.
      final requests = plan([
        page('a', EnhancementSettings.none),
        page('b', magic),
      ], destinationFor: destination);

      expect(requests.single.sourcePath, '/b.jpg');
    });

    test('produces nothing for a session nobody enhanced', () {
      final requests = plan([
        page('a', EnhancementSettings.none),
      ], destinationFor: destination);

      expect(requests, isEmpty);
    });

    test('requests full-resolution work, never a preview', () {
      final requests = plan([page('a', magic)], destinationFor: destination);

      expect(requests.single.isPreview, isFalse);
    });

    test('carries each page its own settings', () {
      const grayscale = EnhancementSettings(
        filter: EnhancementFilter.grayscale,
      );

      final requests = plan([
        page('a', magic),
        page('b', grayscale),
      ], destinationFor: destination);

      expect(requests[0].settings, magic);
      expect(requests[1].settings, grayscale);
    });
  });

  group('failures reaching the caller', () {
    test(
      'a decode failure becomes an unexpected failure, not a crash',
      () async {
        const apply = ApplyEnhancement(InlineBackgroundWorker(), failingJob);

        final result = await apply.single(
          sourcePath: '/fail.jpg',
          destinationPath: '/out.jpg',
          settings: magic,
        );

        expect(result, isA<Failed<String>>());
        expect((result as Failed<String>).failure, isA<UnexpectedFailure>());
      },
    );
  });
}
