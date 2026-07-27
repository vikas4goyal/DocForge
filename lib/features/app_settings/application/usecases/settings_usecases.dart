/// Use cases for reading and changing settings.
library;

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/app_settings/domain/app_settings.dart';
import 'package:doc_forge/features/app_settings/domain/repositories/settings_repository.dart';

/// Loads every setting.
class LoadSettings {
  /// Creates the use case.
  const LoadSettings(this._repository);

  final SettingsRepository _repository;

  /// Returns the current settings, or their documented defaults.
  Future<AppSettings> call() => _repository.load();
}

/// Changes one setting.
///
/// One use case with a method per setting rather than seven use cases: they
/// share the property that matters — *the previous value stays in effect when
/// the write fails* — and splitting them would give that rule seven places to
/// be got wrong.
class UpdateSetting {
  /// Creates the use case.
  const UpdateSetting(this._repository);

  final SettingsRepository _repository;

  /// Applies [theme], returning the settings that are now in effect.
  ///
  /// On failure the returned settings are [current], unchanged — which is what
  /// makes "the previous value remains in effect" true rather than a claim the
  /// UI makes on its own.
  Future<Result<AppSettings>> theme(
    AppSettings current,
    AppThemeChoice theme,
  ) => _apply(
    current,
    current.copyWith(theme: theme),
    () => _repository.saveTheme(theme),
  );

  /// Applies the recognition [script].
  ///
  /// Previously recognised text is untouched: nothing here reaches the OCR
  /// store, and recognition is only re-run when the user asks for it. That is
  /// the whole of the "existing documents are unaffected" requirement.
  Future<Result<AppSettings>> ocrScript(
    AppSettings current,
    OcrScript script,
  ) => _apply(
    current,
    current.copyWith(ocrScript: script),
    () => _repository.saveOcrScript(script),
  );

  /// Applies the PDF [quality].
  Future<Result<AppSettings>> pdfQuality(
    AppSettings current,
    PdfQuality quality,
  ) => _apply(
    current,
    current.copyWith(pdfQuality: quality),
    () => _repository.savePdfQuality(quality),
  );

  /// Applies the image [quality].
  Future<Result<AppSettings>> imageQuality(
    AppSettings current,
    ImageQuality quality,
  ) => _apply(
    current,
    current.copyWith(imageQuality: quality),
    () => _repository.saveImageQuality(quality),
  );

  /// Applies the naming [pattern].
  Future<Result<AppSettings>> namingPattern(
    AppSettings current,
    NamingPattern pattern,
  ) => _apply(
    current,
    current.copyWith(namingPattern: pattern),
    () => _repository.saveNamingPattern(pattern),
  );

  /// Applies the default save location, or clears it when [path] is null.
  Future<Result<AppSettings>> saveLocation(AppSettings current, String? path) =>
      _apply(
        current,
        current.copyWith(saveLocation: path, clearSaveLocation: path == null),
        () => _repository.saveSaveLocation(path),
      );

  /// Persists a change and reports what is now in effect.
  Future<Result<AppSettings>> _apply(
    AppSettings current,
    AppSettings next,
    Future<Result<void>> Function() write,
  ) async {
    final written = await write();

    return switch (written) {
      Success() => Result<AppSettings>.success(next),
      // Deliberately a failure carrying nothing: the caller keeps `current`,
      // and returning `next` on a failed write would show the user a value that
      // will not survive a restart.
      Failed(:final failure) => Result<AppSettings>.failure(failure),
    };
  }
}

/// Produces an example of what the chosen naming pattern yields.
///
/// The spec requires a preview when the pattern is edited: "Sequential" tells
/// the user nothing about whether they will get "Scan 1" or "Scan 0001".
class PreviewDocumentName {
  /// Creates the use case.
  const PreviewDocumentName(this._clock);

  final Clock _clock;

  /// Returns the name a document created now would be given under [pattern].
  ///
  /// [existingCount] is what the sequential pattern counts from; the preview
  /// uses a representative number rather than querying the library, because a
  /// preview that hits the database on every keystroke is a preview nobody
  /// wants.
  String call(NamingPattern pattern, {int existingCount = 3}) =>
      DocumentNaming.expand(
        pattern,
        now: _clock.now(),
        existingCount: existingCount,
      );
}

/// Reads how much storage the library occupies.
class LoadStorageSummary {
  /// Creates the use case.
  const LoadStorageSummary(this._reader);

  final StorageSummaryReader _reader;

  /// Returns the current summary.
  ///
  /// Read on demand rather than cached, which is what makes the figure fall
  /// after a permanent removal — a cached total would keep reporting space that
  /// has been freed.
  Future<Result<StorageSummary>> call() => _reader.summary();
}
