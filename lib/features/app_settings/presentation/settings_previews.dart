/// Widget previews for settings.
///
/// Every preview is fed by fixtures through a Cubit frozen at a chosen state,
/// so nothing here reads a real preference or walks the documents directory
/// (`design.md` §15).
library;

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/preview_scaffold.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/app_settings/application/usecases/settings_usecases.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/infrastructure/repositories/preference_settings_repository.dart';
import 'package:doc_scanly/features/app_settings/presentation/cubit/settings_cubit.dart';
import 'package:doc_scanly/features/app_settings/presentation/screens/camera_resolution_screen.dart';
import 'package:doc_scanly/features/app_settings/presentation/screens/settings_detail_screens.dart';
import 'package:doc_scanly/features/app_settings/presentation/screens/settings_screen.dart';
import 'package:doc_scanly/features/app_settings/presentation/widgets/settings_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A storage reader answering with a fixed summary.
class _PreviewStorage implements StorageSummaryReader {
  const _PreviewStorage();

  @override
  Future<Result<StorageSummary>> summary() async =>
      const Result<StorageSummary>.success(
        StorageSummary(totalBytes: 2_097_152, documentCount: 8),
      );
}

/// A Cubit frozen at [_seeded], with every change inert.
class _PreviewSettingsCubit extends SettingsCubit {
  _PreviewSettingsCubit(this._seeded)
    : super(
        LoadSettings(_repository),
        UpdateSetting(_repository),
        PreviewDocumentName(FixedClock(DateTime.utc(2026, 3, 14, 9, 5))),
        const LoadStorageSummary(_PreviewStorage()),
        onThemeChanged: _ignore,
      );

  static final _repository = PreferenceSettingsRepository(
    InMemoryPreferenceStore(),
  );

  static void _ignore(AppThemeChoice choice) {}

  final SettingsState _seeded;

  @override
  SettingsState get state => _seeded;

  @override
  Future<void> load() async {}

  @override
  Future<void> setTheme(AppThemeChoice theme) async {}

  @override
  Future<void> setPdfQuality(PdfQualityPercent quality) async {}

  @override
  Future<void> setCameraResolution(DesiredCameraResolution desired) async {}

  @override
  Future<void> setNamingPattern(NamingPattern pattern) async {}

  @override
  Future<void> setSaveLocation(String? path) async {}

  @override
  Future<void> refreshStorage() async {}
}

Widget _screen(
  SettingsState state, {
  bool supportsCloudStorage = false,
  bool isTab = false,
}) => BlocProvider<SettingsCubit>(
  create: (_) => _PreviewSettingsCubit(state),
  child: SettingsScreen(
    onBack: isTab ? null : () {},
    pickSaveLocation: () async => null,
    onAbout: () {},
    onPrivacyPolicy: () {},
    onToggleAppLock: (_) {},
    onStorageLocation: supportsCloudStorage ? () {} : null,
  ),
);

Widget _cameraResolution(SettingsState state) => BlocProvider<SettingsCubit>(
  create: (_) => _PreviewSettingsCubit(state),
  child: CameraResolutionScreen(onBack: () {}),
);

const _storage = StorageSummary(totalBytes: 2_097_152, documentCount: 8);

final _ready = SettingsState.initial().copyWith(
  status: SettingsStatus.ready,
  settings: AppSettings.defaults,
  storage: _storage,
  namingPreview: 'Scan 2026-03-14 09.05',
);

// ---------------------------------------------------------------------------
// Settings screen
// ---------------------------------------------------------------------------

/// Settings at their defaults.
@Preview(name: 'Settings — default', group: 'Settings', theme: appPreviewTheme)
Widget settingsDefault() => _screen(_ready);

/// Settings as the top-level tab, without a back affordance.
@Preview(
  name: 'Settings — tab destination',
  group: 'Settings',
  theme: appPreviewTheme,
)
Widget settingsTabDestination() => _screen(_ready, isTab: true);

/// Settings still being read.
@Preview(name: 'Settings — loading', group: 'Settings', theme: appPreviewTheme)
Widget settingsLoading() => _screen(SettingsState.initial());

/// Nothing stored yet — no storage figure to report.
@Preview(name: 'Settings — empty', group: 'Settings', theme: appPreviewTheme)
Widget settingsEmpty() => _screen(
  SettingsState.initial().copyWith(
    status: SettingsStatus.ready,
    namingPreview: 'Scan 2026-03-14 09.05',
  ),
);

/// A setting that could not be saved.
@Preview(name: 'Settings — error', group: 'Settings', theme: appPreviewTheme)
Widget settingsError() => _screen(
  _ready.copyWith(
    status: SettingsStatus.failure,
    failure: const Failure.storage(),
  ),
);

/// Every setting moved away from its default, with a long save location.
@Preview(
  name: 'Settings — long content',
  group: 'Settings',
  theme: appPreviewTheme,
)
Widget settingsLongContent() => _screen(
  _ready.copyWith(
    settings: AppSettings(
      theme: AppThemeChoice.dark,
      pdfQuality: PdfQualityPercent(value: 100),
      cameraResolution: DesiredCameraResolution.tier(
        CameraResolutionTier.ultraHd4k,
      ),
      namingPattern: NamingPattern.sequential,
      saveLocation:
          '/storage/emulated/0/Android/data/com.example.docscanly/files/'
          'Documents/Exports/Quarterly',
      isAppLockEnabled: true,
    ),
    storage: const StorageSummary(
      totalBytes: 3_221_225_472,
      documentCount: 1024,
    ),
    namingPreview: 'Scan 42',
  ),
);

/// Settings on a phone, light.
@Preview(
  name: 'Settings — phone, light',
  group: 'Settings',
  size: PreviewSize.phone,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget settingsPhoneLight() => _screen(_ready);

/// Settings on a phone, dark.
@Preview(
  name: 'Settings — phone, dark',
  group: 'Settings',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget settingsPhoneDark() => _screen(_ready);

/// Settings on a tablet, light.
@Preview(
  name: 'Settings — tablet, light',
  group: 'Settings',
  size: PreviewSize.tablet,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget settingsTabletLight() => _screen(_ready);

/// Settings on a tablet, dark.
@Preview(
  name: 'Settings — tablet, dark',
  group: 'Settings',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget settingsTabletDark() => _screen(_ready);

/// Settings on iOS, where storage location is an explicit option.
@Preview(
  name: 'Settings — iOS storage',
  group: 'Settings',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget settingsICloudStorage() => _screen(_ready, supportsCloudStorage: true);

// ---------------------------------------------------------------------------
// Pushed Settings details
// ---------------------------------------------------------------------------

final _previewHd = SupportedCameraResolution(
  tier: CameraResolutionTier.hd720,
  width: 1280,
  height: 720,
);

final _previewFullHd = SupportedCameraResolution(
  tier: CameraResolutionTier.fullHd1080,
  width: 1920,
  height: 1080,
);

/// Camera resolutions while capabilities load.
@Preview(
  name: 'Camera resolution — loading',
  group: 'Settings details',
  theme: appPreviewTheme,
)
Widget cameraResolutionLoading() => _cameraResolution(
  _ready.copyWith(cameraResolutionStatus: CameraResolutionStatus.loading),
);

/// Supported active-camera resolutions with exact dimensions.
@Preview(
  name: 'Camera resolution — supported',
  group: 'Settings details',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget cameraResolutionSupported() => _cameraResolution(
  _ready.copyWith(
    cameraResolutionStatus: CameraResolutionStatus.supported,
    supportedCameraResolutions: [_previewHd, _previewFullHd],
  ),
);

/// A selected tier falling back on a different camera.
@Preview(
  name: 'Camera resolution — fallback, dark tablet',
  group: 'Settings details',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget cameraResolutionFallback() => _cameraResolution(
  _ready.copyWith(
    settings: AppSettings(
      cameraResolution: DesiredCameraResolution.tier(
        CameraResolutionTier.ultraHd4k,
      ),
    ),
    cameraResolutionStatus: CameraResolutionStatus.supported,
    supportedCameraResolutions: [_previewHd],
  ),
);

/// Capability query failure with Retry.
@Preview(
  name: 'Camera resolution — error',
  group: 'Settings details',
  theme: appPreviewTheme,
)
Widget cameraResolutionError() => _cameraResolution(
  _ready.copyWith(
    cameraResolutionStatus: CameraResolutionStatus.failure,
    cameraResolutionFailure: const Failure.camera(),
  ),
);

/// Plugin maximum when exact capabilities cannot be enumerated.
@Preview(
  name: 'Camera resolution — maximum unavailable',
  group: 'Settings details',
  theme: appPreviewTheme,
)
Widget cameraResolutionMaximum() => _cameraResolution(
  _ready.copyWith(cameraResolutionStatus: CameraResolutionStatus.unavailable),
);

/// Default save location while exports ask every time.
@Preview(
  name: 'Save location — ask each time',
  group: 'Settings details',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget saveLocationAskEachTime() => DefaultSaveLocationScreen(
  currentPath: null,
  pickDirectory: () async => null,
  onSelected: (_) async {},
);

/// Default save location with a long selected folder on a dark tablet.
@Preview(
  name: 'Save location — long path, tablet dark',
  group: 'Settings details',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget saveLocationLongPath() => DefaultSaveLocationScreen(
  currentPath:
      '/storage/emulated/0/Documents/Exports/Quarterly/Reviewed documents',
  pickDirectory: () async => null,
  onSelected: (_) async {},
);

Widget _storageDetails(SettingsState state, {bool iCloud = false}) =>
    BlocProvider<SettingsCubit>(
      create: (_) => _PreviewSettingsCubit(state),
      child: StorageDetailsScreen(onManageLocation: iCloud ? () {} : null),
    );

/// Storage details with a current summary.
@Preview(
  name: 'Storage details — ready',
  group: 'Settings details',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget storageDetailsReady() => _storageDetails(_ready, iCloud: true);

/// Storage details while refreshing in dark tablet layout.
@Preview(
  name: 'Storage details — refreshing, tablet dark',
  group: 'Settings details',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget storageDetailsRefreshing() =>
    _storageDetails(_ready.copyWith(isRefreshingStorage: true));

/// Storage details when a read failed.
@Preview(
  name: 'Storage details — error',
  group: 'Settings details',
  theme: appPreviewTheme,
)
Widget storageDetailsError() =>
    _storageDetails(_ready.copyWith(storageFailure: const Failure.storage()));

// ---------------------------------------------------------------------------
// About and Privacy Policy
// ---------------------------------------------------------------------------

/// The About screen.
@Preview(name: 'About — default', group: 'Settings', theme: appPreviewTheme)
Widget aboutDefault() => AboutScreen(version: '1.0.0', onBack: () {});

/// About with a long pre-release version.
@Preview(
  name: 'About — long content',
  group: 'Settings',
  theme: appPreviewTheme,
)
Widget aboutLongContent() =>
    AboutScreen(version: '1.0.0-beta.4+2026031409', onBack: () {});

/// The About screen on a tablet, dark.
@Preview(
  name: 'About — tablet, dark',
  group: 'Settings',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget aboutTabletDark() => AboutScreen(version: '1.0.0', onBack: () {});

/// The Privacy Policy screen.
@Preview(name: 'Privacy — default', group: 'Settings', theme: appPreviewTheme)
Widget privacyDefault() => PrivacyPolicyScreen(onBack: () {});

/// The Privacy Policy on a phone, dark.
@Preview(
  name: 'Privacy — phone, dark',
  group: 'Settings',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget privacyPhoneDark() => PrivacyPolicyScreen(onBack: () {});

// ---------------------------------------------------------------------------
// Settings tiles
// ---------------------------------------------------------------------------

/// Builds the PDF-quality slider tile at [percent], as Settings composes it.
Widget _sliderTile(int percent, {bool enabled = true}) => SettingsSliderTile(
  title: 'PDF quality',
  value: percent,
  min: PdfQualityPercent.minimum,
  max: PdfQualityPercent.maximum,
  enabled: enabled,
  valueLabelFor: (value) => '$value%',
  semanticLabelFor: (value) => 'Default PDF quality, $value percent',
  description: SettingsCopy.pdfQualityDescription(
    PdfQualityPercent(value: percent),
  ),
  onChanged: (_) {},
  onChangeEnd: (_) {},
);

/// The slider tile at the documented 70% default.
@Preview(
  name: 'SettingsSliderTile — default',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget sliderTileDefault() => _sliderTile(70);

/// The slider tile mid-drag, showing an uncommitted 45% draft.
@Preview(
  name: 'SettingsSliderTile — dragging',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget sliderTileDragging() => _sliderTile(45);

/// The slider tile at its 30% minimum.
@Preview(
  name: 'SettingsSliderTile — minimum',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget sliderTileMinimum() => _sliderTile(PdfQualityPercent.minimum);

/// The slider tile at its 100% maximum.
@Preview(
  name: 'SettingsSliderTile — maximum',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget sliderTileMaximum() => _sliderTile(PdfQualityPercent.maximum);

/// The slider tile while settings are loading: shown, but inert.
@Preview(
  name: 'SettingsSliderTile — loading',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget sliderTileLoading() => _sliderTile(70, enabled: false);

/// The slider tile reverted after a failed write, beneath the error banner.
@Preview(
  name: 'SettingsSliderTile — error',
  group: 'Settings',
  theme: appPreviewTheme,
)
Widget sliderTileError() => _screen(
  _ready.copyWith(
    status: SettingsStatus.failure,
    failure: const Failure.storage(),
  ),
);

/// The slider tile with its description wrapping at double text scale.
@Preview(
  name: 'SettingsSliderTile — long content',
  group: 'Settings',
  textScaleFactor: 2,
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget sliderTileLongContent() => _sliderTile(55);

/// The slider tile in light mode.
@Preview(
  name: 'SettingsSliderTile — light',
  group: 'Settings',
  brightness: Brightness.light,
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget sliderTileLight() => _sliderTile(70);

/// The slider tile in dark mode.
@Preview(
  name: 'SettingsSliderTile — dark',
  group: 'Settings',
  brightness: Brightness.dark,
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget sliderTileDark() => _sliderTile(70);

/// The whole screen mid-drag, with an uncommitted draft on the slider.
@Preview(
  name: 'Settings — PDF quality dragging',
  group: 'Settings',
  theme: appPreviewTheme,
)
Widget settingsPdfQualityDragging() =>
    _screen(_ready.copyWith(pdfQualityDraft: 45));

/// A choice tile at its default.
@Preview(
  name: 'SettingsChoiceTile — default',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget choiceTileDefault() => SettingsChoiceTile<AppThemeChoice>(
  title: 'Theme',
  value: AppThemeChoice.system,
  valueLabel: AppThemeChoice.system.label,
  options: AppThemeChoice.values,
  labelFor: (choice) => choice.label,
  onSelected: (_) {},
);

/// A choice tile with a preview beneath it.
@Preview(
  name: 'SettingsChoiceTile — with preview',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget choiceTileWithPreview() => SettingsChoiceTile<NamingPattern>(
  title: 'Default file naming',
  value: NamingPattern.sequential,
  valueLabel: NamingPattern.sequential.label,
  options: NamingPattern.values,
  labelFor: (pattern) => pattern.label,
  onSelected: (_) {},
  footer: const NamingPatternPreview(example: 'Scan 42'),
);

/// A value tile with something to show.
@Preview(
  name: 'SettingsValueTile — default',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget valueTileDefault() => SettingsValueTile(
  title: 'Storage',
  value: SettingsCopy.storageSummaryLabel('2.0 MB', 8),
  onTap: () {},
);

/// A value tile with no value yet — its empty state.
@Preview(
  name: 'SettingsValueTile — empty',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget valueTileEmpty() =>
    const SettingsValueTile(title: SettingsCopy.aboutTitle, value: '');

/// A value tile whose value has to be truncated.
@Preview(
  name: 'SettingsValueTile — long content',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget valueTileLongContent() => const SettingsValueTile(
  title: 'Default save location',
  value:
      '/storage/emulated/0/Android/data/com.example.docscanly/files/Documents/'
      'Exports/Quarterly',
);

/// A switch tile that is off.
@Preview(
  name: 'SettingsSwitchTile — default',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget switchTileDefault() => SettingsSwitchTile(
  title: 'App lock',
  value: false,
  subtitle: 'Require authentication to open DocScanly',
  onChanged: (_) {},
);

/// A switch tile that is on.
@Preview(
  name: 'SettingsSwitchTile — on',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget switchTileOn() => SettingsSwitchTile(
  title: 'App lock',
  value: true,
  subtitle: 'Require authentication to open DocScanly',
  onChanged: (_) {},
);

/// A switch tile with no handler — the disabled state.
@Preview(
  name: 'SettingsSwitchTile — disabled',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget switchTileDisabled() => const SettingsSwitchTile(
  title: 'App lock',
  value: false,
  subtitle: 'Set up a device passcode to enable this',
);

/// The naming preview on its own.
@Preview(
  name: 'NamingPatternPreview — default',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget namingPreviewDefault() =>
    const NamingPatternPreview(example: 'Scan 2026-03-14 09.05');

/// A naming preview long enough to wrap.
@Preview(
  name: 'NamingPatternPreview — long content',
  group: 'Settings',
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget namingPreviewLongContent() => const NamingPatternPreview(
  example: 'Quarterly consulting invoice 2026-03-14 09.05.42',
);
