/// Tests for the import domain rules.
library;

import 'package:doc_scanly/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/features/document_import/domain/import_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extensionOf', () {
    test('returns the lower-cased extension', () {
      expect(ImportRules.extensionOf('/a/b/Scan.JPG'), 'jpg');
    });

    test('is empty for a file with no extension', () {
      expect(ImportRules.extensionOf('/a/b/README'), '');
    });

    test('is empty for a dotfile, which has no extension either', () {
      // A leading dot names the file; it does not introduce a type.
      expect(ImportRules.extensionOf('/a/.gitignore'), '');
    });

    test('is empty for a name ending in a dot', () {
      expect(ImportRules.extensionOf('/a/odd.'), '');
    });

    test('takes the last extension of a doubled one', () {
      expect(ImportRules.extensionOf('/a/archive.tar.gz'), 'gz');
    });
  });

  group('kindFor', () {
    test('recognises a PDF', () {
      expect(ImportRules.kindFor('/a/doc.pdf'), ImportedFileKind.pdf);
    });

    test('recognises every supported image extension', () {
      for (final extension in ImportRules.imageExtensions) {
        expect(
          ImportRules.kindFor('/a/page.$extension'),
          ImportedFileKind.image,
          reason: '$extension should be a supported image',
        );
      }
    });

    test('includes HEIC, the iPhone camera default', () {
      // Omitting it would reject most of a typical iOS photo library.
      expect(ImportRules.kindFor('/a/IMG_0001.HEIC'), ImportedFileKind.image);
    });

    test('rejects anything else', () {
      for (final path in ['/a/notes.txt', '/a/sheet.xlsx', '/a/no_extension']) {
        expect(ImportRules.kindFor(path), ImportedFileKind.unsupported);
      }
    });
  });

  group('classify', () {
    test('preserves selection order', () {
      // Page order in the finished document comes from this order.
      final classified = ImportRules.classify(['/b.png', '/a.jpg', '/c.pdf']);

      expect(classified.map((c) => c.path), ['/b.png', '/a.jpg', '/c.pdf']);
    });

    test('marks each candidate with what it is', () {
      final classified = ImportRules.classify(['/a.jpg', '/b.txt']);

      expect(classified.first.isSupported, isTrue);
      expect(classified.last.isSupported, isFalse);
    });
  });

  group('hasAnythingToImport', () {
    test('is false when nothing selected is supported', () {
      expect(
        ImportRules.hasAnythingToImport(
          ImportRules.classify(['/a.txt', '/b.docx']),
        ),
        isFalse,
      );
    });

    test('is true when at least one file is supported', () {
      expect(
        ImportRules.hasAnythingToImport(
          ImportRules.classify(['/a.txt', '/b.jpg']),
        ),
        isTrue,
      );
    });
  });

  group('suggestedTitle', () {
    test('is the file name without its extension', () {
      expect(ImportRules.suggestedTitle('/a/Invoice 2026.pdf'), 'Invoice 2026');
    });

    test('is the whole name when there is no extension', () {
      expect(ImportRules.suggestedTitle('/a/Invoice'), 'Invoice');
    });

    test('is null when nothing usable remains', () {
      expect(ImportRules.suggestedTitle('/a/   .pdf'), isNull);
    });
  });

  group('sources', () {
    test('each source maps to the page source recorded on a bundle', () {
      expect(ImportSource.camera.pageSource, PageSource.camera);
      expect(ImportSource.gallery.pageSource, PageSource.gallery);
      expect(ImportSource.files.pageSource, PageSource.files);
      expect(ImportSource.shareSheet.pageSource, PageSource.shareSheet);
    });

    test('each source names the permission it needs', () {
      expect(ImportSource.camera.permission, PermissionKind.camera);
      expect(ImportSource.gallery.permission, PermissionKind.photos);
      expect(ImportSource.files.permission, PermissionKind.files);
    });

    test('the share sheet needs no permission', () {
      // The sending application already granted access by sending it; a prompt
      // here would be one the user cannot connect to anything they did.
      expect(ImportSource.shareSheet.permission, isNull);
    });

    test('every source describes where content comes from', () {
      for (final source in ImportSource.values) {
        expect(source.label, isNotEmpty);
        expect(source.semanticsLabel, isNotEmpty);
      }
    });
  });

  group('messages', () {
    test('the unsupported-type message names the supported types', () {
      expect(ImportRules.unsupportedTypeMessage, contains('PDF'));
      expect(ImportRules.unsupportedTypeMessage, contains('JPEG'));
    });

    test('the count message is singular for one document', () {
      expect(ImportRules.importedCountMessage(1), '1 document imported.');
    });

    test('the count message is plural for several', () {
      expect(ImportRules.importedCountMessage(3), '3 documents imported.');
    });

    test('the count message handles nothing having been imported', () {
      expect(ImportRules.importedCountMessage(0), 'Nothing was imported.');
    });

    test('a single file reports no file number', () {
      expect(ImportRules.progressLabel(0, 1), 'Importing…');
    });

    test('several files report which one', () {
      expect(ImportRules.progressLabel(2, 5), 'Importing file 2 of 5…');
    });
  });
}
