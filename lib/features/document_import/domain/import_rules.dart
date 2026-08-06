/// The rules governing what may be imported and what happens to it.
///
/// Pure: no Flutter, no plugins, no file system. Which file types are accepted,
/// which permission a source needs, what a rejection says and how many
/// documents a batch produced are all decisions, and every one is unit-tested
/// without a picker in sight.
library;

import 'package:doc_scanly/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_scanly/core/failures/failure.dart';

/// Where imported content came from.
enum ImportSource {
  /// The device camera, which starts the scanning flow.
  camera('Camera', 'Scan a new page with the camera'),

  /// The photo library.
  gallery('Photo gallery', 'Choose images from the photo gallery'),

  /// Files stored on the device.
  files('Device files', 'Choose a PDF or images from device files'),

  /// Content handed to the application by another application.
  shareSheet(
    'Shared with DocScanly',
    'Content shared from another application',
  );

  const ImportSource(this.label, this.semanticsLabel);

  /// The visible label of this source.
  final String label;

  /// What a screen reader announces, describing where content comes from.
  final String semanticsLabel;

  /// The page source recorded on a bundle imported this way.
  PageSource get pageSource => switch (this) {
    ImportSource.camera => PageSource.camera,
    ImportSource.gallery => PageSource.gallery,
    ImportSource.files => PageSource.files,
    ImportSource.shareSheet => PageSource.shareSheet,
  };

  /// The permission this source needs, or null when it needs none.
  ///
  /// The share sheet needs none: the other application has already granted
  /// access to the content by sending it. Requesting one anyway would be a
  /// prompt the user cannot connect to anything they did.
  PermissionKind? get permission => switch (this) {
    ImportSource.camera => PermissionKind.camera,
    ImportSource.gallery => PermissionKind.photos,
    ImportSource.files => PermissionKind.files,
    ImportSource.shareSheet => null,
  };
}

/// What an imported file turned out to be.
enum ImportedFileKind {
  /// A supported still image, which becomes a page.
  image,

  /// A PDF, which becomes a document directly.
  pdf,

  /// Something DocScanly cannot read.
  unsupported,
}

/// One file selected for import.
class ImportCandidate {
  /// Creates a candidate at [path].
  const ImportCandidate({required this.path, required this.kind});

  /// Where the file is now, before anything has been copied.
  final String path;

  /// What it turned out to be.
  final ImportedFileKind kind;

  /// Whether this candidate can be imported at all.
  bool get isSupported => kind != ImportedFileKind.unsupported;
}

/// Decisions about importing.
abstract final class ImportRules {
  /// Image extensions DocScanly can turn into a page.
  ///
  /// HEIC is included because it is the iPhone camera's default format, and
  /// omitting it would reject most of a typical photo library.
  static const imageExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'heic',
    'heif',
    'webp',
    'bmp',
    'tif',
    'tiff',
  };

  /// The one document extension DocScanly can import.
  static const pdfExtension = 'pdf';

  /// The directory name, inside app-private storage, holding imported pages.
  static const stagingDirectoryName = 'import_staging';

  /// Returns the lower-cased extension of [path], without its dot.
  ///
  /// Returns an empty string when there is none — a file with no extension is
  /// a file DocScanly cannot classify, which is a rejection rather than a crash.
  static String extensionOf(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  /// Classifies the file at [path] by its extension.
  ///
  /// Extension rather than content, deliberately: the pickers on both platforms
  /// already filter by type, the file may be a security-scoped URL that cannot
  /// be read until it has been copied, and a PDF that is not really a PDF is
  /// caught when it is opened — which is the check that actually matters and
  /// which happens anyway.
  static ImportedFileKind kindFor(String path) {
    final extension = extensionOf(path);
    if (extension == pdfExtension) return ImportedFileKind.pdf;
    if (imageExtensions.contains(extension)) return ImportedFileKind.image;
    return ImportedFileKind.unsupported;
  }

  /// Classifies every path in [paths], preserving selection order.
  ///
  /// Order is preserved because the gallery scenario requires the selected
  /// images to become pages "in selection order", and a set or a map would lose
  /// exactly that.
  static List<ImportCandidate> classify(Iterable<String> paths) => [
    for (final path in paths) ImportCandidate(path: path, kind: kindFor(path)),
  ];

  /// The message shown when a selected file is of a type DocScanly cannot read.
  ///
  /// Names the supported types, which the spec requires: "unsupported file" on
  /// its own leaves the user with no idea what to select instead.
  static const unsupportedTypeMessage =
      'DocScanly can import PDFs and images (JPEG, PNG, HEIC, WebP, BMP and '
      'TIFF). That file is neither.';

  /// The title of a document suggested by an imported file at [path].
  ///
  /// The file's own name without its extension, because an imported file
  /// already has a name the user chose and a generated timestamp would discard
  /// it. Returns null when there is nothing usable, in which case the
  /// configured naming pattern applies.
  static String? suggestedTitle(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    final base = (dot <= 0 ? name : name.substring(0, dot)).trim();
    return base.isEmpty ? null : base;
  }

  /// How the outcome of importing [count] documents is reported.
  ///
  /// The multiple-files scenario requires the user to be told how many
  /// documents were created, which a silent return to Home would not.
  static String importedCountMessage(int count) => switch (count) {
    0 => 'Nothing was imported.',
    1 => '1 document imported.',
    _ => '$count documents imported.',
  };

  /// The label shown while [completed] of [total] files are imported.
  static String progressLabel(int completed, int total) =>
      total <= 1 ? 'Importing…' : 'Importing file $completed of $total…';

  /// Whether a batch containing [candidates] can proceed at all.
  ///
  /// A batch with nothing supported in it is rejected before any work starts,
  /// so no partial document is created for a selection that could never have
  /// produced one.
  static bool hasAnythingToImport(List<ImportCandidate> candidates) =>
      candidates.any((candidate) => candidate.isSupported);
}
