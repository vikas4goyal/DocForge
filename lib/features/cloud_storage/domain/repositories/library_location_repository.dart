/// Persistence contract for the single authoritative library root.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';

/// Stores non-sensitive root selection and restart-safe migration progress.
abstract interface class LibraryLocationRepository {
  /// Reads the selected location, or null before a selection is established.
  Future<Result<StorageLocation?>> readLocation();

  /// Persists [location] after destination verification.
  Future<Result<void>> writeLocation(StorageLocation location);

  /// Reads any interrupted migration checkpoint.
  Future<Result<StorageMigrationCheckpoint?>> readCheckpoint();

  /// Persists [checkpoint].
  Future<Result<void>> writeCheckpoint(StorageMigrationCheckpoint checkpoint);

  /// Clears migration progress after completion or safe cancellation.
  Future<Result<void>> clearCheckpoint();
}
