/// Explicitly replaces an unreachable iCloud authority with the device library.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/library_location_repository.dart';

/// Makes the device library authoritative after the user confirmed it while
/// their iCloud library was unavailable.
///
/// This is the only path from an iCloud authority back to the device, and it
/// runs only on an explicit, confirmed user action: DocScanly never falls back
/// silently. The iCloud payloads and marker stay untouched, so the iCloud
/// library is intact when iCloud returns and the automatic migration merges
/// the device library back into it.
///
/// Any migration checkpoint is discarded. A switched move that was still
/// cleaning would otherwise keep reporting iCloud as the authority; its device
/// files are verified copies of iCloud ones, so they become the device library
/// and merge back without duplicates.
class AdoptDeviceLibrary {
  /// Creates the use case over [locations].
  const AdoptDeviceLibrary(this.locations);

  /// Persisted single-authority state.
  final LibraryLocationRepository locations;

  /// Discards any checkpoint and persists the device as the authority.
  ///
  /// Returns the repository's failure when either write fails; a failed
  /// authority write leaves iCloud selected.
  Future<Result<void>> call() async {
    final cleared = await locations.clearCheckpoint();
    if (cleared case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    return locations.writeLocation(StorageLocation.local);
  }
}
