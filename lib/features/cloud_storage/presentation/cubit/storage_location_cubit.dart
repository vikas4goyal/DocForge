/// Presentation orchestration for iOS storage location.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/choose_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/migrate_library_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Injectable migration function used by [StorageLocationCubit].
typedef RunStorageMigration =
    Future<Result<void>> Function({
      required StorageLocation source,
      required StorageLocation destination,
      StorageMigrationProgressCallback? onProgress,
      bool Function()? shouldCancel,
    });

/// Drives explicit states while business policy remains in use cases.
class StorageLocationCubit extends Cubit<StorageLocationState> {
  /// Creates the Cubit.
  StorageLocationCubit({
    required this.loadLocation,
    required this.chooseLocation,
    required this.runMigration,
  }) : super(const StorageLocationState());

  /// Startup/discovery policy.
  final LoadStorageLocation loadLocation;

  /// Choice validation policy.
  final ChooseStorageLocation chooseLocation;

  /// Copy–verify–switch–cleanup policy.
  final RunStorageMigration runMigration;

  bool _cancelRequested = false;

  /// Loads current authority and cloud availability.
  Future<void> load() async {
    emit(
      state.copyWith(status: StorageLocationStatus.loading, clearFailure: true),
    );
    final result = await loadLocation();
    switch (result) {
      case Success(:final value):
        final unavailable =
            value.location == StorageLocation.iCloud &&
            !value.cloudAvailability.isAvailable;
        emit(
          state.copyWith(
            status: unavailable
                ? StorageLocationStatus.unavailable
                : value.location == StorageLocation.iCloud
                ? StorageLocationStatus.readyICloud
                : StorageLocationStatus.readyLocal,
            location: value.location,
            cloudAvailability: value.cloudAvailability,
            clearPendingChoice: true,
            clearFailure: true,
            canCancel: false,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: StorageLocationStatus.failure,
            failure: failure,
            canCancel: false,
          ),
        );
    }
  }

  /// Validates [destination] and requests confirmation when it differs.
  Future<void> choose(StorageLocation destination) async {
    final current = state.location;
    if (current == null || current == destination) return;
    final result = await chooseLocation(
      current: current,
      destination: destination,
    );
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: StorageLocationStatus.confirmationRequired,
            pendingChoice: value,
            clearFailure: true,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: StorageLocationStatus.unavailable,
            failure: failure,
          ),
        );
    }
  }

  /// Runs the confirmed migration and resumes its durable checkpoint on retry.
  Future<void> confirm() async {
    final choice = state.pendingChoice;
    if (choice == null) return;
    _cancelRequested = false;
    emit(
      state.copyWith(
        status: StorageLocationStatus.migrating,
        progress: 0,
        completedFiles: 0,
        totalFiles: 0,
        canCancel: true,
        clearFailure: true,
      ),
    );
    final result = await runMigration(
      source: choice.source,
      destination: choice.destination,
      shouldCancel: () => _cancelRequested,
      onProgress: (progress) {
        if (isClosed) return;
        emit(
          state.copyWith(
            status: progress.phase == StorageMigrationPhase.verifying
                ? StorageLocationStatus.verifying
                : progress.phase == StorageMigrationPhase.completed
                ? StorageLocationStatus.completed
                : StorageLocationStatus.migrating,
            progress: progress.fraction,
            completedFiles: progress.completedFiles,
            totalFiles: progress.totalFiles,
            canCancel:
                progress.phase.index < StorageMigrationPhase.switching.index,
          ),
        );
      },
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            status: StorageLocationStatus.completed,
            location: choice.destination,
            progress: 1,
            canCancel: false,
            clearPendingChoice: true,
          ),
        );
      case Failed(:final failure) when failure.isCancellation:
        emit(
          state.copyWith(
            status: choice.source == StorageLocation.local
                ? StorageLocationStatus.readyLocal
                : StorageLocationStatus.readyICloud,
            location: choice.source,
            canCancel: false,
            clearPendingChoice: true,
            clearFailure: true,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: StorageLocationStatus.failure,
            failure: failure,
            canCancel: state.canCancel,
          ),
        );
    }
  }

  /// Requests safe cancellation; the migration use case owns rollback.
  void cancel() {
    if (state.canCancel) _cancelRequested = true;
  }

  /// Retries migration when a choice is pending, otherwise reloads availability.
  Future<void> retry() => state.pendingChoice == null ? load() : confirm();
}
