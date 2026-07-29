/// Builds the search screen.
library;

import 'package:doc_forge/app/library_module.dart';
import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/app_routes.dart';
import 'package:doc_forge/features/document_search/presentation/bloc/search_bloc.dart';
import 'package:doc_forge/features/document_search/presentation/screens/search_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Builds search over the [library] module's search use case.
///
/// A Bloc rather than a Cubit here is the search feature's own decision: the
/// query stream is debounced, which is exactly the event-driven case the
/// project's state-management rule reserves a Bloc for.
ScreenBuilder buildSearchScreen({required LibraryModule library}) =>
    (context) => BlocProvider(
      create: (_) => SearchBloc(library.search),
      child: SearchScreen(
        onOpenDocument: (id) => context.push(AppRoutes.documentDetail(id)),
        // Folders are loaded lazily by the screen's own filter in a later
        // step; an empty list simply means the filter offers "all folders".
        folders: const [],
      ),
    );
