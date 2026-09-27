/// Restart-safe copy–verify–switch–cleanup library migration.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_library_marker.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/library_location_repository.dart';
import 'package:equatable/equatable.dart';

/// Resolves stores already constructed for each possible authority.
abstract interface class LibraryStoreResolver {
  /// Returns the store for [location].
  PublicFileStore resolve(StorageLocation location);
}

/// Explicit resolver with no global mutable root.
class FixedLibraryStoreResolver implements LibraryStoreResolver {
  /// Creates a resolver over both candidate stores.
  const FixedLibraryStoreResolver({required this.local, required this.iCloud});

  /// Device-local store.
  final PublicFileStore local;

  /// Registered iCloud document-scope store.
  final PublicFileStore iCloud;

  @override
  PublicFileStore resolve(StorageLocation location) => switch (location) {
    StorageLocation.local => local,
    StorageLocation.iCloud => iCloud,
  };
}

/// Observable migration progress.
class StorageMigrationProgress extends Equatable {
  /// Creates a progress value.
  const StorageMigrationProgress({
    required this.phase,
    required this.completedFiles,
    required this.totalFiles,
  });

  /// Current durable phase.
  final StorageMigrationPhase phase;

  /// Files copied and verified.
  final int completedFiles;

  /// Files in active and reserved Trash trees.
  final int totalFiles;

  /// Bounded fraction suitable for presentation.
  double get fraction => totalFiles == 0 ? 1 : completedFiles / totalFiles;

  @override
  List<Object?> get props => [phase, completedFiles, totalFiles];
}

/// Progress callback for location migration.
typedef StorageMigrationProgressCallback =
    void Function(StorageMigrationProgress progress);

/// Returns the [ordinal]th keep-both name for [path] in the same folder.
///
/// `Scan.pdf` becomes `Scan (Conflict device).pdf`, then
/// `Scan (Conflict device 2).pdf`, and so on. The wording differs from the
/// reconciler's index-only `(Conflict <token>)` names so the two can never
/// collide. A long base name is shortened to keep the result a legal name.
LibraryPath conflictCopyPath(LibraryPath path, int ordinal) {
  assert(ordinal > 0, 'ordinal 0 is the original path');
  final suffix = ordinal == 1
      ? ' (Conflict device)'
      : ' (Conflict device $ordinal)';
  final extension = path.fileName.substring(path.baseName.length);
  final room = LibraryPath.maxNameLength - suffix.length - extension.length;
  final base = path.baseName.length > room
      ? path.baseName.substring(0, room).trimRight()
      : path.baseName;
  return path.withFileName('$base$suffix$extension');
}

/// Performs a durable migration while keeping exactly one authority.
class MigrateLibraryLocation {
  /// Creates the migration use case.
  const MigrateLibraryLocation({
    required this.locations,
    required this.stores,
    required this.cloud,
  });

  /// Durable selection and checkpoints.
  final LibraryLocationRepository locations;

  /// Candidate stores, constructed by the composition root.
  final LibraryStoreResolver stores;

  /// Marker and download operations for the cloud root.
  final CloudContainerRepository cloud;

  /// Copies and verifies all payloads before switching [destination].
  Future<Result<void>> call({
    required StorageLocation source,
    required StorageLocation destination,
    StorageMigrationProgressCallback? onProgress,
    bool Function()? shouldCancel,
  }) async {
    if (source == destination) return const Result<void>.success(null);

    final cloudAvailable = await _requireCloudWhenInvolved(
      source: source,
      destination: destination,
    );
    if (cloudAvailable case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }

    final sourceStore = stores.resolve(source);
    final destinationStore = stores.resolve(destination);
    final initialized = await destinationStore.initialise();
    if (initialized case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }

    final inventory = await _entries(sourceStore);
    if (inventory case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    final entries = inventory.valueOrNull!;
    final directories = entries.where((entry) => entry.isFolder).toList()
      ..sort(
        (a, b) => a.folderSegments.length.compareTo(b.folderSegments.length),
      );
    final files = entries.where((entry) => !entry.isFolder).toList()
      ..sort((a, b) => a.path!.relative.compareTo(b.path!.relative));

    // Merging into a library that already exists (another device's, or an
    // earlier install's) must never delete anything it did not write itself.
    final established = await _destinationEstablished(destination);
    if (established case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    final merge = established.valueOrNull!;
    final written = <LibraryPath>{};

    for (final directory in directories) {
      final created = await destinationStore.createFolder(
        directory.folderSegments,
      );
      if (created case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
    }

    final previous = await locations.readCheckpoint();
    if (previous case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    final resume = previous.valueOrNull;

    if (resume != null &&
        resume.source == source &&
        resume.destination == destination &&
        resume.phase == StorageMigrationPhase.cleaning) {
      // The authority already switched. A retry must only finish forward
      // cleanup; attempting to copy back from a partly-cleaned source can
      // neither restore authority nor prove a rollback is safe.
      final cleaned = await _cleanup(sourceStore, entries);
      if (cleaned case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
      if (source == StorageLocation.iCloud) {
        final marker = await cloud.deleteMarker();
        if (marker case Failed(:final failure)) {
          return Result<void>.failure(failure);
        }
      }
      final cleared = await locations.clearCheckpoint();
      if (cleared case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
      onProgress?.call(
        StorageMigrationProgress(
          phase: StorageMigrationPhase.completed,
          completedFiles: entries.where((entry) => !entry.isFolder).length,
          totalFiles: entries.where((entry) => !entry.isFolder).length,
        ),
      );
      return const Result<void>.success(null);
    }

    final verified =
        resume != null &&
            resume.source == source &&
            resume.destination == destination
        ? resume.verifiedRelativePaths.toSet()
        : <String>{};

    var checkpoint = StorageMigrationCheckpoint(
      source: source,
      destination: destination,
      phase: StorageMigrationPhase.copying,
      verifiedRelativePaths: verified.toList()..sort(),
    );
    final started = await locations.writeCheckpoint(checkpoint);
    if (started case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }

    onProgress?.call(
      StorageMigrationProgress(
        phase: StorageMigrationPhase.copying,
        completedFiles: verified.length,
        totalFiles: files.length,
      ),
    );

    for (final entry in files) {
      final path = entry.path!;
      if (shouldCancel?.call() ?? false) {
        await _rollback(
          destinationStore,
          entries,
          verified: merge ? const {} : verified,
          written: written,
          removeFolders: !merge,
        );
        await locations.clearCheckpoint();
        return const Result<void>.failure(Failure.cancelled());
      }
      if (source == StorageLocation.iCloud) {
        final downloaded = await cloud.ensureDownloaded(path.relative);
        if (downloaded case Failed(:final failure)) {
          return Result<void>.failure(failure);
        }
      }
      final stillAvailable = await _requireCloudWhenInvolved(
        source: source,
        destination: destination,
      );
      if (stillAvailable case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
      final copied = await _copyAndVerify(
        sourceStore,
        destinationStore,
        path,
        keepBothOnConflict: destination == StorageLocation.iCloud,
        written: written,
      );
      if (copied case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
      verified.add(path.relative);
      checkpoint = StorageMigrationCheckpoint(
        source: source,
        destination: destination,
        phase: StorageMigrationPhase.verifying,
        verifiedRelativePaths: verified.toList()..sort(),
      );
      final persisted = await locations.writeCheckpoint(checkpoint);
      if (persisted case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
      onProgress?.call(
        StorageMigrationProgress(
          phase: StorageMigrationPhase.verifying,
          completedFiles: verified.length,
          totalFiles: files.length,
        ),
      );
    }

    final availableBeforeSwitch = await _requireCloudWhenInvolved(
      source: source,
      destination: destination,
    );
    if (availableBeforeSwitch case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }

    if (destination == StorageLocation.iCloud) {
      // An established marker identifies the library other devices already
      // discovered; it is kept as is so the merged library stays that library.
      final existing = await cloud.readMarker();
      if (existing case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
      if (existing.valueOrNull == null) {
        final marker = await cloud.writeMarker(const CloudLibraryMarker());
        if (marker case Failed(:final failure)) {
          return Result<void>.failure(failure);
        }
      }
    }

    final switching = await locations.writeCheckpoint(
      StorageMigrationCheckpoint(
        source: source,
        destination: destination,
        phase: StorageMigrationPhase.switching,
        verifiedRelativePaths: verified.toList()..sort(),
      ),
    );
    if (switching case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    final switched = await locations.writeLocation(destination);
    if (switched case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }

    await locations.writeCheckpoint(
      StorageMigrationCheckpoint(
        source: source,
        destination: destination,
        phase: StorageMigrationPhase.cleaning,
        verifiedRelativePaths: verified.toList()..sort(),
      ),
    );
    onProgress?.call(
      StorageMigrationProgress(
        phase: StorageMigrationPhase.cleaning,
        completedFiles: files.length,
        totalFiles: files.length,
      ),
    );

    final cleaned = await _cleanup(sourceStore, entries);
    if (cleaned case Failed(:final failure)) {
      // Authority has switched; retaining the checkpoint makes cleanup safely
      // retryable and avoids a dangerous attempt to switch back implicitly.
      return Result<void>.failure(failure);
    }
    if (source == StorageLocation.iCloud) {
      final marker = await cloud.deleteMarker();
      if (marker case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
    }
    final cleared = await locations.clearCheckpoint();
    if (cleared case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    onProgress?.call(
      StorageMigrationProgress(
        phase: StorageMigrationPhase.completed,
        completedFiles: files.length,
        totalFiles: files.length,
      ),
    );
    return const Result<void>.success(null);
  }

  Future<Result<List<PublicEntry>>> _entries(PublicFileStore store) async {
    final active = await store.listRecursive(const []);
    if (active case Failed(:final failure)) {
      return Result<List<PublicEntry>>.failure(failure);
    }
    final all = [...active.valueOrNull!];
    final trash = await store.listRecursive(const [publicTrashFolderName]);
    if (trash case Success(:final value)) {
      all
        ..add(
          const PublicEntry(
            kind: PublicEntryKind.folder,
            name: publicTrashFolderName,
            folders: [],
          ),
        )
        ..addAll(value);
    }
    if (trash case Failed(
      failure: final failure,
    ) when failure is! NotFoundFailure) {
      return Result<List<PublicEntry>>.failure(failure);
    }
    return Result<List<PublicEntry>>.success(all);
  }

  /// Copies [path] into [destination] and proves the bytes match.
  ///
  /// An identical file already at [path] counts as verified. A different one
  /// fails with `cloud:conflict`, unless [keepBothOnConflict] is set: then the
  /// source is copied beside it under the first free conflict name. Probing
  /// names in a fixed order and accepting an identical earlier copy keeps an
  /// interrupted merge resumable without a third copy. Every path this call
  /// creates is added to [written].
  Future<Result<void>> _copyAndVerify(
    PublicFileStore source,
    PublicFileStore destination,
    LibraryPath path, {
    required bool keepBothOnConflict,
    required Set<LibraryPath> written,
  }) async {
    final sourcePath = await source.materialise(path);
    if (sourcePath case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    try {
      final sourceFile = File(sourcePath.valueOrNull!);
      // Reserved Trash payloads are addressed by their exact path from the
      // device index, so they can never be renamed to keep both.
      final canKeepBoth =
          keepBothOnConflict &&
          path.folders.firstOrNull != publicTrashFolderName;
      for (var ordinal = 0; ; ordinal++) {
        final candidate = ordinal == 0 ? path : conflictCopyPath(path, ordinal);
        final present = await _matchesExisting(
          destination,
          candidate,
          sourceFile,
        );
        switch (present) {
          case Failed(:final failure):
            return Result<void>.failure(failure);
          case Success(value: true):
            return const Result<void>.success(null);
          case Success(value: false) when canKeepBoth:
            continue;
          case Success(value: false):
            return const Result<void>.failure(
              Failure.storage(debugDetail: 'cloud:conflict'),
            );
          case Success(value: null):
            return await _writeVerified(
              destination,
              candidate,
              sourceFile,
              written,
            );
        }
      }
    } finally {
      await source.releaseMaterialised(path);
    }
  }

  /// Whether [candidate] holds [sourceFile]'s bytes: null when absent.
  Future<Result<bool?>> _matchesExisting(
    PublicFileStore destination,
    LibraryPath candidate,
    File sourceFile,
  ) async {
    final exists = await destination.exists(candidate);
    if (exists case Failed(:final failure)) {
      return Result<bool?>.failure(failure);
    }
    if (!exists.valueOrNull!) return const Result<bool?>.success(null);
    final destinationPath = await destination.materialise(candidate);
    if (destinationPath case Failed(:final failure)) {
      return Result<bool?>.failure(failure);
    }
    try {
      final sourceDigest = await _streamedDigest(sourceFile);
      final destinationDigest = await _streamedDigest(
        File(destinationPath.valueOrNull!),
      );
      return Result<bool?>.success(sourceDigest == destinationDigest);
    } finally {
      await destination.releaseMaterialised(candidate);
    }
  }

  Future<Result<void>> _writeVerified(
    PublicFileStore destination,
    LibraryPath path,
    File sourceFile,
    Set<LibraryPath> written,
  ) async {
    final result = await destination.writeFile(path, sourceFile.path);
    if (result case Failed(:final failure)) {
      // The destination did not exist before this attempt, so any partial
      // output belongs to this migration and is safe to remove for retry.
      await destination.delete(path);
      return Result<void>.failure(failure);
    }
    written.add(path);
    final matches = await _matchesExisting(destination, path, sourceFile);
    if (matches case Failed(:final failure)) {
      await destination.delete(path);
      return Result<void>.failure(failure);
    }
    if (matches.valueOrNull != true) {
      await destination.delete(path);
      return const Result<void>.failure(
        Failure.corruptFile(debugDetail: 'migration digest mismatch'),
      );
    }
    return const Result<void>.success(null);
  }

  Future<Result<void>> _requireCloudWhenInvolved({
    required StorageLocation source,
    required StorageLocation destination,
  }) async {
    if (source != StorageLocation.iCloud &&
        destination != StorageLocation.iCloud) {
      return const Result<void>.success(null);
    }
    final availability = await cloud.availability();
    if (availability case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    return availability.valueOrNull!.isAvailable
        ? const Result<void>.success(null)
        : const Result<void>.failure(
            Failure.storage(debugDetail: 'icloud unavailable during migration'),
          );
  }

  Future<Result<void>> _cleanup(
    PublicFileStore store,
    List<PublicEntry> entries,
  ) async {
    for (final entry in entries.where((entry) => !entry.isFolder)) {
      final removed = await store.delete(entry.path!);
      if (removed case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
    }
    final directories = entries.where((entry) => entry.isFolder).toList()
      ..sort(
        (a, b) => b.folderSegments.length.compareTo(a.folderSegments.length),
      );
    for (final entry in directories) {
      final removed = await store.deleteFolder(entry.folderSegments);
      if (removed case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
    }
    return const Result<void>.success(null);
  }

  /// Removes what a cancelled migration put into [destination].
  ///
  /// [verified] and the folders are only removed when the destination was not
  /// an established library; otherwise only this run's own [written] files
  /// are, because every other file there belongs to that library.
  Future<void> _rollback(
    PublicFileStore destination,
    List<PublicEntry> entries, {
    required Set<String> verified,
    required Set<LibraryPath> written,
    required bool removeFolders,
  }) async {
    for (final path in written) {
      await destination.delete(path);
    }
    for (final relative in verified) {
      await destination.delete(LibraryPath.parse(relative));
    }
    if (!removeFolders) return;
    final directories = entries.where((entry) => entry.isFolder).toList()
      ..sort(
        (a, b) => b.folderSegments.length.compareTo(a.folderSegments.length),
      );
    for (final entry in directories) {
      await destination.deleteFolder(entry.folderSegments);
    }
  }

  /// Whether [destination] already holds an established DocScanly library.
  ///
  /// Only an iCloud container carries a marker; an unreadable one is treated
  /// as established so a failure can never widen what a rollback deletes.
  Future<Result<bool>> _destinationEstablished(
    StorageLocation destination,
  ) async {
    if (destination != StorageLocation.iCloud) {
      return const Result<bool>.success(false);
    }
    final marker = await cloud.readMarker();
    return switch (marker) {
      Success(:final value) => Result<bool>.success(value != null),
      Failed() => const Result<bool>.success(true),
    };
  }

  /// FNV-1a over streamed bytes: deterministic corruption detection without
  /// buffering large PDFs or adding a new cryptography dependency.
  Future<int> _streamedDigest(File file) async {
    var hash = 0xcbf29ce484222325;
    await for (final chunk in file.openRead()) {
      for (final byte in chunk) {
        hash ^= byte;
        hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
      }
    }
    return hash;
  }
}
