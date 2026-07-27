/// A recogniser that returns fixture text.
///
/// Ships in `lib/` rather than in `test/` because previews need it too, and a
/// preview may not reach into the test tree. It touches no plugin, no file and
/// no network, so it is safe everywhere a real recogniser is not.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/ocr/domain/repositories/ocr_repository.dart';

/// Recognises fixture text without touching a recogniser.
class FakeOcrRepository implements OcrRepository {
  /// Creates a fake that returns [blocks] for every page.
  FakeOcrRepository({
    this.blocks = defaultBlocks,
    this.failure,
    this.emptyFor = const {},
    this.recognisedAt,
  });

  /// The blocks returned for a page that has text.
  final List<TextBlock> blocks;

  /// When set, every recognition fails with this instead.
  final Failure? failure;

  /// Pages that recognise successfully but find nothing.
  ///
  /// A page with no legible text is a valid outcome rather than a failure, and
  /// the two have to be distinguishable in a test.
  final Set<String> emptyFor;

  /// The timestamp written onto results.
  ///
  /// Fixed rather than read from a clock so a golden or a `bloc_test` sequence
  /// is byte-stable.
  final DateTime? recognisedAt;

  /// Pages this fake was asked to recognise, in order.
  final requested = <PageId>[];

  /// How many times [dispose] has been called.
  int disposeCount = 0;

  /// The text every recognised page carries unless told otherwise.
  static const defaultBlocks = [
    TextBlock(
      text: 'INVOICE',
      bounds: NormalisedRect(left: 0.1, top: 0.08, right: 0.4, bottom: 0.13),
    ),
    TextBlock(
      text: 'Acme Limited',
      bounds: NormalisedRect(left: 0.1, top: 0.16, right: 0.55, bottom: 0.2),
    ),
    TextBlock(
      text: 'Total due: 240.00',
      bounds: NormalisedRect(left: 0.1, top: 0.62, right: 0.62, bottom: 0.66),
    ),
  ];

  /// The instant results are stamped with when none is supplied.
  static final fixedInstant = DateTime.utc(2026, 3, 14, 9, 30);

  @override
  Future<Result<RecognisedText>> recognise({
    required PageId pageId,
    required String imagePath,
    required OcrScript script,
  }) async {
    requested.add(pageId);

    final configured = failure;
    if (configured != null) {
      return Result<RecognisedText>.failure(configured);
    }

    return Result<RecognisedText>.success(
      RecognisedText(
        pageId: pageId,
        blocks: emptyFor.contains(pageId.value) ? const [] : blocks,
        languageTag: script.languageTag,
        recognisedAt: recognisedAt ?? fixedInstant,
      ),
    );
  }

  @override
  Future<void> dispose() async => disposeCount++;
}

/// An in-memory [OcrTextStore].
///
/// Behaves like the Isar store for everything a use case can observe, without
/// needing a database open.
class InMemoryOcrTextStore implements OcrTextStore {
  /// Creates an empty store.
  InMemoryOcrTextStore({this.failure});

  /// When set, every operation fails with this.
  final Failure? failure;

  /// What has been stored, keyed by page.
  final texts = <PageId, RecognisedText>{};

  /// Which document each page belongs to.
  final owners = <PageId, DocumentId>{};

  @override
  Future<Result<RecognisedText?>> find(PageId pageId) async {
    final configured = failure;
    if (configured != null) {
      return Result<RecognisedText?>.failure(configured);
    }
    return Result<RecognisedText?>.success(texts[pageId]);
  }

  @override
  Future<Result<Map<PageId, RecognisedText>>> findAll(
    List<PageId> pageIds,
  ) async {
    final configured = failure;
    if (configured != null) {
      return Result<Map<PageId, RecognisedText>>.failure(configured);
    }

    return Result<Map<PageId, RecognisedText>>.success({
      for (final id in pageIds)
        if (texts.containsKey(id)) id: texts[id]!,
    });
  }

  @override
  Future<Result<void>> save(RecognisedText text, DocumentId documentId) async {
    final configured = failure;
    if (configured != null) return Result<void>.failure(configured);

    texts[text.pageId] = text;
    owners[text.pageId] = documentId;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> remove(PageId pageId) => removeAll([pageId]);

  @override
  Future<Result<void>> removeAll(List<PageId> pageIds) async {
    final configured = failure;
    if (configured != null) return Result<void>.failure(configured);

    for (final id in pageIds) {
      texts.remove(id);
      owners.remove(id);
    }
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> removeForDocument(DocumentId documentId) async {
    final configured = failure;
    if (configured != null) return Result<void>.failure(configured);

    final owned = [
      for (final entry in owners.entries)
        if (entry.value == documentId) entry.key,
    ];

    return removeAll(owned);
  }
}
