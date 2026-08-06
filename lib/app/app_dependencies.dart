/// The dependency graph, built once and passed down the widget tree.
///
/// The project forbids service locators and global mutable state, so
/// dependencies are constructed explicitly and handed downward. Threading every
/// one through dozens of widget constructors that do not use them buys no
/// testability, so they travel together in this immutable value and are exposed
/// through a single [InheritedWidget].
///
/// This is the **one** deliberate exception to "no ambient state", and it is
/// bounded on purpose (`design.md` §5):
///
/// * it is immutable and constructed exactly once;
/// * it holds no behaviour of its own, only references;
/// * any test or preview can supply a different instance with fakes.
///
/// Cubits are *not* built here. They are created per route by `BlocProvider`
/// factories that read what they need from this object, so a Cubit's lifetime
/// is tied to its route rather than to the application.
library;

import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/isolates/thumbnail_cache.dart';
import 'package:doc_scanly/core/permissions/permission_service.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/telemetry/app_telemetry.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:flutter/widgets.dart';

/// Everything the application needs, constructed once at startup.
@immutable
class AppDependencies {
  /// Creates a dependency graph from already-constructed collaborators.
  const AppDependencies({
    required this.clock,
    required this.idGenerator,
    required this.preferences,
    required this.secureStorage,
    required this.permissions,
    required this.worker,
    required this.thumbnailCache,
    required this.telemetry,
  });

  /// Source of the current time. Injected so business logic is deterministic.
  final Clock clock;

  /// Source of new entity identifiers.
  final IdGenerator idGenerator;

  /// Non-sensitive key–value storage.
  final PreferenceStore preferences;

  /// Storage for secrets. Never used for anything else.
  final SecureStore secureStorage;

  /// Permission queries and requests.
  final PermissionService permissions;

  /// Runs heavy work off the UI thread.
  final BackgroundWorker worker;

  /// Bounded cache of display-resolution page thumbnails.
  final ThumbnailCache thumbnailCache;

  /// Operational analytics, performance traces, and non-fatal error reports.
  final AppTelemetry telemetry;

  /// Returns a copy with the given collaborators replaced.
  ///
  /// Exists for tests and previews, which typically swap one or two
  /// collaborators for fakes and keep the rest.
  AppDependencies copyWith({
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
      clock: clock ?? this.clock,
      idGenerator: idGenerator ?? this.idGenerator,
      preferences: preferences ?? this.preferences,
      secureStorage: secureStorage ?? this.secureStorage,
      permissions: permissions ?? this.permissions,
      worker: worker ?? this.worker,
      thumbnailCache: thumbnailCache ?? this.thumbnailCache,
      telemetry: telemetry ?? this.telemetry,
    );
  }
}

/// Exposes [AppDependencies] to the widget tree.
///
/// Deliberately has no default: a widget asking for dependencies that were
/// never provided is a wiring bug, and failing loudly at that point is far
/// easier to diagnose than silently constructing a real Isar instance inside a
/// widget test.
class AppDependenciesScope extends InheritedWidget {
  /// Provides [dependencies] to [child] and its descendants.
  const AppDependenciesScope({
    required this.dependencies,
    required super.child,
    super.key,
  });

  /// The dependency graph available to descendants.
  final AppDependencies dependencies;

  /// Returns the dependencies provided by the nearest enclosing scope.
  ///
  /// Throws a [FlutterError] when no scope is present.
  static AppDependencies of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppDependenciesScope>();

    if (scope == null) {
      throw FlutterError(
        'AppDependenciesScope.of() called with a context that does not '
        'contain an AppDependenciesScope.\n'
        'Wrap the widget tree in an AppDependenciesScope — in tests and '
        'previews, supply one built from fakes.',
      );
    }

    return scope.dependencies;
  }

  @override
  bool updateShouldNotify(AppDependenciesScope oldWidget) =>
      // The graph is immutable and built once, so this only fires when a test
      // deliberately swaps the whole set of dependencies.
      dependencies != oldWidget.dependencies;
}
