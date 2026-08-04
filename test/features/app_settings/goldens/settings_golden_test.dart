/// Golden tests for the settings screens.
///
/// Tagged `golden` and run on one canonical configuration in CI: rendering the
/// same widget on two platforms produces font-antialiasing diffs that are noise
/// rather than regressions.
@Tags(['golden'])
library;

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/app_settings/application/usecases/settings_usecases.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/infrastructure/repositories/preference_settings_repository.dart';
import 'package:doc_scanly/features/app_settings/presentation/cubit/settings_cubit.dart';
import 'package:doc_scanly/features/app_settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone viewport, in logical pixels at a device pixel ratio of one.
const _phone = Size(390, 844);

/// A tablet viewport.
const _tablet = Size(1024, 1366);

class _Storage implements StorageSummaryReader {
  const _Storage();

  @override
  Future<Result<StorageSummary>> summary() async =>
      const Result<StorageSummary>.success(
        StorageSummary(totalBytes: 2_097_152, documentCount: 8),
      );
}

/// A Cubit frozen at a chosen state.
class _SeededCubit extends SettingsCubit {
  _SeededCubit(this._seeded)
    : super(
        LoadSettings(_repository),
        UpdateSetting(_repository),
        PreviewDocumentName(FixedClock(DateTime.utc(2026, 3, 14, 9, 5))),
        const LoadStorageSummary(_Storage()),
        onThemeChanged: _ignore,
      );

  static final _repository = PreferenceSettingsRepository(
    InMemoryPreferenceStore(),
  );

  static void _ignore(AppThemeChoice choice) {}

  final SettingsState _seeded;

  @override
  SettingsState get state => _seeded;
}

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    SettingsState state, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    // One logical pixel per physical pixel, so the golden's dimensions are the
    // viewport's rather than whatever the host machine reports.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = _SeededCubit(state);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<SettingsCubit>.value(
          value: cubit,
          child: SettingsScreen(
            onBack: () {},
            onAbout: () {},
            onPrivacyPolicy: () {},
            onToggleAppLock: (_) {},
          ),
        ),
      ),
    );

    // Bounded rather than `pumpAndSettle`: the loading state shows an
    // indefinite progress indicator, which never settles.
    await tester.pump();
    await tester.pump();
  }

  final ready = const SettingsState.initial().copyWith(
    status: SettingsStatus.ready,
    settings: AppSettings.defaults,
    storage: const StorageSummary(totalBytes: 2_097_152, documentCount: 8),
    namingPreview: 'Scan 2026-03-14 09.05',
  );

  group('settings goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpAt(tester, _phone, ready);

      await expectLater(
        find.byType(SettingsScreen),
        matchesGoldenFile('settings_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpAt(tester, _phone, ready, brightness: Brightness.dark);

      await expectLater(
        find.byType(SettingsScreen),
        matchesGoldenFile('settings_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpAt(tester, _tablet, ready);

      await expectLater(
        find.byType(SettingsScreen),
        matchesGoldenFile('settings_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpAt(tester, _tablet, ready, brightness: Brightness.dark);

      await expectLater(
        find.byType(SettingsScreen),
        matchesGoldenFile('settings_tablet_dark.png'),
      );
    });

    testWidgets('save failure, light', (tester) async {
      await pumpAt(
        tester,
        _phone,
        ready.copyWith(
          status: SettingsStatus.failure,
          failure: const Failure.storage(),
        ),
      );

      await expectLater(
        find.byType(SettingsScreen),
        matchesGoldenFile('settings_error_light.png'),
      );
    });
  });

  group('About and Privacy goldens', () {
    Future<void> pumpScreen(
      WidgetTester tester,
      Widget screen, {
      Brightness brightness = Brightness.light,
      Size size = _phone,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
          home: screen,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('About, phone light', (tester) async {
      await pumpScreen(tester, AboutScreen(version: '1.0.0', onBack: () {}));

      await expectLater(
        find.byType(AboutScreen),
        matchesGoldenFile('about_phone_light.png'),
      );
    });

    testWidgets('About, tablet dark', (tester) async {
      await pumpScreen(
        tester,
        AboutScreen(version: '1.0.0', onBack: () {}),
        brightness: Brightness.dark,
        size: _tablet,
      );

      await expectLater(
        find.byType(AboutScreen),
        matchesGoldenFile('about_tablet_dark.png'),
      );
    });

    testWidgets('Privacy, phone light', (tester) async {
      await pumpScreen(tester, PrivacyPolicyScreen(onBack: () {}));

      await expectLater(
        find.byType(PrivacyPolicyScreen),
        matchesGoldenFile('privacy_phone_light.png'),
      );
    });

    testWidgets('Privacy, tablet dark', (tester) async {
      await pumpScreen(
        tester,
        PrivacyPolicyScreen(onBack: () {}),
        brightness: Brightness.dark,
        size: _tablet,
      );

      await expectLater(
        find.byType(PrivacyPolicyScreen),
        matchesGoldenFile('privacy_tablet_dark.png'),
      );
    });
  });
}
