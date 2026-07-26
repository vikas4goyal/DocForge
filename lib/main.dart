/// Entry point for the DocForge application.
///
/// Deliberately thin: build the dependency graph once, build the router over
/// it, hand both to the root widget. No feature logic, no service lookup and no
/// mutable global state lives here.
library;

import 'package:doc_forge/app/app.dart';
import 'package:doc_forge/app/app_dependencies.dart';
import 'package:doc_forge/app/composition_root.dart';
import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/app_routes.dart';
import 'package:doc_forge/app/router/route_gates.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/onboarding/application/usecases/onboarding_usecases.dart';
import 'package:doc_forge/features/onboarding/infrastructure/repositories/onboarding_repository_impl.dart';
import 'package:doc_forge/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:doc_forge/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Boots the application.
Future<void> main() async {
  // Required before any plugin is touched — SharedPreferences and secure
  // storage are both resolved inside buildAppDependencies.
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await buildAppDependencies();

  // Onboarding owns its own gate. The flag is read once here, before the first
  // frame, so the router's synchronous redirect has an answer immediately —
  // otherwise a first-time user would see Home flash before onboarding.
  final onboardingRepository = OnboardingRepositoryImpl(
    dependencies.preferences,
  );
  final onboardingGate = OnboardingGateImpl(
    IsOnboardingComplete(onboardingRepository).call,
  );
  await onboardingGate.load();

  // The lock gate is still a placeholder: `app-security` supplies the real one.
  final router = createAppRouter(
    guard: RouteGuard(
      lockGate: FakeAppLockGate(),
      onboardingGate: onboardingGate,
    ),
    screens: _screens(dependencies, onboardingRepository, onboardingGate),
  );

  runApp(DocForgeApp(dependencies: dependencies, router: router));
}

/// Builds the screen set, replacing placeholders as features land.
AppScreens _screens(
  AppDependencies dependencies,
  OnboardingRepositoryImpl onboardingRepository,
  OnboardingGateImpl onboardingGate,
) {
  return AppScreens(
    onboarding: (context) => BlocProvider(
      create: (_) => OnboardingCubit(
        CompleteOnboarding(onboardingRepository),
        RequestOnboardingCameraPermission(dependencies.permissions),
      ),
      child: OnboardingScreen(
        onFinished: () {
          // Update the gate first: the router re-evaluates its redirect on
          // navigation, and a stale gate would bounce the user straight back
          // into onboarding.
          onboardingGate.markComplete();
          context.go(AppRoutes.home);
        },
      ),
    ),
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
}

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
