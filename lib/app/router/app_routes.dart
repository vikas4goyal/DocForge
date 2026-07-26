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

  /// Home screen — the application's primary screen.
  static const home = '/';

  /// Camera capture.
  static const scan = '/scan';

  /// Review of the pages captured in the current session.
  static const scanReview = '/scan/review';

  /// Enhancement of the current session's pages.
  static const scanEnhance = '/scan/enhance';

  /// Preview of the document about to be saved.
  static const scanPreview = '/scan/preview';

  /// All documents.
  static const documents = '/documents';

  /// A single document's detail screen.
  ///
  /// Template form; use [documentDetail] to build a concrete location.
  static const documentDetailTemplate = '/documents/:id';

  /// A document's editing tools.
  static const documentEditTemplate = '/documents/:id/edit';

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

  /// Returns the location of the contents of folder [id].
  static String folderDetail(FolderId id) => '/folders/${id.value}';

  /// Every non-templated route, for tests that assert full coverage.
  static const all = <String>[
    onboarding,
    unlock,
    home,
    scan,
    scanReview,
    scanEnhance,
    scanPreview,
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
