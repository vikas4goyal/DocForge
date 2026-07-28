/// Produces the image a page should be shown as.
///
/// Declared in `core` because three features need it — the crop screen, the
/// enhancement screen and the page table all display a page, and each would
/// otherwise have to import the feature that owns the renderer.
///
/// The implementation lives in `document_creation`, which is where a creation
/// session's cache belongs; nothing here knows that.
library;

import 'package:doc_forge/core/contracts/models/page_render_plan.dart';
import 'package:doc_forge/core/failures/result.dart';

/// Renders a page from its plan.
abstract interface class PageRenderer {
  /// Returns a readable path to the image [plan] describes.
  ///
  /// A plan with neither layer applied returns the original itself: there is
  /// nothing to render, and copying it would duplicate a file that exists.
  Future<Result<String>> call(PageRenderPlan plan);
}
