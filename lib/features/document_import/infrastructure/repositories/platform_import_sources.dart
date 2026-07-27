/// Platform-backed implementations of the import seams.
///
/// Each does the smallest possible amount of work: call the plugin, map what it
/// reports onto a [Failure], and return. There is no picker in a test VM to
/// assert against, so everything that could be *decided* rather than observed
/// already happened in the domain layer.
library;

import 'dart:async';

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_import/domain/repositories/import_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// A [GalleryPicker] backed by the system photo picker.
///
/// The photo picker requests its own permission as part of being shown, on both
/// platforms, which is exactly the just-in-time behaviour the spec requires:
/// nothing is asked for until the user chooses this source.
class SystemGalleryPicker implements GalleryPicker {
  /// Creates the picker.
  const SystemGalleryPicker();

  @override
  Future<Result<List<String>>> pickImages() async {
    try {
      final picked = await ImagePicker().pickMultiImage();
      // Selection order is the order the plugin returns, and it is preserved
      // all the way to the page order of the finished document.
      return Result<List<String>>.success([
        for (final file in picked) file.path,
      ]);
    } on Object catch (error) {
      final detail = '$error';

      // The plugin surfaces a refused photo permission as a platform exception
      // rather than a typed error, so the code is matched here. Getting this
      // wrong would show an error view where the permission-denied view — the
      // only one offering a route to system settings — belongs.
      return detail.contains('photo_access_denied')
          ? Result<List<String>>.failure(
              Failure.permission(
                kind: PermissionKind.photos,
                permanentlyDenied: true,
                debugDetail: detail,
              ),
            )
          : Result<List<String>>.failure(Failure.import(debugDetail: detail));
    }
  }
}

/// A [FileBrowser] backed by the system file picker.
class SystemFileBrowser implements FileBrowser {
  /// Creates the browser.
  const SystemFileBrowser();

  @override
  Future<Result<List<String>>> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);

      // A null result is a cancelled picker, which is a successful empty list:
      // nothing went wrong and the spec requires nothing to be said.
      return Result<List<String>>.success([
        if (result != null)
          for (final file in result.files)
            if (file.path != null) file.path!,
      ]);
    } on Object catch (error) {
      return Result<List<String>>.failure(
        Failure.import(debugDetail: '$error'),
      );
    }
  }
}

/// A [SharedContentSource] backed by the operating system share sheet.
class SystemSharedContentSource implements SharedContentSource {
  /// Creates the source and begins listening.
  SystemSharedContentSource() {
    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => _controller.add([for (final file in files) file.path]),
      // A malformed share is dropped rather than crashing the application, and
      // is not reported: the user did not ask DocForge for anything they are
      // waiting on.
      onError: (Object _) {},
    );
  }

  final _controller = StreamController<List<String>>.broadcast();
  StreamSubscription<List<SharedMediaFile>>? _subscription;

  @override
  Future<Result<List<String>>> pending() async {
    try {
      final files = await ReceiveSharingIntent.instance.getInitialMedia();

      // Told to the plugin that the launch payload has been consumed, so a
      // later resume does not import the same file a second time.
      unawaited(ReceiveSharingIntent.instance.reset());

      return Result<List<String>>.success([
        for (final file in files) file.path,
      ]);
    } on Object catch (error) {
      return Result<List<String>>.failure(
        Failure.import(debugDetail: '$error'),
      );
    }
  }

  @override
  Stream<List<String>> get incoming => _controller.stream;

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller.close();
  }
}
