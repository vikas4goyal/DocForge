/// Chooses the platform's [PublicFileStore].
///
/// The one place in the application that branches on the operating system. A
/// feature that made this choice itself would have to know which platform it
/// runs on, and the whole point of the [PublicFileStore] contract is that none
/// of them do (`design.md` D2).
library;

import 'dart:io';

import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/core/storage/public_storage/media_store_channel.dart';
import 'package:doc_scanly/core/storage/public_storage/media_store_public_file_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';

/// Builds the store this device needs.
///
/// [documentsDirectory] is the container the library folder sits in, used on
/// iOS where the folder is a real directory. [cacheDirectory] holds the copies
/// Android materialises so plugins that require a path can read them.
/// [iosLibraryRoot], when supplied, is already the complete iOS library root;
/// the iCloud Documents container uses it to avoid a second nested folder.
///
/// [isAndroid] is injectable so a host test can exercise the selection without
/// pretending to be a device; production callers leave it alone.
///
/// The project targets Android and iOS only, so there is no third branch: any
/// other platform would need its own store and its own decision about where a
/// user-visible folder even is.
PublicFileStore buildPublicFileStore({
  required Directory documentsDirectory,
  required Directory cacheDirectory,
  Directory? iosLibraryRoot,
  bool? isAndroid,
}) {
  final android = isAndroid ?? Platform.isAndroid;

  return android
      ? MediaStorePublicFileStore(
          channel: const MediaStoreChannel(),
          cacheDirectory: cacheDirectory,
        )
      : iosLibraryRoot == null
      ? FilesystemPublicFileStore(documentsDirectory)
      : FilesystemPublicFileStore.atRoot(iosLibraryRoot);
}
