/// Where in-progress captures live, and how they are cleaned up.
///
/// Captured and picked images are working files, not documents. They exist only
/// while a creation session is open: once the PDF is written, or the session is
/// abandoned, they go — the PDF is the only representation of the document that
/// survives (`design.md` D4a).
///
/// Everything sits in the cache directory, which both platforms treat as
/// reclaimable. That is the backstop for the one case cleanup cannot cover:
/// a process killed mid-session leaves files behind, and the sweep at startup
/// removes them before the operating system has to.
library;

import 'dart:io';

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';

/// Owns the directory a creation session writes its working files into.
class CaptureStaging {
  /// Creates a staging area rooted at [cacheDirectory].
  const CaptureStaging(this.cacheDirectory, {this.directoryName = 'creation'});

  /// The cache directory the staging root sits in.
  final Directory cacheDirectory;

  /// The staging root's name.
  final String directoryName;

  /// The root every session's directory sits under.
  Directory get root => Directory('${cacheDirectory.path}/$directoryName');

  /// The directory belonging to [sessionId], creating it if needed.
  Directory directoryFor(String sessionId) {
    final directory = Directory('${root.path}/$sessionId');
    if (!directory.existsSync()) directory.createSync(recursive: true);
    return directory;
  }

  /// Deletes everything belonging to [sessionId].
  ///
  /// Succeeds when the directory is already absent: cleanup runs on the save
  /// path and on the discard path, and both have to be safe to repeat.
  Future<Result<void>> discardSession(String sessionId) async {
    try {
      final directory = Directory('${root.path}/$sessionId');
      if (directory.existsSync()) await directory.delete(recursive: true);
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(Failure.storage(debugDetail: '$error'));
    }
  }

  /// Deletes every session directory except those named in [keep].
  ///
  /// Run at startup, where [keep] is empty because no session can be open yet.
  /// Anything found is from a run that was killed before it could clean up
  /// after itself.
  Future<Result<int>> sweepOrphans({Set<String> keep = const {}}) async {
    try {
      if (!root.existsSync()) return const Result<int>.success(0);

      var removed = 0;
      await for (final entity in root.list()) {
        final name = entity.path.split(Platform.pathSeparator).last;
        if (keep.contains(name)) continue;

        if (entity is Directory) {
          await entity.delete(recursive: true);
          removed++;
        } else if (entity is File) {
          await entity.delete();
          removed++;
        }
      }
      return Result<int>.success(removed);
    } on Object catch (error) {
      return Result<int>.failure(Failure.storage(debugDetail: '$error'));
    }
  }

  /// Total bytes currently held by in-progress sessions.
  ///
  /// Reported in settings so a user wondering where their space went can see
  /// that a killed session is holding some of it.
  Future<Result<int>> totalBytes() async {
    try {
      if (!root.existsSync()) return const Result<int>.success(0);

      var total = 0;
      await for (final entity in root.list(recursive: true)) {
        if (entity is File) total += entity.statSync().size;
      }
      return Result<int>.success(total);
    } on Object catch (error) {
      return Result<int>.failure(Failure.storage(debugDetail: '$error'));
    }
  }
}
