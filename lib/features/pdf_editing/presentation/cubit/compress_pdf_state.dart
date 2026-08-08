/// Immutable state for the dedicated Compress PDF workflow.
library;

import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/features/pdf_editing/domain/compression_candidate.dart';
import 'package:equatable/equatable.dart';

/// Compression configuration plus three independent asynchronous jobs.
class CompressPdfState extends Equatable {
  /// Creates workflow state.
  const CompressPdfState({
    required this.title,
    required this.pageCount,
    required this.originalBytes,
    required this.qualityPlan,
    this.calculation = const AsyncJobView.idle(),
    this.preview = const AsyncJobView.idle(),
    this.commit = const AsyncJobView.idle(),
    this.calculatedBytes,
    this.pendingDestination,
    this.showAllPassThroughReview = false,
    this.showNoBenefitReview = false,
    this.result,
  });

  /// Source document title.
  final String title;

  /// Number of stable zero-based page rows.
  final int pageCount;

  /// Exact source size before compression.
  final int originalBytes;

  /// Document percentage and page-index exceptions.
  final PageQualityPlan qualityPlan;

  /// Debounced exact-size calculation.
  final AsyncJobView calculation;

  /// Temporary-preview preparation.
  final AsyncJobView preview;

  /// Authoritative copy or overwrite commit.
  final AsyncJobView commit;

  /// Last exact candidate byte count matching [qualityPlan].
  final int? calculatedBytes;

  /// Destination retained while a no-benefit decision is reviewed.
  final CompressionDestination? pendingDestination;

  /// Whether the user must review that every page is pass-through quality.
  final bool showAllPassThroughReview;

  /// Whether the user must review a candidate that did not reduce bytes.
  final bool showNoBenefitReview;

  /// One-shot committed result.
  final CompressionCommitResult? result;

  /// Whether at least one page has an explicit quality.
  bool get hasPageOverrides => qualityPlan.pageOverrides.isNotEmpty;

  /// Effective percentages in stable page order.
  List<int> get effectiveQualities => <int>[
    for (var index = 0; index < pageCount; index++)
      qualityPlan.effectiveFor('$index').value,
  ];

  /// Whether every page is an exact pass-through request.
  bool get isAllPagesPassThrough =>
      effectiveQualities.every((quality) => quality == 100);

  /// Exact non-negative bytes saved, when calculation has completed.
  int? get savedBytes {
    final calculated = calculatedBytes;
    if (calculated == null) return null;
    return calculated >= originalBytes ? 0 : originalBytes - calculated;
  }

  /// Whether no authoritative commit is currently running.
  bool get canSave => commit is! AsyncJobRunning;

  /// Returns a copy with selected nullable fields explicitly clearable.
  CompressPdfState copyWith({
    String? title,
    int? pageCount,
    int? originalBytes,
    PageQualityPlan? qualityPlan,
    AsyncJobView? calculation,
    AsyncJobView? preview,
    AsyncJobView? commit,
    int? calculatedBytes,
    bool clearCalculatedBytes = false,
    CompressionDestination? pendingDestination,
    bool clearPendingDestination = false,
    bool? showAllPassThroughReview,
    bool? showNoBenefitReview,
    CompressionCommitResult? result,
  }) => CompressPdfState(
    title: title ?? this.title,
    pageCount: pageCount ?? this.pageCount,
    originalBytes: originalBytes ?? this.originalBytes,
    qualityPlan: qualityPlan ?? this.qualityPlan,
    calculation: calculation ?? this.calculation,
    preview: preview ?? this.preview,
    commit: commit ?? this.commit,
    calculatedBytes: clearCalculatedBytes
        ? null
        : calculatedBytes ?? this.calculatedBytes,
    pendingDestination: clearPendingDestination
        ? null
        : pendingDestination ?? this.pendingDestination,
    showAllPassThroughReview:
        showAllPassThroughReview ?? this.showAllPassThroughReview,
    showNoBenefitReview: showNoBenefitReview ?? this.showNoBenefitReview,
    result: result ?? this.result,
  );

  @override
  List<Object?> get props => <Object?>[
    title,
    pageCount,
    originalBytes,
    qualityPlan,
    calculation,
    preview,
    commit,
    calculatedBytes,
    pendingDestination,
    showAllPassThroughReview,
    showNoBenefitReview,
    result,
  ];
}
