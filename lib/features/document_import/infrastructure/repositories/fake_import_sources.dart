/// Substitutes for the import seams.
///
/// Ship in `lib/` rather than in `test/` because previews need them too, and a
/// preview that reached the real photo picker would open one while the
/// developer was looking at a widget.
library;

import 'dart:async';

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_import/domain/repositories/import_repository.dart';

/// A [GalleryPicker] answering with a fixed selection.
class FakeGalleryPicker implements GalleryPicker {
  /// Creates a picker returning [paths], or failing with [failure].
  ///
  /// An empty [paths] stands for the user cancelling the picker.
  FakeGalleryPicker({this.paths = const [], this.failure});

  /// The paths the user "selected", in selection order.
  final List<String> paths;

  /// When set, every call fails with this.
  final Failure? failure;

  /// How many times the picker was opened.
  int openCount = 0;

  @override
  Future<Result<List<String>>> pickImages() async {
    openCount++;

    final configured = failure;
    return configured == null
        ? Result<List<String>>.success(paths)
        : Result<List<String>>.failure(configured);
  }
}

/// A [FileBrowser] answering with a fixed selection.
class FakeFileBrowser implements FileBrowser {
  /// Creates a browser returning [paths], or failing with [failure].
  FakeFileBrowser({this.paths = const [], this.failure});

  /// The paths the user "selected", in selection order.
  final List<String> paths;

  /// When set, every call fails with this.
  final Failure? failure;

  /// How many times the browser was opened.
  int openCount = 0;

  @override
  Future<Result<List<String>>> pickFiles() async {
    openCount++;

    final configured = failure;
    return configured == null
        ? Result<List<String>>.success(paths)
        : Result<List<String>>.failure(configured);
  }
}

/// A [SharedContentSource] driven by the test.
class FakeSharedContentSource implements SharedContentSource {
  /// Creates a source whose cold-launch payload is [pendingPaths].
  FakeSharedContentSource({this.pendingPaths = const []});

  /// What was waiting when the application launched.
  final List<String> pendingPaths;

  final _controller = StreamController<List<String>>.broadcast();

  /// Whether the source has been disposed.
  bool isDisposed = false;

  /// Delivers [paths] as if another application had just shared them.
  void emit(List<String> paths) => _controller.add(paths);

  @override
  Future<Result<List<String>>> pending() async =>
      Result<List<String>>.success(pendingPaths);

  @override
  Stream<List<String>> get incoming => _controller.stream;

  @override
  Future<void> dispose() async {
    isDisposed = true;
    await _controller.close();
  }
}

/// An [ImportedPdfInspector] answering with a fixed page count.
class FakePdfInspector implements ImportedPdfInspector {
  /// Creates an inspector reporting [pageCount].
  ///
  /// When [requiresPassword] is true the first call without a password fails
  /// with an authentication failure, which is how the protected-PDF path is
  /// exercised without a real encrypted file.
  FakePdfInspector({
    this.pageCount = 1,
    this.requiresPassword = false,
    this.failure,
  });

  /// What a successful inspection reports.
  final int pageCount;

  /// Whether a password is needed before the file can be read.
  final bool requiresPassword;

  /// When set, every call fails with this.
  final Failure? failure;

  /// Every path inspected, in order.
  final List<String> inspected = [];

  @override
  Future<Result<int>> pageCountOf(String filePath, {String? password}) async {
    inspected.add(filePath);

    final configured = failure;
    if (configured != null) return Result<int>.failure(configured);

    if (requiresPassword && password == null) {
      return const Result<int>.failure(Failure.auth());
    }

    return Result<int>.success(pageCount);
  }
}
