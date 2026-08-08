/// Domain values for exact PDF-compression candidates.
library;

import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'compression_candidate.freezed.dart';
part 'compression_candidate.g.dart';

/// Where a verified compression candidate is committed.
enum CompressionDestination {
  /// Creates a collision-safe sibling and preserves the source.
  copy,

  /// Atomically replaces the source after backup and verification.
  overwrite,
}

/// Immutable user configuration for one Compress PDF route.
@freezed
@JsonSerializable()
class CompressionDraft with _$CompressionDraft {
  /// Creates a validated draft.
  CompressionDraft({
    required this.sourceDocumentId,
    required int pageCount,
    required int originalBytes,
    required this.qualityPlan,
    this.destination,
  }) : pageCount = _positive(pageCount, 'pageCount'),
       originalBytes = _nonNegative(originalBytes, 'originalBytes') {
    if (sourceDocumentId.isEmpty) {
      throw ArgumentError.value(
        sourceDocumentId,
        'sourceDocumentId',
        'must not be empty',
      );
    }
  }

  /// Creates a draft from generated JSON.
  factory CompressionDraft.fromJson(Map<String, dynamic> json) =>
      _$CompressionDraftFromJson(json);

  /// Creates the specified 80% initial configuration.
  factory CompressionDraft.initial({
    required String sourceDocumentId,
    required int pageCount,
    required int originalBytes,
  }) => CompressionDraft(
    sourceDocumentId: sourceDocumentId,
    pageCount: _positive(pageCount, 'pageCount'),
    originalBytes: _nonNegative(originalBytes, 'originalBytes'),
    qualityPlan: PageQualityPlan(documentQuality: PdfQualityPercent(value: 80)),
  );

  /// Stable source document identity.
  @override
  final String sourceDocumentId;

  /// Positive verified source page count.
  @override
  final int pageCount;

  /// Exact non-negative source byte count.
  @override
  final int originalBytes;

  /// Document quality and explicit zero-based page exceptions.
  @override
  final PageQualityPlan qualityPlan;

  /// Pending explicit copy-or-overwrite choice.
  @override
  final CompressionDestination? destination;

  /// Converts this draft to generated JSON.
  Map<String, dynamic> toJson() => _$CompressionDraftToJson(this);

  /// Effective percentages in stable zero-based page order.
  List<int> get effectiveQualities => List<int>.unmodifiable(<int>[
    for (var index = 0; index < pageCount; index++)
      qualityPlan.effectiveFor('$index').value,
  ]);

  /// Whether every page keeps source quality and needs the warning review.
  bool get isAllPagesPassThrough =>
      effectiveQualities.every((quality) => quality == 100);

  static int _positive(int value, String name) {
    if (value <= 0) {
      throw RangeError.value(value, name, 'must be positive');
    }
    return value;
  }

  static int _nonNegative(int value, String name) {
    if (value < 0) {
      throw RangeError.value(value, name, 'must not be negative');
    }
    return value;
  }
}

/// Exact byte summary returned after compression is committed.
@freezed
@JsonSerializable()
class CompressionCommitResult with _$CompressionCommitResult {
  /// Creates an exact result summary.
  CompressionCommitResult({
    required this.documentId,
    required this.destination,
    required int originalBytes,
    required int resultBytes,
  }) : originalBytes = CompressionDraft._nonNegative(
         originalBytes,
         'originalBytes',
       ),
       resultBytes = CompressionDraft._nonNegative(resultBytes, 'resultBytes') {
    if (documentId.isEmpty) {
      throw ArgumentError.value(documentId, 'documentId', 'must not be empty');
    }
  }

  /// Creates a result from generated JSON.
  factory CompressionCommitResult.fromJson(Map<String, dynamic> json) =>
      _$CompressionCommitResultFromJson(json);

  /// Result document identity: source for overwrite, new id for copy.
  @override
  final String documentId;

  /// Explicit destination chosen by the user.
  @override
  final CompressionDestination destination;

  /// Exact source bytes before compression.
  @override
  final int originalBytes;

  /// Exact committed result bytes.
  @override
  final int resultBytes;

  /// Converts this result to generated JSON.
  Map<String, dynamic> toJson() => _$CompressionCommitResultToJson(this);

  /// Non-negative bytes saved; zero when the result has no benefit.
  int get savedBytes =>
      resultBytes >= originalBytes ? 0 : originalBytes - resultBytes;

  /// Whether the candidate did not reduce exact bytes.
  bool get hasNoBenefit => resultBytes >= originalBytes;

  /// Whole percentage saved, bounded to zero for no-benefit results.
  int get savedPercent =>
      originalBytes == 0 ? 0 : (savedBytes * 100 / originalBytes).round();
}

/// Every input needed to build one compression candidate.
class CompressionCandidateRequest {
  /// Creates a validated compression request.
  ///
  /// [password] is transient operation input and is deliberately absent from
  /// JSON, equality, fingerprints, logs, and persisted state.
  CompressionCandidateRequest({
    required this.sourcePath,
    required this.pageCount,
    required this.qualityPlan,
    required this.fingerprint,
    this.password,
  }) {
    if (sourcePath.isEmpty) {
      throw ArgumentError.value(sourcePath, 'sourcePath', 'must not be empty');
    }
    if (pageCount <= 0) {
      throw RangeError.value(pageCount, 'pageCount', 'must be positive');
    }
    if (!_sameQualities(effectiveQualities, fingerprint.orderedPageQualities)) {
      throw ArgumentError.value(
        fingerprint,
        'fingerprint',
        'ordered qualities must describe every source page',
      );
    }
    if (fingerprint.isProtected != (password != null)) {
      throw ArgumentError.value(
        fingerprint,
        'fingerprint',
        'protection flag must match password presence',
      );
    }
  }

  /// Materialized private source path.
  final String sourcePath;

  /// Verified source page count.
  final int pageCount;

  /// Document percentage and stable zero-based page exceptions.
  final PageQualityPlan qualityPlan;

  /// Identity of source bytes, ordered qualities, and protection state.
  final PdfCandidateFingerprint fingerprint;

  /// Transient password needed to open a protected source.
  final String? password;

  /// Effective percentage of every source page in order.
  List<int> get effectiveQualities => List<int>.unmodifiable(<int>[
    for (var index = 0; index < pageCount; index++)
      qualityPlan.effectiveFor('$index').value,
  ]);

  /// Whether the source bytes can be used as a pass-through candidate.
  bool get isAllPagesPassThrough =>
      effectiveQualities.every((quality) => quality == 100);

  static bool _sameQualities(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}
