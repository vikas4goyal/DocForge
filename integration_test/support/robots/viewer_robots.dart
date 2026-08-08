/// Robots for reading a document and acting on it: the viewer, the PDF editor
/// and the share sheet.
library;

import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_sharing/presentation/share_keys.dart';
import 'package:doc_scanly/features/document_viewer/presentation/viewer_keys.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/pdf_edit_keys.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/pdf_keys.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump.dart';
import 'robot.dart';

/// Drives the viewer.
///
/// The rendering surface itself is the real pdfrx widget — Tier 3 runs on a
/// device, where it works — so "the document opened" here means the real
/// renderer parsed the real file the flow produced.
class ViewerRobot extends Robot {
  /// Creates the robot.
  const ViewerRobot(super.tester);

  @override
  Key get screenKey => ViewerKeys.screen;

  /// Waits until the document is open and rendering.
  ///
  /// Waits for the page surface rather than for the screen alone: the screen
  /// appears immediately and spends the next moment loading, so a flow that
  /// stopped at the screen would assert against a spinner.
  Future<void> waitUntilOpen() => step('opening the document', () async {
    await waitUntilVisible();
    await waitUntilGone(
      ViewerKeys.loadingIndicator,
      timeout: const Duration(seconds: 60),
    );
    await waitFor(ViewerKeys.pageView);
  });

  /// Unlocks a protected document with [password].
  Future<void> unlockWith(String password) =>
      step('unlocking the document', () async {
        await waitFor(ViewerKeys.passwordField);
        await type(ViewerKeys.passwordField, password);
        await tap(ViewerKeys.unlockButton);
      });

  /// Jumps to page [number].
  Future<void> goToPage(int number) =>
      step('jumping to page $number', () async {
        await waitUntilVisible();
        await tap(ViewerKeys.pageJumpButton);
        await type(ViewerKeys.jumpToPageField, '$number');
        await tap(ViewerKeys.pageJumpConfirm);
        await tester.pump(const Duration(milliseconds: 300));
      });

  /// Opens the share sheet.
  Future<void> openShare() => step('opening the share sheet', () async {
    await waitUntilVisible();
    await tap(ViewerKeys.shareButton);
    await waitFor(ShareKeys.sheet);
  });

  /// Toggles the document's persisted favourite marker.
  Future<void> toggleFavourite() => step('toggling favourite', () async {
    await waitUntilOpen();
    await tap(ViewerKeys.favouriteButton);
    await tester.pump(const Duration(milliseconds: 200));
  });

  /// Renames the open document through Viewer's reviewed lifecycle action.
  Future<void> rename(String name) => step('renaming to "$name"', () async {
    await _openAction(ViewerKeys.renameButton);
    await type(LibraryKeys.documentRenameField, name);
    await tap(LibraryKeys.documentRenameConfirm);
    await tester.pump(const Duration(milliseconds: 200));
  });

  /// Moves the open document to the first folder offered by the picker.
  Future<({String id, String name})> moveToFirstFolder() =>
      step('moving to the first available folder', () async {
        await _openAction(ViewerKeys.moveButton);
        await waitFor(LibraryKeys.documentMovePicker);
        final keys = find
            .byWidgetPredicate(
              (widget) =>
                  widget.key is ValueKey<String> &&
                  (widget.key! as ValueKey<String>).value.startsWith(
                    'document_move_folder_',
                  ) &&
                  (widget.key! as ValueKey<String>).value !=
                      'document_move_folder_root',
            )
            .evaluate()
            .map((element) => (element.widget.key! as ValueKey<String>).value)
            .toSet()
            .toList();
        expect(keys, hasLength(1));
        final folderId = keys.single.substring('document_move_folder_'.length);
        final folderName = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byKey(LibraryKeys.documentMoveFolder(folderId)),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data)
            .whereType<String>()
            .first;
        await tap(LibraryKeys.documentMoveFolder(folderId));
        await tap(LibraryKeys.documentMoveConfirm);
        await waitUntilGone(LibraryKeys.documentMovePicker);
        return (id: folderId, name: folderName);
      });

  /// Duplicates the open document using the reviewed destination dialog.
  Future<void> duplicate({required String name}) =>
      step('duplicating as "$name"', () async {
        await _openAction(ViewerKeys.duplicateButton);
        await waitFor(LibraryKeys.documentDuplicateDialog);
        await type(LibraryKeys.documentDuplicateName, name);
        await tap(LibraryKeys.documentDuplicateConfirm);
        await waitUntilGone(LibraryKeys.documentDuplicateDialog);
      });

  /// Archives the open document.
  Future<void> archive() => step('archiving the document', () async {
    await _openAction(ViewerKeys.archiveButton);
    await tester.pump(const Duration(milliseconds: 200));
  });

  /// Moves the open document to recoverable Trash and confirms the dialog.
  Future<void> moveToTrash() => step('moving the document to Trash', () async {
    await _openAction(ViewerKeys.moveToTrashButton);
    await waitFor(LibraryKeys.documentDeleteConfirmDialog);
    await tap(LibraryKeys.documentDeleteConfirmButton);
    await waitUntilGone(LibraryKeys.documentDeleteConfirmDialog);
  });

  /// Opens metadata and lifecycle actions over the current PDF.
  Future<void> openDetails() => step('opening document details', () async {
    await waitUntilOpen();
    await tap(ViewerKeys.actionsMenu);
    await tap(ViewerKeys.documentDetailsButton);
  });

  /// Prints, which goes straight to the system dialogue rather than the sheet.
  Future<void> print() => step('printing the document', () async {
    await waitUntilVisible();
    if (has(ViewerKeys.actionsMenu)) {
      await tap(ViewerKeys.actionsMenu);
    }
    await tap(ViewerKeys.printButton);
    await tester.pump(const Duration(milliseconds: 300));
  });

  /// Opens the focused compression workflow.
  Future<void> openCompress() => step('opening PDF compression', () async {
    await waitUntilVisible();
    await tap(ViewerKeys.actionsMenu);
    await tap(ViewerKeys.compressButton);
    await waitFor(PdfEditKeys.compressScreen);
  });

  /// Opens the focused split and output-naming workflow.
  Future<void> openSplit() => step('opening PDF split', () async {
    await waitUntilVisible();
    await tap(ViewerKeys.actionsMenu);
    await tap(ViewerKeys.splitButton);
    await waitFor(PdfEditKeys.pageNamingScreen);
  });

  /// Opens the focused watermark workflow.
  Future<void> openWatermark() =>
      _openOperation(ViewerKeys.watermarkButton, 'opening watermark settings');

  /// Opens the focused password workflow.
  Future<void> openPassword() =>
      _openOperation(ViewerKeys.passwordButton, 'opening password settings');

  /// Opens contextual page selection for derived page operations.
  Future<void> openPageManagement() =>
      _openOperation(ViewerKeys.managePagesButton, 'opening page management');

  Future<void> _openOperation(Key key, String description) =>
      step(description, () async {
        await waitUntilVisible();
        await tap(ViewerKeys.actionsMenu);
        await tap(key);
        await waitFor(PdfEditKeys.screen);
      });

  Future<void> _openAction(Key key) async {
    await waitUntilOpen();
    await tap(ViewerKeys.actionsMenu);
    await tap(key);
  }

  /// Returns to whichever screen opened the viewer.
  Future<void> goBack() => step('leaving the viewer', () async {
    await waitUntilVisible();
    await tester.pageBack();
    await tester.pump();
  });

  /// Whether the viewer is showing a failure.
  bool get hasFailed => has(ViewerKeys.errorView);
}

/// Drives the dedicated full-page Compress PDF route.
class CompressPdfRobot extends Robot {
  /// Creates the robot.
  const CompressPdfRobot(super.tester);

  @override
  Key get screenKey => PdfEditKeys.compressScreen;

  /// Waits for initial exact-size calculation to settle.
  Future<void> waitUntilCalculated() =>
      step('calculating compressed size', () async {
        await waitUntilVisible();
        await waitUntilGone(
          PdfEditKeys.compressProgressDialog,
          timeout: const Duration(seconds: 60),
        );
        await waitFor(PdfEditKeys.compressSizeStatus);
      });

  /// Applies a page override and then resets all overrides.
  Future<void> overrideAndResetFirstPage() =>
      step('overriding and resetting page quality', () async {
        await tap(PdfEditKeys.compressPageQuality(0));
        await tester.drag(
          find.byKey(PdfEditKeys.compressPageSlider),
          const Offset(-100, 0),
        );
        await tester.tap(find.text('Apply'));
        await tester.pump();
        await tap(PdfEditKeys.compressResetAll);
      });

  /// Opens and closes a verified read-only candidate preview.
  Future<void> previewAndClose() => step('previewing compressed PDF', () async {
    await tap(PdfEditKeys.compressPreview);
    await waitFor(
      PdfKeys.temporaryPreviewScreen,
      timeout: const Duration(seconds: 60),
    );
    await tap(PdfKeys.temporaryPreviewClose);
    await waitUntilVisible();
  });

  /// Cancels candidate preparation while keeping the compression choices.
  Future<void> cancelPreview() =>
      step('cancelling compression preview', () async {
        await tap(PdfEditKeys.compressPreview);
        await waitFor(PdfEditKeys.compressProgressDialog);
        await tap(PdfEditKeys.compressCancelJob);
        await waitUntilGone(PdfEditKeys.compressProgressDialog);
        await waitUntilVisible();
      });

  /// Exercises the all-pages-100 warning and returns to quality controls.
  Future<void> reviewAll100AndAdjust() =>
      step('reviewing all-pages-100 warning', () async {
        await tester.drag(
          find.byKey(PdfEditKeys.compressQualitySlider),
          const Offset(1000, 0),
        );
        await tester.pump();
        await tap(PdfEditKeys.compressSave);
        await waitFor(PdfEditKeys.compressPassThroughDialog);
        await tap(PdfEditKeys.compressAdjustQuality);
        await waitUntilVisible();
        await tester.drag(
          find.byKey(PdfEditKeys.compressQualitySlider),
          const Offset(-120, 0),
        );
        await tester.pump();
      });

  /// Commits a collision-safe copy and waits for its Viewer.
  Future<void> saveAsCopy() => step('saving compressed copy', () async {
    await tap(PdfEditKeys.compressSave);
    await waitFor(PdfEditKeys.compressDestinationDialog);
    await tap(PdfEditKeys.compressDestinationCopy);
    await _continueNoBenefitIfNeeded();
    await ViewerRobot(tester).waitUntilOpen();
  });

  /// Starts Save during recalculation, cancels it, then retries as a copy.
  Future<void> cancelAndRetryAsCopy() =>
      step('cancelling and retrying compressed copy', () async {
        await tester.drag(
          find.byKey(PdfEditKeys.compressQualitySlider),
          const Offset(-120, 0),
        );
        await tester.pump();
        await tap(PdfEditKeys.compressSave);
        await waitFor(PdfEditKeys.compressDestinationDialog);
        await tap(PdfEditKeys.compressDestinationCopy);
        await waitFor(PdfEditKeys.compressProgressDialog);
        await tap(PdfEditKeys.compressCancelJob);
        await waitUntilGone(PdfEditKeys.compressProgressDialog);
        await waitUntilVisible();
        await tap(PdfEditKeys.compressSave);
        await waitFor(PdfEditKeys.compressDestinationDialog);
        await tap(PdfEditKeys.compressDestinationCopy);
        await _continueNoBenefitIfNeeded();
        await ViewerRobot(tester).waitUntilOpen();
      });

  /// Safely overwrites the source and waits for its refreshed Viewer.
  Future<void> overwriteOriginal() =>
      step('overwriting with compressed PDF', () async {
        await tap(PdfEditKeys.compressSave);
        await waitFor(PdfEditKeys.compressDestinationDialog);
        await tap(PdfEditKeys.compressDestinationOverwrite);
        await _continueNoBenefitIfNeeded();
        await ViewerRobot(tester).waitUntilOpen();
      });

  Future<void> _continueNoBenefitIfNeeded() async {
    await pumpUntilAnyOf(tester, <Key>[
      PdfEditKeys.compressNoBenefitDialog,
      ViewerKeys.screen,
    ], timeout: const Duration(seconds: 60));
    if (has(PdfEditKeys.compressNoBenefitDialog)) {
      await tap(PdfEditKeys.compressContinueNoBenefit);
    }
  }
}

/// Drives the PDF editor.
class PdfEditRobot extends Robot {
  /// Creates the robot.
  const PdfEditRobot(super.tester);

  @override
  Key get screenKey => PdfEditKeys.screen;

  /// Waits until the document is loaded and its pages are listed.
  Future<void> waitUntilLoaded() => step('loading the editor', () async {
    await waitUntilVisible();
    await waitUntilGone(
      PdfEditKeys.progress,
      timeout: const Duration(seconds: 60),
    );
    await pumpUntilAnyOf(tester, [PdfEditKeys.pageGrid, PdfEditKeys.pageList]);
  });

  /// Waits for a focused whole-document operation reached from Viewer.
  Future<void> waitUntilFocused() =>
      step('loading the focused PDF operation', () async {
        await waitUntilVisible();
        await waitUntilGone(
          PdfEditKeys.progress,
          timeout: const Duration(seconds: 60),
        );
        await pumpUntilAnyOf(tester, [
          PdfEditKeys.operationSheet,
          PdfEditKeys.compressCopyButton,
          PdfEditKeys.compressButton,
          PdfEditKeys.watermarkTextField,
          PdfEditKeys.protectPasswordField,
          PdfEditKeys.removePasswordButton,
        ]);
      });

  /// Waits for the dedicated split naming screen.
  Future<void> waitUntilSplitNaming() =>
      step('loading split output naming', () async {
        await waitFor(PdfEditKeys.pageNamingScreen);
        await waitFor(PdfEditKeys.splitFirstNameField);
        await waitFor(PdfEditKeys.splitSecondNameField);
      });

  /// Selects the page at [index], zero-based.
  Future<void> selectPage(int index) =>
      step('selecting page ${index + 1}', () async {
        await waitUntilVisible();
        await tap(PdfEditKeys.page(index));
      });

  /// Rotates the selected page.
  Future<void> rotateSelected() => step('rotating the selection', () async {
    if (has(PdfEditKeys.actionsMenu)) await tap(PdfEditKeys.actionsMenu);
    await tap(PdfEditKeys.rotateButton);
    await waitFor(PdfEditKeys.review);
    await tap(PdfEditKeys.confirm);
    await waitUntilGone(
      PdfEditKeys.progress,
      timeout: const Duration(seconds: 60),
    );
  });

  /// Deletes the selected page, confirming the prompt.
  Future<void> deleteSelected() => step('deleting the selection', () async {
    await tap(PdfEditKeys.deleteButton);
    await tap(PdfEditKeys.deleteConfirmButton);
    await waitUntilGone(
      PdfEditKeys.progress,
      timeout: const Duration(seconds: 60),
    );
  });

  /// Protects the document with [password].
  Future<void> protectWith(String password) =>
      step('protecting the document', () async {
        await type(PdfEditKeys.protectPasswordField, password);
        await tap(PdfEditKeys.protectConfirmButton);
        await waitFor(PdfEditKeys.review);
        await tap(PdfEditKeys.confirm);
        await waitUntilGone(
          PdfEditKeys.progress,
          timeout: const Duration(seconds: 60),
        );
        await waitFor(PdfEditKeys.result);
      });

  /// Confirms focused compression once and waits for its visible result.
  Future<void> compress() => step('compressing the document once', () async {
    await tap(PdfEditKeys.compressButton);
    await waitFor(PdfEditKeys.review);
    await tap(PdfEditKeys.confirm);
    await waitFor(PdfEditKeys.result, timeout: const Duration(seconds: 60));
  });

  /// Reviews both split names and creates the two outputs once.
  Future<void> split() => step('splitting the document once', () async {
    await tap(PdfEditKeys.splitConfirmButton);
    await waitFor(PdfEditKeys.review);
    await tap(PdfEditKeys.confirm);
    await waitFor(PdfEditKeys.result, timeout: const Duration(seconds: 60));
  });

  /// Applies [text] as a watermark and waits for the in-place result.
  Future<void> watermarkWith(String text) =>
      step('watermarking the document once', () async {
        await type(PdfEditKeys.watermarkTextField, text);
        await tap(PdfEditKeys.watermarkConfirmButton);
        await waitFor(PdfEditKeys.review);
        await tap(PdfEditKeys.confirm);
        await waitFor(PdfEditKeys.result, timeout: const Duration(seconds: 60));
      });

  /// Extracts the selected pages and waits for the derived document result.
  Future<void> extractSelected() =>
      step('extracting the selected pages once', () async {
        if (has(PdfEditKeys.pageExtract(0))) {
          await tap(PdfEditKeys.pageExtract(0));
        } else {
          if (has(PdfEditKeys.actionsMenu)) await tap(PdfEditKeys.actionsMenu);
          await tap(PdfEditKeys.extractButton);
        }
        await waitFor(PdfEditKeys.review);
        await tap(PdfEditKeys.confirm);
        await waitFor(PdfEditKeys.result, timeout: const Duration(seconds: 60));
      });

  /// Finishes a visible derived-document result.
  Future<void> finishResult() => step('finishing the edit result', () async {
    await tap(PdfEditKeys.resultDone);
  });

  /// Closes the editor and returns to the viewer.
  Future<void> close() => step('closing the editor', () async {
    await tester.binding.handlePopRoute();
    await tester.pump();
  });
}

/// Drives the share sheet.
///
/// Every action here ends at a substituted boundary. The real share sheet,
/// print dialogue and destination picker are outside anything the framework can
/// drive, so a flow asserts on what arrived at the fake: the right file, the
/// right metadata, the right call. That is stated as a Non-Goal rather than
/// hidden, and it is the small residue of genuinely manual testing.
class ShareRobot extends Robot {
  /// Creates the robot.
  const ShareRobot(super.tester);

  @override
  Key get screenKey => ShareKeys.sheet;

  /// Shares the document as a PDF.
  Future<void> sharePdf() => step('sharing the PDF', () async {
    await waitUntilVisible();
    await tap(ShareKeys.pdfButton);
    await _waitUntilHandedOver();
  });

  /// Shares the pages as images.
  Future<void> shareImages() => step('sharing the pages as images', () async {
    await waitUntilVisible();
    await tap(ShareKeys.imagesButton);
    await _waitUntilHandedOver();
  });

  /// Prints through the sheet.
  Future<void> print() => step('printing from the sheet', () async {
    await waitUntilVisible();
    await tap(ShareKeys.printButton);
    await _waitUntilHandedOver();
  });

  /// Exports to the destination the substituted picker answers with.
  Future<void> export() => step('exporting the document', () async {
    await waitUntilVisible();
    await tap(ShareKeys.exportButton);
    await _waitUntilHandedOver();
  });

  /// Cancels export without presenting the cancellation as an error.
  Future<void> cancelExport() => step('cancelling export', () async {
    await waitUntilVisible();
    await tap(ShareKeys.exportButton);
    await tester.pumpAndSettle();
    expect(find.text('Export cancelled. No file was written.'), findsOneWidget);
    expect(find.byKey(ShareKeys.errorView), findsNothing);
  });

  /// Observes an export failure and returns through its recovery control.
  Future<void> recoverFromExportFailure() =>
      step('recovering from export failure', () async {
        await waitUntilVisible();
        await tap(ShareKeys.exportButton);
        await waitFor(ShareKeys.errorView);
        await tap(ShareKeys.errorRetryButton);
        await tester.pumpAndSettle();
        await waitFor(ShareKeys.exportButton);
      });

  /// Whether the removed extracted-text action has accidentally returned.
  bool get offersExtractedText => tester.any(find.text('Share extracted text'));

  /// Waits for the sheet to close, which is what a completed hand-off looks
  /// like: the sheet dismisses once the system has the content, rather than
  /// leaving the user looking at options for something already sent.
  Future<void> _waitUntilHandedOver() =>
      waitUntilGone(ShareKeys.sheet, timeout: const Duration(seconds: 60));
}
