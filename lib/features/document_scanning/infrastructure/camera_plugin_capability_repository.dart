/// Camera-plugin implementation of active-camera capability probing.
library;

import 'package:camera/camera.dart';
import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/camera_capability_repository.dart';

/// One actual dimension pair observed after requesting a plugin preset.
class CameraPresetMeasurement {
  /// Creates a probe measurement.
  const CameraPresetMeasurement({
    required this.preset,
    required this.width,
    required this.height,
  });

  /// Preset requested from the camera plugin.
  final ResolutionPreset preset;

  /// Actual width reported after controller initialisation.
  final int width;

  /// Actual height reported after controller initialisation.
  final int height;

  /// Number of pixels in the reported dimensions.
  int get pixelCount => width * height;
}

/// Probes preset requests against the currently active camera.
abstract interface class CameraPresetProbe {
  /// Returns actual dimensions observed for satisfiable plugin presets.
  ///
  /// An empty list means this plugin/platform cannot expose useful dimensions.
  Future<List<CameraPresetMeasurement>> probeActiveCamera();
}

/// Probes Flutter camera controllers and maps only honestly satisfiable tiers.
class CameraPluginCapabilityRepository implements CameraCapabilityRepository {
  /// Creates the repository over an injected plugin probe.
  CameraPluginCapabilityRepository(this._probe);

  final CameraPresetProbe _probe;

  // Instance-scoped cache of the last successful probe. Capture re-resolves the
  // preference before every shot, and probing opens a controller per preset —
  // doing that per shot would be slow and, worse, would try to open the camera
  // while the capture controller already holds it. The first resolve always
  // happens before the first capture opens the camera, so the cache is filled
  // while the device is free. Failures are never cached, so Retry re-probes.
  List<SupportedCameraResolution>? _cached;
  Future<Result<List<SupportedCameraResolution>>>? _inFlight;

  @override
  Future<Result<List<SupportedCameraResolution>>> loadActiveResolutions({
    bool refresh = false,
  }) {
    final cached = _cached;
    if (!refresh && cached != null) {
      return Future.value(
        Result<List<SupportedCameraResolution>>.success(cached),
      );
    }
    // Concurrent callers share one probe rather than each opening the camera.
    return _inFlight ??= _probeAndCache().whenComplete(() => _inFlight = null);
  }

  Future<Result<List<SupportedCameraResolution>>> _probeAndCache() async {
    final result = await _measure();
    if (result case Success(:final value)) _cached = value;
    return result;
  }

  Future<Result<List<SupportedCameraResolution>>> _measure() async {
    try {
      final measurements = await _probe.probeActiveCamera();
      if (measurements.isEmpty) {
        return const Result<List<SupportedCameraResolution>>.success([]);
      }

      final orderedMeasurements = measurements.toList()
        ..sort(_compareMeasurementsAscending);
      final byTier = <CameraResolutionTier, SupportedCameraResolution>{};
      for (final measurement in orderedMeasurements) {
        final satisfied = CameraResolutionTier.canonical
            .where(
              (tier) => tier.isSatisfiedBy(
                width: measurement.width,
                height: measurement.height,
              ),
            )
            .toList();
        if (satisfied.isEmpty) continue;
        final tier = satisfied.last;
        // One plugin preset can clear several thresholds. Advertise only its
        // highest honest tier so one 4K output does not appear as four choices.
        // Measurements arrive smallest first, so a later one in the same tier
        // replaces an earlier: each tier keeps its *largest* measurement. That
        // is what makes the top entry — and so Full resolution — the camera's
        // real maximum rather than the smallest preset that reached the tier.
        byTier[tier] = SupportedCameraResolution(
          tier: tier,
          width: measurement.width,
          height: measurement.height,
          // Replayed verbatim when the camera opens, so the selected tier is
          // requested exactly as it was measured.
          requestKey: measurement.preset.name,
        );
      }
      final resolutions = byTier.values.toList()
        ..sort((left, right) => left.tier.compareTo(right.tier));
      return Result<List<SupportedCameraResolution>>.success(resolutions);
    } on CameraException catch (error) {
      return Result<List<SupportedCameraResolution>>.failure(
        Failure.camera(debugDetail: '${error.code}: ${error.description}'),
      );
    } on Object catch (error) {
      return Result<List<SupportedCameraResolution>>.failure(
        Failure.camera(debugDetail: '$error'),
      );
    }
  }

  static int _compareMeasurementsAscending(
    CameraPresetMeasurement left,
    CameraPresetMeasurement right,
  ) {
    final byPixels = left.pixelCount.compareTo(right.pixelCount);
    if (byPixels != 0) return byPixels;
    final byWidth = left.width.compareTo(right.width);
    if (byWidth != 0) return byWidth;
    return left.height.compareTo(right.height);
  }
}

/// Live Flutter-camera probe used by the composition root.
class FlutterCameraPresetProbe implements CameraPresetProbe {
  /// Creates a probe that prefers the rear camera for document scanning.
  const FlutterCameraPresetProbe();

  @override
  Future<List<CameraPresetMeasurement>> probeActiveCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return const [];
    final camera = cameras.firstWhere(
      (candidate) => candidate.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final measurements = <CameraPresetMeasurement>[];

    for (final preset in const [
      ResolutionPreset.high,
      ResolutionPreset.veryHigh,
      ResolutionPreset.ultraHigh,
      // Without `max` the probe could never see past 2160p, so "Full
      // resolution" was capped well below a 12 MP sensor's real output.
      ResolutionPreset.max,
    ]) {
      CameraController? controller;
      try {
        controller = CameraController(camera, preset, enableAudio: false);
        await controller.initialize();
        final size = controller.value.previewSize;
        if (size != null && size.width > 0 && size.height > 0) {
          measurements.add(
            CameraPresetMeasurement(
              preset: preset,
              width: size.width.round(),
              height: size.height.round(),
            ),
          );
        }
      } on CameraException catch (error) {
        // A platform may reject one preset while supporting the next. Only
        // explicit unsupported/configuration errors are skipped; permission or
        // busy-camera failures must reach the UI as failures with Retry.
        final code = error.code.toLowerCase();
        if (!code.contains('supported') && !code.contains('configuration')) {
          rethrow;
        }
      } finally {
        await controller?.dispose();
      }
    }

    return measurements;
  }
}
