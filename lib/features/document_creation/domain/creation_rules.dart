/// The validation rules the save dialog enforces.
///
/// Pure functions so the Cubit only reports validity and the screen only
/// renders it — neither decides what a legal name or a matching password is.
library;

import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';

/// What is wrong with a document name, or null when nothing is.
typedef NameProblem = ValidationIssue?;

/// The rules for naming and protecting a document being saved.
abstract final class CreationRules {
  /// Returns the problem with [name], or null when it is usable.
  ///
  /// Two distinct refusals, because the fix differs: an empty name needs the
  /// user to type something, and an illegal one needs them to change a
  /// character. The name has to be legal *on disk* now, not merely non-empty —
  /// it becomes a file in a folder the user can also reach from their file
  /// browser.
  static NameProblem validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return ValidationIssue.emptyName;
    if (!LibraryPath.isValidName(LibraryPath.pdfFileName(trimmed))) {
      return ValidationIssue.illegalName;
    }
    return null;
  }

  /// Whether [name] can be saved.
  static bool isNameUsable(String name) => validateName(name) == null;

  /// Returns the problem with a password, or null when it is usable.
  ///
  /// A password is required to be entered twice identically before it is
  /// applied: it is never shown back to the user, never recoverable, and a
  /// typo would lock them out of their own document permanently.
  static NameProblem validatePassword(
    String password,
    String confirmation, {
    required bool enabled,
  }) {
    if (!enabled) return null;
    if (password.isEmpty || confirmation.isEmpty) {
      return ValidationIssue.emptyName;
    }
    if (password != confirmation) return ValidationIssue.passwordMismatch;
    return null;
  }

  /// Whether the save control should be enabled.
  static bool canSave({
    required String name,
    required String password,
    required String confirmation,
    required bool passwordEnabled,
    required bool hasPages,
    required bool isSaving,
  }) =>
      hasPages &&
      !isSaving &&
      isNameUsable(name) &&
      validatePassword(password, confirmation, enabled: passwordEnabled) ==
          null;

  /// The file name [title] will be stored under.
  static String fileNameFor(String title) =>
      LibraryPath.pdfFileName(title.trim());
}
