/// The settings themselves, their defaults and what they mean.
///
/// Pure: no Flutter, no plugins, no storage. Every default is declared here
/// once, which is what makes "each setting shows a documented default value"
/// a property of one file rather than a claim spread across ten call sites.
library;

import 'package:doc_scanly/core/contracts/models/settings_values.dart';

// Re-exported so the rest of this feature has one import for "a setting's
// value". The types live in core/contracts because the features that *act* on
// them may not import settings, and settings may not import them.
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

/// The quality preset applied to page images.
///
/// Separate from [PdfQuality] because the two are genuinely different
/// decisions: image quality governs what is *stored* per page, and PDF quality
/// governs what is put in the document that is shared. Someone who scans at
/// high fidelity may still want small PDFs to email.
enum ImageQuality {
  /// Smallest files, adequate for text.
  low(quality: 60, maxDimension: 1600, label: 'Space saving'),

  /// The default: legible photographs of documents at a reasonable size.
  balanced(quality: 85, maxDimension: 2400, label: 'Balanced'),

  /// Closest to the original capture.
  high(quality: 95, maxDimension: 4000, label: 'Best quality');

  const ImageQuality({
    required this.quality,
    required this.maxDimension,
    required this.label,
  });

  /// JPEG quality, 0–100.
  final int quality;

  /// The longest edge, in pixels, a stored page is scaled to.
  final int maxDimension;

  /// How this preset is named to the user.
  final String label;

  /// The default before the user has chosen.
  static const defaultQuality = ImageQuality.balanced;

  /// The preset stored under [id], or the default when it is unrecognised.
  static ImageQuality fromName(String? id) => ImageQuality.values.firstWhere(
    (quality) => quality.name == id,
    orElse: () => defaultQuality,
  );
}

/// Every user-configurable setting, as one immutable value.
class AppSettings {
  /// Creates a settings snapshot.
  const AppSettings({
    this.theme = AppThemeChoice.system,
    this.ocrScript = OcrScript.defaultScript,
    this.pdfQuality = PdfQuality.defaultQuality,
    this.imageQuality = ImageQuality.defaultQuality,
    this.namingPattern = NamingPattern.defaultPattern,
    this.saveLocation,
    this.isAppLockEnabled = false,
  });

  /// How the theme is chosen. Defaults to following the system.
  final AppThemeChoice theme;

  /// The script used for text recognition. Defaults to Latin.
  final OcrScript ocrScript;

  /// The quality preset used when generating a PDF. Defaults to balanced.
  final PdfQuality pdfQuality;

  /// The quality preset applied to page images. Defaults to balanced.
  final ImageQuality imageQuality;

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
  static const defaults = AppSettings();

  /// Returns a copy with the given fields replaced.
  ///
  /// [clearSaveLocation] resets the save location to the system default, which
  /// a null [saveLocation] cannot express.
  AppSettings copyWith({
    AppThemeChoice? theme,
    OcrScript? ocrScript,
    PdfQuality? pdfQuality,
    ImageQuality? imageQuality,
    NamingPattern? namingPattern,
    String? saveLocation,
    bool clearSaveLocation = false,
    bool? isAppLockEnabled,
  }) => AppSettings(
    theme: theme ?? this.theme,
    ocrScript: ocrScript ?? this.ocrScript,
    pdfQuality: pdfQuality ?? this.pdfQuality,
    imageQuality: imageQuality ?? this.imageQuality,
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
          other.ocrScript == ocrScript &&
          other.pdfQuality == pdfQuality &&
          other.imageQuality == imageQuality &&
          other.namingPattern == namingPattern &&
          other.saveLocation == saveLocation &&
          other.isAppLockEnabled == isAppLockEnabled;

  @override
  int get hashCode => Object.hash(
    theme,
    ocrScript,
    pdfQuality,
    imageQuality,
    namingPattern,
    saveLocation,
    isAppLockEnabled,
  );
}

/// How each setting is described to the user.
abstract final class SettingsCopy {
  /// The trade-off a PDF quality preset makes.
  ///
  /// The spec requires the effect on file size and fidelity to be described:
  /// "Balanced" on its own tells the user nothing about what they are choosing.
  static String pdfQualityDescription(PdfQuality quality) => switch (quality) {
    PdfQuality.low =>
      'Smallest files. Text stays readable; photographs lose '
          'detail.',
    PdfQuality.balanced =>
      'A good compromise for most scans — readable text and '
          'recognisable photographs at a moderate file size.',
    PdfQuality.high =>
      'Closest to the original scan. Files can be several times larger.',
  };

  /// The trade-off an image quality preset makes.
  static String imageQualityDescription(ImageQuality quality) =>
      switch (quality) {
        ImageQuality.low =>
          'Uses the least space. Best for text-only documents.',
        ImageQuality.balanced =>
          'Keeps photographs legible while using moderate space.',
        ImageQuality.high =>
          'Retains the most detail. Uses noticeably more space per page.',
      };

  /// What recognising in [script] means for the user.
  static String ocrScriptDescription(OcrScript script) => script.bundled
      ? 'Included in the application; works offline immediately.'
      : 'Downloaded on first use, then works offline.';

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
      'Captured page images, search and recognised-text indexes, preferences '
      'and other database metadata remain local to each device. They are not '
      'synchronised through iCloud, so a new device rebuilds its document list '
      'from the PDFs it finds. Password-protected PDFs remain protected; you '
      'may need to enter their password again on a new device.\n\n'
      'DocScanly has no document-storage server and text recognition runs on '
      'the device. PDFs can also leave the selected library when you explicitly '
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
