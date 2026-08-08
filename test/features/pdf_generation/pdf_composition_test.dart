/// Tests the PDF composition rules.
///
/// No PDF is produced here. What is verified is everything that decides what
/// goes *into* a document — naming, quality, which text blocks are placeable —
/// which is testable without composing a file and reading it back. Composition
/// itself is covered in `pdf_composer_test.dart`.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:flutter_test/flutter_test.dart';

PageRef page(String id, {PageRotation rotation = PageRotation.none}) =>
    PageRef(id: PageId(id), imagePath: '/$id.jpg', rotation: rotation);

RecognisedText textFor(String pageId, List<TextBlock> blocks) => RecognisedText(
  pageId: PageId(pageId),
  blocks: blocks,
  languageTag: 'la',
  recognisedAt: DateTime.utc(2026, 3, 14),
);

const _validBlock = TextBlock(
  text: 'Invoice',
  bounds: NormalisedRect(left: 0.1, top: 0.1, right: 0.5, bottom: 0.16),
);

void main() {
  group('composed PDF result', () {
    test('compares every published property and has useful diagnostics', () {
      const result = ComposedPdf(
        filePath: '/result.pdf',
        sizeInBytes: 2048,
        pageCount: 2,
        hasTextLayer: true,
      );
      final same = ComposedPdf(
        filePath: result.filePath,
        sizeInBytes: result.sizeInBytes,
        pageCount: result.pageCount,
        hasTextLayer: result.hasTextLayer,
      );

      expect(result, same);
      expect(result, same);
      expect(result.hashCode, same.hashCode);
      expect(
        result.toString(),
        'ComposedPdf(/result.pdf, 2048 bytes, 2 pages)',
      );
      expect(
        result,
        isNot(
          const ComposedPdf(
            filePath: '/other.pdf',
            sizeInBytes: 2048,
            pageCount: 2,
            hasTextLayer: true,
          ),
        ),
      );
      expect(
        result,
        isNot(
          const ComposedPdf(
            filePath: '/result.pdf',
            sizeInBytes: 1024,
            pageCount: 2,
            hasTextLayer: true,
          ),
        ),
      );
      expect(
        result,
        isNot(
          const ComposedPdf(
            filePath: '/result.pdf',
            sizeInBytes: 2048,
            pageCount: 1,
            hasTextLayer: true,
          ),
        ),
      );
      expect(
        result,
        isNot(
          const ComposedPdf(
            filePath: '/result.pdf',
            sizeInBytes: 2048,
            pageCount: 2,
          ),
        ),
      );
    });
  });

  group('quality', () {
    test('lower quality means fewer pixels and harsher compression', () {
      // The property the spec asserts: the lowest setting must produce a
      // smaller file than the highest. Both levers move the same way.
      expect(
        PdfQuality.low.imageQuality,
        lessThan(PdfQuality.high.imageQuality),
      );
      expect(
        PdfQuality.low.maxDimension,
        lessThan(PdfQuality.high.maxDimension),
      );
    });

    test('even the highest quality bounds the page size', () {
      // A modern camera produces more pixels than any printer resolves from a
      // sheet of paper, and carrying them makes a fifty-page scan unshareable.
      expect(PdfQuality.high.maxDimension, lessThan(6000));
    });

    test('the default sits between the extremes', () {
      expect(PdfQuality.defaultQuality, PdfQuality.balanced);
      expect(
        PdfQuality.balanced.imageQuality,
        inExclusiveRange(
          PdfQuality.low.imageQuality,
          PdfQuality.high.imageQuality,
        ),
      );
    });

    test('an unknown stored value falls back rather than throwing', () {
      expect(PdfQuality.fromName('turbo'), PdfQuality.defaultQuality);
      expect(PdfQuality.fromName(null), PdfQuality.defaultQuality);
    });

    test('a known stored value round-trips', () {
      for (final quality in PdfQuality.values) {
        expect(PdfQuality.fromName(quality.name), quality);
      }
    });
  });

  group('naming patterns', () {
    final now = DateTime(2026, 3, 14, 9, 30);

    test('date and time expands to a sortable name', () {
      expect(
        DocumentNaming.expand(NamingPattern.dateAndTime, now: now),
        'Scan 2026-03-14 09.30',
      );
    });

    test('uses dots rather than a colon in the time', () {
      // A colon is illegal in a file name on several platforms and confusing in
      // a share sheet.
      expect(
        DocumentNaming.expand(NamingPattern.dateAndTime, now: now),
        isNot(contains(':')),
      );
    });

    test('date only omits the time', () {
      expect(
        DocumentNaming.expand(NamingPattern.dateOnly, now: now),
        'Scan 2026-03-14',
      );
    });

    test('sequential counts on from what is stored', () {
      expect(
        DocumentNaming.expand(
          NamingPattern.sequential,
          now: now,
          existingCount: 7,
        ),
        'Scan 8',
      );
    });

    test('sequential starts at one for an empty library', () {
      expect(
        DocumentNaming.expand(NamingPattern.sequential, now: now),
        'Scan 1',
      );
    });

    test('plain is the same every time', () {
      expect(
        DocumentNaming.expand(NamingPattern.plain, now: now),
        DocumentNaming.fallback,
      );
    });

    test('single-digit months and days are padded so names sort', () {
      expect(
        DocumentNaming.expand(
          NamingPattern.dateOnly,
          now: DateTime(2026, 1, 5),
        ),
        'Scan 2026-01-05',
      );
    });

    test('the same inputs always give the same name', () {
      // A pure function of its arguments, which is what makes every golden and
      // every naming test stable.
      expect(
        DocumentNaming.expand(NamingPattern.dateAndTime, now: now),
        DocumentNaming.expand(NamingPattern.dateAndTime, now: now),
      );
    });

    test('an unknown stored pattern falls back', () {
      expect(NamingPattern.fromId('nonsense'), NamingPattern.defaultPattern);
      expect(NamingPattern.fromId(null), NamingPattern.defaultPattern);
    });

    test('every pattern has a stable identifier distinct from the others', () {
      // The id is separate from the enum constant name so renaming the constant
      // does not silently invalidate every user's stored preference.
      final ids = NamingPattern.values.map((pattern) => pattern.id).toSet();

      expect(ids, hasLength(NamingPattern.values.length));
    });
  });

  group('resolving the title', () {
    test('what the user typed wins', () {
      expect(DocumentNaming.resolve('Receipts', 'Scan 2026-03-14'), 'Receipts');
    });

    test('surrounding whitespace is trimmed', () {
      expect(DocumentNaming.resolve('  Receipts  ', 'Scan 1'), 'Receipts');
    });

    test('a blank field means the default, not a nameless document', () {
      // An untitled document is unfindable, and the library forbids an empty
      // title outright.
      expect(DocumentNaming.resolve('', 'Scan 1'), 'Scan 1');
      expect(DocumentNaming.resolve('   ', 'Scan 1'), 'Scan 1');
      expect(DocumentNaming.resolve(null, 'Scan 1'), 'Scan 1');
    });

    test('a blank field and a blank default still give a usable name', () {
      expect(DocumentNaming.resolve('', ''), DocumentNaming.fallback);
    });
  });

  group('file names', () {
    test('are derived from the title so a shared file is recognisable', () {
      expect(DocumentNaming.fileNameFor('Invoice 2026'), 'Invoice 2026.pdf');
    });

    test('replace characters a filesystem would reject', () {
      expect(
        DocumentNaming.fileNameFor('Invoice: Acme/Ltd'),
        'Invoice_ Acme_Ltd.pdf',
      );
    });

    test('do not collapse two different titles onto one name', () {
      expect(
        DocumentNaming.fileNameFor('Report-A'),
        isNot(DocumentNaming.fileNameFor('Report B')),
      );
    });

    test('fall back for a title of only punctuation', () {
      expect(DocumentNaming.fileNameFor('***'), 'Document.pdf');
    });
  });

  group('building page specifications', () {
    test('preserves page order', () {
      final specs = PdfComposition.specsFor([
        page('a'),
        page('b'),
        page('c'),
      ], const {});

      expect(specs.map((spec) => spec.imagePath), [
        '/a.jpg',
        '/b.jpg',
        '/c.jpg',
      ]);
    });

    test('preserves rotation', () {
      final specs = PdfComposition.specsFor([
        page('a', rotation: PageRotation.quarter),
      ], const {});

      expect(specs.single.rotation, PageRotation.quarter);
    });

    test('attaches recognised text as a layer', () {
      final specs = PdfComposition.specsFor(
        [page('a')],
        {
          'a': textFor('a', const [_validBlock]),
        },
      );

      expect(specs.single.hasTextLayer, isTrue);
      expect(specs.single.textBlocks.single.text, 'Invoice');
    });

    test('a page with no recognised text simply gets no layer', () {
      // Recognition failure must never prevent a document being created: a PDF
      // without a searchable layer is still a valid document.
      final specs = PdfComposition.specsFor([page('a')], const {});

      expect(specs.single.hasTextLayer, isFalse);
    });

    test('drops a block whose box has no area', () {
      // A text-layer entry with no position lands somewhere arbitrary, and
      // selecting text in a reader then highlights the wrong part of the page.
      final specs = PdfComposition.specsFor(
        [page('a')],
        {
          'a': textFor('a', const [
            TextBlock(
              text: 'nowhere',
              bounds: NormalisedRect(
                left: 0.5,
                top: 0.5,
                right: 0.5,
                bottom: 0.5,
              ),
            ),
          ]),
        },
      );

      expect(specs.single.hasTextLayer, isFalse);
    });

    test('drops a block whose box escapes the page', () {
      final specs = PdfComposition.specsFor(
        [page('a')],
        {
          'a': textFor('a', const [
            TextBlock(
              text: 'off the page',
              bounds: NormalisedRect(
                left: 0.5,
                top: 0.5,
                right: 1.5,
                bottom: 0.6,
              ),
            ),
          ]),
        },
      );

      expect(specs.single.hasTextLayer, isFalse);
    });

    test('drops a block whose text is only whitespace', () {
      final specs = PdfComposition.specsFor(
        [page('a')],
        {
          'a': textFor('a', const [
            TextBlock(
              text: '  ',
              bounds: NormalisedRect(
                left: 0.1,
                top: 0.1,
                right: 0.9,
                bottom: 0.2,
              ),
            ),
          ]),
        },
      );

      expect(specs.single.hasTextLayer, isFalse);
    });

    test('keeps the valid blocks of a partly-unplaceable result', () {
      final specs = PdfComposition.specsFor(
        [page('a')],
        {
          'a': textFor('a', const [
            _validBlock,
            TextBlock(
              text: 'nowhere',
              bounds: NormalisedRect(left: 0, top: 0, right: 0, bottom: 0),
            ),
          ]),
        },
      );

      expect(specs.single.textBlocks, hasLength(1));
    });

    test('text is matched to the right page', () {
      final specs = PdfComposition.specsFor(
        [page('a'), page('b')],
        {
          'b': textFor('b', const [_validBlock]),
        },
      );

      expect(specs[0].hasTextLayer, isFalse);
      expect(specs[1].hasTextLayer, isTrue);
    });
  });

  group('the build request', () {
    test('reports itself searchable when any page has a layer', () {
      final request = PdfBuildRequest(
        pages: PdfComposition.specsFor(
          [page('a'), page('b')],
          {
            'b': textFor('b', const [_validBlock]),
          },
        ),
        destinationPath: '/out.pdf',
      );

      expect(request.isSearchable, isTrue);
    });

    test('reports itself unsearchable when no page has one', () {
      final request = PdfBuildRequest(
        pages: PdfComposition.specsFor([page('a')], const {}),
        destinationPath: '/out.pdf',
      );

      expect(request.isSearchable, isFalse);
    });

    test('defaults to the balanced quality', () {
      const request = PdfBuildRequest(pages: [], destinationPath: '/out.pdf');

      expect(request.quality, PdfQuality.defaultQuality);
    });
  });
}
