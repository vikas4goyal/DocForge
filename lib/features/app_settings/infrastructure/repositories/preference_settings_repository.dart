/// A [SettingsRepository] backed by SharedPreferences.
///
/// Every value is stored as a *string identifier* rather than an enum index.
/// An index is a promise that the enum's declaration order never changes, and
/// reordering an enum is the kind of edit nobody thinks of as a migration —
/// it would silently turn "high quality" into "small file" on every device
/// that had chosen it.
///
/// The app-lock flag is *not* here: it lives in secure storage, so it cannot be
/// turned off by editing an unprotected preferences file on a rooted device
/// (`design.md` §8). This repository reads it through an injected reader.
library;

import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/storage_keys.dart';
import 'package:doc_forge/features/app_settings/domain/app_settings.dart';
import 'package:doc_forge/features/app_settings/domain/repositories/settings_repository.dart';

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
    final script = await _preferences.readString(PreferenceKeys.ocrLanguage);
    final pdf = await _preferences.readString(PreferenceKeys.pdfQuality);
    final image = await _preferences.readString(PreferenceKeys.imageQuality);
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
      ocrScript: OcrScript.fromTag(script.valueOrNull),
      pdfQuality: PdfQuality.fromName(pdf.valueOrNull),
      imageQuality: ImageQuality.fromName(image.valueOrNull),
      namingPattern: NamingPattern.fromId(naming.valueOrNull),
      saveLocation: location.valueOrNull,
      isAppLockEnabled: lockEnabled,
    );
  }

  @override
  Future<Result<void>> saveTheme(AppThemeChoice theme) =>
      _preferences.writeString(PreferenceKeys.themeMode, theme.name);

  @override
  Future<Result<void>> saveOcrScript(OcrScript script) =>
      _preferences.writeString(PreferenceKeys.ocrLanguage, script.languageTag);

  @override
  Future<Result<void>> savePdfQuality(PdfQuality quality) =>
      _preferences.writeString(PreferenceKeys.pdfQuality, quality.name);

  @override
  Future<Result<void>> saveImageQuality(ImageQuality quality) =>
      _preferences.writeString(PreferenceKeys.imageQuality, quality.name);

  @override
  Future<Result<void>> saveNamingPattern(NamingPattern pattern) =>
      _preferences.writeString(PreferenceKeys.fileNamingPattern, pattern.id);

  @override
  Future<Result<void>> saveSaveLocation(String? path) => path == null
      ? _preferences.remove(PreferenceKeys.defaultSaveLocation)
      : _preferences.writeString(PreferenceKeys.defaultSaveLocation, path);
}
