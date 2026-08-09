/// A [PdfEditorRepository] over a toy file format.
///
/// Ships in `lib/` rather than in `test/` because previews need it too.
///
/// The real engine cannot run in the host test VM, so the *semantics* of every
/// operation — which pages survive a delete, what order a merge produces, that
/// a watermark reaches every page, that the wrong password is rejected — would
/// otherwise be unverifiable until the app ran on a device. This fake gives
/// them a substrate to be verified on.
///
/// The format is one line per page:
///
/// ```
/// ENC:hunter2      ← present only when the file is protected
/// page:0
/// page:1 rot:90 wm:DRAFT
/// ```
///
/// Deliberately not a PDF. Pretending to be one would invite the belief that
/// these tests say something about the real engine, which they do not — they
/// say the *use cases* handle pages correctly, which is a different and equally
/// necessary thing.
library;

import 'dart:io';

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';

/// The line prefix marking a protected file.
const fakeEncryptionMarker = 'ENC:';

/// The line prefix marking recoverable padding.
///
/// Stands in for the slack a real PDF carries — unreferenced objects, an
/// oversized image — that compression recovers. Modelling it as a line the page
/// count ignores is what lets "compression made the file smaller" and
/// "compression kept every page" both be asserted, which truncating the file
/// could not.
const fakePaddingMarker = 'PAD:';

/// Writes a fake PDF of [pageCount] pages at [path].
///
/// Exposed so tests and previews build their fixtures the same way the fake
/// reads them.
File writeFakePdf(
  String path, {
  int pageCount = 1,
  String? password,
  String? watermark,
  int padding = 0,
}) {
  final lines = <String>[
    if (password != null) '$fakeEncryptionMarker$password',
    for (var index = 0; index < pageCount; index++)
      'page:$index${watermark == null ? '' : ' wm:$watermark'}',
    if (padding > 0) '$fakePaddingMarker${'x' * padding}',
  ];

  final file = File(path)..parent.createSync(recursive: true);
  return file..writeAsStringSync(lines.join('\n'));
}

/// Reads the pages of a fake PDF, ignoring any encryption line.
List<String> fakePdfPages(String path) {
  final lines = File(path).readAsStringSync().split('\n')
    ..removeWhere((line) => line.trim().isEmpty);

  return [
    for (final line in lines)
      if (!line.startsWith(fakeEncryptionMarker) &&
          !line.startsWith(fakePaddingMarker))
        line,
  ];
}

/// The password a fake PDF is protected with, or null when it is not.
String? fakePdfPassword(String path) {
  final first = File(path).readAsStringSync().split('\n').firstOrNull ?? '';
  return first.startsWith(fakeEncryptionMarker)
      ? first.substring(fakeEncryptionMarker.length)
      : null;
}

/// An editor over the toy format described above.
class FakePdfEditor implements PdfEditorRepository {
  /// Creates the editor.
  ///
  /// [failWith] makes every operation fail, for exercising the failure paths.
  FakePdfEditor({this.failWith});

  /// When set, every operation fails with this.
  final Failure? failWith;

  /// Every operation performed, in order, for asserting on what ran.
  final List<String> operations = [];

  @override
  Future<Result<void>> writePages(
    String sourcePath,
    String destinationPath,
    List<int> pages, {
    String? password,
    bool preserveProtection = true,
  }) async {
    operations.add(
      preserveProtection ? 'writePages($pages)' : 'writePages($pages, plain)',
    );

    return _guard(sourcePath, password, () {
      final source = fakePdfPages(sourcePath);

      for (final page in pages) {
        if (page < 0 || page >= source.length) {
          throw RangeError('page $page is not in the document');
        }
      }

      // The order of `pages` is the order of the result, which is what makes
      // extraction and splitting produce document order rather than tap order.
      _write(
        destinationPath,
        [for (final page in pages) source[page]],
        password: preserveProtection ? fakePdfPassword(sourcePath) : null,
      );
    });
  }

  @override
  Future<Result<void>> rotatePage(
    String sourcePath,
    String destinationPath, {
    required int page,
    required int degrees,
    String? password,
  }) async {
    operations.add('rotatePage($page, $degrees)');

    return _guard(sourcePath, password, () {
      final source = fakePdfPages(sourcePath);
      if (page < 0 || page >= source.length) {
        throw RangeError('page $page is not in the document');
      }

      _write(destinationPath, [
        for (var index = 0; index < source.length; index++)
          index == page ? '${source[index]} rot:$degrees' : source[index],
      ]);
    });
  }

  @override
  Future<Result<void>> merge(
    List<String> sourcePaths,
    String destinationPath,
  ) async {
    operations.add('merge(${sourcePaths.length})');

    return _guard(null, null, () {
      _write(destinationPath, [
        for (final path in sourcePaths) ...fakePdfPages(path),
      ]);
    });
  }

  @override
  Future<Result<void>> compress(
    String sourcePath,
    String destinationPath, {
    int imageQuality = PdfEditRules.compressionImageQuality,
    int? dimensionScalePercent,
    String? password,
  }) async {
    operations.add(
      dimensionScalePercent == null
          ? 'compress($imageQuality)'
          : 'compress($imageQuality, scale: $dimensionScalePercent)',
    );

    return _guard(sourcePath, password, () {
      // Compression drops the padding and keeps every page. A file with no
      // padding therefore comes out the same size, which is exactly the
      // "compression yields no benefit" case the spec requires be handled.
      _write(destinationPath, fakePdfPages(sourcePath));
    });
  }

  @override
  Future<Result<void>> watermark(
    String sourcePath,
    String destinationPath, {
    required String text,
    String? password,
  }) async {
    operations.add('watermark($text)');

    return _guard(sourcePath, password, () {
      _write(destinationPath, [
        for (final page in fakePdfPages(sourcePath)) '$page wm:$text',
      ]);
    });
  }

  @override
  Future<Result<void>> protect(
    String sourcePath,
    String destinationPath, {
    required String password,
  }) async {
    operations.add('protect');

    return _guard(sourcePath, null, () {
      _write(destinationPath, fakePdfPages(sourcePath), password: password);
    });
  }

  @override
  Future<Result<void>> removePassword(
    String sourcePath,
    String destinationPath, {
    required String currentPassword,
  }) async {
    operations.add('removePassword');

    return _guard(sourcePath, currentPassword, () {
      _write(destinationPath, fakePdfPages(sourcePath));
    });
  }

  @override
  Future<Result<int>> pageCountOf(String filePath, {String? password}) async {
    final configured = failWith;
    if (configured != null) return Result<int>.failure(configured);

    final file = File(filePath);
    if (!file.existsSync()) {
      return const Result<int>.failure(Failure.notFound());
    }

    final stored = fakePdfPassword(filePath);
    if (stored != null && stored != password) {
      return const Result<int>.failure(Failure.auth());
    }

    return Result<int>.success(fakePdfPages(filePath).length);
  }

  /// Runs [body], mapping a wrong password or a thrown error onto a failure.
  Result<void> _guard(
    String? sourcePath,
    String? password,
    void Function() body,
  ) {
    final configured = failWith;
    if (configured != null) return Result<void>.failure(configured);

    if (sourcePath != null) {
      if (!File(sourcePath).existsSync()) {
        return const Result<void>.failure(Failure.notFound());
      }

      final stored = fakePdfPassword(sourcePath);
      if (stored != null && stored != password) {
        return const Result<void>.failure(Failure.auth());
      }
    }

    try {
      body();
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(Failure.pdf(debugDetail: '$error'));
    }
  }

  void _write(String path, List<String> pages, {String? password}) {
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        [
          if (password != null) '$fakeEncryptionMarker$password',
          ...pages,
        ].join('\n'),
      );
  }
}
