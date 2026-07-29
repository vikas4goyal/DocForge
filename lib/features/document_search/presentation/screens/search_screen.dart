/// The search screen and its result row.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/formatting/display_formatting.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/document_search/domain/search_query.dart';
import 'package:doc_forge/features/document_search/presentation/bloc/search_bloc.dart';
import 'package:doc_forge/features/document_search/presentation/search_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Searches documents by title and recognised text.
class SearchScreen extends StatefulWidget {
  /// Creates the search screen.
  const SearchScreen({
    required this.onOpenDocument,
    required this.folders,
    super.key,
  });

  /// Called when the user opens a result.
  final void Function(DocumentId id) onOpenDocument;

  /// The folders offered by the folder filter.
  final List<Folder> folders;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        final bloc = context.read<SearchBloc>();

        return Scaffold(
          key: SearchKeys.screen,
          appBar: AppBar(
            title: TextField(
              key: SearchKeys.inputField,
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (term) => bloc.add(SearchTermChanged(term)),
              decoration: InputDecoration(
                hintText: 'Search documents',
                border: InputBorder.none,
                suffixIcon: state.canClear
                    ? IconButton(
                        key: SearchKeys.clearButton,
                        onPressed: () {
                          _controller.clear();
                          bloc.add(const SearchCleared());
                        },
                        icon: const Icon(
                          Icons.close,
                          semanticLabel: 'Clear search',
                        ),
                        tooltip: 'Clear search',
                      )
                    : null,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _Filters(state: state, bloc: bloc, folders: widget.folders),
                const Divider(height: 1),
                Expanded(
                  child: _Results(
                    state: state,
                    bloc: bloc,
                    onOpenDocument: widget.onOpenDocument,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The folder and date filters.
class _Filters extends StatelessWidget {
  const _Filters({
    required this.state,
    required this.bloc,
    required this.folders,
  });

  final SearchState state;
  final SearchBloc bloc;
  final List<Folder> folders;

  @override
  Widget build(BuildContext context) {
    final selectedFolder = state.query.folderId;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Semantics(
            button: true,
            selected: selectedFolder != null,
            label: selectedFolder == null
                ? 'Filter by folder'
                : 'Filtered to one folder',
            child: ExcludeSemantics(
              child: PopupMenuButton<FolderId?>(
                key: SearchKeys.filterFolder,
                // Tapping the chip must open the menu, so the chip itself has
                // no handler — the menu button owns the gesture.
                onSelected: (id) => bloc.add(SearchFolderFilterChanged(id)),
                itemBuilder: (context) => [
                  const PopupMenuItem<FolderId?>(child: Text('All folders')),
                  for (final folder in folders)
                    PopupMenuItem<FolderId?>(
                      value: folder.id,
                      child: Text(folder.name),
                    ),
                ],
                child: Chip(
                  avatar: const Icon(Icons.folder_outlined, size: 18),
                  label: Text(
                    selectedFolder == null
                        ? 'Any folder'
                        : folders
                              .firstWhere(
                                (folder) => folder.id == selectedFolder,
                                orElse: () => folders.isEmpty
                                    ? _unknownFolder
                                    : folders.first,
                              )
                              .name,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            selected: state.query.modifiedWithin != null,
            label: SearchSemantics.filterByDate,
            child: ExcludeSemantics(
              child: ActionChip(
                key: SearchKeys.filterDate,
                avatar: const Icon(Icons.event_outlined, size: 18),
                label: Text(
                  state.query.modifiedWithin == null
                      ? 'Any date'
                      : 'Recent only',
                ),
                onPressed: () => bloc.add(
                  SearchDateFilterChanged(
                    // Toggles rather than opening a picker: the spec asks for a
                    // date filter, and a one-tap "recent" covers the common
                    // case without a modal for something the user is doing
                    // while typing.
                    modified: state.query.modifiedWithin == null
                        ? DateRange(
                            from: DateTime.now().toUtc().subtract(
                              const Duration(days: 30),
                            ),
                          )
                        : const DateRange(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Stands in when a filtered folder is no longer in the list.
  static final _unknownFolder = Folder(
    id: const FolderId('unknown'),
    name: 'Folder',
    createdAt: DateTime.utc(2026),
  );
}

/// Whichever of the screen's result states is current.
class _Results extends StatelessWidget {
  const _Results({
    required this.state,
    required this.bloc,
    required this.onOpenDocument,
  });

  final SearchState state;
  final SearchBloc bloc;
  final void Function(DocumentId id) onOpenDocument;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      SearchStatus.initial => const AppEmptyState(
        key: SearchKeys.initialState,
        title: 'Search your documents',
        message: 'Find a document by its name or by the text on its pages.',
        icon: Icons.search,
      ),
      SearchStatus.searching => const AppLoadingIndicator(
        key: SearchKeys.loadingIndicator,
        semanticsLabel: 'Searching',
      ),
      SearchStatus.empty => const AppEmptyState(
        key: SearchKeys.emptyState,
        title: 'Nothing matched',
        message:
            'Try a shorter term, or remove a filter to search more '
            'widely.',
        icon: Icons.search_off_outlined,
      ),
      SearchStatus.failure when state.failure != null => AppErrorView(
        key: SearchKeys.errorView,
        failure: state.failure!,
        retryKey: SearchKeys.errorRetryButton,
        onRetry: () => bloc.add(SearchTermChanged(state.query.term)),
      ),
      _ => Semantics(
        // Announced on change: a list that silently changes length tells a
        // screen-reader user nothing.
        liveRegion: true,
        label: state.resultCountLabel,
        child: ListView.separated(
          key: SearchKeys.resultsList,
          itemCount: state.results.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => SearchResultRow(
            result: state.results[index],
            onTap: () => onOpenDocument(state.results[index].document.id),
          ),
        ),
      ),
    };
  }
}

/// One search result, showing why it matched.
///
/// A recognised-text match shows its snippet: without one, a document whose
/// title does not contain the term looks like a mistake.
class SearchResultRow extends StatelessWidget {
  /// Creates a result row.
  const SearchResultRow({required this.result, super.key, this.onTap});

  /// The result to present.
  final SearchResult result;

  /// Called when the row is activated.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final document = result.document;

    final subtitle = result.hasSnippet
        ? result.snippet
        : DisplayFormatting.documentSubtitle(document);

    return Semantics(
      button: onTap != null,
      label: [
        document.title,
        if (result.source == MatchSource.recognisedText)
          'matched in the document text',
        subtitle,
      ].join(', '),
      child: ExcludeSemantics(
        child: ListTile(
          key: SearchKeys.resultRow(document.id.value),
          onTap: onTap,
          leading: Icon(
            result.source == MatchSource.recognisedText
                ? Icons.text_snippet_outlined
                : Icons.description_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            document.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}
