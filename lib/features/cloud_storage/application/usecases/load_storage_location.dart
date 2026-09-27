/// Resolves the one authoritative library root at startup.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/resolve_storage_decision.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_library_marker.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_decision.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/library_location_repository.dart';
import 'package:equatable/equatable.dart';

/// Startup decision together with the iCloud snapshot it was based on.
class LoadedStorageLocation extends Equatable {
  /// Creates a resolution.
  const LoadedStorageLocation({
    required this.decision,
    required this.cloudAvailability,
  });

  /// What the composition root must do before building the library.
  final StorageDecision decision;

  /// Current iCloud state, even while the device library is used.
  final CloudAvailability cloudAvailability;

  /// The root that is authoritative right now, before any gate runs.
  ///
  /// A pending migration keeps the device authoritative until its switch; an
  /// unreachable iCloud library stays authoritative although it cannot open.
  StorageLocation get location => switch (decision) {
    UseICloud() || ICloudUnavailable() => StorageLocation.iCloud,
    MigrateToICloud(:final resume) =>
      resume != null &&
              (resume.phase == StorageMigrationPhase.cleaning ||
                  resume.phase == StorageMigrationPhase.completed)
          ? StorageLocation.iCloud
          : StorageLocation.local,
    UseLocal() => StorageLocation.local,
  };

  @override
  List<Object?> get props => [decision, cloudAvailability];
}

/// Gathers the startup inputs, applies [ResolveStorageDecision], and persists
/// the authority it selects.
///
/// The business rule itself lives in [ResolveStorageDecision]; this use case
/// only reads the repositories and performs the decision's side effects.
class LoadStorageLocation {
  /// Creates the use case.
  const LoadStorageLocation({
    required this.locations,
    required this.cloud,
    required this.localStore,
    this.policy = const ResolveStorageDecision(),
  });

  /// Persisted single-authority state.
  final LibraryLocationRepository locations;

  /// App-owned iCloud container.
  final CloudContainerRepository cloud;

  /// The device library, inspected only to learn whether it has content.
  final PublicFileStore localStore;

  /// The pure iCloud-by-default policy.
  final ResolveStorageDecision policy;

  /// Resolves the startup decision.
  ///
  /// [continueLocalThisSession] is true only when the user just chose to
  /// continue on this device after a failed automatic migration; it is never
  /// persisted, so the next launch tries iCloud again.
  ///
  /// Persists iCloud when it is adopted (writing its marker when absent) and
  /// the device when no authority was stored yet. Discards a checkpoint left
  /// by an older release's move to the device. Fails with the repository's
  /// failure when any read or write fails.
  Future<Result<LoadedStorageLocation>> call({
    bool continueLocalThisSession = false,
  }) async {
    final stored = await locations.readLocation();
    if (stored case Failed(:final failure)) {
      return Result<LoadedStorageLocation>.failure(failure);
    }
    final availability = await cloud.availability();
    if (availability case Failed(:final failure)) {
      return Result<LoadedStorageLocation>.failure(failure);
    }
    final snapshot = availability.valueOrNull!;

    final checkpointResult = await locations.readCheckpoint();
    if (checkpointResult case Failed(:final failure)) {
      return Result<LoadedStorageLocation>.failure(failure);
    }
    var checkpoint = checkpointResult.valueOrNull;
    if (checkpoint != null &&
        checkpoint.destination != StorageLocation.iCloud) {
      // Only an older release could move a library to the device. Its source
      // (iCloud) still holds every verified payload, so abandoning the move is
      // safe; the automatic migration merges identical files back without
      // duplicating them.
      final cleared = await locations.clearCheckpoint();
      if (cleared case Failed(:final failure)) {
        return Result<LoadedStorageLocation>.failure(failure);
      }
      checkpoint = null;
    }

    var marker = CloudMarkerState.absent;
    if (snapshot.isAvailable) {
      final read = await cloud.readMarker();
      switch (read) {
        // A marker this release cannot parse was written by a newer one (or
        // damaged). Either way it must not be adopted or overwritten, which
        // the policy guarantees for an unsupported marker.
        case Failed(failure: CorruptFileFailure()):
          marker = CloudMarkerState.unsupported;
        case Failed(:final failure):
          return Result<LoadedStorageLocation>.failure(failure);
        case Success(:final value?):
          marker = value.isSupported
              ? CloudMarkerState.supported
              : CloudMarkerState.unsupported;
        case Success():
          break;
      }
    }

    final hasPayloads = await _localHasContent();
    if (hasPayloads case Failed(:final failure)) {
      return Result<LoadedStorageLocation>.failure(failure);
    }

    final decision = policy(
      StorageDecisionInputs(
        stored: stored.valueOrNull,
        availability: snapshot.status,
        marker: marker,
        localHasPayloads: hasPayloads.valueOrNull!,
        checkpoint: checkpoint,
        continueLocalThisSession: continueLocalThisSession,
      ),
    );

    final applied = await _apply(decision, stored.valueOrNull);
    if (applied case Failed(:final failure)) {
      return Result<LoadedStorageLocation>.failure(failure);
    }
    return Result<LoadedStorageLocation>.success(
      LoadedStorageLocation(decision: decision, cloudAvailability: snapshot),
    );
  }

  Future<Result<void>> _apply(
    StorageDecision decision,
    StorageLocation? stored,
  ) async {
    switch (decision) {
      case UseICloud(:final writeMarker):
        if (writeMarker) {
          final written = await cloud.writeMarker(const CloudLibraryMarker());
          if (written case Failed(:final failure)) {
            return Result<void>.failure(failure);
          }
        }
        if (stored != StorageLocation.iCloud) {
          return locations.writeLocation(StorageLocation.iCloud);
        }
      case UseLocal():
        if (stored == null) {
          return locations.writeLocation(StorageLocation.local);
        }
      case MigrateToICloud() || ICloudUnavailable():
        break;
    }
    return const Result<void>.success(null);
  }

  /// Whether the device library has any file or folder, including Trash.
  ///
  /// Empty folders count: moving them keeps the user's structure, and the
  /// migration handles folders as well as files.
  Future<Result<bool>> _localHasContent() async {
    for (final folders in const [
      <String>[],
      [publicTrashFolderName],
    ]) {
      final listed = await localStore.listRecursive(folders);
      switch (listed) {
        case Success(:final value) when value.isNotEmpty:
          return const Result<bool>.success(true);
        case Success():
        case Failed(failure: NotFoundFailure()):
          continue;
        case Failed(:final failure):
          return Result<bool>.failure(failure);
      }
    }
    return const Result<bool>.success(false);
  }
}
