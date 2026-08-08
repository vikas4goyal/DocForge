import 'package:camera/camera.dart';
import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/camera_capability_repository.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/camera_plugin_capability_repository.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapabilityRepository implements CameraCapabilityRepository {
  _CapabilityRepository(this.responses);

  final List<Result<List<SupportedCameraResolution>>> responses;
  int calls = 0;

  @override
  Future<Result<List<SupportedCameraResolution>>>
  loadActiveResolutions() async => responses[calls++];
}

class _PresetProbe implements CameraPresetProbe {
  _PresetProbe(this.measurements);

  final List<CameraPresetMeasurement> measurements;

  @override
  Future<List<CameraPresetMeasurement>> probeActiveCamera() async =>
      measurements;
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

      expect(result.valueOrNull, [hd, fullHd, ultraHd]);
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
      'resolves and requests the chosen dimensions before every capture',
      () async {
        final repository = _CapabilityRepository([
          Result<List<SupportedCameraResolution>>.success([hd, fullHd]),
          Result<List<SupportedCameraResolution>>.success([hd, fullHd]),
        ]);
        final scanner = FakeScannerRepository();
        final capture = CapturePage(
          scanner,
          const FullPageEdgeDetector(),
          resolveCaptureResolution: ResolveCaptureResolution(
            LoadCameraResolutions(repository),
          ),
        );

        await capture(
          desired: DesiredCameraResolution.tier(CameraResolutionTier.hd720),
        );
        await capture(
          desired: DesiredCameraResolution.tier(CameraResolutionTier.hd720),
        );

        expect(scanner.requestedResolutions, [hd, hd]);
        expect(repository.calls, 2);
      },
    );

    test('Full default requests active-camera maximum', () async {
      final repository = _CapabilityRepository([
        Result<List<SupportedCameraResolution>>.success([hd, fullHd]),
      ]);
      final scanner = FakeScannerRepository();
      final capture = CapturePage(
        scanner,
        const FullPageEdgeDetector(),
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
        const FullPageEdgeDetector(),
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
  });
}
