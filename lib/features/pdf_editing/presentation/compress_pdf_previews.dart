/// Deterministic previews for the dedicated Compress PDF workflow and dialogs.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
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
import 'package:doc_scanly/features/pdf_editing/application/usecases/compression_workflow.dart';
import 'package:doc_scanly/features/pdf_editing/domain/compression_candidate.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/compress_pdf_cubit.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/compress_pdf_state.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/screens/compress_pdf_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

CompressPdfState _state({
  int quality = 80,
  int pageCount = 5,
  String title = 'Quarterly receipts',
  int originalBytes = 4194304,
  int resultBytes = 2457600,
  AsyncJobView? calculation,
  Map<String, PdfQualityPercent> overrides = const {},
  AsyncJobView commit = const AsyncJobView.idle(),
}) => CompressPdfState(
  title: title,
  pageCount: pageCount,
  originalBytes: originalBytes,
  qualityPlan: PageQualityPlan(
    documentQuality: PdfQualityPercent(value: quality),
    pageOverrides: overrides,
  ),
  calculation:
      calculation ??
      AsyncJobView.succeeded(
        generation: 1,
        summary: JobResultSummary(
          exactBytes: resultBytes,
          pageCount: pageCount,
        ),
      ),
  calculatedBytes: calculation == null || calculation is AsyncJobSucceeded
      ? resultBytes
      : null,
  commit: commit,
);

Widget _screen(CompressPdfState state) => CompressPdfScreen(
  cubit: _cubit(state),
  onOpenPreview: (_) {},
  onCompleted: (_) {},
);

/// Default 80% phone state with exact savings.
@Preview(
  name: 'Compress PDF — 80%',
  group: 'PDF editing',
  theme: appPreviewTheme,
  size: PreviewSize.phone,
)
Widget compressPdfDefault() => _screen(_state());

/// Lowest 30% document quality.
@Preview(
  name: 'Compress PDF — 30%',
  group: 'PDF editing',
  theme: appPreviewTheme,
  size: PreviewSize.phone,
)
Widget compressPdfLow() => _screen(_state(quality: 30, resultBytes: 1048576));

/// All-pages pass-through 100% state.
@Preview(
  name: 'Compress PDF — 100%',
  group: 'PDF editing',
  theme: appPreviewTheme,
  size: PreviewSize.phone,
)
Widget compressPdfFull() => _screen(_state(quality: 100, resultBytes: 4194304));

/// Mixed 30/80/100 page overrides on a dark tablet.
@Preview(
  name: 'Compress PDF — mixed overrides',
  group: 'PDF editing',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
)
Widget compressPdfMixed() => _screen(
  _state(
    overrides: <String, PdfQualityPercent>{
      '1': PdfQualityPercent(value: 30),
      '3': PdfQualityPercent(value: 100),
    },
  ),
);

/// Exact calculation progress.
@Preview(
  name: 'Compress PDF — calculating',
  group: 'PDF editing',
  theme: appPreviewTheme,
  size: PreviewSize.phone,
)
Widget compressPdfCalculating() => _screen(
  _state(
    calculation: AsyncJobView.running(
      generation: 2,
      progress: JobProgress(percent: 47),
    ),
  ),
);

/// Non-blocking exact-size failure with Retry.
@Preview(
  name: 'Compress PDF — error',
  group: 'PDF editing',
  theme: appPreviewTheme,
  size: PreviewSize.phone,
  textScaleFactor: 2,
)
Widget compressPdfError() => _screen(
  _state(
    calculation: const AsyncJobView.failed(
      generation: 2,
      failure: Failure.pdf(),
    ),
  ),
);

/// Empty defensive route state.
@Preview(
  name: 'Compress PDF — empty',
  group: 'PDF editing',
  theme: appPreviewTheme,
  size: PreviewSize.phone,
)
Widget compressPdfEmpty() => _screen(_state(pageCount: 0, resultBytes: 0));

/// Long title and long page list stress state.
@Preview(
  name: 'Compress PDF — long content',
  group: 'PDF editing',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
)
Widget compressPdfLongContent() => _screen(
  _state(
    pageCount: 35,
    title: 'A very long multilingual quarterly archive document title 2026',
  ),
);

/// Page-quality override dialog.
@Preview(
  name: 'Compress — page dialog',
  group: 'PDF editing dialogs',
  theme: appPreviewTheme,
)
Widget compressPageDialog() => const CompressionDialogPreview(
  kind: CompressionDialogPreviewKind.pageQuality,
);

/// All-pages-100 warning.
@Preview(
  name: 'Compress — 100% warning',
  group: 'PDF editing dialogs',
  theme: appPreviewTheme,
)
Widget compressPassThroughDialog() => const CompressionDialogPreview(
  kind: CompressionDialogPreviewKind.passThrough,
);

/// Copy-or-overwrite choice.
@Preview(
  name: 'Compress — destination',
  group: 'PDF editing dialogs',
  theme: appPreviewTheme,
)
Widget compressDestinationDialog() => const CompressionDialogPreview(
  kind: CompressionDialogPreviewKind.destination,
);

/// Exact no-benefit review.
@Preview(
  name: 'Compress — no benefit',
  group: 'PDF editing dialogs',
  theme: appPreviewTheme,
)
Widget compressNoBenefitDialog() => const CompressionDialogPreview(
  kind: CompressionDialogPreviewKind.noBenefit,
);

/// Determinate cancellable commit progress.
@Preview(
  name: 'Compress — progress',
  group: 'PDF editing dialogs',
  theme: appPreviewTheme,
)
Widget compressProgressDialog() =>
    const CompressionDialogPreview(kind: CompressionDialogPreviewKind.progress);

CompressPdfCubit _cubit(CompressPdfState state) {
  final repository = _InertRepository();
  final cache = CompressionCandidateCache();
  return CompressPdfCubit.forPreview(
    state: state,
    calculate: CalculateCompressedSize(repository, cache),
    preparePreview: PrepareCompressionPreview(repository, cache),
    save: SaveCompressedPdf(
      repository: repository,
      cache: cache,
      documents: const _InertWriter(),
      rollbackCopy: (_) async => const Result<void>.success(null),
      restoreMetadata: (_) async => const Result<void>.success(null),
      store: InMemoryPublicFileStore(),
      secrets: InMemorySecureStore(),
      clock: FixedClock(DateTime.utc(2026, 8, 8)),
      ids: SequentialIdGenerator(prefix: 'preview'),
      workingDirectory: Directory.systemTemp,
    ),
    requestFactory: ({required qualityPlan, required destination}) =>
        throw UnsupportedError('preview actions are inert'),
  );
}

class _InertRepository implements CompressionCandidateRepository {
  @override
  Future<Result<PdfCandidate>> buildCandidate(
    CompressionCandidateRequest request, {
    required CancellationToken token,
    required CompressionCandidateProgress onProgress,
  }) async => const Result<PdfCandidate>.failure(Failure.cancelled());

  @override
  Future<void> discard(PdfCandidate candidate) async {}

  @override
  Future<Result<EditedPdf>> promote(
    PdfCandidate candidate, {
    required String destinationPath,
    required CancellationToken token,
  }) async => const Result<EditedPdf>.failure(Failure.cancelled());

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
