/// Widget keys for settings.
///
/// The values are normative — they come from `specs/app-settings/spec.md`.
library;

import 'package:flutter/widgets.dart';

/// Keys used by the settings screens.
abstract final class SettingsKeys {
  /// Root of the settings screen.
  static const screen = Key('settings_screen');

  /// The theme entry.
  static const theme = Key('settings_theme');

  /// The recognition-language entry.
  static const ocrLanguage = Key('settings_ocr_language');

  /// The PDF-quality entry.
  static const pdfQuality = Key('settings_pdf_quality');

  /// The image-quality entry.
  static const imageQuality = Key('settings_image_quality');

  /// The default-file-naming entry.
  static const fileNaming = Key('settings_file_naming');

  /// The default-save-location entry.
  static const saveLocation = Key('settings_save_location');

  /// The biometric-lock entry.
  static const biometricLock = Key('settings_biometric_lock');

  /// Explains that saved PDFs are visible to other applications.
  static const storageVisibility = Key('settings_storage_visibility');

  /// The storage-information entry.
  static const storageInfo = Key('settings_storage_info');

  /// The About entry.
  static const about = Key('settings_about');

  /// The Privacy Policy entry.
  static const privacyPolicy = Key('settings_privacy_policy');

  /// Root of the About screen.
  static const aboutScreen = Key('settings_about_screen');

  /// Root of the Privacy Policy screen.
  static const privacyScreen = Key('settings_privacy_screen');

  /// The view shown when a setting could not be saved.
  static const errorView = Key('settings_error_view');

  /// The control that retries a failed save.
  static const errorRetryButton = Key('settings_error_retry_button');

  /// The preview of the chosen naming pattern.
  static const namingPreview = Key('settings_naming_preview');
}
