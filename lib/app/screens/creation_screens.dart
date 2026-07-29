/// Builds the document-creation flow's entry screen.
library;

import 'package:doc_forge/app/creation_module.dart';
import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/app_routes.dart';
import 'package:go_router/go_router.dart';

/// Builds the creation flow: the page table and the loop that fills it.
///
/// Both exits go to Home rather than popping, because the flow is entered from
/// several places and popping would return the user to whichever of them they
/// happened to come from. Home reloads on navigation, so a document saved here
/// appears at the top of Recent without anything having to tell it.
ScreenBuilder buildCreationScreen({required CreationModule creationFlow}) =>
    (context) => CreationFlow(
      module: creationFlow,
      onExit: () => context.go(AppRoutes.home),
      onSaved: (_) => context.go(AppRoutes.home),
    );
