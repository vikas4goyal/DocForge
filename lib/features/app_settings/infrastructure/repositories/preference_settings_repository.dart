/// A [SettingsRepository] backed by SharedPreferences.
///
/// Enumerated values are stored as stable string identifiers rather than enum
/// indices. PDF quality uses a versioned integer percentage.
/// An index is a promise that the enum's declaration order never changes, and
/// reordering an enum is the kind of edit nobody thinks of as a migration —
/// it would silently turn "high quality" into "small file" on every device
/// that had chosen it.
///
/// The app-lock flag is *not* here: it lives in secure storage, so it cannot be
/// turned off by editing an unprotected preferences file on a rooted device
/// (`design.md` §8). This repository reads it through an injected reader.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/domain/repositories/settings_repository.dart';

/// Reports whether the application lock is currently enabled.
///
/// A function rather than the whole security contract: settings needs exactly
/// one fact from it, and taking the narrower dependency keeps a test from
/// having to stand up an authentication stack it does not care about.
typedef AppLockStatusReader = Future<bool> Function();

/// Stores settings in SharedPreferences.
class PreferenceSettingsRepository implements SettingsRepository {
  /// Creates the repository over [_preferences].
  ///
  /// [isAppLockEnabled] reads the lock flag from wherever it really lives,
  /// which is secure storage. Defaults to reporting the lock as off, which is
  /// the correct answer before the security feature is wired in.
  const PreferenceSettingsRepository(
    this._preferences, {
    this.isAppLockEnabled,
  });

  final PreferenceStore _preferences;

  /// Reads the lock flag from wherever it really lives.
  ///
  /// Public because it is supplied by name at the composition root and there is
  /// nothing to hide about it; the value it reads is a boolean, not a secret.
  final AppLockStatusReader? isAppLockEnabled;

  @override
  Future<AppSettings> load() async {
    // Read individually rather than as one blob: each has its own documented
    // default, and one unreadable key must not take the others down with it.
    final theme = await _preferences.readString(PreferenceKeys.themeMode);
    final pdf = await _preferences.readInt(PreferenceKeys.pdfQualityPercent);
    final legacyPdf = await _preferences.readString(PreferenceKeys.pdfQuality);
    final image = await _preferences.readString(PreferenceKeys.imageQuality);
    final cameraResolution = await _preferences.readString(
      PreferenceKeys.cameraResolution,
    );
    final naming = await _preferences.readString(
      PreferenceKeys.fileNamingPattern,
    );
    final location = await _preferences.readString(
      PreferenceKeys.defaultSaveLocation,
    );

    final lockEnabled = await isAppLockEnabled?.call() ?? false;

    return AppSettings(
      // Every `from…` falls back to the default for an unrecognised value, so a
      // preference written by a newer release degrades rather than crashing.
      theme: AppThemeChoice.fromId(theme.valueOrNull),
      pdfQuality: _readPdfQuality(pdf.valueOrNull, legacyPdf.valueOrNull),
      cameraResolution: _readCameraResolution(
        cameraResolution.valueOrNull,
        image.valueOrNull,
      ),
      namingPattern: NamingPattern.fromId(naming.valueOrNull),
      saveLocation: location.valueOrNull,
      isAppLockEnabled: lockEnabled,
    );
  }

  @override
  Future<Result<void>> saveTheme(AppThemeChoice theme) =>
      _preferences.writeString(PreferenceKeys.themeMode, theme.name);

  @override
  Future<Result<void>> savePdfQuality(PdfQualityPercent quality) =>
      _preferences.writeInt(PreferenceKeys.pdfQualityPercent, quality.value);

  @override
  Future<Result<void>> saveCameraResolution(DesiredCameraResolution desired) =>
      _preferences.writeString(
        PreferenceKeys.cameraResolution,
        desired.when(fullResolution: () => 'full', tier: (tier) => tier.id),
      );

  @override
  Future<Result<void>> saveNamingPattern(NamingPattern pattern) =>
      _preferences.writeString(PreferenceKeys.fileNamingPattern, pattern.id);

  @override
  Future<Result<void>> saveSaveLocation(String? path) => path == null
      ? _preferences.remove(PreferenceKeys.defaultSaveLocation)
      : _preferences.writeString(PreferenceKeys.defaultSaveLocation, path);

  static PdfQualityPercent _readPdfQuality(
    int? percentage,
    String? legacyPreset,
  ) {
    if (percentage != null) {
      if (percentage >= PdfQualityPercent.minimum &&
          percentage <= PdfQualityPercent.maximum) {
        return PdfQualityPercent(value: percentage);
      }
      return PdfQualityPercent.defaultValue;
    }

    final migrated = switch (legacyPreset) {
      'low' => 40,
      'balanced' => 70,
      'high' => 100,
      _ => 70,
    };
    // Legacy names are intentionally mapped rather than parsed as the old
    // enum: these percentages are the stable migration contract.
    return PdfQualityPercent(value: migrated);
  }

  static DesiredCameraResolution _readCameraResolution(
    String? persisted,
    String? legacyImageQuality,
  ) {
    if (persisted == 'full') {
      return const DesiredCameraResolution.fullResolution();
    }
    final tier = CameraResolutionTier.fromId(persisted);
    if (tier != null) return DesiredCameraResolution.tier(tier);
    return DesiredCameraResolution.fromLegacyImageQuality(legacyImageQuality);
  }
}
