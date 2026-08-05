/// Robots for reading a document and acting on it: the viewer, the PDF editor
/// and the share sheet.
library;

import 'package:doc_scanly/features/document_sharing/presentation/share_keys.dart';
import 'package:doc_scanly/features/document_viewer/presentation/viewer_keys.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/pdf_edit_keys.dart';
import 'package:flutter/widgets.dart';

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

  /// Prints, which goes straight to the system dialogue rather than the sheet.
  Future<void> print() => step('printing the document', () async {
    await waitUntilVisible();
    if (has(ViewerKeys.actionsMenu)) {
      await tap(ViewerKeys.actionsMenu);
    }
    await tap(ViewerKeys.printButton);
    await tester.pump(const Duration(milliseconds: 300));
  });

  /// Opens the PDF editor.
  Future<void> openEditor() => step('opening the PDF editor', () async {
    await waitUntilVisible();
    if (has(ViewerKeys.actionsMenu)) {
      await tap(ViewerKeys.actionsMenu);
    }
    await tap(ViewerKeys.editButton);
    await waitFor(PdfEditKeys.screen);
  });

  /// Returns to whichever screen opened the viewer.
  Future<void> goBack() => step('leaving the viewer', () async {
    await waitUntilVisible();
    await tester.pageBack();
    await tester.pump();
  });

  /// Whether the viewer is showing a failure.
  bool get hasFailed => has(ViewerKeys.errorView);
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
    await waitFor(PdfEditKeys.pageGrid);
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
      });

  /// Closes the editor and returns to the viewer.
  Future<void> close() => step('closing the editor', () async {
    await tester.pageBack();
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

  /// Shares the recognised text.
  Future<void> shareText() => step('sharing the recognised text', () async {
    await waitUntilVisible();
    await tap(ShareKeys.textButton);
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

  /// Whether the sheet is telling the user there is no recognised text.
  bool get offersNoText => has(ShareKeys.noTextMessage);

  /// Waits for the sheet to close, which is what a completed hand-off looks
  /// like: the sheet dismisses once the system has the content, rather than
  /// leaving the user looking at options for something already sent.
  Future<void> _waitUntilHandedOver() =>
      waitUntilGone(ShareKeys.sheet, timeout: const Duration(seconds: 60));
}
