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
      final fileCount = entries.where((entry) => !entry.isFolder).length;
      // Reported before cleanup starts, exactly as a fresh run reports it
      // after switching: observers decide whether the source is still
      // authoritative from this phase, and a cleanup that then fails must not
      // look like a move that never switched.
      onProgress?.call(
        StorageMigrationProgress(
          phase: StorageMigrationPhase.cleaning,
          completedFiles: fileCount,
          totalFiles: fileCount,
        ),
      );
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
          completedFiles: fileCount,
          totalFiles: fileCount,
        ),
      );
      return const Result<void>.success(null);
    }

    final resuming =
        resume != null &&
        resume.source == source &&
        resume.destination == destination;
    final verified = resuming
        ? resume.verifiedRelativePaths.toSet()
        : <String>{};
    // Destination files this migration created across every attempt, keyed
    // by path, with the digest of what was written. Only these may ever be
    // deleted by a cancellation, and only while they still hold those bytes.
    final owned = <String, int?>{
      if (resuming)
        for (final file in resume.writtenFiles) file.relativePath: file.digest,
    };

    StorageMigrationCheckpoint checkpointAt(StorageMigrationPhase phase) =>
        StorageMigrationCheckpoint(
          source: source,
          destination: destination,
          phase: phase,
          verifiedRelativePaths: verified.toList()..sort(),
          writtenFiles: [
            for (final path in owned.keys.toList()..sort())
              MigrationWrittenFile(relativePath: path, digest: owned[path]),
          ],
        );

    var phase = StorageMigrationPhase.copying;
    final started = await locations.writeCheckpoint(
      checkpointAt(StorageMigrationPhase.copying),
    );
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
          owned: owned,
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
        recordIntent: (candidate, digest) async {
          // Persisted before the bytes are written: if the process dies
          // mid-write, the next attempt still knows this file is its own, and
          // exactly which bytes make it so.
          owned[candidate.relative] = digest;
          return locations.writeCheckpoint(checkpointAt(phase));
        },
      );
      if (copied case Failed(:final failure)) {
        return Result<void>.failure(failure);
      }
      verified.add(path.relative);
      phase = StorageMigrationPhase.verifying;
      final persisted = await locations.writeCheckpoint(checkpointAt(phase));
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
      checkpointAt(StorageMigrationPhase.switching),
    );
    if (switching case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    final switched = await locations.writeLocation(destination);
    if (switched case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }

    await locations.writeCheckpoint(
      checkpointAt(StorageMigrationPhase.cleaning),
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
  /// interrupted merge resumable without a third copy.
  ///
  /// [recordIntent] is awaited with a path, and the digest of the bytes about
  /// to be written there, immediately before this call creates it — and only
  /// for a path that was absent — so the caller can durably record ownership
  /// ahead of the write. An identical file found at a
  /// candidate is *not* recorded: it may be another device's copy, and if an
  /// earlier attempt of this migration wrote it, that attempt already recorded
  /// it before writing.
  Future<Result<void>> _copyAndVerify(
    PublicFileStore source,
    PublicFileStore destination,
    LibraryPath path, {
    required bool keepBothOnConflict,
    required Future<Result<void>> Function(LibraryPath candidate, int digest)
    recordIntent,
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
            final recorded = await recordIntent(
              candidate,
              await contentDigest(sourceFile),
            );
            if (recorded case Failed(:final failure)) {
              // Never write a file whose ownership could not be recorded: a
              // later cancel would have no way to know it may remove it.
              return Result<void>.failure(failure);
            }
            return await _writeVerified(destination, candidate, sourceFile);
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
      final sourceDigest = await contentDigest(sourceFile);
      final destinationDigest = await contentDigest(
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
  ) async {
    final result = await destination.writeFile(path, sourceFile.path);
    if (result case Failed(:final failure)) {
      // The destination did not exist before this attempt, so any partial
      // output belongs to this migration and is safe to remove for retry.
      await destination.delete(path);
      return Result<void>.failure(failure);
    }
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
  /// Only [owned] files are deleted — paths this migration recorded before
  /// creating them, in this attempt or an interrupted earlier one — and only
  /// while their contents still match the recorded digest. Another device can
  /// edit a file between an interrupted attempt and a cancelled retry; that
  /// edited version is not this migration's to delete. An entry without a
  /// digest (an older checkpoint) cannot be proven unchanged, so it is kept. A verified
  /// path is never deleted on that basis alone: verification also succeeds
  /// against an identical file another device already had there, and a
  /// differing original kept beside a conflict copy is never this migration's
  /// at all, even in a container without a library marker.
  ///
  /// Folders are removed only when [removeFolders] (the destination was not an
  /// established library) *and* they are empty once the owned files are gone.
  /// [PublicFileStore.deleteFolder] is recursive, so an unconditional removal
  /// would delete whatever else lived in the folder.
  Future<void> _rollback(
    PublicFileStore destination,
    List<PublicEntry> entries, {
    required Map<String, int?> owned,
    required bool removeFolders,
  }) async {
    for (final MapEntry(key: relative, value: digest) in owned.entries) {
      if (digest == null) continue;
      final path = LibraryPath.parse(relative);
      if (await _stillHolds(destination, path, digest)) {
        await destination.delete(path);
      }
    }
    if (!removeFolders) return;
    final directories = entries.where((entry) => entry.isFolder).toList()
      ..sort(
        (a, b) => b.folderSegments.length.compareTo(a.folderSegments.length),
      );
    for (final entry in directories) {
      final contents = await destination.listRecursive(entry.folderSegments);
      // Unreadable or non-empty: keep it. A leftover empty folder is
      // harmless; a deleted foreign document is not.
      if (contents case Success(:final value) when value.isEmpty) {
        await destination.deleteFolder(entry.folderSegments);
      }
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

  /// Whether [path] exists in [destination] and holds bytes with [digest].
  ///
  /// Any failure to read it counts as "no": a rollback that cannot prove a
  /// file is its own leaves it in place.
  Future<bool> _stillHolds(
    PublicFileStore destination,
    LibraryPath path,
    int digest,
  ) async {
    final exists = await destination.exists(path);
    if (exists.valueOrNull != true) return false;
    final materialised = await destination.materialise(path);
    final local = materialised.valueOrNull;
    if (local == null) return false;
    try {
      return await contentDigest(File(local)) == digest;
    } on Object {
      return false;
    } finally {
      await destination.releaseMaterialised(path);
    }
  }
}

/// FNV-1a over [file]'s streamed bytes.
///
/// Deterministic corruption detection, and the identity of the bytes a
/// migration wrote, without buffering large PDFs or adding a cryptography
/// dependency.
Future<int> contentDigest(File file) async {
  var hash = 0xcbf29ce484222325;
  await for (final chunk in file.openRead()) {
    for (final byte in chunk) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
    }
  }
  return hash;
}
