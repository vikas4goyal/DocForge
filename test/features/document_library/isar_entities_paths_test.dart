import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:flutter_test/flutter_test.dart';

Document documentAt(String relative, {FolderId? folderId}) => Document(
  id: const DocumentId('doc-1'),
  title: 'Invoice',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026, 2),
  pageCount: 3,
  sizeInBytes: 1024,
  libraryPath: LibraryPath.parse(relative),
  folderId: folderId,
);

void main() {
  group('DocumentEntity path round-trip', () {
    test('a document at the library root', () {
      final entity = DocumentEntity.fromDomain(documentAt('Invoice.pdf'));

      expect(entity.folderPath, '');
      expect(entity.fileName, 'Invoice.pdf');
      expect(entity.toDomain().libraryPath.relative, 'Invoice.pdf');
      expect(entity.toDomain().libraryPath.isAtRoot, isTrue);
    });

    test('a document in a nested folder', () {
      final entity = DocumentEntity.fromDomain(
        documentAt('Invoices/2026/Receipt.pdf'),
      );

      expect(entity.folderPath, 'Invoices/2026');
      expect(entity.fileName, 'Receipt.pdf');

      final restored = entity.toDomain().libraryPath;
      expect(restored.folders, ['Invoices', '2026']);
      expect(restored.relative, 'Invoices/2026/Receipt.pdf');
    });

    test('no absolute device path is written', () {
      final entity = DocumentEntity.fromDomain(documentAt('Invoice.pdf'));

      // The whole point of the schema change: a stored absolute path would be
      // wrong after a restore and meaningless to a future sync layer.
      expect(entity.folderPath, isNot(startsWith('/')));
      expect(entity.fileName, isNot(contains('/')));
    });

    test('every other field survives the round-trip', () {
      final document =
          documentAt(
            'Invoices/Receipt.pdf',
            folderId: const FolderId('f1'),
          ).copyWith(
            isFavourite: true,
            isArchived: true,
            isProtected: true,
            hasRecognisedText: true,
          );

      final restored = DocumentEntity.fromDomain(document).toDomain();

      expect(restored.id, document.id);
      expect(restored.title, document.title);
      expect(restored.pageCount, document.pageCount);
      expect(restored.sizeInBytes, document.sizeInBytes);
      expect(restored.folderId, const FolderId('f1'));
      expect(restored.isFavourite, isTrue);
      expect(restored.isArchived, isTrue);
      expect(restored.isProtected, isTrue);
      expect(restored.hasRecognisedText, isTrue);
      expect(restored.libraryPath, document.libraryPath);
    });

    test('rows are written at the current schema version', () {
      expect(
        DocumentEntity.fromDomain(documentAt('A.pdf')).schemaVersion,
        librarySchemaVersion,
      );
      expect(librarySchemaVersion, 3);
    });
  });

  group('Document convenience accessors', () {
    test('expose the file name and relative path', () {
      final document = documentAt('Invoices/2026/Receipt.pdf');

      expect(document.fileName, 'Receipt.pdf');
      expect(document.relativePath, 'Invoices/2026/Receipt.pdf');
    });
  });

  group('FolderEntity path round-trip', () {
    test('carries the relative path alongside the name', () {
      final folder = Folder(
        id: const FolderId('f1'),
        name: '2026',
        relativePath: 'Invoices/2026',
        createdAt: DateTime.utc(2026),
      );

      final restored = FolderEntity.fromDomain(folder).toDomain();

      expect(restored.name, '2026');
      // Name and address are different things: two folders called 2026 under
      // different parents are different folders.
      expect(restored.relativePath, 'Invoices/2026');
    });

    test('a root folder has a relative path equal to its name', () {
      final folder = Folder(
        id: const FolderId('f1'),
        name: 'Invoices',
        relativePath: 'Invoices',
        createdAt: DateTime.utc(2026),
      );

      expect(FolderEntity.fromDomain(folder).relativePath, 'Invoices');
    });
  });

  group('Document JSON', () {
    test('the library path serialises as a plain string', () {
      final json = documentAt('Invoices/Receipt.pdf').toJson();

      expect(json['libraryPath'], 'Invoices/Receipt.pdf');
    });

    test('round-trips through JSON', () {
      final document = documentAt('Invoices/2026/Receipt.pdf');

      final restored = Document.fromJson(document.toJson());

      expect(restored, document);
      expect(restored.libraryPath.folders, ['Invoices', '2026']);
    });
  });
}
