/// Robots for reading and organising the library: the document list, a folder's
/// contents, one document's detail screen, and search.
library;

import 'package:doc_forge/features/document_library/presentation/library_keys.dart';
import 'package:doc_forge/features/document_search/presentation/search_keys.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump.dart';
import 'robot.dart';

/// Drives a document list — all documents, favourites or the archive.
///
/// One robot for all three, because they are one screen under a different
/// filter. A flow says which list it is on by how it navigated there.
class DocumentListRobot extends Robot {
  /// Creates the robot.
  const DocumentListRobot(super.tester);

  @override
  Key get screenKey => LibraryKeys.documentListScreen;

  /// Waits until the list has loaded, empty or not.
  ///
  /// Expressed as "the loading indicator has gone" rather than "content has
  /// arrived", because an empty library is a legitimate loaded state and a
  /// robot that waited for a row would hang while proving the empty state.
  Future<void> waitUntilLoaded() => step('loading the document list', () async {
    await waitUntilVisible();
    await waitUntilGone(LibraryKeys.documentListLoading);
  });

  /// Opens the document identified by [documentId].
  Future<void> openDocument(String documentId) =>
      step('opening document $documentId', () async {
        await waitUntilVisible();
        await tap(LibraryKeys.documentListItem(documentId));
      });

  /// Whether the document identified by [documentId] is in the list.
  ///
  /// The primary assertion of the import and organise flows: "it appears in the
  /// library" and "it is gone from the library" are exactly what the user sees.
  bool contains(String documentId) =>
      has(LibraryKeys.documentListItem(documentId));

  /// Whether the list is showing its empty state.
  bool get isEmpty => has(LibraryKeys.documentListEmptyState);

  /// The identifiers of every document row currently on screen.
  ///
  /// Read out of the row keys, which carry the identifier by construction. This
  /// is how a flow gets from "something was imported" to "the row I mean"
  /// without reaching past the widget tree into the database — which would make
  /// it a Tier-2 test wearing a Tier-3 costume.
  List<String> get visibleDocumentIds => find
      .byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              LibraryKeys.documentListItemPrefix,
            ),
      )
      .evaluate()
      .map(
        (element) => ((element.widget.key! as ValueKey<String>).value)
            .substring(LibraryKeys.documentListItemPrefix.length + 1),
      )
      // Distinct, because a list wraps each row in several widgets that carry
      // the row's key: counting elements would report one document as four.
      .toSet()
      .toList();

  /// How many document rows are showing.
  int get documentCount => visibleDocumentIds.length;
}

/// Drives a folder's contents.
///
/// Distinct from [DocumentListRobot] even though the screen underneath is the
/// same one: a flow that navigated into a folder needs to prove it *arrived*,
/// and the list's own key cannot say which of four routes rendered it.
class FolderDetailRobot extends Robot {
  /// Creates the robot.
  const FolderDetailRobot(super.tester);

  @override
  Key get screenKey => LibraryKeys.folderDetailScreen;

  /// Opens the document identified by [documentId] from inside the folder.
  Future<void> openDocument(String documentId) =>
      step('opening document $documentId inside a folder', () async {
        await waitUntilVisible();
        await tap(LibraryKeys.documentListItem(documentId));
      });

  /// Whether the folder contains the document identified by [documentId].
  bool contains(String documentId) =>
      has(LibraryKeys.documentListItem(documentId));
}

/// Drives one document's detail screen and everything it can do to it.
class DocumentDetailRobot extends Robot {
  /// Creates the robot.
  const DocumentDetailRobot(super.tester);

  @override
  Key get screenKey => LibraryKeys.documentDetailScreen;

  /// Opens the document for reading.
  Future<void> open() => step('opening the document for reading', () async {
    await waitUntilVisible();
    await tap(LibraryKeys.documentOpenButton);
  });

  /// Renames the document to [name].
  Future<void> rename(String name) => step('renaming to "$name"', () async {
    await waitUntilVisible();
    await _openMenuIfPresent();
    await tap(LibraryKeys.documentRenameButton);
    await type(LibraryKeys.documentRenameField, name);
    await tap(LibraryKeys.documentRenameConfirm);
    await tester.pump(const Duration(milliseconds: 200));
  });

  /// Toggles the favourite marker.
  Future<void> toggleFavourite() => step('toggling favourite', () async {
    await waitUntilVisible();
    await tap(LibraryKeys.documentFavouriteToggle);
    await tester.pump(const Duration(milliseconds: 200));
  });

  /// Moves the document into the folder identified by [folderId].
  ///
  /// A null [folderId] chooses "no folder", which unfiles the document — a
  /// distinct outcome from cancelling, which is why the picker returns a sealed
  /// choice rather than a nullable folder.
  Future<void> moveToFolder(String? folderId) =>
      step('moving to folder ${folderId ?? 'none'}', () async {
        await waitUntilVisible();
        await _openMenuIfPresent();
        await tap(LibraryKeys.documentMoveButton);
        await waitFor(LibraryKeys.documentMoveDialog);
        await tap(
          folderId == null
              ? LibraryKeys.documentMoveOptionNone
              : LibraryKeys.documentMoveOption(folderId),
        );
        await waitUntilGone(LibraryKeys.documentMoveDialog);
      });

  /// Archives the document.
  Future<void> archive() => step('archiving the document', () async {
    await waitUntilVisible();
    await _openMenuIfPresent();
    await tap(LibraryKeys.documentArchiveButton);
    await tester.pump(const Duration(milliseconds: 200));
  });

  /// Restores the document from the archive.
  Future<void> restore() => step('restoring the document', () async {
    await waitUntilVisible();
    await _openMenuIfPresent();
    await tap(LibraryKeys.documentRestoreButton);
    await tester.pump(const Duration(milliseconds: 200));
  });

  /// Deletes the document permanently, confirming the dialog.
  ///
  /// The dialog returns true only on explicit confirmation — the barrier, back
  /// and cancel all return false — so an accidental dismissal cannot delete
  /// anything, and this drives the one path that can.
  Future<void> deletePermanently() =>
      step('deleting the document permanently', () async {
        await waitUntilVisible();
        await _openMenuIfPresent();
        await tap(LibraryKeys.documentDeleteButton);
        await waitFor(LibraryKeys.documentDeleteConfirmDialog);
        await tap(LibraryKeys.documentDeleteConfirmButton);
        await waitUntilGone(LibraryKeys.documentDeleteConfirmDialog);
      });

  /// Whether the document is marked as password protected.
  bool get isProtected => has(LibraryKeys.documentProtectedBadge);

  /// Opens the overflow menu when the actions live behind one.
  ///
  /// The detail screen shows some actions inline and folds the rest into a
  /// menu depending on width, so a robot that always opened it would fail on a
  /// tablet and one that never did would fail on a phone.
  Future<void> _openMenuIfPresent() async {
    if (has(LibraryKeys.documentDetailMenu)) {
      await tap(LibraryKeys.documentDetailMenu);
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
}

/// Drives the folder list.
class FolderListRobot extends Robot {
  /// Creates the robot.
  const FolderListRobot(super.tester);

  @override
  Key get screenKey => LibraryKeys.folderListScreen;

  /// Creates a folder named [name].
  Future<void> createFolder(String name) =>
      step('creating folder "$name"', () async {
        await waitUntilVisible();
        await tap(LibraryKeys.folderCreateButton);
        await type(LibraryKeys.folderNameField, name);
        await tap(LibraryKeys.folderNameConfirm);
        await tester.pump(const Duration(milliseconds: 200));
      });

  /// Opens the folder identified by [folderId].
  Future<void> openFolder(String folderId) =>
      step('opening folder $folderId', () async {
        await waitUntilVisible();
        await tap(LibraryKeys.folderListItem(folderId));
      });

  /// Renames the folder identified by [folderId] to [name].
  Future<void> renameFolder(String folderId, String name) =>
      step('renaming folder $folderId to "$name"', () async {
        await waitUntilVisible();
        await tap(LibraryKeys.folderMenuButton(folderId));
        await tap(LibraryKeys.folderMenuRename);
        await type(LibraryKeys.folderNameField, name);
        await tap(LibraryKeys.folderNameConfirm);
        await tester.pump(const Duration(milliseconds: 200));
      });

  /// Whether the folder identified by [folderId] is listed.
  bool contains(String folderId) => has(LibraryKeys.folderListItem(folderId));
}

/// Drives search.
class SearchRobot extends Robot {
  /// Creates the robot.
  const SearchRobot(super.tester);

  @override
  Key get screenKey => SearchKeys.screen;

  /// Searches for [query] and waits for the results to settle.
  ///
  /// Waits for results *or* the empty state, because "nothing matched" is a
  /// legitimate outcome the search spec requires the screen to show, and a
  /// robot that only waited for results would hang while proving it.
  Future<void> search(String query) => step('searching for "$query"', () async {
    await waitUntilVisible();
    await type(SearchKeys.inputField, query);
    // The query is debounced, which is the reason search uses a Bloc rather
    // than a Cubit; the wait has to outlast the debounce window.
    await tester.pump(const Duration(milliseconds: 600));
    await pumpUntilAnyOf(tester, [
      SearchKeys.resultsList,
      SearchKeys.emptyState,
    ]);
  });

  /// Opens the result for the document identified by [documentId].
  Future<void> openResult(String documentId) =>
      step('opening search result $documentId', () async {
        await tap(SearchKeys.resultRow(documentId));
      });

  /// Clears the query.
  Future<void> clear() => step('clearing the search', () async {
    await tap(SearchKeys.clearButton);
  });

  /// Whether search found nothing.
  bool get foundNothing => has(SearchKeys.emptyState);
}
