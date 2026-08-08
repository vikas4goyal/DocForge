/// Builds the search screen.
library;

import 'package:doc_scanly/app/library_module.dart';
import 'package:doc_scanly/app/router/app_router.dart';
import 'package:doc_scanly/app/router/app_routes.dart';
import 'package:doc_scanly/features/document_search/presentation/bloc/search_bloc.dart';
import 'package:doc_scanly/features/document_search/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
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
      child: Builder(
        builder: (searchContext) => SearchScreen(
          onOpenDocument: (id) async {
            await context.push(AppRoutes.documentView(id));
            if (searchContext.mounted) {
              searchContext.read<SearchBloc>().add(
                const SearchRefreshRequested(),
              );
            }
          },
          // Folders are loaded lazily by the screen's own filter in a later
          // step; an empty list simply means the filter offers "all folders".
          folders: const [],
        ),
      ),
    );
