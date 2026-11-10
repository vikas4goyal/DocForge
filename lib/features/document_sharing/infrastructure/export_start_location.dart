/// Converts the stored default save location into the starting-location hint
/// each platform's export picker actually accepts.
library;

import 'package:flutter/foundation.dart';

/// The authority of Android's built-in external-storage documents provider.
const androidExternalStorageAuthority = 'com.android.externalstorage.documents';

/// Returns [stored] as the `initialDirectory` hint the export picker on
/// [platform] understands, or null when there is nothing honest to offer.
///
/// [stored] is what the folder picker returned when the user chose a default
/// location: a plain filesystem path on both platforms. The `file_picker`
/// plugin, however, hands the hint straight to the platform: Android puts it in
/// `DocumentsContract.EXTRA_INITIAL_URI`, which only understands a
/// `content://` document URI, and iOS builds `NSURL URLWithString:` from it,
/// which needs a `file://` URL. A bare path is silently ignored by both — which
/// is why the setting used to do nothing.
///
/// - Android: `/storage/emulated/0/<rel>` becomes the primary volume's document
///   URI, and `/storage/<VOLUME-ID>/<rel>` an SD card's. A value that is
///   already a `content://` URI is passed through.
/// - iOS: an absolute path that still exists becomes a `file://` directory URL;
///   a `file://` value is passed through. [directoryExists] is consulted only
///   here — Android's scoped storage hides existence, and its picker falls back
///   on its own.
///
/// Returns null for null or empty input, for an unrecognised Android path, for
/// a missing iOS directory, and for every other platform. A null hint makes
/// the picker open at its own default, which is always a safe export.
String? exportStartLocation(
  String? stored, {
  required TargetPlatform platform,
  required bool Function(String path) directoryExists,
}) {
  final value = stored?.trim();
  if (value == null || value.isEmpty) return null;

  switch (platform) {
    case TargetPlatform.android:
      if (value.startsWith('content://')) return value;
      return _androidDocumentUri(value);
    case TargetPlatform.iOS:
      if (value.startsWith('file://')) return value;
      if (!value.startsWith('/') || !directoryExists(value)) return null;
      return Uri.directory(value).toString();
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      // Android and iOS only; no other platform is ever composed.
      return null;
  }
}

/// Matches `/storage/<volume>/<optional relative path>`.
final _storageVolumePath = RegExp(r'^/storage/([^/]+)(?:/(.*))?$');

/// Matches a removable volume's identifier, such as `1A2B-3C4D`.
final _volumeId = RegExp(r'^[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}$');

String? _androidDocumentUri(String path) {
  final match = _storageVolumePath.firstMatch(path);
  if (match == null) return null;
  final volume = match.group(1)!;
  final relative = (match.group(2) ?? '').replaceAll(RegExp(r'/+$'), '');

  final String root;
  if (volume == 'emulated') {
    // `/storage/emulated/<user>/...`: only user 0's shared storage is the
    // provider's "primary" volume.
    final user = RegExp(r'^0(?:/(.*))?$').firstMatch(relative);
    if (user == null) return null;
    return _documentUri('primary', user.group(1) ?? '');
  } else if (_volumeId.hasMatch(volume)) {
    root = volume;
  } else {
    return null;
  }
  return _documentUri(root, relative);
}

/// Builds the provider's document id `<root>:<relative>` as a URI.
///
/// The whole id is one path segment, so `:` and every `/` inside the relative
/// path are percent-encoded (`primary%3ADownload%2FScans`). Encoding only the
/// path's characters but leaving `/` raw produces a URI DocumentsUI treats as
/// a different, non-existent document.
String _documentUri(String root, String relative) =>
    'content://$androidExternalStorageAuthority/document/'
    '${Uri.encodeComponent('$root:$relative')}';
