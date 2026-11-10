// Tier 1 — the settings read model other features consume.
//
// Proves `current` only ever reflects values that were loaded or successfully
// persisted, so a loading or failed Settings screen cannot reset what capture,
// Save PDF, naming or export use.
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/infrastructure/repositories/preference_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingStore extends InMemoryPreferenceStore {
  @override
  Future<Result<void>> writeString(String key, String value) async =>
      const Result<void>.failure(Failure.storage());

  @override
  Future<Result<void>> writeInt(String key, int value) async =>
      const Result<void>.failure(Failure.storage());

  @override
  Future<Result<void>> remove(String key) async =>
      const Result<void>.failure(Failure.storage());
}

void main() {
  test('load primes current with the persisted values', () async {
    final store = InMemoryPreferenceStore();
    await store.writeInt(PreferenceKeys.pdfQualityPercent, 45);
    await store.writeString(PreferenceKeys.fileNamingPattern, 'sequential');
    final repository = PreferenceSettingsRepository(store);

    await repository.load();

    expect(repository.current.pdfQuality, PdfQualityPercent(value: 45));
    expect(repository.current.namingPattern, NamingPattern.sequential);
  });

  test('current is never a defaults placeholder before load', () {
    final repository = PreferenceSettingsRepository(InMemoryPreferenceStore());

    expect(() => repository.current, throwsStateError);
  });

  test('a write before load publishes nothing and is read by load', () async {
    final store = InMemoryPreferenceStore();
    await store.writeString(PreferenceKeys.fileNamingPattern, 'dateOnly');
    final repository = PreferenceSettingsRepository(store);
    final emitted = <AppSettings>[];
    repository.changes.listen(emitted.add);

    await repository.savePdfQuality(PdfQualityPercent(value: 35));
    await pumpEventQueue();

    expect(emitted, isEmpty);
    final loaded = await repository.load();
    expect(loaded.pdfQuality, PdfQualityPercent(value: 35));
    expect(loaded.namingPattern, NamingPattern.dateOnly);
  });

  test('every successful write updates current and emits it', () async {
    final repository = PreferenceSettingsRepository(InMemoryPreferenceStore());
    await repository.load();
    final emitted = <AppSettings>[];
    repository.changes.listen(emitted.add);

    await repository.savePdfQuality(PdfQualityPercent(value: 55));
    await repository.saveNamingPattern(NamingPattern.sequential);
    await repository.saveCameraResolution(
      DesiredCameraResolution.tier(CameraResolutionTier.hd720),
    );
    await repository.saveSaveLocation('/storage/emulated/0/Download');
    await repository.saveTheme(AppThemeChoice.dark);
    await pumpEventQueue();

    final current = repository.current;
    expect(current.pdfQuality, PdfQualityPercent(value: 55));
    expect(current.namingPattern, NamingPattern.sequential);
    expect(
      current.cameraResolution,
      DesiredCameraResolution.tier(CameraResolutionTier.hd720),
    );
    expect(current.saveLocation, '/storage/emulated/0/Download');
    expect(current.theme, AppThemeChoice.dark);
    expect(emitted, hasLength(5));
    expect(emitted.last, current);

    await repository.saveSaveLocation(null);
    expect(repository.current.saveLocation, isNull);
  });

  test('a failed write leaves current unchanged and emits nothing', () async {
    final store = _FailingStore();
    final repository = PreferenceSettingsRepository(store);
    final loaded = await repository.load();
    final emitted = <AppSettings>[];
    repository.changes.listen(emitted.add, onError: (_) => fail('error'));

    final result = await repository.savePdfQuality(
      PdfQualityPercent(value: 30),
    );
    await repository.saveSaveLocation('/tmp/x');
    await pumpEventQueue();

    expect(result.isFailure, isTrue);
    expect(repository.current, loaded);
    expect(emitted, isEmpty);
  });
}
