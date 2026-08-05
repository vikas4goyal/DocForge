/// State for the PDF editor.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_operation_workflow.dart';
import 'package:equatable/equatable.dart';

/// Where the editor is in its lifecycle.
enum PdfEditStatus {
  /// The document is being loaded.
  loading,

  /// The editor is on screen and idle.
  ready,

  /// An operation is running.
  working,

  /// An operation could not be completed.
  failure,
}

/// Immutable state of the PDF editor.
class PdfEditState extends Equatable {
  const PdfEditState._({
    required this.status,
    this.document,
    this.filePath,
    this.selection = const {},
    this.operation,
    this.derived,
    this.derivedDocuments = const [],
    this.compression,
    this.metadata,
    this.failure,
    this.passwordRejected = false,
    this.workflowPhase = PdfOperationPhase.idle,
    this.draft,
    this.review,
    this.result,
    this.operationToken,
  });

  /// Before the document has been loaded.
  const PdfEditState.initial() : this._(status: PdfEditStatus.loading);

  /// Where the editor has got to.
  final PdfEditStatus status;

  /// The document being edited, once it is loaded.
  final Document? document;

  /// A readable device path for the document's file, once it is loaded.
  ///
  /// Resolved rather than read off the record: [Document.libraryPath] is an
  /// address, and on Android the readable path is a cache copy. Re-resolved
  /// after every edit, because an edit replaces the file the copy was made of.
  final String? filePath;

  /// The zero-based indices of the selected pages.
  final Set<int> selection;

  /// The operation currently running, when one is.
  final PdfEditOperation? operation;

  /// A document produced by an extract, merge or split, once one has been.
  final Document? derived;

  /// All outputs from the latest derived operation; Split contains two.
  final List<Document> derivedDocuments;

  /// The outcome of the last compression, when there was one.
  final CompressionOutcomeView? compression;

  /// The document's metadata, once it has been read.
  final PdfMetadata? metadata;

  /// What went wrong, when something did.
  final Failure? failure;

  /// Whether the last password attempt was rejected.
  ///
  /// Distinct from [failure]: a wrong password is not an error state, and the
  /// spec requires the user simply be told and allowed to retry.
  final bool passwordRejected;

  /// Current phase shared by every operation family.
  final PdfOperationPhase workflowPhase;

  /// Validated operation input, excluding any password text.
  final PdfOperationDraft? draft;

  /// Effect awaiting explicit user confirmation.
  final PdfOperationReview? review;

  /// Concrete result awaiting presentation or navigation.
  final PdfOperationResult? result;

  /// Identity of the sole in-flight submission, or null when none is running.
  final int? operationToken;

  /// How many pages the document has, or zero before it loads.
  int get pageCount => document?.pageCount ?? 0;

  /// The document's title, or an empty string before it loads.
  String get title => document?.title ?? '';

  /// Whether an operation is running.
  bool get isWorking => status == PdfEditStatus.working;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// Whether anything is selected.
  bool get hasSelection => selection.isNotEmpty;

  /// Whether exactly one page is selected.
  ///
  /// Rotate and duplicate act on a single page; offering them for a multiple
  /// selection would beg the question of which page they meant.
  bool get hasSinglePageSelected => selection.length == 1;

  /// The selected page, when exactly one is.
  int? get selectedPage => hasSinglePageSelected ? selection.first : null;

  /// Whether the current selection may be deleted.
  bool get canDelete => PdfEditRules.canDelete(selection, pageCount: pageCount);

  /// Whether [operation] is currently available.
  bool canRun(PdfEditOperation operation) => switch (operation) {
    PdfEditOperation.rotate ||
    PdfEditOperation.duplicate => hasSinglePageSelected,
    PdfEditOperation.delete => canDelete,
    PdfEditOperation.extract => hasSelection,
    PdfEditOperation.removePassword => document?.isProtected ?? false,
    PdfEditOperation.protect => !(document?.isProtected ?? false),
    _ => true,
  };

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure], [derived], [compression] and [passwordRejected] are cleared
  /// unless supplied, so a resolved error or a stale result cannot outlive its
  /// cause.
  PdfEditState copyWith({
    PdfEditStatus? status,
    Document? document,
    String? filePath,
    Set<int>? selection,
    PdfEditOperation? operation,
    Document? derived,
    List<Document>? derivedDocuments,
    CompressionOutcomeView? compression,
    PdfMetadata? metadata,
    Failure? failure,
    bool passwordRejected = false,
    PdfOperationPhase? workflowPhase,
    PdfOperationDraft? draft,
    PdfOperationReview? review,
    PdfOperationResult? result,
    int? operationToken,
    bool clearWorkflow = false,
  }) => PdfEditState._(
    status: status ?? this.status,
    document: document ?? this.document,
    filePath: filePath ?? this.filePath,
    selection: selection ?? this.selection,
    operation: operation ?? this.operation,
    derived: derived,
    derivedDocuments: derivedDocuments ?? const [],
    compression: compression,
    metadata: metadata ?? this.metadata,
    failure: failure,
    passwordRejected: passwordRejected,
    workflowPhase: workflowPhase ?? this.workflowPhase,
    draft: draft ?? (clearWorkflow ? null : this.draft),
    review: review ?? (clearWorkflow ? null : this.review),
    result: result ?? (clearWorkflow ? null : this.result),
    operationToken:
        operationToken ?? (clearWorkflow ? null : this.operationToken),
  );

  @override
  List<Object?> get props => [
    status,
    document,
    filePath,
    selection,
    operation,
    derived,
    derivedDocuments,
    compression,
    metadata,
    failure,
    passwordRejected,
    workflowPhase,
    draft,
    review,
    result,
    operationToken,
  ];
}

/// What the UI shows about a completed compression.
///
/// A view type rather than the use case's own outcome, so the presentation
/// layer holds only what it renders — and so a state comparison does not depend
/// on a document object the message already summarises.
class CompressionOutcomeView extends Equatable {
  /// Creates the view.
  const CompressionOutcomeView({required this.message, required this.wasKept});

  /// The size-change message.
  final String message;

  /// Whether the compressed result replaced the original.
  final bool wasKept;

  @override
  List<Object?> get props => [message, wasKept];
}
