/// Typed cloud-storage failure information.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:equatable/equatable.dart';

/// Stable reasons a cloud-storage operation cannot complete.
enum CloudStorageIssue {
  /// No Apple Account is available.
  signedOut,

  /// iCloud Drive is disabled.
  disabled,

  /// Policy restricts iCloud Drive.
  restricted,

  /// The registered container is temporarily unavailable.
  unavailable,

  /// A required remote payload cannot download.
  downloadFailed,

  /// Copied bytes failed verification.
  verificationFailed,

  /// A coordinated operation found an unresolved conflict.
  conflict,

  /// The platform returned malformed data.
  invalidResponse,
}

/// A typed cloud failure that maps into the application's shared vocabulary.
class CloudStorageFailure extends Equatable {
  /// Creates a failure containing no user path or content.
  const CloudStorageFailure(this.issue, {this.debugDetail});

  /// Stable recovery category.
  final CloudStorageIssue issue;

  /// Sanitized diagnostic detail.
  final String? debugDetail;

  /// Converts this feature-specific reason to the shared failure contract.
  Failure toFailure() => Failure.storage(
    debugDetail:
        'cloud:${issue.name}${debugDetail == null ? '' : ':$debugDetail'}',
  );

  @override
  List<Object?> get props => [issue, debugDetail];
}
