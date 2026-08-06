/// The in-memory dependency graph tests, previews and goldens run against.
///
/// Kept in its own file rather than beside [buildAppDependencies] so the
/// layering check can state a rule it could not otherwise state: nothing
/// reachable from production `main.dart` may name a fake. The two builders sat
/// in one file until that rule existed, which made "no fake ships to a user" a
/// convention rather than something enforced.
///
/// It still lives under `lib/` rather than under `test/`, because the widget
/// previews need it and previews are built from `lib/`.
library;

import 'package:doc_scanly/app/app_dependencies.dart';
import 'package:doc_scanly/app/composition_root.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/isolates/thumbnail_cache.dart';
import 'package:doc_scanly/core/permissions/permission_service.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/telemetry/app_telemetry.dart';
import 'package:doc_scanly/core/time/clock.dart';

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
  AppTelemetry? telemetry,
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
    telemetry: telemetry ?? const NoopAppTelemetry(),
  );
}
