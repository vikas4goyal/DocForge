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
    this.writtenFiles = const <MigrationWrittenFile>[],
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
  /// rollback deletion — see [writtenFiles].
  final List<String> verifiedRelativePaths;

  /// Destination files this migration created, recorded *before* each write.
  ///
  /// A write-ahead record: an entry is added only when its path was absent
  /// and is about to be written, and it is persisted before the write begins.
  /// After any interruption, every file the migration may have put into the
  /// destination is listed, including keep-both conflict copies. Nothing that
  /// belonged to another device ever is.
  ///
  /// Each entry also carries the digest of the bytes the migration wrote. A
  /// cancellation removes a listed file only while its contents still match:
  /// another device may have edited it since, and that edit is theirs.
  final List<MigrationWrittenFile> writtenFiles;

  @override
  List<Object?> get props => [
    source,
    destination,
    phase,
    verifiedRelativePaths,
    writtenFiles,
  ];
}

/// One destination file a migration created, and what it wrote there.
class MigrationWrittenFile extends Equatable {
  /// Creates a record of a file written at [relativePath].
  const MigrationWrittenFile({required this.relativePath, this.digest});

  /// The destination path, relative to the library root.
  final String relativePath;

  /// Digest of the bytes written, or null for an entry recorded by an older
  /// checkpoint format.
  ///
  /// A null digest means the migration cannot prove the file still holds what
  /// it wrote, so a rollback keeps that file rather than guess.
  final int? digest;

  @override
  List<Object?> get props => [relativePath, digest];
}
