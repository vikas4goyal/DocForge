/// State for the folder list.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:equatable/equatable.dart';

/// Immutable state of the folder list.
class FolderState extends Equatable {
  /// Creates a folder state.
  const FolderState({
    required this.status,
    this.folders = const [],
    this.isWorking = false,
    this.failure,
    this.validationFailure,
  });

  /// The state before folders are requested.
  const FolderState.initial() : this(status: LoadStatus.initial);

  /// Where the list is in its load cycle.
  final LoadStatus status;

  /// The folders currently shown, each with its document count.
  final List<Folder> folders;

  /// Whether a create, rename or delete is in flight.
  final bool isWorking;

  /// What went wrong at the screen level, when something did.
  final Failure? failure;

  /// Why the name currently being entered was rejected.
  ///
  /// Held separately from [failure] because it belongs beside the text field in
  /// the dialog, not in the screen-level error surface — an empty or duplicate
  /// name is a correctable input, not a failed load.
  final ValidationFailure? validationFailure;

  /// The user-facing message for [failure], or null when there is none.
  String? get message => failure?.presentation.message;

  /// The user-facing message for [validationFailure].
  String? get validationMessage => validationFailure?.presentation.message;

  /// Returns a copy with the given fields replaced.
  ///
  /// Both failures are cleared unless supplied: once the user changes the name,
  /// the complaint about the previous one is stale.
  FolderState copyWith({
    LoadStatus? status,
    List<Folder>? folders,
    bool? isWorking,
    Failure? failure,
    ValidationFailure? validationFailure,
  }) {
    return FolderState(
      status: status ?? this.status,
      folders: folders ?? this.folders,
      isWorking: isWorking ?? this.isWorking,
      failure: failure,
      validationFailure: validationFailure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    folders,
    isWorking,
    failure,
    validationFailure,
  ];
}
