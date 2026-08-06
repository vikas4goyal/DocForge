/// The settings screen and the two screens it opens.
library;

import 'package:doc_scanly/core/formatting/display_formatting.dart';
import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/presentation/cubit/settings_cubit.dart';
import 'package:doc_scanly/features/app_settings/presentation/screens/settings_detail_screens.dart';
import 'package:doc_scanly/features/app_settings/presentation/settings_keys.dart';
import 'package:doc_scanly/features/app_settings/presentation/widgets/settings_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Every user-configurable setting.
///
/// Keys: [SettingsKeys.screen] on the root and one key per entry. The keys are
/// normative and come from `specs/app-settings/spec.md`.
class SettingsScreen extends StatelessWidget {
  /// Creates the settings screen.
  const SettingsScreen({
    required this.onAbout,
    required this.onPrivacyPolicy,
    required this.pickSaveLocation,
    super.key,
    this.onBack,
    this.onToggleAppLock,
    this.onStorageLocation,
  });

  /// Invoked when the user leaves settings.
  final VoidCallback? onBack;

  /// Opens the platform directory picker used by export defaults.
  final DirectoryPicker pickSaveLocation;

  /// Invoked when the About entry is chosen.
  final VoidCallback onAbout;

  /// Invoked when the Privacy Policy entry is chosen.
  final VoidCallback onPrivacyPolicy;

  /// Invoked with the requested state when the app lock is toggled.
  ///
  /// Handled outside settings because enabling or disabling the lock requires
  /// authentication first, which is the security feature's business — and the
  /// flag lives in secure storage, not in preferences.
  final ValueChanged<bool>? onToggleAppLock;

  /// Opens iOS storage selection; null keeps cloud UI absent on Android.
  final VoidCallback? onStorageLocation;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();

        return Scaffold(
          key: SettingsKeys.screen,
          appBar: AppBar(
            title: const Text('Settings'),
            // A tab switch creates no route history, so automatic leading
            // controls are deliberately suppressed unless composition gives
            // this pushed instance a real back action.
            automaticallyImplyLeading: false,
            leading: onBack == null ? null : BackButton(onPressed: onBack),
          ),
          body: state.status == SettingsStatus.loading
              ? const AppLoadingIndicator()
              : ResponsiveLayout(
                  compact: (context) => _entries(context, cubit, state),
                  // Centred and width-limited rather than two-column: a list of
                  // settings stretched across a tablet leaves the value so far
                  // from its label that they stop reading as a pair.
                  expanded: (context) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _entries(context, cubit, state),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _entries(
    BuildContext context,
    SettingsCubit cubit,
    SettingsState state,
  ) {
    final settings = state.settings;

    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        if (state.status == SettingsStatus.failure)
          _SaveFailure(state: state, onDismiss: cubit.dismissError),
        SettingsChoiceTile<AppThemeChoice>(
          key: SettingsKeys.theme,
          title: 'Theme',
          value: settings.theme,
          valueLabel: settings.theme.label,
          options: AppThemeChoice.values,
          labelFor: (choice) => choice.label,
          onSelected: cubit.setTheme,
        ),
        SettingsChoiceTile<PdfQuality>(
          key: SettingsKeys.pdfQuality,
          title: 'PDF quality',
          value: settings.pdfQuality,
          valueLabel: settings.pdfQuality.label,
          options: PdfQuality.values,
          labelFor: (quality) => quality.label,
          // The spec requires the effect on size and fidelity to be described;
          // a preset name alone does not say what is being traded.
          descriptionFor: SettingsCopy.pdfQualityDescription,
          onSelected: cubit.setPdfQuality,
        ),
        SettingsChoiceTile<ImageQuality>(
          key: SettingsKeys.imageQuality,
          title: 'Image quality',
          value: settings.imageQuality,
          valueLabel: settings.imageQuality.label,
          options: ImageQuality.values,
          labelFor: (quality) => quality.label,
          descriptionFor: SettingsCopy.imageQualityDescription,
          onSelected: cubit.setImageQuality,
        ),
        SettingsChoiceTile<NamingPattern>(
          key: SettingsKeys.fileNaming,
          title: 'Default file naming',
          value: settings.namingPattern,
          valueLabel: settings.namingPattern.label,
          options: NamingPattern.values,
          labelFor: (pattern) => pattern.label,
          onSelected: cubit.setNamingPattern,
          footer: state.namingPreview.isEmpty
              ? null
              : NamingPatternPreview(example: state.namingPreview),
        ),
        SettingsValueTile(
          key: SettingsKeys.saveLocation,
          title: 'Default save location',
          value: state.saveLocationLabel,
          onTap: () => Navigator.of(context).push<void>(
            SettingsDetailRoutes.saveLocation(
              currentPath: settings.saveLocation,
              pickDirectory: pickSaveLocation,
              onSelected: cubit.setSaveLocation,
            ),
          ),
        ),
        SettingsSwitchTile(
          key: SettingsKeys.biometricLock,
          title: 'App lock',
          value: settings.isAppLockEnabled,
          subtitle: 'Require authentication to open DocScanly',
          onChanged: onToggleAppLock,
        ),
        SettingsValueTile(
          key: SettingsKeys.storageInfo,
          title: 'Storage',
          value: state.storage == null
              ? '—'
              : SettingsCopy.storageSummaryLabel(
                  DisplayFormatting.fileSize(state.storage!.totalBytes),
                  state.storage!.documentCount,
                ),
          onTap: () => Navigator.of(context).push<void>(
            SettingsDetailRoutes.storage(
              settings: cubit,
              onManageLocation: onStorageLocation,
            ),
          ),
        ),
        if (onStorageLocation != null)
          SettingsValueTile(
            key: SettingsKeys.storageLocation,
            title: 'Storage location',
            value: 'On this device or iCloud Drive',
            onTap: onStorageLocation,
          ),
        // Stated plainly rather than left to be discovered. Saved PDFs are
        // deliberately visible to other applications — that is what makes them
        // reachable from the Files app — and a user who assumes otherwise has
        // assumed something about their own documents that is not true.
        const ListTile(
          key: SettingsKeys.storageVisibility,
          leading: Icon(Icons.folder_shared_outlined),
          title: Text('Where your PDFs are kept'),
          subtitle: Text(
            'Saved PDFs live in a DocScanly folder other apps can see, so you '
            'can open them from Files and share them anywhere. '
            'Password-protected PDFs cannot be read without their password. '
            'Page images you capture stay private and are deleted once the '
            'PDF is made.',
          ),
          isThreeLine: true,
        ),
        const Divider(),
        SettingsValueTile(
          key: SettingsKeys.about,
          title: SettingsCopy.aboutTitle,
          value: '',
          onTap: onAbout,
        ),
        SettingsValueTile(
          key: SettingsKeys.privacyPolicy,
          title: SettingsCopy.privacyTitle,
          value: '',
          onTap: onPrivacyPolicy,
        ),
      ],
    );
  }
}

/// The banner shown when a setting could not be saved.
///
/// A banner rather than a full-screen error view: the rest of the settings are
/// still readable and changeable, and replacing the screen would hide them over
/// one failed write.
class _SaveFailure extends StatelessWidget {
  const _SaveFailure({required this.state, required this.onDismiss});

  final SettingsState state;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: SettingsKeys.errorView,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.message!,
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
          TextButton(
            key: SettingsKeys.errorRetryButton,
            onPressed: onDismiss,
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}

/// The About screen.
class AboutScreen extends StatelessWidget {
  /// Creates the About screen for [version].
  const AboutScreen({
    required this.version,
    required this.onBack,
    super.key,
    this.appName = 'DocScanly',
  });

  /// The application's version string.
  ///
  /// Passed in rather than read from the package info plugin here, so the
  /// screen renders identically in a preview, a golden and the app.
  final String version;

  /// Invoked when the user leaves the screen.
  final VoidCallback onBack;

  /// The application's name.
  final String appName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: SettingsKeys.aboutScreen,
      appBar: AppBar(
        title: const Text(SettingsCopy.aboutTitle),
        leading: BackButton(onPressed: onBack),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(appName, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Semantics(
            // Named together, so a screen reader announces "Version, 1.0.0"
            // rather than a bare number the user has to interpret.
            label: SettingsSemantics.version(version),
            excludeSemantics: true,
            child: Text('Version $version', style: theme.textTheme.bodyLarge),
          ),
          const SizedBox(height: 24),
          Text(
            'A private document scanner with device-local storage and optional '
            'iCloud Drive storage on iOS.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// The Privacy Policy screen.
///
/// Entirely local text. The spec requires it to be readable with no network
/// connection, which a hosted policy behind a web view would not be.
class PrivacyPolicyScreen extends StatelessWidget {
  /// Creates the Privacy Policy screen.
  const PrivacyPolicyScreen({required this.onBack, super.key});

  /// Invoked when the user leaves the screen.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: SettingsKeys.privacyScreen,
      appBar: AppBar(
        title: const Text(SettingsCopy.privacyTitle),
        leading: BackButton(onPressed: onBack),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            SettingsCopy.privacyStatement,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
