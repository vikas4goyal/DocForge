/// Storage-location values shared by cloud-storage use cases and UI.
library;

import 'package:equatable/equatable.dart';

/// The single authoritative public-library location.
enum StorageLocation {
  /// The device-local DocScanly folder.
  local('local', 'On this device'),

  /// DocScanly's registered iCloud Documents container.
  iCloud('icloud', 'iCloud Drive');

  const StorageLocation(this.id, this.label);

  /// Stable persisted identifier.
  final String id;

  /// User-facing short label.
  final String label;

  /// Decodes [value], returning null for absent or future values.
  static StorageLocation? fromId(String? value) {
    for (final location in values) {
      if (location.id == value) return location;
    }
    return null;
  }
}

/// Restart-safe phases of a location migration.
enum StorageMigrationPhase {
  /// No migration is active.
  idle,

  /// Payloads are being copied to the destination.
  copying,

  /// Copied payloads are being verified.
  verifying,

  /// The persisted authority is being switched.
  switching,

  /// Verified source payloads are being cleaned up.
  cleaning,

  /// Every migration step completed.
  completed,
}

/// Durable migration progress that can resume after process termination.
class StorageMigrationCheckpoint extends Equatable {
  /// Creates a checkpoint.
  const StorageMigrationCheckpoint({
    required this.source,
    required this.destination,
    required this.phase,
    this.verifiedRelativePaths = const <String>[],
  });

  /// The still-authoritative source.
  final StorageLocation source;

  /// The requested destination.
  final StorageLocation destination;

  /// The last durable phase.
  final StorageMigrationPhase phase;

  /// Payloads whose destination bytes have already been verified.
  final List<String> verifiedRelativePaths;

  @override
  List<Object?> get props => [
    source,
    destination,
    phase,
    verifiedRelativePaths,
  ];
}
