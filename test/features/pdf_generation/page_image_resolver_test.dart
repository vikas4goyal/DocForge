import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/settings_values.dart';
import 'package:doc_forge/features/pdf_generation/application/usecases/pdf_generation_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pdf_test_support.dart';

PageRef page(String id, {EnhancementSettings? enhancement}) => PageRef(
  id: PageId(id),
  imagePath: '/scan/$id.jpg',
  enhancement: enhancement ?? EnhancementSettings.none,
);

void main() {
  group('the image a page is composed from', () {
    test('is the capture when nothing resolves it', () async {
      final composer = FakePdfComposer();
      final build = BuildSearchablePdf(composer, _noText);

      await build([page('a')], destinationPath: '/out.pdf');

      // Unchanged for every caller that never enhanced anything: imports,
      // previews and tests keep composing straight from the capture.
      expect(composer.requests.single.pages.single.imagePath, '/scan/a.jpg');
    });

    test('is whatever the resolver returns', () async {
      final composer = FakePdfComposer();
      final asked = <(String, int)>[];

      final build = BuildSearchablePdf(
        composer,
        _noText,
        resolveImage: (page, {required maxDimension}) async {
          asked.add((page.imagePath, maxDimension));
          return '${page.imagePath}.enhanced.jpg';
        },
      );

      await build(
        [page('a'), page('b')],
        destinationPath: '/out.pdf',
        quality: PdfQuality.high,
      );

      // The composer must draw the resolved image. Drawing imagePath is the bug
      // this exists to prevent: the settings were recorded against the page and
      // never applied to anything the user could see.
      expect(composer.requests.single.pages.map((spec) => spec.imagePath), [
        '/scan/a.jpg.enhanced.jpg',
        '/scan/b.jpg.enhanced.jpg',
      ]);
    });

    test(
      'is rendered at the size it will be drawn, not the capture size',
      () async {
        final composer = FakePdfComposer();
        var requested = 0;

        final build = BuildSearchablePdf(
          composer,
          _noText,
          resolveImage: (page, {required maxDimension}) async {
            requested = maxDimension;
            return page.imagePath;
          },
        );

        await build(
          [page('a')],
          destinationPath: '/out.pdf',
          quality: PdfQuality.low,
        );

        // Composition caps the page at the quality setting, so filtering the full
        // capture would do several times the work and discard most of it.
        expect(requested, PdfQuality.low.maxDimension);
      },
    );
  });
}

Future<Map<String, Never>> _noText(List<PageId> ids) async => const {};
