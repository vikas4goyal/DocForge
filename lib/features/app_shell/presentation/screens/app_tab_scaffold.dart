/// The application's three destinations.
library;

import 'package:doc_forge/features/app_shell/presentation/shell_keys.dart';
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
    final theme = Theme.of(context);
    final labelPainter = TextPainter(
      text: TextSpan(
        text: ShellSemantics.dashboardTab,
        style: theme.textTheme.labelSmall,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
    final labelHeight = labelPainter.preferredLineHeight;
    labelPainter.dispose();

    return Scaffold(
      key: ShellKeys.tabScaffold,
      body: child,
      floatingActionButton: FloatingActionButton(
        key: ShellKeys.createTab,
        onPressed: onCreate,
        tooltip: ShellSemantics.createButton,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        // A notched bar with the create control docked into it: the middle
        // position is what the specification asks for, and a third
        // NavigationDestination would make Create look like a place.
        // Material's bar padding (24), our button padding (16), and the icon
        // (24) consume 64 logical pixels. Let the final part follow the
        // system-scaled label instead of assuming its default 16-pixel line
        // height; otherwise iOS accessibility text can overflow the tab.
        height: 64 + labelHeight,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TabButton(
              buttonKey: ShellKeys.dashboardTab,
              icon: Icons.folder_outlined,
              selectedIcon: Icons.folder,
              label: ShellSemantics.dashboardTab,
              selected: tab == AppTab.dashboard,
              onPressed: () => onTabSelected(AppTab.dashboard),
            ),
            const SizedBox(width: 48),
            _TabButton(
              buttonKey: ShellKeys.settingsTab,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: ShellSemantics.settingsTab,
              selected: tab == AppTab.settings,
              onPressed: () => onTabSelected(AppTab.settings),
            ),
          ],
        ),
      ),
    );
  }
}

/// One destination in the bar.
class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.buttonKey,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;

    return Expanded(
      // The label and the selected state come from here; the tap action comes
      // from the InkWell beneath. Excluding the InkWell instead would announce
      // a button a screen reader could not activate, and only the *content* is
      // redundant once the label is set.
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          key: buttonKey,
          onTap: onPressed,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The icon changes as well as the colour: distinguishing the
                  // selected destination by colour alone fails for anyone who
                  // cannot see the difference.
                  Icon(
                    selected ? selectedIcon : icon,
                    color: selected
                        ? colours.primary
                        : colours.onSurfaceVariant,
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected
                          ? colours.primary
                          : colours.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
