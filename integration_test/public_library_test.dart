// Verifies the parts of the public library that only a device can answer.
//
// Everything here needs real platform storage: on iOS the app's Documents
// container, on Android MediaStore. Neither exists in the host test VM, so the
// unit and widget suites substitute an in-memory store and these assertions —
// "the file is genuinely there", "another app could genuinely see it" — have to
// run on hardware:
//
//   flutter test integration_test/public_library_test.dart -d <device-id>
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/storage/capture_staging.dart';
import 'package:doc_forge/core/storage/public_storage/public_file_store.dart';
import 'package:doc_forge/core/storage/public_storage/public_storage_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late PublicFileStore store;
  late Directory cache;
  late Directory documents;

  setUpAll(() async {
    documents = await getApplicationDocumentsDirectory();
    cache = await getApplicationCacheDirectory();
    store = buildPublicFileStore(
      documentsDirectory: documents,
      cacheDirectory: cache,
    );
    await store.initialise();
  });

  /// Writes a throwaway source file the store can publish.
  Future<String> sourceFile(String name, {String contents = '%PDF-1.7'}) async {
    final file = File('${cache.path}/$name');
    await file.writeAsString(contents);
    return file.path;
  }

  group('the library folder', () {
    testWidgets('exists after initialising', (tester) async {
      final listed = await store.list(const []);

      expect(listed.isSuccess, isTrue);
    });

    testWidgets('a saved PDF is genuinely on the device', (tester) async {
      final path = LibraryPath.parse('Integration Save.pdf');

      final written = await store.writeFile(path, await sourceFile('in.pdf'));

      expect(written.isSuccess, isTrue);
      // Resolved through the store, because on Android the readable path is a
      // materialised copy rather than the item itself.
      final resolved = await store.materialise(path);
      expect(File(resolved.valueOrNull!).existsSync(), isTrue);
      expect(File(resolved.valueOrNull!).readAsStringSync(), '%PDF-1.7');

      await store.delete(path);
    });

    testWidgets('a nested folder is created and browsable', (tester) async {
      const folders = ['Integration', '2026'];

      final created = await store.createFolder(folders);
      expect(created.isSuccess, isTrue);

      final path = LibraryPath.inFolder(folders, 'Nested.pdf');
      await store.writeFile(path, await sourceFile('nested.pdf'));

      final listed = await store.list(folders);
      expect(
        listed.valueOrNull!.map((entry) => entry.name),
        contains('Nested.pdf'),
      );

      await store.deleteFolder(const ['Integration']);
    });

    testWidgets('a recursive walk finds a nested file', (tester) async {
      const folders = ['IntegrationWalk'];
      await store.createFolder(folders);
      final path = LibraryPath.inFolder(folders, 'Walked.pdf');
      await store.writeFile(path, await sourceFile('walk.pdf'));

      final walked = await store.listRecursive(const []);

      expect(
        walked.valueOrNull!
            .where((entry) => !entry.isFolder)
            .map((entry) => entry.path!.relative),
        contains('IntegrationWalk/Walked.pdf'),
      );

      await store.deleteFolder(folders);
    });

    testWidgets('renaming moves the file', (tester) async {
      final from = LibraryPath.parse('Before.pdf');
      final to = LibraryPath.parse('After.pdf');
      await store.writeFile(from, await sourceFile('rename.pdf'));

      final renamed = await store.rename(from, to);

      expect(renamed.isSuccess, isTrue);
      expect((await store.exists(from)).valueOrNull, isFalse);
      expect((await store.exists(to)).valueOrNull, isTrue);

      await store.delete(to);
    });

    testWidgets('deleting removes the file', (tester) async {
      final path = LibraryPath.parse('Doomed.pdf');
      await store.writeFile(path, await sourceFile('doomed.pdf'));

      await store.delete(path);

      expect((await store.exists(path)).valueOrNull, isFalse);
    });
  });

  group('iOS visibility', () {
    testWidgets('the Documents container holds only the library folder', (
      tester,
    ) async {
      // UIFileSharingEnabled exposes the container wholesale, so anything else
      // left in it would be visible in Files alongside the user's documents.
      if (!Platform.isIOS) return;

      final entries = documents
          .listSync()
          .map((entity) => entity.path.split(Platform.pathSeparator).last)
          .where((name) => !name.startsWith('.'))
          .toList();

      expect(entries, ['DocForge']);
    });
  });

  group('captures are temporary', () {
    testWidgets('a discarded session leaves nothing behind', (tester) async {
      final staging = CaptureStaging(cache);
      final directory = staging.directoryFor('integration-session');
      File('${directory.path}/page.jpg').writeAsStringSync('jpeg');

      await staging.discardSession('integration-session');

      expect(directory.existsSync(), isFalse);
    });

    testWidgets('the startup sweep clears what a crash left', (tester) async {
      final staging = CaptureStaging(cache)..directoryFor('crashed-session');

      final removed = await staging.sweepOrphans();

      expect(removed.valueOrNull, greaterThanOrEqualTo(1));
      expect(
        Directory('${staging.root.path}/crashed-session').existsSync(),
        isFalse,
      );
    });
  });

  group('storage accounting', () {
    testWidgets('totalBytes reflects what was written', (tester) async {
      final before = (await store.totalBytes()).valueOrNull!;
      final path = LibraryPath.parse('Measured.pdf');
      await store.writeFile(
        path,
        await sourceFile('measured.pdf', contents: '%PDF-1.7 padding'),
      );

      final after = (await store.totalBytes()).valueOrNull!;

      expect(after, greaterThan(before));

      await store.delete(path);
    });
  });
}
