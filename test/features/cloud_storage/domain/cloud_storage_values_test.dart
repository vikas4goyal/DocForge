import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_library_marker.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/failures/cloud_storage_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('storage locations decode only stable identifiers', () {
    expect(StorageLocation.fromId('local'), StorageLocation.local);
    expect(StorageLocation.fromId('icloud'), StorageLocation.iCloud);
    expect(StorageLocation.fromId('future'), isNull);
    expect(StorageLocation.fromId(null), isNull);
  });

  test('marker equality and version validation are deterministic', () {
    expect(const CloudLibraryMarker(), const CloudLibraryMarker());
    expect(const CloudLibraryMarker().isSupported, isTrue);
    expect(const CloudLibraryMarker(schemaVersion: 2).isSupported, isFalse);
    expect(
      const CloudLibraryMarker(libraryIdentifier: 'another').isSupported,
      isFalse,
    );
    final marker = CloudLibraryMarker(
      schemaVersion: int.parse('1'),
      libraryIdentifier: ['docscanly', 'library'].join('-'),
    );
    expect(marker.hashCode, marker.hashCode);
  });

  test('cloud values use value equality', () {
    final signedOut = CloudAvailabilityStatus.values.firstWhere(
      (status) => status.name == 'signedOut',
    );
    final detail = ['signed', 'out'].join('-');
    expect(
      CloudAvailability(signedOut, debugDetail: detail),
      CloudAvailability(signedOut, debugDetail: detail),
    );
    expect(
      CloudItem(
        relativePath: 'Folder/a.pdf',
        isDirectory: false,
        availability: CloudContentAvailability.remote,
        resourceIdentifier: 'resource-a',
        sizeBytes: 42,
        modifiedAt: DateTime.utc(2026),
      ),
      CloudItem(
        relativePath: 'Folder/a.pdf',
        isDirectory: false,
        availability: CloudContentAvailability.remote,
        resourceIdentifier: 'resource-a',
        sizeBytes: 42,
        modifiedAt: DateTime.utc(2026),
      ),
    );
  });

  test('loaded authority uses value equality and availability policy', () {
    final availableStatus = CloudAvailabilityStatus.values.firstWhere(
      (status) => status.name == 'available',
    );
    final available = CloudAvailability(availableStatus);
    expect(
      LoadedStorageLocation(
        location: StorageLocation.iCloud,
        cloudAvailability: available,
        discoveredEstablishedLibrary: true,
      ),
      LoadedStorageLocation(
        location: StorageLocation.iCloud,
        cloudAvailability: available,
        discoveredEstablishedLibrary: true,
      ),
    );
    expect(
      LoadedStorageLocation(
        location: StorageLocation.local,
        cloudAvailability: CloudAvailability(
          CloudAvailabilityStatus.values.firstWhere(
            (status) => status.name == 'signedOut',
          ),
        ),
      ).isAuthoritativeRootAvailable,
      isTrue,
    );
  });

  test('migration checkpoints use value equality', () {
    expect(
      const StorageMigrationCheckpoint(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
        phase: StorageMigrationPhase.verifying,
        verifiedRelativePaths: ['a.pdf'],
      ),
      const StorageMigrationCheckpoint(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
        phase: StorageMigrationPhase.verifying,
        verifiedRelativePaths: ['a.pdf'],
      ),
    );
  });

  test('cloud failures contain only stable recovery information', () {
    final issue = CloudStorageIssue.values.firstWhere(
      (candidate) => candidate.name == 'downloadFailed',
    );
    final failure = CloudStorageFailure(issue, debugDetail: 'offline');

    expect(failure, CloudStorageFailure(issue, debugDetail: 'offline'));
    expect(failure.hashCode, isNot(0));
    expect(
      (failure.toFailure() as StorageFailure).debugDetail,
      'cloud:downloadFailed:offline',
    );
  });
}
