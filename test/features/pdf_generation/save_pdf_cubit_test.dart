import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_generation/application/usecases/save_pdf_workflow.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/cubit/save_pdf_cubit.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/cubit/save_pdf_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late _Repository repository;
  late _Writer writer;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('save_pdf_cubit');
    repository = _Repository(directory);
    writer = _Writer();
  });

  tearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  SavePdfCubit build() {
    final cache = SavePdfCandidateCache();
    return SavePdfCubit(
      pages: _pages,
      initialName: 'Invoice',
      initialQuality: PdfQualityPercent(value: 70),
      calculate: CalculateSavePdfSize(
        repository,
        cache,
        debounce: Duration.zero,
      ),
      preparePreview: PrepareSavePdfPreview(repository, cache),
      save: SaveGeneratedPdf(
        repository: repository,
        cache: cache,
        documents: writer,
        rollbackDocument: (_) async => const Result<void>.success(null),
        store: InMemoryPublicFileStore(),
        secrets: InMemorySecureStore(),
        clock: FixedClock(DateTime.utc(2026, 8, 8)),
        ids: SequentialIdGenerator(prefix: 'document'),
        workingDirectory: directory,
        completeSession: () async {},
      ),
      requestFactory: ({required name, required qualityPlan, password}) =>
          _request(name, qualityPlan, password),
    );
  }

  blocTest<SavePdfCubit, SavePdfState>(
    'load calculates exact bytes through queued, running, and success',
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.calculatedBytes, repository.bytes);
      expect(cubit.state.calculation, isA<AsyncJobSucceeded>());
      expect(repository.builds, 1);
    },
  );

  test('name and document quality changes supersede calculation', () async {
    final cubit = build();
    addTearDown(cubit.close);

    cubit
      ..nameChanged('Statement')
      ..documentQualityChanged(40);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cubit.state.name, 'Statement');
    expect(cubit.state.qualityPlan.documentQuality.value, 40);
    expect(
      repository.lastRequest!.fingerprint.configurationIdentity,
      'Statement',
    );
    expect(repository.lastRequest!.fingerprint.orderedPageQualities, <int>[
      40,
      40,
    ]);
  });

  test('page override precedence, removal, and reset are stable', () async {
    final cubit = build();
    addTearDown(cubit.close);

    cubit
      ..pageQualityChanged('page-0', 30)
      ..documentQualityChanged(80);
    expect(cubit.state.qualityPlan.effectiveFor('page-0').value, 30);
    expect(cubit.state.qualityPlan.effectiveFor('page-1').value, 80);

    cubit.useDocumentQuality('page-0');
    expect(cubit.state.qualityPlan.effectiveFor('page-0').value, 80);
    cubit
      ..pageQualityChanged('page-0', 50)
      ..pageQualityChanged('page-1', 100)
      ..resetPageQualities();
    expect(cubit.state.hasPageOverrides, isFalse);
  });

  test('calculation failure is retryable and does not disable Save', () async {
    final cubit = build();
    addTearDown(cubit.close);
    repository.failure = const Failure.pdf(debugDetail: 'calculate failed');

    await cubit.load();
    expect(cubit.state.calculation, isA<AsyncJobFailed>());
    expect(cubit.state.canSave, isTrue);

    repository.failure = null;
    await cubit.recalculate();
    expect(cubit.state.calculation, isA<AsyncJobSucceeded>());
  });

  test(
    'password status carries validation only and remove clears it',
    () async {
      final cubit = build();
      addTearDown(cubit.close);

      cubit.setPassword('alpha', 'different');
      expect(cubit.state.passwordEnabled, isFalse);
      expect(cubit.state.passwordProblem, ValidationIssue.passwordMismatch);

      cubit.setPassword('alpha', 'alpha');
      expect(cubit.state.passwordEnabled, isTrue);
      expect(cubit.state.passwordProblem, isNull);
      cubit.removePassword();
      expect(cubit.state.passwordEnabled, isFalse);
    },
  );

  test(
    'preview succeeds independently and returns the candidate handle',
    () async {
      final cubit = build();
      addTearDown(cubit.close);

      final handle = await cubit.preview();

      expect(handle, isNotNull);
      expect(cubit.state.preview, isA<AsyncJobSucceeded>());
      expect(cubit.state.commit, const AsyncJobView.idle());
    },
  );

  test('preview cancellation retains configuration', () async {
    repository.holdBuild = true;
    final cubit = build();
    addTearDown(cubit.close);
    final pending = cubit.preview();
    await Future<void>.delayed(Duration.zero);

    cubit.cancelPreview();
    expect(await pending, isNull);
    expect(cubit.state.preview, isA<AsyncJobCancelled>());
    expect(cubit.state.name, 'Invoice');
    expect(cubit.state.qualityPlan.documentQuality.value, 70);
  });

  test(
    'Save supersedes calculation and emits one committed document',
    () async {
      final cubit = build();
      addTearDown(cubit.close);
      repository.holdBuild = true;
      final calculation = cubit.load();
      await Future<void>.delayed(Duration.zero);
      repository.holdBuild = false;

      final document = await cubit.save();
      await calculation;

      expect(document, isNotNull);
      expect(cubit.state.commit, isA<AsyncJobSucceeded>());
      expect(cubit.state.document, document);
      expect(writer.saved, hasLength(1));
    },
  );

  test(
    'Save failure can retry and successful completion remains one-shot',
    () async {
      final cubit = build();
      addTearDown(cubit.close);
      repository.failure = const Failure.storage();

      expect(await cubit.save(), isNull);
      expect(cubit.state.commit, isA<AsyncJobFailed>());
      repository.failure = null;
      final first = await cubit.save();
      final second = await cubit.save();

      expect(first, isNotNull);
      expect(second, first);
      expect(writer.saved, hasLength(1));
    },
  );
}

const _pages = <PageRef>[
  PageRef(id: PageId('page-0'), imagePath: '/page-0.jpg'),
  PageRef(id: PageId('page-1'), imagePath: '/page-1.jpg'),
];

SavePdfWorkflowRequest _request(
  String name,
  PageQualityPlan plan,
  String? password,
) {
  final qualities = <int>[
    for (final page in _pages) plan.effectiveFor(page.id.value).value,
  ];
  final fingerprint = PdfCandidateFingerprint(
    sourceIdentity: 'session-1',
    configurationIdentity: name,
    orderedPageQualities: qualities,
    isProtected: password != null,
  );
  return SavePdfWorkflowRequest(
    title: name,
    folders: const <String>[],
    sourcePages: _pages,
    candidateRequest: GeneratedPdfCandidateRequest(
      pages: <GeneratedPdfCandidatePage>[
        for (var index = 0; index < _pages.length; index++)
          GeneratedPdfCandidatePage(
            stableId: _pages[index].id.value,
            page: PdfPageSpec(
              imagePath: _pages[index].imagePath,
              rotation: _pages[index].rotation,
            ),
            quality: PdfQualityPercent(value: qualities[index]),
          ),
      ],
      fingerprint: fingerprint,
      password: password,
    ),
  );
}

class _Repository implements GeneratedPdfCandidateRepository {
  _Repository(this.directory);

  final Directory directory;
  final int bytes = 1536;
  int builds = 0;
  Failure? failure;
  bool holdBuild = false;
  GeneratedPdfCandidateRequest? lastRequest;

  @override
  Future<Result<PdfCandidate>> buildCandidate(
    GeneratedPdfCandidateRequest request, {
    required CancellationToken token,
    required PdfCandidateProgress onProgress,
  }) async {
    builds++;
    lastRequest = request;
    if (holdBuild) {
      await token.onCancel.first;
    }
    if (token.isCancelled) {
      return const Result<PdfCandidate>.failure(Failure.cancelled());
    }
    final configured = failure;
    if (configured != null) {
      return Result<PdfCandidate>.failure(configured);
    }
    onProgress(JobProgress(percent: 55));
    final path = '${directory.path}/candidate-$builds.pdf';
    File(path).writeAsBytesSync(List<int>.filled(bytes, builds));
    onProgress(JobProgress(percent: 100));
    return Result<PdfCandidate>.success(
      PdfCandidate(
        handle: path,
        exactBytes: bytes,
        pageCount: request.pages.length,
        fingerprint: request.fingerprint,
      ),
    );
  }

  @override
  Future<void> discard(PdfCandidate candidate) async {
    final file = File(candidate.handle);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  @override
  Future<Result<ComposedPdf>> promote(
    PdfCandidate candidate, {
    required String destinationPath,
    required CancellationToken token,
  }) async {
    if (token.isCancelled) {
      return const Result<ComposedPdf>.failure(Failure.cancelled());
    }
    File(candidate.handle).copySync(destinationPath);
    File(candidate.handle).deleteSync();
    return Result<ComposedPdf>.success(
      ComposedPdf(
        filePath: destinationPath,
        sizeInBytes: candidate.exactBytes,
        pageCount: candidate.pageCount,
      ),
    );
  }

  @override
  Future<Result<PdfCandidate>> verifyCandidate(
    PdfCandidate candidate, {
    String? password,
  }) async => Result<PdfCandidate>.success(candidate);
}

class _Writer implements DocumentWriter {
  final List<Document> saved = <Document>[];

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async {
    saved.add(document);
    return Result<Document>.success(document);
  }

  @override
  Future<Result<Document>> updateMetadata(Document document) async =>
      Result<Document>.success(document);
}
