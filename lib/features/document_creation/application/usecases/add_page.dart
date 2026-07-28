/// Bringing an image into a creation session as a page.
///
/// Both sources — the camera and the photo library — end in the same place: a
/// [PageDraft] over an untouched original, staged privately, with neither layer
/// applied yet. What the user does next is the same loop either way.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/capture_staging.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_creation/domain/page_draft.dart';

/// Picks one or more images, returning their paths.
///
/// An empty list means the user cancelled, which is not a failure.
typedef ImagePicker = Future<Result<List<String>>> Function();

/// Captures one image with the camera, returning its path.
typedef ImageCapture = Future<Result<String>> Function();

/// Copies a picked image into the session's private staging area.
///
/// Picked images live wherever the photo library put them — often outside
/// anything this application may keep a handle on — so a page is built over a
/// copy the session owns and can delete.
class StagePageImage {
  /// Creates the use case.
  const StagePageImage(this._staging, this._ids);

  final CaptureStaging _staging;
  final IdGenerator _ids;

  /// Copies [sourcePath] into [sessionId]'s directory and builds a draft.
  Future<Result<PageDraft>> call(
    String sourcePath, {
    required String sessionId,
  }) async {
    final id = PageId(_ids.generate());

    try {
      final source = File(sourcePath);
      if (!source.existsSync()) {
        return const Result<PageDraft>.failure(Failure.notFound());
      }

      final destination =
          '${_staging.directoryFor(sessionId).path}/${id.value}.jpg';
      await source.copy(destination);

      return Result<PageDraft>.success(
        PageDraft(id: id, originalImagePath: destination),
      );
    } on FileSystemException catch (error) {
      return Result<PageDraft>.failure(
        // errno 28 is ENOSPC on both platforms, and "the device is full" has a
        // different recovery from "that file could not be read".
        error.osError?.errorCode == 28
            ? Failure.storageFull(debugDetail: '$error')
            : Failure.storage(debugDetail: '$error'),
      );
    }
  }
}

/// Adds a page from the camera.
class AddPageFromCamera {
  /// Creates the use case.
  const AddPageFromCamera(this._capture, this._stage);

  final ImageCapture _capture;
  final StagePageImage _stage;

  /// Captures one page and stages it.
  Future<Result<PageDraft>> call({required String sessionId}) async {
    final captured = await _capture();
    if (captured case Failed(:final failure)) {
      return Result<PageDraft>.failure(failure);
    }

    return _stage(captured.valueOrNull!, sessionId: sessionId);
  }
}

/// Adds pages from the photo library.
class AddPagesFromGallery {
  /// Creates the use case.
  const AddPagesFromGallery(this._pick, this._stage);

  final ImagePicker _pick;
  final StagePageImage _stage;

  /// Picks images and stages each one, in selection order.
  ///
  /// Order matters: the pages become rows in the order they are returned, and
  /// the user chose that order.
  ///
  /// An image that cannot be staged is skipped rather than failing the whole
  /// selection — one unreadable file out of twenty should not cost the other
  /// nineteen.
  Future<Result<List<PageDraft>>> call({required String sessionId}) async {
    final picked = await _pick();
    if (picked case Failed(:final failure)) {
      return Result<List<PageDraft>>.failure(failure);
    }

    final drafts = <PageDraft>[];
    for (final path in picked.valueOrNull!) {
      final staged = await _stage(path, sessionId: sessionId);
      if (staged case Success(:final value)) drafts.add(value);
    }

    return Result<List<PageDraft>>.success(drafts);
  }
}

/// Deletes everything a creation session wrote.
///
/// Called when the PDF has been saved and when the session is abandoned: after
/// a save the PDF is the only representation of the document that survives
/// (`design.md` D4a), and after an abandonment there is nothing to keep at all.
class DiscardCreationSession {
  /// Creates the use case.
  const DiscardCreationSession(this._staging);

  final CaptureStaging _staging;

  /// Removes [sessionId]'s originals and every render derived from them.
  Future<Result<void>> call(String sessionId) =>
      _staging.discardSession(sessionId);
}
