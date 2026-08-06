/// One-time compatibility migration for the retired public-folder identity.
library;

import 'dart:async';
import 'dart:io';

/// Result of a legacy public-folder migration.
class LegacyPublicLibraryMigrationReport {
  /// Creates a report.
  const LegacyPublicLibraryMigrationReport({
    this.copiedFiles = 0,
    this.removedSource = false,
  });

  /// Number of payloads copied and verified during this run.
  final int copiedFiles;

  /// Whether all retired source trees were cleaned up.
  final bool removedSource;
}

/// Copies retired iOS folder trees into DocScanly before normal writes begin.
///
/// The retired names are intentionally isolated in this migration. Copy and
/// byte verification happen before cleanup, and a repeated run adopts copies
/// that were already verified before an interruption.
class LegacyPublicLibraryMigration {
  /// Creates the migration inside [documentsContainer].
  const LegacyPublicLibraryMigration(this.documentsContainer);

  /// The application Documents container.
  final Directory documentsContainer;

  static const _legacyLibraryName = 'DocForge';
  static const _currentLibraryName = 'DocScanly';
  static const _legacyTrashName = '.docforge-trash';
  static const _currentTrashName = '.docscanly-trash';

  /// Runs the idempotent copy–verify–cleanup migration.
  Future<LegacyPublicLibraryMigrationReport> run() async {
    final source = Directory('${documentsContainer.path}/$_legacyLibraryName');
    if (!source.existsSync()) {
      return const LegacyPublicLibraryMigrationReport(removedSource: true);
    }
    final destination = Directory(
      '${documentsContainer.path}/$_currentLibraryName',
    );
    await destination.create(recursive: true);

    var copied = 0;
    await for (final entity in source.list(recursive: true)) {
      final rawRelative = entity.path.substring(source.path.length + 1);
      final parts = rawRelative.split(Platform.pathSeparator);
      if (parts.first == _legacyTrashName) parts[0] = _currentTrashName;
      final target =
          '${destination.path}/${parts.join(Platform.pathSeparator)}';
      if (entity is Directory) {
        await Directory(target).create(recursive: true);
        continue;
      }
      if (entity is! File) continue;

      final targetFile = File(target);
      await targetFile.parent.create(recursive: true);
      if (targetFile.existsSync()) {
        if (await _sameBytes(entity, targetFile)) {
          await entity.delete();
          continue;
        }
        // An unexpected independently-created destination is preserved. The
        // legacy payload receives a stable suffix and reconciliation surfaces
        // both instead of one silently replacing the other.
        final collision = await _collisionTarget(targetFile);
        await entity.copy(collision.path);
        if (!await _sameBytes(entity, collision)) {
          throw const FileSystemException('legacy copy verification failed');
        }
        await entity.delete();
        copied++;
        continue;
      }

      await entity.copy(targetFile.path);
      if (!await _sameBytes(entity, targetFile)) {
        throw const FileSystemException('legacy copy verification failed');
      }
      await entity.delete();
      copied++;
    }

    await _deleteEmptyTree(source);
    return LegacyPublicLibraryMigrationReport(
      copiedFiles: copied,
      removedSource: !source.existsSync(),
    );
  }

  Future<File> _collisionTarget(File target) async {
    final dot = target.path.lastIndexOf('.');
    final stem = dot > target.parent.path.length
        ? target.path.substring(0, dot)
        : target.path;
    final extension = dot > target.parent.path.length
        ? target.path.substring(dot)
        : '';
    var sequence = 1;
    while (true) {
      final candidate = File('$stem (legacy $sequence)$extension');
      if (!candidate.existsSync()) return candidate;
      sequence++;
    }
  }

  Future<bool> _sameBytes(File first, File second) async {
    if (await first.length() != await second.length()) return false;
    final firstStream = first.openRead();
    final secondStream = second.openRead();
    final firstIterator = StreamIterator<List<int>>(firstStream);
    final secondIterator = StreamIterator<List<int>>(secondStream);
    try {
      var firstBytes = <int>[];
      var secondBytes = <int>[];
      var firstIndex = 0;
      var secondIndex = 0;
      while (true) {
        if (firstIndex == firstBytes.length) {
          if (!await firstIterator.moveNext()) {
            return secondIndex == secondBytes.length &&
                !await secondIterator.moveNext();
          }
          firstBytes = firstIterator.current;
          firstIndex = 0;
        }
        if (secondIndex == secondBytes.length) {
          if (!await secondIterator.moveNext()) return false;
          secondBytes = secondIterator.current;
          secondIndex = 0;
        }
        final count =
            (firstBytes.length - firstIndex) <
                (secondBytes.length - secondIndex)
            ? firstBytes.length - firstIndex
            : secondBytes.length - secondIndex;
        for (var index = 0; index < count; index++) {
          if (firstBytes[firstIndex + index] !=
              secondBytes[secondIndex + index]) {
            return false;
          }
        }
        firstIndex += count;
        secondIndex += count;
      }
    } finally {
      await firstIterator.cancel();
      await secondIterator.cancel();
    }
  }

  Future<void> _deleteEmptyTree(Directory root) async {
    final directories = <Directory>[];
    await for (final entity in root.list(recursive: true)) {
      if (entity is Directory) directories.add(entity);
    }
    directories.sort((a, b) => b.path.length.compareTo(a.path.length));
    for (final directory in directories) {
      if (directory.existsSync() && directory.listSync().isEmpty) {
        await directory.delete();
      }
    }
    if (root.existsSync() && root.listSync().isEmpty) await root.delete();
  }
}
