/// The root widget.
///
/// Holds the three things that must exist above every screen: the dependency
/// graph, the router, and the Material 3 themes. Everything else is reached
/// through a route.
library;

import 'package:doc_forge/app/app_dependencies.dart';
import 'package:doc_forge/core/storage/storage_keys.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
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
    super.key,
    this.themeMode = ThemeMode.system,
  });

  /// The dependency graph made available to every screen.
  final AppDependencies dependencies;

  /// The router owning every route in the application.
  final GoRouter router;

  /// Which theme to apply.
  ///
  /// Defaults to following the system. The settings feature replaces this with
  /// the persisted preference read from [PreferenceKeys.themeMode]; until then
  /// the system value is the documented default.
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return AppDependenciesScope(
      dependencies: dependencies,
      child: MaterialApp.router(
        title: 'DocForge',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // Supplying both themes plus a mode is what makes a system dark-mode
        // change re-render the whole app without a restart.
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
