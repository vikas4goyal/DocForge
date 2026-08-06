/// Robots for the screens that stand around the application: onboarding, the
/// lock, the tab shell, the dashboard and settings.
library;

import 'package:doc_scanly/features/app_security/presentation/security_keys.dart';
import 'package:doc_scanly/features/app_settings/presentation/settings_keys.dart';
import 'package:doc_scanly/features/app_shell/presentation/shell_keys.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:doc_scanly/features/document_import/presentation/import_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/library_dashboard_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/trash_keys.dart';
import 'package:doc_scanly/features/onboarding/presentation/onboarding_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump.dart';
import 'robot.dart';

/// Drives the three-screen onboarding introduction.
///
/// The screens are a fixed sequence — welcome, privacy, camera permission — so
/// [complete] walks all three. A flow that only wants to *get past* onboarding
/// does not use this at all: it boots with the flag already set, which is what
/// the boot helper defaults to.
class OnboardingRobot extends Robot {
  /// Creates the robot.
  const OnboardingRobot(super.tester);

  @override
  Key get screenKey => OnboardingKeys.welcomeScreen;

  /// Walks welcome → privacy → permission, skipping the camera request.
  ///
  /// Skips rather than allows, because allowing would put a real system
  /// permission dialogue on screen that nothing in the suite could dismiss.
  /// Skipping is a path the spec supports and a real user takes.
  Future<void> complete() => step('completing onboarding', () async {
    await waitUntilVisible();
    await tap(OnboardingKeys.welcomeContinueButton);

    await waitFor(OnboardingKeys.privacyScreen);
    await tap(OnboardingKeys.privacyContinueButton);

    await waitFor(OnboardingKeys.permissionScreen);
    await tap(OnboardingKeys.permissionSkipButton);
  });

  /// Advances only as far as the privacy introduction.
  ///
  /// For a flow asserting the three privacy statements are actually shown,
  /// which the onboarding spec requires by name.
  Future<void> openPrivacyStep() => step('opening the privacy step', () async {
    await waitUntilVisible();
    await tap(OnboardingKeys.welcomeContinueButton);
    await waitFor(OnboardingKeys.privacyScreen);
  });
}

/// Drives the application lock screen.
class UnlockRobot extends Robot {
  /// Creates the robot.
  const UnlockRobot(super.tester);

  @override
  Key get screenKey => SecurityKeys.unlockScreen;

  /// Authenticates, answering the prompt through the substituted authenticator.
  ///
  /// The screen prompts on mount, so this usually only has to wait. The retry
  /// control is used when the first attempt was refused — which is the path a
  /// flow takes when it configured the authenticator to reject.
  Future<void> unlock() => step('unlocking the application', () async {
    await waitUntilVisible();
    if (has(SecurityKeys.unlockRetryButton)) {
      await tap(SecurityKeys.unlockRetryButton);
    }
  });

  /// Retries after a refused attempt.
  Future<void> retry() => step('retrying the unlock', () async {
    await tap(SecurityKeys.unlockRetryButton);
  });
}

/// Drives the tab bar that wraps the dashboard and settings.
class TabShellRobot extends Robot {
  /// Creates the robot.
  const TabShellRobot(super.tester);

  @override
  Key get screenKey => ShellKeys.tabScaffold;

  /// Switches to the dashboard destination.
  Future<void> openDashboard() => step('opening the dashboard tab', () async {
    await waitUntilVisible();
    await tap(ShellKeys.dashboardTab);
  });

  /// Switches to the settings destination.
  Future<void> openSettings() => step('opening the settings tab', () async {
    await waitUntilVisible();
    await tap(ShellKeys.settingsTab);
  });

  /// Starts a new document.
  ///
  /// Create is an action rather than a destination: it pushes the page table
  /// above the shell and leaves the previous destination selected underneath.
  Future<void> startCreation() => step('starting a new document', () async {
    await waitUntilVisible();
    await tap(ShellKeys.createTab);
  });
}

/// Drives the dashboard: recents, folders, search and the import entry point.
class DashboardRobot extends Robot {
  /// Creates the robot.
  const DashboardRobot(super.tester);

  @override
  Key get screenKey => DashboardKeys.screen;

  /// Waits until the dashboard has finished its initial load.
  ///
  /// Waits for the content list *or* the empty state, because an empty library
  /// is a legitimate landing state and a flow that only waited for content
  /// would hang on a fresh install.
  Future<void> waitUntilLoaded() => step('loading the dashboard', () async {
    await waitUntilVisible();
    await pumpUntilAnyOf(tester, [
      DashboardKeys.contentGrid,
      DashboardKeys.emptyState,
    ]);
  });

  /// Chooses the Dashboard thumbnail density through its visible menu.
  Future<void> chooseDisplaySize(Key option) =>
      step('changing the dashboard thumbnail size', () async {
        await waitUntilLoaded();
        await tap(DashboardKeys.displaySizeMenu);
        await tap(option);
        await tester.pump(const Duration(milliseconds: 200));
      });

  /// Number of columns used by the currently rendered library grid.
  int get gridColumnCount {
    final grid = tester.widget<SliverGrid>(
      find.byKey(DashboardKeys.contentGrid),
    );
    return (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
        .crossAxisCount;
  }

  /// Opens the document identified by [documentId].
  Future<void> openDocument(String documentId) =>
      step('opening document $documentId from the dashboard', () async {
        await waitUntilVisible();
        await tap(DashboardKeys.documentTile(documentId));
      });

  /// Enters selection mode by long-pressing [documentId].
  Future<void> selectDocument(String documentId) =>
      step('selecting document $documentId', () async {
        await waitUntilVisible();
        await tester.longPress(
          find.byKey(DashboardKeys.documentTile(documentId)),
        );
        await tester.pump();
        await waitFor(DashboardKeys.selectionToolbar);
      });

  /// Selects every visible eligible document.
  Future<void> selectAll() => step('selecting all visible documents', () async {
    await tap(DashboardKeys.selectAll);
    await tester.pump();
  });

  /// Archives the current selection once.
  Future<void> archiveSelection() => step('archiving the selection', () async {
    await tap(DashboardKeys.bulkArchive);
    await waitUntilGone(DashboardKeys.selectionToolbar);
  });

  /// Moves the current selection to Trash after explicit confirmation.
  Future<void> trashSelection() => step('trashing the selection', () async {
    await tap(DashboardKeys.bulkTrash);
    await waitFor(DashboardKeys.bulkTrashConfirm);
    await tap(DashboardKeys.bulkTrashConfirm);
    await waitUntilGone(DashboardKeys.selectionToolbar);
  });

  /// Waits for the visible document's bounded first-page preview surface.
  Future<void> waitForDocumentThumbnail(String documentId) => step(
    'loading the dashboard thumbnail for $documentId',
    () => waitFor(LibraryKeys.documentThumbnail(documentId)),
  );

  /// Creates a folder named [name].
  Future<void> createFolder(String name) =>
      step('creating folder "$name"', () async {
        await waitUntilVisible();
        await tap(DashboardKeys.createFolderButton);
        await waitFor(DashboardKeys.createFolderDialog);
        await type(DashboardKeys.createFolderField, name);
        await tap(DashboardKeys.createFolderConfirm);
        await waitUntilGone(DashboardKeys.createFolderDialog);
      });

  /// Opens the folder identified by [folderId].
  Future<void> openFolder(String folderId) =>
      step('opening folder $folderId', () async {
        await waitUntilVisible();
        await tap(DashboardKeys.folderTile(folderId));
      });

  /// Returns to the library root through the stable breadcrumb control.
  Future<void> openRoot() => step('returning to the library root', () async {
    await tap(DashboardKeys.breadcrumbRoot);
    await waitUntilLoaded();
  });

  /// Moves [name] to Trash, or cancels at the mandatory confirmation.
  Future<void> moveFolderToTrash(String name, {bool confirm = true}) => step(
    '${confirm ? 'moving' : 'not moving'} folder $name to Trash',
    () async {
      await tap(DashboardKeys.folderMenu(name));
      await tap(DashboardKeys.folderTrash);
      await waitFor(DashboardKeys.trashConfirmDialog);
      if (confirm) {
        await tap(DashboardKeys.trashConfirm);
        await waitUntilGone(DashboardKeys.trashConfirmDialog);
        final failure = find.byKey(DashboardKeys.trashMoveFailure);
        if (failure.evaluate().isNotEmpty) {
          final messages = tester
              .widgetList<Text>(
                find.descendant(of: failure, matching: find.byType(Text)),
              )
              .map((text) => text.data)
              .whereType<String>()
              .join(' ');
          fail('Moving $name to Trash failed: $messages');
        }
        await waitUntilGone(DashboardKeys.folderTile(name));
      } else {
        await tester.tap(find.text('Cancel'));
        await waitUntilGone(DashboardKeys.trashConfirmDialog);
      }
    },
  );

  /// Opens recoverable Trash from Collections.
  Future<void> openTrash() => step('opening Trash', () async {
    await tap(DashboardKeys.trashCollection);
    await waitFor(TrashKeys.screen);
  });

  /// Whether a named folder is currently visible.
  bool containsFolder(String name) => has(DashboardKeys.folderTile(name));

  /// Opens the import sources sheet.
  Future<void> openImportSheet() => step('opening the import sheet', () async {
    await waitUntilVisible();
    await tap(DashboardKeys.importPdfButton);
    await waitFor(ImportKeys.sheet);
  });

  /// Searches the library from the dashboard.
  ///
  /// The dashboard's field filters in place rather than opening a screen —
  /// there is a `/search` route, but nothing in the shell navigates to it — so
  /// this is the search a user actually performs.
  Future<void> search(String query) => step('searching for "$query"', () async {
    await waitUntilVisible();
    await type(DashboardKeys.searchField, query);
    // The query is debounced, so the wait has to outlast the debounce window
    // before the result can be believed.
    await tester.pump(const Duration(milliseconds: 600));
    await pumpUntilAnyOf(tester, [
      DashboardKeys.contentGrid,
      DashboardKeys.emptyState,
    ]);
  });

  /// Clears the query, restoring the unfiltered library.
  Future<void> clearSearch() => step('clearing the search', () async {
    await waitUntilVisible();
    await type(DashboardKeys.searchField, '');
    await tester.pump(const Duration(milliseconds: 600));
  });

  /// Document identifiers currently exposed by dashboard rows.
  List<String> get visibleDocumentIds => find
      .byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              '${DashboardKeys.documentTilePrefix}_',
            ),
      )
      .evaluate()
      .map(
        (element) => (element.widget.key! as ValueKey<String>).value.substring(
          DashboardKeys.documentTilePrefix.length + 1,
        ),
      )
      .toSet()
      .toList();

  /// Pulls the iCloud-backed dashboard refresh control.
  Future<void> refreshCloudLibrary() =>
      step('refreshing the iCloud library', () async {
        await waitUntilVisible();
        final indicator = tester.widget<RefreshIndicator>(
          find.byKey(CloudStorageKeys.libraryRefresh),
        );
        await indicator.onRefresh();
        await tester.pump();
      });

  /// Whether the dashboard is showing its empty state.
  bool get isEmpty => has(DashboardKeys.emptyState);
}

/// Drives recoverable Trash.
class TrashRobot extends Robot {
  /// Creates the robot.
  const TrashRobot(super.tester);

  @override
  Key get screenKey => TrashKeys.screen;

  /// Restores [trashId].
  Future<void> restore(String trashId) => step('restoring $trashId', () async {
    await tap(TrashKeys.restore(trashId));
    await tester.pump(const Duration(milliseconds: 200));
  });

  /// Permanently removes [trashId], explicitly confirming the warning.
  Future<void> purge(String trashId) =>
      step('permanently deleting $trashId', () async {
        await tap(TrashKeys.purge(trashId));
        await waitFor(TrashKeys.purgeDialog(trashId));
        await tester.tap(find.text('Delete permanently'));
        await tester.pump(const Duration(milliseconds: 200));
      });

  /// Identifiers of visible Trash rows.
  List<String> get visibleEntryIds => find
      .byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('trash_row_'),
      )
      .evaluate()
      .map(
        (element) => (element.widget.key! as ValueKey<String>).value.substring(
          'trash_row_'.length,
        ),
      )
      .toSet()
      .toList();
}

/// Drives the import sources sheet.
class ImportRobot extends Robot {
  /// Creates the robot.
  const ImportRobot(super.tester);

  @override
  Key get screenKey => ImportKeys.sheet;

  /// Imports through the file browser, which answers with the flow's fixture.
  ///
  /// Returns once the sheet has closed, which is what the import having
  /// finished looks like to the user.
  Future<void> importFromFiles() => step('importing from files', () async {
    await waitUntilVisible();
    await tap(ImportKeys.sourceFiles);
    await waitUntilGone(ImportKeys.sheet, timeout: const Duration(seconds: 60));
  });

  /// Imports through the photo library.
  Future<void> importFromGallery() =>
      step('importing from the photo library', () async {
        await waitUntilVisible();
        await tap(ImportKeys.sourceGallery);
      });
}

/// Drives the settings screen.
class SettingsRobot extends Robot {
  /// Creates the robot.
  const SettingsRobot(super.tester);

  @override
  Key get screenKey => SettingsKeys.screen;

  /// Chooses [optionName] for the choice setting carrying [settingKey].
  ///
  /// [optionName] is the enum value's own name — `dark`, `balanced` — not its
  /// visible label, because the label is user-visible text that moves and
  /// localises while the value's name does not.
  Future<void> choose(Key settingKey, String optionName) =>
      step('choosing $optionName', () async {
        await waitUntilVisible();
        await tap(settingKey);
        await waitFor(SettingsKeys.choiceSheet);
        final option = find.byKey(SettingsKeys.choiceOption(optionName));
        await tester.ensureVisible(option);
        await tester.pump();
        await tap(SettingsKeys.choiceOption(optionName));
        await waitUntilGone(SettingsKeys.choiceSheet);
      });

  /// Scrolls to the final Privacy Policy row and leaves the list at its end.
  Future<void> revealPrivacyPolicy() =>
      step('revealing the privacy policy with bottom spacing', () async {
        await waitUntilVisible();
        final list = find
            .descendant(
              of: find.byKey(SettingsKeys.screen),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.byKey(SettingsKeys.privacyPolicy),
          300,
          scrollable: list,
        );
        await tester.fling(list, const Offset(0, -300), 1000);
        await tester.pumpAndSettle();
      });

  /// Visible clearance below the final Privacy Policy row.
  double get privacyBottomClearance {
    final screenBottom = tester.getBottomLeft(find.byKey(screenKey)).dy;
    final privacyBottom = tester
        .getBottomLeft(find.byKey(SettingsKeys.privacyPolicy))
        .dy;
    return screenBottom - privacyBottom;
  }

  /// Chooses a recognition-language enum value by [optionName].
  Future<void> chooseRecognitionLanguage(String optionName) =>
      step('choosing recognition language $optionName', () async {
        await waitUntilVisible();
        await tap(SettingsKeys.ocrLanguage);
        await waitFor(SettingsKeys.ocrLanguageScreen);
        await tap(SettingsKeys.ocrLanguageOption(optionName));
        await waitUntilGone(SettingsKeys.ocrLanguageScreen);
      });

  /// Selects the deterministic folder supplied by the platform fake.
  Future<void> chooseDefaultSaveFolder() =>
      step('choosing a default save folder', () async {
        await waitUntilVisible();
        await tap(SettingsKeys.saveLocation);
        await waitFor(SettingsKeys.saveLocationScreen);
        await tap(SettingsKeys.saveLocationChooseFolder);
        await waitUntilGone(SettingsKeys.saveLocationScreen);
      });

  /// Keeps destination prompting enabled for every export.
  Future<void> askForSaveLocationEachTime() =>
      step('asking for a save location each time', () async {
        await waitUntilVisible();
        await tap(SettingsKeys.saveLocation);
        await waitFor(SettingsKeys.saveLocationScreen);
        await tap(SettingsKeys.saveLocationAskEachTime);
        await waitUntilGone(SettingsKeys.saveLocationScreen);
      });

  /// Opens storage details and refreshes the visible summary.
  Future<void> openStorageDetails() =>
      step('opening storage details', () async {
        await waitUntilVisible();
        await tap(SettingsKeys.storageInfo);
        await waitFor(SettingsKeys.storageScreen);
        await tap(SettingsKeys.storageRefresh);
      });

  /// Returns from a pushed Settings detail screen.
  Future<void> closeDetails() => step('closing settings details', () async {
    await tester.pageBack();
    await tester.pumpAndSettle();
    await waitUntilVisible();
  });

  /// Toggles the application lock.
  ///
  /// Authentication happens inside the use case in both directions, so this
  /// goes through the substituted authenticator whichever way it is being moved.
  Future<void> toggleAppLock() => step('toggling the app lock', () async {
    await waitUntilVisible();
    await tap(SettingsKeys.biometricLock);
    // The toggle re-reads what was actually stored rather than what was asked
    // for, so the settled state arrives a frame or two later.
    await tester.pump(const Duration(milliseconds: 200));
  });

  /// Opens the About screen.
  Future<void> openAbout() => step('opening About', () async {
    await waitUntilVisible();
    await tap(SettingsKeys.about);
    await waitFor(SettingsKeys.aboutScreen);
  });

  /// Opens the iOS-only storage-location screen.
  Future<void> openStorageLocation() =>
      step('opening storage location', () async {
        await waitUntilVisible();
        await tap(SettingsKeys.storageInfo);
        await waitFor(SettingsKeys.storageScreen);
        await tap(SettingsKeys.storageManageLocation);
      });
}
