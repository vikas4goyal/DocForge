/// Widget tests for the settings screens.
library;

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/core/theme/theme_mode_controller.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/app_settings/application/usecases/settings_usecases.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/infrastructure/repositories/preference_settings_repository.dart';
import 'package:doc_scanly/features/app_settings/presentation/cubit/settings_cubit.dart';
import 'package:doc_scanly/features/app_settings/presentation/screens/settings_screen.dart';
import 'package:doc_scanly/features/app_settings/presentation/settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A storage reader answering with a fixed summary.
class _Storage implements StorageSummaryReader {
  const _Storage();

  @override
  Future<Result<StorageSummary>> summary() async =>
      const Result<StorageSummary>.success(
        StorageSummary(totalBytes: 2_097_152, documentCount: 8),
      );
}

void main() {
  Future<SettingsCubit> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    Size viewport = const Size(600, 1600),
    PreferenceStore? store,
    ThemeModeController? themeController,
    ValueChanged<bool>? onToggleAppLock,
    VoidCallback? onAbout,
    VoidCallback? onPrivacy,
    VoidCallback? onStorageLocation,
    Future<String?> Function()? pickSaveLocation,
    bool isTab = false,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = PreferenceSettingsRepository(
      store ?? InMemoryPreferenceStore(),
    );

    final cubit = SettingsCubit(
      LoadSettings(repository),
      UpdateSetting(repository),
      PreviewDocumentName(FixedClock(DateTime.utc(2026, 3, 14, 9, 5))),
      const LoadStorageSummary(_Storage()),
      onThemeChanged: (choice) => themeController?.select(switch (choice) {
        AppThemeChoice.system => ThemeMode.system,
        AppThemeChoice.light => ThemeMode.light,
        AppThemeChoice.dark => ThemeMode.dark,
      }),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController ?? ThemeModeController(),
        builder: (context, mode, _) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              platformBrightness: brightness,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: BlocProvider<SettingsCubit>.value(
            value: cubit,
            child: SettingsScreen(
              onBack: isTab ? null : () {},
              pickSaveLocation: pickSaveLocation ?? () async => null,
              onAbout: onAbout ?? () {},
              onPrivacyPolicy: onPrivacy ?? () {},
              onToggleAppLock: onToggleAppLock,
              onStorageLocation: onStorageLocation,
            ),
          ),
        ),
      ),
    );

    await cubit.load();
    await tester.pump();
    await tester.pump();

    return cubit;
  }

  group('composition', () {
    testWidgets('the settings tab has no meaningless back control', (
      tester,
    ) async {
      await pump(tester, isTab: true);

      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('a pushed settings screen retains its back control', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('shows every entry the spec names', (tester) async {
      await pump(tester);

      for (final key in [
        SettingsKeys.screen,
        SettingsKeys.theme,
        SettingsKeys.pdfQuality,
        SettingsKeys.imageQuality,
        SettingsKeys.fileNaming,
        SettingsKeys.saveLocation,
        SettingsKeys.biometricLock,
        SettingsKeys.storageInfo,
        SettingsKeys.about,
        SettingsKeys.privacyPolicy,
      ]) {
        expect(find.byKey(key), findsOneWidget, reason: '$key is missing');
      }
    });

    testWidgets('each setting shows its current value', (tester) async {
      await pump(tester);

      expect(find.text(AppThemeChoice.system.label), findsOneWidget);
      expect(find.text(SettingsCopy.systemSaveLocation), findsOneWidget);
    });

    testWidgets('Android composition has no iCloud storage entry', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byKey(SettingsKeys.storageLocation), findsNothing);
      expect(find.text('iCloud Drive'), findsNothing);
    });

    testWidgets('iOS composition exposes the storage entry', (tester) async {
      var opened = false;
      await pump(tester, onStorageLocation: () => opened = true);

      await tester.ensureVisible(find.byKey(SettingsKeys.storageLocation));
      await tester.tap(find.byKey(SettingsKeys.storageLocation));

      expect(opened, isTrue);
    });

    testWidgets('shows the naming preview', (tester) async {
      await pump(tester);

      expect(find.byKey(SettingsKeys.namingPreview), findsOneWidget);
      expect(find.textContaining('Example:'), findsOneWidget);
    });

    testWidgets('shows the storage figure and document count', (tester) async {
      await pump(tester);

      expect(find.textContaining('2.0 MB'), findsOneWidget);
      expect(find.textContaining('8 documents'), findsOneWidget);
    });

    testWidgets('keeps bottom space below Privacy Policy', (tester) async {
      await pump(tester);

      final list = tester.widget<ListView>(find.byType(ListView).first);
      final padding = list.padding! as EdgeInsets;
      expect(padding.bottom, greaterThanOrEqualTo(24));
    });
  });

  group('changing a setting', () {
    testWidgets('Ask each time can be opened and changed to a folder', (
      tester,
    ) async {
      final cubit = await pump(
        tester,
        pickSaveLocation: () async => '/Exports',
      );

      await tester.ensureVisible(find.byKey(SettingsKeys.saveLocation));
      await tester.tap(find.byKey(SettingsKeys.saveLocation));
      await tester.pumpAndSettle();

      expect(find.byKey(SettingsKeys.saveLocationScreen), findsOneWidget);
      expect(find.byKey(SettingsKeys.saveLocationAskEachTime), findsOneWidget);
      await tester.tap(find.byKey(SettingsKeys.saveLocationChooseFolder));
      await tester.pumpAndSettle();

      expect(cubit.state.settings.saveLocation, '/Exports');
    });

    testWidgets('cancelling the folder picker changes nothing', (tester) async {
      final cubit = await pump(tester, pickSaveLocation: () async => null);

      await tester.ensureVisible(find.byKey(SettingsKeys.saveLocation));
      await tester.tap(find.byKey(SettingsKeys.saveLocation));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SettingsKeys.saveLocationChooseFolder));
      await tester.pumpAndSettle();

      expect(cubit.state.settings.saveLocation, isNull);
      expect(find.byKey(SettingsKeys.saveLocationScreen), findsOneWidget);
    });

    testWidgets('storage opens visible details and iOS management', (
      tester,
    ) async {
      var managed = false;
      await pump(tester, onStorageLocation: () => managed = true);

      await tester.ensureVisible(find.byKey(SettingsKeys.storageInfo));
      await tester.tap(find.byKey(SettingsKeys.storageInfo));
      await tester.pumpAndSettle();

      expect(find.byKey(SettingsKeys.storageScreen), findsOneWidget);
      expect(find.textContaining('2.0 MB'), findsOneWidget);
      await tester.tap(find.byKey(SettingsKeys.storageManageLocation));
      expect(managed, isTrue);
    });

    testWidgets('Android storage details omit iCloud management', (
      tester,
    ) async {
      await pump(tester);

      await tester.ensureVisible(find.byKey(SettingsKeys.storageInfo));
      await tester.tap(find.byKey(SettingsKeys.storageInfo));
      await tester.pumpAndSettle();

      expect(find.byKey(SettingsKeys.storageScreen), findsOneWidget);
      expect(find.byKey(SettingsKeys.storageRefresh), findsOneWidget);
      expect(find.byKey(SettingsKeys.storageManageLocation), findsNothing);
    });

    testWidgets('choosing a PDF quality shows its trade-off first', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byKey(SettingsKeys.pdfQuality));
      await tester.pumpAndSettle();

      expect(
        find.text(SettingsCopy.pdfQualityDescription(PdfQuality.high)),
        findsOneWidget,
      );
    });

    testWidgets(
      'PDF quality remains scrollable without overflow at large text',
      (tester) async {
        await pump(tester, viewport: const Size(390, 600), textScale: 3);

        await tester.scrollUntilVisible(
          find.byKey(SettingsKeys.pdfQuality),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.drag(find.byType(ListView).first, const Offset(0, -180));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(SettingsKeys.pdfQuality));
        await tester.pumpAndSettle();

        expect(find.byKey(SettingsKeys.choiceSheet), findsOneWidget);
        expect(find.byType(Scrollable), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('choosing a value applies it', (tester) async {
      final cubit = await pump(tester);

      await tester.tap(find.byKey(SettingsKeys.pdfQuality));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PdfQuality.high.label));
      await tester.pumpAndSettle();

      expect(cubit.state.settings.pdfQuality, PdfQuality.high);
    });

    testWidgets('changing the theme re-renders immediately', (tester) async {
      // The requirement is "without a restart", so the assertion is that the
      // rendered theme changed within the same pumped tree.
      final controller = ThemeModeController();
      addTearDown(controller.dispose);

      await pump(tester, themeController: controller);

      final before = Theme.of(
        tester.element(find.byKey(SettingsKeys.screen)),
      ).brightness;

      await tester.tap(find.byKey(SettingsKeys.theme));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppThemeChoice.dark.label));
      await tester.pumpAndSettle();

      final after = Theme.of(
        tester.element(find.byKey(SettingsKeys.screen)),
      ).brightness;

      expect(before, Brightness.light);
      expect(after, Brightness.dark);
      expect(controller.value, ThemeMode.dark);
    });
  });

  group('app lock', () {
    testWidgets('toggling reports the requested state to the caller', (
      tester,
    ) async {
      // Handled outside settings: enabling the lock requires authentication
      // first, and the flag lives in secure storage.
      final requested = <bool>[];
      await pump(tester, onToggleAppLock: requested.add);

      await tester.ensureVisible(find.byKey(SettingsKeys.biometricLock));
      await tester.tap(find.byKey(SettingsKeys.biometricLock));
      await tester.pumpAndSettle();

      expect(requested, [true]);
    });

    testWidgets('is disabled when no handler is supplied', (tester) async {
      await pump(tester);

      final tile = tester.widget<SwitchListTile>(
        find.descendant(
          of: find.byKey(SettingsKeys.biometricLock),
          matching: find.byType(SwitchListTile),
        ),
      );

      expect(tile.onChanged, isNull);
    });
  });

  group('About and Privacy Policy', () {
    testWidgets('the entries open their screens', (tester) async {
      var about = 0;
      var privacy = 0;
      await pump(tester, onAbout: () => about++, onPrivacy: () => privacy++);

      await tester.ensureVisible(find.byKey(SettingsKeys.about));
      await tester.tap(find.byKey(SettingsKeys.about));
      await tester.pump();
      await tester.ensureVisible(find.byKey(SettingsKeys.privacyPolicy));
      await tester.tap(find.byKey(SettingsKeys.privacyPolicy));
      await tester.pump();

      expect(about, 1);
      expect(privacy, 1);
    });

    testWidgets('About shows the application name and version', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AboutScreen(version: '1.0.0', onBack: () {}),
        ),
      );

      expect(find.byKey(SettingsKeys.aboutScreen), findsOneWidget);
      expect(find.text('DocScanly'), findsOneWidget);
      expect(find.textContaining('1.0.0'), findsOneWidget);
    });

    testWidgets(
      'the Privacy Policy distinguishes Android and optional iCloud',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: PrivacyPolicyScreen(onBack: () {}),
          ),
        );

        expect(find.byKey(SettingsKeys.privacyScreen), findsOneWidget);
        expect(find.textContaining('On Android'), findsOneWidget);
        expect(find.textContaining('app-owned iCloud Drive'), findsOneWidget);
        expect(find.textContaining('metadata remain local'), findsOneWidget);
      },
    );
  });

  group('accessibility', () {
    testWidgets('each entry announces its name and current value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      expect(
        find.bySemanticsLabel('Theme, ${AppThemeChoice.system.label}'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('PDF quality, ${PdfQuality.balanced.label}'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('App lock, off'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('every control meets the minimum touch target', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('passes the contrast guideline in dark mode', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = ThemeModeController(ThemeMode.dark);
      addTearDown(controller.dispose);

      await pump(tester, themeController: controller);

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });

    testWidgets('survives a tablet viewport at double text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repository = PreferenceSettingsRepository(
        InMemoryPreferenceStore(),
      );
      final cubit = SettingsCubit(
        LoadSettings(repository),
        UpdateSetting(repository),
        PreviewDocumentName(FixedClock(DateTime.utc(2026, 3, 14))),
        const LoadStorageSummary(_Storage()),
        onThemeChanged: (_) {},
      );
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child!,
          ),
          home: BlocProvider<SettingsCubit>.value(
            value: cubit,
            child: SettingsScreen(
              onBack: () {},
              pickSaveLocation: () async => null,
              onAbout: () {},
              onPrivacyPolicy: () {},
            ),
          ),
        ),
      );
      await cubit.load();
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
