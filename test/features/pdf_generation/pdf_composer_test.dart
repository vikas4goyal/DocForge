/// Tests PDF composition against real files.
///
/// The rules are covered in `pdf_composition_test.dart` without producing a
/// PDF. What this file verifies is the part that only shows up once a document
/// exists: page count and order, that rotation and quality reach the output,
/// and that a failure leaves no partial artefact.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/domain/repositories/pdf_repository.dart';
import 'package:doc_scanly/features/pdf_generation/infrastructure/pdf_composer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Writes a page-like image and returns its path.
///
/// Detailed rather than flat: a flat colour compresses to almost nothing at
/// every quality, which would make the quality assertions meaningless.
String writePage(
  Directory directory,
  String name, {
  int width = 900,
  int height = 1200,
}) {
  final image = img.Image(width: width, height: height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final onText = y % 14 < 4 && x > width * 0.1 && x < width * 0.9;
      // A fine gradient under the text, so there is real detail for the
      // compressor to lose at lower settings.
      final shade = onText ? 30 : 200 + (x * 13 + y * 7) % 55;
      image.setPixelRgba(x, y, shade, shade, (shade + x) % 256, 255);
    }
  }

  final path = '${directory.path}/$name';
  File(path).writeAsBytesSync(img.encodeJpg(image, quality: 95));
  return path;
}

/// The readable strings in [bytes].
///
/// A PDF's text is stored inside compressed streams, so this is not a parser —
/// it only counts page objects.
int pageCountIn(List<int> bytes) {
  final text = String.fromCharCodes(bytes.where((byte) => byte < 128));
  return RegExp(r'/Type\s*/Page[^s]').allMatches(text).length;
}

void main() {
  late Directory directory;
  const composer = InlinePdfComposer();

  setUp(() {
    directory = Directory.systemTemp.createTempSync('docscanly_pdf');
  });

  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  PdfPageSpec spec(String path, {PageRotation rotation = PageRotation.none}) =>
      PdfPageSpec(imagePath: path, rotation: rotation);

  Future<ComposedPdf> compose(
    List<PdfPageSpec> pages, {
    PdfQuality quality = PdfQuality.defaultQuality,
    String name = 'out.pdf',
  }) async {
    final result = await composer.compose(
      PdfBuildRequest(
        pages: pages,
        destinationPath: '${directory.path}/$name',
        quality: quality,
      ),
    );

    return (result as Success<ComposedPdf>).value;
  }

  group('composition', () {
    test('produces a PDF with one page per input page', () async {
      final pages = [
        spec(writePage(directory, 'a.jpg')),
        spec(writePage(directory, 'b.jpg')),
        spec(writePage(directory, 'c.jpg')),
      ];

      final composed = await compose(pages);

      expect(composed.pageCount, 3);
      expect(pageCountIn(File(composed.filePath).readAsBytesSync()), 3);
    });

    test('writes the file to the destination given', () async {
      final composed = await compose([spec(writePage(directory, 'a.jpg'))]);

      expect(composed.filePath, '${directory.path}/out.pdf');
      expect(File(composed.filePath).existsSync(), isTrue);
    });

    test('reports the size the filesystem actually reports', () async {
      // Stored on the document record and shown to the user; an estimate that
      // drifts from the file is worse than no figure at all.
      final composed = await compose([spec(writePage(directory, 'a.jpg'))]);

      expect(composed.sizeInBytes, File(composed.filePath).lengthSync());
      expect(composed.sizeInBytes, greaterThan(0));
    });

    test('leaves no temporary file behind', () async {
      await compose([spec(writePage(directory, 'a.jpg'))]);

      expect(
        directory.listSync().where((e) => e.path.endsWith('.partial')),
        isEmpty,
      );
    });

    test('a single-page document works', () async {
      final composed = await compose([spec(writePage(directory, 'a.jpg'))]);

      expect(composed.pageCount, 1);
    });
  });

  group('quality', () {
    test('the lowest setting yields a smaller file than the highest', () async {
      // The property the spec asserts directly.
      final page = writePage(directory, 'a.jpg', width: 2600, height: 3400);

      final low = await compose(
        [spec(page)],
        quality: PdfQuality.low,
        name: 'low.pdf',
      );
      final high = await compose(
        [spec(page)],
        quality: PdfQuality.high,
        name: 'high.pdf',
      );

      expect(low.sizeInBytes, lessThan(high.sizeInBytes));
    });

    test('balanced sits between the two', () async {
      final page = writePage(directory, 'a.jpg', width: 2600, height: 3400);

      final low = await compose(
        [spec(page)],
        quality: PdfQuality.low,
        name: 'low.pdf',
      );
      final balanced = await compose([spec(page)], name: 'balanced.pdf');
      final high = await compose(
        [spec(page)],
        quality: PdfQuality.high,
        name: 'high.pdf',
      );

      expect(balanced.sizeInBytes, greaterThan(low.sizeInBytes));
      expect(balanced.sizeInBytes, lessThan(high.sizeInBytes));
    });

    test('a page already smaller than the bound is not upscaled', () async {
      // Upscaling adds bytes and no detail.
      final small = writePage(directory, 'small.jpg', width: 300, height: 400);

      final low = await compose(
        [spec(small)],
        quality: PdfQuality.low,
        name: 'low.pdf',
      );
      final high = await compose(
        [spec(small)],
        quality: PdfQuality.high,
        name: 'high.pdf',
      );

      // Only the encoder quality differs now, so the gap is small rather than
      // the several-fold difference a rescale would produce.
      expect(high.sizeInBytes / low.sizeInBytes, lessThan(6));
    });
  });

  group('rotation', () {
    test('a rotated page produces a differently shaped output', () async {
      // Rotation is baked into the image rather than set as page metadata a
      // reader may or may not honour, so a quarter turn changes the page's
      // aspect ratio and therefore its compressed size.
      final page = writePage(directory, 'a.jpg');

      final upright = await compose([spec(page)], name: 'upright.pdf');
      final turned = await compose([
        spec(page, rotation: PageRotation.quarter),
      ], name: 'turned.pdf');

      expect(turned.sizeInBytes, isNot(upright.sizeInBytes));
      expect(turned.pageCount, 1);
    });

    test('every rotation composes without failing', () async {
      final page = writePage(directory, 'a.jpg');

      for (final rotation in PageRotation.values) {
        final composed = await compose([
          spec(page, rotation: rotation),
        ], name: 'r_${rotation.name}.pdf');

        expect(composed.pageCount, 1);
      }
    });
  });

  group('failure', () {
    test('an undecodable page fails and leaves no artefact', () async {
      final broken = '${directory.path}/broken.jpg';
      File(broken).writeAsStringSync('this is not an image');

      final result = await composer.compose(
        PdfBuildRequest(
          pages: [spec(broken)],
          destinationPath: '${directory.path}/never.pdf',
        ),
      );

      expect(result, isA<Failed<ComposedPdf>>());
      expect(File('${directory.path}/never.pdf').existsSync(), isFalse);
      expect(File('${directory.path}/never.pdf.partial').existsSync(), isFalse);
    });

    test('a missing page fails without writing anything', () async {
      final result = await composer.compose(
        PdfBuildRequest(
          pages: [spec('${directory.path}/absent.jpg')],
          destinationPath: '${directory.path}/never.pdf',
        ),
      );

      expect(result, isA<Failed<ComposedPdf>>());
      expect(File('${directory.path}/never.pdf').existsSync(), isFalse);
    });

    test(
      'a corrupt page is reported as such, not as an unexpected error',
      () async {
        // The recoveries differ: "the page could not be read" is not the same
        // advice as "try again".
        final broken = '${directory.path}/broken.jpg';
        File(broken).writeAsStringSync('nonsense');

        final result = await composer.compose(
          PdfBuildRequest(
            pages: [spec(broken)],
            destinationPath: '${directory.path}/never.pdf',
          ),
        );

        expect(
          (result as Failed<ComposedPdf>).failure,
          isA<CorruptFileFailure>(),
        );
      },
    );

    test('an unwritable destination is reported as a PDF failure', () async {
      final result = await composer.compose(
        PdfBuildRequest(
          pages: [spec(writePage(directory, 'a.jpg'))],
          destinationPath: '${directory.path}/nonexistent/out.pdf',
        ),
      );

      expect((result as Failed<ComposedPdf>).failure, isA<PdfFailure>());
    });
  });
}
