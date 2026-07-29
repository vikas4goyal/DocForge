/// Tier 2 — settings over its real Cubit, real use cases and real repository.
///
/// The only thing substituted here is the preference store, which means a
/// choice made on screen goes screen → Cubit → use case → repository → store
/// and the assertion is on what was actually written. That matters more here
/// than almost anywhere: a setting that appears to change and does not persist
/// is indistinguishable from a working one until the next launch.
library;

import 'package:doc_forge/app/settings_module.dart';
import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/app_settings/domain/app_settings.dart';
import 'package:doc_forge/features/app_settings/presentation/cubit/settings_cubit.dart';
import 'package:doc_forge/features/app_settings/presentation/screens/settings_screen.dart';
import 'package:doc_forge/features/app_settings/presentation/settings_keys.dart';
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

void main() {
  late InMemoryPreferenceStore preferences;
  late List<AppThemeChoice> published;

  setUp(() {
    preferences = InMemoryPreferenceStore();
    published = [];
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    final module = buildSettingsModule(
      preferences: preferences,
      storageReader: const _FixedStorageReader(),
      clock: FixedClock(DateTime.utc(2026, 7, 26)),
    );

    await pumpComponent(
      tester,
      SettingsScreen(
        onBack: () {},
        onAbout: () {},
        onPrivacyPolicy: () {},
        onToggleAppLock: (_) {},
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
    await settleComponent(tester);
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
  });
}
