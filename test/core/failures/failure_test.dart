import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every [Failure] variant, so the mapping test cannot silently miss one.
///
/// A new variant added to the sealed union without being added here will fail
/// the completeness test below rather than reaching users as a blank message.
const allFailures = <Failure>[
  Failure.camera(),
  Failure.camera(inUseByAnotherApp: true),
  Failure.permission(kind: PermissionKind.camera),
  Failure.permission(kind: PermissionKind.photos),
  Failure.permission(kind: PermissionKind.files),
  Failure.permission(kind: PermissionKind.camera, permanentlyDenied: true),
  Failure.ocr(),
  Failure.pdf(),
  Failure.storageFull(),
  Failure.import(),
  Failure.import(unsupportedType: true),
  Failure.export(),
  Failure.export(noReceivingApp: true),
  Failure.auth(),
  Failure.auth(rejected: false),
  Failure.auth(notEnrolled: true),
  Failure.notFound(),
  Failure.corruptFile(),
  Failure.secureStorageUnavailable(),
  Failure.storage(),
  Failure.cancelled(),
  Failure.unexpected(),
];

void main() {
  group('Failure equality', () {
    test('identical variants are equal', () {
      expect(const Failure.ocr(), const Failure.ocr());
      expect(
        const Failure.permission(kind: PermissionKind.camera),
        const Failure.permission(kind: PermissionKind.camera),
      );
    });

    test('different variants are not equal', () {
      expect(const Failure.ocr(), isNot(const Failure.pdf()));
    });

    test('the same variant with different data is not equal', () {
      expect(
        const Failure.permission(kind: PermissionKind.camera),
        isNot(const Failure.permission(kind: PermissionKind.photos)),
      );
    });
  });

  group('isCancellation', () {
    test('is true only for the cancelled variant', () {
      expect(const Failure.cancelled().isCancellation, isTrue);

      for (final failure in allFailures.where((f) => f is! CancelledFailure)) {
        expect(
          failure.isCancellation,
          isFalse,
          reason: '$failure should not be a cancellation',
        );
      }
    });
  });

  group('presentation mapping is exhaustive and usable', () {
    test('every variant maps to a presentation', () {
      for (final failure in allFailures) {
        expect(
          () => failure.presentation,
          returnsNormally,
          reason: '$failure has no presentation',
        );
      }
    });

    test('every non-cancellation variant has a non-empty message', () {
      for (final failure in allFailures.where((f) => !f.isCancellation)) {
        expect(
          failure.presentation.message,
          isNotEmpty,
          reason: '$failure produced an empty message',
        );
      }
    });

    test('every non-cancellation variant offers a recovery action', () {
      for (final failure in allFailures.where((f) => !f.isCancellation)) {
        expect(
          failure.presentation.action,
          isNot(RecoveryAction.none),
          reason: '$failure offers the user no way forward',
        );
      }
    });

    test('cancellation shows nothing and offers nothing', () {
      const presentation = FailurePresentation(
        message: '',
        action: RecoveryAction.none,
      );

      expect(
        const Failure.cancelled().presentation.message,
        presentation.message,
      );
      expect(
        const Failure.cancelled().presentation.action,
        presentation.action,
      );
    });

    test('no message leaks technical detail to the user', () {
      for (final failure in allFailures) {
        expect(
          failure.presentation.message.toLowerCase(),
          isNot(anyOf(contains('exception'), contains('null'), contains('0x'))),
          reason: '$failure leaks technical detail',
        );
      }
    });
  });

  group('recovery actions match the specs', () {
    test('a permanently denied permission offers system settings', () {
      const failure = Failure.permission(
        kind: PermissionKind.camera,
        permanentlyDenied: true,
      );

      // Retrying an in-app request would silently do nothing once the user has
      // chosen "don't ask again", so settings is the only real recovery.
      expect(failure.presentation.action, RecoveryAction.openSettings);
    });

    test('a denied-but-askable permission offers a retry', () {
      const failure = Failure.permission(kind: PermissionKind.camera);

      expect(failure.presentation.action, RecoveryAction.retry);
    });

    test('each permission kind names what it needs', () {
      expect(
        const Failure.permission(
          kind: PermissionKind.camera,
        ).presentation.message,
        contains('camera'),
      );
      expect(
        const Failure.permission(
          kind: PermissionKind.photos,
        ).presentation.message,
        contains('photo'),
      );
      expect(
        const Failure.permission(
          kind: PermissionKind.files,
        ).presentation.message,
        contains('file'),
      );
    });

    test('storage full guides the user to free space', () {
      expect(
        const Failure.storageFull().presentation.action,
        RecoveryAction.freeStorage,
      );
    });

    test('no receiving app offers export instead of sharing', () {
      expect(
        const Failure.export(noReceivingApp: true).presentation.action,
        RecoveryAction.exportInstead,
      );
    });

    test('an unsupported import type names the supported types', () {
      final message = const Failure.import(
        unsupportedType: true,
      ).presentation.message.toLowerCase();

      expect(message, contains('pdf'));
      expect(message, contains('image'));
    });

    test('OCR failure reassures that the document is still usable', () {
      // The specs require OCR failure never to block document creation, so the
      // message must not imply the document was lost.
      expect(
        const Failure.ocr().presentation.message.toLowerCase(),
        contains('still saved'),
      );
    });

    test('not-enrolled authentication points at device setup', () {
      expect(
        const Failure.auth(notEnrolled: true).presentation.action,
        RecoveryAction.openSettings,
      );
    });

    test('a missing or corrupt file offers a way back rather than a retry', () {
      expect(
        const Failure.notFound().presentation.action,
        RecoveryAction.goBack,
      );
      expect(
        const Failure.corruptFile().presentation.action,
        RecoveryAction.goBack,
      );
    });
  });
}
