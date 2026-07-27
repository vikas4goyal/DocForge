/// Renders a stored page image into a file fit to hand to another application.
///
/// Runs **inside a background isolate**: no Flutter, and only the request and
/// the resulting path cross the boundary (`design.md` §7).
///
/// Deliberately does *not* re-run enhancement. The stored page image is already
/// the enhanced one — enhancement is applied when the page is saved — so all
/// that is left is to bake in the rotation and re-encode at a size suited to
/// being sent somewhere. Re-running enhancement here would also mean importing
/// another feature, which the layering check forbids.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/features/document_sharing/domain/share_content.dart';
import 'package:image/image.dart' as img;

/// The longest edge, in pixels, of a shared page image.
///
/// A shared image is looked at on a screen or attached to a message, not
/// re-scanned, and a ten-page share at full capture resolution is large enough
/// that several mail services reject it outright.
const sharedImageMaxDimension = 2400;

/// Renders one page to [SharePageRequest.destinationPath] and returns that path.
///
/// A top-level function because a closure cannot be sent to an isolate.
///
/// Throws [FormatException] when the stored page image cannot be decoded, which
/// the caller maps to a corrupt-file failure.
String renderSharePageJob(SharePageRequest request) {
  final source = File(request.page.imagePath);
  final decoded = img.decodeImage(source.readAsBytesSync());

  if (decoded == null) {
    throw FormatException(
      'the page image could not be decoded: ${request.page.imagePath}',
    );
  }

  final oriented = request.page.rotation == PageRotation.none
      ? decoded
      : img.copyRotate(decoded, angle: request.page.rotation.degrees);

  final scaled = _scaled(oriented, sharedImageMaxDimension);

  // Written to a temporary sibling and renamed, so a share sheet opened while
  // this is still running can never pick up a half-written image. A rename
  // within a directory is atomic on both platforms.
  final temporary = File('${request.destinationPath}.partial');

  try {
    temporary
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(img.encodeJpg(scaled, quality: request.quality));
    return temporary.renameSync(request.destinationPath).path;
  } on Object {
    if (temporary.existsSync()) temporary.deleteSync();
    rethrow;
  }
}

/// Scales [image] so its longest edge is at most [maxDimension].
///
/// Never scales up: enlarging a low-resolution capture adds bytes and no
/// detail.
img.Image _scaled(img.Image image, int maxDimension) {
  final longest = image.width > image.height ? image.width : image.height;
  if (longest <= maxDimension) return image;

  return image.width >= image.height
      ? img.copyResize(image, width: maxDimension)
      : img.copyResize(image, height: maxDimension);
}
