/// Shared fixtures and fakes for the OCR tests.
library;

import 'dart:async';

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/ocr/application/usecases/ocr_usecases.dart';
import 'package:doc_forge/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:doc_forge/features/ocr/infrastructure/repositories/fake_ocr_repository.dart';
import 'package:doc_forge/features/ocr/presentation/cubit/ocr_cubit.dart';
import 'package:doc_forge/features/ocr/presentation/cubit/ocr_state.dart';

/// The document every test recognises.
const testDocument = DocumentId('doc-1');

/// The title the export name is derived from.
const testTitle = 'Invoice 2026';

/// A page reference.
PageRef page(String id) => PageRef(id: PageId(id), imagePath: '/$id.jpg');

/// The document's pages.
List<PageRef> testPages() => [page('a'), page('b'), page('c')];

/// One recorded export request.
typedef ExportRequest = ({String text, String fileName});

/// Builds OCR Cubits over in-memory collaborators and records what they do.
///
/// One harness per test, so the recorded calls describe that test alone.
class OcrHarness {
  /// Creates a harness with an empty store and a text-producing recogniser.
  OcrHarness() : recogniser = FakeOcrRepository();

  /// The recogniser the Cubit runs against.
  FakeOcrRepository recogniser;

  /// The store the Cubit reads and writes.
  final store = InMemoryOcrTextStore();

  /// Everything put on the clipboard, in order.
  final copied = <String>[];

  /// Every export requested, in order.
  final exported = <ExportRequest>[];

  /// A store whose every operation fails.
  InMemoryOcrTextStore brokenStore() =>
      InMemoryOcrTextStore(failure: const Failure.storage());

  /// Builds a Cubit over this harness.
  ///
  /// [recogniser] and [store] override the harness's own, for the cases that
  /// need a failing or gated collaborator.
  OcrCubit build({
    OcrRepository? recogniser,
    OcrTextStore? store,
    Failure? exportFailure,
    List<PageRef>? pages,
  }) {
    final activeRecogniser = recogniser ?? this.recogniser;
    if (recogniser is FakeOcrRepository) this.recogniser = recogniser;

    final activeStore = store ?? this.store;

    return OcrCubit(
      testDocument,
      testTitle,
      OcrState.initial(pages ?? testPages()),
      RecogniseText(activeRecogniser, activeStore),
      LoadRecognisedText(activeStore),
      (text) async => copied.add(text),
      (text, {required fileName}) async {
        exported.add((text: text, fileName: fileName));
        return exportFailure == null
            ? const Result<void>.success(null)
            : Result<void>.failure(exportFailure);
      },
    );
  }
}

/// A recogniser whose pages complete only when released.
///
/// Lets a test cancel a run part-way, which is the only way to exercise the
/// check the use case makes between pages rather than before the first.
class GatedRecogniser implements OcrRepository {
  final _pending = <Completer<Result<RecognisedText>>>[];

  /// Pages this recogniser was asked to read, in order.
  final requested = <PageId>[];

  @override
  Future<Result<RecognisedText>> recognise({
    required PageId pageId,
    required String imagePath,
    required OcrScript script,
  }) {
    requested.add(pageId);

    final completer = Completer<Result<RecognisedText>>();
    _pending.add(completer);

    // Completed on the next microtask unless a test holds it: the default is a
    // recogniser that works, and only the tests that need to interleave with a
    // running pass hold one open.
    return completer.future;
  }

  /// Completes the oldest page still in flight.
  Future<void> completeNext() async {
    if (_pending.isEmpty) {
      // The run has not reached its first page yet; let it get there.
      await Future<void>.delayed(Duration.zero);
    }
    if (_pending.isEmpty) return;

    _pending
        .removeAt(0)
        .complete(
          Result<RecognisedText>.success(
            RecognisedText(
              pageId: requested.first,
              blocks: FakeOcrRepository.defaultBlocks,
              languageTag: OcrScript.latin.languageTag,
              recognisedAt: FakeOcrRepository.fixedInstant,
            ),
          ),
        );
    await Future<void>.delayed(Duration.zero);
  }

  /// Completes everything still in flight, so the run can finish.
  Future<void> completeRemaining() async {
    while (_pending.isNotEmpty) {
      await completeNext();
    }
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> dispose() async {}
}
