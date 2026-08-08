/// Cubit tests for the settings screen.
library;

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/app_settings/application/usecases/settings_usecases.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/infrastructure/repositories/preference_settings_repository.dart';
import 'package:doc_scanly/features/app_settings/presentation/cubit/settings_cubit.dart';
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

/// A controllable storage read used to observe the in-progress state.
class _DelayedStorage implements StorageSummaryReader {
  final result = Completer<Result<StorageSummary>>();

  @override
  Future<Result<StorageSummary>> summary() => result.future;
}

void main() {
  late List<AppThemeChoice> published;

  setUp(() => published = []);

  SettingsCubit build({
    PreferenceStore? store,
    _Storage? storage,
    AppLockStatusReader? lock,
    CameraResolutionLoader? loadCameraResolutions,
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
      loadCameraResolutions: loadCameraResolutions,
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
        await cubit.setPdfQuality(PdfQualityPercent(value: 100));
      },
      verify: (cubit) => expect(
        cubit.state.settings.pdfQuality,
        PdfQualityPercent(value: 100),
      ),
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
        await cubit.setCameraResolution(
          DesiredCameraResolution.tier(CameraResolutionTier.ultraHd4k),
        );
      },
      verify: (cubit) {
        expect(cubit.state.status, SettingsStatus.failure);
        expect(
          cubit.state.settings.cameraResolution,
          const DesiredCameraResolution.fullResolution(),
        );
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

  group('camera resolution', () {
    final hd = SupportedCameraResolution(
      tier: CameraResolutionTier.hd720,
      width: 1280,
      height: 720,
    );

    blocTest<SettingsCubit, SettingsState>(
      'publishes loading and supported capability states',
      build: () => build(
        loadCameraResolutions: () async =>
            Result<List<SupportedCameraResolution>>.success([hd]),
      ),
      act: (cubit) => cubit.loadCameraResolutionOptions(),
      expect: () => [
        isA<SettingsState>().having(
          (state) => state.cameraResolutionStatus,
          'cameraResolutionStatus',
          CameraResolutionStatus.loading,
        ),
        isA<SettingsState>()
            .having(
              (state) => state.cameraResolutionStatus,
              'cameraResolutionStatus',
              CameraResolutionStatus.supported,
            )
            .having(
              (state) => state.supportedCameraResolutions,
              'supportedCameraResolutions',
              [hd],
            ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'Retry replaces a capability failure with supported choices',
      build: () {
        var calls = 0;
        return build(
          loadCameraResolutions: () async => calls++ == 0
              ? const Result<List<SupportedCameraResolution>>.failure(
                  Failure.camera(),
                )
              : Result<List<SupportedCameraResolution>>.success([hd]),
        );
      },
      act: (cubit) async {
        await cubit.loadCameraResolutionOptions();
        await cubit.loadCameraResolutionOptions();
      },
      verify: (cubit) {
        expect(
          cubit.state.cameraResolutionStatus,
          CameraResolutionStatus.supported,
        );
        expect(cubit.state.cameraResolutionFailure, isNull);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'camera fallback is deterministic while PDF default is preserved',
      build: () => build(
        store: InMemoryPreferenceStore({
          PreferenceKeys.cameraResolution: '4k',
          PreferenceKeys.pdfQualityPercent: 60,
        }),
        loadCameraResolutions: () async =>
            Result<List<SupportedCameraResolution>>.success([hd]),
      ),
      act: (cubit) async {
        await cubit.load();
        await cubit.loadCameraResolutionOptions();
      },
      verify: (cubit) {
        expect(
          cubit.state.settings.cameraResolution.resolve(
            cubit.state.supportedCameraResolutions,
          ),
          hd,
        );
        expect(cubit.state.settings.pdfQuality, PdfQualityPercent(value: 60));
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

    test('refresh exposes progress until the new summary arrives', () async {
      final storage = _DelayedStorage();
      final repository = PreferenceSettingsRepository(
        InMemoryPreferenceStore(),
      );
      final controlled = SettingsCubit(
        LoadSettings(repository),
        UpdateSetting(repository),
        PreviewDocumentName(FixedClock(DateTime.utc(2026, 3, 14))),
        LoadStorageSummary(storage),
        onThemeChanged: published.add,
      );
      addTearDown(controlled.close);

      final refresh = controlled.refreshStorage();
      expect(controlled.state.isRefreshingStorage, isTrue);

      storage.result.complete(
        const Result<StorageSummary>.success(
          StorageSummary(totalBytes: 1024, documentCount: 1),
        ),
      );
      await refresh;

      expect(controlled.state.isRefreshingStorage, isFalse);
      expect(controlled.state.storage?.documentCount, 1);
    });

    blocTest<SettingsCubit, SettingsState>(
      'records a refresh failure and stops progress',
      build: () => build(storage: _Storage(failure: const Failure.storage())),
      act: (cubit) => cubit.refreshStorage(),
      verify: (cubit) {
        expect(cubit.state.isRefreshingStorage, isFalse);
        expect(cubit.state.storageFailure, isA<StorageFailure>());
      },
    );

    test('refresh after close is safely ignored', () async {
      final cubit = build();
      await cubit.close();

      await expectLater(cubit.refreshStorage(), completes);
    });
  });

  group('dismissError', () {
    blocTest<SettingsCubit, SettingsState>(
      'returns to the settings list',
      build: () => build(store: _FailingStore()),
      act: (cubit) async {
        await cubit.load();
        await cubit.setPdfQuality(PdfQualityPercent(value: 100));
        cubit.dismissError();
      },
      verify: (cubit) {
        expect(cubit.state.status, SettingsStatus.ready);
        expect(cubit.state.failure, isNull);
      },
    );
  });
}
