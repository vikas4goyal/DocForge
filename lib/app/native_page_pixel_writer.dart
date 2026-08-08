/// Adapts the typed native-first backend to the application's page writer.
library;

import 'package:doc_scanly/app/page_render_job.dart';
import 'package:doc_scanly/core/contracts/geometry/page_geometry.dart';
import 'package:doc_scanly/core/contracts/image_processing/image_processing.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/time/clock.dart';

/// The one cancellable pixel writer used by crop, enhance, preview, and save.
class NativePagePixelWriter {
  /// Creates a writer over the injected native-first [backend].
  NativePagePixelWriter(this.backend, this.ids);

  /// Native-first GPU renderer with deterministic CPU fallback.
  final ImageProcessingBackend backend;

  /// Generates request identifiers without global mutable state.
  final IdGenerator ids;

  final Map<String, String> _activeRequests = {};

  /// Renders one page and cancels the previous request in the same [scope].
  Future<Result<void>> call(
    PageRenderPlan plan, {
    required String destinationPath,
    ComposedGeometry? transform,
    String? scope,
  }) async {
    final requestId = ids.generate();
    if (scope != null) {
      final previous = _activeRequests[scope];
      if (previous != null) await backend.cancel(previous);
      _activeRequests[scope] = requestId;
    }

    try {
      final response = await backend.render(
        ImageRenderRequest(
          requestId: requestId,
          sourcePath: plan.originalImagePath,
          destinationPath: destinationPath,
          scale: plan.scale == RenderScale.preview
              ? ImageRenderScale.preview
              : ImageRenderScale.fullResolution,
          enhancement: plan.enhancement,
          jpegQuality: plan.scale == RenderScale.preview
              ? previewRenderQuality
              : renderQuality,
          transform: transform?.transform,
          outputWidth: transform?.outputSize.width,
          outputHeight: transform?.outputSize.height,
          maximumPreviewDimension: plan.scale == RenderScale.preview
              ? previewMaxDimension
              : null,
        ),
      );
      return switch (response) {
        ImageProcessingBackendSuccess() => const Result<void>.success(null),
        ImageProcessingBackendFailure(:final kind, :final debugDetail) =>
          Result<void>.failure(_failure(kind, debugDetail)),
      };
    } finally {
      if (scope != null && _activeRequests[scope] == requestId) {
        _activeRequests.remove(scope);
      }
    }
  }

  /// Cancels the request currently associated with [scope].
  Future<void> cancel(String scope) async {
    final requestId = _activeRequests.remove(scope);
    if (requestId != null) await backend.cancel(requestId);
  }
}

Failure _failure(ImageProcessingFailureKind kind, String? detail) =>
    switch (kind) {
      ImageProcessingFailureKind.corruptInput => Failure.corruptFile(
        debugDetail: detail,
      ),
      ImageProcessingFailureKind.storageFull => Failure.storageFull(
        debugDetail: detail,
      ),
      ImageProcessingFailureKind.storage ||
      ImageProcessingFailureKind.invalidPath => Failure.storage(
        debugDetail: detail,
      ),
      ImageProcessingFailureKind.cancelled => const Failure.cancelled(),
      _ => Failure.unexpected(debugDetail: detail),
    };
