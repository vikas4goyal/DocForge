/// Builds the document-creation flow's entry screen.
library;

import 'package:doc_scanly/app/creation_module.dart';
import 'package:doc_scanly/app/router/app_router.dart';
import 'package:doc_scanly/app/router/app_routes.dart';
import 'package:go_router/go_router.dart';

/// Builds the creation flow: the page table and the loop that fills it.
///
/// Cancellation returns Home; a successful save opens the new document in the
/// Viewer, which owns the app's reading journey.
ScreenBuilder buildCreationScreen({required CreationModule creationFlow}) =>
    (context) => CreationFlow(
      module: creationFlow,
      onExit: () => context.go(AppRoutes.home),
      onSaved: (document) =>
          context.pushReplacement(AppRoutes.documentView(document.id)),
    );
