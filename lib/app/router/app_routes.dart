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

import 'package:doc_forge/core/contracts/models/ids.dart';

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
  /// A child of the detail route rather than a replacement for it: opening a
  /// document to read it and inspecting its metadata are different intents, and
  /// Back from the viewer should return to the detail the user came from.
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

  /// Settings.
  static const settings = '/settings';

  /// Application information.
  static const about = '/settings/about';

  /// Privacy policy.
  static const privacy = '/settings/privacy';

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
    settings,
    about,
    privacy,
  ];
}
