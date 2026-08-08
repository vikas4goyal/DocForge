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

  /// The PDF-quality entry.
  static const pdfQuality = Key('settings_pdf_quality');

  /// The active-camera resolution entry.
  static const cameraResolution = Key('settings_camera_resolution');

  /// Root of the active-camera resolution screen.
  static const cameraResolutionScreen = Key(
    'settings_camera_resolution_screen',
  );

  /// Retries a failed active-camera capability query.
  static const cameraResolutionRetry = Key('settings_camera_resolution_retry');

  /// One supported camera-resolution choice.
  static Key cameraResolutionOption(String tier) =>
      Key('settings_camera_resolution_option_$tier');

  /// The default-file-naming entry.
  static const fileNaming = Key('settings_file_naming');

  /// The default-save-location entry.
  static const saveLocation = Key('settings_save_location');

  /// Root of the pushed default-save-location screen.
  static const saveLocationScreen = Key('settings_save_location_screen');

  /// Keeps the export destination prompt enabled for every export.
  static const saveLocationAskEachTime = Key(
    'settings_save_location_ask_each_time',
  );

  /// Opens the platform directory picker.
  static const saveLocationChooseFolder = Key(
    'settings_save_location_choose_folder',
  );

  /// The biometric-lock entry.
  static const biometricLock = Key('settings_biometric_lock');

  /// Explains that saved PDFs are visible to other applications.
  static const storageVisibility = Key('settings_storage_visibility');

  /// The storage-information entry.
  static const storageInfo = Key('settings_storage_info');

  /// Root of the pushed storage-details screen.
  static const storageScreen = Key('settings_storage_screen');

  /// Re-reads storage usage.
  static const storageRefresh = Key('settings_storage_refresh');

  /// Opens iOS library storage management from storage details.
  static const storageManageLocation = Key('settings_storage_manage_location');

  /// iOS-only storage-location entry.
  static const storageLocation = Key('settings_storage_location');

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

  /// The sheet a choice setting opens to offer its options.
  static const choiceSheet = Key('settings_choice_sheet');

  /// One option inside a choice setting's sheet.
  ///
  /// Identified by the value's own name rather than by its label or its
  /// position: the label is user-visible text that moves and localises, and the
  /// position changes whenever an option is added.
  static Key choiceOption(String optionName) =>
      Key('settings_choice_option_$optionName');

  /// The stable name of [option], for [choiceOption].
  ///
  /// Enum values stringify as `Type.value`; the value alone is what identifies
  /// the option, and it survives a sibling being added or the labels changing.
  static String optionNameOf(Object? option) =>
      option.toString().split('.').last;
}

/// Semantics labels for settings.
///
/// Every tile announces its **name and current value together**, which the
/// accessibility scenario requires: a screen reader that reads "Theme" and then
/// "Dark" as two separate items leaves the user to associate them, and in a
/// list of ten settings that is guesswork. Composing those two halves here
/// rather than in each widget is what keeps the pairing consistent.
abstract final class SettingsSemantics {
  /// Announces a choice setting as its name and its current value.
  static String choiceTile(String title, String valueLabel) =>
      '$title, $valueLabel';

  /// Announces the ask-each-time save option and its selection state.
  static String askEachTime({required bool selected}) =>
      'Ask each time${selected ? ', selected' : ''}';

  /// Announces the folder picker action.
  static const chooseFolder = 'Choose a folder';

  /// Announces the storage refresh action.
  static const refreshStorage = 'Refresh storage usage';

  /// Announces iOS storage-location management.
  static const manageStorageLocation = 'Manage storage location';

  /// Announces a switch setting as its name and whether it is on.
  static String switchTile(String title, {required bool on}) =>
      '$title, ${on ? 'on' : 'off'}';

  /// Announces the example the chosen naming pattern would produce.
  static String namingPreview(String example) => 'Example name, $example';

  /// Announces the application version on the About screen.
  static String version(String version) => 'Version, $version';
}
