/// Produces the image a page should be shown as.
///
/// Declared in `core` because three features need it — the crop screen, the
/// enhancement screen and the page table all display a page, and each would
/// otherwise have to import the feature that owns the renderer.
///
/// The implementation lives in `document_creation`, which is where a creation
/// session's cache belongs; nothing here knows that.
library;

import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/failures/result.dart';

/// Renders a page from its plan.
abstract interface class PageRenderer {
  /// Returns a readable path to the image [plan] describes.
  ///
  /// A plan with neither layer applied returns the original itself: there is
  /// nothing to render, and copying it would duplicate a file that exists.
  Future<Result<String>> call(PageRenderPlan plan, {String? scope});

  /// Cancels the render currently owned by [scope], if any.
  ///
  /// Cancellation is best-effort at codec boundaries, but a cancelled render
  /// must never publish over a newer result. Renderers without interruptible
  /// work implement this as a no-op.
  Future<void> cancel(String scope);
}
