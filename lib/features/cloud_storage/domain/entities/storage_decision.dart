/// The startup authority decision for DocScanly's iOS library.
library;

import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage_decision.freezed.dart';

/// What the composition root must do before it builds the library.
///
/// Exactly one variant applies at each launch, so the composition root can
/// switch on it exhaustively and never compose against two roots.
@freezed
sealed class StorageDecision with _$StorageDecision {
  /// Composes on the app-owned iCloud root now.
  ///
  /// [writeMarker] is true when iCloud becomes authoritative for the first
  /// time on this container and its marker must be created.
  const factory StorageDecision.useICloud({@Default(false) bool writeMarker}) =
      UseICloud;

  /// Moves the device library into iCloud through the startup gate first.
  ///
  /// [resume] carries an interrupted migration's checkpoint, when one exists.
  const factory StorageDecision.migrateToICloud({
    StorageMigrationCheckpoint? resume,
  }) = MigrateToICloud;

  /// Composes on the device library because iCloud cannot be used.
  ///
  /// [reason] is the iCloud status that caused the fallback; it is
  /// [CloudAvailabilityStatus.available] only for a session in which the user
  /// explicitly continued on this device.
  const factory StorageDecision.useLocal({
    required CloudAvailabilityStatus reason,
  }) = UseLocal;

  /// iCloud is authoritative but unreachable; the app must not fall back.
  const factory StorageDecision.iCloudUnavailable({
    required CloudAvailabilityStatus reason,
  }) = ICloudUnavailable;
}
