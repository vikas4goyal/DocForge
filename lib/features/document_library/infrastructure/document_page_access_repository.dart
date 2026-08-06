/// Unified page access backed by stored scan rows and authoritative PDFs.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:doc_scanly/core/contracts/document_page_access.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/document_page_handle.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';

/// Renders one PDF page into PNG bytes at a bounded width.
typedef DocumentPagePdfRenderer =
    Future<Result<Uint8List>> Function(
      String filePath, {
      required int pageNumber,
      required int width,
      String? password,
    });

/// Extracts embedded text from one PDF page.
typedef DocumentPageTextExtractor =
    Future<Result<String?>> Function(
      String filePath, {
      required int pageNumber,
      String? password,
    });

/// Resolves document pages without persisting synthetic image-backed rows.
class LibraryDocumentPageAccessRepository
    implements DocumentPageAccessRepository {
  /// Creates the repository from explicit storage and PDF-engine boundaries.
  const LibraryDocumentPageAccessRepository(
    this._pages,
    this._files,
    this._secrets,
    this._cacheDirectory,
    this._renderPdfPage,
    this._extractPdfText,
  );

  final PageRepository _pages;
  final DocumentFileResolver _files;
  final SecureStore _secrets;
  final Directory _cacheDirectory;
  final DocumentPagePdfRenderer _renderPdfPage;
  final DocumentPageTextExtractor _extractPdfText;

  @override
  Future<Result<List<DocumentPageHandle>>> pagesOf(Document document) async {
    final stored = await _pages.forDocument(document.id);
    if (stored case Failed(:final failure)) {
      return Result<List<DocumentPageHandle>>.failure(failure);
    }
    final storedPages = stored.valueOrNull!;
    if (storedPages.isNotEmpty) {
      final ordered = [...storedPages]
        ..sort((a, b) => a.order.compareTo(b.order));
      return Result<List<DocumentPageHandle>>.success(
        ordered
            .map(
              (page) => DocumentPageHandle(
                id: page.id,
                documentId: document.id,
                pageNumber: page.pageNumber,
                source: DocumentPageSource.storedImage(
                  imagePath: page.imagePath,
                  thumbnailPath: page.thumbnailPath,
                ),
              ),
            )
            .toList(growable: false),
      );
    }

    return Result<List<DocumentPageHandle>>.success(
      List.generate(document.pageCount, (index) {
        final pageNumber = index + 1;
        return DocumentPageHandle(
          id: DocumentPageHandle.virtualPdfPageId(document.id, pageNumber),
          documentId: document.id,
          pageNumber: pageNumber,
          source: const DocumentPageSource.pdfPage(),
        );
      }, growable: false),
    );
  }

  @override
  Future<Result<MaterializedDocumentPage>> materialize(
    Document document,
    DocumentPageHandle page,
    DocumentPageRenderPurpose purpose,
  ) async {
    if (page.documentId != document.id ||
        page.pageNumber < 1 ||
        page.pageNumber > document.pageCount) {
      return const Result<MaterializedDocumentPage>.failure(
        Failure.notFound(debugDetail: 'Page does not belong to document.'),
      );
    }

    return page.source.when(
      storedImage: (imagePath, thumbnailPath) async {
        final selected = purpose == DocumentPageRenderPurpose.thumbnail
            ? (thumbnailPath ?? imagePath)
            : imagePath;
        if (!File(selected).existsSync()) {
          return const Result<MaterializedDocumentPage>.failure(
            Failure.notFound(debugDetail: 'Stored page image is missing.'),
          );
        }
        return Result<MaterializedDocumentPage>.success(
          MaterializedDocumentPage.authoritative(path: selected),
        );
      },
      pdfPage: () => _materializePdf(document, page, purpose),
    );
  }

  Future<Result<MaterializedDocumentPage>> _materializePdf(
    Document document,
    DocumentPageHandle page,
    DocumentPageRenderPurpose purpose,
  ) async {
    final target = File(_renderPath(document, page, purpose));
    if (purpose.retainsCache && target.existsSync()) {
      return Result<MaterializedDocumentPage>.success(
        MaterializedDocumentPage.cached(path: target.path),
      );
    }

    final resolved = await _files.pathFor(document);
    if (resolved case Failed(:final failure)) {
      return Result<MaterializedDocumentPage>.failure(failure);
    }
    try {
      final rendered = await _renderPdfPage(
        resolved.valueOrNull!,
        pageNumber: page.pageNumber,
        width: purpose.maxWidth,
        password: await _passwordFor(document),
      );
      if (rendered case Failed(:final failure)) {
        return Result<MaterializedDocumentPage>.failure(failure);
      }
      try {
        target.parent.createSync(recursive: true);
        await target.writeAsBytes(rendered.valueOrNull!, flush: true);
        return Result<MaterializedDocumentPage>.success(
          purpose.retainsCache
              ? MaterializedDocumentPage.cached(path: target.path)
              : MaterializedDocumentPage.temporary(path: target.path),
        );
      } on Object catch (error) {
        return Result<MaterializedDocumentPage>.failure(
          Failure.storage(debugDetail: '$error'),
        );
      }
    } finally {
      await _files.release(document);
    }
  }

  @override
  Future<Result<String?>> embeddedText(
    Document document,
    DocumentPageHandle page,
  ) async {
    if (page.source is StoredImageDocumentPageSource) {
      return const Result<String?>.success(null);
    }
    final resolved = await _files.pathFor(document);
    if (resolved case Failed(:final failure)) {
      return Result<String?>.failure(failure);
    }
    try {
      return await _extractPdfText(
        resolved.valueOrNull!,
        pageNumber: page.pageNumber,
        password: await _passwordFor(document),
      );
    } finally {
      await _files.release(document);
    }
  }

  @override
  Future<Result<void>> release(MaterializedDocumentPage page) async =>
      page.when(
        authoritative: (_) async => const Result<void>.success(null),
        cached: (_) async => const Result<void>.success(null),
        temporary: (path) async {
          try {
            final file = File(path);
            if (file.existsSync()) await file.delete();
            return const Result<void>.success(null);
          } on Object catch (error) {
            return Result<void>.failure(Failure.storage(debugDetail: '$error'));
          }
        },
      );

  Future<String?> _passwordFor(Document document) async => document.isProtected
      ? (await _secrets.read(
          SecureStorageKeys.pdfPassword(document.id.value),
        )).valueOrNull
      : null;

  String _renderPath(
    Document document,
    DocumentPageHandle page,
    DocumentPageRenderPurpose purpose,
  ) {
    final fingerprint =
        '${document.sizeInBytes}-${document.updatedAt.millisecondsSinceEpoch}';
    return '${_cacheDirectory.path}/document-pages/${document.id.value}/'
        '$fingerprint/${purpose.name}-${page.pageNumber}.png';
  }
}
