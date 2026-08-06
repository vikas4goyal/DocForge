/// Privacy-conscious operational telemetry used at application boundaries.
library;

/// A timed operation reported to the performance backend.
abstract interface class AppTrace {
  /// Adds a low-cardinality value used to filter trace samples.
  void putAttribute(String name, String value);

  /// Records a numeric measurement alongside the trace duration.
  void setMetric(String name, int value);

  /// Finishes the trace. Every started trace must be stopped.
  Future<void> stop();
}

/// Analytics, performance, and non-fatal error reporting.
///
/// Callers must never send document names, paths, OCR text, image data, or
/// other user content. Parameters are limited to operational outcomes and
/// coarse settings that cannot identify a document or a person.
abstract interface class AppTelemetry {
  /// Starts a custom performance trace.
  Future<AppTrace> startTrace(String name);

  /// Records an analytics event.
  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  /// Records a caught error as a non-fatal Crashlytics report.
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  });
}

/// Telemetry used by tests, previews, and injected non-production graphs.
class NoopAppTelemetry implements AppTelemetry {
  /// Creates no-op telemetry.
  const NoopAppTelemetry();

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) async {}

  @override
  Future<AppTrace> startTrace(String name) async => const NoopAppTrace();
}

/// A trace that deliberately records nothing.
class NoopAppTrace implements AppTrace {
  /// Creates a no-op trace.
  const NoopAppTrace();

  @override
  void putAttribute(String name, String value) {}

  @override
  void setMetric(String name, int value) {}

  @override
  Future<void> stop() async {}
}
