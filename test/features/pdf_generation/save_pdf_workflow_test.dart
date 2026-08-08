import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_generation/application/usecases/save_pdf_workflow.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late _CandidateRepository candidates;
  late SavePdfCandidateCache cache;
  late _Writer writer;
  late _Store store;
  late InMemorySecureStore secrets;
  late List<DocumentId> rollbacks;
  late int completedSessions;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('save_pdf_workflow');
    candidates = _CandidateRepository(directory);
    cache = SavePdfCandidateCache();
    writer = _Writer();
    store = _Store();
    secrets = InMemorySecureStore();
    rollbacks = <DocumentId>[];
    completedSessions = 0;
  });

  tearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  SaveGeneratedPdf save() => SaveGeneratedPdf(
    repository: candidates,
    cache: cache,
    documents: writer,
    rollbackDocument: (id) async {
      rollbacks.add(id);
      return const Result<void>.success(null);
    },
    store: store,
    secrets: secrets,
    clock: FixedClock(DateTime.utc(2026, 8, 8, 12)),
    ids: SequentialIdGenerator(prefix: 'document'),
    workingDirectory: directory,
    completeSession: () async => completedSessions++,
  );

  test('calculation honours debounce cancellation without building', () async {
    final token = CancellationToken();
    final calculation = CalculateSavePdfSize(
      candidates,
      cache,
      debounce: const Duration(milliseconds: 40),
    );
    final pending = calculation(_request(), token: token, onProgress: (_) {});
    token.cancel();

    expect((await pending).failureOrNull, const Failure.cancelled());
    expect(candidates.builds, 0);
  });

  test('preview reuses a verified matching calculation candidate', () async {
    final request = _request();
    await CalculateSavePdfSize(candidates, cache, debounce: Duration.zero)(
      request,
      token: CancellationToken(),
      onProgress: (_) {},
    );

    final preview = await PrepareSavePdfPreview(candidates, cache)(
      request,
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(preview, isA<Success<PdfCandidate>>());
    expect(candidates.builds, 1);
    expect(candidates.verifications, 1);
  });

  test('request rejects an empty or mismatched source page list', () {
    final valid = _request();

    expect(
      () => SavePdfWorkflowRequest(
        title: 'Invoice',
        folders: const <String>[],
        sourcePages: const <PageRef>[],
        candidateRequest: valid.candidateRequest,
      ),
      throwsArgumentError,
    );
  });

  test('candidate cache exposes and clears its retained candidate', () async {
    await CalculateSavePdfSize(candidates, cache, debounce: Duration.zero)(
      _request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(cache.candidate, isNotNull);
    cache.clear();
    expect(cache.candidate, isNull);
  });

  test('a stale cached candidate is discarded and rebuilt', () async {
    final value = _request();
    await CalculateSavePdfSize(candidates, cache, debounce: Duration.zero)(
      value,
      token: CancellationToken(),
      onProgress: (_) {},
    );
    candidates.verifyFailure = const Failure.pdf();

    final result = await PrepareSavePdfPreview(candidates, cache)(
      value,
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result, isA<Success<PdfCandidate>>());
    expect(candidates.builds, 2);
    expect(candidates.discards, 1);
  });

  test('a fingerprint change prevents candidate reuse', () async {
    final first = _request();
    final changed = _request(qualities: const <int>[70, 40]);
    await CalculateSavePdfSize(candidates, cache, debounce: Duration.zero)(
      first,
      token: CancellationToken(),
      onProgress: (_) {},
    );

    await PrepareSavePdfPreview(candidates, cache)(
      changed,
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(candidates.builds, 2);
    expect(candidates.lastRequest!.fingerprint.orderedPageQualities, <int>[
      70,
      40,
    ]);
  });

  test(
    'Save starts immediately while a calculation is still debounced',
    () async {
      final request = _request();
      final calculationToken = CancellationToken();
      final pendingCalculation = CalculateSavePdfSize(
        candidates,
        cache,
        debounce: const Duration(seconds: 1),
      )(request, token: calculationToken, onProgress: (_) {});

      final result = await save()(
        request,
        token: CancellationToken(),
        onProgress: (_) {},
      );
      calculationToken.cancel();

      expect(result, isA<Success<Document>>());
      expect(candidates.builds, 1);
      expect(
        (await pendingCalculation).failureOrNull,
        const Failure.cancelled(),
      );
    },
  );

  test(
    'cancellation after promotion leaves no file, record, or session cleanup',
    () async {
      final token = CancellationToken();
      candidates.onPromote = token.cancel;

      final result = await save()(_request(), token: token, onProgress: (_) {});

      expect(result.failureOrNull, const Failure.cancelled());
      expect(store.files, isEmpty);
      expect(writer.saved, isEmpty);
      expect(completedSessions, 0);
      expect(
        directory.listSync().where(
          (entry) => entry.path.endsWith('.commit.pdf'),
        ),
        isEmpty,
      );
    },
  );

  test('cancellation after candidate creation discards it', () async {
    final token = CancellationToken();
    candidates.onBuild = token.cancel;

    final result = await save()(_request(), token: token, onProgress: (_) {});

    expect(result.failureOrNull, const Failure.cancelled());
    expect(candidates.discards, 1);
    expect(candidates.promotions, 0);
  });

  test('promotion failure is returned before publishing', () async {
    candidates.promoteFailure = const Failure.storageFull();

    final result = await save()(
      _request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.storageFull());
    expect(store.files, isEmpty);
  });

  test('library listing failure is returned before publishing', () async {
    store.failures['list'] = const Failure.storage();

    final result = await save()(
      _request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.storage());
    expect(writer.saved, isEmpty);
  });

  test('cancellation after publishing removes authoritative bytes', () async {
    final token = CancellationToken();
    store.onWrite = token.cancel;

    final result = await save()(_request(), token: token, onProgress: (_) {});

    expect(result.failureOrNull, const Failure.cancelled());
    expect(store.files, isEmpty);
    expect(writer.saved, isEmpty);
  });

  test('record failure removes authoritative bytes', () async {
    writer.failure = const Failure.storage();

    final result = await save()(
      _request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.storage());
    expect(store.files, isEmpty);
  });

  test('Save promotes a matching calculation without rebuilding', () async {
    final request = _request(qualities: const <int>[40, 100]);
    await CalculateSavePdfSize(candidates, cache, debounce: Duration.zero)(
      request,
      token: CancellationToken(),
      onProgress: (_) {},
    );

    final result = await save()(
      request,
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result, isA<Success<Document>>());
    expect(candidates.builds, 1);
    expect(candidates.verifications, 1);
    expect(candidates.promotions, 1);
  });

  test('a cancelled Save can retry unchanged', () async {
    final operation = save();
    final firstToken = CancellationToken();
    candidates.onPromote = firstToken.cancel;
    final first = await operation(
      _request(),
      token: firstToken,
      onProgress: (_) {},
    );
    candidates.onPromote = null;

    final retried = await operation(
      _request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(first.failureOrNull, const Failure.cancelled());
    expect(retried, isA<Success<Document>>());
    expect(candidates.builds, 2);
    expect(writer.saved, hasLength(1));
  });

  test('storage failure leaves no record and keeps the session', () async {
    store.failures['writeFile'] = const Failure.storageFull();

    final result = await save()(
      _request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.storageFull());
    expect(writer.saved, isEmpty);
    expect(store.files, isEmpty);
    expect(completedSessions, 0);
  });

  test(
    'secure-storage failure rolls back record and authoritative bytes',
    () async {
      secrets.failNextOperation = true;

      final result = await save()(
        _request(password: 'operation secret'),
        token: CancellationToken(),
        onProgress: (_) {},
      );

      expect(result.failureOrNull, const Failure.secureStorageUnavailable());
      expect(writer.saved, hasLength(1));
      expect(rollbacks, <DocumentId>[const DocumentId('document-1')]);
      expect(store.files, isEmpty);
      expect(completedSessions, 0);
    },
  );

  test(
    'successful protected commit stores metadata then secret and cleans session',
    () async {
      final result = await save()(
        _request(password: 'operation secret'),
        token: CancellationToken(),
        onProgress: (_) {},
      );
      final document = result.valueOrNull!;

      expect(document.title, 'Invoice');
      expect(document.pageCount, 2);
      expect(document.sizeInBytes, candidates.candidateBytes);
      expect(document.isProtected, isTrue);
      expect(writer.saved.single, document);
      expect(
        secrets.values[SecureStorageKeys.pdfPassword(document.id.value)],
        'operation secret',
      );
      expect(store.files.keys, <String>['Invoice.pdf']);
      expect(completedSessions, 1);
    },
  );

  test('session cleanup failure does not undo a verified commit', () async {
    final operation = SaveGeneratedPdf(
      repository: candidates,
      cache: cache,
      documents: writer,
      rollbackDocument: (_) async => const Result<void>.success(null),
      store: store,
      secrets: secrets,
      clock: FixedClock(DateTime.utc(2026, 8, 8, 12)),
      ids: SequentialIdGenerator(prefix: 'document'),
      workingDirectory: directory,
      completeSession: () async => throw StateError('cleanup failed'),
    );

    final result = await operation(
      _request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result, isA<Success<Document>>());
    expect(store.files, isNotEmpty);
  });

  test(
    'successful Save is one-shot and collision naming is deterministic',
    () async {
      store.files['Invoice.pdf'] = 'existing';
      final operation = save();
      final first = await operation(
        _request(),
        token: CancellationToken(),
        onProgress: (_) {},
      );
      final second = await operation(
        _request(),
        token: CancellationToken(),
        onProgress: (_) {},
      );

      expect(first.valueOrNull, second.valueOrNull);
      expect(candidates.builds, 1);
      expect(writer.saved, hasLength(1));
      expect(store.files.keys, contains('Invoice (2).pdf'));
      expect(completedSessions, 1);
    },
  );

  test('protection changes the fingerprint without exposing secret text', () {
    final plain = _request().candidateRequest;
    final protected = _request(password: 'operation secret').candidateRequest;

    expect(plain.fingerprint, isNot(protected.fingerprint));
    expect(protected.fingerprint.isProtected, isTrue);
    expect(
      protected.fingerprint.toJson().toString(),
      isNot(contains('secret')),
    );
  });
}

SavePdfWorkflowRequest _request({
  List<int> qualities = const <int>[70, 70],
  String? password,
}) {
  final pages = <PageRef>[
    for (var index = 0; index < qualities.length; index++)
      PageRef(id: PageId('page-$index'), imagePath: '/page-$index.jpg'),
  ];
  final fingerprint = PdfCandidateFingerprint(
    sourceIdentity: 'session-1',
    configurationIdentity: 'Invoice',
    orderedPageQualities: qualities,
    isProtected: password != null,
  );
  return SavePdfWorkflowRequest(
    title: 'Invoice',
    folders: const <String>[],
    sourcePages: pages,
    candidateRequest: GeneratedPdfCandidateRequest(
      pages: <GeneratedPdfCandidatePage>[
        for (var index = 0; index < pages.length; index++)
          GeneratedPdfCandidatePage(
            stableId: pages[index].id.value,
            page: PdfPageSpec(
              imagePath: pages[index].imagePath,
              rotation: pages[index].rotation,
            ),
            quality: PdfQualityPercent(value: qualities[index]),
          ),
      ],
      fingerprint: fingerprint,
      password: password,
    ),
  );
}

class _CandidateRepository implements GeneratedPdfCandidateRepository {
  _CandidateRepository(this.directory);

  final Directory directory;
  int builds = 0;
  int verifications = 0;
  int promotions = 0;
  int discards = 0;
  final int candidateBytes = 2048;
  GeneratedPdfCandidateRequest? lastRequest;
  void Function()? onPromote;
  void Function()? onBuild;
  Failure? promoteFailure;
  Failure? verifyFailure;

  @override
  Future<Result<PdfCandidate>> buildCandidate(
    GeneratedPdfCandidateRequest request, {
    required CancellationToken token,
    required PdfCandidateProgress onProgress,
  }) async {
    builds++;
    lastRequest = request;
    if (token.isCancelled) {
      return const Result<PdfCandidate>.failure(Failure.cancelled());
    }
    final path = '${directory.path}/candidate-$builds.pdf';
    File(path).writeAsBytesSync(List<int>.filled(candidateBytes, builds));
    onProgress(JobProgress(percent: 100));
    onBuild?.call();
    return Result<PdfCandidate>.success(
      PdfCandidate(
        handle: path,
        exactBytes: candidateBytes,
        pageCount: request.pages.length,
        fingerprint: request.fingerprint,
      ),
    );
  }

  @override
  Future<void> discard(PdfCandidate candidate) async {
    discards++;
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
    promotions++;
    final failure = promoteFailure;
    if (failure != null) return Result<ComposedPdf>.failure(failure);
    File(candidate.handle).copySync(destinationPath);
    File(candidate.handle).deleteSync();
    onPromote?.call();
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
  }) async {
    verifications++;
    final failure = verifyFailure;
    if (failure != null) {
      verifyFailure = null;
      return Result<PdfCandidate>.failure(failure);
    }
    return File(candidate.handle).existsSync()
        ? Result<PdfCandidate>.success(candidate)
        : const Result<PdfCandidate>.failure(Failure.notFound());
  }
}

class _Store extends InMemoryPublicFileStore {
  void Function()? onWrite;

  @override
  Future<Result<String>> writeFile(LibraryPath path, String sourcePath) async {
    final result = await super.writeFile(path, sourcePath);
    if (result case Success()) onWrite?.call();
    return result;
  }
}

class _Writer implements DocumentWriter {
  final List<Document> saved = <Document>[];
  Failure? failure;

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async {
    final configured = failure;
    if (configured != null) {
      return Result<Document>.failure(configured);
    }
    saved.add(document);
    return Result<Document>.success(document);
  }

  @override
  Future<Result<Document>> updateMetadata(Document document) async =>
      Result<Document>.success(document);
}
