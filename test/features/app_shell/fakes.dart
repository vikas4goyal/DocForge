import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';

/// A [DocumentReader] backed by an in-memory list.
///
/// Applies the same visibility and ordering rules as the real reader, so a Home
/// test asserting "archived documents are excluded" is asserting about
/// behaviour the app actually has rather than about the fake.
class FakeDocumentReader implements DocumentReader {
  FakeDocumentReader([List<Document>? initial]) : documents = [...?initial];

  /// The documents this reader returns.
  final List<Document> documents;

  /// When set, every query fails with this failure.
  Failure? failure;

  /// Every query this reader received, for asserting on limits.
  final List<({DocumentFilter filter, int? limit})> queries = [];

  @override
  Future<Result<Document>> findById(DocumentId id) async {
    final match = documents.where((d) => d.id == id);
    return match.isEmpty
        ? const Result<Document>.failure(Failure.notFound())
        : Result<Document>.success(match.first);
  }

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async {
    queries.add((filter: filter, limit: limit));
    if (failure != null) return Result<List<Document>>.failure(failure!);

    final matching = documents
        .where(
          (d) => switch (filter) {
            DocumentFilter.all => !d.isArchived,
            DocumentFilter.favourites => !d.isArchived && d.isFavourite,
            DocumentFilter.archived => d.isArchived,
            DocumentFilter.folder => !d.isArchived && d.folderId == folderId,
          },
        )
        .toList();

    matching.sort(switch (sort) {
      DocumentSort.modifiedDescending => (a, b) => b.updatedAt.compareTo(
        a.updatedAt,
      ),
      DocumentSort.modifiedAscending => (a, b) => a.updatedAt.compareTo(
        b.updatedAt,
      ),
      DocumentSort.createdDescending => (a, b) => b.createdAt.compareTo(
        a.createdAt,
      ),
      DocumentSort.titleAscending => (a, b) => a.title.toLowerCase().compareTo(
        b.title.toLowerCase(),
      ),
    });

    final skipped = matching.skip(offset);
    return Result<List<Document>>.success(
      (limit == null ? skipped : skipped.take(limit)).toList(),
    );
  }

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      const Result<List<DocumentPage>>.success([]);
}

/// A [FolderReader] backed by an in-memory list.
class FakeFolderReader implements FolderReader {
  FakeFolderReader([List<Folder>? initial]) : folders = [...?initial];

  /// The folders this reader returns.
  final List<Folder> folders;

  /// When set, every read fails with this failure.
  Failure? failure;

  @override
  Future<Result<List<Folder>>> all() async => failure != null
      ? Result<List<Folder>>.failure(failure!)
      : Result<List<Folder>>.success(folders);

  @override
  Future<Result<Folder>> findById(FolderId id) async {
    final match = folders.where((f) => f.id == id);
    return match.isEmpty
        ? const Result<Folder>.failure(Failure.notFound())
        : Result<Folder>.success(match.first);
  }
}

/// A [StorageSummaryReader] returning a fixed summary.
class FakeStorageSummaryReader implements StorageSummaryReader {
  FakeStorageSummaryReader([this.value = StorageSummary.empty]);

  /// The summary returned when no failure is set.
  StorageSummary value;

  /// When set, the read fails with this failure.
  Failure? failure;

  @override
  Future<Result<StorageSummary>> summary() async => failure != null
      ? Result<StorageSummary>.failure(failure!)
      : Result<StorageSummary>.success(value);
}
