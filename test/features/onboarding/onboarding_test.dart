import 'package:bloc_test/bloc_test.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/permissions/permission_service.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/storage_keys.dart';
import 'package:doc_forge/features/onboarding/application/usecases/onboarding_usecases.dart';
import 'package:doc_forge/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:doc_forge/features/onboarding/infrastructure/repositories/onboarding_repository_impl.dart';
import 'package:doc_forge/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:doc_forge/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// A repository whose answers are scripted.
class _FakeRepository implements OnboardingRepository {
  _FakeRepository({this.complete = false, this.failWrite = false});

  bool complete;
  bool failWrite;
  bool failRead = false;
  int markCompleteCalls = 0;

  @override
  Future<Result<bool>> isComplete() async => failRead
      ? const Result<bool>.failure(Failure.storage())
      : Result<bool>.success(complete);

  @override
  Future<Result<void>> markComplete() async {
    markCompleteCalls++;
    if (failWrite) {
      return const Result<void>.failure(Failure.storage());
    }
    complete = true;
    return const Result<void>.success(null);
  }
}

void main() {
  group('OnboardingRepositoryImpl', () {
    test('reports incomplete when the flag has never been written', () async {
      final repository = OnboardingRepositoryImpl(InMemoryPreferenceStore());

      expect((await repository.isComplete()).valueOrNull, isFalse);
    });

    test('persists and reads back completion', () async {
      final store = InMemoryPreferenceStore();
      final repository = OnboardingRepositoryImpl(store);

      await repository.markComplete();

      expect((await repository.isComplete()).valueOrNull, isTrue);
      expect(store.values[PreferenceKeys.onboardingComplete], isTrue);
    });

    test('uses the documented preference key', () async {
      final store = InMemoryPreferenceStore();

      await OnboardingRepositoryImpl(store).markComplete();

      expect(store.values.keys, contains(PreferenceKeys.onboardingComplete));
    });

    test('survives a simulated restart', () async {
      final store = InMemoryPreferenceStore();
      await OnboardingRepositoryImpl(store).markComplete();

      // A new repository over the same store models relaunching the app.
      final afterRestart = OnboardingRepositoryImpl(store);

      expect((await afterRestart.isComplete()).valueOrNull, isTrue);
    });

    test('surfaces a write failure', () async {
      final store = InMemoryPreferenceStore()..failNextWrite = true;

      final result = await OnboardingRepositoryImpl(store).markComplete();

      expect(result.isFailure, isTrue);
    });
  });

  group('IsOnboardingComplete', () {
    test('returns the persisted value', () async {
      expect(await IsOnboardingComplete(_FakeRepository())(), isFalse);
      expect(
        await IsOnboardingComplete(_FakeRepository(complete: true))(),
        isTrue,
      );
    });

    test('treats a read failure as not complete', () async {
      // Showing onboarding twice is a minor annoyance; skipping it would strand
      // a user who never granted camera permission on a Home screen whose main
      // action silently fails.
      final repository = _FakeRepository(complete: true)..failRead = true;

      expect(await IsOnboardingComplete(repository)(), isFalse);
    });
  });

  group('CompleteOnboarding', () {
    test('records completion', () async {
      final repository = _FakeRepository();

      final result = await CompleteOnboarding(repository)();

      expect(result.isSuccess, isTrue);
      expect(repository.complete, isTrue);
      expect(repository.markCompleteCalls, 1);
    });

    test('returns the failure when the flag cannot be persisted', () async {
      final repository = _FakeRepository(failWrite: true);

      expect((await CompleteOnboarding(repository)()).isFailure, isTrue);
    });
  });

  group('RequestOnboardingCameraPermission', () {
    test('requests the camera permission specifically', () async {
      final permissions = FakePermissionService(
        defaultState: PermissionState.denied,
        grantOnRequest: true,
      );

      final state = await RequestOnboardingCameraPermission(permissions)();

      expect(state, PermissionState.granted);
      expect(permissions.requestCallCount, 1);
    });

    test('reports a refusal without failing', () async {
      final permissions = FakePermissionService(
        defaultState: PermissionState.permanentlyDenied,
      );

      expect(
        await RequestOnboardingCameraPermission(permissions)(),
        PermissionState.permanentlyDenied,
      );
    });
  });

  group('OnboardingGateImpl', () {
    test('assumes onboarding is needed before loading', () {
      final gate = OnboardingGateImpl(() async => true);

      // A slow read must never let a first-time user slip past onboarding.
      expect(gate.needsOnboarding, isTrue);
      gate.dispose();
    });

    test('clears the requirement once a completed flag loads', () async {
      final gate = OnboardingGateImpl(() async => true);

      await gate.load();

      expect(gate.needsOnboarding, isFalse);
      gate.dispose();
    });

    test('keeps the requirement when onboarding is incomplete', () async {
      final gate = OnboardingGateImpl(() async => false);

      await gate.load();

      expect(gate.needsOnboarding, isTrue);
      gate.dispose();
    });

    test('publishes changes so the router can re-evaluate', () async {
      final gate = OnboardingGateImpl(() async => false);
      final changes = <bool>[];
      gate.onboardingChanges.listen(changes.add);

      gate.markComplete();
      await Future<void>.delayed(Duration.zero);

      expect(changes, [false]);
      expect(gate.needsOnboarding, isFalse);
      gate.dispose();
    });

    test('does not publish when nothing changed', () async {
      final gate = OnboardingGateImpl(() async => false);
      final changes = <bool>[];
      gate.onboardingChanges.listen(changes.add);

      await gate.load();
      await Future<void>.delayed(Duration.zero);

      expect(changes, isEmpty);
      gate.dispose();
    });
  });

  group('OnboardingCubit', () {
    late _FakeRepository repository;

    OnboardingCubit build({
      PermissionState permission = PermissionState.granted,
      bool grantOnRequest = false,
    }) {
      repository = _FakeRepository();
      return OnboardingCubit(
        CompleteOnboarding(repository),
        RequestOnboardingCameraPermission(
          FakePermissionService(
            defaultState: permission,
            grantOnRequest: grantOnRequest,
          ),
        ),
      );
    }

    test('starts on the welcome step', () {
      expect(build().state, const OnboardingState());
      expect(build().state.step, OnboardingStep.welcome);
    });

    blocTest<OnboardingCubit, OnboardingState>(
      'advances welcome -> privacy',
      build: build,
      act: (cubit) => cubit.continueFromWelcome(),
      expect: () => const [OnboardingState(step: OnboardingStep.privacy)],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'advances privacy -> permission',
      build: build,
      seed: () => const OnboardingState(step: OnboardingStep.privacy),
      act: (cubit) => cubit.continueFromPrivacy(),
      expect: () => const [OnboardingState(step: OnboardingStep.permission)],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'emits the full sequence when permission is granted',
      build: build,
      seed: () => const OnboardingState(step: OnboardingStep.permission),
      act: (cubit) => cubit.requestCameraPermission(),
      expect: () => const [
        OnboardingState(
          step: OnboardingStep.permission,
          isRequestingPermission: true,
        ),
        OnboardingState(
          step: OnboardingStep.permission,
          permission: PermissionState.granted,
        ),
        OnboardingState(
          step: OnboardingStep.finished,
          permission: PermissionState.granted,
        ),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'still finishes when permission is denied',
      build: () => build(permission: PermissionState.denied),
      seed: () => const OnboardingState(step: OnboardingStep.permission),
      act: (cubit) => cubit.requestCameraPermission(),
      expect: () => const [
        OnboardingState(
          step: OnboardingStep.permission,
          isRequestingPermission: true,
        ),
        OnboardingState(
          step: OnboardingStep.permission,
          permission: PermissionState.denied,
        ),
        OnboardingState(
          step: OnboardingStep.finished,
          permission: PermissionState.denied,
        ),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'skipping finishes without asking for permission',
      build: build,
      seed: () => const OnboardingState(step: OnboardingStep.permission),
      act: (cubit) => cubit.skipPermission(),
      expect: () => const [OnboardingState(step: OnboardingStep.finished)],
      verify: (_) {
        // No system prompt may be shown when the user skips.
        expect(repository.markCompleteCalls, 1);
      },
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'ignores a second request while one is in flight',
      build: build,
      seed: () => const OnboardingState(
        step: OnboardingStep.permission,
        isRequestingPermission: true,
      ),
      act: (cubit) => cubit.requestCameraPermission(),
      // A double tap must not raise two system prompts.
      expect: () => const <OnboardingState>[],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'persists completion before reporting finished',
      build: build,
      seed: () => const OnboardingState(step: OnboardingStep.permission),
      act: (cubit) => cubit.skipPermission(),
      verify: (_) => expect(repository.complete, isTrue),
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'still finishes when the flag cannot be persisted',
      build: () {
        repository = _FakeRepository(failWrite: true);
        return OnboardingCubit(
          CompleteOnboarding(repository),
          RequestOnboardingCameraPermission(FakePermissionService()),
        );
      },
      seed: () => const OnboardingState(step: OnboardingStep.permission),
      act: (cubit) => cubit.skipPermission(),
      // Trapping the user in onboarding because of a storage error would be
      // worse than showing it again next launch.
      expect: () => const [OnboardingState(step: OnboardingStep.finished)],
    );
  });

  group('OnboardingState', () {
    test('compares by value so identical states de-duplicate', () {
      expect(const OnboardingState(), const OnboardingState());
      expect(
        const OnboardingState(step: OnboardingStep.privacy),
        isNot(const OnboardingState()),
      );
    });

    test('lists every field in props', () {
      const state = OnboardingState(
        step: OnboardingStep.permission,
        permission: PermissionState.denied,
        isRequestingPermission: true,
      );

      expect(state.props, [
        OnboardingStep.permission,
        PermissionState.denied,
        true,
      ]);
    });

    test('reports when the flow is finished', () {
      expect(const OnboardingState().isFinished, isFalse);
      expect(
        const OnboardingState(step: OnboardingStep.finished).isFinished,
        isTrue,
      );
    });

    test('copyWith replaces only what it is given', () {
      const original = OnboardingState(permission: PermissionState.granted);

      final updated = original.copyWith(step: OnboardingStep.privacy);

      expect(updated.step, OnboardingStep.privacy);
      expect(updated.permission, PermissionState.granted);
    });
  });
}
