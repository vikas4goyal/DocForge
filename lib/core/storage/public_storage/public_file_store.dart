/// The contract for the user-visible document folder.
///
/// Declared in `core` rather than inside a feature because two features depend
/// on it — PDF generation writes through it and the library reads through it —
/// and a contract owned by one feature and imported by another is exactly the
/// feature-to-feature coupling the architecture forbids (`design.md` D2).
///
/// Everything here addresses files by [LibraryPath], never by a device path.
/// That is what lets one contract cover a real filesystem on iOS, MediaStore
/// content URIs on Android, and one day a remote object store, without a caller
/// knowing which it is talking to.
library;

import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:meta/meta.dart';

/// What kind of thing an entry in the public folder is.
enum PublicEntryKind {
  /// A folder the user can open.
  folder,

  /// A document file.
  file,
}

/// Reserved folder containing recoverable payloads.
///
/// It is deliberately excluded from normal listing and reconciliation.
const publicTrashFolderName = '.docforge-trash';

/// Recursive facts used by the destructive-action confirmation.
@immutable
class PublicTreeInventory {
  /// Creates an inventory.
  const PublicTreeInventory({
    this.documentCount = 0,
    this.otherFileCount = 0,
    this.folderCount = 0,
    this.sizeInBytes = 0,
  });

  /// Number of PDF files.
  final int documentCount;

  /// Number of files not indexed as DocForge PDFs.
  final int otherFileCount;

  /// Number of descendant folders, including empty folders.
  final int folderCount;

  /// Recursive file bytes.
  final int sizeInBytes;
}

/// One entry found in the public folder.
///
/// Carries the fingerprint fields the reconciler diffs on — [sizeBytes] and
/// [modifiedAt] — because reading them during the walk is free, while a second
/// pass to fetch them per entry would turn one directory listing into N calls.
@immutable
class PublicEntry {
  /// Creates an entry.
  const PublicEntry({
    required this.kind,
    required this.name,
    required this.folders,
    this.sizeBytes = 0,
    this.modifiedAt,
  });

  /// Whether this is a folder or a file.
  final PublicEntryKind kind;

  /// The entry's own name, including the extension for a file.
  final String name;

  /// The folder segments leading to this entry, outermost first.
  final List<String> folders;

  /// Size in bytes; zero for a folder.
  final int sizeBytes;

  /// Last modification time, when the platform reports one.
  final DateTime? modifiedAt;

  /// Whether this entry is a folder.
  bool get isFolder => kind == PublicEntryKind.folder;

  /// The library path of this entry, when it is a file.
  ///
  /// Null for a folder, which has no file name to address.
  LibraryPath? get path =>
      isFolder ? null : LibraryPath.raw(folders: folders, fileName: name);

  /// The folder segments of this entry when it is itself a folder.
  List<String> get folderSegments => isFolder ? [...folders, name] : folders;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicEntry &&
          other.kind == kind &&
          other.name == name &&
          other.sizeBytes == sizeBytes &&
          other.modifiedAt == modifiedAt &&
          _sameFolders(other.folders, folders);

  @override
  int get hashCode =>
      Object.hash(kind, name, sizeBytes, modifiedAt, Object.hashAll(folders));

  @override
  String toString() =>
      '${isFolder ? 'folder' : 'file'} ${[...folders, name].join('/')}';

  static bool _sameFolders(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Reads and writes the user-visible `DocForge` folder.
///
/// Every method returns a [Result] rather than throwing, and every one of them
/// works with no network: the folder is local storage on both platforms, so
/// nothing here has an offline mode distinct from its normal one.
///
/// Failure vocabulary, uniform across implementations:
/// * `Failure.storageFull` when the device has no space left.
/// * `Failure.notFound` when the addressed file or folder does not exist.
/// * `Failure.validation` when a name would escape the library root.
/// * `Failure.storage` for any other I/O fault.
abstract interface class PublicFileStore {
  /// Creates the library folder if it does not exist.
  ///
  /// Call once at startup, before anything reads or writes. Succeeds when the
  /// folder is already present, so it is safe to call on every launch.
  Future<Result<void>> initialise();

  /// Lists the immediate contents of [folders], relative to the library root.
  ///
  /// An empty list means the library root. Returns folders and files together,
  /// in no guaranteed order — the caller sorts for display. A folder that does
  /// not exist yields `Failure.notFound` rather than an empty list, so a stale
  /// breadcrumb is distinguishable from an empty folder.
  Future<Result<List<PublicEntry>>> list(List<String> folders);

  /// Walks [folders] and everything beneath it.
  ///
  /// Used by the reconciler, which needs the whole tree in one pass; calling
  /// [list] recursively would be one platform round trip per directory.
  Future<Result<List<PublicEntry>>> listRecursive(List<String> folders);

  /// Measures a file or folder tree before it is moved to Trash.
  Future<Result<PublicTreeInventory>> inventory({
    LibraryPath? file,
    List<String>? folder,
  });

  /// Moves [path] into the reserved payload for [trashId].
  Future<Result<void>> moveFileToTrash(String trashId, LibraryPath path);

  /// Moves [folders] and every descendant into the reserved payload.
  Future<Result<void>> moveFolderToTrash(String trashId, List<String> folders);

  /// Restores a file payload to [destination].
  Future<Result<void>> restoreFileFromTrash(
    String trashId,
    String originalName,
    LibraryPath destination,
  );

  /// Restores a folder payload to [destinationFolders].
  Future<Result<void>> restoreFolderFromTrash(
    String trashId,
    String originalName,
    List<String> destinationFolders,
  );

  /// Permanently removes [trashId]'s reserved payload.
  Future<Result<void>> purgeTrashPayload(String trashId);

  /// Whether [trashId]'s reserved payload still exists.
  Future<Result<bool>> trashPayloadExists(String trashId);

  /// Creates the folder at [folders], including any missing parents.
  ///
  /// Succeeds when the folder already exists, so a retry after a partial
  /// failure can complete.
  Future<Result<void>> createFolder(List<String> folders);

  /// Deletes the folder at [folders] and everything inside it.
  ///
  /// Succeeds when the folder is already absent: removal has to be idempotent.
  Future<Result<void>> deleteFolder(List<String> folders);

  /// Renames the folder at [folders] to [newName], keeping its contents.
  Future<Result<void>> renameFolder(List<String> folders, String newName);

  /// Copies the file at [sourcePath] into the library at [path].
  ///
  /// [sourcePath] is a device path — a freshly generated PDF in the cache, or
  /// a file the user picked. Returns the path callers can read the result back
  /// from, which is [materialise]'s answer for the same location.
  ///
  /// Overwrites an existing file at [path]; de-duplicating a name is the
  /// caller's decision, because only the caller knows whether the user asked
  /// to replace or to keep both.
  Future<Result<String>> writeFile(LibraryPath path, String sourcePath);

  /// Returns a readable device path for the file at [path].
  ///
  /// The seam that makes the platform difference invisible to consumers: on
  /// iOS this is the file's real path; on Android the MediaStore item is copied
  /// into the cache and the copy's path is returned. `pdfrx`, `pdf_manipulator`
  /// and `printing` all require a path, and none of them can take a URI.
  ///
  /// Callers must treat the result as read-only and must not assume it survives
  /// beyond the current use — see [releaseMaterialised].
  Future<Result<String>> materialise(LibraryPath path);

  /// Releases a path previously returned by [materialise].
  ///
  /// A no-op where materialisation is free. On Android it makes the cached copy
  /// evictable, which is what stops a session of opening documents filling the
  /// cache with copies of every one of them.
  Future<Result<void>> releaseMaterialised(LibraryPath path);

  /// Moves or renames the file at [from] to [to].
  Future<Result<void>> rename(LibraryPath from, LibraryPath to);

  /// Deletes the file at [path].
  ///
  /// Succeeds when the file is already absent.
  Future<Result<void>> delete(LibraryPath path);

  /// Whether a file exists at [path].
  Future<Result<bool>> exists(LibraryPath path);

  /// Returns the total bytes used by every file in the library folder.
  Future<Result<int>> totalBytes();
}
