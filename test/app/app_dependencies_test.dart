import 'package:doc_forge/app/app_dependencies.dart';
import 'package:doc_forge/app/fake_dependencies.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/isolates/thumbnail_cache.dart';
import 'package:doc_forge/core/permissions/permission_service.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildFakeAppDependencies', () {
    test('produces a fully in-memory graph', () {
      final deps = buildFakeAppDependencies();

      expect(deps.clock, isA<FixedClock>());
      expect(deps.idGenerator, isA<SequentialIdGenerator>());
      expect(deps.preferences, isA<InMemoryPreferenceStore>());
      expect(deps.secureStorage, isA<InMemorySecureStore>());
      expect(deps.permissions, isA<FakePermissionService>());
      expect(deps.worker, isA<InlineBackgroundWorker>());
    });

    test('is deterministic, so goldens built from it are stable', () {
      final first = buildFakeAppDependencies();
      final second = buildFakeAppDependencies();

      expect(first.clock.now(), second.clock.now());
      expect(first.idGenerator.generate(), second.idGenerator.generate());
    });

    test('accepts individual overrides', () {
      final clock = FixedClock(DateTime.utc(2030));

      final deps = buildFakeAppDependencies(clock: clock);

      expect(deps.clock.now(), DateTime.utc(2030));
      // Everything not overridden keeps its fake default.
      expect(deps.preferences, isA<InMemoryPreferenceStore>());
    });
  });

  group('copyWith', () {
    test('replaces only the named collaborators', () {
      final original = buildFakeAppDependencies();
      final replacement = InMemoryPreferenceStore({'k': 'v'});

      final updated = original.copyWith(preferences: replacement);

      expect(updated.preferences, same(replacement));
      expect(updated.clock, same(original.clock));
      expect(updated.secureStorage, same(original.secureStorage));
      expect(updated.permissions, same(original.permissions));
      expect(updated.worker, same(original.worker));
      expect(updated.thumbnailCache, same(original.thumbnailCache));
    });

    test('with no arguments preserves every collaborator', () {
      final original = buildFakeAppDependencies();

      final copy = original.copyWith();

      expect(copy.clock, same(original.clock));
      expect(copy.idGenerator, same(original.idGenerator));
    });
  });

  group('AppDependenciesScope', () {
    testWidgets('exposes its dependencies to descendants', (tester) async {
      final deps = buildFakeAppDependencies();
      AppDependencies? seen;

      await tester.pumpWidget(
        AppDependenciesScope(
          dependencies: deps,
          child: Builder(
            builder: (context) {
              seen = AppDependenciesScope.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen, same(deps));
    });

    testWidgets('every collaborator can be replaced with a fake', (
      tester,
    ) async {
      // The whole justification for the InheritedWidget exception is that a
      // test can substitute the entire graph. This is that guarantee.
      final clock = FixedClock(DateTime.utc(1999));
      final prefs = InMemoryPreferenceStore({'seeded': 'yes'});
      final secure = InMemorySecureStore({'secret': 'value'});
      final permissions = FakePermissionService(
        defaultState: PermissionState.permanentlyDenied,
      );
      final cache = ThumbnailCache(maxEntries: 1);
      final deps = buildFakeAppDependencies(
        clock: clock,
        idGenerator: SequentialIdGenerator(prefix: 'test'),
        preferences: prefs,
        secureStorage: secure,
        permissions: permissions,
        thumbnailCache: cache,
      );

      AppDependencies? seen;
      await tester.pumpWidget(
        AppDependenciesScope(
          dependencies: deps,
          child: Builder(
            builder: (context) {
              seen = AppDependenciesScope.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen!.clock.now(), DateTime.utc(1999));
      expect(seen!.idGenerator.generate(), 'test-1');
      expect(seen!.preferences, same(prefs));
      expect(seen!.secureStorage, same(secure));
      expect(seen!.permissions, same(permissions));
      expect(seen!.thumbnailCache, same(cache));
      expect(
        await seen!.permissions.status(PermissionKind.camera),
        PermissionState.permanentlyDenied,
      );
    });

    testWidgets('throws a helpful error when no scope is present', (
      tester,
    ) async {
      // Silently constructing real infrastructure inside a widget test would be
      // far harder to diagnose than failing here.
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => AppDependenciesScope.of(context),
              throwsA(
                isA<FlutterError>().having(
                  (e) => e.message,
                  'message',
                  contains('AppDependenciesScope'),
                ),
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      );
    });

    test('notifies dependents only when the graph is swapped', () {
      // Tested directly rather than through pumpWidget: pumping rebuilds the
      // child widget regardless of updateShouldNotify, so a build counter
      // cannot distinguish the two cases.
      final deps = buildFakeAppDependencies();
      const child = SizedBox.shrink();

      final scope = AppDependenciesScope(dependencies: deps, child: child);
      final same = AppDependenciesScope(dependencies: deps, child: child);
      final different = AppDependenciesScope(
        dependencies: buildFakeAppDependencies(),
        child: child,
      );

      expect(scope.updateShouldNotify(same), isFalse);
      expect(scope.updateShouldNotify(different), isTrue);
    });
  });

  group('fake graph is genuinely inert', () {
    test('the fake worker runs jobs without spawning an isolate', () async {
      final deps = buildFakeAppDependencies();

      final result = await deps.worker.run(_identity, 7);

      expect(result.valueOrNull, 7);
    });

    test('the fake preference store starts empty', () async {
      final deps = buildFakeAppDependencies();

      expect(
        (await deps.preferences.readString('anything')).valueOrNull,
        isNull,
      );
    });

    test('the fake secure store can simulate being unavailable', () async {
      final secure = InMemorySecureStore()..failNextOperation = true;
      final deps = buildFakeAppDependencies(secureStorage: secure);

      final result = await deps.secureStorage.read('k');

      expect(result.failureOrNull, isA<SecureStorageFailure>());
    });
  });
}

/// Returns its input. Top-level so it is a valid isolate entry point.
int _identity(int value) => value;
