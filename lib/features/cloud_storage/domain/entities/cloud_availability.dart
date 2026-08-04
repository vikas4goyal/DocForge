/// iCloud availability and item-state values.
library;

import 'package:equatable/equatable.dart';

/// Why the registered iCloud container can or cannot be used.
enum CloudAvailabilityStatus {
  /// The registered container is reachable.
  available,

  /// No Apple Account is signed into iCloud Drive.
  signedOut,

  /// iCloud Drive is disabled.
  disabled,

  /// Account or device policy blocks iCloud Drive.
  restricted,

  /// The container is temporarily unreachable for another reason.
  unavailable,
}

/// A platform availability snapshot with a stable status.
class CloudAvailability extends Equatable {
  /// Creates an availability snapshot.
  const CloudAvailability(this.status, {this.debugDetail});

  /// The stable status shown through domain policy.
  final CloudAvailabilityStatus status;

  /// Diagnostic context that must never contain user data.
  final String? debugDetail;

  /// Whether cloud operations can begin.
  bool get isAvailable => status == CloudAvailabilityStatus.available;

  @override
  List<Object?> get props => [status, debugDetail];
}

/// Whether bytes for one cloud-backed item are readable on this device.
enum CloudContentAvailability {
  /// The item belongs to the local library rather than iCloud.
  local,

  /// Metadata is present but bytes are only in iCloud.
  remote,

  /// iCloud is materialising the bytes.
  downloading,

  /// Bytes are readable locally and remain cloud-backed.
  available,

  /// The latest download attempt failed without deleting the item.
  failed,
}

/// One item enumerated from the app-owned iCloud document scope.
class CloudItem extends Equatable {
  /// Creates cloud item metadata.
  const CloudItem({
    required this.relativePath,
    required this.isDirectory,
    required this.availability,
    this.resourceIdentifier,
    this.sizeBytes = 0,
    this.modifiedAt,
  });

  /// Path relative to the iCloud document-scope root.
  final String relativePath;

  /// Whether this item is a directory.
  final bool isDirectory;

  /// Whether its bytes are currently local.
  final CloudContentAvailability availability;

  /// Stable platform identifier, when Foundation provides one.
  final String? resourceIdentifier;

  /// File size reported by metadata.
  final int sizeBytes;

  /// Last modification instant reported by metadata.
  final DateTime? modifiedAt;

  @override
  List<Object?> get props => [
    relativePath,
    isDirectory,
    availability,
    resourceIdentifier,
    sizeBytes,
    modifiedAt,
  ];
}
