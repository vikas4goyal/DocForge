/// Builds the dependency graph at startup.
///
/// This is the only place in the application that constructs infrastructure.
/// Everything downstream receives what it needs through a constructor or
/// through [AppDependencies], so no repository, use case or Cubit ever reaches
/// out for a collaborator.
///
/// Construction order is fixed and one-directional — platform primitives, then
/// data sources, then repositories, then use cases — which is what makes the
/// dependency graph a graph rather than a web (`design.md` §5).
library;

import 'package:doc_forge/app/app_dependencies.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/isolates/thumbnail_cache.dart';
import 'package:doc_forge/core/permissions/permission_service.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Constructs the production dependency graph.
///
/// Call once from `main` before running the application. Awaits the platform
/// primitives that must be resolved before anything can use them — notably
/// SharedPreferences, which is asynchronous to obtain but synchronous to read,
/// so resolving it here keeps every later read cheap and non-async.
Future<AppDependencies> buildAppDependencies() async {
  // 1. Platform primitives.
  final preferences = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage(
    // No `encryptedSharedPreferences` flag: Google deprecated Jetpack Security,
    // and flutter_secure_storage 10+ applies its own ciphers on Android
    // unconditionally, migrating existing values on first access. Passing the
    // old flag is now ignored.
    //
    // first_unlock rather than the stricter passcode-only accessibility: the
    // app lock must be able to read its own configuration on a cold start
    // before the user has authenticated, otherwise the lock cannot tell whether
    // it is enabled.
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // 2. Cross-cutting collaborators.
  return AppDependencies(
    clock: const SystemClock(),
    idGenerator: UuidGenerator(),
    preferences: SharedPreferencesStore(preferences),
    secureStorage: const FlutterSecureStore(secureStorage),
    permissions: const PluginPermissionService(),
    // One isolate shared across jobs rather than one spawned per job. A scan
    // session runs hundreds of them — a preview render per adjustment, a
    // correction per crop, a pass per page of a batch — and each spawn
    // allocates a heap and starts an event loop before any pixel is touched.
    worker: PooledIsolateBackgroundWorker(),
    thumbnailCache: ThumbnailCache(),
  );
}

/// Constructs a dependency graph backed entirely by in-memory fakes.
///
/// For widget tests, previews and goldens. Nothing here touches the platform,
/// the filesystem, the network or a database, and every collaborator is
/// deterministic — a fixed clock and sequential ids — so a golden rendered from
/// it is byte-stable.
AppDependencies buildFakeAppDependencies({
  Clock? clock,
  IdGenerator? idGenerator,
  PreferenceStore? preferences,
  SecureStore? secureStorage,
  PermissionService? permissions,
  BackgroundWorker? worker,
  ThumbnailCache? thumbnailCache,
}) {
  return AppDependencies(
    clock: clock ?? FixedClock(DateTime.utc(2026, 7, 26, 10, 30)),
    idGenerator: idGenerator ?? SequentialIdGenerator(),
    preferences: preferences ?? InMemoryPreferenceStore(),
    secureStorage: secureStorage ?? InMemorySecureStore(),
    permissions: permissions ?? FakePermissionService(),
    // Inline rather than isolate-backed: a test asserting on a failure should
    // not also be exercising isolate spawn behaviour.
    worker: worker ?? const InlineBackgroundWorker(),
    thumbnailCache: thumbnailCache ?? ThumbnailCache(),
  );
}
