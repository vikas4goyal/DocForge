/// Every route in the application, as typed constants.
///
/// The project forbids string-literal navigation in feature code. Paths are
/// declared here once and reached through the typed helpers below, so a renamed
/// route becomes a compile error rather than a link that silently stops working.
///
/// Paths are stable from V1 onward: they are what a future deep link or
/// share-sheet target will resolve against, and changing one later breaks
/// anything already pointing at it (`design.md` §8).
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';

/// Path templates for every route, and helpers to build concrete locations.
abstract final class AppRoutes {
  /// First-launch onboarding flow.
  static const onboarding = '/onboarding';

  /// Application lock screen.
  static const unlock = '/unlock';

  /// The application's primary screen — the dashboard.
  ///
  /// Kept at the root so a deep link, a share and a cold start all land in the
  /// same place, which is the folder the user's documents are in.
  static const home = '/';

  /// The dashboard, as a named destination for the tab bar.
  static const dashboard = '/';

  /// Creating a document: one page table, and the loop that fills it.
  ///
  /// The crop, enhancement and camera screens are pushed by the flow rather
  /// than declared here: they are steps of a transient session, and a deep link
  /// into one would land on a session that does not exist.
  static const scan = '/scan';

  /// Dedicated PDF configuration and commit surface for a creation session.
  static const savePdf = '/scan/save';

  /// Read-only preview of one app-private temporary PDF candidate.
  static const pdfTemporaryPreview = '/scan/save/preview';

  /// Dedicated compression configuration and commit surface.
  static const compressPdfTemplate = '/documents/:id/compress';

  /// All documents.
  static const documents = '/documents';

  /// A single document's detail screen.
  ///
  /// Template form; use [documentDetail] to build a concrete location.
  static const documentDetailTemplate = '/documents/:id';

  /// A document's editing tools.
  static const documentEditTemplate = '/documents/:id/edit';

  /// The viewer for one document.
  ///
  /// Registered as a top-level typed route so direct activation places only
  /// Viewer over the originating library surface. Detail is pushed explicitly
  /// from Viewer's overflow when metadata or lifecycle actions are requested.
  static const documentViewTemplate = '/documents/:id/view';

  /// All folders.
  static const folders = '/folders';

  /// A single folder's contents.
  static const folderDetailTemplate = '/folders/:id';

  /// Search across the library.
  static const search = '/search';

  /// Documents marked as favourite.
  static const favourites = '/favourites';

  /// Archived documents.
  static const archive = '/archive';

  /// Recoverable items waiting for automatic permanent deletion.
  static const trash = '/trash';

  /// Settings.
  static const settings = '/settings';

  /// Application information.
  static const about = '/settings/about';

  /// Privacy policy.
  static const privacy = '/settings/privacy';

  /// iOS-only app-owned iCloud storage selection.
  static const storageLocation = '/settings/storage-location';

  /// Name of the `:id` path parameter shared by the templated routes.
  static const idParameter = 'id';

  /// Returns the location of the detail screen for [id].
  static String documentDetail(DocumentId id) => '/documents/${id.value}';

  /// Returns the location of the editing tools for [id].
  static String documentEdit(DocumentId id) => '/documents/${id.value}/edit';

  /// The viewer for [id].
  static String documentView(DocumentId id) => '/documents/${id.value}/view';

  /// Returns the location of the contents of folder [id].
  static String folderDetail(FolderId id) => '/folders/${id.value}';

  /// Every non-templated route, for tests that assert full coverage.
  static const all = <String>[
    onboarding,
    unlock,
    home,
    scan,
    documents,
    folders,
    search,
    favourites,
    archive,
    trash,
    settings,
    about,
    privacy,
  ];

  /// Routes that are registered only when the platform supports them.
  static const iosOnly = <String>[storageLocation];
}

/// Typed iOS storage-location destination.
class StorageLocationRoute {
  /// Creates the destination value.
  const StorageLocationRoute();

  /// Stable route location.
  String get location => AppRoutes.storageLocation;
}

/// Typed Save PDF destination carrying an app-private creation session handle.
class SavePdfRoute {
  /// Creates the destination value.
  SavePdfRoute({required this.sessionHandle}) {
    if (sessionHandle.isEmpty) {
      throw ArgumentError.value(
        sessionHandle,
        'sessionHandle',
        'must not be empty',
      );
    }
  }

  /// Opaque handle resolved only by the composition root.
  final String sessionHandle;

  /// Stable route location.
  String get location => AppRoutes.savePdf;
}

/// Typed read-only preview destination carrying a private candidate handle.
class PdfTemporaryPreviewRoute {
  /// Creates the destination value.
  PdfTemporaryPreviewRoute({required this.candidateHandle}) {
    if (candidateHandle.isEmpty) {
      throw ArgumentError.value(
        candidateHandle,
        'candidateHandle',
        'must not be empty',
      );
    }
  }

  /// Opaque candidate handle resolved only by the PDF-generation factory.
  final String candidateHandle;

  /// Stable route location.
  String get location => AppRoutes.pdfTemporaryPreview;
}

/// Typed Compress PDF destination for one stored document.
class CompressPdfRoute {
  /// Creates the destination value.
  const CompressPdfRoute({required this.documentId});

  /// Source document opened directly from Viewer or the editor.
  final DocumentId documentId;

  /// Concrete stable location for [documentId].
  String get location => '/documents/${documentId.value}/compress';
}

/// Navigation action after a compression commit succeeds.
enum CompressPdfCompletionKind {
  /// Open the new sibling document produced by Save as copy.
  openCopy,

  /// Refresh the Viewer that already displays the overwritten source.
  refreshOriginal,
}

/// Typed result popped exactly once by the Compress PDF route.
class CompressPdfCompletion {
  /// Creates the result for [documentId].
  const CompressPdfCompletion({required this.kind, required this.documentId});

  /// Whether navigation opens a copy or refreshes the source.
  final CompressPdfCompletionKind kind;

  /// New copy identity for [CompressPdfCompletionKind.openCopy], otherwise the
  /// original source identity to refresh.
  final DocumentId documentId;
}
