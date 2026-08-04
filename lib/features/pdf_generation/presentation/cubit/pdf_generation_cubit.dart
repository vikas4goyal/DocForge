/// The Cubit driving the document preview and save screen.
///
/// Every method is emit / await a use case / emit. Naming, ordering, the
/// "compose before writing the record" rule and the cleanup of orphaned files
/// all live in the domain and application layers and are unit-tested there.
library;

import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/features/pdf_generation/application/usecases/pdf_generation_usecases.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/cubit/pdf_generation_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the document preview and save screen.
class PdfGenerationCubit extends Cubit<PdfGenerationState> {
  /// Creates the Cubit over the session's [pages] and its collaborators.
  PdfGenerationCubit(
    List<PageRef> pages,
    this._save,
    this._generateName, {
    required this._source,
    this._pattern = NamingPattern.defaultPattern,
    PdfQuality quality = PdfQuality.defaultQuality,
    this._suggestedTitle,
  }) : super(
         PdfGenerationState.initial(
           pages: pages,
           // Empty until the pattern is expanded, which needs a clock and
           // possibly a query. Expanding it in the constructor would make
           // construction asynchronous, or would read a clock synchronously
           // from a Cubit — both forbidden.
           title: '',
           quality: quality,
         ),
       );

  final SaveDocument _save;
  final GenerateDocumentName _generateName;
  final PageSource _source;
  final NamingPattern _pattern;
  final String? _suggestedTitle;

  CancellationToken? _token;

  /// Expands the naming pattern into the default title.
  Future<void> load() async {
    final title = await _generateName(_pattern, suggested: _suggestedTitle);
    emit(state.copyWith(title: title));
  }

  /// Records what the user typed as the document's name.
  ///
  /// Stored beside the generated title rather than replacing it, so clearing
  /// the field falls back to the default rather than leaving the document
  /// nameless.
  void setTitle(String value) => emit(state.copyWith(enteredTitle: value));

  /// Chooses how much fidelity the PDF keeps.
  void setQuality(PdfQuality quality) => emit(state.copyWith(quality: quality));

  /// Generates the PDF and creates the document record.
  Future<void> save() async {
    if (!state.canSave) return;

    final token = CancellationToken();
    _token = token;

    emit(state.copyWith(status: PdfGenerationStatus.generating));

    final result = await _save(
      ScannedPageBundle(
        pages: state.pages,
        source: _source,
        suggestedTitle: _suggestedTitle,
      ),
      title: state.effectiveTitle,
      quality: state.quality,
      token: token,
    );

    _token = null;
    if (isClosed) return;

    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: PdfGenerationStatus.saved,
        document: value,
      ),
      Failed(:final failure) => state.copyWith(
        // Back to ready rather than to a dead end: the captured pages are
        // retained so the user can retry without rescanning, which the spec
        // requires explicitly.
        status: failure is CancelledFailure
            ? PdfGenerationStatus.ready
            : PdfGenerationStatus.failure,
        failure: failure is CancelledFailure ? null : failure,
      ),
    });
  }

  /// Stops generation before it completes.
  ///
  /// No partial record is created and no orphaned file is left, which the use
  /// case guarantees and its tests verify.
  void cancel() => _token?.cancel();

  /// Retries after a failure.
  Future<void> retry() async {
    emit(state.copyWith(status: PdfGenerationStatus.ready));
    await save();
  }

  @override
  Future<void> close() {
    // Cancelled rather than left running: a generation that outlives its screen
    // would write a document nobody asked for and report to nothing.
    _token?.cancel();
    return super.close();
  }
}
