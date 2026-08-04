import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';
import 'package:doc_scanly/core/contracts/models/scanned_page_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

final _fixedTime = DateTime.utc(2026, 7, 26, 10, 30);

void main() {
  group('identifiers', () {
    test('round-trip through JSON', () {
      const id = DocumentId('doc-1');

      expect(DocumentId.fromJson(id.toJson()), id);
      expect(id.toJson(), 'doc-1');
    });

    test('toString yields the raw value for use in routes and logs', () {
      expect(const DocumentId('doc-1').toString(), 'doc-1');
      expect(const FolderId('folder-1').toString(), 'folder-1');
      expect(const PageId('page-1').toString(), 'page-1');
    });

    test(
      'identifiers of different types with the same value are not equal',
      () {
        // This is the whole point of wrapping them: passing a folder id where a
        // document id belongs must not type-check or compare equal.
        expect(const DocumentId('x'), isNot(equals(const FolderId('x'))));
      },
    );

    test('same-type identifiers compare by value', () {
      expect(const DocumentId('x'), const DocumentId('x'));
      expect(const DocumentId('x'), isNot(const DocumentId('y')));
    });
  });

  group('PageRotation', () {
    test('exposes clockwise degrees', () {
      expect(PageRotation.none.degrees, 0);
      expect(PageRotation.quarter.degrees, 90);
      expect(PageRotation.half.degrees, 180);
      expect(PageRotation.threeQuarter.degrees, 270);
    });

    test('rotating clockwise cycles back to none', () {
      var rotation = PageRotation.none;
      for (var i = 0; i < 4; i++) {
        rotation = rotation.rotatedClockwise;
      }

      expect(rotation, PageRotation.none);
    });

    test('each quarter turn advances by 90 degrees', () {
      expect(PageRotation.none.rotatedClockwise, PageRotation.quarter);
      expect(PageRotation.quarter.rotatedClockwise, PageRotation.half);
      expect(PageRotation.half.rotatedClockwise, PageRotation.threeQuarter);
      expect(PageRotation.threeQuarter.rotatedClockwise, PageRotation.none);
    });
  });

  group('NormalisedPoint', () {
    test('round-trips through JSON', () {
      const point = NormalisedPoint(x: 0.25, y: 0.75);

      expect(NormalisedPoint.fromJson(point.toJson()), point);
    });

    test('validates its bounds', () {
      expect(const NormalisedPoint(x: 0, y: 0).isWithinBounds, isTrue);
      expect(const NormalisedPoint(x: 1, y: 1).isWithinBounds, isTrue);
      expect(const NormalisedPoint(x: -0.1, y: 0.5).isWithinBounds, isFalse);
      expect(const NormalisedPoint(x: 0.5, y: 1.1).isWithinBounds, isFalse);
    });
  });

  group('PageQuad', () {
    test('round-trips through JSON', () {
      expect(PageQuad.fromJson(PageQuad.full.toJson()), PageQuad.full);
    });

    test('the full-page quad covers the whole page', () {
      expect(PageQuad.full.isFullPage, isTrue);
      expect(PageQuad.full.isWithinBounds, isTrue);
    });

    test('corners are returned in canonical order', () {
      expect(PageQuad.full.corners, [
        const NormalisedPoint(x: 0, y: 0),
        const NormalisedPoint(x: 1, y: 0),
        const NormalisedPoint(x: 1, y: 1),
        const NormalisedPoint(x: 0, y: 1),
      ]);
    });

    test('an adjusted quad is not the full page', () {
      const quad = PageQuad(
        topLeft: NormalisedPoint(x: 0.1, y: 0.1),
        topRight: NormalisedPoint(x: 0.9, y: 0.1),
        bottomRight: NormalisedPoint(x: 0.9, y: 0.9),
        bottomLeft: NormalisedPoint(x: 0.1, y: 0.9),
      );

      expect(quad.isFullPage, isFalse);
      expect(quad.isWithinBounds, isTrue);
    });

    test('a quad with an out-of-range corner is rejected', () {
      const quad = PageQuad(
        topLeft: NormalisedPoint(x: -0.5, y: 0),
        topRight: NormalisedPoint(x: 1, y: 0),
        bottomRight: NormalisedPoint(x: 1, y: 1),
        bottomLeft: NormalisedPoint(x: 0, y: 1),
      );

      expect(quad.isWithinBounds, isFalse);
    });
  });

  group('EnhancementSettings', () {
    test('round-trips through JSON', () {
      const settings = EnhancementSettings(
        filter: EnhancementFilter.magicColour,
        brightness: 0.2,
        contrast: -0.1,
        sharpen: 0.5,
        shadowRemoval: true,
      );

      expect(EnhancementSettings.fromJson(settings.toJson()), settings);
    });

    test('defaults leave the image untouched', () {
      expect(EnhancementSettings.none.isIdentity, isTrue);
      expect(EnhancementSettings.none.filter, EnhancementFilter.original);
      expect(EnhancementSettings.none.brightness, 0.0);
      expect(EnhancementSettings.none.shadowRemoval, isFalse);
    });

    test('any change makes the settings non-identity', () {
      expect(const EnhancementSettings(brightness: 0.1).isIdentity, isFalse);
      expect(
        const EnhancementSettings(
          filter: EnhancementFilter.grayscale,
        ).isIdentity,
        isFalse,
      );
      expect(
        const EnhancementSettings(shadowRemoval: true).isIdentity,
        isFalse,
      );
    });
  });

  group('DocumentPage', () {
    const page = DocumentPage(
      id: PageId('page-1'),
      documentId: DocumentId('doc-1'),
      order: 0,
      imagePath: '/documents/doc-1/page-1.jpg',
    );

    test('round-trips through JSON', () {
      expect(DocumentPage.fromJson(page.toJson()), page);
    });

    test('page numbers count from one', () {
      expect(page.pageNumber, 1);
      expect(page.copyWith(order: 4).pageNumber, 5);
    });

    test('carries a path rather than image bytes', () {
      // Enforced by the type: a page that could hold bytes would let a large
      // batch scan exhaust memory.
      expect(page.imagePath, isA<String>());
      expect(page.toJson().values.whereType<List<int>>(), isEmpty);
    });
  });

  group('PageRef', () {
    test('round-trips through JSON', () {
      const ref = PageRef(
        id: PageId('page-1'),
        imagePath: '/documents/doc-1/page-1.jpg',
        rotation: PageRotation.quarter,
      );

      expect(PageRef.fromJson(ref.toJson()), ref);
    });
  });

  group('Document', () {
    final document = Document(
      id: const DocumentId('doc-1'),
      title: 'Invoice',
      createdAt: _fixedTime,
      updatedAt: _fixedTime,
      pageCount: 3,
      sizeInBytes: 1024,
      libraryPath: LibraryPath.parse('document.pdf'),
    );

    test('round-trips through JSON', () {
      expect(Document.fromJson(document.toJson()), document);
    });

    test('round-trips with every optional field populated', () {
      final full = document.copyWith(
        folderId: const FolderId('folder-1'),
        isFavourite: true,
        isArchived: true,
        isProtected: true,
        hasRecognisedText: true,
      );

      expect(Document.fromJson(full.toJson()), full);
    });

    test('an archived document is not visible in the library', () {
      expect(document.isVisibleInLibrary, isTrue);
      expect(document.copyWith(isArchived: true).isVisibleInLibrary, isFalse);
    });

    test('a document with no folder is unfiled', () {
      expect(document.isUnfiled, isTrue);
      expect(
        document.copyWith(folderId: const FolderId('f-1')).isUnfiled,
        isFalse,
      );
    });

    test('never carries a password', () {
      // Protection is a flag; the secret lives only in secure storage.
      final json = document.copyWith(isProtected: true).toJson();

      expect(
        json.keys.map((k) => k.toLowerCase()),
        isNot(contains('password')),
      );
    });
  });

  group('Folder', () {
    final folder = Folder(
      id: const FolderId('folder-1'),
      name: 'Receipts',
      createdAt: _fixedTime,
    );

    test('round-trips through JSON', () {
      expect(Folder.fromJson(folder.toJson()), folder);
    });

    test('a new folder is empty', () {
      expect(folder.documentCount, 0);
      expect(folder.isEmpty, isTrue);
    });

    test('a folder with documents is not empty', () {
      expect(folder.copyWith(documentCount: 3).isEmpty, isFalse);
    });
  });

  group('StorageSummary', () {
    test('round-trips through JSON', () {
      const summary = StorageSummary(totalBytes: 2048, documentCount: 4);

      expect(StorageSummary.fromJson(summary.toJson()), summary);
    });

    test('the empty summary reports nothing stored', () {
      expect(StorageSummary.empty.totalBytes, 0);
      expect(StorageSummary.empty.documentCount, 0);
    });
  });

  group('NormalisedRect', () {
    test('round-trips through JSON', () {
      const rect = NormalisedRect(left: 0.1, top: 0.2, right: 0.8, bottom: 0.4);

      expect(NormalisedRect.fromJson(rect.toJson()), rect);
    });

    test('computes width and height', () {
      const rect = NormalisedRect(left: 0.2, top: 0.1, right: 0.6, bottom: 0.4);

      expect(rect.width, closeTo(0.4, 1e-9));
      expect(rect.height, closeTo(0.3, 1e-9));
    });

    test('rejects an inverted or out-of-range rectangle', () {
      const inverted = NormalisedRect(
        left: 0.8,
        top: 0.2,
        right: 0.1,
        bottom: 0.4,
      );
      const outOfRange = NormalisedRect(
        left: 0,
        top: 0,
        right: 1.5,
        bottom: 0.5,
      );

      expect(inverted.isValid, isFalse);
      expect(outOfRange.isValid, isFalse);
    });

    test('accepts a valid rectangle', () {
      const rect = NormalisedRect(left: 0, top: 0, right: 1, bottom: 1);

      expect(rect.isValid, isTrue);
    });
  });

  group('RecognisedText', () {
    final text = RecognisedText(
      pageId: const PageId('page-1'),
      languageTag: 'en',
      recognisedAt: _fixedTime,
      blocks: const [
        TextBlock(
          text: 'Total',
          bounds: NormalisedRect(left: 0.1, top: 0.1, right: 0.3, bottom: 0.15),
        ),
        TextBlock(
          text: '42.00',
          bounds: NormalisedRect(left: 0.6, top: 0.1, right: 0.8, bottom: 0.15),
        ),
      ],
    );

    test('round-trips through JSON with its bounding boxes', () {
      final restored = RecognisedText.fromJson(text.toJson());

      expect(restored, text);
      // Bounds must survive the round trip or the invisible text layer would be
      // written in the wrong place.
      expect(restored.blocks.first.bounds, text.blocks.first.bounds);
    });

    test('joins blocks into readable plain text', () {
      expect(text.plainText, 'Total\n42.00');
    });

    test('an empty result is valid, not an error', () {
      final empty = RecognisedText.empty(
        pageId: const PageId('page-1'),
        languageTag: 'en',
        recognisedAt: _fixedTime,
      );

      expect(empty.isEmpty, isTrue);
      expect(empty.plainText, isEmpty);
      expect(RecognisedText.fromJson(empty.toJson()), empty);
    });

    test('records the language it ran with', () {
      expect(text.languageTag, 'en');
    });
  });

  group('ScannedPageBundle', () {
    const bundle = ScannedPageBundle(
      pages: [
        PageRef(id: PageId('p1'), imagePath: '/tmp/p1.jpg'),
        PageRef(id: PageId('p2'), imagePath: '/tmp/p2.jpg'),
      ],
      source: PageSource.camera,
    );

    test('round-trips through JSON', () {
      expect(ScannedPageBundle.fromJson(bundle.toJson()), bundle);
    });

    test('reports its page count and readiness', () {
      expect(bundle.pageCount, 2);
      expect(bundle.isEmpty, isFalse);
      expect(bundle.canCreateDocument, isTrue);
    });

    test('an empty bundle cannot create a document', () {
      final empty = ScannedPageBundle.empty(PageSource.camera);

      expect(empty.isEmpty, isTrue);
      expect(empty.canCreateDocument, isFalse);
      expect(empty.pageCount, 0);
    });

    test('preserves page order', () {
      expect(bundle.pages.map((p) => p.id.value), ['p1', 'p2']);
    });

    test('carries a suggested title when the source provides one', () {
      const imported = ScannedPageBundle(
        pages: [],
        source: PageSource.files,
        suggestedTitle: 'Contract.pdf',
      );

      expect(
        ScannedPageBundle.fromJson(imported.toJson()).suggestedTitle,
        'Contract.pdf',
      );
    });
  });
}
