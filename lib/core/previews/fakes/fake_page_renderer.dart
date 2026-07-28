/// A [PageRenderer] that never touches the filesystem.
///
/// For previews and goldens, which must be byte-stable and must not depend on
/// a machine's temporary directory. Reports the plan's original back, which is
/// what a page with neither layer applied renders as anyway.
library;

import 'package:doc_forge/core/contracts/models/page_render_plan.dart';
import 'package:doc_forge/core/contracts/page_renderer.dart';
import 'package:doc_forge/core/failures/result.dart';

/// Renders every plan to its own original.
class FakePageRenderer implements PageRenderer {
  /// Creates the renderer.
  const FakePageRenderer();

  @override
  Future<Result<String>> call(PageRenderPlan plan) async =>
      Result<String>.success(plan.originalImagePath);
}
