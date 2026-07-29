/// The application's single GoRouter configuration.
///
/// Every route in the app is declared here and reached through [AppRoutes], so
/// no feature contains a navigation string literal. Screens are supplied by the
/// caller rather than imported directly, which keeps `lib/app/` free of any
/// dependency on a feature and lets a navigation test exercise the real routing
/// and gate behaviour against trivial placeholder screens.
library;

import 'package:doc_forge/app/router/app_routes.dart';
import 'package:doc_forge/app/router/route_gates.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/core/widgets/core_keys.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builds the widget for a route that takes no parameters.
typedef ScreenBuilder = Widget Function(BuildContext context);

/// Builds the widget for a route identified by a document.
typedef DocumentScreenBuilder =
    Widget Function(BuildContext context, DocumentId id);

/// Builds the widget for a route identified by a folder.
typedef FolderScreenBuilder =
    Widget Function(BuildContext context, FolderId id);

/// The screens each route renders.
///
/// Injected rather than imported so the router depends on no feature. A
/// navigation test supplies placeholders; the application supplies the real
/// screens from the composition root.
@immutable
class AppScreens {
  /// Creates the screen set.
  const AppScreens({
    required this.onboarding,
    required this.unlock,
    required this.home,
    required this.scan,
    required this.documents,
    required this.documentDetail,
    required this.viewer,
    required this.documentEdit,
    required this.folders,
    required this.folderDetail,
    required this.search,
    required this.favourites,
    required this.archive,
    required this.settings,
    required this.about,
    required this.privacy,
  });

  /// First-launch onboarding.
  final ScreenBuilder onboarding;

  /// Application lock screen.
  final ScreenBuilder unlock;

  /// Home.
  final ScreenBuilder home;

  /// The creation flow: the page table and the loop that fills it.
  final ScreenBuilder scan;

  /// All documents.
  final ScreenBuilder documents;

  /// A single document.
  final DocumentScreenBuilder documentDetail;

  /// Builds the viewer for one document.
  final DocumentScreenBuilder viewer;

  /// A document's editing tools.
  final DocumentScreenBuilder documentEdit;

  /// All folders.
  final ScreenBuilder folders;

  /// A folder's contents.
  final FolderScreenBuilder folderDetail;

  /// Search.
  final ScreenBuilder search;

  /// Favourites.
  final ScreenBuilder favourites;

  /// Archive.
  final ScreenBuilder archive;

  /// Settings.
  final ScreenBuilder settings;

  /// About.
  final ScreenBuilder about;

  /// Privacy policy.
  final ScreenBuilder privacy;
}

/// Creates the application router.
///
/// [guard] decides redirects; see [RouteGuard] for why the lock gate is
/// evaluated before the onboarding gate. [refreshListenable] causes GoRouter to
/// re-evaluate redirects when gate state changes — without it, unlocking the
/// app would leave the user sitting on the unlock screen.
/// [observers] are handed to the router so a screen can learn when a route
/// pushed over it has popped. Home needs that: it is built once and kept alive,
/// so nothing else would tell it that a document was added while it was covered.
GoRouter createAppRouter({
  required RouteGuard guard,
  required AppScreens screens,
  String initialLocation = AppRoutes.home,
  Listenable? refreshListenable,
  List<NavigatorObserver> observers = const [],
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    observers: observers,
    redirect: (context, state) => guard.redirectFor(state.matchedLocation),
    errorBuilder: (context, state) => _RouteNotFound(location: state.uri.path),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => screens.onboarding(context),
      ),
      GoRoute(
        path: AppRoutes.unlock,
        builder: (context, state) => screens.unlock(context),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => screens.home(context),
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (context, state) => screens.scan(context),
      ),
      GoRoute(
        path: AppRoutes.documents,
        builder: (context, state) => screens.documents(context),
      ),
      GoRoute(
        path: AppRoutes.documentDetailTemplate,
        builder: (context, state) => screens.documentDetail(
          context,
          DocumentId(state.pathParameters[AppRoutes.idParameter]!),
        ),
        routes: [
          GoRoute(
            path: 'view',
            builder: (context, state) => screens.viewer(
              context,
              DocumentId(state.pathParameters[AppRoutes.idParameter]!),
            ),
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) => screens.documentEdit(
              context,
              DocumentId(state.pathParameters[AppRoutes.idParameter]!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.folders,
        builder: (context, state) => screens.folders(context),
      ),
      GoRoute(
        path: AppRoutes.folderDetailTemplate,
        builder: (context, state) => screens.folderDetail(
          context,
          FolderId(state.pathParameters[AppRoutes.idParameter]!),
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => screens.search(context),
      ),
      GoRoute(
        path: AppRoutes.favourites,
        builder: (context, state) => screens.favourites(context),
      ),
      GoRoute(
        path: AppRoutes.archive,
        builder: (context, state) => screens.archive(context),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => screens.settings(context),
        routes: [
          GoRoute(
            path: 'about',
            builder: (context, state) => screens.about(context),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => screens.privacy(context),
          ),
        ],
      ),
    ],
  );
}

/// Shown when a location matches no route.
///
/// The app-shell spec requires a not-found state with a way back to Home rather
/// than a crash — a stale deep link to a deleted document must not kill the app.
class _RouteNotFound extends StatelessWidget {
  const _RouteNotFound({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: CoreKeys.routeNotFoundScreen,
      appBar: AppBar(title: const Text('Not found')),
      body: AppEmptyState(
        key: CoreKeys.routeNotFoundState,
        title: 'That page does not exist',
        message: location,
        icon: Icons.help_outline,
        actionLabel: 'Go to Home',
        onAction: () => context.go(AppRoutes.home),
      ),
    );
  }
}
