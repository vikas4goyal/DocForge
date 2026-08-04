/// Every failure the specs name has a message and a recovery action.
///
/// The specs state this per feature; this file states it once, for the whole
/// vocabulary. `Failure` is a sealed union, so a new variant is a compile error
/// here until someone decides what the user sees — which is precisely the
/// property the sealed union was chosen for (`design.md` §3).
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:flutter_test/flutter_test.dart';

/// One of every failure the application can produce.
///
/// Written out rather than generated, so adding a variant to the union without
/// adding it here is caught by the exhaustiveness test at the bottom.
const _everyFailure = <Failure>[
  Failure.camera(),
  Failure.camera(inUseByAnotherApp: true),
  Failure.permission(kind: PermissionKind.camera),
  Failure.permission(kind: PermissionKind.photos, permanentlyDenied: true),
  Failure.permission(kind: PermissionKind.files),
  Failure.ocr(),
  Failure.pdf(),
  Failure.storageFull(),
  Failure.import(),
  Failure.import(unsupportedType: true),
  Failure.export(),
  Failure.export(noReceivingApp: true),
  Failure.auth(),
  Failure.auth(rejected: false, notEnrolled: true),
  Failure.validation(issue: ValidationIssue.emptyName),
  Failure.validation(issue: ValidationIssue.duplicateFolderName),
  Failure.validation(issue: ValidationIssue.documentWouldHaveNoPages),
  Failure.notFound(),
  Failure.corruptFile(),
  Failure.secureStorageUnavailable(),
  Failure.storage(),
  Failure.cancelled(),
  Failure.unexpected(),
];

void main() {
  group('every failure explains itself', () {
    test('each has a non-empty, human-readable message', () {
      for (final failure in _everyFailure) {
        // Cancellation is the deliberate exception, and the only one: the specs
        // require the UI to say *nothing* when the user cancelled, so an empty
        // message here is the correct value rather than a gap.
        if (failure.isCancellation) continue;

        final message = failure.presentation.message;

        expect(message, isNotEmpty, reason: '$failure has no message');
        // A message that is a type name is not human-readable.
        expect(
          message,
          isNot(contains('Failure')),
          reason: '$failure leaks its type into the message',
        );
      }
    });

    test('no message leaks a technical detail', () {
      for (final failure in _everyFailure) {
        final message = failure.presentation.message.toLowerCase();

        for (final jargon in [
          'exception',
          'errno',
          'null',
          'stacktrace',
          'isar',
        ]) {
          expect(
            message,
            isNot(contains(jargon)),
            reason: '$failure says "$jargon" to the user',
          );
        }
      }
    });

    test('each message ends as a sentence', () {
      // Not pedantry: a message rendered next to a retry button reads as an
      // instruction when it is a sentence and as a log line when it is not.
      for (final failure in _everyFailure) {
        if (failure.isCancellation) continue;

        expect(
          failure.presentation.message,
          matches(RegExp(r'[.!?]$')),
          reason: '$failure is not a sentence',
        );
      }
    });
  });

  group('every failure offers a way forward', () {
    test('each names a recovery action', () {
      for (final failure in _everyFailure) {
        expect(
          failure.presentation.action,
          isNotNull,
          reason: '$failure offers nothing',
        );
      }
    });

    test('only the two that genuinely have none offer none', () {
      // Cancellation is the user's own doing and needs no message at all;
      // validation is corrected in place, beside the field. Everything else
      // must lead somewhere.
      final withoutAction = [
        for (final failure in _everyFailure)
          if (failure.presentation.action == RecoveryAction.none) failure,
      ];

      expect(
        withoutAction.every(
          (failure) =>
              failure is CancelledFailure || failure is ValidationFailure,
        ),
        isTrue,
        reason: 'these offer no recovery: $withoutAction',
      );
    });

    test('a permanently denied permission leads to the system settings', () {
      // The one case a retry cannot resolve.
      expect(
        const Failure.permission(
          kind: PermissionKind.photos,
          permanentlyDenied: true,
        ).presentation.action,
        RecoveryAction.openSettings,
      );

      expect(
        const Failure.permission(
          kind: PermissionKind.photos,
        ).presentation.action,
        RecoveryAction.retry,
      );
    });

    test('a device with nothing enrolled leads to the system settings', () {
      expect(
        const Failure.auth(
          rejected: false,
          notEnrolled: true,
        ).presentation.action,
        RecoveryAction.openSettings,
      );
    });

    test('a full device leads to managing storage, not to a retry', () {
      // Retrying an operation that failed for want of space fails again.
      expect(
        const Failure.storageFull().presentation.action,
        RecoveryAction.freeStorage,
      );
    });

    test('nothing able to receive a share leads to exporting instead', () {
      expect(
        const Failure.export(noReceivingApp: true).presentation.action,
        RecoveryAction.exportInstead,
      );
    });
  });

  group('cancellation is not an error', () {
    test('it says nothing at all', () {
      // Not an oversight — a message for "you cancelled" is noise about
      // something the user just did on purpose.
      expect(const Failure.cancelled().presentation.message, isEmpty);
    });

    test('it is recognisable without pattern-matching every call site', () {
      expect(const Failure.cancelled().isCancellation, isTrue);

      for (final failure in _everyFailure) {
        if (failure is CancelledFailure) continue;
        expect(failure.isCancellation, isFalse, reason: '$failure');
      }
    });

    test('it offers no recovery action, because none is needed', () {
      expect(
        const Failure.cancelled().presentation.action,
        RecoveryAction.none,
      );
    });
  });

  group('the vocabulary is complete', () {
    test('every variant of the union appears in this file', () {
      // The exhaustiveness guard. A new `Failure` variant makes this switch a
      // compile error, so it cannot be added without deciding what the user is
      // told and where they are sent.
      const sample = Failure.unexpected();

      final covered = switch (sample) {
        CameraFailure() => true,
        PermissionFailure() => true,
        OcrFailure() => true,
        PdfFailure() => true,
        StorageFullFailure() => true,
        ImportFailure() => true,
        ExportFailure() => true,
        AuthFailure() => true,
        ValidationFailure() => true,
        NotFoundFailure() => true,
        CorruptFileFailure() => true,
        SecureStorageFailure() => true,
        StorageFailure() => true,
        CancelledFailure() => true,
        UnexpectedFailure() => true,
      };

      expect(covered, isTrue);

      // And every one of those types is represented in the list above.
      final types = _everyFailure.map((f) => f.runtimeType).toSet();
      expect(types, hasLength(15));
    });
  });
}
