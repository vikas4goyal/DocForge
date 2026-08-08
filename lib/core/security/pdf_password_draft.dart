/// Route-scoped secret storage for an uncommitted PDF password.
library;

import 'package:doc_scanly/core/failures/failure.dart';

/// Holds password text outside immutable state, JSON, logs, and persistence.
///
/// Dart strings cannot be reliably zeroized because the runtime may retain or
/// intern copies. [clear] nevertheless drops this route's references at the
/// earliest lifecycle boundary, which is the strongest guarantee Dart offers.
class PdfPasswordDraft {
  String _password = '';
  String _confirmation = '';

  /// Replaces either input and returns its current validation problem.
  ///
  /// A `null` argument leaves that input unchanged. Empty strings are real
  /// replacements and allow field clearing without exposing a getter.
  ValidationIssue? replace({String? password, String? confirmation}) {
    if (password != null) {
      _password = password;
    }
    if (confirmation != null) {
      _confirmation = confirmation;
    }
    if (_password.isEmpty || _confirmation.isEmpty) {
      return ValidationIssue.emptyName;
    }
    if (_password != _confirmation) {
      return ValidationIssue.passwordMismatch;
    }
    return null;
  }

  /// Whether [readForOperation] currently returns a confirmed secret.
  bool get hasConfirmedValue =>
      _password.isNotEmpty && _password == _confirmation;

  /// Reads the confirmed password only for an immediate candidate operation.
  String? readForOperation() => hasConfirmedValue ? _password : null;

  /// Drops both secret references when disabled, completed, or route-disposed.
  void clear() {
    _password = '';
    _confirmation = '';
  }

  /// Clears the secret at the route lifecycle boundary.
  void dispose() => clear();

  @override
  String toString() => 'PdfPasswordDraft(<redacted>)';
}
