import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/features/pdf_editing/domain/compression_candidate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('draft validates source identity, page count, and original bytes', () {
    final plan = PageQualityPlan(documentQuality: PdfQualityPercent(value: 80));

    expect(
      () => CompressionDraft(
        sourceDocumentId: '',
        pageCount: 1,
        originalBytes: 1,
        qualityPlan: plan,
      ),
      throwsArgumentError,
    );
    expect(
      () => CompressionDraft(
        sourceDocumentId: 'document-1',
        pageCount: 0,
        originalBytes: 1,
        qualityPlan: plan,
      ),
      throwsRangeError,
    );
    expect(
      () => CompressionDraft(
        sourceDocumentId: 'document-1',
        pageCount: 1,
        originalBytes: -1,
        qualityPlan: plan,
      ),
      throwsRangeError,
    );
  });

  test('initial draft is 80 percent and has no destination', () {
    final draft = CompressionDraft.initial(
      sourceDocumentId: 'document-1',
      pageCount: 3,
      originalBytes: 4096,
    );

    expect(draft.qualityPlan.documentQuality.value, 80);
    expect(draft.effectiveQualities, <int>[80, 80, 80]);
    expect(draft.destination, isNull);
    expect(draft.isAllPagesPassThrough, isFalse);
  });

  test('page overrides take precedence and reset independently', () {
    final initial = CompressionDraft.initial(
      sourceDocumentId: 'document-1',
      pageCount: 3,
      originalBytes: 4096,
    );
    final mixed = initial.copyWith(
      qualityPlan: initial.qualityPlan
          .withOverride('0', PdfQualityPercent(value: 100))
          .withOverride('2', PdfQualityPercent(value: 30)),
    );

    expect(mixed.effectiveQualities, <int>[100, 80, 30]);
    expect(mixed.isAllPagesPassThrough, isFalse);
    expect(
      mixed
          .copyWith(qualityPlan: mixed.qualityPlan.resetOverrides())
          .effectiveQualities,
      <int>[80, 80, 80],
    );
  });

  test('all-pages-100 warning requires every effective page at 100', () {
    final initial = CompressionDraft.initial(
      sourceDocumentId: 'document-1',
      pageCount: 2,
      originalBytes: 4096,
    );
    final allFull = initial.copyWith(
      qualityPlan: PageQualityPlan(
        documentQuality: PdfQualityPercent(value: 100),
      ),
    );
    final mixed = allFull.copyWith(
      qualityPlan: allFull.qualityPlan.withOverride(
        '1',
        PdfQualityPercent(value: 80),
      ),
    );

    expect(allFull.isAllPagesPassThrough, isTrue);
    expect(mixed.isAllPagesPassThrough, isFalse);
  });

  test('exact result calculates bounded saving and no-benefit states', () {
    final smaller = CompressionCommitResult(
      documentId: 'copy-1',
      destination: CompressionDestination.copy,
      originalBytes: 1000,
      resultBytes: 650,
    );
    final larger = CompressionCommitResult(
      documentId: 'document-1',
      destination: CompressionDestination.overwrite,
      originalBytes: 1000,
      resultBytes: 1100,
    );

    expect(smaller.savedBytes, 350);
    expect(smaller.savedPercent, 35);
    expect(smaller.hasNoBenefit, isFalse);
    expect(larger.savedBytes, 0);
    expect(larger.savedPercent, 0);
    expect(larger.hasNoBenefit, isTrue);
  });

  test(
    'draft and result have value equality and generated JSON round trips',
    () {
      final draft = CompressionDraft.initial(
        sourceDocumentId: 'document-1',
        pageCount: 2,
        originalBytes: 4096,
      ).copyWith(destination: CompressionDestination.copy);
      final result = CompressionCommitResult(
        documentId: 'copy-1',
        destination: CompressionDestination.copy,
        originalBytes: 4096,
        resultBytes: 2048,
      );

      expect(CompressionDraft.fromJson(draft.toJson()), draft);
      expect(CompressionCommitResult.fromJson(result.toJson()), result);
      expect(result, result.copyWith());
    },
  );
}
