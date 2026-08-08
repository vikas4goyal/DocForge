import 'dart:io';
import 'dart:typed_data';

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/document_page_handle.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/fixtures/fixtures.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/document_library/infrastructure/document_page_access_repository.dart';
import 'package:doc_scanly/features/document_library/infrastructure/document_page_cache.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late Directory directory;
  late FakePageRepository pages;
  late _Resolver files;
  late InMemorySecureStore secrets;
  late _PdfEngine engine;
  late LibraryDocumentPageAccessRepository access;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('document-page-access-');
    pages = FakePageRepository();
    files = _Resolver();
    secrets = InMemorySecureStore();
    engine = _PdfEngine();
    access = LibraryDocumentPageAccessRepository(
      pages,
      files,
      secrets,
      directory,
      engine.render,
      engine.extract,
    );
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test(
    'stored rows are ordered and retain their authoritative identities',
    () async {
      final stored = samplePages(2).reversed.toList();
      pages.pages[sampleDocument.id] = stored;

      final result = await access.pagesOf(sampleDocument);

      expect(result.valueOrNull!.map((page) => page.pageNumber), [1, 2]);
      expect(result.valueOrNull!.first.id, samplePages(2).first.id);
      expect(
        result.valueOrNull!.first.source,
        isA<StoredImageDocumentPageSource>(),
      );
    },
  );

  test(
    'PDF without rows receives one stable virtual handle per page',
    () async {
      final document = sampleDocument.copyWith(pageCount: 3);

      final first = (await access.pagesOf(document)).valueOrNull!;
      final second = (await access.pagesOf(document)).valueOrNull!;

      expect(first, second);
      expect(first.map((page) => page.pageNumber), [1, 2, 3]);
      expect(
        first.map((page) => page.source),
        everyElement(isA<PdfDocumentPageSource>()),
      );
    },
  );

  test(
    'stored image materialisation returns existing authoritative path',
    () async {
      final image = File('${directory.path}/page.jpg')..writeAsBytesSync([1]);
      final handle = DocumentPageHandle(
        id: samplePages(1).single.id,
        documentId: sampleDocument.id,
        pageNumber: 1,
        source: DocumentPageSource.storedImage(imagePath: image.path),
      );

      final result = await access.materialize(
        sampleDocument,
        handle,
        DocumentPageRenderPurpose.sharing,
      );

      expect(
        result.valueOrNull,
        MaterializedDocumentPage.authoritative(path: image.path),
      );
      expect(engine.renderCount, 0);
    },
  );

  test('missing stored image falls back to the saved PDF', () async {
    final handle = DocumentPageHandle(
      id: samplePages(1).single.id,
      documentId: sampleDocument.id,
      pageNumber: 1,
      source: const DocumentPageSource.storedImage(
        imagePath: '/removed/capture-staging/page.jpg',
        thumbnailPath: '/removed/capture-staging/thumbnail.jpg',
      ),
    );

    final result = await access.materialize(
      sampleDocument,
      handle,
      DocumentPageRenderPurpose.thumbnail,
    );

    expect(result.valueOrNull, isA<CachedDocumentPage>());
    expect(File(result.valueOrNull!.path).existsSync(), isTrue);
    expect(engine.renderCount, 1);
    expect(files.released, 1);
  });

  test('missing thumbnail uses the retained full-size page image', () async {
    final image = File('${directory.path}/page.jpg')..writeAsBytesSync([1]);
    final handle = DocumentPageHandle(
      id: samplePages(1).single.id,
      documentId: sampleDocument.id,
      pageNumber: 1,
      source: DocumentPageSource.storedImage(
        imagePath: image.path,
        thumbnailPath: '/removed/thumbnail.jpg',
      ),
    );

    final result = await access.materialize(
      sampleDocument,
      handle,
      DocumentPageRenderPurpose.thumbnail,
    );

    expect(
      result.valueOrNull,
      MaterializedDocumentPage.authoritative(path: image.path),
    );
    expect(engine.renderCount, 0);
  });

  test(
    'PDF materialisation respects purpose bounds, password, and cleanup',
    () async {
      final document = sampleDocument.copyWith(isProtected: true, pageCount: 1);
      await secrets.write(
        SecureStorageKeys.pdfPassword(document.id.value),
        'secret',
      );
      final handle = (await access.pagesOf(document)).valueOrNull!.single;

      final result = await access.materialize(
        document,
        handle,
        DocumentPageRenderPurpose.sharing,
      );
      final materialized = result.valueOrNull!;

      expect(engine.width, DocumentPageRenderPurpose.sharing.maxWidth);
      expect(engine.password, 'secret');
      expect(File(materialized.path).existsSync(), isTrue);
      expect(files.released, 1);
      expect((await access.release(materialized)).isSuccess, isTrue);
      expect(File(materialized.path).existsSync(), isFalse);
    },
  );

  test('thumbnail render is cached and not repeated', () async {
    final handle = (await access.pagesOf(sampleDocument)).valueOrNull!.first;

    final first = await access.materialize(
      sampleDocument,
      handle,
      DocumentPageRenderPurpose.thumbnail,
    );
    final second = await access.materialize(
      sampleDocument,
      handle,
      DocumentPageRenderPurpose.thumbnail,
    );

    expect(first.valueOrNull, isA<CachedDocumentPage>());
    expect(second.valueOrNull, first.valueOrNull);
    expect(engine.renderCount, 1);
  });

  test('an evicted thumbnail is regenerated from the PDF', () async {
    access = LibraryDocumentPageAccessRepository(
      pages,
      files,
      secrets,
      directory,
      engine.render,
      engine.extract,
      cache: DocumentPageCacheMaintenance(
        root: Directory('${directory.path}/document-pages'),
        maxFiles: 1,
      ),
    );
    final document = sampleDocument.copyWith(pageCount: 2);
    final handles = (await access.pagesOf(document)).valueOrNull!;

    await access.materialize(
      document,
      handles.first,
      DocumentPageRenderPurpose.thumbnail,
    );
    await access.materialize(
      document,
      handles.last,
      DocumentPageRenderPurpose.thumbnail,
    );
    await access.materialize(
      document,
      handles.first,
      DocumentPageRenderPurpose.thumbnail,
    );

    expect(engine.renderCount, 3);
  });

  test('a changed PDF invalidates the prior fingerprint cache', () async {
    final handle = (await access.pagesOf(sampleDocument)).valueOrNull!.first;
    final first = await access.materialize(
      sampleDocument,
      handle,
      DocumentPageRenderPurpose.thumbnail,
    );
    final changed = sampleDocument.copyWith(
      sizeInBytes: sampleDocument.sizeInBytes + 1,
      updatedAt: sampleDocument.updatedAt.add(const Duration(seconds: 1)),
    );

    final second = await access.materialize(
      changed,
      handle,
      DocumentPageRenderPurpose.thumbnail,
    );

    expect(File(first.valueOrNull!.path).existsSync(), isFalse);
    expect(File(second.valueOrNull!.path).existsSync(), isTrue);
    expect(engine.renderCount, 2);
  });

  test('cleanup failure returns a readable temporary render', () async {
    access = LibraryDocumentPageAccessRepository(
      pages,
      files,
      secrets,
      directory,
      engine.render,
      engine.extract,
      cache: DocumentPageCacheMaintenance(
        root: Directory('${directory.path}/document-pages'),
        maxFiles: 1,
        deleteFile: (_) async => throw const FileSystemException('refused'),
      ),
    );
    final document = sampleDocument.copyWith(pageCount: 2);
    final handles = (await access.pagesOf(document)).valueOrNull!;
    await access.materialize(
      document,
      handles.first,
      DocumentPageRenderPurpose.thumbnail,
    );

    final second = await access.materialize(
      document,
      handles.last,
      DocumentPageRenderPurpose.thumbnail,
    );

    expect(second.valueOrNull, isA<TemporaryDocumentPage>());
    expect(File(second.valueOrNull!.path).existsSync(), isTrue);
    expect((await access.release(second.valueOrNull!)).isSuccess, isTrue);
  });

  test(
    'embedded text uses PDF engine and stored image returns no text',
    () async {
      engine.text = ' Policy text ';
      final pdf = (await access.pagesOf(sampleDocument)).valueOrNull!.first;
      expect(
        (await access.embeddedText(sampleDocument, pdf)).valueOrNull,
        ' Policy text ',
      );

      final stored = pdf.copyWith(
        source: const DocumentPageSource.storedImage(imagePath: '/missing.jpg'),
      );
      expect(
        (await access.embeddedText(sampleDocument, stored)).valueOrNull,
        isNull,
      );
    },
  );

  test('render failure is typed and still releases resolved PDF', () async {
    engine.failure = const Failure.corruptFile();
    final handle = (await access.pagesOf(sampleDocument)).valueOrNull!.first;

    final result = await access.materialize(
      sampleDocument,
      handle,
      DocumentPageRenderPurpose.recognition,
    );

    expect(result.failureOrNull, const Failure.corruptFile());
    expect(files.released, 1);
  });
}

class _Resolver implements DocumentFileResolver {
  int released = 0;

  @override
  Future<Result<String>> pathFor(Document document) async =>
      const Result<String>.success('/virtual/document.pdf');

  @override
  Future<Result<void>> release(Document document) async {
    released += 1;
    return const Result<void>.success(null);
  }
}

class _PdfEngine {
  int renderCount = 0;
  int? width;
  String? password;
  String? text;
  Failure? failure;

  Future<Result<Uint8List>> render(
    String filePath, {
    required int pageNumber,
    required int width,
    String? password,
  }) async {
    renderCount += 1;
    this.width = width;
    this.password = password;
    return failure == null
        ? Result<Uint8List>.success(Uint8List.fromList([1, 2, 3]))
        : Result<Uint8List>.failure(failure!);
  }

  Future<Result<String?>> extract(
    String filePath, {
    required int pageNumber,
    String? password,
  }) async => Result<String?>.success(text);
}
