/// Use cases for text recognition.
library;

import 'dart:async';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/features/ocr/domain/ocr_rules.dart';
import 'package:doc_scanly/features/ocr/domain/repositories/ocr_repository.dart';

/// One page's recognition outcome, as it is reported while a run proceeds.
class RecognitionEvent {
  /// Creates an event for [pageId].
  const RecognitionEvent({
    required this.pageId,
    required this.progress,
    this.text,
    this.failure,
  });

  /// The page this event concerns.
  final PageId pageId;

  /// How far the run has progressed.
  final Progress progress;

  /// What was recognised, when recognition succeeded.
  final RecognisedText? text;

  /// Why the page failed, when it did.
  final Object? failure;

  /// Whether this page was recognised.
  bool get isSuccess => failure == null;
}

/// Recognises the text of a document's pages.
///
/// Runs page by page rather than as one batch so progress can be reported per
/// page and each result is persisted the moment it exists. That is what makes
/// cancellation leave completed pages intact: a page is either stored or never
/// started, never half-recognised.
class RecogniseText {
  /// Creates the use case.
  const RecogniseText(this._recogniser, this._store);

  final OcrRepository _recogniser;
  final OcrTextStore _store;

  /// Recognises every page of [pages] that still needs it.
  ///
  /// Emits a [RecognitionEvent] per page. Pages already recognised are skipped
  /// unless [force] is set, which is what the re-run control passes: recognition
  /// is expensive in time and battery, and re-running it on every open would
  /// make opening a fifty-page document cost as much as creating it.
  ///
  /// A page that fails does not stop the run. Unlike an enhancement batch,
  /// where a failure means the later pages' inputs are suspect, one unreadable
  /// page says nothing about the next — and the spec requires the document to
  /// stay usable without recognised text.
  Stream<RecognitionEvent> call(
    List<PageRef> pages, {
    required DocumentId documentId,
    required OcrScript script,
    bool force = false,
    CancellationToken? token,
  }) async* {
    final storedResult = await _store.findAll([
      for (final page in pages) page.id,
    ]);

    // A store that cannot be read is treated as empty rather than fatal: worst
    // case every page is recognised again, which is slow but correct, where
    // failing outright would leave a usable document with no text at all.
    final stored = storedResult.valueOrNull ?? const {};

    final pending = OcrRules.pagesNeedingRecognition(
      pages,
      stored,
      force: force,
    );

    final total = pending.length;

    for (var index = 0; index < total; index++) {
      // Checked before each page rather than during one. A page is either
      // recognised and stored, or never started — which is what makes
      // "cancelling keeps already-recognised pages" true.
      if (token?.isCancelled ?? false) return;

      final page = pending[index];
      final progress = Progress(completed: index + 1, total: total);

      final result = await _recogniser.recognise(
        pageId: page.id,
        imagePath: page.imagePath,
        script: script,
      );

      switch (result) {
        case Success(:final value):
          // Persisted immediately, before the event is emitted. A result
          // reported to the UI but not yet stored would be recomputed on the
          // next open, which is exactly what the "recognised at most once" rule
          // exists to prevent.
          await _store.save(value, documentId);
          yield RecognitionEvent(
            pageId: page.id,
            progress: progress,
            text: value,
          );
        case Failed(:final failure):
          yield RecognitionEvent(
            pageId: page.id,
            progress: progress,
            failure: failure,
          );
      }
    }
  }
}

/// Loads the recognised text already stored for a document.
class LoadRecognisedText {
  /// Creates the use case.
  const LoadRecognisedText(this._store);

  final OcrTextStore _store;

  /// Returns what has been recognised for [pages], keyed by page.
  ///
  /// Pages never recognised are simply absent, which is how the caller tells
  /// "nothing found on this page" from "this page has not been read yet".
  Future<Result<Map<PageId, RecognisedText>>> call(List<PageRef> pages) =>
      _store.findAll([for (final page in pages) page.id]);
}

/// Removes a document's recognised text.
///
/// Called when a document is permanently removed. Recognised text is document
/// content: leaving it behind would keep readable text — names, amounts,
/// addresses — for a document the user believes they deleted.
class ForgetRecognisedText {
  /// Creates the use case.
  const ForgetRecognisedText(this._store);

  final OcrTextStore _store;

  /// Removes every stored result belonging to [documentId].
  Future<Result<void>> call(DocumentId documentId) =>
      _store.removeForDocument(documentId);
}

/// Provides recognised text to search and sharing.
///
/// The `document-library` and `document-search` features may not import `ocr`,
/// so this implements the shared [OcrTextSource] contract and is injected into
/// them by the composition root (`design.md` §2).
class OcrTextSourceImpl implements OcrTextSource {
  /// Creates the source over the stored text and a page lookup.
  const OcrTextSourceImpl(this._store, this._pagesOf);

  final OcrTextStore _store;
  final Future<Result<List<DocumentPage>>> Function(DocumentId) _pagesOf;

  @override
  Future<Result<RecognisedText?>> textForPage(PageId pageId) =>
      _store.find(pageId);

  @override
  Future<Result<String>> textForDocument(DocumentId documentId) async {
    final pages = await _pagesOf(documentId);

    return pages.flatMapAsync((pages) async {
      final refs = [
        for (final page in pages)
          PageRef(id: page.id, imagePath: page.imagePath),
      ];

      final stored = await _store.findAll([for (final ref in refs) ref.id]);

      return stored.map((texts) => OcrRules.combinedText(refs, texts));
    });
  }
}
