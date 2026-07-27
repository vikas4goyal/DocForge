/// State for the sharing options.
library;

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/features/document_sharing/domain/share_content.dart';
import 'package:equatable/equatable.dart';

/// Where a share, print or export is in its lifecycle.
enum ShareStatus {
  /// Nothing has been asked for; the options are on screen.
  idle,

  /// Content is being prepared for handing over.
  preparing,

  /// The content has been handed to the system, or the export has been written.
  done,

  /// The operation could not be completed.
  failure,
}

/// Immutable state of the sharing options.
class ShareState extends Equatable {
  const ShareState._({
    required this.status,
    required this.title,
    required this.pageCount,
    this.canShareText = false,
    this.action,
    this.format,
    this.progress,
    this.failure,
    this.exportedTo,
  });

  /// The options as first shown, for a document with [title] and [pageCount].
  ///
  /// [canShareText] comes from the document record and its recognised text; the
  /// text control is disabled when it is false, which is the accessible form of
  /// the "no recognised text" rule.
  const ShareState.initial({
    String title = '',
    int pageCount = 0,
    bool canShareText = false,
  }) : this._(
         status: ShareStatus.idle,
         title: title,
         pageCount: pageCount,
         canShareText: canShareText,
       );

  /// Where the operation has got to.
  final ShareStatus status;

  /// The document's title, used in labels and file names.
  final String title;

  /// How many pages the document has.
  final int pageCount;

  /// Whether there is recognised text to share.
  final bool canShareText;

  /// What was asked for, once something was.
  final ShareAction? action;

  /// In what form, once something was asked for.
  final ShareFormat? format;

  /// How far preparation has got, when it reports progress.
  final Progress? progress;

  /// What went wrong, when something did.
  final Failure? failure;

  /// Where the document was exported, once it has been.
  final String? exportedTo;

  /// Whether preparation is under way.
  bool get isPreparing => status == ShareStatus.preparing;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// Whether the failure was "no application can receive this".
  ///
  /// Drives the offer of export as an alternative, which the spec requires
  /// specifically for this case rather than for failures in general.
  bool get canOfferExportInstead =>
      failure is ExportFailure && (failure! as ExportFailure).noReceivingApp;

  /// The label shown beside the progress indicator.
  String get progressLabel => ShareRules.preparingLabel(
    progress?.completed ?? 0,
    progress?.total ?? pageCount,
  );

  /// The confirmation shown after a successful export.
  String? get exportConfirmation {
    final destination = exportedTo;
    return destination == null
        ? null
        : ShareRules.exportConfirmation(destination);
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure], [progress] and [exportedTo] are cleared unless supplied, so a
  /// resolved error or a stale progress reading cannot outlive its cause.
  ShareState copyWith({
    ShareStatus? status,
    String? title,
    int? pageCount,
    bool? canShareText,
    ShareAction? action,
    ShareFormat? format,
    Progress? progress,
    Failure? failure,
    String? exportedTo,
  }) => ShareState._(
    status: status ?? this.status,
    title: title ?? this.title,
    pageCount: pageCount ?? this.pageCount,
    canShareText: canShareText ?? this.canShareText,
    action: action ?? this.action,
    format: format ?? this.format,
    progress: progress,
    failure: failure,
    exportedTo: exportedTo,
  );

  @override
  List<Object?> get props => [
    status,
    title,
    pageCount,
    canShareText,
    action,
    format,
    progress,
    failure,
    exportedTo,
  ];
}
