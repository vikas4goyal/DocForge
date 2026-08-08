import 'dart:io';

import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_editing/domain/compression_candidate.dart';
import 'package:doc_scanly/features/pdf_editing/infrastructure/repositories/bounded_compression_candidate_repository.dart';
import 'package:doc_scanly/features/pdf_editing/infrastructure/repositories/fake_pdf_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late FakePdfEditor editor;
  late BoundedCompressionCandidateRepository repository;
  late String source;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('compression_candidate');
    editor = FakePdfEditor();
    repository = _repository(directory, editor);
    source = writeFakePdf(
      '${directory.path}/source.pdf',
      pageCount: 4,
      padding: 500,
    ).path;
  });

  tearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  test(
    'builds 30, 50, and 80 percent candidates with exact metadata',
    () async {
      for (final quality in <int>[30, 50, 80]) {
        editor.operations.clear();
        final progress = <int>[];
        final result = await repository.buildCandidate(
          _request(
            source,
            pageCount: 4,
            qualities: List<int>.filled(4, quality),
          ),
          token: CancellationToken(),
          onProgress: (value) => progress.add(value.percent),
        );
        final candidate = (result as Success<PdfCandidate>).value;

        expect(candidate.pageCount, 4);
        expect(candidate.exactBytes, File(candidate.handle).lengthSync());
        expect(fakePdfPages(candidate.handle), <String>[
          'page:0',
          'page:1',
          'page:2',
          'page:3',
        ]);
        expect(
          editor.operations.where(
            (operation) => operation == 'compress($quality)',
          ),
          hasLength(4),
        );
        expect(progress.first, 0);
        expect(progress.last, 100);
        expect(progress, orderedEquals(progress.toList()..sort()));
      }
    },
  );

  test(
    '100 percent is an exact source pass-through without raster work',
    () async {
      final sourceBytes = File(source).readAsBytesSync();

      final result = await repository.buildCandidate(
        _request(
          source,
          pageCount: 4,
          qualities: const <int>[100, 100, 100, 100],
        ),
        token: CancellationToken(),
        onProgress: (_) {},
      );
      final candidate = result.valueOrNull!;

      expect(File(candidate.handle).readAsBytesSync(), sourceBytes);
      expect(candidate.exactBytes, sourceBytes.length);
      expect(editor.operations, isEmpty);
    },
  );

  test(
    'mixed plan compresses lower pages and passes 100 percent pages through',
    () async {
      final result = await repository.buildCandidate(
        _request(
          source,
          pageCount: 4,
          qualities: const <int>[30, 100, 50, 100],
        ),
        token: CancellationToken(),
        onProgress: (_) {},
      );

      expect(result, isA<Success<PdfCandidate>>());
      expect(
        editor.operations,
        containsAllInOrder(<String>[
          'writePages([0])',
          'compress(30)',
          'writePages([1])',
          'writePages([2])',
          'compress(50)',
          'writePages([3])',
          'merge(4)',
        ]),
      );
      expect(fakePdfPages(result.valueOrNull!.handle), hasLength(4));
    },
  );

  test('returns a valid no-benefit candidate for explicit review', () async {
    final compact = writeFakePdf('${directory.path}/compact.pdf').path;
    final originalBytes = File(compact).lengthSync();

    final result = await repository.buildCandidate(
      _request(compact, pageCount: 1, qualities: const <int>[80]),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result, isA<Success<PdfCandidate>>());
    expect(result.valueOrNull!.exactBytes, greaterThanOrEqualTo(originalBytes));
    expect(fakePdfPages(result.valueOrNull!.handle), <String>['page:0']);
  });

  test(
    'stale cancellation cleans new output and retains prior candidate',
    () async {
      final retained = (await repository.buildCandidate(
        _request(source, pageCount: 4, qualities: const <int>[80, 80, 80, 80]),
        token: CancellationToken(),
        onProgress: (_) {},
      )).valueOrNull!;
      final token = CancellationToken();

      final cancelled = await repository.buildCandidate(
        _request(source, pageCount: 4, qualities: const <int>[30, 30, 30, 30]),
        token: token,
        onProgress: (progress) {
          if (progress.percent > 0) {
            token.cancel();
          }
        },
      );

      expect(cancelled.failureOrNull, const Failure.cancelled());
      expect(File(retained.handle).existsSync(), isTrue);
      expect(_temporaryFiles(directory), <String>[retained.handle]);
    },
  );

  test('failure removes every page intermediate and candidate', () async {
    final failing = _repository(
      directory,
      FakePdfEditor(failWith: const Failure.pdf(debugDetail: 'offline fake')),
    );

    final result = await failing.buildCandidate(
      _request(source, pageCount: 4, qualities: const <int>[50, 50, 50, 50]),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(
      result.failureOrNull,
      const Failure.pdf(debugDetail: 'offline fake'),
    );
    expect(_temporaryFiles(directory), isEmpty);
  });

  test('protected mixed candidate stays protected and promotes once', () async {
    final protectedSource = writeFakePdf(
      '${directory.path}/protected.pdf',
      pageCount: 2,
      password: 'route secret',
      padding: 100,
    ).path;
    final candidate = (await repository.buildCandidate(
      _request(
        protectedSource,
        pageCount: 2,
        qualities: const <int>[50, 100],
        password: 'route secret',
      ),
      token: CancellationToken(),
      onProgress: (_) {},
    )).valueOrNull!;

    expect(candidate.isProtected, isTrue);
    expect(fakePdfPassword(candidate.handle), 'route secret');
    final promoted = await repository.promote(
      candidate,
      destinationPath: '${directory.path}/saved.pdf',
      token: CancellationToken(),
    );
    expect(promoted.valueOrNull!.pageCount, 2);
    expect(File(candidate.handle).existsSync(), isFalse);
  });
}

BoundedCompressionCandidateRepository _repository(
  Directory directory,
  FakePdfEditor editor,
) => BoundedCompressionCandidateRepository(
  workingDirectory: directory,
  ids: SequentialIdGenerator(prefix: 'candidate'),
  editor: editor,
);

CompressionCandidateRequest _request(
  String source, {
  required int pageCount,
  required List<int> qualities,
  String? password,
}) {
  final defaultQuality = PdfQualityPercent(value: qualities.first);
  final plan = PageQualityPlan(
    documentQuality: defaultQuality,
    pageOverrides: <String, PdfQualityPercent>{
      for (var index = 0; index < qualities.length; index++)
        if (qualities[index] != qualities.first)
          '$index': PdfQualityPercent(value: qualities[index]),
    },
  );
  return CompressionCandidateRequest(
    sourcePath: source,
    pageCount: pageCount,
    qualityPlan: plan,
    fingerprint: PdfCandidateFingerprint(
      sourceIdentity: 'source-${File(source).lengthSync()}',
      configurationIdentity: 'compression',
      orderedPageQualities: qualities,
      isProtected: password != null,
    ),
    password: password,
  );
}

List<String> _temporaryFiles(Directory directory) => directory
    .listSync()
    .where((entry) => entry.path.contains('compression-candidate-'))
    .map((entry) => entry.path)
    .toList();
