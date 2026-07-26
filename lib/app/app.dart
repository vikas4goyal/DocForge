/// The root widget.
///
/// Holds the three things that must exist above every screen: the dependency
/// graph, the router, and the Material 3 themes. Everything else is reached
/// through a route.
library;

import 'package:doc_forge/app/app_dependencies.dart';
import 'package:doc_forge/core/storage/storage_keys.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/core/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The DocForge application.
class DocForgeApp extends StatelessWidget {
  /// Creates the root widget over an already-built [dependencies] graph and
  /// [router].
  ///
  /// Both are constructed in `main` rather than here so that a test can supply
  /// fakes without the widget reaching for anything itself.
  const DocForgeApp({
    required this.dependencies,
    required this.router,
    required this.themeMode,
    super.key,
  });

  /// The dependency graph made available to every screen.
  final AppDependencies dependencies;

  /// The router owning every route in the application.
  final GoRouter router;

  /// Which theme to apply, and a way to observe changes to it.
  ///
  /// Listened to rather than read once: the spec requires an explicit theme
  /// selection in settings to apply without a restart, and settings is several
  /// routes below this widget. The initial value is the persisted preference
  /// read from [PreferenceKeys.themeMode] by the composition root.
  final ThemeModeController themeMode;

  @override
  Widget build(BuildContext context) {
    return AppDependenciesScope(
      dependencies: dependencies,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeMode,
        builder: (context, mode, _) => MaterialApp.router(
          title: 'DocForge',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          // Supplying both themes plus a mode is what makes a *system* dark-mode
          // change re-render without a restart; rebuilding on the notifier is
          // what makes an *explicit* selection do the same.
          themeMode: mode,
          routerConfig: router,
        ),
      ),
    );
  }
}
