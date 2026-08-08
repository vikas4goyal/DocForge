/// On-device CPU baseline for the composed page-rendering pipeline.
///
/// Run explicitly because 12-megapixel CPU processing is intentionally too
/// expensive for the normal Tier-3 catalogue:
///
/// ```sh
/// flutter test integration_test/benchmarks/image_processing_cpu_benchmark_test.dart \
///   -d <device-id> --release
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:doc_scanly/app/page_render_job.dart';
import 'package:doc_scanly/core/contracts/geometry/perspective_transform.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';

const _fixtureAsset =
    'integration_test/fixtures/image_processing_benchmark_12mp.jpg';
const _warmups = int.fromEnvironment('BENCHMARK_WARMUPS', defaultValue: 5);
const _samples = int.fromEnvironment('BENCHMARK_SAMPLES', defaultValue: 30);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'records preview and full-resolution CPU baselines',
    (tester) async {
      await tester.runAsync(() async {
        final root = Directory.systemTemp.createTempSync('image_cpu_benchmark');
        try {
          final bytes = await rootBundle.load(_fixtureAsset);
          final source = File('${root.path}/source.jpg');
          await source.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

          final preview = await _measure(
            root: root,
            sourcePath: source.path,
            kind: 'preview',
            isPreview: true,
          );
          final full = await _measure(
            root: root,
            sourcePath: source.path,
            kind: 'full',
            isPreview: false,
          );

          final report = <String, Object?>{
            'schemaVersion': 1,
            'backend': 'dart_cpu_isolate_reference',
            'fixture': _fixtureAsset,
            'fixtureWidth': 4000,
            'fixtureHeight': 3000,
            'buildMode': kReleaseMode
                ? 'release'
                : kProfileMode
                ? 'profile'
                : 'debug',
            'operatingSystem': Platform.operatingSystem,
            'operatingSystemVersion': Platform.operatingSystemVersion,
            'warmups': _warmups,
            'samples': _samples,
            'preview': preview,
            'full': full,
          };

          // A stable prefix lets automation extract the JSON from Flutter logs.
          debugPrint('IMAGE_PROCESSING_BENCHMARK ${jsonEncode(report)}');
        } finally {
          if (root.existsSync()) root.deleteSync(recursive: true);
        }
      });
    },
    timeout: const Timeout(Duration(minutes: 90)),
  );
}

Future<Map<String, Object?>> _measure({
  required Directory root,
  required String sourcePath,
  required String kind,
  required bool isPreview,
}) async {
  final durations = <int>[];
  var minimumRss = ProcessInfo.currentRss;
  var maximumRss = minimumRss;
  int? outputWidth;
  int? outputHeight;

  for (var index = -_warmups; index < _samples; index++) {
    final destination = '${root.path}/$kind-$index.jpg';
    final request = PageRenderRequest(
      sourcePath: sourcePath,
      destinationPath: destination,
      enhancement: const EnhancementSettings(
        filter: EnhancementFilter.magicColour,
        brightness: 0.12,
        contrast: 0.18,
        sharpen: 0.35,
        shadowRemoval: true,
      ),
      isPreview: isPreview,
      transform: const Homography(
        h00: 1.02,
        h01: 0.018,
        h02: 105,
        h10: 0.012,
        h11: 0.96,
        h12: 82,
        h20: 0.000006,
        h21: 0.000004,
      ),
      outputWidth: 3780,
      outputHeight: 2760,
    );

    final stopwatch = Stopwatch()..start();
    final outputPath = pageRenderJob(request);
    stopwatch.stop();

    final outputBytes = await File(outputPath).readAsBytes();
    final decoded = img.decodeJpg(outputBytes)!;
    outputWidth = decoded.width;
    outputHeight = decoded.height;

    minimumRss = minimumRss < ProcessInfo.currentRss
        ? minimumRss
        : ProcessInfo.currentRss;
    maximumRss = maximumRss > ProcessInfo.currentRss
        ? maximumRss
        : ProcessInfo.currentRss;

    if (index >= 0) durations.add(stopwatch.elapsedMicroseconds);
    File(outputPath).deleteSync();
  }

  durations.sort();
  return <String, Object?>{
    'durationsUs': durations,
    'medianUs': _percentile(durations, 0.50),
    'p95Us': _percentile(durations, 0.95),
    'outputWidth': outputWidth,
    'outputHeight': outputHeight,
    'rssBeforeBytes': minimumRss,
    'rssSampledPeakBytes': maximumRss,
    'rssSampledDeltaBytes': maximumRss - minimumRss,
  };
}

int _percentile(List<int> sorted, double percentile) {
  final index = ((sorted.length - 1) * percentile).ceil();
  return sorted[index.clamp(0, sorted.length - 1)];
}
