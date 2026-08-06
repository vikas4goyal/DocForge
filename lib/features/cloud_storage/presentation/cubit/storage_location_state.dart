/// Immutable UI state for iOS library-location selection.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/choose_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:equatable/equatable.dart';

/// Observable storage-selection phase.
enum StorageLocationStatus {
  /// Initial or retry load.
  loading,

  /// Device-local storage is authoritative.
  readyLocal,

  /// iCloud is authoritative and available.
  readyICloud,

  /// A different location awaits destructive migration confirmation.
  confirmationRequired,

  /// Payloads are being copied.
  migrating,

  /// Copied payloads are being verified.
  verifying,

  /// Authority switched successfully.
  completed,

  /// Selected or requested iCloud is unavailable.
  unavailable,

  /// A recoverable operation failed.
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
    this.pendingChoice,
    this.progress = 0,
    this.completedFiles = 0,
    this.totalFiles = 0,
    this.failure,
    this.canCancel = false,
  });

  /// Current presentation phase.
  final StorageLocationStatus status;

  /// Current authoritative location.
  final StorageLocation? location;

  /// Latest iCloud snapshot.
  final CloudAvailability cloudAvailability;

  /// Choice waiting for confirmation or retry.
  final StorageLocationChoice? pendingChoice;

  /// Bounded migration fraction.
  final double progress;

  /// Verified payloads.
  final int completedFiles;

  /// Total payloads.
  final int totalFiles;

  /// Typed recoverable failure.
  final Failure? failure;

  /// Whether cancellation still preserves source authority.
  final bool canCancel;

  /// Returns a copy with explicit field replacements.
  StorageLocationState copyWith({
    StorageLocationStatus? status,
    StorageLocation? location,
    CloudAvailability? cloudAvailability,
    StorageLocationChoice? pendingChoice,
    bool clearPendingChoice = false,
    double? progress,
    int? completedFiles,
    int? totalFiles,
    Failure? failure,
    bool clearFailure = false,
    bool? canCancel,
  }) => StorageLocationState(
    status: status ?? this.status,
    location: location ?? this.location,
    cloudAvailability: cloudAvailability ?? this.cloudAvailability,
    pendingChoice: clearPendingChoice
        ? null
        : pendingChoice ?? this.pendingChoice,
    progress: progress ?? this.progress,
    completedFiles: completedFiles ?? this.completedFiles,
    totalFiles: totalFiles ?? this.totalFiles,
    failure: clearFailure ? null : failure ?? this.failure,
    canCancel: canCancel ?? this.canCancel,
  );

  @override
  List<Object?> get props => [
    status,
    location,
    cloudAvailability,
    pendingChoice,
    progress,
    completedFiles,
    totalFiles,
    failure,
    canCancel,
  ];
}
