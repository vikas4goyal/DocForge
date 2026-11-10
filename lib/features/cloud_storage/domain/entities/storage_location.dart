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
    this.writtenRelativePaths = const <String>[],
  });

  /// The still-authoritative source.
  final StorageLocation source;

  /// The requested destination.
  final StorageLocation destination;

  /// The last durable phase.
  final StorageMigrationPhase phase;

  /// Payloads whose destination bytes have already been verified.
  ///
  /// These are *source* paths. A verified payload may have been satisfied by
  /// an identical file that was already in the destination, so this list says
  /// nothing about who owns the destination file and must never drive a
  /// rollback deletion — see [writtenRelativePaths].
  final List<String> verifiedRelativePaths;

  /// Destination paths this migration created, recorded *before* each write.
  ///
  /// A write-ahead record: a path is added only when it was absent and is
  /// about to be written, and it is persisted before the write begins. So
  /// after any interruption every file the migration may have put into the
  /// destination — including keep-both conflict copies — is listed here, and
  /// nothing that belonged to another device ever is. Cancellation removes
  /// exactly these paths.
  final List<String> writtenRelativePaths;

  @override
  List<Object?> get props => [
    source,
    destination,
    phase,
    verifiedRelativePaths,
    writtenRelativePaths,
  ];
}
