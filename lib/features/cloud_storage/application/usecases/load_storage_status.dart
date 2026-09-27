/// Reads the current storage status without changing the authority.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/cloud_container_repository.dart';
import 'package:equatable/equatable.dart';

/// Where the running app keeps documents, and whether iCloud is usable now.
class StorageStatus extends Equatable {
  /// Creates a status snapshot.
  const StorageStatus({required this.authority, required this.availability});

  /// The root this app session was composed on.
  final StorageLocation authority;

  /// The current iCloud account and container state.
  final CloudAvailability availability;

  @override
  List<Object?> get props => [authority, availability];
}

/// Reports the session's authority together with a fresh iCloud snapshot.
///
/// The authority is fixed when the app is composed, so this use case never
/// persists or switches anything: moving the library happens only through the
/// startup migration gate. That keeps the running session on exactly one root
/// even when iCloud appears or disappears while it runs.
class LoadStorageStatus {
  /// Creates the use case for a session composed on [authority].
  const LoadStorageStatus({required this.authority, required this.cloud});

  /// The root this app session was composed on.
  final StorageLocation authority;

  /// App-owned iCloud container.
  final CloudContainerRepository cloud;

  /// Returns the status, or the repository's failure when iCloud availability
  /// cannot be read.
  Future<Result<StorageStatus>> call() async =>
      (await cloud.availability()).map(
        (availability) =>
            StorageStatus(authority: authority, availability: availability),
      );
}
