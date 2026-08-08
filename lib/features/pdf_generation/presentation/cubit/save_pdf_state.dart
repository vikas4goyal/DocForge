/// Immutable state for the dedicated Save PDF workflow.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:equatable/equatable.dart';

/// Configuration plus three independent asynchronous Save jobs.
class SavePdfState extends Equatable {
  /// Creates workflow state.
  SavePdfState({
    required List<PageRef> pages,
    required this.name,
    required this.qualityPlan,
    this.passwordEnabled = false,
    this.passwordProblem,
    this.calculation = const AsyncJobView.idle(),
    this.preview = const AsyncJobView.idle(),
    this.commit = const AsyncJobView.idle(),
    this.calculatedBytes,
    this.document,
  }) : pages = List<PageRef>.unmodifiable(pages);

  /// Pages in final output order.
  final List<PageRef> pages;

  /// Current user-entered document name.
  final String name;

  /// Document percentage and stable page-id exceptions.
  final PageQualityPlan qualityPlan;

  /// Whether a matching route-only secret is configured.
  final bool passwordEnabled;

  /// Password validation status without any secret text.
  final ValidationIssue? passwordProblem;

  /// Debounced exact-size calculation job.
  final AsyncJobView calculation;

  /// Modal temporary-preview preparation job.
  final AsyncJobView preview;

  /// Modal authoritative commit job.
  final AsyncJobView commit;

  /// Last exact candidate byte count matching the current configuration.
  final int? calculatedBytes;

  /// Committed document, emitted once after successful Save.
  final Document? document;

  /// Whether configuration is valid and no commit is running.
  bool get canSave =>
      pages.isNotEmpty &&
      name.trim().isNotEmpty &&
      commit is! AsyncJobRunning &&
      commit is! AsyncJobQueued;

  /// Whether at least one page has explicit quality.
  bool get hasPageOverrides => qualityPlan.pageOverrides.isNotEmpty;

  /// Returns a copy with selected fields changed.
  SavePdfState copyWith({
    List<PageRef>? pages,
    String? name,
    PageQualityPlan? qualityPlan,
    bool? passwordEnabled,
    ValidationIssue? passwordProblem,
    bool clearPasswordProblem = false,
    AsyncJobView? calculation,
    AsyncJobView? preview,
    AsyncJobView? commit,
    int? calculatedBytes,
    bool clearCalculatedBytes = false,
    Document? document,
  }) => SavePdfState(
    pages: pages ?? this.pages,
    name: name ?? this.name,
    qualityPlan: qualityPlan ?? this.qualityPlan,
    passwordEnabled: passwordEnabled ?? this.passwordEnabled,
    passwordProblem: clearPasswordProblem
        ? null
        : passwordProblem ?? this.passwordProblem,
    calculation: calculation ?? this.calculation,
    preview: preview ?? this.preview,
    commit: commit ?? this.commit,
    calculatedBytes: clearCalculatedBytes
        ? null
        : calculatedBytes ?? this.calculatedBytes,
    document: document ?? this.document,
  );

  @override
  List<Object?> get props => <Object?>[
    pages,
    name,
    qualityPlan,
    passwordEnabled,
    passwordProblem,
    calculation,
    preview,
    commit,
    calculatedBytes,
    document,
  ];
}
