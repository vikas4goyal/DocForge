/// Renders a page from its plan, once per distinct plan.
///
/// The one place a page's appearance is produced. Everything that shows a page
/// goes through here, so the row thumbnail, the crop screen and the generated
/// PDF cannot disagree about what the user's edits amount to (`design.md` D6).
///
/// Rendering is keyed by [PageRenderPlan], which has value equality: an
/// unchanged plan reuses its file, and a changed one cannot collide with the
/// old render because the key is derived from the plan itself.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/geometry/page_geometry.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/contracts/page_renderer.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';

/// Produces the pixels for one plan, off the UI thread.
///
/// Distinct from `PageRenderer`, which is the *contract* consumers depend on:
/// this is the pixel work the implementation delegates to.
///
/// [transform] is the single composed geometry — the original is resampled once
/// however many crops the user applied. A null transform means no geometry, in
/// which case the implementation copies or enhances the original directly
/// rather than running an identity resample over it.
typedef PagePixelWriter =
    Future<Result<void>> Function(
      PageRenderPlan plan, {
      required String destinationPath,
      ComposedGeometry? transform,
    });

/// Reads an image's pixel dimensions, so the geometry can be composed.
typedef ImageSizeReader =
    Future<Result<({int width, int height})>> Function(String imagePath);

/// Renders pages and caches the results by plan.
class RenderPage implements PageRenderer {
  /// Creates the use case.
  RenderPage({
    required this.cacheDirectory,
    required this.render,
    required this.sizeOf,
    this.directoryName = 'renders',
  });

  /// Where renders are cached.
  ///
  /// The session's own cache directory: a render is derived from the original
  /// and is worth keeping only while the session is open.
  final Directory cacheDirectory;

  /// The render directory's name.
  final String directoryName;

  /// Produces pixels for a plan.
  final PagePixelWriter render;

  /// Reads the original's dimensions.
  final ImageSizeReader sizeOf;

  /// Renders in flight, so two callers wanting the same plan share one render.
  ///
  /// An instance field rather than a static: two sessions in a test must not
  /// interfere, and nothing here is global mutable state.
  final Map<String, Future<Result<String>>> _inFlight = {};

  /// The root cached renders sit under.
  Directory get root => Directory('${cacheDirectory.path}/$directoryName');

  /// Returns a path to the rendered image for [plan].
  ///
  /// Reuses a cached render when the plan has not changed. A plan with neither
  /// layer applied returns the original itself — there is nothing to render,
  /// and copying it would be a byte-for-byte duplicate of a file that already
  /// exists.
  @override
  Future<Result<String>> call(PageRenderPlan plan) {
    if (plan.isPassThrough) {
      return Future.value(Result<String>.success(plan.originalImagePath));
    }

    final destination = _pathFor(plan);
    if (File(destination).existsSync()) {
      return Future.value(Result<String>.success(destination));
    }

    // Coalesced: a page table scrolling past a row and the crop screen opening
    // on it want the same render, and producing it twice is pure waste.
    final existing = _inFlight[plan.cacheKey];
    if (existing != null) return existing;

    final pending = _render(plan, destination);
    _inFlight[plan.cacheKey] = pending;
    return pending.whenComplete(() => _inFlight.remove(plan.cacheKey));
  }

  /// Removes every cached render, whatever plan produced it.
  ///
  /// Called when the session ends: the renders are derived from originals that
  /// are themselves about to be deleted.
  Future<Result<void>> discardAll() async {
    try {
      if (root.existsSync()) await root.delete(recursive: true);
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(Failure.storage(debugDetail: '$error'));
    }
  }

  Future<Result<String>> _render(
    PageRenderPlan plan,
    String destination,
  ) async {
    ComposedGeometry? transform;

    if (plan.geometry.isNotEmpty) {
      final size = await sizeOf(plan.originalImagePath);
      if (size case Failed(:final failure)) {
        return Result<String>.failure(failure);
      }

      // Composed once, here: applying the crops one after another would
      // resample the photograph per operation and lose sharpness each time.
      transform = PageGeometry.compose(
        plan.geometry,
        imageWidth: size.valueOrNull!.width,
        imageHeight: size.valueOrNull!.height,
      );
    }

    try {
      Directory(destination).parent.createSync(recursive: true);
    } on Object catch (error) {
      return Result<String>.failure(Failure.storage(debugDetail: '$error'));
    }

    final produced = await render(
      plan,
      destinationPath: destination,
      transform: transform,
    );

    if (produced case Failed(:final failure)) {
      // A partial file would be served as a valid render by the existence
      // check above, so it goes rather than being left behind.
      final partial = File(destination);
      if (partial.existsSync()) partial.deleteSync();
      return Result<String>.failure(failure);
    }

    return Result<String>.success(destination);
  }

  String _pathFor(PageRenderPlan plan) => '${root.path}/${plan.cacheKey}.jpg';
}
