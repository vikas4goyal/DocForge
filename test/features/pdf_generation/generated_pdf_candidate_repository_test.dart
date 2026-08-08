import 'dart:io';
import 'dart:typed_data';

import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/infrastructure/generated_pdf_candidate_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  late Directory directory;
  late IsolateGeneratedPdfCandidateRepository repository;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('generated_candidate');
    repository = IsolateGeneratedPdfCandidateRepository(
      workingDirectory: directory,
      ids: SequentialIdGenerator(prefix: 'candidate'),
      pageCountOf: _pageCountOf,
      protect: _copyProtected,
    );
  });

  tearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  test(
    'builds a valid exact candidate in page order with mixed quality',
    () async {
      final first = _writePage(directory, 'first.jpg', red: 220);
      final second = _writePage(directory, 'second.jpg', red: 40);
      final request = _request(
        <String>[first, second],
        qualities: <int>[50, 100],
      );
      final progress = <int>[];

      final result = await repository.buildCandidate(
        request,
        token: CancellationToken(),
        onProgress: (value) => progress.add(value.percent),
      );
      final candidate = (result as Success<PdfCandidate>).value;

      expect(File(candidate.handle).existsSync(), isTrue);
      expect(candidate.exactBytes, File(candidate.handle).lengthSync());
      expect(candidate.exactBytes, greaterThan(0));
      expect(candidate.pageCount, 2);
      expect(
        await _pageCountOf(candidate.handle),
        const Result<int>.success(2),
      );
      expect(candidate.fingerprint.orderedPageQualities, <int>[50, 100]);
      expect(progress.first, 0);
      expect(progress.last, 100);
      expect(progress, orderedEquals(progress.toList()..sort()));

      final embedded = _embeddedJpegs(File(candidate.handle).readAsBytesSync());
      expect(embedded, hasLength(2));
      expect((embedded[0].width, embedded[0].height), (160, 240));
      expect((embedded[1].width, embedded[1].height), (320, 480));
      expect(
        embedded[0].getPixel(20, 20).r,
        greaterThan(embedded[1].getPixel(20, 20).r),
      );
    },
  );

  test(
    'records protected and unprotected fingerprints without secret text',
    () async {
      final page = _writePage(directory, 'page.jpg', red: 120);
      final plain = await repository.buildCandidate(
        _request(<String>[page], qualities: <int>[70]),
        token: CancellationToken(),
        onProgress: (_) {},
      );
      expect(plain.valueOrNull!.isProtected, isFalse);

      final protected = await repository.buildCandidate(
        _request(
          <String>[page],
          qualities: <int>[70],
          password: 'route-only secret',
        ),
        token: CancellationToken(),
        onProgress: (_) {},
      );

      expect(protected.valueOrNull!.isProtected, isTrue);
      expect(
        protected.valueOrNull!.toJson().toString(),
        isNot(contains('secret')),
      );
      expect(File(plain.valueOrNull!.handle).existsSync(), isFalse);
    },
  );

  test(
    'cooperative cancellation removes partial and candidate output',
    () async {
      final paths = <String>[
        for (var index = 0; index < 8; index++)
          _writePage(directory, 'page-$index.jpg', red: index * 20),
      ];
      final token = CancellationToken();

      final result = await repository.buildCandidate(
        _request(paths, qualities: List<int>.filled(paths.length, 70)),
        token: token,
        onProgress: (progress) {
          if (progress.percent > 0) {
            token.cancel();
          }
        },
      );

      expect(result.failureOrNull, const Failure.cancelled());
      expect(_candidateFiles(directory), isEmpty);
    },
  );

  test('composition failure removes partial and candidate output', () async {
    final corrupt = File('${directory.path}/corrupt.jpg')
      ..writeAsStringSync('not an image');

    final result = await repository.buildCandidate(
      _request(<String>[corrupt.path], qualities: <int>[70]),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result, isA<Failed<PdfCandidate>>());
    expect(_candidateFiles(directory), isEmpty);
  });

  test('retains one candidate and reuses it for verified promotion', () async {
    final page = _writePage(directory, 'page.jpg', red: 120);
    final first = (await repository.buildCandidate(
      _request(<String>[page], qualities: <int>[70]),
      token: CancellationToken(),
      onProgress: (_) {},
    )).valueOrNull!;
    final firstPath = first.handle;
    final second = (await repository.buildCandidate(
      _request(<String>[page], qualities: <int>[50]),
      token: CancellationToken(),
      onProgress: (_) {},
    )).valueOrNull!;

    expect(File(firstPath).existsSync(), isFalse);
    expect(await repository.verifyCandidate(second), Result.success(second));

    final destination = '${directory.path}/saved.pdf';
    final promoted = await repository.promote(
      second,
      destinationPath: destination,
      token: CancellationToken(),
    );

    expect(promoted.valueOrNull!.filePath, destination);
    expect(promoted.valueOrNull!.sizeInBytes, second.exactBytes);
    expect(File(second.handle).existsSync(), isFalse);
    expect(File(destination).existsSync(), isTrue);
  });
}

GeneratedPdfCandidateRequest _request(
  List<String> paths, {
  required List<int> qualities,
  String? password,
}) {
  final pages = <GeneratedPdfCandidatePage>[
    for (var index = 0; index < paths.length; index++)
      GeneratedPdfCandidatePage(
        stableId: 'page-$index',
        page: PdfPageSpec(imagePath: paths[index], rotation: PageRotation.none),
        quality: PdfQualityPercent(value: qualities[index]),
      ),
  ];
  return GeneratedPdfCandidateRequest(
    pages: pages,
    fingerprint: PdfCandidateFingerprint(
      sourceIdentity: 'session-1',
      configurationIdentity: 'document-name',
      orderedPageQualities: qualities,
      isProtected: password != null,
    ),
    password: password,
  );
}

String _writePage(Directory directory, String name, {required int red}) {
  final image = img.Image(width: 320, height: 480);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgba(
        x,
        y,
        (red + x % 17).clamp(0, 255),
        (y + x) % 255,
        100,
        255,
      );
    }
  }
  final path = '${directory.path}/$name';
  File(path).writeAsBytesSync(img.encodeJpg(image, quality: 95));
  return path;
}

Future<Result<int>> _pageCountOf(String path, {String? password}) async {
  final bytes = File(path).readAsBytesSync();
  final ascii = String.fromCharCodes(bytes.where((byte) => byte < 128));
  final count = RegExp(r'/Type\s*/Page[^s]').allMatches(ascii).length;
  return Result<int>.success(count);
}

Future<Result<String>> _copyProtected(String source, String password) async {
  final destination = '$source.protected';
  File(source).copySync(destination);
  return Result<String>.success(destination);
}

List<FileSystemEntity> _candidateFiles(Directory directory) => directory
    .listSync()
    .where(
      (entity) =>
          entity.path.contains('pdf-candidate-') ||
          entity.path.endsWith('.partial'),
    )
    .toList();

List<img.Image> _embeddedJpegs(List<int> bytes) {
  final images = <img.Image>[];
  var cursor = 0;
  while (cursor < bytes.length - 1) {
    if (bytes[cursor] != 0xff || bytes[cursor + 1] != 0xd8) {
      cursor++;
      continue;
    }
    var end = cursor + 2;
    while (end < bytes.length - 1 &&
        (bytes[end] != 0xff || bytes[end + 1] != 0xd9)) {
      end++;
    }
    if (end >= bytes.length - 1) {
      break;
    }
    final decoded = img.decodeJpg(
      Uint8List.fromList(bytes.sublist(cursor, end + 2)),
    );
    if (decoded != null) {
      images.add(decoded);
    }
    cursor = end + 2;
  }
  return images;
}
