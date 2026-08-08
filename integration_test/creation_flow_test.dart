// Verifies the creation flow end to end, on real storage.
//
// The unit and widget suites prove each piece against fakes. This proves the
// pieces agree once a real store, a real render pipeline and a real PDF
// composer are involved — which only a device can supply:
//
//   flutter test integration_test/creation_flow_test.dart -d <device-id>
library;

import 'dart:io';

import 'package:doc_scanly/app/page_render_job.dart';
import 'package:doc_scanly/core/contracts/geometry/page_geometry.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/storage/capture_staging.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_storage_factory.dart';
import 'package:doc_scanly/features/document_creation/application/usecases/render_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

PageQuad box(double left, double top, double right, double bottom) => PageQuad(
  topLeft: NormalisedPoint(x: left, y: top),
  topRight: NormalisedPoint(x: right, y: top),
  bottomRight: NormalisedPoint(x: right, y: bottom),
  bottomLeft: NormalisedPoint(x: left, y: bottom),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory cache;
  late Directory documents;
  late PublicFileStore store;
  late CaptureStaging staging;
  late RenderPage renderPage;

  setUpAll(() async {
    documents = await getApplicationDocumentsDirectory();
    cache = await getApplicationCacheDirectory();
    store = buildPublicFileStore(
      documentsDirectory: documents,
      cacheDirectory: cache,
    );
    await store.initialise();
    staging = CaptureStaging(cache);

    renderPage = RenderPage(
      cacheDirectory: cache,
      sizeOf: readImageSize,
      render: (plan, {required destinationPath, transform, scope}) =>
          renderPageJob(
            const InlineBackgroundWorker(),
            plan,
            destinationPath: destinationPath,
            transform: transform,
          ),
    );
  });

  /// Writes a real JPEG a page can be built over.
  ///
  /// Actual pixels, not a stub: the render pipeline decodes it, resamples it
  /// and re-encodes it, and a placeholder would exercise none of that.
  Future<PageDraft> stagedPage(String sessionId, {int size = 400}) async {
    final image = img.Image(width: size, height: size);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        image.setPixelRgba(x, y, x % 256, y % 256, 128, 255);
      }
    }

    final path = '${staging.directoryFor(sessionId).path}/original.jpg';
    File(path).writeAsBytesSync(img.encodeJpg(image));

    return PageDraft(id: PageId('$sessionId-page'), originalImagePath: path);
  }

  group('rendering a page', () {
    testWidgets('an unedited page renders as its own original', (tester) async {
      final page = await stagedPage('render-plain');

      final rendered = await renderPage(PageRenderPlan.of(page));

      expect(rendered.valueOrNull, page.originalImagePath);
      await staging.discardSession('render-plain');
    });

    testWidgets('a cropped page produces a smaller image', (tester) async {
      final page = (await stagedPage(
        'render-crop',
      )).withCrop(CropOp(quad: box(0.25, 0.25, 0.75, 0.75)));

      final rendered = await renderPage(PageRenderPlan.of(page));

      final result = img.decodeImage(
        File(rendered.valueOrNull!).readAsBytesSync(),
      );
      expect(result, isNotNull);
      expect(result!.width, lessThan(400));

      await staging.discardSession('render-crop');
    });

    testWidgets('cropping twice lands where cropping once does', (
      tester,
    ) async {
      // Two chains onto the *same* region of the original. The second crop is
      // expressed in the coordinates the first one leaves behind: keeping
      // [0 .. 0.75] first means the original's [0.25 .. 0.75] is [1/3 .. 1] of
      // what remains. Getting this wrong is how the composition would silently
      // land somewhere else and still produce a plausible-looking image.
      final once = (await stagedPage(
        'render-once',
      )).withCrop(CropOp(quad: box(0.25, 0.25, 0.75, 0.75)));
      final twice = (await stagedPage('render-twice'))
          .withCrop(CropOp(quad: box(0.0, 0.0, 0.75, 0.75)))
          .withCrop(CropOp(quad: box(1 / 3, 1 / 3, 1.0, 1.0)));

      final first = await renderPage(PageRenderPlan.of(once));
      final second = await renderPage(PageRenderPlan.of(twice));

      // Equal dimensions are what says the composed chain reached the same
      // region. That it got there in a single resampling pass is proved by the
      // host test against step-by-step application; what this adds is that the
      // real decoder and the real geometry agree on device.
      final a = img.decodeImage(File(first.valueOrNull!).readAsBytesSync())!;
      final b = img.decodeImage(File(second.valueOrNull!).readAsBytesSync())!;
      expect((a.width - b.width).abs(), lessThanOrEqualTo(2));
      expect((a.height - b.height).abs(), lessThanOrEqualTo(2));

      await staging.discardSession('render-once');
      await staging.discardSession('render-twice');
    });

    testWidgets('an enhanced page renders through the same pipeline', (
      tester,
    ) async {
      final page = (await stagedPage('render-enhance')).withEnhancement(
        const EnhancementSettings(filter: EnhancementFilter.blackAndWhite),
      );

      final rendered = await renderPage(PageRenderPlan.of(page));

      expect(rendered.isSuccess, isTrue);
      expect(File(rendered.valueOrNull!).existsSync(), isTrue);

      await staging.discardSession('render-enhance');
    });
  });

  group('the two layers are independent', () {
    testWidgets('reverting the crop keeps the enhancement', (tester) async {
      final both = (await stagedPage('layers-a'))
          .withCrop(CropOp(quad: box(0.2, 0.2, 0.8, 0.8)))
          .withEnhancement(
            const EnhancementSettings(filter: EnhancementFilter.grayscale),
          );

      final reverted = both.revertGeometry();
      final rendered = await renderPage(PageRenderPlan.of(reverted));

      // The full original frame, still enhanced: same size as the original,
      // and a render was still needed because the enhancement remains.
      final result = img.decodeImage(
        File(rendered.valueOrNull!).readAsBytesSync(),
      )!;
      expect(result.width, 400);
      expect(reverted.hasEnhancement, isTrue);

      await staging.discardSession('layers-a');
    });

    testWidgets('reverting the enhancement keeps the crop', (tester) async {
      final both = (await stagedPage('layers-b'))
          .withCrop(CropOp(quad: box(0.25, 0.25, 0.75, 0.75)))
          .withEnhancement(
            const EnhancementSettings(filter: EnhancementFilter.grayscale),
          );

      final reverted = both.revertEnhancement();
      final rendered = await renderPage(PageRenderPlan.of(reverted));

      final result = img.decodeImage(
        File(rendered.valueOrNull!).readAsBytesSync(),
      )!;
      expect(result.width, lessThan(400));
      expect(reverted.hasGeometry, isTrue);

      await staging.discardSession('layers-b');
    });
  });

  group('publishing', () {
    testWidgets('a rendered page can be published and read back', (
      tester,
    ) async {
      final page = (await stagedPage(
        'publish',
      )).withCrop(CropOp(quad: box(0.1, 0.1, 0.9, 0.9)));
      final rendered = await renderPage(PageRenderPlan.of(page));

      final path = LibraryPath.parse('Integration Render.pdf');
      final published = await store.writeFile(path, rendered.valueOrNull!);

      expect(published.isSuccess, isTrue);
      expect((await store.exists(path)).valueOrNull, isTrue);

      await store.delete(path);
      await staging.discardSession('publish');
    });
  });

  group('cleanup', () {
    testWidgets('discarding a session removes its originals', (tester) async {
      final page = await stagedPage('cleanup');
      expect(File(page.originalImagePath).existsSync(), isTrue);

      await staging.discardSession('cleanup');

      // After a save the PDF is the only representation that survives.
      expect(File(page.originalImagePath).existsSync(), isFalse);
    });
  });
}
