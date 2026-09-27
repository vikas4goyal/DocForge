/// Immutable UI state for the startup move of the library into iCloud.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:equatable/equatable.dart';

/// Observable phase of the migration gate.
enum CloudMigrationGateStatus {
  /// The migration is starting and has not reported an inventory yet.
  preparing,

  /// Payloads are being copied into iCloud.
  copying,

  /// Copied payloads are being verified.
  verifying,

  /// iCloud is authoritative; the device copies are being removed.
  cleaning,

  /// The library is in iCloud and the app may open on it.
  completed,

  /// The move stopped before the switch; the device is still authoritative.
  failed,
}

/// Complete immutable state rendered by the migration gate.
class CloudMigrationGateState extends Equatable {
  /// Creates a state.
  const CloudMigrationGateState({
    this.status = CloudMigrationGateStatus.preparing,
    this.completedFiles = 0,
    this.totalFiles = 0,
    this.failure,
  });

  /// Current phase.
  final CloudMigrationGateStatus status;

  /// Payloads copied and verified so far.
  final int completedFiles;

  /// Payloads in the device library's active and Trash trees.
  final int totalFiles;

  /// Why the move stopped; set only for [CloudMigrationGateStatus.failed].
  final Failure? failure;

  /// Bounded completion fraction for the progress indicator.
  double get progress => switch (status) {
    CloudMigrationGateStatus.cleaning ||
    CloudMigrationGateStatus.completed => 1,
    _ => totalFiles == 0 ? 0 : (completedFiles / totalFiles).clamp(0, 1),
  };

  /// Whether a move is still running and can be left safely.
  bool get isRunning =>
      status == CloudMigrationGateStatus.preparing ||
      status == CloudMigrationGateStatus.copying ||
      status == CloudMigrationGateStatus.verifying;

  @override
  List<Object?> get props => [status, completedFiles, totalFiles, failure];
}
