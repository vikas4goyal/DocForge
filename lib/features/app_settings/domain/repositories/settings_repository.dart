/// The seam between settings and where they are stored.
library;

import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/app_settings/domain/app_settings.dart';

/// Reads and writes the user's settings.
///
/// Whole-object reads and field-level writes, deliberately. A read on launch
/// wants everything at once; a write is always one setting the user just
/// changed, and writing the whole object back would risk overwriting a value
/// another screen changed in between.
abstract interface class SettingsRepository {
  /// Returns every setting, falling back to the documented default for each.
  ///
  /// Never fails: a preference that cannot be read degrades to its default,
  /// because a settings screen that will not open is worse than one showing
  /// defaults. A *write* failure is surfaced, since that is the one the user
  /// needs to know about.
  Future<AppSettings> load();

  /// Stores the theme choice.
  Future<Result<void>> saveTheme(AppThemeChoice theme);

  /// Stores the recognition script.
  Future<Result<void>> saveOcrScript(OcrScript script);

  /// Stores the PDF quality preset.
  Future<Result<void>> savePdfQuality(PdfQuality quality);

  /// Stores the image quality preset.
  Future<Result<void>> saveImageQuality(ImageQuality quality);

  /// Stores the default naming pattern.
  Future<Result<void>> saveNamingPattern(NamingPattern pattern);

  /// Stores the default save location, or clears it when [path] is null.
  Future<Result<void>> saveSaveLocation(String? path);
}
