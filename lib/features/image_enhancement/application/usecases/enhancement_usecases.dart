// ignore_for_file: prefer_initializing_formals

/// Use cases for image enhancement.
library;

import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/telemetry/app_telemetry.dart';
import 'package:doc_scanly/features/image_enhancement/domain/enhancement_rules.dart';

/// Applies enhancement settings to pages, off the UI thread.
class ApplyEnhancement {
  /// Creates the use case over its [_worker] and the [_job] it runs.
  ///
  /// The job is injected rather than referenced directly because the code that
  /// moves pixels is infrastructure, and the application layer may not import
  /// it. It must be a top-level or static function: a closure cannot be sent to
  /// an isolate, and one capturing UI state would reintroduce exactly the
  /// hidden coupling the architecture forbids.
  // A named public `telemetry` parameter is clearer than exposing the private
  // field name solely to use an initializing formal.
  const ApplyEnhancement(
    this._worker,
    this._job, {
    AppTelemetry telemetry = const NoopAppTelemetry(),
  }) : _telemetry = telemetry;

  final BackgroundWorker _worker;
  final IsolateJob<EnhancementRequest, String> _job;

  /// Reports full-resolution enhancement duration and outcomes.
  final AppTelemetry _telemetry;

  /// Renders a downscaled preview of [settings] applied to [sourcePath].
  ///
  /// Runs against a downscaled copy so dragging a slider stays interactive; the
  /// saved page is always recomputed at full resolution, so nothing the user
  /// judged on the preview is lost.
  Future<Result<String>> preview({
    required String sourcePath,
    required String destinationPath,
    required EnhancementSettings settings,
  }) => _worker.run(
    _job,
    EnhancementRequest.preview(
      sourcePath: sourcePath,
      destinationPath: destinationPath,
      settings: settings,
    ),
  );

  /// Applies [settings] to one page.
  ///
  /// [maxDimension] bounds the output. Left null the page keeps its captured
  /// size; given the size the page will actually be drawn at, the filters run
  /// over that many pixels instead of over a capture that is several times
  /// larger and about to be scaled down anyway.
  Future<Result<String>> single({
    required String sourcePath,
    required String destinationPath,
    required EnhancementSettings settings,
    int? maxDimension,
  }) async {
    final trace = await _telemetry.startTrace('page_enhancement');
    trace.putAttribute('filter', settings.filter.name);
    if (maxDimension != null) {
      trace.setMetric('max_dimension', maxDimension);
    }

    try {
      final result = await _worker.run(
        _job,
        EnhancementRequest(
          sourcePath: sourcePath,
          destinationPath: destinationPath,
          settings: settings,
          maxDimension: maxDimension,
        ),
      );
      final outcome = result is Success<String> ? 'success' : 'failure';
      trace.putAttribute('outcome', outcome);
      await _telemetry.logEvent(
        'page_enhanced',
        parameters: {'outcome': outcome, 'filter': settings.filter.name},
      );
      return result;
    } on Object catch (error, stackTrace) {
      trace.putAttribute('outcome', 'exception');
      await _telemetry.recordError(
        error,
        stackTrace,
        reason: 'Full-resolution page enhancement',
      );
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  /// Applies each of [requests] in turn, reporting progress as it goes.
  ///
  /// Cancellation is checked between pages rather than during one, so a page is
  /// either fully written or never started. Cancelling mid-batch therefore
  /// leaves every finished page intact and no half-written file behind, which
  /// is what the spec requires of "apply to all".
  Stream<BatchEvent<String>> batch(
    List<EnhancementRequest> requests, {
    CancellationToken? token,
  }) => _worker.runBatch(_job, requests, token: token);
}

/// Builds the requests that apply one page's settings to a whole session.
///
/// A separate use case from [ApplyEnhancement] because deciding *what* to
/// enhance is a business rule — which pages are affected, where their output
/// goes, and which pages can be skipped entirely — while [ApplyEnhancement] is
/// only concerned with running the work.
class PlanSessionEnhancement {
  /// Creates the use case.
  const PlanSessionEnhancement();

  /// Returns a request per page of [pages] that needs work.
  ///
  /// [destinationFor] names the output file for a page. Pages whose settings
  /// would change nothing are omitted rather than copied: re-encoding an
  /// untouched page costs it a generation of JPEG loss and buys nothing.
  List<EnhancementRequest> call(
    List<PageRef> pages, {
    required String Function(PageRef page) destinationFor,
  }) => [
    for (final page in pages)
      if (EnhancementRules.requiresProcessing(page.enhancement))
        EnhancementRequest(
          sourcePath: page.imagePath,
          destinationPath: destinationFor(page),
          settings: page.enhancement,
        ),
  ];
}
