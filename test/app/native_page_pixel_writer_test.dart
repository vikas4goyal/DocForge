import 'dart:async';

import 'package:doc_scanly/app/native_page_pixel_writer.dart';
import 'package:doc_scanly/core/contracts/image_processing/image_processing.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _ControlledBackend backend;
  late NativePagePixelWriter writer;

  const original = PageRenderPlan(
    originalImagePath: '/app/source.jpg',
    geometry: [],
    enhancement: EnhancementSettings.none,
  );

  setUp(() {
    backend = _ControlledBackend();
    writer = NativePagePixelWriter(
      backend,
      SequentialIdGenerator(prefix: 'render'),
    );
  });

  test('a newer render cancels the active request in the same scope', () async {
    final first = writer(
      original,
      destinationPath: '/app/first.jpg',
      scope: 'enhancement:page-1',
    );
    await _nextEvent();

    final second = writer(
      original.copyWithEnhancement(
        const EnhancementSettings(filter: EnhancementFilter.grayscale),
      ),
      destinationPath: '/app/second.jpg',
      scope: 'enhancement:page-1',
    );
    await _nextEvent();

    expect(backend.cancelled, ['render-1']);
    expect((await first).failureOrNull?.isCancellation, isTrue);

    backend.succeed('render-2');
    expect((await second).isSuccess, isTrue);
  });

  test('different editor scopes do not cancel each other', () async {
    final enhancement = writer(
      original,
      destinationPath: '/app/enhancement.jpg',
      scope: 'enhancement:page-1',
    );
    final crop = writer(
      original,
      destinationPath: '/app/crop.jpg',
      scope: 'crop:page-1',
    );
    await _nextEvent();

    expect(backend.cancelled, isEmpty);
    backend
      ..succeed('render-1')
      ..succeed('render-2');
    expect((await enhancement).isSuccess, isTrue);
    expect((await crop).isSuccess, isTrue);
  });

  test('closing a scope cancels its active native request', () async {
    final pending = writer(
      original,
      destinationPath: '/app/output.jpg',
      scope: 'crop:page-1',
    );
    await _nextEvent();

    await writer.cancel('crop:page-1');

    expect(backend.cancelled, ['render-1']);
    expect((await pending).failureOrNull?.isCancellation, isTrue);
  });

  test('maps full and preview plans without transferring pixels', () async {
    final pending = writer(
      original
          .copyWithEnhancement(
            const EnhancementSettings(
              filter: EnhancementFilter.magicColour,
              brightness: 0.2,
              contrast: -0.1,
              sharpen: 0.4,
              shadowRemoval: true,
            ),
          )
          .atScale(RenderScale.full),
      destinationPath: '/app/output.jpg',
    );
    await _nextEvent();

    final request = backend.requests.single;
    expect(request.scale, ImageRenderScale.fullResolution);
    expect(request.maximumPreviewDimension, isNull);
    expect(request.enhancement.filter, EnhancementFilter.magicColour);
    expect(request.sourcePath, '/app/source.jpg');
    expect(request.destinationPath, '/app/output.jpg');

    backend.succeed(request.requestId);
    expect((await pending).isSuccess, isTrue);
  });

  test('forwards the exact physical preview-view dimension', () async {
    final pending = writer(
      original
          .copyWithEnhancement(
            const EnhancementSettings(filter: EnhancementFilter.grayscale),
          )
          .atPreviewDimension(914),
      destinationPath: '/app/preview.jpg',
    );
    await _nextEvent();

    final request = backend.requests.single;
    expect(request.scale, ImageRenderScale.preview);
    expect(request.maximumPreviewDimension, 914);
    expect(request.jpegQuality, 82);

    backend.succeed(request.requestId);
    expect((await pending).isSuccess, isTrue);
  });
}

extension on PageRenderPlan {
  PageRenderPlan copyWithEnhancement(EnhancementSettings value) =>
      PageRenderPlan(
        originalImagePath: originalImagePath,
        geometry: geometry,
        enhancement: value,
        scale: scale,
        maximumPreviewDimension: maximumPreviewDimension,
      );

  PageRenderPlan atPreviewDimension(int dimension) => PageRenderPlan(
    originalImagePath: originalImagePath,
    geometry: geometry,
    enhancement: enhancement,
    maximumPreviewDimension: dimension,
  );
}

Future<void> _nextEvent() => Future<void>.delayed(Duration.zero);

class _ControlledBackend implements ImageProcessingBackend {
  final requests = <ImageRenderRequest>[];
  final cancelled = <String>[];
  final _responses = <String, Completer<ImageProcessingBackendResponse>>{};

  @override
  Future<ImageProcessingCapability> capability() async =>
      const ImageProcessingCapability(
        backend: ImageProcessingBackendKind.androidOpenGl,
        isSupported: true,
        maximumTextureSize: 16384,
        supportsTiling: false,
      );

  @override
  Future<ImageProcessingBackendResponse> render(ImageRenderRequest request) {
    requests.add(request);
    final response = Completer<ImageProcessingBackendResponse>();
    _responses[request.requestId] = response;
    return response.future;
  }

  @override
  Future<void> cancel(String requestId) async {
    cancelled.add(requestId);
    _responses[requestId]?.complete(
      const ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.cancelled,
      ),
    );
  }

  void succeed(String requestId) {
    final request = requests.singleWhere(
      (candidate) => candidate.requestId == requestId,
    );
    _responses[requestId]!.complete(
      ImageProcessingBackendResponse.success(
        ImageProcessingResult(
          destinationPath: request.destinationPath,
          sourceWidth: 1000,
          sourceHeight: 800,
          outputWidth: 1000,
          outputHeight: 800,
          backend: ImageProcessingBackendKind.androidOpenGl,
          timings: const ImageProcessingTimings(totalMicroseconds: 1000),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {}
}
