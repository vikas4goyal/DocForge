/// Flutter channel for the iOS iCloud Documents container.
library;

import 'dart:async';

import 'package:doc_scanly/core/telemetry/app_telemetry.dart';
import 'package:flutter/services.dart';

/// Raw metadata returned by the native iCloud bridge.
class ICloudItemData {
  /// Creates raw item metadata.
  const ICloudItemData(this.values);

  /// Platform values with stable string keys.
  final Map<String, Object?> values;
}

/// The narrow platform edge used by the cloud repository.
abstract interface class ICloudPlatformApi {
  /// Reads the stable availability status string.
  Future<String> availability();

  /// Resolves the container's Documents root.
  Future<String?> documentRootPath();

  /// Reads marker JSON values, or null when absent.
  Future<Map<String, Object?>?> readMarker();

  /// Writes marker JSON values.
  Future<void> writeMarker(Map<String, Object?> marker);

  /// Removes the marker when moving the authority back to local storage.
  Future<void> deleteMarker();

  /// Lists document-scope metadata.
  Future<List<ICloudItemData>> listItems();

  /// Starts/materialises the item at [relativePath].
  Future<void> ensureDownloaded(String relativePath);

  /// Returns paths selected by the user for one import.
  Future<List<String>> pickImportFolder();

  /// Releases security-scoped access for [paths].
  Future<void> releaseImportFolder(List<String> paths);

  /// Emits when the iCloud identity changes.
  Stream<void> get identityChanges;
}

/// Invokes DocScanly's first-party Swift bridge.
class IosICloudChannel implements ICloudPlatformApi {
  /// Creates the bridge over injectable channels.
  const IosICloudChannel({
    this.methods = const MethodChannel(methodChannelName),
    this.events = const EventChannel(eventChannelName),
    this.invocationTimeout = defaultInvocationTimeout,
    this.telemetry = const NoopAppTelemetry(),
  });

  /// Method-channel name shared with Swift.
  static const methodChannelName = 'com.bruxkey.docscanly/icloud';

  /// Identity-event channel name shared with Swift.
  static const eventChannelName = 'com.bruxkey.docscanly/icloud_identity';

  /// Maximum time startup waits for an iCloud platform response.
  static const defaultInvocationTimeout = Duration(seconds: 10);

  /// Method transport.
  final MethodChannel methods;

  /// Event transport.
  final EventChannel events;

  /// Bound for launch-time probes that may otherwise wait indefinitely.
  final Duration invocationTimeout;

  /// Privacy-safe non-fatal reporting for native iCloud failures.
  final AppTelemetry telemetry;

  @override
  Future<String> availability() async =>
      await _invoke<String?>(
        'availability',
        () => methods.invokeMethod<String>('availability'),
        timeout: invocationTimeout,
        timeoutFallback: () => 'unavailable',
      ) ??
      'unavailable';

  @override
  Future<String?> documentRootPath() => _invoke<String?>(
    'document_root',
    () => methods.invokeMethod<String>('documentRootPath'),
    timeout: invocationTimeout,
    timeoutFallback: () => null,
  );

  @override
  Future<Map<String, Object?>?> readMarker() async {
    final value = await _invoke<Map<String, Object?>?>(
      'read_marker',
      () => methods.invokeMapMethod<String, Object?>('readMarker'),
      timeout: invocationTimeout,
      timeoutFallback: () => null,
    );
    return value == null ? null : Map<String, Object?>.from(value);
  }

  @override
  Future<void> writeMarker(Map<String, Object?> marker) => _invoke<void>(
    'write_marker',
    () => methods.invokeMethod<void>('writeMarker', marker),
  );

  @override
  Future<void> deleteMarker() => _invoke<void>(
    'delete_marker',
    () => methods.invokeMethod<void>('deleteMarker'),
  );

  @override
  Future<List<ICloudItemData>> listItems() async {
    final values =
        await _invoke<List<Object?>?>(
          'list_items',
          () => methods.invokeListMethod<Object?>('listItems'),
        ) ??
        [];
    return values
        .whereType<Map<Object?, Object?>>()
        .map(
          (entry) => ICloudItemData(
            entry.map((key, value) => MapEntry('$key', value)),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> ensureDownloaded(String relativePath) => _invoke<void>(
    'ensure_downloaded',
    () => methods.invokeMethod<void>('ensureDownloaded', {
      'relativePath': relativePath,
    }),
  );

  @override
  Future<List<String>> pickImportFolder() async =>
      (await _invoke<List<String?>?>(
        'pick_import_folder',
        () => methods.invokeListMethod<String>('pickImportFolder'),
      ))?.whereType<String>().toList(growable: false) ??
      [];

  @override
  Future<void> releaseImportFolder(List<String> paths) => _invoke<void>(
    'release_import_folder',
    () => methods.invokeMethod<void>('releaseImportFolder', {'paths': paths}),
  );

  @override
  Stream<void> get identityChanges =>
      events.receiveBroadcastStream().map((_) {});

  Future<T> _invoke<T>(
    String operation,
    Future<T> Function() invoke, {
    Duration? timeout,
    T Function()? timeoutFallback,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final future = invoke();
      return await (timeout == null ? future : future.timeout(timeout));
    } on TimeoutException catch (error, stackTrace) {
      _log(
        operation,
        'timeout',
        stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
      );
      if (timeoutFallback != null) return timeoutFallback();
      rethrow;
    } on Object catch (error, stackTrace) {
      _log(
        operation,
        'error',
        stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void _log(
    String operation,
    String outcome,
    Duration elapsed, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final message =
        'operation=$operation outcome=$outcome elapsedMs=${elapsed.inMilliseconds}';
    if (error != null) {
      unawaited(
        telemetry.recordError(
          error,
          stackTrace ?? StackTrace.current,
          reason: 'iCloud $message',
        ),
      );
    }
  }
}
