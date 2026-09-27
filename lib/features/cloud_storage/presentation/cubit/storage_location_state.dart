/// Immutable UI state for the iOS storage-location status screen.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:equatable/equatable.dart';

/// Observable storage-status phase.
enum StorageLocationStatus {
  /// Initial or retry load.
  loading,

  /// iCloud is authoritative and available.
  iCloudActive,

  /// The device library is used; [StorageLocationState.cloudAvailability]
  /// says why.
  localFallback,

  /// iCloud is authoritative but currently unreachable.
  unavailable,

  /// The status could not be read.
  failure,
}

/// Complete immutable state rendered by the storage-location screen.
class StorageLocationState extends Equatable {
  /// Creates a state.
  const StorageLocationState({
    this.status = StorageLocationStatus.loading,
    this.location,
    this.cloudAvailability = const CloudAvailability(
      CloudAvailabilityStatus.unavailable,
    ),
    this.failure,
  });

  /// Current presentation phase.
  final StorageLocationStatus status;

  /// The session's authoritative location, once loaded.
  final StorageLocation? location;

  /// Latest iCloud snapshot.
  final CloudAvailability cloudAvailability;

  /// Typed recoverable failure for [StorageLocationStatus.failure].
  final Failure? failure;

  /// Whether the device library can be moved to iCloud right now.
  bool get canMoveNow =>
      status == StorageLocationStatus.localFallback &&
      cloudAvailability.isAvailable;

  @override
  List<Object?> get props => [status, location, cloudAvailability, failure];
}
