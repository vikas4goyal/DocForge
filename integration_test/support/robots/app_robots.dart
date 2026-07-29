/// Robots for the screens that stand around the application: onboarding, the
/// lock, the tab shell, the dashboard and settings.
library;

import 'package:doc_forge/features/app_security/presentation/security_keys.dart';
import 'package:doc_forge/features/app_settings/presentation/settings_keys.dart';
import 'package:doc_forge/features/app_shell/presentation/shell_keys.dart';
import 'package:doc_forge/features/document_import/presentation/import_keys.dart';
import 'package:doc_forge/features/document_library/presentation/library_dashboard_keys.dart';
import 'package:doc_forge/features/document_library/presentation/library_keys.dart';
import 'package:doc_forge/features/onboarding/presentation/onboarding_keys.dart';
import 'package:flutter/widgets.dart';
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
      DashboardKeys.contentList,
      DashboardKeys.emptyState,
    ]);
  });

  /// Opens the document identified by [documentId].
  Future<void> openDocument(String documentId) =>
      step('opening document $documentId from the dashboard', () async {
        await waitUntilVisible();
        await tap(LibraryKeys.documentListItem(documentId));
      });

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
        await tap(DashboardKeys.folderRow(folderId));
      });

  /// Opens the import sources sheet.
  Future<void> openImportSheet() => step('opening the import sheet', () async {
    await waitUntilVisible();
    await tap(DashboardKeys.importPdfButton);
    await waitFor(ImportKeys.sheet);
  });

  /// Opens search from the dashboard's search field.
  ///
  /// Opens only: the query itself is typed through `SearchRobot`, because the
  /// dashboard's field is an entry point to the search screen rather than a
  /// field that searches in place.
  Future<void> openSearch() => step('opening search', () async {
    await waitUntilVisible();
    await tap(DashboardKeys.searchField);
  });

  /// Whether the dashboard is showing its empty state.
  bool get isEmpty => has(DashboardKeys.emptyState);
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
        await tap(SettingsKeys.choiceOption(optionName));
        await waitUntilGone(SettingsKeys.choiceSheet);
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
}
