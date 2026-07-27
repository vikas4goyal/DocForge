/// The Dart side of the Android MediaStore bridge.
///
/// Android 10 introduced scoped storage, which forbids writing arbitrary paths
/// into shared `Documents/`. MediaStore is the only route that reaches a
/// user-visible folder with no permission prompt and no folder picker, and no
/// published plugin exposes nested-folder creation and enumeration together —
/// see `design.md` D3 for the alternatives that were rejected.
///
/// Everything crosses the channel as plain maps and lists so the payload stays
/// inspectable in a test; the channel itself is injected so a fake can assert
/// the arguments without a device.
library;

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// Thrown by [MediaStoreChannel] when the platform refuses an operation.
///
/// Carries the platform's error [code] so the store can distinguish the cases
/// it must handle specifically — a full disk, a missing item, and an OEM build
/// that will not create a nested folder — from faults it can only report.
@immutable
class MediaStoreException implements Exception {
  /// Creates an exception describing a platform refusal.
  const MediaStoreException(this.code, this.message);

  /// The platform error code, as sent by the Android side.
  final String code;

  /// A human-readable description, for diagnosis only.
  final String? message;

  /// Whether the device reported that it has no space left.
  bool get isStorageFull => code == codeStorageFull;

  /// Whether the addressed item does not exist.
  bool get isNotFound => code == codeNotFound;

  /// Whether the platform refused to create a nested folder.
  ///
  /// Some OEM builds reject an insert whose `RELATIVE_PATH` names a folder
  /// below the top-level collection. The store falls back to a flat layout when
  /// it sees this rather than failing the save.
  bool get isNestedFolderUnsupported => code == codeNestedUnsupported;

  /// Code reported when the device has no space left.
  static const codeStorageFull = 'storage_full';

  /// Code reported when the addressed item does not exist.
  static const codeNotFound = 'not_found';

  /// Code reported when a nested `RELATIVE_PATH` was refused.
  static const codeNestedUnsupported = 'nested_unsupported';

  @override
  String toString() => 'MediaStoreException($code): $message';
}

/// One item as MediaStore reports it.
@immutable
class MediaStoreItem {
  /// Creates an item.
  const MediaStoreItem({
    required this.relativePath,
    required this.displayName,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  /// Builds an item from the channel's map form.
  ///
  /// Tolerates a missing size or timestamp — a file being written by another
  /// application can be reported before either is known — because dropping the
  /// whole entry would make the document vanish from the library instead.
  factory MediaStoreItem.fromMap(Map<Object?, Object?> map) => MediaStoreItem(
    relativePath: (map['relativePath'] as String?) ?? '',
    displayName: (map['displayName'] as String?) ?? '',
    sizeBytes: (map['size'] as int?) ?? 0,
    modifiedAt: switch (map['modified'] as int?) {
      // MediaStore reports DATE_MODIFIED in seconds, not milliseconds.
      final seconds? when seconds > 0 => DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
      ),
      _ => null,
    },
  );

  /// The path of the containing folder relative to shared storage,
  /// e.g. `Documents/DocForge/Invoices/`.
  final String relativePath;

  /// The file's name including its extension.
  final String displayName;

  /// The file's size in bytes.
  final int sizeBytes;

  /// When the file was last modified, when MediaStore reports it.
  final DateTime? modifiedAt;

  @override
  String toString() => '$relativePath$displayName ($sizeBytes bytes)';
}

/// Talks to the Android host's MediaStore bridge.
///
/// One thin wrapper over a [MethodChannel] rather than calls scattered through
/// the store, so a test can substitute the channel and assert exactly which
/// MediaStore arguments were sent.
class MediaStoreChannel {
  /// Creates a channel wrapper over [channel].
  const MediaStoreChannel([this.channel = const MethodChannel(channelName)]);

  /// The channel name shared with the Android host.
  static const channelName = 'com.bruxkey.doc_forge/media_store';

  /// The platform channel calls are sent on.
  final MethodChannel channel;

  /// Ensures the collection folder named by [relativePath] exists.
  ///
  /// Throws [MediaStoreException] with
  /// [MediaStoreException.codeNestedUnsupported] when the platform will not
  /// create a folder below the top-level collection.
  Future<void> createFolder(String relativePath) =>
      _invoke<void>('createFolder', {'relativePath': relativePath});

  /// Deletes the folder at [relativePath] and everything beneath it.
  Future<void> deleteFolder(String relativePath) =>
      _invoke<void>('deleteFolder', {'relativePath': relativePath});

  /// Renames the folder at [relativePath] to [newName].
  Future<void> renameFolder(String relativePath, String newName) =>
      _invoke<void>('renameFolder', {
        'relativePath': relativePath,
        'newName': newName,
      });

  /// Lists items whose relative path is exactly [relativePath].
  ///
  /// Set [recursive] to include everything beneath it as well, which is what
  /// the reconciler needs so one call covers the whole tree.
  Future<List<MediaStoreItem>> list(
    String relativePath, {
    bool recursive = false,
  }) async {
    final raw = await _invoke<List<Object?>>('list', {
      'relativePath': relativePath,
      'recursive': recursive,
    });
    return [
      for (final entry in raw ?? const <Object?>[])
        MediaStoreItem.fromMap(entry! as Map<Object?, Object?>),
    ];
  }

  /// Lists the folders directly inside [relativePath].
  ///
  /// Separate from [list] because MediaStore has no folder rows: a folder is
  /// inferred from the paths of the files beneath it, and an empty folder is
  /// only discoverable through the directory listing the host performs.
  Future<List<String>> listFolders(String relativePath) async {
    final raw = await _invoke<List<Object?>>('listFolders', {
      'relativePath': relativePath,
    });
    return [for (final name in raw ?? const <Object?>[]) name! as String];
  }

  /// Copies [sourcePath] into MediaStore at [relativePath]/[displayName].
  ///
  /// Replaces an existing item of the same name, so the caller's decision about
  /// de-duplication is the only one that applies.
  Future<void> writeFile({
    required String relativePath,
    required String displayName,
    required String sourcePath,
  }) => _invoke<void>('writeFile', {
    'relativePath': relativePath,
    'displayName': displayName,
    'sourcePath': sourcePath,
  });

  /// Copies the item at [relativePath]/[displayName] out to [destinationPath].
  ///
  /// The Android half of `materialise`: plugins need a real path, and a
  /// MediaStore item only has a content URI.
  Future<void> copyToCache({
    required String relativePath,
    required String displayName,
    required String destinationPath,
  }) => _invoke<void>('copyToCache', {
    'relativePath': relativePath,
    'displayName': displayName,
    'destinationPath': destinationPath,
  });

  /// Moves or renames an item.
  Future<void> moveFile({
    required String fromRelativePath,
    required String fromDisplayName,
    required String toRelativePath,
    required String toDisplayName,
  }) => _invoke<void>('moveFile', {
    'fromRelativePath': fromRelativePath,
    'fromDisplayName': fromDisplayName,
    'toRelativePath': toRelativePath,
    'toDisplayName': toDisplayName,
  });

  /// Deletes the item at [relativePath]/[displayName].
  Future<void> deleteFile({
    required String relativePath,
    required String displayName,
  }) => _invoke<void>('deleteFile', {
    'relativePath': relativePath,
    'displayName': displayName,
  });

  /// Whether an item exists at [relativePath]/[displayName].
  Future<bool> exists({
    required String relativePath,
    required String displayName,
  }) async =>
      await _invoke<bool>('exists', {
        'relativePath': relativePath,
        'displayName': displayName,
      }) ??
      false;

  /// Sends one call, translating a platform error into [MediaStoreException].
  ///
  /// Translating here rather than at each call site is what keeps the store's
  /// error handling to one `catch`, and what stops a raw `PlatformException`
  /// leaking into a layer that has no business knowing about channels.
  Future<T?> _invoke<T>(String method, Map<String, Object?> arguments) async {
    try {
      return await channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw MediaStoreException(error.code, error.message);
    } on MissingPluginException catch (error) {
      throw MediaStoreException('missing_plugin', '$error');
    }
  }
}
