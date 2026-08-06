/// Reconciles iCloud metadata with DocScanly's local searchable index.
///
/// This orchestration lives at the composition layer because it deliberately
/// joins cloud-storage and document-library contracts; neither feature imports
/// the other.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/cloud_container_repository.dart';
import 'package:doc_scanly/features/document_library/domain/repositories/library_repositories.dart';

/// Summary of one cloud metadata reconciliation pass.
class CloudReconcileOutcome {
  /// Creates an immutable reconciliation summary.
  const CloudReconcileOutcome({
    this.added = 0,
    this.updated = 0,
    this.removed = 0,
    this.foldersAdded = 0,
    this.foldersRemoved = 0,
  });

  /// Newly indexed PDFs.
  final int added;

  /// Existing PDFs whose path, metadata, or availability changed.
  final int updated;

  /// Index records removed after an external iCloud deletion.
  final int removed;

  /// Newly indexed folders.
  final int foldersAdded;

  /// Folder records removed after an external iCloud deletion.
  final int foldersRemoved;
}

/// Applies bounded iCloud metadata batches without downloading remote files.
class ReconcileCloudLibrary {
  /// Creates the reconciler.
  ReconcileCloudLibrary({
    required this.cloud,
    required this.documents,
    required this.folders,
    required this.pages,
    required this.clock,
    required this.ids,
    this.batchSize = 200,
  }) : assert(batchSize > 0);

  /// App-owned iCloud container metadata.
  final CloudContainerRepository cloud;

  /// Searchable document index.
  final DocumentRepository documents;

  /// Searchable folder index.
  final FolderRepository folders;

  /// Page rows removed with externally deleted documents.
  final PageRepository pages;

  /// Supplies timestamps for metadata that does not expose one.
  final Clock clock;

  /// Supplies local record identities for newly discovered cloud items.
  final IdGenerator ids;

  /// Maximum number of metadata operations yielded as one batch.
  final int batchSize;

  Future<Result<CloudReconcileOutcome>>? _active;

  /// Reconciles once; overlapping triggers share the same in-flight operation.
  Future<Result<CloudReconcileOutcome>> call() {
    final active = _active;
    if (active != null) return active;
    final run = _run();
    _active = run;
    return run.whenComplete(() {
      if (identical(_active, run)) _active = null;
    });
  }

  Future<Result<CloudReconcileOutcome>> _run() async {
    final listed = await cloud.listItems();
    if (listed case Failed(:final failure)) {
      return Result<CloudReconcileOutcome>.failure(failure);
    }

    final visible = listed.valueOrNull!
        .where((item) => !_isReserved(item.relativePath))
        .toList(growable: false);
    final pdfs = visible
        .where(
          (item) =>
              !item.isDirectory &&
              item.relativePath.toLowerCase().endsWith('.pdf'),
        )
        .toList(growable: false);
    final resolvedPdfs = _resolveConflictPaths(pdfs);
    final cloudFolders = visible
        .where((item) => item.isDirectory)
        .map((item) => _normalise(item.relativePath))
        .where((path) => path.isNotEmpty)
        .toSet();

    final current = await documents.query();
    if (current case Failed(:final failure)) {
      return Result<CloudReconcileOutcome>.failure(failure);
    }
    final archived = await documents.query(filter: DocumentFilter.archived);
    if (archived case Failed(:final failure)) {
      return Result<CloudReconcileOutcome>.failure(failure);
    }
    final indexed = <Document>[
      ...current.valueOrNull!,
      ...archived.valueOrNull!,
    ];
    final indexedFolders = await folders.all();
    if (indexedFolders case Failed(:final failure)) {
      return Result<CloudReconcileOutcome>.failure(failure);
    }

    final byResource = <String, Document>{
      for (final document in indexed)
        if (document.cloudResourceIdentifier case final String identity)
          identity: document,
    };
    final byPath = <String, Document>{
      for (final document in indexed) document.relativePath: document,
    };
    final seenDocuments = <DocumentId>{};
    var added = 0;
    var updated = 0;

    for (var start = 0; start < resolvedPdfs.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, resolvedPdfs.length);
      for (final resolved in resolvedPdfs.sublist(start, end)) {
        final item = resolved.item;
        final path = _path(resolved.indexPath);
        final existing = item.resourceIdentifier == null
            ? byPath[path.relative]
            : byResource[item.resourceIdentifier!] ?? byPath[path.relative];
        final availability = _documentAvailability(item.availability);
        if (existing == null) {
          final now = (item.modifiedAt ?? clock.now()).toUtc();
          final saved = await documents.save(
            Document(
              id: DocumentId(ids.generate()),
              title: path.baseName,
              createdAt: now,
              updatedAt: now,
              // Page metadata is derived lazily after the first download. One
              // keeps legacy list/detail invariants valid without fetching bytes.
              pageCount: 1,
              sizeInBytes: item.sizeBytes,
              libraryPath: path,
              cloudResourceIdentifier: item.resourceIdentifier,
              cloudRelativePath: _normalise(item.relativePath),
              contentAvailability: availability,
            ),
          );
          if (saved case Failed(:final failure)) {
            return Result<CloudReconcileOutcome>.failure(failure);
          }
          seenDocuments.add(saved.valueOrNull!.id);
          added++;
        } else {
          seenDocuments.add(existing.id);
          final changed =
              existing.libraryPath != path ||
              existing.sizeInBytes != item.sizeBytes ||
              existing.cloudResourceIdentifier != item.resourceIdentifier ||
              existing.cloudRelativePath != _normalise(item.relativePath) ||
              existing.contentAvailability != availability ||
              (item.modifiedAt != null &&
                  existing.updatedAt != item.modifiedAt!.toUtc());
          if (changed) {
            final saved = await documents.save(
              existing.copyWith(
                title: path.baseName,
                libraryPath: path,
                sizeInBytes: item.sizeBytes,
                updatedAt: item.modifiedAt?.toUtc() ?? existing.updatedAt,
                cloudResourceIdentifier:
                    item.resourceIdentifier ?? existing.cloudResourceIdentifier,
                cloudRelativePath: _normalise(item.relativePath),
                contentAvailability: availability,
              ),
            );
            if (saved case Failed(:final failure)) {
              return Result<CloudReconcileOutcome>.failure(failure);
            }
            updated++;
          }
        }
      }
      // Yield between bounded batches so a several-thousand-item library does
      // not monopolise the UI isolate.
      await Future<void>.delayed(Duration.zero);
    }

    var removed = 0;
    for (final document in indexed.where(
      (document) =>
          document.cloudResourceIdentifier != null &&
          !seenDocuments.contains(document.id),
    )) {
      final pageDelete = await pages.deleteForDocument(document.id);
      if (pageDelete case Failed(:final failure)) {
        return Result<CloudReconcileOutcome>.failure(failure);
      }
      final deleted = await documents.delete(document.id);
      if (deleted case Failed(:final failure)) {
        return Result<CloudReconcileOutcome>.failure(failure);
      }
      removed++;
    }

    final existingFolderByPath = {
      for (final folder in indexedFolders.valueOrNull!)
        _normalise(folder.relativePath): folder,
    };
    var foldersAdded = 0;
    for (final path in cloudFolders.difference(
      existingFolderByPath.keys.toSet(),
    )) {
      final saved = await folders.save(
        Folder(
          id: FolderId(ids.generate()),
          name: path.split('/').last,
          relativePath: path,
          createdAt: clock.now().toUtc(),
        ),
      );
      if (saved case Failed(:final failure)) {
        return Result<CloudReconcileOutcome>.failure(failure);
      }
      foldersAdded++;
    }

    var foldersRemoved = 0;
    for (final entry in existingFolderByPath.entries) {
      if (!cloudFolders.contains(entry.key)) {
        final deleted = await folders.delete(entry.value.id);
        if (deleted case Failed(:final failure)) {
          return Result<CloudReconcileOutcome>.failure(failure);
        }
        foldersRemoved++;
      }
    }

    return Result<CloudReconcileOutcome>.success(
      CloudReconcileOutcome(
        added: added,
        updated: updated,
        removed: removed,
        foldersAdded: foldersAdded,
        foldersRemoved: foldersRemoved,
      ),
    );
  }

  static DocumentContentAvailability _documentAvailability(
    CloudContentAvailability value,
  ) => switch (value) {
    CloudContentAvailability.local ||
    CloudContentAvailability.available => DocumentContentAvailability.available,
    CloudContentAvailability.remote => DocumentContentAvailability.remote,
    CloudContentAvailability.downloading =>
      DocumentContentAvailability.downloading,
    CloudContentAvailability.failed => DocumentContentAvailability.failed,
  };

  /// Assigns deterministic display paths when metadata exposes two distinct
  /// cloud resources at the same relative path.
  ///
  /// The first resource is selected by stable identity rather than enumeration
  /// order. Every additional payload receives a conflict suffix, while the
  /// document's `cloudRelativePath` continues to address the real iCloud item.
  /// Repeating reconciliation therefore finds the same record by resource ID
  /// and never creates another copy or overwrites either payload.
  static List<({CloudItem item, String indexPath})> _resolveConflictPaths(
    List<CloudItem> items,
  ) {
    final sorted = [...items]
      ..sort((left, right) {
        final path = _normalise(
          left.relativePath,
        ).compareTo(_normalise(right.relativePath));
        if (path != 0) return path;
        return (left.resourceIdentifier ?? '').compareTo(
          right.resourceIdentifier ?? '',
        );
      });
    final claimed = <String, String?>{};
    final suffixCounts = <String, int>{};
    final resolved = <({CloudItem item, String indexPath})>[];

    for (final item in sorted) {
      final source = _normalise(item.relativePath);
      final identity = item.resourceIdentifier;
      if (!claimed.containsKey(source)) {
        claimed[source] = identity;
        resolved.add((item: item, indexPath: source));
        continue;
      }
      if (claimed[source] == identity) continue;

      final token = _conflictToken(identity);
      final countKey = '$source\u0000$token';
      final count = (suffixCounts[countKey] ?? 0) + 1;
      suffixCounts[countKey] = count;
      resolved.add((
        item: item,
        indexPath: _conflictPath(source, token, count == 1 ? null : count),
      ));
    }
    return resolved;
  }

  static String _conflictToken(String? identity) {
    final safe = (identity ?? 'cloud')
        .replaceAll(RegExp('[^A-Za-z0-9]'), '')
        .toLowerCase();
    if (safe.isEmpty) return 'cloud';
    return safe.substring(0, safe.length.clamp(0, 8));
  }

  static String _conflictPath(String source, String token, int? sequence) {
    final slash = source.lastIndexOf('/');
    final parent = slash < 0 ? '' : source.substring(0, slash + 1);
    final fileName = slash < 0 ? source : source.substring(slash + 1);
    final dot = fileName.lastIndexOf('.');
    final stem = dot <= 0 ? fileName : fileName.substring(0, dot);
    final extension = dot <= 0 ? '' : fileName.substring(dot);
    final ordinal = sequence == null ? '' : ' $sequence';
    return '$parent$stem (Conflict $token$ordinal)$extension';
  }

  static bool _isReserved(String path) {
    final normalised = _normalise(path).toLowerCase();
    return normalised == '.docscanly-library.json' ||
        normalised == '.docscanly-trash' ||
        normalised.startsWith('.docscanly-trash/');
  }

  static LibraryPath _path(String raw) {
    final segments = _normalise(raw).split('/');
    return LibraryPath.raw(
      folders: segments.sublist(0, segments.length - 1),
      fileName: segments.last,
    );
  }

  static String _normalise(String path) => path
      .replaceAll('\\', '/')
      .split('/')
      .where((segment) => segment.isNotEmpty && segment != '.')
      .join('/');
}
