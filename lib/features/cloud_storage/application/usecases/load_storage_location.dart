/// Resolves the one authoritative library root at startup.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/library_location_repository.dart';
import 'package:equatable/equatable.dart';

/// Startup resolution of the authoritative location and current availability.
class LoadedStorageLocation extends Equatable {
  /// Creates a resolution.
  const LoadedStorageLocation({
    required this.location,
    required this.cloudAvailability,
    this.discoveredEstablishedLibrary = false,
  });

  /// The only root normal writes may use.
  final StorageLocation location;

  /// Current iCloud state, even while local is selected.
  final CloudAvailability cloudAvailability;

  /// Whether a valid marker selected iCloud on this device for the first time.
  final bool discoveredEstablishedLibrary;

  /// Whether the selected authority is currently usable.
  bool get isAuthoritativeRootAvailable =>
      location == StorageLocation.local || cloudAvailability.isAvailable;

  @override
  List<Object?> get props => [
    location,
    cloudAvailability,
    discoveredEstablishedLibrary,
  ];
}

/// Loads a persisted choice or discovers an established app-owned library.
class LoadStorageLocation {
  /// Creates the use case.
  const LoadStorageLocation({required this.locations, required this.cloud});

  /// Persisted single-authority state.
  final LibraryLocationRepository locations;

  /// App-owned iCloud container.
  final CloudContainerRepository cloud;

  /// Resolves the location without ever silently replacing selected iCloud.
  Future<Result<LoadedStorageLocation>> call() async {
    final stored = await locations.readLocation();
    if (stored case Failed(:final failure)) {
      return Result<LoadedStorageLocation>.failure(failure);
    }

    final availability = await cloud.availability();
    if (availability case Failed(:final failure)) {
      return Result<LoadedStorageLocation>.failure(failure);
    }
    final snapshot = availability.valueOrNull!;
    final selected = stored.valueOrNull;
    if (selected != null) {
      return Result<LoadedStorageLocation>.success(
        LoadedStorageLocation(location: selected, cloudAvailability: snapshot),
      );
    }

    // An absent preference is the only time automatic discovery is allowed.
    // Existing users with no marker remain local; selected iCloud never falls
    // back here merely because its container is temporarily unavailable.
    if (snapshot.isAvailable) {
      final marker = await cloud.readMarker();
      if (marker case Failed(:final failure)) {
        return Result<LoadedStorageLocation>.failure(failure);
      }
      if (marker.valueOrNull?.isSupported ?? false) {
        final persisted = await locations.writeLocation(StorageLocation.iCloud);
        if (persisted case Failed(:final failure)) {
          return Result<LoadedStorageLocation>.failure(failure);
        }
        return Result<LoadedStorageLocation>.success(
          LoadedStorageLocation(
            location: StorageLocation.iCloud,
            cloudAvailability: snapshot,
            discoveredEstablishedLibrary: true,
          ),
        );
      }
    }

    final persisted = await locations.writeLocation(StorageLocation.local);
    if (persisted case Failed(:final failure)) {
      return Result<LoadedStorageLocation>.failure(failure);
    }
    return Result<LoadedStorageLocation>.success(
      LoadedStorageLocation(
        location: StorageLocation.local,
        cloudAvailability: snapshot,
      ),
    );
  }
}
