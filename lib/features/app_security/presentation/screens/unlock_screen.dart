/// The unlock screen.
library;

import 'package:doc_forge/features/app_security/domain/app_lock.dart';
import 'package:doc_forge/features/app_security/presentation/cubit/app_lock_cubit.dart';
import 'package:doc_forge/features/app_security/presentation/security_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Stands between a launch and the library when the lock is enabled.
///
/// Renders **nothing about any document** — no title, no thumbnail, no count.
/// That is not incidental: the router shows this screen in place of every other
/// route while the gate reports locked, and this screen has no access to a
/// document reader to leak from even if it wanted to.
///
/// Keys: [SecurityKeys.unlockScreen] on the root. The keys are normative and
/// come from `specs/app-security/spec.md`.
class UnlockScreen extends StatefulWidget {
  /// Creates the unlock screen.
  const UnlockScreen({
    super.key,
    this.onOpenSettings,
    this.promptOnOpen = true,
  });

  /// Invoked when the user opens the system settings to enrol a credential.
  final VoidCallback? onOpenSettings;

  /// Whether to raise the system prompt as soon as the screen appears.
  ///
  /// True in the application, because making the user tap "Unlock" before the
  /// prompt they expected is a step with one option. False in tests, previews
  /// and goldens, where an automatic prompt would fire on every render.
  final bool promptOnOpen;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  @override
  void initState() {
    super.initState();

    if (widget.promptOnOpen) {
      // After the first frame: raising a system dialogue during build leaves
      // the screen behind it unpainted, so a dismissed prompt reveals nothing
      // but a blank rectangle.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AppLockCubit>().authenticate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLockCubit, AppLockState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final cubit = context.read<AppLockCubit>();

        return Scaffold(
          key: SecurityKeys.unlockScreen,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                // Width-limited rather than stretched: on a tablet a centred
                // column reads as a lock screen, and a full-width one reads as
                // an empty page.
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.lock_outline,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLockRules.unlockTitle,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLockRules.unlockInstruction,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (state.message != null) ...[
                      const SizedBox(height: 24),
                      Semantics(
                        key: SecurityKeys.unlockMessage,
                        // A live region, so a screen reader announces a
                        // rejection without the user having to go looking for
                        // the text that appeared.
                        liveRegion: true,
                        child: Text(
                          state.message!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (state.isAuthenticating)
                      const CircularProgressIndicator(
                        key: SecurityKeys.authenticatingIndicator,
                      )
                    else if (state.canRetry)
                      Semantics(
                        button: true,
                        label: AppLockRules.unlockSemanticsLabel,
                        excludeSemantics: true,
                        child: FilledButton.icon(
                          key: SecurityKeys.unlockRetryButton,
                          onPressed: cubit.authenticate,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text(AppLockRules.unlockActionLabel),
                        ),
                      ),
                    if (state.needsDeviceSetup &&
                        widget.onOpenSettings != null) ...[
                      const SizedBox(height: 12),
                      // Offered *instead of* a retry, not alongside it: nothing
                      // the user does here can succeed until they enrol
                      // something, so a retry button would be inert.
                      TextButton(
                        key: SecurityKeys.openSettingsButton,
                        onPressed: widget.onOpenSettings,
                        child: const Text('Open device settings'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
