import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/permissions/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakePermissionService', () {
    test('answers the default state for any kind', () async {
      final service = FakePermissionService();

      expect(
        await service.status(PermissionKind.camera),
        PermissionState.granted,
      );
      expect(
        await service.status(PermissionKind.photos),
        PermissionState.granted,
      );
    });

    test('honours per-kind overrides', () async {
      final service = FakePermissionService(
        states: {PermissionKind.camera: PermissionState.denied},
      );

      expect(
        await service.status(PermissionKind.camera),
        PermissionState.denied,
      );
      expect(
        await service.status(PermissionKind.files),
        PermissionState.granted,
      );
    });

    test('status does not count as a request', () async {
      final service = FakePermissionService();

      await service.status(PermissionKind.camera);

      // Just-in-time prompting means checking must not prompt.
      expect(service.requestCallCount, 0);
    });

    test('counts requests', () async {
      final service = FakePermissionService();

      await service.request(PermissionKind.camera);
      await service.request(PermissionKind.photos);

      expect(service.requestCallCount, 2);
    });

    test('grants a denied permission when the user accepts', () async {
      final service = FakePermissionService(
        defaultState: PermissionState.denied,
        grantOnRequest: true,
      );

      expect(
        await service.request(PermissionKind.camera),
        PermissionState.granted,
      );
      expect(
        await service.status(PermissionKind.camera),
        PermissionState.granted,
      );
    });

    test(
      'a permanently denied permission is never granted by a request',
      () async {
        final service = FakePermissionService(
          defaultState: PermissionState.permanentlyDenied,
          grantOnRequest: true,
        );

        // The system shows no prompt once "don't ask again" is chosen, so the
        // fake must not pretend one appeared.
        expect(
          await service.request(PermissionKind.camera),
          PermissionState.permanentlyDenied,
        );
      },
    );

    test('records openSettings calls', () async {
      final service = FakePermissionService();

      expect(await service.openSettings(), isTrue);
      expect(service.openSettingsCallCount, 1);
    });
  });

  group('require', () {
    test('succeeds when granted', () async {
      final service = FakePermissionService();

      final result = await service.require(PermissionKind.camera);

      expect(result.isSuccess, isTrue);
    });

    test('maps a denial to a retryable permission failure', () async {
      final service = FakePermissionService(
        defaultState: PermissionState.denied,
      );

      final failure = (await service.require(
        PermissionKind.camera,
      )).failureOrNull;

      expect(failure, isA<PermissionFailure>());
      expect((failure! as PermissionFailure).permanentlyDenied, isFalse);
      expect((failure as PermissionFailure).kind, PermissionKind.camera);
    });

    test('maps a permanent denial so the UI offers settings', () async {
      final service = FakePermissionService(
        defaultState: PermissionState.permanentlyDenied,
      );

      final failure = (await service.require(
        PermissionKind.photos,
      )).failureOrNull;

      expect((failure! as PermissionFailure).permanentlyDenied, isTrue);
    });

    test('treats a restricted permission as permanently denied', () async {
      final service = FakePermissionService(
        defaultState: PermissionState.restricted,
      );

      final failure = (await service.require(
        PermissionKind.camera,
      )).failureOrNull;

      // Neither a retry nor a prompt can help, so the UI must not offer one.
      expect((failure! as PermissionFailure).permanentlyDenied, isTrue);
    });

    test('carries the requested kind through to the failure', () async {
      final service = FakePermissionService(
        defaultState: PermissionState.denied,
      );

      for (final kind in PermissionKind.values) {
        final failure =
            (await service.require(kind)).failureOrNull! as PermissionFailure;

        expect(failure.kind, kind);
      }
    });
  });
}
