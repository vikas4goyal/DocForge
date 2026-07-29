/// Robots for the creation journey: capture, crop, enhance, the page table and
/// generation.
///
/// Crop and enhance are reached by *tapping*, never by URL, because
/// `openPageCrop` and `openPageEnhance` are imperative `Navigator.push` calls
/// that no route addresses. That is the correct level for Tier 3 in any case —
/// it is how a user reaches them — and it is why no routing change was proposed
/// to accommodate the suite (`design.md` D5).
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/features/document_creation/presentation/creation_keys.dart';
import 'package:doc_forge/features/document_scanning/presentation/scan_keys.dart';
import 'package:doc_forge/features/image_enhancement/presentation/enhance_keys.dart';
import 'package:doc_forge/features/pdf_generation/presentation/pdf_keys.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump.dart';
import 'robot.dart';

/// Drives the camera capture screen.
///
/// The camera itself is substituted, so a "capture" writes a fixture image and
/// returns its path. Everything above that — the counter, the batch toggle, the
/// exit to review — is the real screen.
class CaptureRobot extends Robot {
  /// Creates the robot.
  const CaptureRobot(super.tester);

  @override
  Key get screenKey => ScanKeys.cameraScreen;

  /// Captures [count] pages.
  ///
  /// Waits a frame between shots rather than firing them together: the screen
  /// writes each capture to disk before accepting the next, and a burst would
  /// be testing the tester's timing rather than the application's.
  Future<void> capturePages(int count) =>
      step('capturing $count page(s)', () async {
        await waitUntilVisible();
        for (var i = 0; i < count; i++) {
          await tap(ScanKeys.shutterButton);
          await tester.pump(const Duration(milliseconds: 200));
        }
      });

  /// Leaves capture for the review list.
  Future<void> finish() => step('finishing capture', () async {
    await tap(ScanKeys.doneButton);
  });

  /// Abandons capture without keeping anything.
  Future<void> cancel() => step('cancelling capture', () async {
    await tap(ScanKeys.captureCancelButton);
  });
}

/// Drives the crop and rotate editor.
class CropRobot extends Robot {
  /// Creates the robot.
  const CropRobot(super.tester);

  @override
  Key get screenKey => ScanKeys.cropScreen;

  /// Accepts the crop as offered and continues to enhancement.
  ///
  /// The substituted detector returns the full page, which is also what the
  /// spec requires when edges cannot be found, so accepting it exercises a real
  /// path rather than a test-only one.
  ///
  /// Uses the *next* control rather than the confirm control: confirm applies
  /// the crop in place and stays, next is what leaves the screen with the page.
  Future<void> acceptAndContinue() => step('accepting the crop', () async {
    await waitUntilVisible();
    await tap(ScanKeys.cropNextButton);
  });

  /// Rotates the page by dragging the rotation slider.
  Future<void> rotate({double by = 60}) => step('rotating the page', () async {
    await waitUntilVisible();
    await tester.drag(find.byKey(ScanKeys.cropRotationSlider), Offset(by, 0));
    await tester.pump();
  });

  /// Returns every layer to its default.
  Future<void> reset() => step('resetting the crop', () async {
    await tap(ScanKeys.cropResetButton);
  });

  /// Leaves without applying anything.
  Future<void> cancel() => step('cancelling the crop', () async {
    await tap(ScanKeys.cropCancelButton);
  });
}

/// Drives the enhancement editor.
class EnhanceRobot extends Robot {
  /// Creates the robot.
  const EnhanceRobot(super.tester);

  @override
  Key get screenKey => EnhanceKeys.screen;

  /// Selects the filter carrying [filterKey].
  ///
  /// Takes the key rather than the enum so a flow names the control the spec
  /// names, and so this file does not have to import the enhancement domain.
  Future<void> selectFilter(Key filterKey) =>
      step('selecting an enhancement filter', () async {
        await waitUntilVisible();
        await tap(filterKey);
        // The preview re-renders off the UI thread; waiting for it here is what
        // stops the next step acting on the previous image.
        await waitFor(EnhanceKeys.preview);
      });

  /// Drags the brightness slider.
  Future<void> adjustBrightness({double by = 40}) =>
      step('adjusting brightness', () async {
        await waitUntilVisible();
        await tester.drag(
          find.byKey(EnhanceKeys.brightnessSlider),
          Offset(by, 0),
        );
        await tester.pump();
      });

  /// Confirms the enhancement and leaves.
  Future<void> done() => step('finishing enhancement', () async {
    await tap(EnhanceKeys.doneButton);
  });
}

/// Drives the page table — the screen the whole creation journey runs through.
class PageTableRobot extends Robot {
  /// Creates the robot.
  const PageTableRobot(super.tester);

  @override
  Key get screenKey => CreationKeys.pageTableScreen;

  /// Waits until the table has settled into content or its empty state.
  Future<void> waitUntilLoaded() => step('loading the page table', () async {
    await waitUntilVisible();
    await pumpUntilAnyOf(tester, [
      CreationKeys.pageList,
      CreationKeys.emptyState,
    ]);
  });

  /// Adds one page from the camera, through crop and enhancement.
  ///
  /// There is no camera *screen* on this path: the page table captures through
  /// the scanner directly and then walks the new page through crop and
  /// enhancement, which is where the user actually decides what the page looks
  /// like. Driving it any other way would be testing a route the creation flow
  /// does not use.
  Future<void> addPageFromCamera() =>
      step('adding a page from the camera', () async {
        await waitUntilVisible();
        await tap(CreationKeys.addPageButton);
        await waitFor(CreationKeys.addPageSheet);
        await tap(CreationKeys.addFromCamera);

        // Crop, then enhancement, in that order — the loop every newly staged
        // page goes through before it becomes a row.
        await CropRobot(tester).acceptAndContinue();
        await EnhanceRobot(tester).done();

        await waitUntilVisible();
      });

  /// Starts adding a page from the camera and stops at the crop screen.
  ///
  /// For a flow that means to abandon the page rather than finish it: crop is
  /// the first screen it can be abandoned from, and the spec requires that
  /// abandoning adds nothing.
  Future<void> beginAddingPageFromCamera() =>
      step('beginning to add a page from the camera', () async {
        await waitUntilVisible();
        await tap(CreationKeys.addPageButton);
        await waitFor(CreationKeys.addPageSheet);
        await tap(CreationKeys.addFromCamera);
        await CropRobot(tester).waitUntilVisible();
      });

  /// Adds pages from the photo library, through the same crop and enhance loop.
  Future<void> addFromGallery() =>
      step('adding pages from the photo library', () async {
        await waitUntilVisible();
        await tap(CreationKeys.addPageButton);
        await waitFor(CreationKeys.addPageSheet);
        await tap(CreationKeys.addFromGallery);
      });

  /// Opens crop for the page identified by [id].
  ///
  /// Scoped to the row rather than matching the crop key globally: every row
  /// carries the same action keys, so an unscoped finder would match one per
  /// page and act on whichever the framework returned first.
  Future<void> cropPage(PageId id) =>
      step('cropping page ${id.value}', () async {
        await waitUntilVisible();
        await _tapInRow(id, CreationKeys.rowCropButton);
      });

  /// Opens enhancement for the page identified by [id].
  Future<void> enhancePage(PageId id) =>
      step('enhancing page ${id.value}', () async {
        await waitUntilVisible();
        await _tapInRow(id, CreationKeys.rowEnhanceButton);
      });

  /// Removes the page identified by [id].
  Future<void> deletePage(PageId id) =>
      step('deleting page ${id.value}', () async {
        await waitUntilVisible();
        await _tapInRow(id, CreationKeys.rowDeleteButton);
      });

  /// Moves the page currently at [pageNumber] one position later.
  ///
  /// Driven through the row's semantics increase action rather than a drag: the
  /// action is the screen-reader path the spec requires, it is deterministic,
  /// and a synthesised drag on a reorderable list is the single most
  /// flake-prone gesture available.
  ///
  /// Addressed by position rather than by page id because position is what the
  /// row announces as its value, and because a reorder is inherently about
  /// where a page sits rather than which page it is.
  Future<void> movePageLater(int pageNumber) =>
      step('moving page $pageNumber later', () async {
        await waitUntilVisible();

        // Semantics are not built unless something is listening, so the handle
        // has to be held for the duration of the action.
        final handle = tester.ensureSemantics();
        await tester.pump();
        tester.semantics.performAction(
          find.semantics.byValue(CreationSemantics.pagePosition(pageNumber)),
          SemanticsAction.increase,
        );
        await tester.pump();
        handle.dispose();
      });

  /// How many page rows the table is showing.
  ///
  /// Counts *distinct* keys, not matching elements. A reorderable list wraps
  /// each child in several widgets that carry the child's key, so counting
  /// elements reports one page as four and makes the assertion meaningless.
  int get pageCount => find
      .byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              CreationKeys.rowPrefix,
            ),
      )
      .evaluate()
      .map((element) => (element.widget.key! as ValueKey<String>).value)
      .toSet()
      .length;

  /// Saves the document as [name], with no password.
  ///
  /// Returns once the save dialog has closed, which is what "it saved" looks
  /// like to the user. The document itself is asserted where it lands — the
  /// library, or the file on disk — not here.
  Future<void> save(String name) => step('saving as "$name"', () async {
    await waitUntilVisible();
    await tap(CreationKeys.saveButton);
    await waitFor(CreationKeys.saveDialog);
    await type(CreationKeys.saveNameField, name);
    await tap(CreationKeys.saveConfirmButton);
    // Generation runs the real composer over real images, so this is the
    // slowest wait in the suite by a wide margin.
    await waitUntilGone(
      CreationKeys.saveDialog,
      timeout: const Duration(seconds: 120),
    );
  });

  /// Saves the document as [name], protected by [password].
  Future<void> saveProtected(String name, String password) =>
      step('saving "$name" with a password', () async {
        await waitUntilVisible();
        await tap(CreationKeys.saveButton);
        await waitFor(CreationKeys.saveDialog);
        await type(CreationKeys.saveNameField, name);
        await tap(CreationKeys.savePasswordToggle);
        await type(CreationKeys.savePasswordField, password);
        await type(CreationKeys.savePasswordConfirmField, password);
        await tap(CreationKeys.saveConfirmButton);
        await waitUntilGone(
          CreationKeys.saveDialog,
          timeout: const Duration(seconds: 120),
        );
      });

  /// Taps [action] inside the row for [id].
  Future<void> _tapInRow(PageId id, Key action) async {
    final target = find.descendant(
      of: find.byKey(CreationKeys.row(id)),
      matching: find.byKey(action),
    );
    await pumpUntil(tester, target, describe: 'key $action in row ${id.value}');
    await tester.tap(target);
    await tester.pump();
  }
}

/// Drives the generation preview.
class GenerationRobot extends Robot {
  /// Creates the robot.
  const GenerationRobot(super.tester);

  @override
  Key get screenKey => PdfKeys.previewScreen;

  /// Waits for composition to finish.
  ///
  /// A long timeout on purpose: this runs the real composer over real images in
  /// a real isolate, and it is the one step whose cost scales with the number
  /// of pages the flow captured.
  Future<void> waitUntilGenerated() =>
      step('generating the document', () async {
        await waitUntilVisible();
        await waitUntilGone(
          PdfKeys.generationProgress,
          timeout: const Duration(seconds: 120),
        );
      });

  /// Abandons generation.
  Future<void> cancel() => step('cancelling generation', () async {
    await tap(PdfKeys.cancelButton);
  });
}
