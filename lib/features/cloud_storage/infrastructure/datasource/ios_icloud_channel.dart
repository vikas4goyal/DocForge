/// Flutter channel for the iOS iCloud Documents container.
library;

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
  });

  /// Method-channel name shared with Swift.
  static const methodChannelName = 'com.bruxkey.docscanly/icloud';

  /// Identity-event channel name shared with Swift.
  static const eventChannelName = 'com.bruxkey.docscanly/icloud_identity';

  /// Method transport.
  final MethodChannel methods;

  /// Event transport.
  final EventChannel events;

  @override
  Future<String> availability() async =>
      await methods.invokeMethod<String>('availability') ?? 'unavailable';

  @override
  Future<String?> documentRootPath() =>
      methods.invokeMethod<String>('documentRootPath');

  @override
  Future<Map<String, Object?>?> readMarker() async {
    final value = await methods.invokeMapMethod<String, Object?>('readMarker');
    return value == null ? null : Map<String, Object?>.from(value);
  }

  @override
  Future<void> writeMarker(Map<String, Object?> marker) =>
      methods.invokeMethod<void>('writeMarker', marker);

  @override
  Future<void> deleteMarker() => methods.invokeMethod<void>('deleteMarker');

  @override
  Future<List<ICloudItemData>> listItems() async {
    final values = await methods.invokeListMethod<Object?>('listItems') ?? [];
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
  Future<void> ensureDownloaded(String relativePath) => methods
      .invokeMethod<void>('ensureDownloaded', {'relativePath': relativePath});

  @override
  Future<List<String>> pickImportFolder() async =>
      (await methods.invokeListMethod<String>('pickImportFolder')) ?? [];

  @override
  Future<void> releaseImportFolder(List<String> paths) =>
      methods.invokeMethod<void>('releaseImportFolder', {'paths': paths});

  @override
  Stream<void> get identityChanges =>
      events.receiveBroadcastStream().map((_) {});
}
