/// Widget previews for the application shell.
///
/// The shell has no data of its own — it is a tab bar wrapped around whatever
/// destination is selected — so its states are expressed through the content
/// it is given: a destination that is loading, one that is empty, one that
/// failed, and one long enough to scroll under the bar (`design.md` §15).
library;

import 'package:doc_scanly/core/previews/preview_scaffold.dart';
import 'package:doc_scanly/features/app_shell/presentation/screens/app_tab_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Wraps [body] in the shell with [tab] selected.
Widget _shell(AppTab tab, Widget body) => previewScreen(
  AppTabScaffold(tab: tab, onTabSelected: (_) {}, onCreate: () {}, child: body),
);

/// A placeholder destination that names what it is standing in for.
Widget _destination(String label) => Center(child: Text(label));

/// The shell showing the dashboard destination.
@Preview(name: 'Shell — default', group: 'Shell', theme: appPreviewTheme)
Widget shellDefault() => _shell(AppTab.dashboard, _destination('Dashboard'));

/// The shell with the settings destination selected.
@Preview(name: 'Shell — settings', group: 'Shell', theme: appPreviewTheme)
Widget shellSettings() => _shell(AppTab.settings, _destination('Settings'));

/// The shell while its destination is loading.
@Preview(name: 'Shell — loading', group: 'Shell', theme: appPreviewTheme)
Widget shellLoading() =>
    _shell(AppTab.dashboard, const Center(child: CircularProgressIndicator()));

/// The shell with nothing to show.
///
/// The bar stays: an empty library is still somewhere the user can act from,
/// and hiding the create control here would strand them.
@Preview(name: 'Shell — empty', group: 'Shell', theme: appPreviewTheme)
Widget shellEmpty() => _shell(AppTab.dashboard, _destination('No documents'));

/// The shell around a destination that failed to load.
@Preview(name: 'Shell — error', group: 'Shell', theme: appPreviewTheme)
Widget shellError() =>
    _shell(AppTab.dashboard, _destination('Could not load the library'));

/// The shell around content long enough to scroll beneath the bar.
///
/// What this checks is that the bar never covers the last row: the destination
/// scrolls under it, and the final item has to stay reachable.
@Preview(name: 'Shell — long content', group: 'Shell', theme: appPreviewTheme)
Widget shellLongContent() => _shell(
  AppTab.dashboard,
  ListView(
    children: [for (var i = 1; i <= 40; i++) ListTile(title: Text('Item $i'))],
  ),
);

/// The shell in dark mode.
@Preview(
  name: 'Shell — dark',
  group: 'Shell',
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget shellDark() => _shell(AppTab.dashboard, _destination('Dashboard'));

/// The shell on a tablet, where the bar spans a much wider window.
@Preview(
  name: 'Shell — tablet',
  group: 'Shell',
  theme: appPreviewTheme,
  size: PreviewSize.tablet,
)
Widget shellTablet() => _shell(AppTab.dashboard, _destination('Dashboard'));
