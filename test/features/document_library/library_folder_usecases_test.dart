/// Folder operations against the user-visible library folder.
///
/// The point of every test here is the pairing: a folder is a real directory
/// *and* an index record, and an operation that updates one without the other
/// leaves the user looking at a folder that does not open, or a directory the
/// application cannot see.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/application/usecases/library_folder_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late InMemoryPublicFileStore store;
  late FakeFolderRepository folders;
  late FakeDocumentRepository documents;

  final clock = FixedClock(DateTime.utc(2026, 3, 14, 9, 30));

  setUp(() {
    store = InMemoryPublicFileStore();
    folders = FakeFolderRepository();
    documents = FakeDocumentRepository();
  });

  CreateLibraryFolder create() =>
      CreateLibraryFolder(store, folders, clock, SequentialIdGenerator());

  RenameLibraryFolder rename() =>
      RenameLibraryFolder(store, folders, documents);

  DeleteLibraryFolder remove() =>
      DeleteLibraryFolder(store, folders, documents);

  /// Puts a document at [path] in both the folder and the index.
  Document given(String path) {
    final libraryPath = LibraryPath.parse(path);
    final document = Document(
      id: DocumentId('doc-$path'),
      title: libraryPath.fileName.replaceAll('.pdf', ''),
      createdAt: DateTime.utc(2026, 3),
      updatedAt: DateTime.utc(2026, 3),
      pageCount: 1,
      sizeInBytes: 1024,
      libraryPath: libraryPath,
    );

    store.files[libraryPath.relative] = 'x';
    for (var depth = 1; depth <= libraryPath.folders.length; depth++) {
      store.folderPaths.add(libraryPath.folders.take(depth).join('/'));
    }
    documents.documents[document.id] = document;

    return document;
  }

  group('creating a folder', () {
    test('makes the directory and records it', () async {
      final result = await create()('Invoices');

      expect(result, isA<Success<Folder>>());
      expect(store.folderPaths, contains('Invoices'));
      expect(folders.folders.values.single.name, 'Invoices');
      expect(folders.folders.values.single.relativePath, 'Invoices');
    });

    test('creates inside the folder currently open', () async {
      await create()('Invoices');

      await create()('2026', parent: const ['Invoices']);

      expect(store.folderPaths, contains('Invoices/2026'));
      expect(folders.folders.values.last.relativePath, 'Invoices/2026');
    });

    test('trims the name the user typed', () async {
      await create()('  Invoices  ');

      expect(folders.folders.values.single.name, 'Invoices');
    });

    test('refuses an empty name', () async {
      final result = await create()('   ');

      expect(
        result,
        const Result<Folder>.failure(
          Failure.validation(issue: ValidationIssue.emptyName),
        ),
      );
      expect(store.folderPaths, isNot(contains('Invoices')));
    });

    test('refuses a name the filesystem would not accept', () async {
      // A separator would silently create a *nested* folder rather than the
      // one the user asked for, which is why it is refused rather than
      // sanitised.
      final result = await create()('Invoices/2026');

      expect(
        result,
        const Result<Folder>.failure(
          Failure.validation(issue: ValidationIssue.illegalName),
        ),
      );
    });

    test('refuses a name already taken, whatever its case', () async {
      await create()('Invoices');

      final result = await create()('invoices');

      expect(
        result,
        const Result<Folder>.failure(
          Failure.validation(issue: ValidationIssue.duplicateFolderName),
        ),
      );
      expect(folders.folders, hasLength(1));
    });

    test('a file of the same name does not block a folder', () async {
      given('Invoices.pdf');

      final result = await create()('Invoices.pdf');

      expect(result, isA<Success<Folder>>());
    });

    test('an unreadable parent is reported rather than overwritten', () async {
      // Without the listing there is no way to know whether the name is free,
      // and creating anyway could collide with a folder that is already there.
      store.failures['list'] = const Failure.storage();

      final result = await create()('Invoices');

      expect(result, isA<Failed<Folder>>());
      expect(folders.folders, isEmpty);
    });

    test('a directory that could not be made records nothing', () async {
      store.failures['createFolder'] = const Failure.storage();

      final result = await create()('Invoices');

      expect(result, isA<Failed<Folder>>());
      expect(folders.folders, isEmpty);
    });
  });

  group('renaming a folder', () {
    test('renames the directory and its record', () async {
      await create()('Invoices');

      final result = await rename()(const ['Invoices'], 'Bills');

      expect(result, isA<Success<void>>());
      expect(store.folderPaths, contains('Bills'));
      expect(folders.folders.values.single.name, 'Bills');
      expect(folders.folders.values.single.relativePath, 'Bills');
    });

    test('re-paths the documents inside it', () async {
      final document = given('Invoices/March.pdf');

      await rename()(const ['Invoices'], 'Bills');

      expect(documents.documents[document.id]!.relativePath, 'Bills/March.pdf');
    });

    test('leaves documents outside it alone', () async {
      final other = given('Receipts/March.pdf');

      await rename()(const ['Invoices'], 'Bills');

      expect(documents.documents[other.id]!.relativePath, 'Receipts/March.pdf');
    });

    test('renames a nested folder without disturbing its parent', () async {
      final document = given('Invoices/2026/March.pdf');

      await rename()(const ['Invoices', '2026'], '2027');

      expect(
        documents.documents[document.id]!.relativePath,
        'Invoices/2027/March.pdf',
      );
    });

    test('refuses an empty name', () async {
      final result = await rename()(const ['Invoices'], '  ');

      expect(
        result,
        const Result<void>.failure(
          Failure.validation(issue: ValidationIssue.emptyName),
        ),
      );
    });

    test('refuses a name the filesystem would not accept', () async {
      final result = await rename()(const ['Invoices'], 'a/b');

      expect(
        result,
        const Result<void>.failure(
          Failure.validation(issue: ValidationIssue.illegalName),
        ),
      );
    });

    test('a directory that could not be renamed re-paths nothing', () async {
      final document = given('Invoices/March.pdf');
      store.failures['renameFolder'] = const Failure.storage();

      final result = await rename()(const ['Invoices'], 'Bills');

      expect(result, isA<Failed<void>>());
      expect(
        documents.documents[document.id]!.relativePath,
        'Invoices/March.pdf',
      );
    });
  });

  group('deleting a folder', () {
    test('removes the directory and its record', () async {
      await create()('Invoices');

      final result = await remove()(const ['Invoices']);

      expect(result, isA<Success<void>>());
      expect(store.folderPaths, isNot(contains('Invoices')));
      expect(folders.folders, isEmpty);
    });

    test('deletes the documents inside it by default', () async {
      final document = given('Invoices/March.pdf');

      await remove()(const ['Invoices']);

      expect(documents.documents, isNot(contains(document.id)));
    });

    test('keeps documents by moving them to the root when asked', () async {
      final document = given('Invoices/March.pdf');

      await remove()(const ['Invoices'], keepDocuments: true);

      expect(documents.documents[document.id]!.relativePath, 'March.pdf');
      expect(store.files, contains('March.pdf'));
    });

    test('leaves documents outside it alone', () async {
      final other = given('Receipts/March.pdf');

      await remove()(const ['Invoices']);

      expect(documents.documents, contains(other.id));
    });

    test('a file that could not be moved stops the deletion', () async {
      // Half-moved is the worst outcome: documents in two places, and the
      // folder gone so the user cannot see what was left behind.
      final document = given('Invoices/March.pdf');
      store.failures['rename'] = const Failure.storage();

      final result = await remove()(const ['Invoices'], keepDocuments: true);

      expect(result, isA<Failed<void>>());
      expect(store.folderPaths, contains('Invoices'));
      expect(
        documents.documents[document.id]!.relativePath,
        'Invoices/March.pdf',
      );
    });

    test('a directory that could not be removed is reported', () async {
      await create()('Invoices');
      store.failures['deleteFolder'] = const Failure.storage();

      final result = await remove()(const ['Invoices']);

      expect(result, isA<Failed<void>>());
      expect(folders.folders, hasLength(1));
    });
  });
}
