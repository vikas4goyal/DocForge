/// The handoff type between capture and document creation.
///
/// Scanning and import both produce pages; PDF generation consumes them. This
/// bundle is the only thing that crosses between them, which is what lets
/// `document-scanning` stay ignorant of `pdf-generation` and vice versa
/// (`design.md` §2).
library;

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scanned_page_bundle.freezed.dart';
part 'scanned_page_bundle.g.dart';

/// Where the pages in a bundle came from.
///
/// Recorded because the two sources warrant different defaults — an imported
/// PDF already has a text layer, a camera capture does not.
enum PageSource {
  /// Captured with the device camera.
  camera,

  /// Selected from the photo library.
  gallery,

  /// Read from a file on the device.
  files,

  /// Received through the operating system share sheet.
  shareSheet,
}

/// An ordered set of captured or imported pages awaiting document creation.
@freezed
abstract class ScannedPageBundle with _$ScannedPageBundle {
  /// Creates a bundle of pages.
  const factory ScannedPageBundle({
    /// Pages in the order they will appear in the finished document.
    required List<PageRef> pages,
    required PageSource source,

    /// Title suggested by the source, when it has one — an imported file's
    /// name, for example. Null means the default naming pattern applies.
    String? suggestedTitle,
  }) = _ScannedPageBundle;

  /// Creates a bundle from JSON.
  factory ScannedPageBundle.fromJson(Map<String, dynamic> json) =>
      _$ScannedPageBundleFromJson(json);

  const ScannedPageBundle._();

  /// An empty bundle from [source], used when a session starts.
  factory ScannedPageBundle.empty(PageSource source) =>
      ScannedPageBundle(pages: const [], source: source);

  /// Number of pages captured so far.
  int get pageCount => pages.length;

  /// Whether the bundle has no pages.
  ///
  /// The review screen shows its empty state in this case rather than creating
  /// a document with no pages, which the library forbids.
  bool get isEmpty => pages.isEmpty;

  /// Whether the bundle can be turned into a document.
  bool get canCreateDocument => pages.isNotEmpty;
}
