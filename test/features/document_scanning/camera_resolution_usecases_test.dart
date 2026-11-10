import 'package:camera/camera.dart';
import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/camera_capability_repository.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/camera_plugin_capability_repository.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapabilityRepository implements CameraCapabilityRepository {
  _CapabilityRepository(this.responses);

  final List<Result<List<SupportedCameraResolution>>> responses;
  int calls = 0;

  @override
  Future<Result<List<SupportedCameraResolution>>> loadActiveResolutions({
    bool refresh = false,
  }) async => responses[calls++];
}

/// Answers every load with the same supported list, as a cache would.
class _FixedCapabilities implements CameraCapabilityRepository {
  _FixedCapabilities(this.resolutions);

  final List<SupportedCameraResolution> resolutions;

  @override
  Future<Result<List<SupportedCameraResolution>>> loadActiveResolutions({
    bool refresh = false,
  }) async => Result<List<SupportedCameraResolution>>.success(resolutions);
}

class _PresetProbe implements CameraPresetProbe {
  _PresetProbe(this.measurements);

  final List<CameraPresetMeasurement> measurements;

  /// How many times the camera was probed.
  var probes = 0;

  /// When set, the next probe throws it instead of answering.
  Exception? failNext;

  @override
  Future<List<CameraPresetMeasurement>> probeActiveCamera() async {
    probes++;
    final failure = failNext;
    if (failure != null) {
      failNext = null;
      throw failure;
    }
    return measurements;
  }
}

void main() {
  final hd = SupportedCameraResolution(
    tier: CameraResolutionTier.hd720,
    width: 1280,
    height: 720,
  );
  final fullHd = SupportedCameraResolution(
    tier: CameraResolutionTier.fullHd1080,
    width: 1920,
    height: 1080,
  );
  final ultraHd = SupportedCameraResolution(
    tier: CameraResolutionTier.ultraHd4k,
    width: 4032,
    height: 3024,
  );

  group('CameraPluginCapabilityRepository', () {
    test('maps only the highest tier each actual preset satisfies', () async {
      final repository = CameraPluginCapabilityRepository(
        _PresetProbe([
          const CameraPresetMeasurement(
            preset: ResolutionPreset.high,
            width: 1280,
            height: 720,
          ),
          const CameraPresetMeasurement(
            preset: ResolutionPreset.veryHigh,
            width: 1920,
            height: 1080,
          ),
          const CameraPresetMeasurement(
            preset: ResolutionPreset.ultraHigh,
            width: 4032,
            height: 3024,
          ),
        ]),
      );

      final result = await repository.loadActiveResolutions();

      expect(result.valueOrNull, [
        hd.copyWith(requestKey: 'high'),
        fullHd.copyWith(requestKey: 'veryHigh'),
        ultraHd.copyWith(requestKey: 'ultraHigh'),
      ]);
    });

    test(
      'each tier keeps its largest measurement, so Full replays max',
      () async {
        final repository = CameraPluginCapabilityRepository(
          _PresetProbe([
            const CameraPresetMeasurement(
              preset: ResolutionPreset.ultraHigh,
              width: 3840,
              height: 2160,
            ),
            const CameraPresetMeasurement(
              preset: ResolutionPreset.max,
              width: 4032,
              height: 3024,
            ),
            const CameraPresetMeasurement(
              preset: ResolutionPreset.veryHigh,
              width: 2560,
              height: 1440,
            ),
          ]),
        );

        final resolutions =
            (await repository.loadActiveResolutions()).valueOrNull!;

        expect(resolutions.map((r) => r.tier), [
          CameraResolutionTier.qhd2k,
          CameraResolutionTier.ultraHd4k,
        ]);
        // 2K is requested by the preset that measured 2K — never the 4K one.
        expect(resolutions.first.requestKey, 'veryHigh');
        expect(resolutions.last.requestKey, 'max');
        expect(
          const DesiredCameraResolution.fullResolution()
              .resolve(resolutions)
              ?.requestKey,
          'max',
        );
      },
    );

    test(
      'answers from cache until refreshed, and never caches a failure',
      () async {
        final probe = _PresetProbe([
          const CameraPresetMeasurement(
            preset: ResolutionPreset.high,
            width: 1280,
            height: 720,
          ),
        ]);
        final repository = CameraPluginCapabilityRepository(probe);

        probe.failNext = Exception('camera busy');
        final failed = await repository.loadActiveResolutions();
        expect(failed.isFailure, isTrue);

        await repository.loadActiveResolutions();
        await repository.loadActiveResolutions();
        expect(probe.probes, 2, reason: 'a failure must not be cached');

        await repository.loadActiveResolutions(refresh: true);
        expect(probe.probes, 3);
      },
    );

    test('concurrent loads share one probe', () async {
      final probe = _PresetProbe(const []);
      final repository = CameraPluginCapabilityRepository(probe);

      await Future.wait([
        repository.loadActiveResolutions(),
        repository.loadActiveResolutions(),
      ]);

      expect(probe.probes, 1);
    });

    test('reports unavailable enumeration as an empty success', () async {
      final repository = CameraPluginCapabilityRepository(_PresetProbe([]));

      final result = await repository.loadActiveResolutions();

      expect(result, const Result<List<SupportedCameraResolution>>.success([]));
    });
  });

  group('LoadCameraResolutions and ResolveCaptureResolution', () {
    test('Full resolution chooses the active-camera maximum', () async {
      final repository = _CapabilityRepository([
        Result<List<SupportedCameraResolution>>.success([fullHd, ultraHd, hd]),
      ]);
      final resolve = ResolveCaptureResolution(
        LoadCameraResolutions(repository),
      );

      final result = await resolve(
        const DesiredCameraResolution.fullResolution(),
      );

      expect(result.valueOrNull, ultraHd);
    });

    test('chooses exact and nearest-lower supported tiers', () async {
      final repository = _CapabilityRepository([
        Result<List<SupportedCameraResolution>>.success([hd, fullHd, ultraHd]),
        Result<List<SupportedCameraResolution>>.success([hd, fullHd, ultraHd]),
      ]);
      final resolve = ResolveCaptureResolution(
        LoadCameraResolutions(repository),
      );

      expect(
        (await resolve(
          DesiredCameraResolution.tier(CameraResolutionTier.fullHd1080),
        )).valueOrNull,
        fullHd,
      );
      expect(
        (await resolve(
          DesiredCameraResolution.tier(CameraResolutionTier.qhd2k),
        )).valueOrNull,
        fullHd,
      );
    });

    test(
      'falls back to active-camera maximum when no lower tier exists',
      () async {
        final repository = _CapabilityRepository([
          Result<List<SupportedCameraResolution>>.success([fullHd, ultraHd]),
        ]);
        final resolve = ResolveCaptureResolution(
          LoadCameraResolutions(repository),
        );
        final unmatchedLowest = CameraResolutionTier(
          id: 'minimum',
          label: 'Minimum',
          shortEdge: 1,
          longEdge: 1,
          rank: 0,
        );

        expect(
          (await resolve(
            DesiredCameraResolution.tier(unmatchedLowest),
          )).valueOrNull,
          ultraHd,
        );
      },
    );

    test('re-queries after a camera switch', () async {
      final repository = _CapabilityRepository([
        Result<List<SupportedCameraResolution>>.success([hd, ultraHd]),
        Result<List<SupportedCameraResolution>>.success([hd]),
      ]);
      final resolve = ResolveCaptureResolution(
        LoadCameraResolutions(repository),
      );

      expect(
        (await resolve(
          const DesiredCameraResolution.fullResolution(),
        )).valueOrNull,
        ultraHd,
      );
      expect(
        (await resolve(
          const DesiredCameraResolution.fullResolution(),
        )).valueOrNull,
        hd,
      );
      expect(repository.calls, 2);
    });

    test(
      'unavailable probing selects plugin maximum and stays offline',
      () async {
        final repository = _CapabilityRepository([
          const Result<List<SupportedCameraResolution>>.success([]),
        ]);
        final resolve = ResolveCaptureResolution(
          LoadCameraResolutions(repository),
        );

        final result = await resolve(
          const DesiredCameraResolution.fullResolution(),
        );

        expect(result, const Result<SupportedCameraResolution?>.success(null));
      },
    );

    test('propagates a capability failure for Retry', () async {
      final repository = _CapabilityRepository([
        const Result<List<SupportedCameraResolution>>.failure(Failure.camera()),
      ]);

      final result = await ResolveCaptureResolution(
        LoadCameraResolutions(repository),
      )(const DesiredCameraResolution.fullResolution());

      expect(result, isA<Failed<SupportedCameraResolution?>>());
    });
  });

  group('capture resolution orchestration', () {
    test(
      're-opens at the resolved resolution after the camera is released',
      () async {
        final repository = _CapabilityRepository([
          Result<List<SupportedCameraResolution>>.success([hd, fullHd]),
          Result<List<SupportedCameraResolution>>.success([hd, fullHd]),
        ]);
        final scanner = FakeScannerRepository();
        final capture = CapturePage(
          scanner,
          resolveCaptureResolution: ResolveCaptureResolution(
            LoadCameraResolutions(repository),
          ),
        );

        await capture(
          desired: DesiredCameraResolution.tier(CameraResolutionTier.hd720),
        );
        expect(scanner.requestedResolutions, [hd]);
        expect(repository.calls, 1);

        await scanner.dispose();
        await capture(
          desired: DesiredCameraResolution.tier(CameraResolutionTier.hd720),
        );

        expect(scanner.requestedResolutions, [hd, hd]);
        expect(repository.calls, 2);
      },
    );

    test('an unchanged preference does not re-open an open camera', () async {
      final scanner = FakeScannerRepository();
      final capture = CapturePage(
        scanner,
        resolveCaptureResolution: ResolveCaptureResolution(
          LoadCameraResolutions(_FixedCapabilities([hd, fullHd])),
        ),
      );
      final desired = DesiredCameraResolution.tier(CameraResolutionTier.hd720);

      await capture(desired: desired);
      await capture(desired: desired);
      await capture(desired: desired);

      expect(scanner.requestedResolutions, [hd]);
      expect(scanner.captures, hasLength(3));
    });

    test(
      'a preference changed while the camera is open applies to the next shot',
      () async {
        final scanner = FakeScannerRepository();
        final capture = CapturePage(
          scanner,
          resolveCaptureResolution: ResolveCaptureResolution(
            LoadCameraResolutions(_FixedCapabilities([hd, fullHd])),
          ),
        );

        await capture(
          desired: DesiredCameraResolution.tier(CameraResolutionTier.hd720),
        );
        expect(scanner.isReady, isTrue);
        await capture();

        // Re-opened at the new size before the second shot, not at the next
        // camera session.
        expect(scanner.requestedResolutions, [hd, fullHd]);
        expect(scanner.captures, hasLength(2));
      },
    );

    test('a failed re-resolve is surfaced and nothing is captured', () async {
      final scanner = FakeScannerRepository();
      final capture = CapturePage(
        scanner,
        resolveCaptureResolution: ResolveCaptureResolution(
          LoadCameraResolutions(
            _CapabilityRepository([
              Result<List<SupportedCameraResolution>>.success([hd]),
              const Result<List<SupportedCameraResolution>>.failure(
                Failure.camera(debugDetail: 'probe failed'),
              ),
            ]),
          ),
        ),
      );

      await capture();
      final second = await capture();

      expect(second.failureOrNull, isA<CameraFailure>());
      expect(scanner.captures, hasLength(1));
    });

    test('Full default requests active-camera maximum', () async {
      final repository = _CapabilityRepository([
        Result<List<SupportedCameraResolution>>.success([hd, fullHd]),
      ]);
      final scanner = FakeScannerRepository();
      final capture = CapturePage(
        scanner,
        resolveCaptureResolution: ResolveCaptureResolution(
          LoadCameraResolutions(repository),
        ),
      );

      await capture();

      expect(scanner.requestedResolutions, [fullHd]);
    });

    test('unavailable enumeration requests plugin maximum', () async {
      final repository = _CapabilityRepository([
        const Result<List<SupportedCameraResolution>>.success([]),
      ]);
      final scanner = FakeScannerRepository();
      final capture = CapturePage(
        scanner,
        resolveCaptureResolution: ResolveCaptureResolution(
          LoadCameraResolutions(repository),
        ),
      );

      await capture();

      expect(scanner.requestedResolutions, [isNull]);
      expect(resolutionPresetFor(null), ResolutionPreset.max);
    });

    test('maps resolved tiers to satisfiable plugin presets', () {
      expect(resolutionPresetFor(hd), ResolutionPreset.high);
      expect(resolutionPresetFor(fullHd), ResolutionPreset.veryHigh);
      expect(resolutionPresetFor(ultraHd), ResolutionPreset.ultraHigh);
    });

    test('replays the measured request rather than guessing from the tier', () {
      final qhd = SupportedCameraResolution(
        tier: CameraResolutionTier.qhd2k,
        width: 2560,
        height: 1440,
        requestKey: 'veryHigh',
      );

      expect(resolutionPresetFor(qhd), ResolutionPreset.veryHigh);
      expect(
        resolutionPresetFor(ultraHd.copyWith(requestKey: 'max')),
        ResolutionPreset.max,
      );
      // An unknown key (a newer plugin's preset) falls back to the tier.
      expect(
        resolutionPresetFor(hd.copyWith(requestKey: 'futurePreset')),
        ResolutionPreset.high,
      );
    });
  });
}
