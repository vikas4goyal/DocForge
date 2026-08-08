import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_scanly/features/document_scanning/domain/scan_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds [count] captures with stable identifiers.
List<CapturedPage> captures(int count) => List.generate(
  count,
  (index) => CapturedPage(
    id: PageId('page-$index'),
    imagePath: '/pages/page-$index.jpg',
    quad: PageQuad.full,
  ),
);

void main() {
  group('rotate', () {
    test('turns a page one quarter clockwise', () {
      final rotated = ScanSessionRules.rotate(captures(3), 1);

      expect(rotated[1].rotation, PageRotation.quarter);
    });

    test('leaves every other page alone', () {
      final rotated = ScanSessionRules.rotate(captures(3), 1);

      expect(rotated[0].rotation, PageRotation.none);
      expect(rotated[2].rotation, PageRotation.none);
    });

    test('four rotations return to the original orientation', () {
      var pages = captures(1);
      for (var i = 0; i < 4; i++) {
        pages = ScanSessionRules.rotate(pages, 0);
      }

      expect(pages.single.rotation, PageRotation.none);
    });

    test('never rewrites the file on disk', () {
      final original = captures(1);
      final rotated = ScanSessionRules.rotate(original, 0);

      // Rotation is metadata: re-encoding on every quarter turn would lose
      // quality and cost a write for a gesture the user may undo immediately.
      expect(rotated.single.imagePath, original.single.imagePath);
    });

    test('an out-of-range index changes nothing', () {
      final pages = captures(2);

      expect(ScanSessionRules.rotate(pages, 5), pages);
      expect(ScanSessionRules.rotate(pages, -1), pages);
    });
  });

  group('reorder', () {
    test('moves a page to its new position', () {
      final reordered = ScanSessionRules.reorder(captures(3), 0, 2);

      expect(reordered.map((p) => p.id.value), ['page-1', 'page-2', 'page-0']);
    });

    test('moving backwards works as well as forwards', () {
      final reordered = ScanSessionRules.reorder(captures(3), 2, 0);

      expect(reordered.map((p) => p.id.value), ['page-2', 'page-0', 'page-1']);
    });

    test('keeps every page', () {
      final reordered = ScanSessionRules.reorder(captures(4), 1, 3);

      expect(reordered, hasLength(4));
      expect(reordered.map((p) => p.id).toSet(), hasLength(4));
    });

    test('a drag that ends where it started changes nothing', () {
      final pages = captures(3);

      expect(ScanSessionRules.reorder(pages, 1, 1), pages);
    });

    test('a drag that ends outside the list changes nothing', () {
      final pages = captures(3);

      // A gesture released off the edge of the list is normal, not an error.
      expect(ScanSessionRules.reorder(pages, 0, 9), pages);
      expect(ScanSessionRules.reorder(pages, 9, 0), pages);
    });

    test('never mutates the list it was given', () {
      final pages = captures(3);
      final before = pages.map((p) => p.id.value).toList();

      ScanSessionRules.reorder(pages, 0, 2);

      expect(pages.map((p) => p.id.value), before);
    });
  });

  group('delete and undo', () {
    test('removes the page at the index', () {
      final remaining = ScanSessionRules.delete(captures(3), 1);

      expect(remaining.map((p) => p.id.value), ['page-0', 'page-2']);
    });

    test('deleting the only page leaves nothing to save', () {
      final remaining = ScanSessionRules.delete(captures(1), 0);

      expect(remaining, isEmpty);
      expect(ScanSessionRules.canSave(remaining), isFalse);
    });

    test('undo puts the page back where it was, not at the end', () {
      final original = captures(3);
      final deleted = ScanSessionRules.delete(original, 1);

      final restored = ScanSessionRules.restore(deleted, original[1], 1);

      // Appending instead would silently reorder the document as a side effect
      // of an undo, which is the opposite of what an undo means.
      expect(restored.map((p) => p.id.value), ['page-0', 'page-1', 'page-2']);
    });

    test('undo of the first page restores it first', () {
      final original = captures(3);
      final deleted = ScanSessionRules.delete(original, 0);

      final restored = ScanSessionRules.restore(deleted, original[0], 0);

      expect(restored.first.id.value, 'page-0');
    });

    test('restoring beyond the end appends rather than throwing', () {
      final pages = captures(1);

      final restored = ScanSessionRules.restore(pages, captures(2)[1], 99);

      expect(restored, hasLength(2));
    });

    test('an out-of-range delete changes nothing', () {
      final pages = captures(2);

      expect(ScanSessionRules.delete(pages, 7), pages);
      expect(ScanSessionRules.delete(pages, -1), pages);
    });
  });

  group('saving', () {
    test('a session with pages can be saved', () {
      expect(ScanSessionRules.canSave(captures(1)), isTrue);
    });

    test('an empty session cannot', () {
      // The library forbids a document with no pages, so the save action stays
      // disabled rather than producing one that cannot be rendered.
      expect(ScanSessionRules.canSave(const []), isFalse);
    });

    test('the bundle preserves page order', () {
      final reordered = ScanSessionRules.reorder(captures(3), 2, 0);

      final bundle = ScanSessionRules.toBundle(reordered);

      expect(bundle.pages.map((p) => p.id.value), [
        'page-2',
        'page-0',
        'page-1',
      ]);
    });

    test('the bundle carries each page rotation through', () {
      final rotated = ScanSessionRules.rotate(captures(2), 0);

      final bundle = ScanSessionRules.toBundle(rotated);

      expect(bundle.pages.first.rotation, PageRotation.quarter);
    });

    test('the bundle records that the pages came from the camera', () {
      final bundle = ScanSessionRules.toBundle(captures(1));

      expect(bundle.source, PageSource.camera);
    });

    test('the bundle carries paths, never image bytes', () {
      final bundle = ScanSessionRules.toBundle(captures(3));

      // A bundle that could hold decoded images would defeat the write-first
      // rule the moment a batch got long.
      expect(bundle.pages.every((p) => p.imagePath.isNotEmpty), isTrue);
    });
  });

  group('correction tracking', () {
    test('a full-page crop needs no correction', () {
      expect(captures(1).single.needsCorrection, isFalse);
    });

    test('an adjusted crop does', () {
      final page = captures(1).single.copyWith(
        quad: const PageQuad(
          topLeft: NormalisedPoint(x: 0.1, y: 0.1),
          topRight: NormalisedPoint(x: 0.9, y: 0.15),
          bottomRight: NormalisedPoint(x: 0.88, y: 0.9),
          bottomLeft: NormalisedPoint(x: 0.12, y: 0.85),
        ),
      );

      expect(page.needsCorrection, isTrue);
    });

    test('an already-corrected page is never corrected twice', () {
      final page = captures(1).single.copyWith(
        quad: const PageQuad(
          topLeft: NormalisedPoint(x: 0.1, y: 0.1),
          topRight: NormalisedPoint(x: 0.9, y: 0.15),
          bottomRight: NormalisedPoint(x: 0.88, y: 0.9),
          bottomLeft: NormalisedPoint(x: 0.12, y: 0.85),
        ),
        isCorrected: true,
      );

      // Applying the transform to an already-rectangular image would distort
      // it further rather than fixing anything.
      expect(page.needsCorrection, isFalse);
    });
  });
}
