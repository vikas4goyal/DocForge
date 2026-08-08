/// Emulator/Simulator benchmark and smoke test for the native GPU channel.
library;

import 'dart:convert';
import 'dart:io';

import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/contracts/image_processing/image_processing.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/features/image_enhancement/infrastructure/datasource/native_image_processing_data_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _fixture =
    'integration_test/fixtures/image_processing_benchmark_12mp.jpg';
const _warmups = int.fromEnvironment('BENCHMARK_WARMUPS', defaultValue: 5);
const _samples = int.fromEnvironment('BENCHMARK_SAMPLES', defaultValue: 30);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native GPU preview and full-resolution benchmark',
    (tester) async {
      await tester.runAsync(() async {
        final root = Directory.systemTemp.createTempSync('image_gpu_benchmark');
        final kind = Platform.isIOS
            ? ImageProcessingBackendKind.iosCoreImage
            : ImageProcessingBackendKind.androidOpenGl;
        final backend = NativeImageProcessingDataSource(backend: kind);
        try {
          final bytes = await rootBundle.load(_fixture);
          final source = File('${root.path}/source.jpg');
          await source.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
          final capability = await backend.capability();
          expect(capability.isSupported, isTrue);
          final preview = await _measure(backend, root, source.path, true);
          final full = await _measure(backend, root, source.path, false);
          final cpuPreviewMedian = Platform.isIOS ? 3881959 : 4665289;
          final cpuFullMedian = Platform.isIOS ? 12404061 : 15355661;
          expect(preview['p95Us'] as int, lessThanOrEqualTo(200000));
          expect(full['p95Us'] as int, lessThanOrEqualTo(1500000));
          expect(
            cpuPreviewMedian / (preview['medianUs'] as int),
            greaterThanOrEqualTo(3),
          );
          expect(
            cpuFullMedian / (full['medianUs'] as int),
            greaterThanOrEqualTo(3),
          );
          debugPrint(
            'IMAGE_PROCESSING_GPU_BENCHMARK ${jsonEncode({'schemaVersion': 1, 'backend': kind.name, 'buildMode': kReleaseMode
                ? 'release'
                : kProfileMode
                ? 'profile'
                : 'debug', 'operatingSystem': Platform.operatingSystem, 'operatingSystemVersion': Platform.operatingSystemVersion, 'warmups': _warmups, 'samples': _samples, 'preview': preview, 'full': full})}',
          );
        } finally {
          await backend.dispose();
          if (root.existsSync()) root.deleteSync(recursive: true);
        }
      });
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

Future<Map<String, Object?>> _measure(
  ImageProcessingBackend backend,
  Directory root,
  String source,
  bool preview,
) async {
  final durations = <int>[];
  final rssBefore = ProcessInfo.currentRss;
  var peakRss = rssBefore;
  ImageProcessingResult? last;
  for (var index = -_warmups; index < _samples; index++) {
    final stopwatch = Stopwatch()..start();
    final response = await backend.render(
      ImageRenderRequest(
        requestId: '${preview ? 'preview' : 'full'}-$index',
        sourcePath: source,
        destinationPath:
            '${root.path}/${preview ? 'preview' : 'full'}-$index.jpg',
        scale: preview
            ? ImageRenderScale.preview
            : ImageRenderScale.fullResolution,
        maximumPreviewDimension: preview ? 1400 : null,
        jpegQuality: preview ? 82 : 92,
        enhancement: const EnhancementSettings(
          filter: EnhancementFilter.magicColour,
          brightness: .12,
          contrast: .18,
          sharpen: .35,
          shadowRemoval: true,
        ),
        transform: const Homography(
          h00: 1.02,
          h01: .018,
          h02: 105,
          h10: .012,
          h11: .96,
          h12: 82,
          h20: .000006,
          h21: .000004,
        ),
        outputWidth: 3780,
        outputHeight: 2760,
      ),
    );
    stopwatch.stop();
    switch (response) {
      case ImageProcessingBackendSuccess(:final result):
        last = result;
      case ImageProcessingBackendFailure(:final kind, :final debugDetail):
        fail('native GPU render failed: $kind $debugDetail');
    }
    if (index >= 0) durations.add(stopwatch.elapsedMicroseconds);
    peakRss = max(peakRss, ProcessInfo.currentRss);
  }
  durations.sort();
  return {
    'durationsUs': durations,
    'medianUs': _percentile(durations, .5),
    'p95Us': _percentile(durations, .95),
    'outputWidth': last?.outputWidth,
    'outputHeight': last?.outputHeight,
    'nativeTimings': last?.timings.toString(),
    'rssBeforeBytes': rssBefore,
    'rssSampledPeakBytes': peakRss,
    'rssSampledDeltaBytes': peakRss - rssBefore,
  };
}

int max(int left, int right) => left > right ? left : right;

int _percentile(List<int> sorted, double value) =>
    sorted[((sorted.length - 1) * value).ceil().clamp(0, sorted.length - 1)];
