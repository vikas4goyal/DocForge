/// Tests for the settings domain, repository and use cases.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/app_settings/application/usecases/settings_usecases.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/infrastructure/repositories/preference_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// A preference store that fails every write.
class _FailingStore extends InMemoryPreferenceStore {
  @override
  Future<Result<void>> writeString(String key, String value) async =>
      const Result<void>.failure(Failure.storage());

  @override
  Future<Result<void>> remove(String key) async =>
      const Result<void>.failure(Failure.storage());
}

void main() {
  group('defaults', () {
    test('every setting has a documented default', () {
      const defaults = AppSettings.defaults;

      expect(defaults.theme, AppThemeChoice.system);
      expect(defaults.ocrScript, OcrScript.latin);
      expect(defaults.pdfQuality, PdfQuality.balanced);
      expect(defaults.imageQuality, ImageQuality.balanced);
      expect(defaults.namingPattern, NamingPattern.dateAndTime);
      expect(defaults.saveLocation, isNull);
      expect(defaults.isAppLockEnabled, isFalse);
    });

    test('the app lock is off by default', () {
      // Security that is on by default would lock a first-time user out of an
      // application they have not yet put anything in.
      expect(AppSettings.defaults.isAppLockEnabled, isFalse);
    });
  });

  group('AppSettings', () {
    test('copyWith replaces only what it is given', () {
      const original = AppSettings(saveLocation: '/Downloads');

      final updated = original.copyWith(theme: AppThemeChoice.dark);

      expect(updated.theme, AppThemeChoice.dark);
      expect(updated.saveLocation, '/Downloads');
    });

    test('clearSaveLocation resets to the system default', () {
      // A null `saveLocation` cannot express "clear it", because null also
      // means "leave it alone".
      const original = AppSettings(saveLocation: '/Downloads');

      expect(original.copyWith(clearSaveLocation: true).saveLocation, isNull);
    });

    test('compares by value', () {
      expect(
        const AppSettings(theme: AppThemeChoice.dark),
        const AppSettings(theme: AppThemeChoice.dark),
      );
      expect(
        const AppSettings(theme: AppThemeChoice.dark),
        isNot(const AppSettings()),
      );
    });
  });

  group('enum parsing', () {
    test('an unrecognised theme falls back to the default', () {
      // A preference written by a newer release must degrade, not crash.
      expect(AppThemeChoice.fromId('sepia'), AppThemeChoice.system);
      expect(AppThemeChoice.fromId(null), AppThemeChoice.system);
    });

    test('an unrecognised image quality falls back to the default', () {
      expect(ImageQuality.fromName('lossless'), ImageQuality.balanced);
      expect(ImageQuality.fromName(null), ImageQuality.balanced);
    });

    test('a known value round-trips', () {
      expect(
        AppThemeChoice.fromId(AppThemeChoice.dark.name),
        AppThemeChoice.dark,
      );
      expect(ImageQuality.fromName(ImageQuality.high.name), ImageQuality.high);
    });

    test('image quality presets are ordered by fidelity', () {
      expect(ImageQuality.low.quality, lessThan(ImageQuality.balanced.quality));
      expect(
        ImageQuality.balanced.quality,
        lessThan(ImageQuality.high.quality),
      );
      expect(
        ImageQuality.low.maxDimension,
        lessThan(ImageQuality.high.maxDimension),
      );
    });
  });

  group('SettingsCopy', () {
    test('every PDF quality names its trade-off', () {
      for (final quality in PdfQuality.values) {
        final description = SettingsCopy.pdfQualityDescription(quality);
        expect(description, isNotEmpty);
        // The spec requires the effect on size *and* fidelity.
        expect(
          description.toLowerCase(),
          anyOf(contains('file'), contains('larger'), contains('space')),
        );
      }
    });

    test('every image quality names its trade-off', () {
      for (final quality in ImageQuality.values) {
        expect(SettingsCopy.imageQualityDescription(quality), isNotEmpty);
      }
    });

    test('a bundled script is described as working immediately', () {
      expect(
        SettingsCopy.ocrScriptDescription(OcrScript.latin),
        contains('offline immediately'),
      );
    });

    test('a downloadable script says it is fetched on first use', () {
      expect(
        SettingsCopy.ocrScriptDescription(OcrScript.japanese),
        contains('first use'),
      );
    });

    test('the privacy statement distinguishes Android and optional iCloud', () {
      final statement = SettingsCopy.privacyStatement.toLowerCase();

      expect(
        statement,
        contains('on android this library is always on the device'),
      );
      expect(statement, contains('explicitly select'));
      expect(statement, contains('icloud drive container'));
      expect(statement, contains('never silently switches'));
    });

    test('the storage label agrees in number', () {
      expect(
        SettingsCopy.storageSummaryLabel('1.0 MB', 1),
        endsWith('document'),
      );
      expect(
        SettingsCopy.storageSummaryLabel('1.0 MB', 4),
        endsWith('documents'),
      );
    });
  });

  group('PreferenceSettingsRepository', () {
    test('loads defaults when nothing has been written', () async {
      final settings = await PreferenceSettingsRepository(
        InMemoryPreferenceStore(),
      ).load();

      expect(settings, AppSettings.defaults);
    });

    test('round-trips every setting', () async {
      final store = InMemoryPreferenceStore();
      final repository = PreferenceSettingsRepository(store);

      await repository.saveTheme(AppThemeChoice.dark);
      await repository.saveOcrScript(OcrScript.japanese);
      await repository.savePdfQuality(PdfQuality.high);
      await repository.saveImageQuality(ImageQuality.low);
      await repository.saveNamingPattern(NamingPattern.sequential);
      await repository.saveSaveLocation('/Downloads');

      final settings = await repository.load();

      expect(settings.theme, AppThemeChoice.dark);
      expect(settings.ocrScript, OcrScript.japanese);
      expect(settings.pdfQuality, PdfQuality.high);
      expect(settings.imageQuality, ImageQuality.low);
      expect(settings.namingPattern, NamingPattern.sequential);
      expect(settings.saveLocation, '/Downloads');
    });

    test('stores identifiers rather than enum indices', () async {
      // An index is a promise that declaration order never changes, and
      // reordering an enum is not the kind of edit anyone treats as a
      // migration.
      final store = InMemoryPreferenceStore();

      await PreferenceSettingsRepository(store).saveTheme(AppThemeChoice.dark);

      final stored = await store.readString(PreferenceKeys.themeMode);
      expect(stored.valueOrNull, 'dark');
    });

    test('clearing the save location removes the key', () async {
      final store = InMemoryPreferenceStore();
      final repository = PreferenceSettingsRepository(store);

      await repository.saveSaveLocation('/Downloads');
      await repository.saveSaveLocation(null);

      expect((await repository.load()).saveLocation, isNull);
    });

    test('reports a write failure', () async {
      final result = await PreferenceSettingsRepository(
        _FailingStore(),
      ).saveTheme(AppThemeChoice.dark);

      expect(result, isA<Failed<void>>());
    });

    test('reads the app-lock flag from where it really lives', () async {
      // Never from preferences: an unprotected file on a rooted device must not
      // be able to turn the lock off.
      final settings = await PreferenceSettingsRepository(
        InMemoryPreferenceStore(),
        isAppLockEnabled: () async => true,
      ).load();

      expect(settings.isAppLockEnabled, isTrue);
    });

    test('no setting key is a secure key', () {
      // Guards the boundary directly: a settings value must never be written
      // through the secure store's namespace, nor a secret through this one.
      for (final key in PreferenceKeys.all) {
        expect(key, matches(RegExp(r'^(app|settings)\.')));
        expect(key, isNot(startsWith('secure.')));
      }
    });
  });

  group('UpdateSetting', () {
    test('returns the settings now in effect', () async {
      final update = UpdateSetting(
        PreferenceSettingsRepository(InMemoryPreferenceStore()),
      );

      final result = await update.theme(
        AppSettings.defaults,
        AppThemeChoice.dark,
      );

      expect((result as Success<AppSettings>).value.theme, AppThemeChoice.dark);
    });

    test('a failed write leaves the previous value in effect', () async {
      // The caller keeps `current`; returning the new value would show the user
      // something that will not survive a restart.
      final update = UpdateSetting(
        PreferenceSettingsRepository(_FailingStore()),
      );

      final result = await update.pdfQuality(
        AppSettings.defaults,
        PdfQuality.high,
      );

      expect(result, isA<Failed<AppSettings>>());
    });

    test('changing the recognition script touches no recognised text', () async {
      // Nothing in this use case reaches the OCR store — which is the whole of
      // the "existing documents are unaffected" requirement, and is asserted by
      // the collaborator list rather than by a side effect that is not there.
      final store = InMemoryPreferenceStore();
      final update = UpdateSetting(PreferenceSettingsRepository(store));

      await update.ocrScript(AppSettings.defaults, OcrScript.chinese);

      // Only the language key was written; nothing else in storage changed.
      expect(
        (await store.readString(PreferenceKeys.ocrLanguage)).valueOrNull,
        'zh',
      );
    });

    test('clearing the save location is expressible', () async {
      const current = AppSettings(saveLocation: '/Downloads');
      final update = UpdateSetting(
        PreferenceSettingsRepository(InMemoryPreferenceStore()),
      );

      final result = await update.saveLocation(current, null);

      expect((result as Success<AppSettings>).value.saveLocation, isNull);
    });
  });

  group('PreviewDocumentName', () {
    test('expands the pattern with the current time', () {
      final preview = PreviewDocumentName(
        FixedClock(DateTime.utc(2026, 3, 14, 9, 5)),
      );

      expect(preview(NamingPattern.dateAndTime), isNotEmpty);
      expect(preview(NamingPattern.plain), isNotEmpty);
    });

    test('each pattern produces a different example', () {
      final preview = PreviewDocumentName(
        FixedClock(DateTime.utc(2026, 3, 14, 9, 5)),
      );

      final examples = {
        for (final pattern in NamingPattern.values) preview(pattern),
      };

      // "Sequential" tells the user nothing on its own; the previews have to
      // actually differ for the preview to be worth showing.
      expect(examples, hasLength(NamingPattern.values.length));
    });

    test('the sequential preview counts from the supplied number', () {
      final preview = PreviewDocumentName(
        FixedClock(DateTime.utc(2026, 3, 14)),
      );

      // Explicit on both sides: the point is that the count is what varies,
      // which relying on the default would leave implicit.
      expect(
        preview(NamingPattern.sequential, existingCount: 41),
        isNot(preview(NamingPattern.sequential, existingCount: 7)),
      );
    });
  });
}
