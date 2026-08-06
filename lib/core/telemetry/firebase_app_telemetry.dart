/// Firebase implementation of the application's telemetry boundary.
library;

import 'package:doc_scanly/core/telemetry/app_telemetry.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

/// Sends operational events to Firebase without exposing user content.
class FirebaseAppTelemetry implements AppTelemetry {
  /// Creates the production telemetry adapter.
  const FirebaseAppTelemetry();

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } on Object {
      // Observability must never make the user operation fail.
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
      );
    } on Object {
      // A reporting failure is not an application failure.
    }
  }

  @override
  Future<AppTrace> startTrace(String name) async {
    try {
      final trace = FirebasePerformance.instance.newTrace(name);
      await trace.start();
      return _FirebaseAppTrace(trace);
    } on Object {
      return const NoopAppTrace();
    }
  }
}

class _FirebaseAppTrace implements AppTrace {
  const _FirebaseAppTrace(this._trace);

  final Trace _trace;

  @override
  void putAttribute(String name, String value) {
    try {
      _trace.putAttribute(name, value);
    } on Object {
      // The operation being measured remains authoritative.
    }
  }

  @override
  void setMetric(String name, int value) {
    try {
      _trace.setMetric(name, value);
    } on Object {
      // The operation being measured remains authoritative.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _trace.stop();
    } on Object {
      // The operation being measured remains authoritative.
    }
  }
}
