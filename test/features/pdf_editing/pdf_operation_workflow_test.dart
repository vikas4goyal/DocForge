import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_operation_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Freezed operation values', () {
    test('equivalent split drafts compare by value', () {
      const first = PdfOperationDraft.split(
        boundary: 2,
        firstTitle: 'Policy 1',
        secondTitle: 'Policy 2',
      );

      expect(
        first,
        const PdfOperationDraft.split(
          boundary: 2,
          firstTitle: 'Policy 1',
          secondTitle: 'Policy 2',
        ),
      );
    });

    test('merge order participates in value equality', () {
      const a = DocumentId('a');
      const b = DocumentId('b');
      const forward = PdfOperationDraft.merge(
        documentIds: [a, b],
        outputTitle: 'Combined',
      );
      const reverse = PdfOperationDraft.merge(
        documentIds: [b, a],
        outputTitle: 'Combined',
      );

      expect(forward, isNot(reverse));
    });

    test('password text cannot be stored in a protection draft', () {
      expect(
        const PdfOperationDraft.protection(remove: false).toString(),
        isNot(contains('password:')),
      );
    });
  });

  group('draft validation', () {
    test('split requires a valid boundary', () {
      const draft = PdfOperationDraft.split(
        boundary: 4,
        firstTitle: 'First',
        secondTitle: 'Second',
      );

      expect(
        PdfOperationValidation.messageFor(draft, pageCount: 4),
        contains('split point'),
      );
    });

    test('split requires two distinct nonblank output names', () {
      const blank = PdfOperationDraft.split(
        boundary: 2,
        firstTitle: '',
        secondTitle: 'Second',
      );
      const same = PdfOperationDraft.split(
        boundary: 2,
        firstTitle: 'Copy',
        secondTitle: 'Copy',
      );

      expect(
        PdfOperationValidation.messageFor(blank, pageCount: 4),
        contains('name'),
      );
      expect(
        PdfOperationValidation.messageFor(same, pageCount: 4),
        contains('different'),
      );
    });

    test('merge requires two distinct documents and an output name', () {
      const id = DocumentId('a');
      const one = PdfOperationDraft.merge(
        documentIds: [id],
        outputTitle: 'Combined',
      );
      const blank = PdfOperationDraft.merge(
        documentIds: [id, DocumentId('b')],
        outputTitle: ' ',
      );

      expect(
        PdfOperationValidation.messageFor(one, pageCount: 1),
        contains('two'),
      );
      expect(
        PdfOperationValidation.messageFor(blank, pageCount: 1),
        contains('name'),
      );
    });

    test('watermark and page-derived drafts validate their required input', () {
      const watermark = PdfOperationDraft.watermark(text: '  ');
      const pages = PdfOperationDraft.pages(
        operation: PdfEditOperation.extract,
        pageIndices: [],
        sourceEffect: PdfSourceEffect.preserve,
      );

      expect(
        PdfOperationValidation.messageFor(watermark, pageCount: 3),
        contains('watermark'),
      );
      expect(
        PdfOperationValidation.messageFor(pages, pageCount: 3),
        contains('page'),
      );
    });

    test('valid split and merge drafts pass validation', () {
      const split = PdfOperationDraft.split(
        boundary: 2,
        firstTitle: 'First',
        secondTitle: 'Second',
      );
      const merge = PdfOperationDraft.merge(
        documentIds: [DocumentId('a'), DocumentId('b')],
        outputTitle: 'Combined',
      );

      expect(PdfOperationValidation.messageFor(split, pageCount: 4), isNull);
      expect(PdfOperationValidation.messageFor(merge, pageCount: 4), isNull);
    });

    test('a selected page-derived draft passes validation', () {
      const draft = PdfOperationDraft.pages(
        operation: PdfEditOperation.extract,
        pageIndices: [1],
        sourceEffect: PdfSourceEffect.preserve,
      );

      expect(PdfOperationValidation.messageFor(draft, pageCount: 3), isNull);
    });

    test('compression needs no additional user input', () {
      expect(
        PdfOperationValidation.messageFor(
          const PdfOperationDraft.compress(),
          pageCount: 3,
        ),
        isNull,
      );
    });
  });
}
