/// The settings themselves, their defaults and what they mean.
///
/// Pure: no Flutter, no plugins, no storage. Every default is declared here
/// once, which is what makes "each setting shows a documented default value"
/// a property of one file rather than a claim spread across ten call sites.
library;

import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/contracts/models/settings_values.dart';

// Re-exported so the rest of this feature has one import for "a setting's
// value". The types live in core/contracts because the features that *act* on
// them may not import settings, and settings may not import them.
export 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
export 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
export 'package:doc_scanly/core/contracts/models/settings_values.dart';

/// How the application decides between the light and dark themes.
///
/// Mirrors Flutter's `ThemeMode` without importing it: the domain layer is pure
/// Dart, and the presentation layer maps between the two.
enum AppThemeChoice {
  /// Follow whatever the operating system is set to.
  system('Follow system'),

  /// Always light.
  light('Light'),

  /// Always dark.
  dark('Dark');

  const AppThemeChoice(this.label);

  /// How this choice is named to the user.
  final String label;

  /// The choice stored under [id], or the default when it is unrecognised.
  static AppThemeChoice fromId(String? id) => AppThemeChoice.values.firstWhere(
    (choice) => choice.name == id,
    orElse: () => AppThemeChoice.system,
  );
}

/// Every user-configurable setting, as one immutable value.
class AppSettings {
  /// Creates a settings snapshot.
  AppSettings({
    this.theme = AppThemeChoice.system,
    PdfQualityPercent? pdfQuality,
    this.cameraResolution = const DesiredCameraResolution.fullResolution(),
    this.namingPattern = NamingPattern.defaultPattern,
    this.saveLocation,
    this.isAppLockEnabled = false,
  }) : pdfQuality = pdfQuality ?? PdfQualityPercent.defaultValue;

  /// How the theme is chosen. Defaults to following the system.
  final AppThemeChoice theme;

  /// The default percentage for a newly opened Save PDF workflow.
  final PdfQualityPercent pdfQuality;

  /// Desired camera tier. Full resolution means the active-camera maximum.
  final DesiredCameraResolution cameraResolution;

  /// How a document with no entered title is named. Defaults to date and time.
  final NamingPattern namingPattern;

  /// The directory offered first when exporting. Null means the system default.
  final String? saveLocation;

  /// Whether the biometric application lock is enabled. Defaults to off.
  ///
  /// Held here so the settings screen can show it, but *written* through the
  /// security feature: the flag lives in secure storage, not in preferences,
  /// so it cannot be turned off by editing an unprotected file on a rooted
  /// device.
  final bool isAppLockEnabled;

  /// The defaults, before the user has changed anything.
  static final defaults = AppSettings();

  /// Returns a copy with the given fields replaced.
  ///
  /// [clearSaveLocation] resets the save location to the system default, which
  /// a null [saveLocation] cannot express.
  AppSettings copyWith({
    AppThemeChoice? theme,
    PdfQualityPercent? pdfQuality,
    DesiredCameraResolution? cameraResolution,
    NamingPattern? namingPattern,
    String? saveLocation,
    bool clearSaveLocation = false,
    bool? isAppLockEnabled,
  }) => AppSettings(
    theme: theme ?? this.theme,
    pdfQuality: pdfQuality ?? this.pdfQuality,
    cameraResolution: cameraResolution ?? this.cameraResolution,
    namingPattern: namingPattern ?? this.namingPattern,
    saveLocation: clearSaveLocation
        ? null
        : (saveLocation ?? this.saveLocation),
    isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          other.theme == theme &&
          other.pdfQuality == pdfQuality &&
          other.cameraResolution == cameraResolution &&
          other.namingPattern == namingPattern &&
          other.saveLocation == saveLocation &&
          other.isAppLockEnabled == isAppLockEnabled;

  @override
  int get hashCode => Object.hash(
    theme,
    pdfQuality,
    cameraResolution,
    namingPattern,
    saveLocation,
    isAppLockEnabled,
  );
}

/// How each setting is described to the user.
abstract final class SettingsCopy {
  /// Explains what a PDF quality percentage controls.
  ///
  /// The spec requires the effect on file size and fidelity to be described:
  /// "Balanced" on its own tells the user nothing about what they are choosing.
  static String pdfQualityDescription(PdfQualityPercent quality) =>
      '${quality.value}% scales each page’s width and height. '
      'The Save screen calculates the actual file size and can override this '
      'default for one document.';

  /// Explains that capture resolution precedes later PDF scaling.
  static String cameraResolutionDescription(DesiredCameraResolution desired) =>
      '${cameraResolutionLabel(desired)} controls source capture dimensions '
      'before cropping and PDF scaling. Only resolutions supported by the '
      'active camera are offered.';

  /// Friendly label for a desired camera resolution.
  static String cameraResolutionLabel(DesiredCameraResolution desired) =>
      desired.when(
        fullResolution: () => 'Full resolution',
        tier: (tier) => tier.label,
      );

  /// The statement the Privacy Policy screen makes.
  ///
  /// Held here rather than in the widget so the guarantee is one string that a
  /// test can assert on, and so changing it is a deliberate act rather than a
  /// copy edit in a widget tree.
  static const privacyStatement =
      'DocScanly stores PDFs in the DocScanly folder selected for your library. '
      'On Android this library is always on the device. On iOS you can keep it '
      'on the device or explicitly select DocScanly’s app-owned iCloud Drive '
      'container. Apple then transfers those PDFs between devices signed into '
      'the same iCloud account. DocScanly never silently switches an iCloud '
      'library to a separate local copy.\n\n'
      'Captured page images, search indexes, preferences '
      'and other database metadata remain local to each device. They are not '
      'synchronised through iCloud, so a new device rebuilds its document list '
      'from the PDFs it finds. Password-protected PDFs remain protected; you '
      'may need to enter their password again on a new device.\n\n'
      'DocScanly has no document-storage server. PDFs can leave the selected '
      'library when you explicitly '
      'share, export or print them. Files and other applications with storage '
      'access may be able to see PDFs in the user-visible DocScanly folder.';

  /// The label of the entry that opens the Privacy Policy.
  static const privacyTitle = 'Privacy Policy';

  /// The label of the entry that opens About.
  static const aboutTitle = 'About';

  /// The message shown when a setting could not be saved.
  static const writeFailureMessage =
      'That setting could not be saved. The previous value is still in effect.';

  /// How the save location is described when none has been chosen.
  static const systemSaveLocation = 'Ask each time';

  /// How storage usage is announced alongside the figure.
  static String storageSummaryLabel(String size, int documentCount) =>
      '$size used by $documentCount '
      '${documentCount == 1 ? 'document' : 'documents'}';
}
