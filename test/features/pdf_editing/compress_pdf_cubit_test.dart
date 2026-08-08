library;

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
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_editing/application/usecases/compression_workflow.dart';
import 'package:doc_scanly/features/pdf_editing/domain/compression_candidate.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/compress_pdf_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _Harness harness;

  setUp(() async {
    harness = _Harness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.cubit.close();
    harness.dispose();
  });

  test(
    'starts at 80% and load publishes exact original/result sizes',
    () async {
      expect(harness.cubit.state.qualityPlan.documentQuality.value, 80);

      await harness.cubit.load();

      expect(harness.cubit.state.originalBytes, 100);
      expect(harness.cubit.state.calculatedBytes, 60);
      expect(harness.cubit.state.savedBytes, 40);
      expect(harness.cubit.state.calculation, isA<AsyncJobSucceeded>());
    },
  );

  test(
    'document and page changes preserve override precedence and reset',
    () async {
      harness.cubit.pageQualityChanged(1, 30);
      await harness.settle();
      harness.cubit.documentQualityChanged(70);
      await harness.settle();

      expect(harness.cubit.state.effectiveQualities, <int>[70, 30]);

      harness.cubit.useDocumentQuality(1);
      await harness.settle();
      expect(harness.cubit.state.effectiveQualities, <int>[70, 70]);

      harness.cubit.pageQualityChanged(0, 100);
      await harness.settle();
      harness.cubit.resetPageQualities();
      await harness.settle();
      expect(harness.cubit.state.hasPageOverrides, isFalse);
    },
  );

  test('calculation failure is retryable', () async {
    harness.candidates.buildFailure = const Failure.pdf();
    await harness.cubit.load();
    expect(harness.cubit.state.calculation, isA<AsyncJobFailed>());

    harness.candidates.buildFailure = null;
    await harness.cubit.recalculate();
    expect(harness.cubit.state.calculatedBytes, 60);
  });

  test('preview succeeds independently and returns candidate handle', () async {
    final handle = await harness.cubit.previewPdf();

    expect(handle, isNotNull);
    expect(harness.cubit.state.preview, isA<AsyncJobSucceeded>());
    expect(harness.cubit.state.commit, const AsyncJobView.idle());
  });

  test('preview cancellation remains on the editable workflow', () async {
    harness.candidates.cancelDuringBuild = true;

    final handle = await harness.cubit.previewPdf();

    expect(handle, isNull);
    expect(harness.cubit.state.preview, isA<AsyncJobCancelled>());
    expect(harness.cubit.state.qualityPlan.documentQuality.value, 80);
  });

  test('all-pages-100 requires review before destination selection', () async {
    harness.cubit.documentQualityChanged(100);
    await harness.settle();

    expect(harness.cubit.beginDestinationSelection(), isFalse);
    expect(harness.cubit.state.showAllPassThroughReview, isTrue);

    harness.cubit.dismissReview();
    expect(harness.cubit.state.showAllPassThroughReview, isFalse);
    harness.cubit.acknowledgeAllPassThrough();
  });

  test('copy completion carries new document and retains source', () async {
    final result = await harness.cubit.saveTo(CompressionDestination.copy);

    expect(result?.destination, CompressionDestination.copy);
    expect(result?.documentId, isNot('source'));
    expect(harness.writer.saved, hasLength(1));
    expect(harness.sourceFile.readAsStringSync(), 'original');
  });

  test(
    'overwrite completion refreshes original identity and metadata',
    () async {
      final result = await harness.cubit.saveTo(
        CompressionDestination.overwrite,
      );

      expect(result?.documentId, 'source');
      expect(result?.destination, CompressionDestination.overwrite);
      expect(harness.writer.updated.single.sizeInBytes, 60);
    },
  );

  test('no-benefit result is reviewed and can continue', () async {
    harness.candidates.resultBytes = 120;

    final blocked = await harness.cubit.saveTo(CompressionDestination.copy);
    expect(blocked, isNull);
    expect(harness.cubit.state.showNoBenefitReview, isTrue);
    expect(harness.cubit.state.pendingDestination, CompressionDestination.copy);

    final continued = await harness.cubit.continueWithoutBenefit();
    expect(continued?.hasNoBenefit, isTrue);
  });

  test('Save cancellation is visible and retry succeeds', () async {
    harness.candidates.cancelDuringPromotion = true;

    final cancelled = await harness.cubit.saveTo(
      CompressionDestination.overwrite,
    );
    expect(cancelled, isNull);
    expect(harness.cubit.state.commit, isA<AsyncJobCancelled>());

    harness.candidates.cancelDuringPromotion = false;
    final retried = await harness.cubit.saveTo(
      CompressionDestination.overwrite,
    );
    expect(retried, isNotNull);
  });

  test('commit failure is typed and retryable', () async {
    harness.candidates.promoteFailure = const Failure.storageFull();

    final failed = await harness.cubit.saveTo(CompressionDestination.copy);
    expect(failed, isNull);
    expect(harness.cubit.state.commit, isA<AsyncJobFailed>());

    harness.candidates.promoteFailure = null;
    final retried = await harness.cubit.saveTo(CompressionDestination.copy);
    expect(retried, isNotNull);
  });

  test('successful result is emitted once by the one-shot use case', () async {
    final first = await harness.cubit.saveTo(CompressionDestination.copy);
    final second = await harness.cubit.saveTo(CompressionDestination.copy);

    expect(second, first);
    expect(harness.writer.saved, hasLength(1));
  });
}

class _Harness {
  late final Directory temporary;
  late final Directory working;
  late final FilesystemPublicFileStore store;
  late final _Candidates candidates;
  late final _Writer writer;
  late final CompressPdfCubit cubit;
  late final File sourceFile;

  Future<void> setUp() async {
    temporary = Directory.systemTemp.createTempSync('compress_cubit');
    working = Directory('${temporary.path}/working')..createSync();
    store = FilesystemPublicFileStore(temporary);
    await store.initialise();
    sourceFile = File('${store.rootDirectory.path}/Invoice.pdf')
      ..writeAsStringSync('original');
    candidates = _Candidates(working);
    writer = _Writer();
    final cache = CompressionCandidateCache();
    final save = SaveCompressedPdf(
      repository: candidates,
      cache: cache,
      documents: writer,
      rollbackCopy: (_) async => const Result<void>.success(null),
      restoreMetadata: (_) async => const Result<void>.success(null),
      store: store,
      secrets: InMemorySecureStore(),
      clock: FixedClock(DateTime.utc(2026, 8, 8)),
      ids: SequentialIdGenerator(),
      workingDirectory: working,
    );
    cubit = CompressPdfCubit(
      title: 'Invoice',
      pageCount: 2,
      originalBytes: 100,
      calculate: CalculateCompressedSize(
        candidates,
        cache,
        debounce: Duration.zero,
      ),
      preparePreview: PrepareCompressionPreview(candidates, cache),
      save: save,
      requestFactory: ({required qualityPlan, required destination}) =>
          _request(qualityPlan, destination),
    );
  }

  CompressionWorkflowRequest _request(
    PageQualityPlan qualityPlan,
    CompressionDestination? destination,
  ) => CompressionWorkflowRequest(
    source: _source,
    sourcePages: const <DocumentPage>[],
    draft: CompressionDraft(
      sourceDocumentId: 'source',
      pageCount: 2,
      originalBytes: 100,
      qualityPlan: qualityPlan,
      destination: destination,
    ),
    candidateRequest: CompressionCandidateRequest(
      sourcePath: sourceFile.path,
      pageCount: 2,
      qualityPlan: qualityPlan,
      fingerprint: PdfCandidateFingerprint(
        sourceIdentity: 'source-v1',
        configurationIdentity: qualityPlan.toJson().toString(),
        orderedPageQualities: <int>[
          qualityPlan.effectiveFor('0').value,
          qualityPlan.effectiveFor('1').value,
        ],
        isProtected: false,
      ),
    ),
  );

  Document get _source => Document(
    id: const DocumentId('source'),
    title: 'Invoice',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026, 2),
    pageCount: 2,
    sizeInBytes: 100,
    libraryPath: LibraryPath.parse('Invoice.pdf'),
  );

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  void dispose() {
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  }
}

class _Writer implements DocumentWriter {
  final List<Document> saved = <Document>[];
  final List<Document> updated = <Document>[];

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async {
    saved.add(document);
    return Result<Document>.success(document);
  }

  @override
  Future<Result<Document>> updateMetadata(Document document) async {
    updated.add(document);
    return Result<Document>.success(document);
  }
}

class _Candidates implements CompressionCandidateRepository {
  _Candidates(this.directory);

  final Directory directory;
  int resultBytes = 60;
  int builds = 0;
  Failure? buildFailure;
  Failure? promoteFailure;
  bool cancelDuringBuild = false;
  bool cancelDuringPromotion = false;
  PdfCandidate? owned;

  @override
  Future<Result<PdfCandidate>> buildCandidate(
    CompressionCandidateRequest request, {
    required CancellationToken token,
    required CompressionCandidateProgress onProgress,
  }) async {
    final failure = buildFailure;
    if (failure != null) return Result<PdfCandidate>.failure(failure);
    if (cancelDuringBuild) {
      token.cancel();
      return const Result<PdfCandidate>.failure(Failure.cancelled());
    }
    builds++;
    final file = File('${directory.path}/candidate-$builds.pdf')
      ..writeAsBytesSync(List<int>.filled(resultBytes, 1));
    onProgress(JobProgress(percent: 100));
    owned = PdfCandidate(
      handle: file.path,
      exactBytes: resultBytes,
      pageCount: request.pageCount,
      fingerprint: request.fingerprint,
    );
    return Result<PdfCandidate>.success(owned!);
  }

  @override
  Future<void> discard(PdfCandidate candidate) async {
    final file = File(candidate.handle);
    if (file.existsSync()) file.deleteSync();
    if (owned == candidate) owned = null;
  }

  @override
  Future<Result<EditedPdf>> promote(
    PdfCandidate candidate, {
    required String destinationPath,
    required CancellationToken token,
  }) async {
    final failure = promoteFailure;
    if (failure != null) return Result<EditedPdf>.failure(failure);
    File(candidate.handle).copySync(destinationPath);
    File(candidate.handle).deleteSync();
    owned = null;
    if (cancelDuringPromotion) token.cancel();
    return Result<EditedPdf>.success(
      EditedPdf(
        filePath: destinationPath,
        pageCount: candidate.pageCount,
        sizeInBytes: candidate.exactBytes,
      ),
    );
  }

  @override
  Future<Result<PdfCandidate>> verifyCandidate(
    PdfCandidate candidate, {
    String? password,
  }) async {
    final file = File(candidate.handle);
    return file.existsSync() && file.lengthSync() == candidate.exactBytes
        ? Result<PdfCandidate>.success(candidate)
        : const Result<PdfCandidate>.failure(Failure.pdf());
  }
}
