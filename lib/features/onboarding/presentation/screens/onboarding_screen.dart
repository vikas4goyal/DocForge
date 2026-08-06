/// The first-launch onboarding flow.
///
/// One widget owns the flow and swaps its body per step, rather than three
/// routes. The steps share a layout, must be traversed in order, and cannot be
/// deep-linked into individually — modelling them as separate routes would
/// invite exactly that.
///
/// Every screen is scrollable and every control is labelled: the accessibility
/// requirements demand the flow works with a screen reader, at the maximum text
/// scale, in dark mode, on both phone and tablet.
library;

import 'package:doc_scanly/core/permissions/permission_service.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:doc_scanly/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:doc_scanly/features/onboarding/presentation/onboarding_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Hosts the onboarding flow and routes onward when it finishes.
class OnboardingScreen extends StatelessWidget {
  /// Creates the onboarding flow.
  ///
  /// [onFinished] is invoked once the flow completes, so this widget performs
  /// no navigation itself and can be previewed and widget-tested in isolation.
  const OnboardingScreen({required this.onFinished, super.key});

  /// Called when onboarding finishes and the user should go to Home.
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) =>
          !previous.isFinished && current.isFinished,
      listener: (context, state) => onFinished(),
      builder: (context, state) => switch (state.step) {
        OnboardingStep.welcome => const _WelcomeStep(),
        OnboardingStep.privacy => const _PrivacyStep(),
        OnboardingStep.permission => _PermissionStep(state: state),
        // Briefly visible between finishing and the router redirecting.
        OnboardingStep.finished => const SizedBox.shrink(),
      },
    );
  }
}

/// Shared layout for every onboarding step.
///
/// Centres content on a phone and constrains its width on a tablet, so text
/// does not stretch into unreadably long lines on a wide screen.
class _OnboardingScaffold extends StatelessWidget {
  const _OnboardingScaffold({
    required this.screenKey,
    required this.icon,
    required this.title,
    required this.content,
    required this.actions,
  });

  final Key screenKey;
  final IconData icon;
  final String title;
  final List<Widget> content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: screenKey,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoints.compact),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      // Scrollable so nothing is lost at the maximum text scale.
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          // Decorative: a screen reader gains nothing from the
                          // icon's name, and the title already says this.
                          ExcludeSemantics(
                            child: Icon(
                              icon,
                              size: 64,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ...content,
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Step one: what the application is.
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      screenKey: OnboardingKeys.welcomeScreen,
      icon: Icons.document_scanner_outlined,
      title: 'Welcome to DocScanly',
      content: [
        Text(
          'Scan, organise, search and share your documents — quickly and '
          'privately.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
      actions: [
        FilledButton(
          key: OnboardingKeys.welcomeContinueButton,
          onPressed: () =>
              context.read<OnboardingCubit>().continueFromWelcome(),
          child: const Text('Get started'),
        ),
      ],
    );
  }
}

/// Step two: the privacy and offline guarantees.
class _PrivacyStep extends StatelessWidget {
  const _PrivacyStep();

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffold(
      screenKey: OnboardingKeys.privacyScreen,
      icon: Icons.lock_outline,
      title: 'Private by design',
      content: const [
        _PrivacyPoint(
          statementKey: OnboardingKeys.privacyLocalStorageStatement,
          icon: Icons.smartphone_outlined,
          text: 'Your documents are stored only on this device.',
        ),
        SizedBox(height: 12),
        _PrivacyPoint(
          statementKey: OnboardingKeys.privacyNoUploadStatement,
          icon: Icons.cloud_off_outlined,
          text: 'Nothing is uploaded automatically. You choose what to share.',
        ),
        SizedBox(height: 12),
        _PrivacyPoint(
          statementKey: OnboardingKeys.privacyOfflineStatement,
          icon: Icons.wifi_off_outlined,
          text:
              'Scanning and text recognition work without an internet '
              'connection.',
        ),
      ],
      actions: [
        FilledButton(
          key: OnboardingKeys.privacyContinueButton,
          onPressed: () =>
              context.read<OnboardingCubit>().continueFromPrivacy(),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

/// A single privacy guarantee.
///
/// The icon is decorative and the whole row is exposed as one semantics node,
/// so a screen reader reads the statement rather than announcing an icon and
/// then the text separately.
class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({
    required this.statementKey,
    required this.icon,
    required this.text,
  });

  final Key statementKey;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      key: statementKey,
      label: text,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

/// Step three: the just-in-time camera permission request.
class _PermissionStep extends StatelessWidget {
  const _PermissionStep({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final busy = state.isRequestingPermission;

    return _OnboardingScaffold(
      screenKey: OnboardingKeys.permissionScreen,
      icon: Icons.photo_camera_outlined,
      title: 'Allow camera access',
      content: [
        Text(
          'DocScanly needs your camera to scan documents. You can change this '
          'later in Settings.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        if (state.permission == PermissionState.denied ||
            state.permission == PermissionState.permanentlyDenied) ...[
          const SizedBox(height: 16),
          Text(
            'Camera access was not granted. You can still use DocScanly and '
            'grant it later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
      actions: [
        FilledButton(
          key: OnboardingKeys.permissionAllowButton,
          // Disabled while in flight so a double tap cannot raise two prompts.
          onPressed: busy ? null : cubit.requestCameraPermission,
          child: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Allow camera access'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: OnboardingKeys.permissionSkipButton,
          onPressed: busy ? null : cubit.skipPermission,
          child: const Text('Not now'),
        ),
      ],
    );
  }
}
