import 'dart:async';
import 'dart:io';

import 'package:doc_scanly/core/contracts/geometry/page_geometry.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_creation/application/usecases/render_page.dart';
import 'package:flutter_test/flutter_test.dart';

PageQuad box(double left, double top, double right, double bottom) => PageQuad(
  topLeft: NormalisedPoint(x: left, y: top),
  topRight: NormalisedPoint(x: right, y: top),
  bottomRight: NormalisedPoint(x: right, y: bottom),
  bottomLeft: NormalisedPoint(x: left, y: bottom),
);

CropOp crop([double inset = 0.1]) =>
    CropOp(quad: box(inset, inset, 1 - inset, 1 - inset));

void main() {
  late Directory cache;
  late List<PageRenderPlan> rendered;
  late List<ComposedGeometry?> transforms;
  late Failure? renderFailure;
  late Completer<void>? gate;
  late RenderPage renderPage;

  PageDraft draft() => const PageDraft(
    id: PageId('page-1'),
    originalImagePath: '/staging/page-1.jpg',
  );

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('docscanly_render_');
    rendered = [];
    transforms = [];
    renderFailure = null;
    gate = null;

    renderPage = RenderPage(
      cacheDirectory: cache,
      sizeOf: (path) async => const Result<({int width, int height})>.success((
        width: 1000,
        height: 800,
      )),
      render: (plan, {required destinationPath, transform}) async {
        rendered.add(plan);
        transforms.add(transform);
        if (gate != null) await gate!.future;

        final configured = renderFailure;
        if (configured != null) return Result<void>.failure(configured);

        File(destinationPath).writeAsStringSync('rendered');
        return const Result<void>.success(null);
      },
    );
  });

  tearDown(() async {
    if (cache.existsSync()) await cache.delete(recursive: true);
  });

  group('pass-through', () {
    test('an unedited page renders as its own original', () async {
      final result = await renderPage(PageRenderPlan.of(draft()));

      // Nothing has been applied, so copying the file would produce a
      // byte-for-byte duplicate of one that already exists.
      expect(result.valueOrNull, '/staging/page-1.jpg');
      expect(rendered, isEmpty);
    });
  });

  group('rendering', () {
    test('renders a page that has a crop', () async {
      final result = await renderPage(
        PageRenderPlan.of(draft().withCrop(crop())),
      );

      expect(rendered, hasLength(1));
      expect(File(result.valueOrNull!).readAsStringSync(), 'rendered');
    });

    test('composes the whole chain into one transform', () async {
      await renderPage(
        PageRenderPlan.of(draft().withCrop(crop()).withCrop(crop(0.2))),
      );

      // One render, one transform: the original is resampled once however many
      // times the user cropped.
      expect(rendered, hasLength(1));
      expect(transforms.single, isNotNull);
      expect(transforms.single!.transform.isValid, isTrue);
    });

    test('an enhancement-only page needs no transform', () async {
      await renderPage(
        PageRenderPlan.of(
          draft().withEnhancement(
            const EnhancementSettings(filter: EnhancementFilter.blackAndWhite),
          ),
        ),
      );

      // No geometry, so nothing to resample — running an identity transform
      // over the image would cost a pass for no change.
      expect(transforms.single, isNull);
    });
  });

  group('caching', () {
    test('an unchanged plan reuses its render', () async {
      final plan = PageRenderPlan.of(draft().withCrop(crop()));
      await renderPage(plan);

      await renderPage(plan);

      expect(rendered, hasLength(1));
    });

    test('a changed crop renders again', () async {
      await renderPage(PageRenderPlan.of(draft().withCrop(crop())));

      await renderPage(PageRenderPlan.of(draft().withCrop(crop(0.2))));

      expect(rendered, hasLength(2));
    });

    test('a changed enhancement renders again', () async {
      final cropped = draft().withCrop(crop());
      await renderPage(PageRenderPlan.of(cropped));

      await renderPage(
        PageRenderPlan.of(
          cropped.withEnhancement(
            const EnhancementSettings(filter: EnhancementFilter.grayscale),
          ),
        ),
      );

      expect(rendered, hasLength(2));
    });

    test('a preview and a full render do not share a file', () async {
      final edited = draft().withCrop(crop());
      final preview = await renderPage(PageRenderPlan.of(edited));

      final full = await renderPage(
        PageRenderPlan.of(edited, scale: RenderScale.full),
      );

      expect(full.valueOrNull, isNot(preview.valueOrNull));
      expect(rendered, hasLength(2));
    });

    test('two callers wanting the same render share one', () async {
      gate = Completer<void>();
      final plan = PageRenderPlan.of(draft().withCrop(crop()));

      final first = renderPage(plan);
      final second = renderPage(plan);
      gate!.complete();
      await Future.wait([first, second]);

      // A row scrolling into view and the crop screen opening want the same
      // picture; producing it twice is pure waste.
      expect(rendered, hasLength(1));
    });
  });

  group('failure', () {
    test('a failed render is reported', () async {
      renderFailure = const Failure.unexpected();

      final result = await renderPage(
        PageRenderPlan.of(draft().withCrop(crop())),
      );

      expect(result.isFailure, isTrue);
    });

    test('a failed render leaves no partial file to be served', () async {
      renderFailure = const Failure.unexpected();
      final plan = PageRenderPlan.of(draft().withCrop(crop()));
      await renderPage(plan);

      renderFailure = null;
      await renderPage(plan);

      // Had the partial survived, the existence check would have served it as
      // a finished render.
      expect(rendered, hasLength(2));
    });

    test('a failure reading the original size is reported', () async {
      final failing = RenderPage(
        cacheDirectory: cache,
        sizeOf: (path) async => const Result<({int width, int height})>.failure(
          Failure.corruptFile(),
        ),
        render: (plan, {required destinationPath, transform}) async =>
            const Result<void>.success(null),
      );

      final result = await failing(PageRenderPlan.of(draft().withCrop(crop())));

      expect(result.failureOrNull, isA<CorruptFileFailure>());
    });
  });

  group('discardAll', () {
    test('removes every cached render', () async {
      final result = await renderPage(
        PageRenderPlan.of(draft().withCrop(crop())),
      );

      await renderPage.discardAll();

      expect(File(result.valueOrNull!).existsSync(), isFalse);
    });

    test('succeeds when nothing was ever rendered', () async {
      expect((await renderPage.discardAll()).isSuccess, isTrue);
    });
  });
}
