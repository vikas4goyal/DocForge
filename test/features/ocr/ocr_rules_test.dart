/// Tests the OCR business rules.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';
import 'package:doc_scanly/features/ocr/domain/ocr_rules.dart';
import 'package:doc_scanly/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// A page reference.
PageRef page(String id) => PageRef(id: PageId(id), imagePath: '/$id.jpg');

/// A recognition result carrying [lines].
RecognisedText text(String id, List<String> lines) => RecognisedText(
  pageId: PageId(id),
  blocks: [
    for (var index = 0; index < lines.length; index++)
      TextBlock(
        text: lines[index],
        bounds: NormalisedRect(
          left: 0.1,
          top: 0.1 + index * 0.1,
          right: 0.9,
          bottom: 0.16 + index * 0.1,
        ),
      ),
  ],
  languageTag: 'la',
  recognisedAt: DateTime.utc(2026, 3, 14),
);

/// An empty result for [id].
RecognisedText empty(String id) => RecognisedText.empty(
  pageId: PageId(id),
  languageTag: 'la',
  recognisedAt: DateTime.utc(2026, 3, 14),
);

void main() {
  final pages = [page('a'), page('b'), page('c')];

  group('deciding what to recognise', () {
    test('every page when nothing has been recognised', () {
      expect(OcrRules.pagesNeedingRecognition(pages, const {}), pages);
    });

    test('only the pages without a stored result', () {
      // The rule behind "a page is recognised at most once". Recognition is
      // expensive in time and battery; re-running it on every open would make
      // opening a fifty-page document cost as much as creating it.
      final stored = {
        const PageId('a'): text('a', ['hello']),
      };

      expect(OcrRules.pagesNeedingRecognition(pages, stored), [
        page('b'),
        page('c'),
      ]);
    });

    test('a page that was read and found empty is not read again', () {
      // An empty result is a real answer, not a gap. Retrying it every open
      // would recognise a blank page forever.
      final stored = {const PageId('a'): empty('a')};

      expect(
        OcrRules.pagesNeedingRecognition(pages, stored),
        isNot(contains(page('a'))),
      );
    });

    test('nothing when every page is recognised', () {
      final stored = {
        for (final p in pages) p.id: text(p.id.value, ['x']),
      };

      expect(OcrRules.pagesNeedingRecognition(pages, stored), isEmpty);
    });

    test('every page again when the run is forced', () {
      // What the re-run control passes: the spec requires it to replace the
      // stored text rather than skip the page.
      final stored = {
        for (final p in pages) p.id: text(p.id.value, ['x']),
      };

      expect(
        OcrRules.pagesNeedingRecognition(pages, stored, force: true),
        pages,
      );
    });
  });

  group('completeness', () {
    test('is false while any page is unrecognised', () {
      expect(
        OcrRules.isFullyRecognised(pages, {
          const PageId('a'): text('a', ['x']),
        }),
        isFalse,
      );
    });

    test('is true once every page has a result, empty or not', () {
      final stored = {
        const PageId('a'): text('a', ['x']),
        const PageId('b'): empty('b'),
        const PageId('c'): text('c', ['y']),
      };

      expect(OcrRules.isFullyRecognised(pages, stored), isTrue);
    });

    test('is true for a document with no pages', () {
      expect(OcrRules.isFullyRecognised(const [], const {}), isTrue);
    });
  });

  group('combining text', () {
    test('joins pages in page order, not in recognition order', () {
      final stored = {
        const PageId('c'): text('c', ['third']),
        const PageId('a'): text('a', ['first']),
        const PageId('b'): text('b', ['second']),
      };

      expect(OcrRules.combinedText(pages, stored), 'first\n\nsecond\n\nthird');
    });

    test('separates pages by a blank line', () {
      final stored = {
        const PageId('a'): text('a', ['one', 'two']),
        const PageId('b'): text('b', ['three']),
      };

      // Lines within a page are separated by one newline, pages by two, so a
      // copied document reads as pages rather than as one run-on paragraph.
      expect(
        OcrRules.combinedText([page('a'), page('b')], stored),
        'one\ntwo\n\nthree',
      );
    });

    test('omits pages that found nothing rather than leaving a gap', () {
      final stored = {
        const PageId('a'): text('a', ['first']),
        const PageId('b'): empty('b'),
        const PageId('c'): text('c', ['third']),
      };

      expect(OcrRules.combinedText(pages, stored), 'first\n\nthird');
    });

    test('omits pages that have never been recognised', () {
      final stored = {
        const PageId('b'): text('b', ['only']),
      };

      expect(OcrRules.combinedText(pages, stored), 'only');
    });

    test('is empty when nothing has been recognised', () {
      expect(OcrRules.combinedText(pages, const {}), isEmpty);
    });
  });

  group('whether there is text at all', () {
    test('is false for an empty store', () {
      expect(OcrRules.hasText(const {}), isFalse);
    });

    test('is false when every result found nothing', () {
      // Drives whether copy and export are offered. A control that puts an
      // empty string on the clipboard is worse than one visibly unavailable.
      expect(OcrRules.hasText({const PageId('a'): empty('a')}), isFalse);
    });

    test('is true when any page produced text', () {
      expect(
        OcrRules.hasText({
          const PageId('a'): empty('a'),
          const PageId('b'): text('b', ['found']),
        }),
        isTrue,
      );
    });
  });

  group('blocks placeable in a PDF text layer', () {
    test('keeps blocks with a valid box', () {
      expect(OcrRules.placeableBlocks(text('a', ['one', 'two'])), hasLength(2));
    });

    test('drops a block with a zero-area box', () {
      // A text-layer entry with no position is worse than a missing one: it
      // lands somewhere arbitrary, and selecting text in a reader then
      // highlights the wrong part of the page.
      final degenerate = RecognisedText(
        pageId: const PageId('a'),
        blocks: const [
          TextBlock(
            text: 'nowhere',
            bounds: NormalisedRect(
              left: 0.5,
              top: 0.5,
              right: 0.5,
              bottom: 0.5,
            ),
          ),
        ],
        languageTag: 'la',
        recognisedAt: DateTime.utc(2026),
      );

      expect(OcrRules.placeableBlocks(degenerate), isEmpty);
    });

    test('drops a block whose box escapes the page', () {
      final outside = RecognisedText(
        pageId: const PageId('a'),
        blocks: const [
          TextBlock(
            text: 'off the page',
            bounds: NormalisedRect(
              left: 0.5,
              top: 0.5,
              right: 1.4,
              bottom: 0.6,
            ),
          ),
        ],
        languageTag: 'la',
        recognisedAt: DateTime.utc(2026),
      );

      expect(OcrRules.placeableBlocks(outside), isEmpty);
    });

    test('drops a block whose text is only whitespace', () {
      final blank = RecognisedText(
        pageId: const PageId('a'),
        blocks: const [
          TextBlock(
            text: '   ',
            bounds: NormalisedRect(
              left: 0.1,
              top: 0.1,
              right: 0.9,
              bottom: 0.2,
            ),
          ),
        ],
        languageTag: 'la',
        recognisedAt: DateTime.utc(2026),
      );

      expect(OcrRules.placeableBlocks(blank), isEmpty);
    });
  });

  group('export file name', () {
    test('is the title with a text extension', () {
      expect(OcrRules.exportFileName('Invoice 2026'), 'Invoice 2026.txt');
    });

    test('replaces characters a filesystem would reject', () {
      expect(
        OcrRules.exportFileName('Invoice: Acme/Ltd'),
        'Invoice_ Acme_Ltd.txt',
      );
    });

    test('does not collapse two different titles onto one name', () {
      // Replacing rather than dropping punctuation is what keeps these apart.
      expect(
        OcrRules.exportFileName('Report-A'),
        isNot(OcrRules.exportFileName('Report B')),
      );
    });

    test('falls back to a usable name for a title of only punctuation', () {
      expect(OcrRules.exportFileName('***'), 'document.txt');
    });

    test('falls back for an empty title', () {
      expect(OcrRules.exportFileName(''), 'document.txt');
    });
  });

  group('scripts', () {
    test('only Latin is bundled', () {
      expect(OcrScript.values.where((script) => script.bundled), [
        OcrScript.latin,
      ]);
    });

    test('the default script is one that is bundled', () {
      // Otherwise a fresh install could not recognise anything at all.
      expect(OcrScript.defaultScript.bundled, isTrue);
    });

    test('a known tag resolves to its script', () {
      expect(OcrScript.fromTag('ja'), OcrScript.japanese);
    });

    test('an unknown tag falls back rather than throwing', () {
      // A settings value written by an older release, or by a build that
      // shipped a script this one does not, must degrade to working
      // recognition rather than to an error.
      expect(OcrScript.fromTag('xx'), OcrScript.defaultScript);
      expect(OcrScript.fromTag(null), OcrScript.defaultScript);
    });

    test('every script has a distinct tag', () {
      final tags = OcrScript.values.map((script) => script.languageTag).toSet();

      expect(tags, hasLength(OcrScript.values.length));
    });
  });
}
