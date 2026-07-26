/// The camera-backed scanner and its in-memory stand-in.
library;

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/permissions/permission_service.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_scanning/domain/repositories/scanner_repository.dart';

/// A staging area under the application's cache directory.
class LocalScanStagingArea implements ScanStagingArea {
  /// Creates a staging area inside [_root].
  ///
  /// The caller resolves [_root] once — the cache directory rather than the
  /// documents directory, so the operating system may reclaim abandoned
  /// captures under storage pressure instead of them counting as user data.
  const LocalScanStagingArea(this._root);

  final Directory _root;

  /// Name of the staging subdirectory.
  static const directoryName = 'scan_session';

  @override
  Future<Result<Directory>> directory() async {
    try {
      final staging = Directory('${_root.path}/$directoryName');
      if (!staging.existsSync()) await staging.create(recursive: true);
      return Result<Directory>.success(staging);
    } on FileSystemException catch (error) {
      return Result<Directory>.failure(_storageFailureFor(error));
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      final staging = Directory('${_root.path}/$directoryName');
      if (staging.existsSync()) await staging.delete(recursive: true);
      return const Result<void>.success(null);
    } on FileSystemException catch (error) {
      return Result<void>.failure(_storageFailureFor(error));
    }
  }
}

/// Maps a filesystem error to the failure the user should see.
///
/// errno 28 is ENOSPC on both Android and iOS. It is separated from a general
/// storage failure because the recovery differs: a retry cannot help until the
/// user frees space, and the spec requires that offer specifically.
Failure _storageFailureFor(FileSystemException error) =>
    error.osError?.errorCode == 28
    ? Failure.storageFull(debugDetail: error.message)
    : Failure.storage(debugDetail: error.message);

/// A [ScannerRepository] over the device camera.
///
/// Owns the camera controller's whole lifecycle. Every capture is written to
/// the staging area before the call returns, so the bytes are never retained:
/// the method hands back a path and nothing else (`design.md` §7).
class CameraScannerRepository implements ScannerRepository {
  /// Creates the repository over its collaborators.
  CameraScannerRepository(this._permissions, this._staging, this._ids);

  final PermissionService _permissions;
  final ScanStagingArea _staging;
  final IdGenerator _ids;

  CameraController? _controller;
  bool _torchOn = false;

  @override
  bool get isReady => _controller?.value.isInitialized ?? false;

  @override
  bool get isTorchOn => _torchOn;

  @override
  Future<Result<void>> initialise() async {
    final permission = await _permissions.request(PermissionKind.camera);

    if (permission != PermissionState.granted) {
      // The permanently-denied distinction survives to the UI, because it is
      // what decides between offering a retry and offering system settings.
      return Result<void>.failure(
        Failure.permission(
          kind: PermissionKind.camera,
          permanentlyDenied: permission == PermissionState.permanentlyDenied,
        ),
      );
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return const Result<void>.failure(
          Failure.camera(debugDetail: 'no cameras reported by the platform'),
        );
      }

      // Rear camera when there is one: a document scanner pointed at the user
      // is never what was intended.
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Any previous controller is disposed first, so a retry after a failure
      // cannot leave two controllers holding the device.
      await _disposeController();

      final controller = CameraController(
        camera,
        // Highest available: a scan is only as legible as its capture, and the
        // page is downscaled later for the PDF rather than up.
        ResolutionPreset.max,
        // Audio would require the microphone permission for no benefit.
        enableAudio: false,
      );

      await controller.initialize();
      _controller = controller;
      _torchOn = false;

      return const Result<void>.success(null);
    } on CameraException catch (error) {
      await _disposeController();
      return Result<void>.failure(_cameraFailureFor(error));
    }
  }

  @override
  Future<Result<CaptureResult>> capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Result<CaptureResult>.failure(
        Failure.camera(debugDetail: 'capture before initialise'),
      );
    }

    final staging = await _staging.directory();
    if (staging case Failed<Directory>(:final failure)) {
      return Result<CaptureResult>.failure(failure);
    }

    try {
      final id = PageId(_ids.generate());
      final file = await controller.takePicture();
      final destination = '${staging.valueOrNull!.path}/${id.value}.jpg';

      // Moved out of the plugin's temporary location immediately: the platform
      // may reclaim that directory at any time, and a capture the user can see
      // in the review list must not be able to vanish from under them.
      await File(file.path).rename(destination);

      return Result<CaptureResult>.success(
        CaptureResult(id: id, imagePath: destination),
      );
    } on CameraException catch (error) {
      return Result<CaptureResult>.failure(_cameraFailureFor(error));
    } on FileSystemException catch (error) {
      // Storage-full arrives here, and the spec requires the already-captured
      // pages to survive it — which they do, because each was written on its
      // own capture and nothing rolls back.
      return Result<CaptureResult>.failure(_storageFailureFor(error));
    }
  }

  @override
  Future<Result<void>> setTorch({required bool on}) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Result<void>.failure(
        Failure.camera(debugDetail: 'torch before initialise'),
      );
    }

    try {
      await controller.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      _torchOn = on;
      return const Result<void>.success(null);
    } on CameraException catch (error) {
      return Result<void>.failure(_cameraFailureFor(error));
    }
  }

  @override
  Future<Result<void>> dispose() async {
    await _disposeController();
    return const Result<void>.success(null);
  }

  /// Tears down the controller, tolerating every state it might be in.
  ///
  /// Never throws. The capture screen releases the camera on every exit path,
  /// including paths taken because initialisation failed, and a dispose that
  /// could throw would turn one failure into two.
  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    _torchOn = false;

    if (controller == null) return;
    try {
      await controller.dispose();
    } on Object {
      // Nothing useful to do: the camera is being given up either way.
    }
  }
}

/// Maps a camera plugin error to a failure.
Failure _cameraFailureFor(CameraException error) {
  final code = error.code.toLowerCase();

  // The platform reports a refused permission through the camera channel as
  // well as through the permission channel, and the two must not disagree.
  if (code.contains('permission') || code.contains('denied')) {
    return const Failure.permission(kind: PermissionKind.camera);
  }

  return Failure.camera(
    inUseByAnotherApp: code.contains('inuse') || code.contains('busy'),
    debugDetail: '${error.code}: ${error.description}',
  );
}

/// A [ScannerRepository] that captures nothing and touches no device.
///
/// For tests, previews and goldens. Writes a small placeholder file per capture
/// so the disk-first rule is genuinely exercised — a fake that returned a path
/// to nothing would let a bug that never writes the file pass every test.
class FakeScannerRepository implements ScannerRepository {
  /// Creates a fake writing captures into [directory].
  ///
  /// When [directory] is null nothing is written and the returned paths are
  /// synthetic, which suits a preview that only needs a page count.
  FakeScannerRepository({this.directory, IdGenerator? ids})
    : _ids = ids ?? SequentialIdGenerator(prefix: 'capture');

  /// Where captures are written, when anywhere.
  final Directory? directory;

  final IdGenerator _ids;

  /// Fails [initialise] with this failure when set.
  Failure? initialiseFailure;

  /// Fails [capture] with this failure when set.
  Failure? captureFailure;

  /// Every capture this fake produced, in order.
  final List<CaptureResult> captures = [];

  /// How many times [dispose] was called.
  ///
  /// The spec requires the camera to be released on every exit path, and a
  /// counter is how a test proves it happened exactly once per path.
  int disposeCount = 0;

  bool _ready = false;
  bool _torchOn = false;

  @override
  bool get isReady => _ready;

  @override
  bool get isTorchOn => _torchOn;

  @override
  Future<Result<void>> initialise() async {
    if (initialiseFailure != null) {
      return Result<void>.failure(initialiseFailure!);
    }
    _ready = true;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<CaptureResult>> capture() async {
    if (captureFailure != null) {
      return Result<CaptureResult>.failure(captureFailure!);
    }
    if (!_ready) {
      return const Result<CaptureResult>.failure(
        Failure.camera(debugDetail: 'capture before initialise'),
      );
    }

    final id = PageId(_ids.generate());
    final path = directory == null
        ? '/scan/${id.value}.jpg'
        : '${directory!.path}/${id.value}.jpg';

    if (directory != null) {
      // A byte of content, so a test can assert the file exists and a caller
      // that forgets to write is caught rather than silently passing.
      await File(path).writeAsBytes(const [0]);
    }

    final result = CaptureResult(id: id, imagePath: path);
    captures.add(result);
    return Result<CaptureResult>.success(result);
  }

  @override
  Future<Result<void>> setTorch({required bool on}) async {
    if (!_ready) {
      return const Result<void>.failure(
        Failure.camera(debugDetail: 'torch before initialise'),
      );
    }
    _torchOn = on;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> dispose() async {
    disposeCount++;
    _ready = false;
    _torchOn = false;
    return const Result<void>.success(null);
  }
}

/// A [ScanStagingArea] in a temporary directory, for tests.
class FakeScanStagingArea implements ScanStagingArea {
  /// Creates a staging area over [_directory].
  const FakeScanStagingArea(this._directory);

  final Directory _directory;

  @override
  Future<Result<Directory>> directory() async =>
      Result<Directory>.success(_directory);

  @override
  Future<Result<void>> clear() async {
    if (_directory.existsSync()) {
      await _directory.delete(recursive: true);
    }
    return const Result<void>.success(null);
  }
}
