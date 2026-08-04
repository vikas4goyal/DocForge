/// Isar-backed implementations of the library repositories.
///
/// Every query is expressed as an indexed Isar filter rather than a full scan
/// followed by in-memory filtering: the specs require the library to stay
/// responsive at several thousand documents, and pagination only helps if the
/// database does the narrowing.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/trash.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';
import 'package:doc_scanly/features/document_library/infrastructure/models/isar_entities.dart';
import 'package:isar_community/isar.dart';

/// Runs [body] and converts any thrown error into a storage failure.
///
/// Exceptions must not cross the repository boundary — every caller upward
/// handles a [Failure] instead.
Future<Result<T>> _guard<T>(Future<T> Function() body) async {
  try {
    return Result<T>.success(await body());
  } on Object catch (error) {
    return Result<T>.failure(Failure.storage(debugDetail: '$error'));
  }
}

/// Stores documents in Isar.
class IsarDocumentRepository implements DocumentRepository {
  /// Creates the repository over an open [_isar] instance.
  const IsarDocumentRepository(this._isar);

  final Isar _isar;

  @override
  Future<Result<Document>> findById(DocumentId id) async {
    final result = await _guard(
      () => _isar.documentEntitys.filter().uuidEqualTo(id.value).findFirst(),
    );

    return result.flatMap(
      (entity) => entity == null
          ? const Result<Document>.failure(Failure.notFound())
          : Result<Document>.success(entity.toDomain()),
    );
  }

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) {
    return _guard(() async {
      // Isar's query builder is progressively typed — applying a sort moves it
      // from QAfterFilterCondition to QAfterSortBy — so the sorted query needs
      // its own variable rather than reassigning the filtered one.
      final sorted = _applySort(_applyFilter(filter, folderId), sort);

      final entities = limit == null
          ? await sorted.offset(offset).findAll()
          : await sorted.offset(offset).limit(limit).findAll();

      return entities.map((e) => e.toDomain()).toList();
    });
  }

  @override
  Future<Result<Document>> save(Document document) async {
    final result = await _guard(
      () => _isar.writeTxn(
        // The uuid index is declared `replace: true`, so putting a row with an
        // existing uuid updates it rather than inserting a duplicate.
        () => _isar.documentEntitys.put(DocumentEntity.fromDomain(document)),
      ),
    );

    return result.map((_) => document);
  }

  @override
  Future<Result<void>> delete(DocumentId id) => _guard(
    () => _isar.writeTxn(
      () => _isar.documentEntitys.filter().uuidEqualTo(id.value).deleteAll(),
    ),
  );

  @override
  Future<Result<int>> count({
    DocumentFilter filter = DocumentFilter.all,
    FolderId? folderId,
  }) => _guard(() => _applyFilter(filter, folderId).count());

  @override
  Future<Result<int>> totalSizeInBytes() => _guard(() async {
    final entities = await _isar.documentEntitys.where().findAll();
    return entities.fold<int>(0, (sum, e) => sum + e.sizeInBytes);
  });

  /// Builds the filtered query for [filter].
  ///
  /// Archived documents are excluded everywhere except the archive view — the
  /// single place that rule is applied for queries.
  QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition>
  _applyFilter(DocumentFilter filter, FolderId? folderId) {
    final base = _isar.documentEntitys.filter();

    return switch (filter) {
      DocumentFilter.all => base.trashUuidIsNull().and().isArchivedEqualTo(
        false,
      ),
      DocumentFilter.favourites =>
        base
            .trashUuidIsNull()
            .and()
            .isArchivedEqualTo(false)
            .and()
            .isFavouriteEqualTo(true),
      DocumentFilter.archived => base.trashUuidIsNull().and().isArchivedEqualTo(
        true,
      ),
      DocumentFilter.folder =>
        base
            .trashUuidIsNull()
            .and()
            .isArchivedEqualTo(false)
            .and()
            .folderUuidEqualTo(folderId?.value),
    };
  }

  /// Applies [sort] to [query].
  QueryBuilder<DocumentEntity, DocumentEntity, QAfterSortBy> _applySort(
    QueryBuilder<DocumentEntity, DocumentEntity, QAfterFilterCondition> query,
    DocumentSort sort,
  ) {
    return switch (sort) {
      DocumentSort.modifiedDescending => query.sortByUpdatedAtDesc(),
      DocumentSort.modifiedAscending => query.sortByUpdatedAt(),
      DocumentSort.createdDescending => query.sortByCreatedAtDesc(),
      DocumentSort.titleAscending => query.sortByTitle(),
    };
  }
}

/// Stores folders in Isar.
class IsarFolderRepository implements FolderRepository {
  /// Creates the repository over an open [_isar] instance.
  const IsarFolderRepository(this._isar);

  final Isar _isar;

  @override
  Future<Result<List<Folder>>> all() => _guard(() async {
    final entities = await _isar.folderEntitys
        .filter()
        .trashUuidIsNull()
        .sortByName()
        .findAll();

    // Counts are computed here rather than stored, so they cannot drift out of
    // sync with the documents themselves.
    return Future.wait(
      entities.map((entity) async {
        final count = await _isar.documentEntitys
            .filter()
            .trashUuidIsNull()
            .and()
            .isArchivedEqualTo(false)
            .and()
            .folderUuidEqualTo(entity.uuid)
            .count();
        return entity.toDomain(documentCount: count);
      }),
    );
  });

  @override
  Future<Result<Folder>> findById(FolderId id) async {
    final result = await _guard(() async {
      final entity = await _isar.folderEntitys
          .filter()
          .uuidEqualTo(id.value)
          .findFirst();
      if (entity == null) return null;

      final count = await _isar.documentEntitys
          .filter()
          .trashUuidIsNull()
          .and()
          .isArchivedEqualTo(false)
          .and()
          .folderUuidEqualTo(entity.uuid)
          .count();

      return entity.toDomain(documentCount: count);
    });

    return result.flatMap(
      (folder) => folder == null
          ? const Result<Folder>.failure(Failure.notFound())
          : Result<Folder>.success(folder),
    );
  }

  @override
  Future<Result<Folder?>> findByName(String name) async {
    final result = await _guard(
      () => _isar.folderEntitys
          .filter()
          .trashUuidIsNull()
          .and()
          .nameEqualTo(name)
          .findFirst(),
    );

    return result.map((entity) => entity?.toDomain());
  }

  @override
  Future<Result<Folder?>> findByRelativePath(String relativePath) async {
    final result = await _guard(
      () => _isar.folderEntitys
          .filter()
          .trashUuidIsNull()
          .and()
          .relativePathEqualTo(relativePath)
          .findFirst(),
    );

    return result.map((entity) => entity?.toDomain());
  }

  @override
  Future<Result<Folder>> save(Folder folder) async {
    final result = await _guard(
      () => _isar.writeTxn(
        () => _isar.folderEntitys.put(FolderEntity.fromDomain(folder)),
      ),
    );

    return result.map((_) => folder);
  }

  @override
  Future<Result<void>> delete(FolderId id) => _guard(
    () => _isar.writeTxn(
      () => _isar.folderEntitys.filter().uuidEqualTo(id.value).deleteAll(),
    ),
  );
}

/// Stores recoverable Trash metadata in Isar.
class IsarTrashRepository implements TrashRepository {
  /// Creates the repository over an open [_isar] instance.
  const IsarTrashRepository(this._isar);

  final Isar _isar;

  @override
  Future<Result<TrashEntry>> findById(TrashId id) async {
    final result = await _guard(
      () => _isar.trashEntitys.filter().uuidEqualTo(id.value).findFirst(),
    );
    return result.flatMap(
      (entity) => entity == null
          ? const Result<TrashEntry>.failure(Failure.notFound())
          : Result<TrashEntry>.success(entity.toDomain()),
    );
  }

  @override
  Future<Result<List<TrashEntry>>> all() => _guard(() async {
    final rows = await _isar.trashEntitys
        .where()
        .sortByDeletedAtDesc()
        .findAll();
    return rows.map((row) => row.toDomain()).toList();
  });

  @override
  Future<Result<TrashEntry>> save(TrashEntry entry) async {
    final result = await _guard(
      () => _isar.writeTxn(
        () => _isar.trashEntitys.put(TrashEntity.fromDomain(entry)),
      ),
    );
    return result.map((_) => entry);
  }

  @override
  Future<Result<void>> delete(TrashId id) => _guard(
    () => _isar.writeTxn(
      () => _isar.trashEntitys.filter().uuidEqualTo(id.value).deleteAll(),
    ),
  );

  @override
  Future<Result<List<TrashEntry>>> expiredAt(DateTime now) => _guard(() async {
    final rows = await _isar.trashEntitys
        .filter()
        .expiresAtLessThan(now.toUtc(), include: true)
        .findAll();
    return rows.map((row) => row.toDomain()).toList();
  });

  @override
  Future<Result<int>> count() => _guard(() => _isar.trashEntitys.count());
}

/// Stores pages in Isar.
class IsarPageRepository implements PageRepository {
  /// Creates the repository over an open [_isar] instance.
  const IsarPageRepository(this._isar);

  final Isar _isar;

  @override
  Future<Result<List<DocumentPage>>> forDocument(DocumentId documentId) =>
      _guard(() async {
        final entities = await _isar.pageEntitys
            .filter()
            .documentUuidEqualTo(documentId.value)
            .sortByOrder()
            .findAll();

        return entities.map((e) => e.toDomain()).toList();
      });

  @override
  Future<Result<void>> replaceAll(
    DocumentId documentId,
    List<DocumentPage> pages,
  ) => _guard(
    () => _isar.writeTxn(() async {
      // Replacing wholesale inside one transaction keeps ordering unambiguous:
      // there is no window in which two pages claim the same position.
      await _isar.pageEntitys
          .filter()
          .documentUuidEqualTo(documentId.value)
          .deleteAll();

      await _isar.pageEntitys.putAll(pages.map(PageEntity.fromDomain).toList());
    }),
  );

  @override
  Future<Result<void>> deleteForDocument(DocumentId documentId) => _guard(
    () => _isar.writeTxn(
      () => _isar.pageEntitys
          .filter()
          .documentUuidEqualTo(documentId.value)
          .deleteAll(),
    ),
  );
}
