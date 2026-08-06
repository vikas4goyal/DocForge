/// State for the extracted-text view.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/features/ocr/domain/ocr_rules.dart';
import 'package:equatable/equatable.dart';

/// Where the extracted-text view is in its lifecycle.
enum OcrStatus {
  /// Stored results are being loaded.
  loading,

  /// Recognition has never been run on this document.
  notRecognised,

  /// Recognition is running.
  running,

  /// Recognition has finished and text is available.
  ready,

  /// Recognition has finished and found nothing.
  empty,

  /// Recognition failed.
  failure,
}

/// Immutable state of the extracted-text view.
class OcrState extends Equatable {
  const OcrState._({
    required this.status,
    required this.pages,
    required this.texts,
    this.progress,
    this.failure,
    this.copied = false,
  });

  /// Before anything has been loaded.
  const OcrState.initial(List<PageRef> pages)
    : this._(status: OcrStatus.loading, pages: pages, texts: const {});

  /// Where the view is in its lifecycle.
  final OcrStatus status;

  /// The document's pages, in page order.
  final List<PageRef> pages;

  /// What has been recognised so far, keyed by page.
  final Map<PageId, RecognisedText> texts;

  /// How far a running recognition has progressed.
  final Progress? progress;

  /// What went wrong, when something did.
  final Failure? failure;

  /// Whether the text has just been copied.
  ///
  /// Drives the confirmation the spec requires. Held in state rather than shown
  /// imperatively so the confirmation is a property of what the screen is,
  /// which a widget test can assert on without racing a snackbar.
  final bool copied;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// Every recognised page's text, joined in page order.
  String get combinedText => OcrRules.combinedText(pages, texts);

  /// Whether there is any text to copy or export.
  bool get hasText => OcrRules.hasText(texts);

  /// Whether recognition is currently running.
  bool get isRunning => status == OcrStatus.running;

  /// Whether every page has been recognised.
  bool get isFullyRecognised => OcrRules.isFullyRecognised(pages, texts);

  /// How many pages produced text.
  int get recognisedPageCount =>
      texts.values.where((text) => !text.isEmpty).length;

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure], [progress] and [copied] are cleared unless supplied, so a
  /// resolved error, a finished run and a stale confirmation cannot outlive the
  /// conditions that produced them.
  OcrState copyWith({
    OcrStatus? status,
    List<PageRef>? pages,
    Map<PageId, RecognisedText>? texts,
    Progress? progress,
    Failure? failure,
    bool copied = false,
  }) => OcrState._(
    status: status ?? this.status,
    pages: pages ?? this.pages,
    texts: texts ?? this.texts,
    progress: progress,
    failure: failure,
    copied: copied,
  );

  @override
  List<Object?> get props => [status, pages, texts, progress, failure, copied];
}
