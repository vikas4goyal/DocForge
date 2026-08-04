/// State for the import flow.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/features/document_import/domain/import_rules.dart';
import 'package:equatable/equatable.dart';

/// Where an import is in its lifecycle.
enum ImportStatus {
  /// The sources are on screen and nothing has been chosen.
  idle,

  /// A source picker is open.
  choosing,

  /// Files are being copied and inspected.
  importing,

  /// A protected PDF is waiting for its password.
  awaitingPassword,

  /// Images are ready to be reviewed before a document is created.
  readyForReview,

  /// Every selected file was imported.
  done,

  /// Photo or file access was refused.
  permissionDenied,

  /// The import could not be completed.
  failure,
}

/// Immutable state of the import flow.
class ImportState extends Equatable {
  const ImportState._({
    required this.status,
    this.source,
    this.progress,
    this.bundle,
    this.imported = const [],
    this.protectedFilePath,
    this.passwordRejected = false,
    this.failure,
  });

  /// Before any source has been chosen.
  const ImportState.initial() : this._(status: ImportStatus.idle);

  /// Where the import has got to.
  final ImportStatus status;

  /// The source being imported from, once one was chosen.
  final ImportSource? source;

  /// How far the copy has got, while files are being copied.
  final Progress? progress;

  /// Pages awaiting review, once images have been copied.
  final ScannedPageBundle? bundle;

  /// Documents created from imported PDFs, in the order they were created.
  final List<Document> imported;

  /// The protected file awaiting a password, when one is.
  final String? protectedFilePath;

  /// Whether the last password attempt was rejected.
  ///
  /// Distinct from [failure] because a wrong password is not an error state:
  /// the prompt stays up and says so.
  final bool passwordRejected;

  /// What went wrong, when something did.
  final Failure? failure;

  /// Whether files are currently being copied.
  bool get isImporting => status == ImportStatus.importing;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// The label shown beside the progress indicator.
  String get progressLabel =>
      ImportRules.progressLabel(progress?.completed ?? 0, progress?.total ?? 0);

  /// How the outcome is reported once the import has finished.
  String get outcomeMessage =>
      ImportRules.importedCountMessage(imported.length);

  /// Whether the refused permission can only be resolved in system settings.
  ///
  /// Drives which control the permission view offers: a retry when the user
  /// simply declined, and a route to settings when they chose "don't ask
  /// again", which no retry can undo.
  bool get isPermanentlyDenied =>
      failure is PermissionFailure &&
      (failure! as PermissionFailure).permanentlyDenied;

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure], [progress], [protectedFilePath] and [passwordRejected] are
  /// cleared unless supplied, so a resolved error, a stale progress reading or
  /// an answered prompt cannot outlive its cause.
  ImportState copyWith({
    ImportStatus? status,
    ImportSource? source,
    Progress? progress,
    ScannedPageBundle? bundle,
    List<Document>? imported,
    String? protectedFilePath,
    bool passwordRejected = false,
    Failure? failure,
  }) => ImportState._(
    status: status ?? this.status,
    source: source ?? this.source,
    progress: progress,
    bundle: bundle ?? this.bundle,
    imported: imported ?? this.imported,
    protectedFilePath: protectedFilePath,
    passwordRejected: passwordRejected,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    source,
    progress,
    bundle,
    imported,
    protectedFilePath,
    passwordRejected,
    failure,
  ];
}
