/// State for the save dialog.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/features/document_creation/domain/creation_rules.dart';
import 'package:equatable/equatable.dart';

/// Where saving is in its lifecycle.
enum SaveStatus {
  /// The dialog is showing and the user is filling it in.
  editing,

  /// The PDF is being generated and written.
  saving,

  /// The write failed.
  failure,
}

/// Immutable state of the save dialog.
class SaveDocumentState extends Equatable {
  const SaveDocumentState._({
    required this.status,
    required this.name,
    required this.passwordEnabled,
    required this.passwordReady,
    this.passwordProblem,
    required this.hasPages,
    this.failure,
  });

  /// The dialog as it opens, with [name] prefilled from the naming pattern.
  const SaveDocumentState.initial({String name = '', bool hasPages = true})
    : this._(
        status: SaveStatus.editing,
        name: name,
        passwordEnabled: false,
        passwordReady: false,
        hasPages: hasPages,
      );

  /// Where saving is in its lifecycle.
  final SaveStatus status;

  /// The document's name, as the user has it.
  final String name;

  /// Whether the user asked for password protection.
  final bool passwordEnabled;

  /// Whether the route-only secret draft contains matching non-empty inputs.
  final bool passwordReady;

  /// What is wrong with the secret draft, without carrying its text.
  final ValidationIssue? passwordProblem;

  /// Whether the session has any pages to save.
  final bool hasPages;

  /// What went wrong, when something did.
  final Failure? failure;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// Whether the PDF is being written.
  bool get isSaving => status == SaveStatus.saving;

  /// What is wrong with the name, or null when nothing is.
  ValidationIssue? get nameProblem => CreationRules.validateName(name);

  /// Whether the save control does anything.
  bool get canSave =>
      hasPages &&
      !isSaving &&
      CreationRules.isNameUsable(name) &&
      (!passwordEnabled || passwordReady);

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] is cleared unless supplied, so a resolved error cannot outlive
  /// the condition that produced it.
  SaveDocumentState copyWith({
    SaveStatus? status,
    String? name,
    bool? passwordEnabled,
    bool? passwordReady,
    ValidationIssue? passwordProblem,
    bool clearPasswordProblem = false,
    bool? hasPages,
    Failure? failure,
  }) => SaveDocumentState._(
    status: status ?? this.status,
    name: name ?? this.name,
    passwordEnabled: passwordEnabled ?? this.passwordEnabled,
    passwordReady: passwordReady ?? this.passwordReady,
    passwordProblem: clearPasswordProblem
        ? null
        : passwordProblem ?? this.passwordProblem,
    hasPages: hasPages ?? this.hasPages,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    name,
    passwordEnabled,
    passwordReady,
    passwordProblem,
    hasPages,
    failure,
  ];
}
