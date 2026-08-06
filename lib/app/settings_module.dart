/// Constructs the settings object graph.
///
/// Everything here is infrastructure construction, which the composition root
/// is the only place allowed to do (`design.md` §5).
library;

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/app_settings/application/usecases/settings_usecases.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/domain/repositories/settings_repository.dart';
import 'package:doc_scanly/features/app_settings/infrastructure/repositories/preference_settings_repository.dart';
import 'package:flutter/material.dart';

/// Everything settings exposes to the rest of the application.
class SettingsModule {
  /// Creates the module over an already-built object graph.
  const SettingsModule({
    required this.repository,
    required this.load,
    required this.update,
    required this.previewName,
    required this.storage,
  });

  /// The repository, exposed so the composition root can read the settings that
  /// other features need — the naming pattern and the quality presets — without
  /// standing up a Cubit to do it.
  final SettingsRepository repository;

  /// Reads every setting.
  final LoadSettings load;

  /// Changes one setting.
  final UpdateSetting update;

  /// Produces an example of the chosen naming pattern.
  final PreviewDocumentName previewName;

  /// Reads how much storage the library occupies.
  final LoadStorageSummary storage;
}

/// Builds the settings module.
SettingsModule buildSettingsModule({
  required PreferenceStore preferences,
  required StorageSummaryReader storageReader,
  required Clock clock,
  AppLockStatusReader? isAppLockEnabled,
}) {
  final repository = PreferenceSettingsRepository(
    preferences,
    isAppLockEnabled: isAppLockEnabled,
  );

  return SettingsModule(
    repository: repository,
    load: LoadSettings(repository),
    update: UpdateSetting(repository),
    previewName: PreviewDocumentName(clock),
    storage: LoadStorageSummary(storageReader),
  );
}

/// Maps a stored theme choice onto the Flutter theme mode that renders it.
///
/// Lives here rather than in the domain layer, which is pure Dart and may not
/// import Flutter. Keeping the mapping in one place is what stops "dark" and
/// `ThemeMode.dark` drifting apart across the places that care.
ThemeMode themeModeFor(AppThemeChoice choice) => switch (choice) {
  AppThemeChoice.system => ThemeMode.system,
  AppThemeChoice.light => ThemeMode.light,
  AppThemeChoice.dark => ThemeMode.dark,
};
