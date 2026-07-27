/// Shared fakes for the PDF generation tests.
library;

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_forge/features/pdf_generation/domain/repositories/pdf_repository.dart';

/// A composer that records its requests and produces no file.
class FakePdfComposer implements PdfComposer {
  /// Every request it was given, in order.
  final requests = <PdfBuildRequest>[];

  /// When set, every composition fails with this instead.
  Failure? failure;

  /// What a successful composition reports.
  ComposedPdf? result;

  /// Called just before a successful composition returns.
  ///
  /// Lets a test cancel *after* the file exists but before the record is
  /// written, which is the window the orphan-cleanup rule exists to cover.
  void Function()? onCompose;

  @override
  Future<Result<ComposedPdf>> compose(PdfBuildRequest request) async {
    requests.add(request);

    final configured = failure;
    if (configured != null) {
      return Result<ComposedPdf>.failure(configured);
    }

    onCompose?.call();

    return Result<ComposedPdf>.success(
      result ??
          ComposedPdf(
            filePath: request.destinationPath,
            sizeInBytes: 40960,
            pageCount: request.pages.length,
          ),
    );
  }
}

/// A [DocumentWriter] that records what it was asked to store.
class RecordingDocumentWriter implements DocumentWriter {
  /// Documents saved, in order.
  final saved = <Document>[];

  /// Page lists saved, in order.
  final savedPages = <List<DocumentPage>>[];

  /// When set, every write fails with this.
  Failure? failure;

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async {
    final configured = failure;
    if (configured != null) return Result<Document>.failure(configured);

    saved.add(document);
    savedPages.add(pages);
    return Result<Document>.success(document);
  }

  @override
  Future<Result<Document>> updateMetadata(Document document) async {
    final configured = failure;
    if (configured != null) return Result<Document>.failure(configured);

    saved.add(document);
    return Result<Document>.success(document);
  }
}

/// A [DocumentReader] that reports a fixed library size.
class StubDocumentReader implements DocumentReader {
  /// Creates a reader reporting [count] documents.
  StubDocumentReader({this.count = 0, this.failure});

  /// How many documents the library holds.
  final int count;

  /// When set, every query fails with this.
  final Failure? failure;

  /// How many times [query] has been called.
  int queryCount = 0;

  @override
  Future<Result<Document>> findById(DocumentId id) async =>
      const Result<Document>.failure(Failure.notFound());

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async {
    queryCount++;

    final configured = failure;
    if (configured != null) {
      return Result<List<Document>>.failure(configured);
    }

    return Result<List<Document>>.success([
      for (var index = 0; index < count; index++)
        Document(
          id: DocumentId('existing-$index'),
          title: 'Existing $index',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          pageCount: 1,
          sizeInBytes: 1024,
          libraryPath: LibraryPath.parse('Existing $index.pdf'),
        ),
    ]);
  }

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      const Result<List<DocumentPage>>.success([]);
}
