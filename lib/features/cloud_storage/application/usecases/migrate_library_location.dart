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
        await _rollback(destinationStore, entries, verified);
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
      final copied = await _copyAndVerify(sourceStore, destinationStore, path);
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
      final marker = await cloud.writeMarker(const CloudLibraryMarker());
      if (marker case Failed(:final failure)) {
        return Result<void>.failure(failure);
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

  Future<Result<void>> _copyAndVerify(
    PublicFileStore source,
    PublicFileStore destination,
    LibraryPath path,
  ) async {
    final sourcePath = await source.materialise(path);
    if (sourcePath case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    try {
      final alreadyExists = await destination.exists(path);
      if (alreadyExists case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
      if (alreadyExists.valueOrNull!) {
        final destinationPath = await destination.materialise(path);
        if (destinationPath case Failed(:final failure)) {
          return Result<void>.failure(failure);
        }
        try {
          final sourceDigest = await _streamedDigest(
            File(sourcePath.valueOrNull!),
          );
          final destinationDigest = await _streamedDigest(
            File(destinationPath.valueOrNull!),
          );
          return sourceDigest == destinationDigest
              ? const Result<void>.success(null)
              : const Result<void>.failure(
                  Failure.storage(debugDetail: 'cloud:conflict'),
                );
        } finally {
          await destination.releaseMaterialised(path);
        }
      }
      final written = await destination.writeFile(
        path,
        sourcePath.valueOrNull!,
      );
      if (written case Failed(:final failure)) {
        // The destination did not exist before this attempt, so any partial
        // output belongs to this migration and is safe to remove for retry.
        await destination.delete(path);
        return Result<void>.failure(failure);
      }
      final destinationPath = await destination.materialise(path);
      if (destinationPath case Failed(:final failure)) {
        await destination.delete(path);
        return Result<void>.failure(failure);
      }
      var digestMatches = false;
      try {
        final sourceDigest = await _streamedDigest(
          File(sourcePath.valueOrNull!),
        );
        final destinationDigest = await _streamedDigest(
          File(destinationPath.valueOrNull!),
        );
        digestMatches = sourceDigest == destinationDigest;
      } finally {
        await destination.releaseMaterialised(path);
      }
      if (!digestMatches) {
        await destination.delete(path);
        return const Result<void>.failure(
          Failure.corruptFile(debugDetail: 'migration digest mismatch'),
        );
      }
    } finally {
      await source.releaseMaterialised(path);
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

  Future<void> _rollback(
    PublicFileStore destination,
    List<PublicEntry> entries,
    Set<String> verified,
  ) async {
    for (final relative in verified) {
      await destination.delete(LibraryPath.parse(relative));
    }
    final directories = entries.where((entry) => entry.isFolder).toList()
      ..sort(
        (a, b) => b.folderSegments.length.compareTo(a.folderSegments.length),
      );
    for (final entry in directories) {
      await destination.deleteFolder(entry.folderSegments);
    }
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
