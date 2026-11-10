/// The seam between settings and where they are stored.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';

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

  /// Returns the last settings that were successfully loaded or persisted.
  ///
  /// This is the read model every other feature consumes through the
  /// composition root. It is never a loading placeholder and never reflects a
  /// write that failed, so a Settings screen that is still loading or showing
  /// an error cannot reset what capture, Save PDF, naming or export use.
  ///
  /// Purely in memory and offline; reading it performs no I/O.
  ///
  /// Throws a [StateError] when read before the first [load] completes — the
  /// composition root awaits [load] before building any consumer.
  AppSettings get current;

  /// Emits [current] after every successful write.
  ///
  /// A broadcast stream that never emits errors: a failed write emits
  /// nothing, because nothing other features use has changed.
  Stream<AppSettings> get changes;

  /// Stores the theme choice.
  Future<Result<void>> saveTheme(AppThemeChoice theme);

  /// Stores the default PDF quality percentage.
  Future<Result<void>> savePdfQuality(PdfQualityPercent quality);

  /// Stores the desired camera capture resolution.
  Future<Result<void>> saveCameraResolution(DesiredCameraResolution desired);

  /// Stores the default naming pattern.
  Future<Result<void>> saveNamingPattern(NamingPattern pattern);

  /// Stores the default save location, or clears it when [path] is null.
  Future<Result<void>> saveSaveLocation(String? path);
}
