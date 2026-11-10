/// Active-camera capability boundary owned by document scanning.
library;

import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/failures/result.dart';

/// Reports concrete still-image resolutions supported by the active camera.
///
/// An empty successful list means the platform plugin cannot enumerate exact
/// capabilities. Callers then request its maximum preset and verify the actual
/// captured dimensions. A failure instead means the camera could not be
/// queried and should be surfaced with Retry.
abstract interface class CameraCapabilityRepository {
  /// Loads resolutions for whichever camera is currently active.
  ///
  /// Implementations may answer from a cache of the last successful query,
  /// because probing can open the camera several times and capture re-resolves
  /// before every shot. [refresh] bypasses that cache; callers pass it when the
  /// user retries or the active camera may have changed — a list from the rear
  /// camera is not valid evidence about the front camera.
  Future<Result<List<SupportedCameraResolution>>> loadActiveResolutions({
    bool refresh = false,
  });
}
