/// Tier 1 — the previews for every widget this change keyed or relabelled.
///
/// Adding a key or a semantics label changes the widget tree, and a preview is
/// the one place several of these widgets are built in their loading, empty and
/// error states at all. `flutter widget-preview start` renders them for a human
/// to look at; this pumps the same functions so a preview that stops *building*
/// fails in CI rather than the next time someone happens to open the previewer.
///
/// It asserts that each preview builds and paints without throwing. It
/// deliberately asserts nothing about appearance — that is what the goldens are
/// for, and duplicating them here would mean two things to re-record.
library;

import 'package:doc_forge/core/previews/preview_scaffold.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/features/app_settings/presentation/settings_previews.dart';
import 'package:doc_forge/features/app_shell/presentation/shell_previews.dart';
import 'package:doc_forge/features/document_creation/presentation/creation_previews.dart';
import 'package:doc_forge/features/document_library/presentation/library_previews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Pumps [build] and fails if it throws while building or painting.
  ///
  /// Wrapped in a MaterialApp and [previewSurface] because a preview supplies
  /// neither: directionality, theming and the media query come from the
  /// previewer, and several previews declare `wrapper: previewSurface` on the
  /// annotation rather than calling it in the body, which only the previewer
  /// applies. This stands in for that host.
  Future<void> rendersCleanly(
    WidgetTester tester,
    Widget Function() build,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: previewSurface(build())),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
  }

  group('library previews still render', () {
    // FolderTile gained keys on its action menu, and the folder detail screen
    // gained a key and a semantics label of its own.
    for (final entry in <String, Widget Function()>{
      'folderTileDefault': folderTileDefault,
      'folderTileEmpty': folderTileEmpty,
      'folderTileDark': folderTileDark,
      'pageThumbnailPlaceholder': pageThumbnailPlaceholder,
      'pageThumbnailStrip': pageThumbnailStrip,
      'documentCardDefault': documentCardDefault,
      'documentCardDark': documentCardDark,
      'documentListReady': documentListReady,
      'documentListEmpty': documentListEmpty,
      'documentListError': documentListError,
      'documentListDark': documentListDark,
      'documentListTablet': documentListTablet,
      'documentDetailReady': documentDetailReady,
      'documentDetailError': documentDetailError,
      'documentDetailDark': documentDetailDark,
      'documentDetailTablet': documentDetailTablet,
      'folderListReady': folderListReady,
      'folderListEmpty': folderListEmpty,
      'folderListError': folderListError,
      'dashboardDefault': dashboardDefault,
      'dashboardEmpty': dashboardEmpty,
      'dashboardError': dashboardError,
      'dashboardPhoneDark': dashboardPhoneDark,
      'dashboardTabletLight': dashboardTabletLight,
    }.entries) {
      testWidgets(entry.key, (tester) => rendersCleanly(tester, entry.value));
    }
  });

  group('settings previews still render', () {
    // Every tile's semantics label moved into SettingsSemantics, and the choice
    // sheet's options gained keys.
    for (final entry in <String, Widget Function()>{
      'settingsDefault': settingsDefault,
      'settingsLoading': settingsLoading,
      'settingsError': settingsError,
      'settingsPhoneDark': settingsPhoneDark,
      'settingsTabletLight': settingsTabletLight,
      'aboutDefault': aboutDefault,
      'privacyDefault': privacyDefault,
      'choiceTileDefault': choiceTileDefault,
      'choiceTileWithPreview': choiceTileWithPreview,
      'choiceTileLongContent': choiceTileLongContent,
      'valueTileDefault': valueTileDefault,
      'valueTileEmpty': valueTileEmpty,
      'switchTileDefault': switchTileDefault,
      'switchTileOn': switchTileOn,
      'switchTileDisabled': switchTileDisabled,
      'namingPreviewDefault': namingPreviewDefault,
    }.entries) {
      testWidgets(entry.key, (tester) => rendersCleanly(tester, entry.value));
    }
  });

  group('creation previews still render', () {
    // The page row's labels moved into CreationSemantics, and the save dialog's
    // buttons gained semantics wrappers.
    for (final entry in <String, Widget Function()>{
      'pageTableDefault': pageTableDefault,
      'pageTableEmpty': pageTableEmpty,
      'pageTableError': pageTableError,
      'pageTablePhoneDark': pageTablePhoneDark,
      'pageTableTabletLight': pageTableTabletLight,
      'rowDefault': rowDefault,
      'rowEdited': rowEdited,
      'rowLongContent': rowLongContent,
      'saveDefault': saveDefault,
      'saveEmptyName': saveEmptyName,
      'savePasswordOn': savePasswordOn,
      'savePasswordMismatch': savePasswordMismatch,
      'saveError': saveError,
    }.entries) {
      testWidgets(entry.key, (tester) => rendersCleanly(tester, entry.value));
    }
  });

  group('shell previews still render', () {
    // The tab bar's labels moved into ShellSemantics.
    for (final entry in <String, Widget Function()>{
      'shellDefault': shellDefault,
      'shellSettings': shellSettings,
      'shellDark': shellDark,
      'shellTablet': shellTablet,
    }.entries) {
      testWidgets(entry.key, (tester) => rendersCleanly(tester, entry.value));
    }
  });
}
