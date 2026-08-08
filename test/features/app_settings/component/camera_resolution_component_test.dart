import 'dart:async';

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
import 'package:doc_scanly/features/app_settings/presentation/screens/settings_screen.dart';
import 'package:doc_scanly/features/app_settings/presentation/settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _StorageSummary implements StorageSummaryReader {
  const _StorageSummary();

  @override
  Future<Result<StorageSummary>> summary() async =>
      const Result<StorageSummary>.success(
        StorageSummary(totalBytes: 0, documentCount: 0),
      );
}

class _CapabilityLoader {
  _CapabilityLoader(this.responses);

  final List<FutureOr<Result<List<SupportedCameraResolution>>>> responses;
  int calls = 0;

  Future<Result<List<SupportedCameraResolution>>> call() async =>
      responses[calls++];
}

void main() {
  final hd = SupportedCameraResolution(
    tier: CameraResolutionTier.hd720,
    width: 1280,
    height: 720,
  );
  final fullHd = SupportedCameraResolution(
    tier: CameraResolutionTier.fullHd1080,
    width: 1920,
    height: 1080,
  );

  Future<SettingsCubit> pumpScreen(
    WidgetTester tester, {
    required _CapabilityLoader loader,
    InMemoryPreferenceStore? store,
    double textScale = 1,
  }) async {
    final preferences = store ?? InMemoryPreferenceStore();
    final repository = PreferenceSettingsRepository(preferences);
    final cubit = SettingsCubit(
      LoadSettings(repository),
      UpdateSetting(repository),
      PreviewDocumentName(FixedClock(DateTime.utc(2026, 8, 8))),
      const LoadStorageSummary(_StorageSummary()),
      onThemeChanged: (_) {},
      loadCameraResolutions: loader.call,
    );
    await cubit.load();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: BlocProvider.value(
          value: cubit,
          child: SettingsScreen(
            pickSaveLocation: () async => null,
            onAbout: () {},
            onPrivacyPolicy: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(SettingsKeys.cameraResolution));
    await tester.pump();
    return cubit;
  }

  testWidgets('shows loading then only supported exact choices', (
    tester,
  ) async {
    final pending = Completer<Result<List<SupportedCameraResolution>>>();
    final loader = _CapabilityLoader([pending.future]);

    await pumpScreen(tester, loader: loader);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(
      Result<List<SupportedCameraResolution>>.success([hd, fullHd]),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsKeys.cameraResolutionScreen), findsOneWidget);
    expect(
      find.byKey(SettingsKeys.cameraResolutionOption('720p')),
      findsOneWidget,
    );
    expect(
      find.byKey(SettingsKeys.cameraResolutionOption('1080p')),
      findsOneWidget,
    );
    expect(find.text('1280 × 720'), findsWidgets);
    expect(find.text('4K'), findsNothing);
  });

  testWidgets('shows deterministic camera-change fallback', (tester) async {
    final store = InMemoryPreferenceStore({
      PreferenceKeys.cameraResolution: '4k',
      PreferenceKeys.pdfQualityPercent: 60,
    });

    await pumpScreen(
      tester,
      loader: _CapabilityLoader([
        Result<List<SupportedCameraResolution>>.success([hd]),
      ]),
      store: store,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('4K is unavailable on this camera. Using 720p • 1280 × 720.'),
      findsOneWidget,
    );
  });

  testWidgets('Retry recovers from a capability error', (tester) async {
    final loader = _CapabilityLoader([
      const Result<List<SupportedCameraResolution>>.failure(Failure.camera()),
      Result<List<SupportedCameraResolution>>.success([hd]),
    ]);

    await pumpScreen(tester, loader: loader);
    await tester.pumpAndSettle();
    expect(find.byKey(SettingsKeys.cameraResolutionRetry), findsOneWidget);

    await tester.tap(find.byKey(SettingsKeys.cameraResolutionRetry));
    await tester.pumpAndSettle();

    expect(find.text('1280 × 720'), findsWidgets);
    expect(loader.calls, 2);
  });

  testWidgets('unavailable probing shows maximum copy at large text', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      loader: _CapabilityLoader([
        const Result<List<SupportedCameraResolution>>.success([]),
      ]),
      textScale: 3,
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Exact choices are unavailable'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Camera maximum'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection persists without changing the PDF default', (
    tester,
  ) async {
    final store = InMemoryPreferenceStore({
      PreferenceKeys.pdfQualityPercent: 60,
    });
    final cubit = await pumpScreen(
      tester,
      loader: _CapabilityLoader([
        Result<List<SupportedCameraResolution>>.success([hd]),
      ]),
      store: store,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(SettingsKeys.cameraResolutionOption('720p')));
    await tester.pumpAndSettle();

    expect(
      cubit.state.settings.cameraResolution,
      DesiredCameraResolution.tier(CameraResolutionTier.hd720),
    );
    expect(cubit.state.settings.pdfQuality, PdfQualityPercent(value: 60));
    expect(store.values[PreferenceKeys.cameraResolution], '720p');
    expect(store.values[PreferenceKeys.pdfQualityPercent], 60);
  });
}
