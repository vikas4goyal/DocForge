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
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_editing/application/usecases/compression_workflow.dart';
import 'package:doc_scanly/features/pdf_editing/domain/compression_candidate.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/compress_pdf_cubit.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/pdf_edit_keys.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/screens/compress_pdf_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _Harness harness;
  late List<String> previews;
  late List<CompressionCommitResult> completions;

  setUp(() async {
    harness = _Harness();
    await harness.setUp();
    previews = <String>[];
    completions = <CompressionCommitResult>[];
  });

  tearDown(() async {
    await harness.cubit.close();
    harness.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester, {Size? size}) async {
    if (size != null) tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: CompressPdfScreen(
          cubit: harness.cubit,
          onOpenPreview: previews.add,
          onCompleted: completions.add,
        ),
      ),
    );
    await tester.runAsync(harness.cubit.load);
    await tester.pumpAndSettle();
  }

  Future<void> tapWithFileWork(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('default renders 80%, exact sizes, saving, and page rows', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byKey(PdfEditKeys.compressScreen), findsOneWidget);
    expect(find.text('Document quality · 80%'), findsOneWidget);
    expect(find.text('Original: 100 B · Result: 60 B'), findsOneWidget);
    expect(find.text('40 B saved'), findsOneWidget);
    expect(find.byKey(PdfEditKeys.compressPageQuality(1)), findsOneWidget);
  });

  testWidgets(
    'page override dialog applies and Reset all restores document quality',
    (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(PdfEditKeys.compressPageQuality(0)));
      await tester.pumpAndSettle();
      expect(find.byKey(PdfEditKeys.compressPageSlider), findsOneWidget);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('80% · Custom quality'), findsOneWidget);

      await tester.tap(find.byKey(PdfEditKeys.compressResetAll));
      await tester.pumpAndSettle();
      expect(find.text('80% · Custom quality'), findsNothing);
    },
  );

  testWidgets('calculation failure exposes Retry and recovers', (tester) async {
    harness.candidates.buildFailure = const Failure.pdf();
    await pumpScreen(tester);
    expect(find.byKey(PdfEditKeys.compressSizeRetry), findsOneWidget);

    harness.candidates.buildFailure = null;
    await tester.tap(find.byKey(PdfEditKeys.compressSizeRetry));
    await tester.pumpAndSettle();
    expect(find.text('Original: 100 B · Result: 60 B'), findsOneWidget);
  });

  testWidgets(
    'Preview prepares candidate and invokes typed navigation callback',
    (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(PdfEditKeys.compressPreview));
      await tester.pumpAndSettle();

      expect(previews, hasLength(1));
      expect(find.byKey(PdfEditKeys.compressScreen), findsOneWidget);
    },
  );

  testWidgets('100% warning adjusts or continues to destination', (
    tester,
  ) async {
    await pumpScreen(tester);
    harness.cubit.documentQualityChanged(100);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(PdfEditKeys.compressSave));
    await tester.pumpAndSettle();
    expect(find.byKey(PdfEditKeys.compressPassThroughDialog), findsOneWidget);
    await tester.tap(find.byKey(PdfEditKeys.compressAdjustQuality));
    await tester.pumpAndSettle();
    expect(find.byKey(PdfEditKeys.compressScreen), findsOneWidget);

    await tester.tap(find.byKey(PdfEditKeys.compressSave));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PdfEditKeys.compressContinuePassThrough));
    await tester.pumpAndSettle();
    expect(find.byKey(PdfEditKeys.compressDestinationDialog), findsOneWidget);
  });

  testWidgets('copy and overwrite destinations return typed completions', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(PdfEditKeys.compressSave));
    await tester.pumpAndSettle();
    await tapWithFileWork(
      tester,
      find.byKey(PdfEditKeys.compressDestinationCopy),
    );

    expect(
      harness.cubit.state.commit,
      isA<AsyncJobSucceeded>(),
      reason: '${harness.cubit.state.commit}',
    );
    expect(completions.single.destination, CompressionDestination.copy);
    expect(harness.sourceFile.readAsStringSync(), 'original');
  });

  testWidgets('no-benefit review can continue the retained destination', (
    tester,
  ) async {
    harness.candidates.resultBytes = 120;
    await pumpScreen(tester);

    await tester.tap(find.byKey(PdfEditKeys.compressSave));
    await tester.pumpAndSettle();
    await tapWithFileWork(
      tester,
      find.byKey(PdfEditKeys.compressDestinationCopy),
    );
    expect(find.byKey(PdfEditKeys.compressNoBenefitDialog), findsOneWidget);

    await tapWithFileWork(
      tester,
      find.byKey(PdfEditKeys.compressContinueNoBenefit),
    );
    expect(
      harness.cubit.state.commit,
      isA<AsyncJobSucceeded>(),
      reason: '${harness.cubit.state.commit}',
    );
    expect(completions.single.hasNoBenefit, isTrue);
  });

  testWidgets('commit cancellation and failure keep Compress available', (
    tester,
  ) async {
    harness.candidates.cancelDuringPromotion = true;
    await pumpScreen(tester);

    await tester.tap(find.byKey(PdfEditKeys.compressSave));
    await tester.pumpAndSettle();
    await tapWithFileWork(
      tester,
      find.byKey(PdfEditKeys.compressDestinationOverwrite),
    );
    expect(completions, isEmpty);
    expect(find.byKey(PdfEditKeys.compressScreen), findsOneWidget);

    harness.candidates.cancelDuringPromotion = false;
    harness.candidates.promoteFailure = const Failure.storageFull();
    await tester.tap(find.byKey(PdfEditKeys.compressSave));
    await tester.pumpAndSettle();
    await tapWithFileWork(
      tester,
      find.byKey(PdfEditKeys.compressDestinationOverwrite),
    );
    expect(completions, isEmpty);
    expect(harness.cubit.state.commit, isA<AsyncJobFailed>());
  });

  testWidgets('wide layout and maximum text scale remain scrollable', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpScreen(tester, size: const Size(1200, 900));

    expect(find.byKey(PdfEditKeys.compressScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Harness {
  late final Directory temporary;
  late final Directory working;
  late final _SyncStore store;
  late final _Candidates candidates;
  late final _Writer writer;
  late final CompressPdfCubit cubit;
  late final File sourceFile;

  Future<void> setUp() async {
    temporary = Directory.systemTemp.createTempSync('compress_component');
    working = Directory('${temporary.path}/working')..createSync();
    store = _SyncStore(temporary);
    await store.initialise();
    sourceFile = File('${store.rootDirectory.path}/Invoice.pdf')
      ..writeAsStringSync('original');
    candidates = _Candidates(working);
    writer = _Writer();
    final cache = CompressionCandidateCache();
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
      save: SaveCompressedPdf(
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
      ),
      requestFactory: ({required qualityPlan, required destination}) =>
          _request(qualityPlan, destination),
    );
  }

  CompressionWorkflowRequest _request(
    PageQualityPlan plan,
    CompressionDestination? destination,
  ) => CompressionWorkflowRequest(
    source: Document(
      id: const DocumentId('source'),
      title: 'Invoice',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 2),
      pageCount: 2,
      sizeInBytes: 100,
      libraryPath: LibraryPath.parse('Invoice.pdf'),
    ),
    sourcePages: const <DocumentPage>[],
    draft: CompressionDraft(
      sourceDocumentId: 'source',
      pageCount: 2,
      originalBytes: 100,
      qualityPlan: plan,
      destination: destination,
    ),
    candidateRequest: CompressionCandidateRequest(
      sourcePath: sourceFile.path,
      pageCount: 2,
      qualityPlan: plan,
      fingerprint: PdfCandidateFingerprint(
        sourceIdentity: 'source-v1',
        configurationIdentity: plan.toJson().toString(),
        orderedPageQualities: <int>[
          plan.effectiveFor('0').value,
          plan.effectiveFor('1').value,
        ],
        isProtected: false,
      ),
    ),
  );

  void dispose() {
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  }
}

class _SyncStore extends FilesystemPublicFileStore {
  _SyncStore(super.containerDirectory);

  @override
  Future<Result<List<PublicEntry>>> list(List<String> folders) async {
    final directory = Directory(
      <String>[rootDirectory.path, ...folders].join(Platform.pathSeparator),
    );
    if (!directory.existsSync()) {
      return const Result<List<PublicEntry>>.failure(Failure.notFound());
    }
    return Result<List<PublicEntry>>.success(<PublicEntry>[
      for (final entity in directory.listSync())
        if (entity is File)
          PublicEntry(
            kind: PublicEntryKind.file,
            name: entity.uri.pathSegments.last,
            folders: folders,
            sizeBytes: entity.lengthSync(),
          ),
    ]);
  }

  @override
  Future<Result<String>> writeFile(LibraryPath path, String sourcePath) async {
    final target = File(
      <String>[
        rootDirectory.path,
        ...path.folders,
        path.fileName,
      ].join(Platform.pathSeparator),
    );
    target.parent.createSync(recursive: true);
    File(sourcePath).copySync(target.path);
    return Result<String>.success(target.path);
  }

  @override
  Future<Result<String>> materialise(LibraryPath path) async {
    final target = File(
      <String>[
        rootDirectory.path,
        ...path.folders,
        path.fileName,
      ].join(Platform.pathSeparator),
    );
    return target.existsSync()
        ? Result<String>.success(target.path)
        : const Result<String>.failure(Failure.notFound());
  }

  @override
  Future<Result<void>> releaseMaterialised(LibraryPath path) async =>
      const Result<void>.success(null);

  @override
  Future<Result<void>> delete(LibraryPath path) async {
    final target = File(
      <String>[
        rootDirectory.path,
        ...path.folders,
        path.fileName,
      ].join(Platform.pathSeparator),
    );
    if (target.existsSync()) target.deleteSync();
    return const Result<void>.success(null);
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
