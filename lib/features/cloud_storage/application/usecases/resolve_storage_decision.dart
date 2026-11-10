/// The pure iCloud-by-default policy that picks DocScanly's startup authority.
library;

import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_decision.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:equatable/equatable.dart';

/// Whether the registered container holds a DocScanly marker, and whether this
/// release understands it.
enum CloudMarkerState {
  /// No marker exists; iCloud has never been DocScanly's authority here.
  absent,

  /// A marker this release can adopt.
  supported,

  /// A marker written by a newer, incompatible release.
  unsupported,
}

/// Every value the startup policy depends on, gathered by the caller.
class StorageDecisionInputs extends Equatable {
  /// Creates the policy inputs.
  const StorageDecisionInputs({
    required this.stored,
    required this.availability,
    required this.marker,
    required this.localHasPayloads,
    this.checkpoint,
    this.continueLocalThisSession = false,
  });

  /// The persisted authority, or null before one was ever stored.
  final StorageLocation? stored;

  /// The current iCloud account and container status.
  final CloudAvailabilityStatus availability;

  /// The container's marker state; [CloudMarkerState.absent] when unreadable
  /// because iCloud is unavailable.
  final CloudMarkerState marker;

  /// Whether the device library has any active or reserved Trash payload.
  final bool localHasPayloads;

  /// An interrupted migration, when one exists.
  final StorageMigrationCheckpoint? checkpoint;

  /// Whether the user chose to continue on this device for this session after
  /// a failed automatic migration.
  final bool continueLocalThisSession;

  @override
  List<Object?> get props => [
    stored,
    availability,
    marker,
    localHasPayloads,
    checkpoint,
    continueLocalThisSession,
  ];
}

/// Enforces the rule that iCloud is DocScanly's only authority whenever it is
/// available, while never silently abandoning an unreachable iCloud library.
///
/// This is a pure function of [StorageDecisionInputs]: it performs no I/O, so
/// every combination of inputs is covered by unit tests. The caller applies
/// the resulting side effects (persisting the authority, writing a marker).
class ResolveStorageDecision {
  /// Creates the policy.
  const ResolveStorageDecision();

  /// Returns the decision for [inputs].
  ///
  /// The rules are evaluated in order:
  /// 1. An interrupted move to iCloud is resumed while iCloud is available.
  /// 2. A stored iCloud authority is used, or reported unavailable; it never
  ///    falls back to the device.
  /// 3. Otherwise iCloud is adopted when available: directly when the device
  ///    library is empty, through the migration gate when it is not.
  /// 4. Otherwise the device library is used, carrying the iCloud reason.
  StorageDecision call(StorageDecisionInputs inputs) {
    final available = inputs.availability == CloudAvailabilityStatus.available;
    final checkpoint = inputs.checkpoint;

    // Only a move towards iCloud can still be in flight. A checkpoint towards
    // the device was written by an older release's manual "On this device"
    // move; the caller discards it, and this policy ignores it.
    if (checkpoint != null &&
        checkpoint.destination == StorageLocation.iCloud) {
      // Once the switch is recorded, iCloud already is the authority, so an
      // unreachable container is reported rather than bypassed.
      final switched =
          checkpoint.phase == StorageMigrationPhase.cleaning ||
          checkpoint.phase == StorageMigrationPhase.completed ||
          inputs.stored == StorageLocation.iCloud;
      if (available && (switched || !inputs.continueLocalThisSession)) {
        return StorageDecision.migrateToICloud(resume: checkpoint);
      }
      if (switched) {
        return StorageDecision.iCloudUnavailable(reason: inputs.availability);
      }
      return StorageDecision.useLocal(reason: inputs.availability);
    }

    if (inputs.stored == StorageLocation.iCloud) {
      return available
          ? StorageDecision.useICloud(
              writeMarker: inputs.marker == CloudMarkerState.absent,
            )
          : StorageDecision.iCloudUnavailable(reason: inputs.availability);
    }

    if (!available) {
      return StorageDecision.useLocal(reason: inputs.availability);
    }
    if (inputs.continueLocalThisSession) {
      return const StorageDecision.useLocal(
        reason: CloudAvailabilityStatus.available,
      );
    }
    // A newer release owns this container's format. Moving into it could
    // corrupt that library, so the device stays authoritative until updated.
    if (inputs.marker == CloudMarkerState.unsupported) {
      return const StorageDecision.useLocal(
        reason: CloudAvailabilityStatus.unavailable,
      );
    }
    if (inputs.localHasPayloads) {
      return const StorageDecision.migrateToICloud();
    }
    return StorageDecision.useICloud(
      writeMarker: inputs.marker == CloudMarkerState.absent,
    );
  }
}
