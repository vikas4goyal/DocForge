import 'dart:async';
import 'dart:io';

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/trash.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_library/domain/library_rules.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/document_file_store.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';

/// An in-memory [DocumentRepository].
///
/// Applies the same visibility and ordering rules as the Isar implementation by
/// delegating to [DocumentRules], so a use-case test exercised against this
/// fake still reflects production behaviour.
class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository([List<Document>? initial]) {
    for (final document in initial ?? const <Document>[]) {
      documents[document.id] = document;
    }
  }

  final Map<DocumentId, Document> documents = {};

  /// When set, every operation fails with this failure.
  Failure? failure;

  /// When set, every query waits on this before returning.
  ///
  /// Lets a widget test observe the in-flight loading state, which is otherwise
  /// unreachable: an in-memory fake completes within the same frame.
  Completer<void>? gate;

  @override
  Future<Result<Document>> findById(DocumentId id) async {
    if (failure != null) return Result<Document>.failure(failure!);
    final document = documents[id];
    return document == null
        ? const Result<Document>.failure(Failure.notFound())
        : Result<Document>.success(document);
  }

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async {
    if (gate != null) await gate!.future;
    if (failure != null) return Result<List<Document>>.failure(failure!);

    final matching = documents.values
        .where(
          (d) => DocumentRules.matchesFilter(
            d,
            filter,
            folderMatcher: (doc) => doc.folderId == folderId,
          ),
        )
        .toList();

    final ordered = DocumentRules.sorted(matching, sort);
    final skipped = ordered.skip(offset);

    return Result<List<Document>>.success(
      (limit == null ? skipped : skipped.take(limit)).toList(),
    );
  }

  @override
  Future<Result<Document>> save(Document document) async {
    if (failure != null) return Result<Document>.failure(failure!);
    documents[document.id] = document;
    return Result<Document>.success(document);
  }

  @override
  Future<Result<void>> delete(DocumentId id) async {
    if (failure != null) return Result<void>.failure(failure!);
    documents.remove(id);
    return const Result<void>.success(null);
  }

  @override
  Future<Result<int>> count({
    DocumentFilter filter = DocumentFilter.all,
    FolderId? folderId,
  }) async {
    final result = await query(filter: filter, folderId: folderId);
    return result.map((list) => list.length);
  }

  @override
  Future<Result<int>> totalSizeInBytes() async => Result<int>.success(
    documents.values.fold<int>(0, (sum, d) => sum + d.sizeInBytes),
  );
}

/// An in-memory [FolderRepository].
class FakeFolderRepository implements FolderRepository {
  FakeFolderRepository([List<Folder>? initial]) {
    for (final folder in initial ?? const <Folder>[]) {
      folders[folder.id] = folder;
    }
  }

  final Map<FolderId, Folder> folders = {};

  /// When set, every operation fails with this failure.
  Failure? failure;

  @override
  Future<Result<List<Folder>>> all() async => failure != null
      ? Result<List<Folder>>.failure(failure!)
      : Result<List<Folder>>.success(
          folders.values.where((folder) => folder.isVisibleInLibrary).toList(),
        );

  @override
  Future<Result<Folder>> findById(FolderId id) async {
    if (failure != null) return Result<Folder>.failure(failure!);
    final folder = folders[id];
    return folder == null
        ? const Result<Folder>.failure(Failure.notFound())
        : Result<Folder>.success(folder);
  }

  @override
  Future<Result<Folder?>> findByName(String name) async {
    if (failure != null) return Result<Folder?>.failure(failure!);
    final matches = folders.values.where(
      (f) => f.isVisibleInLibrary && f.name.toLowerCase() == name.toLowerCase(),
    );
    return Result<Folder?>.success(matches.isEmpty ? null : matches.first);
  }

  @override
  Future<Result<Folder?>> findByRelativePath(String relativePath) async {
    if (failure != null) return Result<Folder?>.failure(failure!);

    return Result<Folder?>.success(
      folders.values
          .where(
            (folder) =>
                folder.isVisibleInLibrary &&
                folder.relativePath == relativePath,
          )
          .firstOrNull,
    );
  }

  @override
  Future<Result<Folder>> save(Folder folder) async {
    if (failure != null) return Result<Folder>.failure(failure!);
    folders[folder.id] = folder;
    return Result<Folder>.success(folder);
  }

  @override
  Future<Result<void>> delete(FolderId id) async {
    if (failure != null) return Result<void>.failure(failure!);
    folders.remove(id);
    return const Result<void>.success(null);
  }
}

/// An in-memory [PageRepository].
class FakePageRepository implements PageRepository {
  final Map<DocumentId, List<DocumentPage>> pages = {};

  @override
  Future<Result<List<DocumentPage>>> forDocument(DocumentId documentId) async =>
      Result<List<DocumentPage>>.success(pages[documentId] ?? const []);

  @override
  Future<Result<void>> replaceAll(
    DocumentId documentId,
    List<DocumentPage> newPages,
  ) async {
    pages[documentId] = newPages;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> deleteForDocument(DocumentId documentId) async {
    pages.remove(documentId);
    return const Result<void>.success(null);
  }
}

/// An in-memory [TrashRepository].
class FakeTrashRepository implements TrashRepository {
  /// Stored entries by stable identifier.
  final Map<TrashId, TrashEntry> entries = {};

  /// When set, every operation fails with this failure.
  Failure? failure;

  @override
  Future<Result<TrashEntry>> findById(TrashId id) async {
    if (failure != null) return Result<TrashEntry>.failure(failure!);
    final entry = entries[id];
    return entry == null
        ? const Result<TrashEntry>.failure(Failure.notFound())
        : Result<TrashEntry>.success(entry);
  }

  @override
  Future<Result<List<TrashEntry>>> all() async {
    if (failure != null) return Result<List<TrashEntry>>.failure(failure!);
    return Result<List<TrashEntry>>.success(
      entries.values.toList()
        ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt)),
    );
  }

  @override
  Future<Result<TrashEntry>> save(TrashEntry entry) async {
    if (failure != null) return Result<TrashEntry>.failure(failure!);
    entries[entry.id] = entry;
    return Result<TrashEntry>.success(entry);
  }

  @override
  Future<Result<void>> delete(TrashId id) async {
    if (failure != null) return Result<void>.failure(failure!);
    entries.remove(id);
    return const Result<void>.success(null);
  }

  @override
  Future<Result<List<TrashEntry>>> expiredAt(DateTime now) async {
    final loaded = await all();
    return loaded.map(
      (values) => values.where((entry) => entry.isExpiredAt(now)).toList(),
    );
  }

  @override
  Future<Result<int>> count() async => failure != null
      ? Result<int>.failure(failure!)
      : Result<int>.success(entries.length);
}

/// A [DocumentFileStore] that records calls without touching the filesystem.
class FakeDocumentFileStore implements DocumentFileStore {
  final List<DocumentId> deleted = [];
  final List<(DocumentId, DocumentId)> copied = [];

  /// Bytes reported by [totalBytes].
  int bytes = 0;

  /// When set, every operation fails with this failure.
  Failure? failure;

  @override
  Future<Result<Directory>> initialise() async =>
      Result<Directory>.success(Directory.systemTemp);

  @override
  Future<Result<Directory>> directoryFor(DocumentId id) async =>
      Result<Directory>.success(Directory('/documents/${id.value}'));

  @override
  Future<Result<String>> pdfPathFor(DocumentId id) async => failure != null
      ? Result<String>.failure(failure!)
      : Result<String>.success('/documents/${id.value}/document.pdf');

  @override
  Future<Result<String>> pagePathFor(
    DocumentId documentId,
    PageId pageId,
  ) async => Result<String>.success(
    '/documents/${documentId.value}/pages/${pageId.value}.jpg',
  );

  @override
  Future<Result<String>> thumbnailPathFor(
    DocumentId documentId,
    PageId pageId,
  ) async => Result<String>.success(
    '/documents/${documentId.value}/thumbnails/${pageId.value}.jpg',
  );

  @override
  Future<Result<void>> deleteDocument(DocumentId id) async {
    if (failure != null) return Result<void>.failure(failure!);
    deleted.add(id);
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> copyDocument(DocumentId from, DocumentId to) async {
    if (failure != null) return Result<void>.failure(failure!);
    copied.add((from, to));
    return const Result<void>.success(null);
  }

  @override
  Future<Result<int>> totalBytes() async => failure != null
      ? Result<int>.failure(failure!)
      : Result<int>.success(bytes);
}
