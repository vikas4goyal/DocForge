/// Substitutes for the platform sharing seams.
///
/// Ship in `lib/` rather than in `test/` because previews need them too, and a
/// preview that reached a real share sheet would open one while the developer
/// was looking at a widget.
///
/// Each records what it was asked to do, which is how the tests assert the one
/// property that matters most here: that nothing leaves unless it was asked
/// for, and that what leaves is what was intended.
library;

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_sharing/domain/repositories/share_repository.dart';
import 'package:doc_forge/features/document_sharing/domain/share_content.dart';

/// A [ShareRepository] that records payloads instead of sharing them.
class FakeShareRepository implements ShareRepository {
  /// Creates a fake that fails with [failure] when one is supplied.
  FakeShareRepository({this.failure});

  /// When set, every share fails with this.
  final Failure? failure;

  /// Every payload handed over, in order.
  final List<SharePayload> shared = [];

  @override
  Future<Result<void>> share(SharePayload payload) async {
    shared.add(payload);

    final configured = failure;
    return configured == null
        ? const Result<void>.success(null)
        : Result<void>.failure(configured);
  }
}

/// A [PrintRepository] that records jobs instead of printing them.
class FakePrintRepository implements PrintRepository {
  /// Creates a fake that returns [submitted], or fails with [failure].
  FakePrintRepository({this.submitted = true, this.failure});

  /// What a successful call reports: false stands for a cancelled dialogue.
  final bool submitted;

  /// When set, every call fails with this.
  final Failure? failure;

  /// Every (path, job name) pair printed, in order.
  final List<(String, String)> printed = [];

  @override
  Future<Result<bool>> printFile(
    String filePath, {
    required String jobName,
  }) async {
    printed.add((filePath, jobName));

    final configured = failure;
    return configured == null
        ? Result<bool>.success(submitted)
        : Result<bool>.failure(configured);
  }
}

/// An [ExportDestinationPicker] that answers with a fixed choice.
class FakeExportDestinationPicker implements ExportDestinationPicker {
  /// Creates a picker returning [destination], or failing with [failure].
  ///
  /// A null [destination] stands for the user cancelling the picker.
  FakeExportDestinationPicker({this.destination, this.failure});

  /// The path the user "chose", or null for a cancelled picker.
  final String? destination;

  /// When set, every call fails with this.
  final Failure? failure;

  /// Every suggested name the picker was offered, in order.
  final List<String> suggestions = [];

  @override
  Future<Result<String?>> chooseDestination({
    required String suggestedName,
    String? initialDirectory,
  }) async {
    suggestions.add(suggestedName);

    final configured = failure;
    return configured == null
        ? Result<String?>.success(destination)
        : Result<String?>.failure(configured);
  }
}
