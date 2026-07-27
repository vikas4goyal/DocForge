/// Cubit tests for the settings screen.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/app_settings/application/usecases/settings_usecases.dart';
import 'package:doc_forge/features/app_settings/domain/app_settings.dart';
import 'package:doc_forge/features/app_settings/infrastructure/repositories/preference_settings_repository.dart';
import 'package:doc_forge/features/app_settings/presentation/cubit/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// A preference store whose writes all fail.
class _FailingStore extends InMemoryPreferenceStore {
  @override
  Future<Result<void>> writeString(String key, String value) async =>
      const Result<void>.failure(Failure.storage());
}

/// A storage reader answering with a fixed summary, or a failure.
class _Storage implements StorageSummaryReader {
  _Storage({this.totalBytes = 2_097_152, this.documentCount = 8, this.failure});

  int totalBytes;
  int documentCount;
  final Failure? failure;

  @override
  Future<Result<StorageSummary>> summary() async {
    final configured = failure;
    return configured == null
        ? Result<StorageSummary>.success(
            StorageSummary(
              totalBytes: totalBytes,
              documentCount: documentCount,
            ),
          )
        : Result<StorageSummary>.failure(configured);
  }
}

void main() {
  late List<AppThemeChoice> published;

  setUp(() => published = []);

  SettingsCubit build({
    PreferenceStore? store,
    _Storage? storage,
    AppLockStatusReader? lock,
  }) {
    final repository = PreferenceSettingsRepository(
      store ?? InMemoryPreferenceStore(),
      isAppLockEnabled: lock,
    );

    return SettingsCubit(
      LoadSettings(repository),
      UpdateSetting(repository),
      PreviewDocumentName(FixedClock(DateTime.utc(2026, 3, 14, 9, 5))),
      LoadStorageSummary(storage ?? _Storage()),
      onThemeChanged: published.add,
    );
  }

  group('load', () {
    blocTest<SettingsCubit, SettingsState>(
      'shows defaults, then the storage summary',
      build: build,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.status, 'status', SettingsStatus.ready)
            .having((s) => s.settings, 'settings', AppSettings.defaults)
            .having((s) => s.namingPreview, 'namingPreview', isNotEmpty)
            // Storage is read after the screen is on, so it is absent here.
            .having((s) => s.storage, 'storage', isNull),
        isA<SettingsState>().having(
          (s) => s.storage?.documentCount,
          'documentCount',
          8,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'still shows settings when storage cannot be read',
      build: () => build(storage: _Storage(failure: const Failure.storage())),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        // One unreadable figure must not take the screen down with it.
        expect(cubit.state.status, SettingsStatus.ready);
        expect(cubit.state.storage, isNull);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'reflects an app lock that is already enabled',
      build: () => build(lock: () async => true),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.settings.isAppLockEnabled, isTrue),
    );
  });

  group('changing a setting', () {
    blocTest<SettingsCubit, SettingsState>(
      'applies and keeps the new value',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.setPdfQuality(PdfQuality.high);
      },
      verify: (cubit) =>
          expect(cubit.state.settings.pdfQuality, PdfQuality.high),
    );

    blocTest<SettingsCubit, SettingsState>(
      'publishes an accepted theme so the app re-renders',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.setTheme(AppThemeChoice.dark);
      },
      verify: (cubit) {
        expect(cubit.state.settings.theme, AppThemeChoice.dark);
        expect(published, [AppThemeChoice.dark]);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'publishes nothing when the theme could not be saved',
      build: () => build(store: _FailingStore()),
      act: (cubit) async {
        await cubit.load();
        await cubit.setTheme(AppThemeChoice.dark);
      },
      verify: (cubit) {
        // Applying a theme that did not persist would leave the app looking one
        // way now and another after a restart.
        expect(published, isEmpty);
        expect(cubit.state.settings.theme, AppThemeChoice.system);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'a failed write keeps the previous value and explains',
      build: () => build(store: _FailingStore()),
      act: (cubit) async {
        await cubit.load();
        await cubit.setImageQuality(ImageQuality.high);
      },
      verify: (cubit) {
        expect(cubit.state.status, SettingsStatus.failure);
        expect(cubit.state.settings.imageQuality, ImageQuality.balanced);
        expect(cubit.state.message, contains('previous value'));
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'changing the naming pattern refreshes its preview',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.setNamingPattern(NamingPattern.sequential);
      },
      verify: (cubit) => expect(cubit.state.namingPreview, startsWith('Scan ')),
    );

    blocTest<SettingsCubit, SettingsState>(
      'changing the recognition script leaves everything else alone',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.setOcrScript(OcrScript.chinese);
      },
      verify: (cubit) {
        expect(cubit.state.settings.ocrScript, OcrScript.chinese);
        // Nothing else moved — in particular, no recognised text was touched,
        // which is the requirement this guards.
        expect(cubit.state.settings.pdfQuality, PdfQuality.balanced);
        expect(cubit.state.settings.namingPattern, NamingPattern.dateAndTime);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'clearing the save location returns to asking each time',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.setSaveLocation('/Downloads');
        await cubit.setSaveLocation(null);
      },
      verify: (cubit) {
        expect(cubit.state.settings.saveLocation, isNull);
        expect(cubit.state.saveLocationLabel, SettingsCopy.systemSaveLocation);
      },
    );
  });

  group('storage', () {
    test('a re-read reflects documents that were removed', () async {
      // The figure has to fall after a permanent removal; a cached total would
      // keep reporting space that has been freed.
      final storage = _Storage(totalBytes: 4_194_304, documentCount: 10);
      final cubit = build(storage: storage);
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.storage!.documentCount, 10);

      storage
        ..totalBytes = 1_048_576
        ..documentCount = 3;
      await cubit.refreshStorage();

      expect(cubit.state.storage!.documentCount, 3);
      expect(cubit.state.storage!.totalBytes, 1_048_576);
    });
  });

  group('dismissError', () {
    blocTest<SettingsCubit, SettingsState>(
      'returns to the settings list',
      build: () => build(store: _FailingStore()),
      act: (cubit) async {
        await cubit.load();
        await cubit.setPdfQuality(PdfQuality.high);
        cubit.dismissError();
      },
      verify: (cubit) {
        expect(cubit.state.status, SettingsStatus.ready);
        expect(cubit.state.failure, isNull);
      },
    );
  });
}
