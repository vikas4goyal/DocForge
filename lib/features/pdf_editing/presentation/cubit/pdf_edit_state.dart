/// State for the PDF editor.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/features/pdf_editing/domain/pdf_edit_rules.dart';
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
    this.selection = const {},
    this.operation,
    this.derived,
    this.compression,
    this.metadata,
    this.failure,
    this.passwordRejected = false,
  });

  /// Before the document has been loaded.
  const PdfEditState.initial() : this._(status: PdfEditStatus.loading);

  /// Where the editor has got to.
  final PdfEditStatus status;

  /// The document being edited, once it is loaded.
  final Document? document;

  /// The zero-based indices of the selected pages.
  final Set<int> selection;

  /// The operation currently running, when one is.
  final PdfEditOperation? operation;

  /// A document produced by an extract, merge or split, once one has been.
  final Document? derived;

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
    Set<int>? selection,
    PdfEditOperation? operation,
    Document? derived,
    CompressionOutcomeView? compression,
    PdfMetadata? metadata,
    Failure? failure,
    bool passwordRejected = false,
  }) => PdfEditState._(
    status: status ?? this.status,
    document: document ?? this.document,
    selection: selection ?? this.selection,
    operation: operation ?? this.operation,
    derived: derived,
    compression: compression,
    metadata: metadata ?? this.metadata,
    failure: failure,
    passwordRejected: passwordRejected,
  );

  @override
  List<Object?> get props => [
    status,
    document,
    selection,
    operation,
    derived,
    compression,
    metadata,
    failure,
    passwordRejected,
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
