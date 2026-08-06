/// Validates an explicit storage-location choice before confirmation.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/cloud_container_repository.dart';
import 'package:equatable/equatable.dart';

/// A user-confirmable migration request.
class StorageLocationChoice extends Equatable {
  /// Creates a choice from [source] to [destination].
  const StorageLocationChoice({
    required this.source,
    required this.destination,
  });

  /// Current authority.
  final StorageLocation source;

  /// Requested authority.
  final StorageLocation destination;

  /// Whether any migration is required.
  bool get changesLocation => source != destination;

  @override
  List<Object?> get props => [source, destination];
}

/// Checks availability but leaves migration and persistence to their use case.
class ChooseStorageLocation {
  /// Creates the use case.
  const ChooseStorageLocation(this.cloud);

  /// App-owned cloud state.
  final CloudContainerRepository cloud;

  /// Validates [destination] and returns the request the UI may confirm.
  Future<Result<StorageLocationChoice>> call({
    required StorageLocation current,
    required StorageLocation destination,
  }) async {
    if (destination == StorageLocation.iCloud) {
      final availability = await cloud.availability();
      if (availability case Failed(:final failure)) {
        return Result<StorageLocationChoice>.failure(failure);
      }
      if (!availability.valueOrNull!.isAvailable) {
        return const Result<StorageLocationChoice>.failure(
          Failure.storage(debugDetail: 'cloud:unavailable'),
        );
      }
    }
    return Result<StorageLocationChoice>.success(
      StorageLocationChoice(source: current, destination: destination),
    );
  }
}
