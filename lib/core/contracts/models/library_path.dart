/// A location inside the library folder.
///
/// Pure value object: no filesystem, no Flutter, so every rule here is directly
/// unit-testable and none of it can leak into a repository or a Cubit.
library;

import 'package:meta/meta.dart';

/// Thrown when a path cannot be built because it would escape the library root
/// or is otherwise not a legal location.
///
/// A dedicated exception rather than a `Failure`: constructing an illegal path
/// is a programming error at the boundary, and the callers that accept user
/// input validate with [LibraryPath.isValidName] before they get here.
@immutable
class InvalidLibraryPath implements Exception {
  /// Creates the exception describing [reason] for [input].
  const InvalidLibraryPath(this.input, this.reason);

  /// The text that could not be parsed.
  final String input;

  /// Why it was refused, in a form suitable for a debug log.
  final String reason;

  @override
  String toString() => 'InvalidLibraryPath("$input"): $reason';
}

/// A location inside the library folder, as folder segments plus a file name.
///
/// A value object rather than a `String` because every path the application
/// writes has to be proven not to escape the library root, and a `String` that
/// has been validated somewhere is indistinguishable from one that has not
/// (`design.md` D1).
///
/// Paths are always relative to the library root — `DocScanly/` — and never
/// carry a device-absolute prefix, which is what lets the same value address a
/// file on iOS, an entry in Android's MediaStore, and one day a remote object.
@immutable
final class LibraryPath {
  /// Creates a path from already-validated parts.
  ///
  /// Prefer [LibraryPath.parse] or [LibraryPath.inFolder] at boundaries; this
  /// constructor assumes its inputs have been checked and is const so fixtures
  /// can be compile-time constants.
  const LibraryPath.raw({required this.folders, required this.fileName});

  /// Creates a path for [fileName] inside [folders].
  ///
  /// Throws [InvalidLibraryPath] when any segment or the file name is not a
  /// legal name — see [isValidName].
  factory LibraryPath.inFolder(List<String> folders, String fileName) {
    for (final folder in folders) {
      if (!isValidName(folder)) {
        throw InvalidLibraryPath(folder, 'illegal folder segment');
      }
    }
    if (!isValidName(fileName)) {
      throw InvalidLibraryPath(fileName, 'illegal file name');
    }
    return LibraryPath.raw(
      folders: List.unmodifiable(folders),
      fileName: fileName,
    );
  }

  /// Parses a library-relative path such as `Invoices/2026/Receipt.pdf`.
  ///
  /// Trailing and repeated separators are tolerated and normalised away,
  /// because the platform stores hand back more than one of those forms — a
  /// MediaStore `RELATIVE_PATH` carries a trailing separator, a filesystem walk
  /// does not. A *leading* separator is refused rather than stripped: it means
  /// a device-absolute path, and quietly reinterpreting one as library-relative
  /// is how a caller ends up addressing a file outside the library. `..`
  /// segments and empty names are refused for the same reason.
  ///
  /// Throws [InvalidLibraryPath] when [relative] is not a legal location.
  factory LibraryPath.parse(String relative) {
    final trimmed = relative.trim();
    if (trimmed.isEmpty) {
      throw InvalidLibraryPath(relative, 'empty path');
    }
    if (trimmed.startsWith('/') || trimmed.startsWith(r'\')) {
      throw InvalidLibraryPath(
        relative,
        'absolute paths are not library paths',
      );
    }

    final segments = [
      for (final segment in trimmed.split(separator))
        if (segment.isNotEmpty) segment,
    ];
    if (segments.isEmpty) {
      throw InvalidLibraryPath(relative, 'no segments');
    }

    for (final segment in segments) {
      if (!isValidName(segment)) {
        throw InvalidLibraryPath(segment, 'illegal segment');
      }
    }

    return LibraryPath.raw(
      folders: List.unmodifiable(segments.sublist(0, segments.length - 1)),
      fileName: segments.last,
    );
  }

  /// Creates a path from its JSON string form.
  ///
  /// Written out by hand rather than generated, for the same reason the typed
  /// ids are: a wrapper serialised by json_serializable nests as
  /// `{"relative": "..."}`, where the stored form wants to be a plain string
  /// that reads the same in the database, in a log and on the wire.
  factory LibraryPath.fromJson(String json) => LibraryPath.parse(json);

  /// Returns [relative] so the path serialises as a plain JSON string.
  String toJson() => relative;

  /// The separator between segments of a library path.
  ///
  /// Always `/`, on every platform. A library path is a portable address, not
  /// a device path, so it does not follow the host separator — the platform
  /// stores translate when they touch the filesystem.
  static const separator = '/';

  /// The extension every document in the library carries.
  static const pdfExtension = '.pdf';

  /// The folder segments from the library root, outermost first.
  ///
  /// Empty for a document sitting directly in the library root.
  final List<String> folders;

  /// The file's name including its extension.
  final String fileName;

  /// The path relative to the library root, e.g. `Invoices/2026/Receipt.pdf`.
  String get relative => [...folders, fileName].join(separator);

  /// The containing folder's path, e.g. `Invoices/2026`, empty at the root.
  String get folderPath => folders.join(separator);

  /// The file name without its extension.
  String get baseName {
    final dot = fileName.lastIndexOf('.');
    return dot <= 0 ? fileName : fileName.substring(0, dot);
  }

  /// Whether this path sits directly in the library root.
  bool get isAtRoot => folders.isEmpty;

  /// Returns a copy of this path with [name] as the file name.
  ///
  /// Throws [InvalidLibraryPath] when [name] is not a legal file name.
  LibraryPath withFileName(String name) => LibraryPath.inFolder(folders, name);

  /// Returns a copy of this path moved into [destination].
  ///
  /// Throws [InvalidLibraryPath] when any segment of [destination] is illegal.
  LibraryPath movedTo(List<String> destination) =>
      LibraryPath.inFolder(destination, fileName);

  /// Whether [name] is legal as a folder segment or a file name.
  ///
  /// Refuses the traversal names, path separators, the reserved characters that
  /// at least one of the two target platforms rejects, control characters, and
  /// names that are empty or made only of dots or spaces. Being stricter than
  /// either platform alone keeps a name created on one device legal on the
  /// other, which a future sync depends on.
  static bool isValidName(String name) {
    if (name.isEmpty || name.length > maxNameLength) return false;
    if (name == '.' || name == '..') return false;
    if (name.trim().isEmpty) return false;
    // A trailing dot or space is silently dropped by some filesystems, which
    // would make the stored name and the name on disk disagree.
    if (name.endsWith('.') || name.endsWith(' ')) return false;
    if (name.startsWith(' ')) return false;

    for (final unit in name.codeUnits) {
      if (unit < 0x20) return false;
      if (_reservedCodeUnits.contains(unit)) return false;
    }
    return true;
  }

  /// The longest a single segment may be.
  ///
  /// 255 is the limit on both platforms' filesystems; a longer name is refused
  /// here rather than truncated, so the name in the index always matches disk.
  static const maxNameLength = 255;

  /// Returns [name] with every illegal character replaced by an underscore.
  ///
  /// Used only when adopting a name that already exists — a folder created
  /// outside the application, or a legacy record from before names were
  /// constrained. New names entered by the user are validated and refused
  /// rather than silently rewritten, because a rewritten name is one the user
  /// did not choose.
  ///
  /// Returns [fallback] when nothing legal survives.
  static String sanitiseName(String name, {String fallback = 'Untitled'}) {
    final buffer = StringBuffer();
    for (final rune in name.runes) {
      if (rune < 0x20 || _reservedCodeUnits.contains(rune)) {
        buffer.write('_');
      } else {
        buffer.writeCharCode(rune);
      }
    }

    var cleaned = buffer.toString().trim();
    while (cleaned.endsWith('.')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trimRight();
    }
    if (cleaned.length > maxNameLength) {
      cleaned = cleaned.substring(0, maxNameLength).trimRight();
    }
    return isValidName(cleaned) ? cleaned : fallback;
  }

  /// Returns [baseName] with the PDF extension, appending it only when absent.
  static String pdfFileName(String baseName) =>
      baseName.toLowerCase().endsWith(pdfExtension)
      ? baseName
      : '$baseName$pdfExtension';

  /// Returns a name derived from [desired] that is not present in [taken].
  ///
  /// Appends ` (2)`, ` (3)` and so on before the extension, which is what both
  /// platforms' file browsers do, so a de-duplicated name looks like one the
  /// operating system would have produced.
  static String deduplicate(String desired, Set<String> taken) {
    if (!taken.contains(desired)) return desired;

    final dot = desired.lastIndexOf('.');
    final stem = dot <= 0 ? desired : desired.substring(0, dot);
    final extension = dot <= 0 ? '' : desired.substring(dot);

    for (var suffix = 2; ; suffix++) {
      final candidate = '$stem ($suffix)$extension';
      if (!taken.contains(candidate)) return candidate;
    }
  }

  /// Characters refused in a segment.
  ///
  /// The union of what iOS and Android reject, plus the Windows set: a name
  /// legal on one platform but not the other would break as soon as a document
  /// moved between devices.
  static const _reservedCodeUnits = <int>{
    0x2F, // /
    0x5C, // \
    0x3A, // :
    0x2A, // *
    0x3F, // ?
    0x22, // "
    0x3C, // <
    0x3E, // >
    0x7C, // |
    0x00, // NUL
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryPath &&
          other.fileName == fileName &&
          _sameFolders(other.folders, folders);

  @override
  int get hashCode => Object.hash(fileName, Object.hashAll(folders));

  @override
  String toString() => relative;

  static bool _sameFolders(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
