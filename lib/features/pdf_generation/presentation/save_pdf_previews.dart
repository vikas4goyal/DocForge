/// Deterministic widget previews for the dedicated Save PDF workflow.
library;

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
import 'package:doc_scanly/core/previews/preview_scaffold.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_generation/application/usecases/save_pdf_workflow.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/cubit/save_pdf_cubit.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/cubit/save_pdf_state.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/screens/save_pdf_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

final _pages = <PageRef>[
  for (var index = 0; index < 5; index++)
    PageRef(id: PageId('preview-$index'), imagePath: '/preview-$index.jpg'),
];

SavePdfState _state({
  int quality = 70,
  String name = 'Quarterly receipts',
  AsyncJobView calculation = const AsyncJobView.succeeded(
    generation: 1,
    summary: JobResultSummary(exactBytes: 2457600, pageCount: 5),
  ),
  Map<String, PdfQualityPercent> overrides = const {},
  bool passwordEnabled = false,
}) => SavePdfState(
  pages: _pages,
  name: name,
  qualityPlan: PageQualityPlan(
    documentQuality: PdfQualityPercent(value: quality),
    pageOverrides: overrides,
  ),
  passwordEnabled: passwordEnabled,
  calculation: calculation,
  calculatedBytes: calculation is AsyncJobSucceeded ? 2457600 : null,
);

Widget _save(SavePdfState state) =>
    SavePdfScreen(cubit: _cubit(state), onOpenPreview: (_) {}, onSaved: (_) {});

/// Default 70% phone state with exact bytes.
@Preview(
  name: 'Save PDF — default',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget savePdfDefault() => _save(_state());

/// Lowest document quality.
@Preview(
  name: 'Save PDF — 30%',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget savePdfLow() => _save(_state(quality: 30));

/// Full document quality.
@Preview(
  name: 'Save PDF — 100%',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget savePdfFull() => _save(_state(quality: 100));

/// Debounced size calculation in progress.
@Preview(
  name: 'Save PDF — calculating',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget savePdfCalculating() => _save(
  _state(
    calculation: AsyncJobView.running(
      generation: 2,
      progress: JobProgress(percent: 45),
    ),
  ),
);

/// Non-blocking calculation failure with Retry.
@Preview(
  name: 'Save PDF — error',
  group: 'PDF generation',
  theme: appPreviewTheme,
  textScaleFactor: 2,
)
Widget savePdfError() => _save(
  _state(
    calculation: const AsyncJobView.failed(
      generation: 2,
      failure: Failure.pdf(),
    ),
  ),
);

/// Mixed document and explicit page percentages.
@Preview(
  name: 'Save PDF — overrides',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget savePdfOverrides() => _save(
  _state(
    overrides: <String, PdfQualityPercent>{
      'preview-1': PdfQualityPercent(value: 40),
      'preview-3': PdfQualityPercent(value: 100),
    },
  ),
);

/// Non-secret protected status.
@Preview(
  name: 'Save PDF — protected',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget savePdfProtected() => _save(_state(passwordEnabled: true));

/// Long content and name stress state.
@Preview(
  name: 'Save PDF — long content',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget savePdfLongContent() => _save(
  SavePdfState(
    pages: <PageRef>[
      for (var index = 0; index < 35; index++)
        PageRef(id: PageId('long-$index'), imagePath: '/long-$index.jpg'),
    ],
    name: 'A very long multilingual quarterly document title 2026',
    qualityPlan: PageQualityPlan(documentQuality: PdfQualityPercent(value: 70)),
    calculation: const AsyncJobView.queued(generation: 1),
  ),
);

/// Defensive empty creation state.
@Preview(
  name: 'Save PDF — empty',
  group: 'PDF generation',
  theme: appPreviewTheme,
  size: PreviewSize.phone,
)
Widget savePdfEmpty() => _save(
  SavePdfState(
    pages: const <PageRef>[],
    name: '',
    qualityPlan: PageQualityPlan(documentQuality: PdfQualityPercent(value: 70)),
  ),
);

/// Override state on a dark tablet.
@Preview(
  name: 'Save PDF — overrides tablet dark',
  group: 'PDF generation',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
)
Widget savePdfOverridesTabletDark() => savePdfOverrides();

/// Page-quality override dialog.
@Preview(
  name: 'Save PDF — page dialog',
  group: 'PDF generation dialogs',
  theme: appPreviewTheme,
)
Widget savePdfPageDialog() =>
    const SavePdfDialogPreview(kind: SavePdfDialogPreviewKind.pageQuality);

/// Route-scoped password dialog.
@Preview(
  name: 'Save PDF — password dialog',
  group: 'PDF generation dialogs',
  theme: appPreviewTheme,
)
Widget savePdfPasswordDialog() =>
    const SavePdfDialogPreview(kind: SavePdfDialogPreviewKind.password);

/// Determinate cancellable commit dialog.
@Preview(
  name: 'Save PDF — progress dialog',
  group: 'PDF generation dialogs',
  theme: appPreviewTheme,
)
Widget savePdfProgressDialog() =>
    const SavePdfDialogPreview(kind: SavePdfDialogPreviewKind.progress);

/// Read-only candidate preview surface.
@Preview(
  name: 'Temporary PDF preview',
  group: 'PDF generation',
  theme: appPreviewTheme,
)
Widget temporaryPdfPreview() => PdfTemporaryPreviewScreen(
  candidateHandle: 'candidate-preview',
  surfaceBuilder: (_, _) =>
      const Center(child: Icon(Icons.picture_as_pdf_outlined, size: 96)),
  onClose: () {},
);

SavePdfCubit _cubit(SavePdfState state) {
  final repository = _InertRepository();
  final cache = SavePdfCandidateCache();
  return SavePdfCubit.forPreview(
    state: state,
    calculate: CalculateSavePdfSize(repository, cache),
    preparePreview: PrepareSavePdfPreview(repository, cache),
    save: SaveGeneratedPdf(
      repository: repository,
      cache: cache,
      documents: const _InertWriter(),
      rollbackDocument: (_) async => const Result<void>.success(null),
      store: InMemoryPublicFileStore(),
      secrets: InMemorySecureStore(),
      clock: FixedClock(DateTime.utc(2026, 8, 8)),
      ids: SequentialIdGenerator(prefix: 'preview'),
      workingDirectory: Directory.systemTemp,
      completeSession: () async {},
    ),
    requestFactory: ({required name, required qualityPlan, password}) =>
        throw UnsupportedError('preview actions are inert'),
  );
}

class _InertRepository implements GeneratedPdfCandidateRepository {
  @override
  Future<Result<PdfCandidate>> buildCandidate(
    GeneratedPdfCandidateRequest request, {
    required CancellationToken token,
    required PdfCandidateProgress onProgress,
  }) async => const Result<PdfCandidate>.failure(Failure.cancelled());

  @override
  Future<void> discard(PdfCandidate candidate) async {}

  @override
  Future<Result<ComposedPdf>> promote(
    PdfCandidate candidate, {
    required String destinationPath,
    required CancellationToken token,
  }) async => const Result<ComposedPdf>.failure(Failure.cancelled());

  @override
  Future<Result<PdfCandidate>> verifyCandidate(
    PdfCandidate candidate, {
    String? password,
  }) async => const Result<PdfCandidate>.failure(Failure.cancelled());
}

class _InertWriter implements DocumentWriter {
  const _InertWriter();

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async => Result<Document>.success(document);

  @override
  Future<Result<Document>> updateMetadata(Document document) async =>
      Result<Document>.success(document);
}
