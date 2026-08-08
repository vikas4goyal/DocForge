import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PdfCandidateFingerprint', () {
    test('has value equality and generated JSON round trips', () {
      const fingerprint = PdfCandidateFingerprint(
        sourceIdentity: 'session:7',
        configurationIdentity: 'name:Report',
        orderedPageQualities: <int>[70, 40, 100],
        isProtected: true,
      );

      expect(
        PdfCandidateFingerprint.fromJson(fingerprint.toJson()),
        fingerprint,
      );
      expect(
        fingerprint,
        const PdfCandidateFingerprint(
          sourceIdentity: 'session:7',
          configurationIdentity: 'name:Report',
          orderedPageQualities: <int>[70, 40, 100],
          isProtected: true,
        ),
      );
    });
  });

  group('PdfCandidate', () {
    test('validates metadata and generated JSON round trips', () {
      final candidate = _candidate('candidate-a');

      expect(PdfCandidate.fromJson(candidate.toJson()), candidate);
      expect(candidate.isProtected, isFalse);
      expect(
        () => PdfCandidate(
          handle: '',
          exactBytes: 1,
          pageCount: 1,
          fingerprint: candidate.fingerprint,
        ),
        throwsArgumentError,
      );
      expect(
        () => PdfCandidate(
          handle: 'candidate',
          exactBytes: -1,
          pageCount: 1,
          fingerprint: candidate.fingerprint,
        ),
        throwsRangeError,
      );
      expect(
        () => PdfCandidate(
          handle: 'candidate',
          exactBytes: 1,
          pageCount: 0,
          fingerprint: candidate.fingerprint,
        ),
        throwsRangeError,
      );
    });
  });

  group('JobProgress', () {
    test('accepts inclusive bounds and round trips through JSON', () {
      expect(JobProgress.fromJson(JobProgress(percent: 0).toJson()).percent, 0);
      expect(
        JobProgress.fromJson(JobProgress(percent: 100).toJson()).percent,
        100,
      );
    });

    test('rejects values outside zero through one hundred', () {
      expect(() => JobProgress(percent: -1), throwsRangeError);
      expect(() => JobProgress(percent: 101), throwsRangeError);
    });
  });

  group('AsyncJobView', () {
    test('all variants have deterministic value equality', () {
      const summary = JobResultSummary(
        exactBytes: 2048,
        pageCount: 2,
        candidateHandle: 'candidate-a',
      );
      final states = <AsyncJobView>[
        const AsyncJobView.idle(),
        const AsyncJobView.queued(generation: 2),
        AsyncJobView.running(generation: 2, progress: JobProgress(percent: 45)),
        const AsyncJobView.succeeded(generation: 2, summary: summary),
        const AsyncJobView.cancelled(generation: 2),
        const AsyncJobView.failed(
          generation: 2,
          failure: Failure.pdf(debugDetail: 'failed'),
        ),
      ];
      final equalStates = <AsyncJobView>[
        const AsyncJobView.idle(),
        const AsyncJobView.queued(generation: 2),
        AsyncJobView.running(generation: 2, progress: JobProgress(percent: 45)),
        const AsyncJobView.succeeded(generation: 2, summary: summary),
        const AsyncJobView.cancelled(generation: 2),
        const AsyncJobView.failed(
          generation: 2,
          failure: Failure.pdf(debugDetail: 'failed'),
        ),
      ];

      expect(states, orderedEquals(equalStates));
      expect(states.toSet(), hasLength(states.length));
    });
  });

  group('RouteJobController', () {
    test('issues deterministic generations and rejects stale completion', () {
      final controller = RouteJobController();
      addTearDown(controller.dispose);

      final first = controller.begin();
      expect(first.generation, 1);
      expect(controller.isCurrent(first.generation), isTrue);

      final second = controller.begin();
      expect(second.generation, 2);
      expect(first.token.isCancelled, isTrue);
      expect(controller.isCurrent(first.generation), isFalse);
      expect(controller.isCurrent(second.generation), isTrue);

      controller.cancel();
      expect(second.token.isCancelled, isTrue);
      expect(controller.isCurrent(second.generation), isFalse);
    });
  });

  group('SingleCandidateOwner', () {
    test(
      'retains one candidate and discards replaced candidates once',
      () async {
        final owner = SingleCandidateOwner();
        final first = _candidate('candidate-a');
        final second = _candidate('candidate-b');
        final discarded = <PdfCandidate>[];

        await owner.replace(first, discard: discarded.addAsync);
        await owner.replace(first, discard: discarded.addAsync);
        await owner.replace(second, discard: discarded.addAsync);

        expect(owner.candidate, second);
        expect(discarded, <PdfCandidate>[first]);

        await owner.clear(discard: discarded.addAsync);
        await owner.clear(discard: discarded.addAsync);
        expect(owner.candidate, isNull);
        expect(discarded, <PdfCandidate>[first, second]);
      },
    );

    test('transfers only a matching candidate without discarding it', () async {
      final owner = SingleCandidateOwner();
      final candidate = _candidate('candidate-a');
      final discarded = <PdfCandidate>[];
      await owner.replace(candidate, discard: discarded.addAsync);

      const mismatch = PdfCandidateFingerprint(
        sourceIdentity: 'other',
        configurationIdentity: 'config',
        orderedPageQualities: <int>[70],
        isProtected: false,
      );
      expect(owner.takeMatching(mismatch), isNull);
      expect(owner.candidate, candidate);

      expect(owner.takeMatching(candidate.fingerprint), candidate);
      expect(owner.candidate, isNull);
      expect(discarded, isEmpty);
    });
  });
}

PdfCandidate _candidate(String handle) => PdfCandidate(
  handle: handle,
  exactBytes: 1024,
  pageCount: 1,
  fingerprint: const PdfCandidateFingerprint(
    sourceIdentity: 'session:7',
    configurationIdentity: 'config',
    orderedPageQualities: <int>[70],
    isProtected: false,
  ),
);

extension on List<PdfCandidate> {
  Future<void> addAsync(PdfCandidate candidate) async => add(candidate);
}
