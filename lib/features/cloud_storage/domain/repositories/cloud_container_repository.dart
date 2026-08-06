/// Contracts for the app-owned iCloud Documents container.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_library_marker.dart';

/// Progress emitted while iCloud materialises one file.
typedef CloudDownloadProgress = void Function(double progress);

/// Accesses iCloud without exposing MethodChannel or Foundation types.
abstract interface class CloudContainerRepository {
  /// Returns current account/container availability.
  Future<Result<CloudAvailability>> availability();

  /// Returns the container's document-scope root path, or null when unavailable.
  Future<Result<String?>> documentRootPath();

  /// Reads the versioned app-owned library marker.
  Future<Result<CloudLibraryMarker?>> readMarker();

  /// Writes [marker] into the app-owned container.
  Future<Result<void>> writeMarker(CloudLibraryMarker marker);

  /// Removes the marker when iCloud ceases to be authoritative.
  Future<Result<void>> deleteMarker();

  /// Enumerates metadata below the document-scope root.
  Future<Result<List<CloudItem>>> listItems();

  /// Makes [relativePath] readable locally, reporting bounded [onProgress].
  Future<Result<void>> ensureDownloaded(
    String relativePath, {
    CloudDownloadProgress? onProgress,
  });

  /// Returns external folder paths explicitly selected for one import.
  Future<Result<List<String>>> pickImportFolder();

  /// Releases security-scoped access obtained for [paths].
  Future<Result<void>> releaseImportFolder(List<String> paths);

  /// Emits when the signed-in iCloud identity changes.
  Stream<void> get identityChanges;
}
