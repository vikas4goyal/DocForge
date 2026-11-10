/// Presentation orchestration for the iOS storage-location status screen.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_status.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the status screen's state: where documents are stored and why.
///
/// It chooses nothing. iCloud is adopted automatically at startup, so the only
/// action is [moveNow], which asks the composition root to rebuild the app
/// through the migration gate.
class StorageLocationCubit extends Cubit<StorageLocationState> {
  /// Creates the Cubit.
  ///
  /// [onMoveNow] re-runs the app's startup composition; it is null where the
  /// composition cannot be rebuilt, which hides nothing but disables the move.
  StorageLocationCubit({required this.loadStatus, this.onMoveNow})
    : super(const StorageLocationState());

  /// Reads the session authority and a fresh iCloud snapshot.
  final LoadStorageStatus loadStatus;

  /// Rebuilds the app so a device library moves through the migration gate.
  final Future<void> Function()? onMoveNow;

  /// Loads the current status.
  Future<void> load() async {
    emit(const StorageLocationState());
    final result = await loadStatus();
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(
          StorageLocationState(
            status: switch ((value.authority, value.availability.isAvailable)) {
              (StorageLocation.iCloud, true) =>
                StorageLocationStatus.iCloudActive,
              (StorageLocation.iCloud, false) =>
                StorageLocationStatus.unavailable,
              (StorageLocation.local, _) => StorageLocationStatus.localFallback,
            },
            location: value.authority,
            cloudAvailability: value.availability,
          ),
        );
      case Failed(:final failure):
        emit(
          StorageLocationState(
            status: StorageLocationStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  /// Starts moving the device library to iCloud when that is possible now.
  Future<void> moveNow() async {
    final move = onMoveNow;
    if (!state.canMoveNow || move == null) return;
    await move();
  }

  /// Reloads the status after a failure or an unavailable iCloud.
  Future<void> retry() => load();
}
