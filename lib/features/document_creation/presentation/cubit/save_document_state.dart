/// State for the save dialog.
library;

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/features/document_creation/domain/creation_rules.dart';
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
    required this.password,
    required this.confirmation,
    required this.passwordEnabled,
    required this.hasPages,
    this.failure,
  });

  /// The dialog as it opens, with [name] prefilled from the naming pattern.
  const SaveDocumentState.initial({String name = '', bool hasPages = true})
    : this._(
        status: SaveStatus.editing,
        name: name,
        password: '',
        confirmation: '',
        passwordEnabled: false,
        hasPages: hasPages,
      );

  /// Where saving is in its lifecycle.
  final SaveStatus status;

  /// The document's name, as the user has it.
  final String name;

  /// The password, when protection is on.
  ///
  /// Held only while the dialog is open. It reaches secure storage when the
  /// document is written and is never put on a record or in a log.
  final String password;

  /// The password entered a second time.
  final String confirmation;

  /// Whether the user asked for password protection.
  final bool passwordEnabled;

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

  /// What is wrong with the password, or null when nothing is.
  ValidationIssue? get passwordProblem => CreationRules.validatePassword(
    password,
    confirmation,
    enabled: passwordEnabled,
  );

  /// Whether the save control does anything.
  bool get canSave => CreationRules.canSave(
    name: name,
    password: password,
    confirmation: confirmation,
    passwordEnabled: passwordEnabled,
    hasPages: hasPages,
    isSaving: isSaving,
  );

  /// The password to protect with, or null when protection is off.
  String? get effectivePassword => passwordEnabled ? password : null;

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] is cleared unless supplied, so a resolved error cannot outlive
  /// the condition that produced it.
  SaveDocumentState copyWith({
    SaveStatus? status,
    String? name,
    String? password,
    String? confirmation,
    bool? passwordEnabled,
    bool? hasPages,
    Failure? failure,
  }) => SaveDocumentState._(
    status: status ?? this.status,
    name: name ?? this.name,
    password: password ?? this.password,
    confirmation: confirmation ?? this.confirmation,
    passwordEnabled: passwordEnabled ?? this.passwordEnabled,
    hasPages: hasPages ?? this.hasPages,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    name,
    password,
    confirmation,
    passwordEnabled,
    hasPages,
    failure,
  ];
}
