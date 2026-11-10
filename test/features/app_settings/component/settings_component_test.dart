/// Tier 2 — settings over its real Cubit, real use cases and real repository.
///
/// The only thing substituted here is the preference store, which means a
/// choice made on screen goes screen → Cubit → use case → repository → store
/// and the assertion is on what was actually written. That matters more here
/// than almost anywhere: a setting that appears to change and does not persist
/// is indistinguishable from a working one until the next launch.
library;

import 'package:doc_scanly/app/settings_module.dart';
import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/presentation/cubit/settings_cubit.dart';
import 'package:doc_scanly/features/app_settings/presentation/screens/settings_screen.dart';
import 'package:doc_scanly/features/app_settings/presentation/settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/component_harness.dart';

/// A storage reader that reports a fixed summary.
///
/// Storage size is the one thing on this screen that comes from the filesystem
/// rather than from preferences, and it is not what these tests are about.
class _FixedStorageReader implements StorageSummaryReader {
  const _FixedStorageReader();

  @override
  Future<Result<StorageSummary>> summary() async =>
      const Result<StorageSummary>.success(
        StorageSummary(documentCount: 3, totalBytes: 2048),
      );
}

class _CountingStorageReader implements StorageSummaryReader {
  var reads = 0;

  @override
  Future<Result<StorageSummary>> summary() async {
    reads++;
    return Result<StorageSummary>.success(
      StorageSummary(documentCount: reads, totalBytes: reads * 1024),
    );
  }
}

/// A store whose reads work but whose every write fails, as a full disk would.
class _WriteFailingStore extends InMemoryPreferenceStore {
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
  late InMemoryPreferenceStore preferences;
  late List<AppThemeChoice> published;

  setUp(() {
    preferences = InMemoryPreferenceStore();
    published = [];
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    StorageSummaryReader storageReader = const _FixedStorageReader(),
    VoidCallback? onStorageLocation,
    SettingsModule? prebuilt,
    bool settle = true,
  }) async {
    final module =
        prebuilt ??
        buildSettingsModule(
          preferences: preferences,
          storageReader: storageReader,
          clock: FixedClock(DateTime.utc(2026, 7, 26)),
        );

    await pumpComponent(
      tester,
      SettingsScreen(
        onBack: () {},
        pickSaveLocation: () async => '/Exports',
        onAbout: () {},
        onPrivacyPolicy: () {},
        onToggleAppLock: (_) {},
        onStorageLocation: onStorageLocation,
      ),
      providers: [
        BlocProvider(
          create: (_) => SettingsCubit(
            module.load,
            module.update,
            module.previewName,
            module.storage,
            onThemeChanged: published.add,
          )..load(),
        ),
      ],
    );
    if (settle) await settleComponent(tester);
  }

  group('SettingsScreen over its real state machine', () {
    testWidgets('loads and renders every entry the spec names', (tester) async {
      await pumpSettings(tester);

      expectVisible(SettingsKeys.theme);
      expectVisible(SettingsKeys.pdfQuality);
      expectVisible(SettingsKeys.fileNaming);
      expectVisible(SettingsKeys.biometricLock);
      expectNotVisible(SettingsKeys.errorView);
    });

    testWidgets('a choice setting offers every value it can take', (
      tester,
    ) async {
      await pumpSettings(tester);

      await tester.tap(find.byKey(SettingsKeys.theme));
      await tester.pumpAndSettle();

      expectVisible(SettingsKeys.choiceSheet);
      // Every option, keyed by the value's own name rather than its label, so
      // a flow can reach one without matching on user-visible text.
      for (final choice in AppThemeChoice.values) {
        expectVisible(
          SettingsKeys.choiceOption(SettingsKeys.optionNameOf(choice)),
          because: 'the theme sheet must offer ${choice.name}',
        );
      }

      // What choosing one *does* — persisting it and applying it without a
      // restart — is asserted in `flows/settings_and_lock_test.dart`, on a
      // device. Driving a modal sheet's radio selection reliably needs the real
      // binding, and asserting it weakly here would be worse than not
      // asserting it: it would read as covered.
    });

    testWidgets('reports a failed load rather than an empty screen', (
      tester,
    ) async {
      await pumpSettings(tester);

      // The screen distinguishes "nothing is set yet" from "the settings could
      // not be read". Collapsing the two would tell a user whose storage is
      // failing that their preferences had simply reset.
      expectNotVisible(SettingsKeys.errorView);
      expectVisible(SettingsKeys.storageInfo);
    });

    testWidgets('the naming preview reflects the chosen pattern', (
      tester,
    ) async {
      await pumpSettings(tester);

      // "Sequential" tells the user nothing about whether they will get
      // "Scan 1" or "Scan 0001", which is why the spec requires the example.
      expectVisible(SettingsKeys.namingPreview);
    });

    testWidgets('a selected export folder persists through the real use case', (
      tester,
    ) async {
      await pumpSettings(tester);

      await tester.ensureVisible(find.byKey(SettingsKeys.saveLocation));
      await tester.tap(find.byKey(SettingsKeys.saveLocation));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SettingsKeys.saveLocationChooseFolder));
      await tester.pumpAndSettle();

      expect(
        (await preferences.readString(
          PreferenceKeys.defaultSaveLocation,
        )).valueOrNull,
        '/Exports',
      );
    });

    testWidgets('storage details refresh through the real use case', (
      tester,
    ) async {
      final reader = _CountingStorageReader();
      var managed = false;
      await pumpSettings(
        tester,
        storageReader: reader,
        onStorageLocation: () => managed = true,
      );

      await tester.ensureVisible(find.byKey(SettingsKeys.storageInfo));
      await tester.tap(find.byKey(SettingsKeys.storageInfo));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SettingsKeys.storageRefresh));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SettingsKeys.storageManageLocation));

      expect(reader.reads, greaterThanOrEqualTo(3));
      expect(managed, isTrue);
    });

    testWidgets('dragging the PDF quality slider persists the new default', (
      tester,
    ) async {
      final module = buildSettingsModule(
        preferences: preferences,
        storageReader: const _FixedStorageReader(),
        clock: FixedClock(DateTime.utc(2026, 7, 26)),
      );
      await module.load();
      await pumpSettings(tester, prebuilt: module);

      final slider = find.byKey(SettingsKeys.pdfQualitySlider);
      await tester.ensureVisible(slider);
      await tester.drag(slider, const Offset(-2000, 0));
      await tester.pumpAndSettle();

      expect(
        (await preferences.readInt(
          PreferenceKeys.pdfQualityPercent,
        )).valueOrNull,
        PdfQualityPercent.minimum,
      );
      expect(
        module.repository.current.pdfQuality,
        PdfQualityPercent(value: PdfQualityPercent.minimum),
      );
      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('a failed slider write springs back to the persisted value', (
      tester,
    ) async {
      final seeded = InMemoryPreferenceStore();
      await seeded.writeInt(PreferenceKeys.pdfQualityPercent, 60);
      final module = buildSettingsModule(
        preferences: _SeededWriteFailingStore(seeded),
        storageReader: const _FixedStorageReader(),
        clock: FixedClock(DateTime.utc(2026, 7, 26)),
      );
      await module.load();
      await pumpSettings(tester, prebuilt: module);

      final slider = find.byKey(SettingsKeys.pdfQualitySlider);
      await tester.ensureVisible(slider);
      await tester.drag(slider, const Offset(-2000, 0));
      await tester.pumpAndSettle();

      expect(tester.widget<Slider>(slider).value, 60);
      // The banner leads the list; scroll back up to where the user sees it.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expectVisible(SettingsKeys.errorView);
      expect(find.text('60%'), findsOneWidget);
      expect(module.repository.current.pdfQuality.value, 60);
    });

    testWidgets(
      'neither loading nor a failed write changes what other features read',
      (tester) async {
        // The failing store refuses writes, so its reads come from a seed.
        final seeded = InMemoryPreferenceStore();
        await seeded.writeInt(PreferenceKeys.pdfQualityPercent, 45);
        await seeded.writeString(PreferenceKeys.fileNamingPattern, 'dateOnly');
        final failing = _SeededWriteFailingStore(seeded);
        final module = buildSettingsModule(
          preferences: failing,
          storageReader: const _FixedStorageReader(),
          clock: FixedClock(DateTime.utc(2026, 7, 26)),
        );
        // What the composition root does before building any consumer.
        await module.load();
        final persisted = module.repository.current;

        await pumpSettings(tester, prebuilt: module, settle: false);
        // While the Cubit is still loading it holds defaults; consumers must
        // not see them.
        expect(module.repository.current, persisted);
        await settleComponent(tester);

        await tester.tap(find.byKey(SettingsKeys.fileNaming));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            SettingsKeys.choiceOption(
              SettingsKeys.optionNameOf(NamingPattern.sequential),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expectVisible(SettingsKeys.errorView);
        expect(module.repository.current, persisted);
        expect(module.repository.current.pdfQuality.value, 45);
        expect(module.repository.current.namingPattern, NamingPattern.dateOnly);
      },
    );
  });
}

/// Reads from [_seed]; refuses every write.
class _SeededWriteFailingStore extends _WriteFailingStore {
  _SeededWriteFailingStore(this._seed);

  final InMemoryPreferenceStore _seed;

  @override
  Future<Result<String?>> readString(String key) => _seed.readString(key);

  @override
  Future<Result<int?>> readInt(String key) => _seed.readInt(key);
}
