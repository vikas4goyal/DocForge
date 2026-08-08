import 'dart:io';

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
import 'package:doc_scanly/features/pdf_generation/presentation/pdf_keys.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/screens/save_pdf_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late _Harness harness;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('save_pdf_component');
    harness = _Harness(directory);
  });

  tearDown(() async {
    await harness.cubit.close();
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SavePdfScreen(
          cubit: harness.cubit,
          onOpenPreview: harness.previews.add,
          onSaved: harness.saved.add,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('default configuration calculates exact size', (tester) async {
    await pump(tester);
    await harness.cubit.load();
    await tester.pumpAndSettle();

    expect(find.byKey(PdfKeys.saveScreen), findsOneWidget);
    expect(find.byKey(PdfKeys.saveNameField), findsOneWidget);
    expect(find.text('PDF quality · 70%'), findsOneWidget);
    expect(find.text('Calculated size: 2.0 KB'), findsOneWidget);
    expect(find.byKey(PdfKeys.savePageQuality('page-0')), findsOneWidget);
  });

  testWidgets('name, document quality, page override, and reset update state', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byKey(PdfKeys.saveNameField), 'Statement');
    harness.cubit.documentQualityChanged(80);
    await tester.pump();

    await tester.tap(find.byKey(PdfKeys.savePageQuality('page-0')));
    await tester.pumpAndSettle();
    final slider = tester.widget<Slider>(find.byKey(PdfKeys.pageQualitySlider));
    slider.onChanged!(40);
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(harness.cubit.state.name, 'Statement');
    expect(harness.cubit.state.qualityPlan.documentQuality.value, 80);
    expect(harness.cubit.state.qualityPlan.effectiveFor('page-0').value, 40);
    expect(find.byKey(PdfKeys.pageQualityResetAll), findsOneWidget);

    await tester.tap(find.byKey(PdfKeys.pageQualityResetAll));
    await tester.pumpAndSettle();
    expect(harness.cubit.state.hasPageOverrides, isFalse);
  });

  testWidgets('password dialog validates, enables status, and removes secret', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(PdfKeys.saveSetPassword));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(PdfKeys.savePasswordField), 'alpha');
    await tester.enterText(
      find.byKey(PdfKeys.savePasswordConfirmField),
      'different',
    );
    await tester.tap(find.byKey(PdfKeys.savePasswordDialogConfirm));
    await tester.pump();
    expect(find.text('The passwords do not match.'), findsOneWidget);

    await tester.enterText(
      find.byKey(PdfKeys.savePasswordConfirmField),
      'alpha',
    );
    await tester.tap(find.byKey(PdfKeys.savePasswordDialogConfirm));
    await tester.pumpAndSettle();
    expect(find.byKey(PdfKeys.savePasswordEnabled), findsOneWidget);
    expect(find.text('alpha'), findsNothing);

    await tester.tap(find.byKey(PdfKeys.saveRemovePassword));
    await tester.pumpAndSettle();
    expect(harness.cubit.state.passwordEnabled, isFalse);
  });

  testWidgets('Preview opens only after successful candidate preparation', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(PdfKeys.savePreviewButton));
    await tester.pumpAndSettle();

    expect(harness.previews, hasLength(1));
    expect(find.byKey(PdfKeys.jobProgressDialog), findsNothing);
    expect(harness.cubit.state.document, isNull);
  });

  testWidgets('cancelling modal Preview keeps configuration on Save', (
    tester,
  ) async {
    harness.repository.hold = true;
    await pump(tester);

    await tester.tap(find.byKey(PdfKeys.savePreviewButton));
    await tester.pump();
    expect(find.byKey(PdfKeys.jobProgressDialog), findsOneWidget);
    await tester.tap(find.byKey(PdfKeys.jobCancelButton));
    await tester.pumpAndSettle();

    expect(harness.previews, isEmpty);
    expect(find.byKey(PdfKeys.saveScreen), findsOneWidget);
    expect(harness.cubit.state.name, 'Invoice');
  });

  testWidgets(
    'calculation failure offers Retry without blocking Preview or Save',
    (tester) async {
      harness.repository.failure = const Failure.pdf(debugDetail: 'offline');
      await pump(tester);
      await harness.cubit.load();
      await tester.pumpAndSettle();

      expect(find.byKey(PdfKeys.outputSizeRetry), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(PdfKeys.savePreviewButton))
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(PdfKeys.saveConfirmButton))
            .onPressed,
        isNotNull,
      );

      harness.repository.failure = null;
      await tester.tap(find.byKey(PdfKeys.outputSizeRetry));
      await tester.pumpAndSettle();
      expect(find.text('Calculated size: 2.0 KB'), findsOneWidget);
    },
  );

  testWidgets('Save without Preview commits once and reports completion', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(PdfKeys.saveConfirmButton));
    await tester.runAsync(() async {
      for (
        var attempt = 0;
        attempt < 20 && harness.cubit.state.document == null;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();

    expect(harness.writer.saved, hasLength(1));
    expect(harness.cubit.state.commit, isA<AsyncJobSucceeded>());
    expect(harness.cubit.state.document, isNotNull);
    expect(harness.saved, hasLength(1));
    expect(harness.previews, isEmpty);
  });

  testWidgets('temporary preview is read-only and closes explicitly', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PdfTemporaryPreviewScreen(
          candidateHandle: 'candidate-1',
          surfaceBuilder: (_, handle) => Text('render:$handle'),
          onClose: () => closed = true,
        ),
      ),
    );

    expect(find.byKey(PdfKeys.temporaryPreviewScreen), findsOneWidget);
    expect(find.text('render:candidate-1'), findsOneWidget);
    await tester.tap(find.byKey(PdfKeys.temporaryPreviewClose));
    expect(closed, isTrue);
  });
}

class _Harness {
  _Harness(this.directory)
    : repository = _Repository(directory),
      writer = _Writer() {
    final cache = SavePdfCandidateCache();
    cubit = SavePdfCubit(
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

  final Directory directory;
  final _Repository repository;
  final _Writer writer;
  late final SavePdfCubit cubit;
  final List<String> previews = <String>[];
  final List<Document> saved = <Document>[];
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
    sourceIdentity: 'session',
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
  int builds = 0;
  bool hold = false;
  Failure? failure;

  @override
  Future<Result<PdfCandidate>> buildCandidate(
    GeneratedPdfCandidateRequest request, {
    required CancellationToken token,
    required PdfCandidateProgress onProgress,
  }) async {
    builds++;
    if (hold) {
      await token.onCancel.first;
    }
    if (token.isCancelled) {
      return const Result<PdfCandidate>.failure(Failure.cancelled());
    }
    final configured = failure;
    if (configured != null) {
      return Result<PdfCandidate>.failure(configured);
    }
    onProgress(JobProgress(percent: 50));
    final path = '${directory.path}/candidate-$builds.pdf';
    File(path).writeAsBytesSync(List<int>.filled(2048, builds));
    return Result<PdfCandidate>.success(
      PdfCandidate(
        handle: path,
        exactBytes: 2048,
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
