/// Materialises remote iCloud bytes before a reader opens a document.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/cloud_container_repository.dart';

/// Ensures one cloud item is locally readable without affecting its index row.
class EnsureDocumentDownloaded {
  /// Creates the use case.
  const EnsureDocumentDownloaded(this.cloud);

  /// App-owned cloud container.
  final CloudContainerRepository cloud;

  /// Downloads [relativePath] only when metadata says its bytes are remote.
  Future<Result<void>> call(
    String relativePath, {
    CloudDownloadProgress? onProgress,
    bool Function()? shouldCancel,
    Future<Result<void>> Function(String relativePath)? validateReadable,
  }) async {
    if (shouldCancel?.call() ?? false) {
      return const Result<void>.failure(Failure.cancelled());
    }
    final listed = await cloud.listItems();
    if (listed case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    final matches = listed.valueOrNull!
        .where((item) => item.relativePath == relativePath && !item.isDirectory)
        .toList(growable: false);
    if (matches.isEmpty) {
      return const Result<void>.failure(Failure.notFound());
    }
    final item = matches.single;
    if (item.availability
        case CloudContentAvailability.local ||
            CloudContentAvailability.available) {
      onProgress?.call(1);
      return validateReadable?.call(relativePath) ??
          const Result<void>.success(null);
    }
    final downloaded = await cloud.ensureDownloaded(
      relativePath,
      onProgress: onProgress,
    );
    if (downloaded case Failed(:final failure)) {
      return Result<void>.failure(failure);
    }
    if (shouldCancel?.call() ?? false) {
      return const Result<void>.failure(Failure.cancelled());
    }
    return validateReadable?.call(relativePath) ??
        const Result<void>.success(null);
  }
}
