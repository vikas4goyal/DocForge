/// Explicitly imports a user-selected external iCloud Drive folder.
library;

import 'dart:io';

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/cloud_container_repository.dart';

/// Copies explicitly selected paths through the application's normal importer.
class ImportExistingCloudFolder {
  /// Creates the use case.
  const ImportExistingCloudFolder({
    required this.cloud,
    required this.importPath,
  });

  /// App-owned platform edge that owns scoped folder-picker access.
  final CloudContainerRepository cloud;

  /// Existing import rule entry point.
  final Future<Result<void>> Function(String path) importPath;

  /// Picks, imports, and always releases scoped access.
  Future<Result<int>> call() async {
    final selected = await cloud.pickImportFolder();
    if (selected case Failed(:final failure)) {
      return Result<int>.failure(failure);
    }
    final scopedPaths = selected.valueOrNull!;
    var imported = 0;
    Result<int>? failure;
    try {
      final paths = <String>[];
      for (final scopedPath in scopedPaths) {
        final directory = Directory(scopedPath);
        if (!directory.existsSync()) {
          // Keeps the seam useful for virtual/document-provider paths and
          // deterministic fakes that expose individual selections.
          paths.add(scopedPath);
          continue;
        }
        try {
          paths.addAll(
            directory
                .listSync(recursive: true, followLinks: false)
                .whereType<File>()
                .map((file) => file.path)
                .where((path) => path.toLowerCase().endsWith('.pdf')),
          );
        } on FileSystemException catch (error) {
          failure = Result<int>.failure(
            Failure.storage(debugDetail: '${error.osError?.errorCode}'),
          );
          break;
        }
      }
      if (failure == null && paths.isEmpty && scopedPaths.isNotEmpty) {
        failure = const Result<int>.failure(
          Failure.import(unsupportedType: true),
        );
      }
      for (final path in paths) {
        final result = await importPath(path);
        if (result case Failed(failure: final cause)) {
          failure = Result<int>.failure(cause);
          break;
        }
        imported++;
      }
    } finally {
      final released = await cloud.releaseImportFolder(scopedPaths);
      if (released case Failed(failure: final cause)) {
        failure ??= Result<int>.failure(cause);
      }
    }
    return failure ?? Result<int>.success(imported);
  }
}
