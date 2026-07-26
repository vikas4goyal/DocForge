/// Entry point for the DocForge application.
///
/// Deliberately thin: build the dependency graph once, build the router over
/// it, hand both to the root widget. No feature logic, no service lookup and no
/// mutable global state lives here.
library;

import 'package:doc_forge/app/app.dart';
import 'package:doc_forge/app/composition_root.dart';
import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/route_gates.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:flutter/material.dart';

/// Boots the application.
Future<void> main() async {
  // Required before any plugin is touched — SharedPreferences and secure
  // storage are both resolved inside buildAppDependencies.
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await buildAppDependencies();

  // Both gates are placeholders until their owning features land: the app is
  // unlocked and onboarding is complete, so every route is reachable while the
  // remaining capabilities are built. `app-security` supplies the real lock
  // gate and `onboarding` the real onboarding gate.
  final router = createAppRouter(
    guard: RouteGuard(
      lockGate: FakeAppLockGate(),
      onboardingGate: FakeOnboardingGate(),
    ),
    screens: _placeholderScreens,
  );

  runApp(DocForgeApp(dependencies: dependencies, router: router));
}

/// Placeholder screens shown until each capability is implemented.
///
/// Every route resolves to a labelled screen rather than a crash, so the app is
/// runnable on a device throughout the build-out and each route can be checked
/// as its feature lands. Entries are replaced one at a time as the
/// corresponding feature group is completed.
final _placeholderScreens = AppScreens(
  onboarding: (_) => const _Placeholder('Onboarding'),
  unlock: (_) => const _Placeholder('Unlock'),
  home: (_) => const _Placeholder('Home'),
  scan: (_) => const _Placeholder('Scan'),
  scanReview: (_) => const _Placeholder('Review pages'),
  scanEnhance: (_) => const _Placeholder('Enhance'),
  scanPreview: (_) => const _Placeholder('Preview document'),
  documents: (_) => const _Placeholder('Documents'),
  documentDetail: (_, id) => _Placeholder('Document ${id.value}'),
  documentEdit: (_, id) => _Placeholder('Edit ${id.value}'),
  folders: (_) => const _Placeholder('Folders'),
  folderDetail: (_, id) => _Placeholder('Folder ${id.value}'),
  search: (_) => const _Placeholder('Search'),
  favourites: (_) => const _Placeholder('Favourites'),
  archive: (_) => const _Placeholder('Archive'),
  settings: (_) => const _Placeholder('Settings'),
  about: (_) => const _Placeholder('About'),
  privacy: (_) => const _Placeholder('Privacy policy'),
);

/// A labelled stand-in for a screen that has not been built yet.
class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppEmptyState(
        title: title,
        message: 'This screen has not been built yet.',
        icon: Icons.construction_outlined,
      ),
    );
  }
}
