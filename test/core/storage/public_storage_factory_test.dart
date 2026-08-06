import 'dart:io';

import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/core/storage/public_storage/media_store_public_file_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_storage_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory documents;
  late Directory cache;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('docscanly_docs_');
    cache = await Directory.systemTemp.createTemp('docscanly_cache_');
  });

  tearDown(() async {
    if (documents.existsSync()) await documents.delete(recursive: true);
    if (cache.existsSync()) await cache.delete(recursive: true);
  });

  test('Android gets the MediaStore store', () {
    final store = buildPublicFileStore(
      documentsDirectory: documents,
      cacheDirectory: cache,
      isAndroid: true,
    );

    expect(store, isA<MediaStorePublicFileStore>());
  });

  test('iOS gets the filesystem store rooted at the documents container', () {
    final store = buildPublicFileStore(
      documentsDirectory: documents,
      cacheDirectory: cache,
      isAndroid: false,
    );

    expect(store, isA<FilesystemPublicFileStore>());
    expect(
      (store as FilesystemPublicFileStore).containerDirectory.path,
      documents.path,
    );
  });

  test('both platforms name the library folder identically', () {
    // The folder the user sees has to be called the same thing on each
    // platform, or a document synced between devices would land in two places.
    expect(
      FilesystemPublicFileStore.defaultLibraryFolderName,
      MediaStorePublicFileStore.defaultLibraryFolderName,
    );
  });

  test('iCloud uses the supplied document scope without nesting', () async {
    final cloudRoot = Directory('${documents.path}/iCloud/Documents');
    final store =
        buildPublicFileStore(
              documentsDirectory: documents,
              cacheDirectory: cache,
              iosLibraryRoot: cloudRoot,
              isAndroid: false,
            )
            as FilesystemPublicFileStore;

    await store.initialise();

    expect(store.rootDirectory.path, cloudRoot.path);
    expect(Directory('${cloudRoot.path}/DocScanly').existsSync(), isFalse);
  });
}
