/// Deterministic iCloud platform seam for tests, previews, and integration runs.
library;

import 'dart:async';

import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/ios_icloud_channel.dart';
import 'package:flutter/services.dart';

/// One immutable iCloud item fixture.
class ScriptedICloudItem {
  /// Creates an item from values accepted by the production channel contract.
  const ScriptedICloudItem({
    required this.relativePath,
    this.isDirectory = false,
    this.availability = 'available',
    this.resourceIdentifier,
    this.sizeBytes = 0,
    this.modifiedMilliseconds,
  });

  /// Path below the app-owned document scope.
  final String relativePath;

  /// Whether the entry is a folder.
  final bool isDirectory;

  /// Stable cloud-content status name.
  final String availability;

  /// Stable native identity, when supplied by the fixture.
  final String? resourceIdentifier;

  /// Fixture byte size.
  final int sizeBytes;

  /// UTC epoch milliseconds, avoiding any wall-clock lookup.
  final int? modifiedMilliseconds;

  /// Converts the fixture to the raw channel representation.
  ICloudItemData toData() => ICloudItemData({
    'relativePath': relativePath,
    'isDirectory': isDirectory,
    'availability': availability,
    'resourceIdentifier': resourceIdentifier,
    'sizeBytes': sizeBytes,
    'modifiedMilliseconds': modifiedMilliseconds,
  });
}

/// A scripted, instance-owned implementation of the native iCloud edge.
///
/// It deliberately has no random values, clock, network, static mutable state,
/// or filesystem paths. A caller mutates it only through explicit methods,
/// which keeps repeated test runs byte-for-byte deterministic.
class ScriptedICloudPlatform implements ICloudPlatformApi {
  /// Creates the platform from immutable starting fixtures.
  ScriptedICloudPlatform({
    this.availabilityValue = 'available',
    this.rootPath = '/fixture/icloud/Documents',
    Map<String, Object?>? marker,
    List<ScriptedICloudItem> items = const [],
    List<String> pickedPaths = const [],
  }) : marker = marker == null ? null : Map.unmodifiable(marker),
       _items = List.of(items),
       _pickedPaths = List.of(pickedPaths);

  /// Current scripted availability string.
  String availabilityValue;

  /// Current scripted root, or null for an unavailable container.
  String? rootPath;

  /// Current marker values.
  Map<String, Object?>? marker;

  final List<ScriptedICloudItem> _items;
  final List<String> _pickedPaths;
  final StreamController<void> _identity = StreamController<void>.broadcast();

  /// Relative paths requested for download, in call order.
  final List<String> downloadRequests = [];

  /// Number of metadata enumerations, for duplicate-trigger assertions.
  int listRequests = 0;

  /// Total platform calls, used to prove Android composition is cloud-inert.
  int operationRequests = 0;

  /// Security-scoped paths released after import, in call order.
  final List<String> releasedPaths = [];

  /// Optional stable platform error returned by the next download.
  PlatformException? nextDownloadFailure;

  /// Replaces the listed items with [items].
  void replaceItems(List<ScriptedICloudItem> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  /// Emits one deterministic identity-change event.
  void emitIdentityChange() => _identity.add(null);

  /// Closes the instance-owned event source.
  Future<void> dispose() => _identity.close();

  @override
  Future<String> availability() async {
    operationRequests++;
    return availabilityValue;
  }

  @override
  Future<String?> documentRootPath() async {
    operationRequests++;
    return rootPath;
  }

  @override
  Future<Map<String, Object?>?> readMarker() async {
    operationRequests++;
    return marker == null ? null : Map.of(marker!);
  }

  @override
  Future<void> writeMarker(Map<String, Object?> marker) async {
    operationRequests++;
    this.marker = Map.unmodifiable(marker);
  }

  @override
  Future<void> deleteMarker() async {
    operationRequests++;
    marker = null;
  }

  @override
  Future<List<ICloudItemData>> listItems() async {
    operationRequests++;
    listRequests++;
    return _items.map((item) => item.toData()).toList(growable: false);
  }

  @override
  Future<void> ensureDownloaded(String relativePath) async {
    operationRequests++;
    downloadRequests.add(relativePath);
    final failure = nextDownloadFailure;
    nextDownloadFailure = null;
    if (failure != null) throw failure;
  }

  @override
  Future<List<String>> pickImportFolder() async {
    operationRequests++;
    return List.of(_pickedPaths);
  }

  @override
  Future<void> releaseImportFolder(List<String> paths) async {
    operationRequests++;
    releasedPaths.addAll(paths);
  }

  @override
  Stream<void> get identityChanges => _identity.stream;
}
