/// Builds the settings screen and the two informational screens it pushes.
library;

import 'package:doc_scanly/app/router/app_router.dart';
import 'package:doc_scanly/app/router/app_routes.dart';
import 'package:doc_scanly/app/screens/screen_support.dart';
import 'package:doc_scanly/app/settings_module.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/theme/theme_mode_controller.dart';
import 'package:doc_scanly/features/app_security/application/usecases/app_lock_usecases.dart';
import 'package:doc_scanly/features/app_security/domain/app_lock.dart';
import 'package:doc_scanly/features/app_security/domain/repositories/app_lock_repository.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/presentation/cubit/settings_cubit.dart';
import 'package:doc_scanly/features/app_settings/presentation/screens/settings_detail_screens.dart';
import 'package:doc_scanly/features/app_settings/presentation/screens/settings_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The settings screen and its two pushed destinations.
class SettingsScreens {
  /// Creates the group.
  const SettingsScreens({
    required this.settings,
    required this.settingsTab,
    required this.about,
    required this.privacy,
  });

  /// The settings screen itself.
  ///
  /// Used twice: as the settings tab of the shell and as the `/settings` route.
  /// One builder rather than two, so a change to either reaches both.
  final ScreenBuilder settings;

  /// Settings composed as a tab destination, without a back action.
  final ScreenBuilder settingsTab;

  /// About, as a route.
  ///
  /// A placeholder: the real About screen is pushed imperatively from settings,
  /// because it carries no state the router has any reason to hold.
  final ScreenBuilder about;

  /// The privacy policy, as a route, for the same reason as [about].
  final ScreenBuilder privacy;
}

/// Builds settings over [settings], publishing what it persists.
///
/// [currentSettings] is written on every rebuild so the naming pattern and
/// quality presets a new document uses are the ones on screen rather than the
/// ones loaded at startup. [themeMode] is published to so an explicit theme
/// choice applies without a restart, which the spec requires.
///
/// [appVersion] is shown on About. [lockConfiguration] stores whether the lock
/// is on, and [authenticator] confirms who is asking — in both directions, for
/// the reason [toggleAppLock] documents. [authenticator] is a parameter because
/// biometrics are a platform edge; the composition root defaults it to the real
/// device authenticator.
SettingsScreens buildSettingsScreens({
  required SettingsModule settings,
  required ValueNotifier<AppSettings> currentSettings,
  required ThemeModeController themeMode,
  required String appVersion,
  required AppLockConfiguration lockConfiguration,
  required DeviceAuthenticator authenticator,
  bool supportsCloudStorage = false,
  DirectoryPicker? pickSaveLocation,
}) {
  final directoryPicker =
      pickSaveLocation ??
      () => FilePicker.getDirectoryPath(
        dialogTitle: 'Choose default save location',
      );
  Widget settingsScreen(BuildContext context, {required bool isTab}) =>
      BlocProvider(
        create: (_) => SettingsCubit(
          settings.load,
          settings.update,
          settings.previewName,
          settings.storage,
          // Published to the root so an explicit theme takes effect without a
          // restart, which the spec requires.
          onThemeChanged: (choice) => themeMode.select(themeModeFor(choice)),
        )..load(),
        child: Builder(
          builder: (screenContext) {
            // Kept in step with what was actually persisted, so the naming
            // pattern and quality presets a new document uses are the ones on
            // screen.
            currentSettings.value = screenContext
                .watch<SettingsCubit>()
                .state
                .settings;

            return SettingsScreen(
              onBack: isTab ? null : () => context.pop(),
              pickSaveLocation: directoryPicker,
              onAbout: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (routeContext) => AboutScreen(
                    version: appVersion,
                    onBack: () => Navigator.of(routeContext).pop(),
                  ),
                ),
              ),
              onPrivacyPolicy: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (routeContext) => PrivacyPolicyScreen(
                    onBack: () => Navigator.of(routeContext).pop(),
                  ),
                ),
              ),
              onToggleAppLock: (requested) => toggleAppLock(
                context,
                SetAppLockEnabled(authenticator, lockConfiguration),
                screenContext.read<SettingsCubit>(),
                enabled: requested,
              ),
              onStorageLocation: supportsCloudStorage
                  ? () => context.push(AppRoutes.storageLocation)
                  : null,
            );
          },
        ),
      );

  return SettingsScreens(
    settings: (context) => settingsScreen(context, isTab: false),
    settingsTab: (context) => settingsScreen(context, isTab: true),
    about: (_) => const PlaceholderScreen('About'),
    privacy: (_) => const PlaceholderScreen('Privacy policy'),
  );
}

/// Turns the application lock on or off, confirming who is asking.
///
/// Authentication happens inside [setEnabled], in **both** directions:
/// requiring it only to enable would let anyone holding an unlocked phone
/// switch the lock off, which is exactly the situation the lock exists for.
///
/// Re-reads [settings] on success so the switch reflects what is actually
/// stored rather than what was asked for, and reports any refusal or failure
/// where the user can see it.
Future<void> toggleAppLock(
  BuildContext context,
  SetAppLockEnabled setEnabled,
  SettingsCubit settings, {
  required bool enabled,
}) async {
  final result = await setEnabled(enabled: enabled);
  if (!context.mounted) return;

  switch (result) {
    case Success(:final value):
      if (value == AuthOutcome.succeeded) {
        // Re-read so the switch reflects what is actually stored rather than
        // what was asked for.
        await settings.load();
      } else {
        final message = AppLockRules.messageFor(value);
        if (message != null && context.mounted) report(context, message);
      }
    case Failed(:final failure):
      report(context, failure.presentation.message);
  }
}
