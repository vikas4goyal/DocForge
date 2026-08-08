import 'dart:io';

import 'package:doc_scanly/app/cpu_image_processing_backend.dart';
import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/contracts/image_processing/image_processing.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  late Directory root;
  late String sourcePath;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cpu_image_backend');
    final image = img.Image(width: 120, height: 160);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final shade = y % 20 < 5 ? 35 : (235 - x ~/ 3);
        image.setPixelRgba(
          x,
          y,
          shade,
          (shade - 4).clamp(0, 255),
          (shade - 8).clamp(0, 255),
          255,
        );
      }
    }
    sourcePath = '${root.path}/source.jpg';
    File(sourcePath).writeAsBytesSync(img.encodeJpg(image, quality: 95));
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  ImageRenderRequest request({
    String id = 'request-1',
    EnhancementSettings enhancement = const EnhancementSettings(),
    Homography? transform,
    int? width,
    int? height,
    ImageRenderScale scale = ImageRenderScale.fullResolution,
    int? maximumPreviewDimension,
    String? source,
    String? destination,
  }) => ImageRenderRequest(
    requestId: id,
    sourcePath: source ?? sourcePath,
    destinationPath: destination ?? '${root.path}/output.jpg',
    scale: scale,
    enhancement: enhancement,
    jpegQuality: scale == ImageRenderScale.preview ? 82 : 92,
    transform: transform,
    outputWidth: width,
    outputHeight: height,
    maximumPreviewDimension: maximumPreviewDimension,
  );

  CpuImageProcessingBackend backend() =>
      CpuImageProcessingBackend(const InlineBackgroundWorker());

  test('reports a supported CPU fallback capability', () async {
    final capability = await backend().capability();

    expect(capability.backend, ImageProcessingBackendKind.cpuFallback);
    expect(capability.isSupported, isTrue);
    expect(capability.validate, returnsNormally);
  });

  for (final filter in EnhancementFilter.values) {
    test(
      'renders ${filter.name} and atomically publishes dimensions',
      () async {
        final output = await backend().render(
          request(
            enhancement: EnhancementSettings(
              filter: filter,
              brightness: 0.1,
              contrast: 0.1,
              sharpen: 0.2,
              shadowRemoval: true,
            ),
          ),
        );

        final success = output as ImageProcessingBackendSuccess;
        expect(success.result.backend, ImageProcessingBackendKind.cpuFallback);
        expect(success.result.outputWidth, 120);
        expect(success.result.outputHeight, 160);
        expect(File(success.result.destinationPath).existsSync(), isTrue);
        expect(
          root.listSync().where((entry) => entry.path.endsWith('.tmp')),
          isEmpty,
        );
      },
    );
  }

  test(
    'composes geometry before enhancement and supports preview bounds',
    () async {
      final output = await backend().render(
        request(
          scale: ImageRenderScale.preview,
          maximumPreviewDimension: 1400,
          transform: Homography.identity,
          width: 60,
          height: 80,
          enhancement: const EnhancementSettings(
            filter: EnhancementFilter.grayscale,
          ),
        ),
      );

      final result = (output as ImageProcessingBackendSuccess).result;
      expect(result.outputWidth, 60);
      expect(result.outputHeight, 80);
      final decoded = img.decodeJpg(
        File(result.destinationPath).readAsBytesSync(),
      )!;
      final pixel = decoded.getPixel(20, 20);
      expect((pixel.r - pixel.g).abs(), lessThanOrEqualTo(2));
      expect((pixel.g - pixel.b).abs(), lessThanOrEqualTo(2));
    },
  );

  test('classifies corrupt input and removes temporary output', () async {
    final corrupt = File('${root.path}/corrupt.jpg')..writeAsStringSync('nope');

    final output = await backend().render(request(source: corrupt.path));

    expect(
      (output as ImageProcessingBackendFailure).kind,
      ImageProcessingFailureKind.corruptInput,
    );
    expect(File('${root.path}/output.jpg').existsSync(), isFalse);
    expect(
      root.listSync().where((entry) => entry.path.endsWith('.tmp')),
      isEmpty,
    );
  });

  test(
    'classifies destination storage failure and cleans temporary output',
    () async {
      final notDirectory = File('${root.path}/not-directory')
        ..writeAsStringSync('occupied');

      final output = await backend().render(
        request(destination: '${notDirectory.path}/output.jpg'),
      );

      expect(
        (output as ImageProcessingBackendFailure).kind,
        ImageProcessingFailureKind.storage,
      );
      expect(
        root.listSync().where((entry) => entry.path.endsWith('.tmp')),
        isEmpty,
      );
    },
  );

  test(
    'cancels after an uninterruptible CPU stage without publishing',
    () async {
      final api = backend();
      final pending = api.render(request(id: 'cancel-me'));
      await api.cancel('cancel-me');

      final output = await pending;

      expect(
        (output as ImageProcessingBackendFailure).kind,
        ImageProcessingFailureKind.cancelled,
      );
      expect(File('${root.path}/output.jpg').existsSync(), isFalse);
      expect(
        root.listSync().where((entry) => entry.path.endsWith('.tmp')),
        isEmpty,
      );
    },
  );

  test('rejects invalid requests before starting work', () async {
    final output = await backend().render(
      request(enhancement: const EnhancementSettings(sharpen: 2)),
    );

    expect(
      (output as ImageProcessingBackendFailure).kind,
      ImageProcessingFailureKind.invalidRequest,
    );
  });

  test('disposal cancels active work and disables later renders', () async {
    final api = backend();
    await api.dispose();

    expect((await api.capability()).isSupported, isFalse);
    expect(
      (await api.render(request()) as ImageProcessingBackendFailure).kind,
      ImageProcessingFailureKind.unsupported,
    );
  });
}
