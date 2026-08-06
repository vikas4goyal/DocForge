/// Screens that announce which route resolved them.
///
/// Two router tests each grew their own copy of this set — sixteen builders,
/// identical but for the wording each used to name itself. Two copies of a
/// sixteen-field literal is two places to update when a route is added, and the
/// one that is forgotten fails with a compile error at best and a misleading
/// assertion at worst.
///
/// This is the Tier-1 counterpart to the real screen set: `buildAppScreens`
/// builds the application's, and this builds one where every route renders its
/// own name, so a navigation test asserts on *routing* without dragging in a
/// feature's widgets, Cubits or use cases.
library;

import 'package:doc_scanly/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A screen that renders [name], so a test can assert which one resolved.
Widget markerScreen(String name) => Scaffold(body: Center(child: Text(name)));

/// The name [markerScreen] renders for each route.
///
/// Exposed as constants rather than left as literals in each test, so a test
/// asserts on the same string the screen set produces and a rename cannot make
/// the two disagree silently.
abstract final class RouteMarkers {
  /// First-launch onboarding.
  static const onboarding = 'onboarding';

  /// The application lock.
  static const unlock = 'unlock';

  /// Home.
  static const home = 'home';

  /// The creation flow.
  static const scan = 'scan';

  /// All documents.
  static const documents = 'documents';

  /// All folders.
  static const folders = 'folders';

  /// Search.
  static const search = 'search';

  /// Favourites.
  static const favourites = 'favourites';

  /// The archive.
  static const archive = 'archive';

  /// Recoverable Trash.
  static const trash = 'trash';

  /// Settings.
  static const settings = 'settings';

  /// About.
  static const about = 'about';

  /// The privacy policy.
  static const privacy = 'privacy';

  /// One document's detail screen, named with the document it resolved.
  static String documentDetail(String id) => 'documentDetail:$id';

  /// The viewer, named with the document it resolved.
  static String viewer(String id) => 'viewer:$id';

  /// A document's editing tools, named with the document it resolved.
  static String documentEdit(String id) => 'documentEdit:$id';

  /// A folder's contents, named with the folder it resolved.
  static String folderDetail(String id) => 'folderDetail:$id';
}

/// A screen set where every route renders its own name.
///
/// The parameterised routes render the identifier they were given as well, so a
/// test can prove not only that the right route resolved but that it resolved
/// with the right argument — which is the half a bare route assertion misses.
AppScreens markerScreens({bool includeStorageLocation = false}) => AppScreens(
  onboarding: (_) => markerScreen(RouteMarkers.onboarding),
  unlock: (_) => markerScreen(RouteMarkers.unlock),
  home: (_) => markerScreen(RouteMarkers.home),
  scan: (_) => markerScreen(RouteMarkers.scan),
  documents: (_) => markerScreen(RouteMarkers.documents),
  documentDetail: (_, id) =>
      markerScreen(RouteMarkers.documentDetail(id.value)),
  viewer: (_, id) => markerScreen(RouteMarkers.viewer(id.value)),
  documentEdit: (_, id) => markerScreen(RouteMarkers.documentEdit(id.value)),
  folders: (_) => markerScreen(RouteMarkers.folders),
  folderDetail: (_, id) => markerScreen(RouteMarkers.folderDetail(id.value)),
  search: (_) => markerScreen(RouteMarkers.search),
  favourites: (_) => markerScreen(RouteMarkers.favourites),
  archive: (_) => markerScreen(RouteMarkers.archive),
  trash: (_) => markerScreen(RouteMarkers.trash),
  settings: (_) => markerScreen(RouteMarkers.settings),
  about: (_) => markerScreen(RouteMarkers.about),
  privacy: (_) => markerScreen(RouteMarkers.privacy),
  storageLocation: includeStorageLocation
      ? (_) => markerScreen('storageLocation')
      : null,
);

/// Asserts that the route rendering [name] is the one on screen.
void expectRoute(String name) => expect(
  find.text(name),
  findsOneWidget,
  reason: 'expected the $name route to be showing',
);
