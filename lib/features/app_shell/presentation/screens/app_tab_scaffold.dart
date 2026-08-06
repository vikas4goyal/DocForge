/// The application's three destinations.
library;

import 'package:doc_scanly/features/app_shell/presentation/shell_keys.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Which destination the tab bar is showing.
enum AppTab {
  /// The library: folders, documents, search.
  dashboard,

  /// Settings.
  settings,
}

/// The persistent tab bar and whichever destination is selected.
///
/// Three controls, but only two of them are places. Create PDF is an *action*:
/// it starts a session and pushes the page table above the shell, leaving the
/// previously selected destination selected underneath. A Create tab that
/// stayed selected after the user backed out would leave the bar highlighting
/// a screen that is not there (`design.md` D10).
class AppTabScaffold extends StatelessWidget {
  /// Creates the scaffold.
  const AppTabScaffold({
    required this.tab,
    required this.child,
    required this.onTabSelected,
    required this.onCreate,
    super.key,
  });

  /// The destination currently selected.
  final AppTab tab;

  /// The destination's own content.
  final Widget child;

  /// Called when the user picks a destination.
  final ValueChanged<AppTab> onTabSelected;

  /// Called when the user starts a new document.
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final usesCupertinoBar = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      key: ShellKeys.tabScaffold,
      body: child,
      bottomNavigationBar: usesCupertinoBar
          ? _CupertinoAppTabBar(
              tab: tab,
              onTabSelected: onTabSelected,
              onCreate: onCreate,
            )
          : _MaterialAppTabBar(
              tab: tab,
              onTabSelected: onTabSelected,
              onCreate: onCreate,
            ),
    );
  }
}

/// Renders the native iOS tab-bar treatment.
class _CupertinoAppTabBar extends StatelessWidget {
  const _CupertinoAppTabBar({
    required this.tab,
    required this.onTabSelected,
    required this.onCreate,
  });

  final AppTab tab;
  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewPadding.bottom;

    // CupertinoTabBar normally reserves the home-indicator inset below its
    // 50pt content row. On taller iPhone insets that makes the controls appear
    // pinned to the top of the complete visible bar. Give the bar the same
    // total height but let its full-width tap regions and visual groups use
    // that height, keeping them optically centred with clearance below.
    return MediaQuery(
      data: mediaQuery.copyWith(
        viewPadding: EdgeInsets.fromLTRB(
          mediaQuery.viewPadding.left,
          mediaQuery.viewPadding.top,
          mediaQuery.viewPadding.right,
          0,
        ),
      ),
      child: CupertinoTabBar(
        height: 50 + bottomInset,
        // Create is an action, not navigation state. Keeping the selected index
        // on 0 or 2 prevents it from looking selected after a cancelled scan.
        currentIndex: tab == AppTab.dashboard ? 0 : 2,
        activeColor: CupertinoColors.activeBlue.resolveFrom(context),
        iconSize: 25,
        onTap: (index) {
          switch (index) {
            case 0:
              onTabSelected(AppTab.dashboard);
            case 1:
              onCreate();
            case 2:
              onTabSelected(AppTab.settings);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: _CupertinoTabItem(
              icon: CupertinoIcons.folder,
              label: 'Dashboard',
              key: ShellKeys.dashboardTab,
              semanticsLabel: ShellSemantics.dashboardTab,
            ),
            activeIcon: _CupertinoTabItem(
              icon: CupertinoIcons.folder_fill,
              label: 'Dashboard',
              key: ShellKeys.dashboardTab,
              semanticsLabel: ShellSemantics.dashboardTab,
              selected: true,
            ),
          ),
          BottomNavigationBarItem(
            icon: _CupertinoTabItem(
              icon: CupertinoIcons.add_circled,
              label: 'Create',
              key: ShellKeys.createTab,
              semanticsLabel: ShellSemantics.createButton,
            ),
          ),
          BottomNavigationBarItem(
            icon: _CupertinoTabItem(
              icon: CupertinoIcons.gear,
              label: 'Settings',
              key: ShellKeys.settingsTab,
              semanticsLabel: ShellSemantics.settingsTab,
            ),
            activeIcon: _CupertinoTabItem(
              icon: CupertinoIcons.gear_solid,
              label: 'Settings',
              key: ShellKeys.settingsTab,
              semanticsLabel: ShellSemantics.settingsTab,
              selected: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Centers an iOS tab icon and label as one visual unit.
///
/// `CupertinoTabBar` normally lays out its icon in an expanding region above
/// a separately bottom-aligned label. Keeping the pair in one compact column
/// gives all three items the same optical vertical centre while the tab bar
/// continues to own its native safe-area inset and separator.
class _CupertinoTabItem extends StatelessWidget {
  const _CupertinoTabItem({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    super.key,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    selected: selected,
    button: true,
    excludeSemantics: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(icon), const SizedBox(height: 2), Text(label)],
    ),
  );
}

/// Renders the native Material 3 Android navigation treatment.
class _MaterialAppTabBar extends StatelessWidget {
  const _MaterialAppTabBar({
    required this.tab,
    required this.onTabSelected,
    required this.onCreate,
  });

  final AppTab tab;
  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: tab == AppTab.dashboard ? 0 : 2,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            onTabSelected(AppTab.dashboard);
          case 1:
            onCreate();
          case 2:
            onTabSelected(AppTab.settings);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: _TabIcon(
            icon: Icons.folder_outlined,
            key: ShellKeys.dashboardTab,
            semanticsLabel: ShellSemantics.dashboardTab,
          ),
          selectedIcon: _TabIcon(
            icon: Icons.folder,
            key: ShellKeys.dashboardTab,
            semanticsLabel: ShellSemantics.dashboardTab,
            selected: true,
          ),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: _TabIcon(
            icon: Icons.add_circle_outline,
            key: ShellKeys.createTab,
            semanticsLabel: ShellSemantics.createButton,
          ),
          label: 'Create',
          tooltip: ShellSemantics.createButton,
        ),
        NavigationDestination(
          icon: _TabIcon(
            icon: Icons.settings_outlined,
            key: ShellKeys.settingsTab,
            semanticsLabel: ShellSemantics.settingsTab,
          ),
          selectedIcon: _TabIcon(
            icon: Icons.settings,
            key: ShellKeys.settingsTab,
            semanticsLabel: ShellSemantics.settingsTab,
            selected: true,
          ),
          label: 'Settings',
        ),
      ],
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({
    required this.icon,
    required this.semanticsLabel,
    super.key,
    this.selected = false,
  });

  final IconData icon;
  final String semanticsLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    selected: selected,
    button: true,
    excludeSemantics: true,
    child: Icon(icon),
  );
}
