/// Presentation orchestration for the startup move of the library into iCloud.
library;

import 'dart:async';

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/migrate_library_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/cloud_migration_gate_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Injectable migration function, supplied by the composition root.
typedef RunStorageMigration =
    Future<Result<void>> Function({
      required StorageLocation source,
      required StorageLocation destination,
      StorageMigrationProgressCallback? onProgress,
      bool Function()? shouldCancel,
    });

/// Owns the migration gate's UI state while [runMigration] moves the device
/// library into iCloud.
///
/// All migration rules (copy, verify, merge, switch, cleanup, resume) live in
/// the migration use case; this Cubit only maps its progress and result to
/// [CloudMigrationGateState].
class CloudMigrationGateCubit extends Cubit<CloudMigrationGateState> {
  /// Creates the Cubit.
  CloudMigrationGateCubit({required this.runMigration})
    : super(const CloudMigrationGateState());

  /// Copy–verify–switch–cleanup migration from the device to iCloud.
  final RunStorageMigration runMigration;

  bool _leaveRequested = false;
  Future<void>? _running;

  /// Starts the move, or restarts it after a failure.
  ///
  /// Does nothing while a move is already running. The migration resumes its
  /// own durable checkpoint, so a retry never duplicates verified files.
  Future<void> start() => _running ??= _run().whenComplete(() {
    _running = null;
  });

  /// Retries after [CloudMigrationGateStatus.failed].
  Future<void> retry() => start();

  /// Asks to continue on this device for this session.
  ///
  /// A running move is cancelled before its switch and rolled back by the
  /// migration use case; this waits for that to finish. Returns true when the
  /// device library is still authoritative and the app may open on it, or
  /// false when the move had already switched to iCloud and completes instead.
  Future<bool> continueOnDevice() async {
    _leaveRequested = true;
    await _running;
    return state.status != CloudMigrationGateStatus.completed;
  }

  Future<void> _run() async {
    _leaveRequested = false;
    emit(const CloudMigrationGateState());
    var switched = false;
    final result = await runMigration(
      source: StorageLocation.local,
      destination: StorageLocation.iCloud,
      shouldCancel: () => _leaveRequested,
      onProgress: (progress) {
        if (isClosed) return;
        switched = progress.phase.index >= StorageMigrationPhase.cleaning.index;
        emit(
          CloudMigrationGateState(
            status: switch (progress.phase) {
              StorageMigrationPhase.idle ||
              StorageMigrationPhase.copying => CloudMigrationGateStatus.copying,
              StorageMigrationPhase.verifying ||
              StorageMigrationPhase.switching =>
                CloudMigrationGateStatus.verifying,
              StorageMigrationPhase.cleaning =>
                CloudMigrationGateStatus.cleaning,
              StorageMigrationPhase.completed =>
                CloudMigrationGateStatus.completed,
            },
            completedFiles: progress.completedFiles,
            totalFiles: progress.totalFiles,
          ),
        );
      },
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(
          CloudMigrationGateState(
            status: CloudMigrationGateStatus.completed,
            completedFiles: state.totalFiles,
            totalFiles: state.totalFiles,
          ),
        );
      // After the switch iCloud already is the authority. A cleanup failure
      // leaves only verified device duplicates, and the retained checkpoint
      // makes the next launch finish them, so the user continues to iCloud.
      case Failed() when switched:
        emit(
          CloudMigrationGateState(
            status: CloudMigrationGateStatus.completed,
            completedFiles: state.totalFiles,
            totalFiles: state.totalFiles,
          ),
        );
      case Failed(:final failure):
        emit(
          CloudMigrationGateState(
            status: CloudMigrationGateStatus.failed,
            completedFiles: state.completedFiles,
            totalFiles: state.totalFiles,
            failure: failure,
          ),
        );
    }
  }
}
