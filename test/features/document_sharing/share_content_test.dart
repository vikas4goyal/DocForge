/// Tests for the sharing domain rules.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/features/document_sharing/domain/share_content.dart';
import 'package:flutter_test/flutter_test.dart';

Document doc({String title = 'Invoice', bool hasRecognisedText = false}) =>
    Document(
      id: const DocumentId('a'),
      title: title,
      createdAt: DateTime.utc(2026, 3, 14),
      updatedAt: DateTime.utc(2026, 3, 14),
      pageCount: 3,
      sizeInBytes: 2048,
      libraryPath: LibraryPath.parse('a.pdf'),
      hasRecognisedText: hasRecognisedText,
    );

DocumentPage page(int order) => DocumentPage(
  id: PageId('p$order'),
  documentId: const DocumentId('a'),
  order: order,
  imagePath: '/pages/$order.jpg',
);

void main() {
  group('SharePayload', () {
    test('is empty when it carries neither files nor text', () {
      expect(const SharePayload().isEmpty, isTrue);
      expect(const SharePayload(text: '   ').isEmpty, isTrue);
    });

    test('is not empty when it carries either', () {
      expect(const SharePayload(filePaths: ['/a.pdf']).isEmpty, isFalse);
      expect(const SharePayload(text: 'hello').isEmpty, isFalse);
    });
  });

  group('canShareText', () {
    test('is false when the document has no recognised text', () {
      expect(ShareRules.canShareText(doc(), 'anything'), isFalse);
    });

    test('is false when the recognised text is blank', () {
      // The record can say text exists while the pages recognised nothing
      // legible; the control must still be disabled.
      expect(
        ShareRules.canShareText(doc(hasRecognisedText: true), '   \n  '),
        isFalse,
      );
    });

    test('is true when there is text to share', () {
      expect(
        ShareRules.canShareText(doc(hasRecognisedText: true), 'Acme'),
        isTrue,
      );
    });
  });

  group('inPageOrder', () {
    test('sorts a tap-ordered selection into page order', () {
      final ordered = ShareRules.inPageOrder([page(2), page(0), page(1)]);

      expect(ordered.map((p) => p.order), [0, 1, 2]);
    });

    test('leaves the source list untouched', () {
      final source = [page(2), page(0)];

      ShareRules.inPageOrder(source);

      expect(source.map((p) => p.order), [2, 0]);
    });
  });

  group('sanitise', () {
    test('removes characters no file name may contain', () {
      expect(ShareRules.sanitise('a/b:c*d?e"f<g>h|i'), 'a b c d e f g h i');
    });

    test('collapses the whitespace left behind', () {
      expect(ShareRules.sanitise('a///b'), 'a b');
    });

    test('falls back when nothing usable remains', () {
      expect(ShareRules.sanitise('///'), 'Document');
      expect(ShareRules.sanitise('   '), 'Document');
    });
  });

  group('file names', () {
    test('a PDF takes the title', () {
      expect(ShareRules.pdfFileName('Invoice 2026'), 'Invoice 2026.pdf');
    });

    test('page images are zero-padded so they sort in page order', () {
      // Several mail clients order attachments alphabetically; without padding
      // page 10 would arrive before page 2.
      final names = [
        for (final n in [2, 10]) ShareRules.imageFileName('Scan', n),
      ];

      expect(names, ['Scan_002.jpg', 'Scan_010.jpg']);
      expect(names.first.compareTo(names.last), lessThan(0));
    });

    test('text takes the title with a text extension', () {
      expect(ShareRules.textFileName('Invoice'), 'Invoice.txt');
    });
  });

  group('optionSemanticsLabel', () {
    test('names both the content and the format for a PDF', () {
      final label = ShareRules.optionSemanticsLabel(
        ShareAction.share,
        ShareFormat.pdf,
        title: 'Invoice',
      );

      expect(label, 'Share the document "Invoice" as a PDF');
    });

    test('counts the pages for an image share', () {
      expect(
        ShareRules.optionSemanticsLabel(
          ShareAction.share,
          ShareFormat.images,
          title: 'Invoice',
          pageCount: 3,
        ),
        'Share 3 pages of "Invoice" as images',
      );
    });

    test('uses the singular for one page', () {
      expect(
        ShareRules.optionSemanticsLabel(
          ShareAction.share,
          ShareFormat.images,
          title: 'Invoice',
          pageCount: 1,
        ),
        contains('one page'),
      );
    });

    test('names printing and exporting as their own actions', () {
      expect(
        ShareRules.optionSemanticsLabel(
          ShareAction.print,
          ShareFormat.pdf,
          title: 'Invoice',
        ),
        startsWith('Print '),
      );
      expect(
        ShareRules.optionSemanticsLabel(
          ShareAction.export,
          ShareFormat.pdf,
          title: 'Invoice',
        ),
        endsWith('to device storage'),
      );
    });

    test('names the text format', () {
      expect(
        ShareRules.optionSemanticsLabel(
          ShareAction.share,
          ShareFormat.text,
          title: 'Invoice',
        ),
        contains('recognised text'),
      );
    });
  });

  group('labels', () {
    test('the subject is the document title', () {
      expect(ShareRules.subjectFor(doc(title: 'Receipt')), 'Receipt');
    });

    test('a single item reports no page number', () {
      expect(ShareRules.preparingLabel(0, 1), 'Preparing…');
    });

    test('several items report which one', () {
      expect(ShareRules.preparingLabel(2, 5), 'Preparing page 2 of 5…');
    });

    test('the export confirmation names the destination', () {
      expect(
        ShareRules.exportConfirmation('/Downloads/a.pdf'),
        contains('/Downloads/a.pdf'),
      );
    });
  });

  group('formats', () {
    test('every format has a label used mid-sentence', () {
      expect(ShareFormat.values.map((f) => f.label), everyElement(isNotEmpty));
    });
  });
}
