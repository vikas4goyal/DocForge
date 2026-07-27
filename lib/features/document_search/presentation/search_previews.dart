/// Widget previews for search.
///
/// Every preview is fed by fixtures through a seeded Bloc, so nothing here
/// queries a database (`design.md` §15).
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/previews/preview_scaffold.dart';
import 'package:doc_forge/features/document_search/domain/search_query.dart';
import 'package:doc_forge/features/document_search/infrastructure/repositories/indexed_search_repository.dart';
import 'package:doc_forge/features/document_search/presentation/bloc/search_bloc.dart';
import 'package:doc_forge/features/document_search/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A fixture document.
Document _document(String id, String title) => Document(
  id: DocumentId(id),
  title: title,
  // Fixed, so every preview and golden built on it is byte-stable.
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 3, 14),
  pageCount: 4,
  sizeInBytes: 184_320,
  filePath: '/preview/$id.pdf',
);

/// The folders the filter offers.
List<Folder> _folders() => [
  Folder(
    id: const FolderId('f1'),
    name: 'Receipts',
    createdAt: DateTime.utc(2026),
  ),
  Folder(
    id: const FolderId('f2'),
    name: 'Invoices',
    createdAt: DateTime.utc(2026),
  ),
];

/// Fixture results.
List<SearchResult> _results({int count = 4, bool withSnippets = true}) => [
  for (var index = 0; index < count; index++)
    SearchResult(
      document: _document('preview-$index', 'Invoice $index'),
      source: withSnippets && index.isOdd
          ? MatchSource.recognisedText
          : MatchSource.title,
      snippet: withSnippets && index.isOdd
          ? '…Acme Limited issued this invoice on the fourteenth of March…'
          : '',
    ),
];

/// A [SearchBloc] frozen at a chosen state.
///
/// Seeded through its own event stream rather than by emitting: a Bloc's
/// `emit` is protected and its transformers are the thing under preview, so
/// driving it the way the screen does keeps the preview honest.
class _PreviewSearchBloc extends SearchBloc {
  _PreviewSearchBloc(this._seeded)
    : super(
        IndexedSearchRepository(
          InMemoryTitleIndex(),
          InMemoryOcrIndex(),
          InMemoryDocumentLookup(),
        ),
      );

  final SearchState _seeded;

  @override
  SearchState get state => _seeded;
}

Widget _screen(SearchState state) => BlocProvider<SearchBloc>(
  create: (_) => _PreviewSearchBloc(state),
  child: SearchScreen(onOpenDocument: (_) {}, folders: _folders()),
);

// ---------------------------------------------------------------------------
// Search screen
// ---------------------------------------------------------------------------

/// The screen before anything has been searched for.
@Preview(name: 'Search — default', group: 'Search', theme: appPreviewTheme)
Widget searchDefault() => _screen(const SearchState.initial());

/// Results for a term that matched several documents.
@Preview(name: 'Search — results', group: 'Search', theme: appPreviewTheme)
Widget searchResults() => _screen(
  const SearchState.initial().copyWith(
    status: SearchStatus.results,
    query: const SearchQuery(term: 'invoice'),
    results: _results(),
  ),
);

/// A search that is still running.
@Preview(name: 'Search — loading', group: 'Search', theme: appPreviewTheme)
Widget searchLoading() => _screen(
  const SearchState.initial().copyWith(
    status: SearchStatus.searching,
    query: const SearchQuery(term: 'invoice'),
  ),
);

/// A search that matched nothing.
@Preview(name: 'Search — empty', group: 'Search', theme: appPreviewTheme)
Widget searchEmpty() => _screen(
  const SearchState.initial().copyWith(
    status: SearchStatus.empty,
    query: const SearchQuery(term: 'aardvark'),
  ),
);

/// A search that failed.
@Preview(name: 'Search — error', group: 'Search', theme: appPreviewTheme)
Widget searchError() => _screen(
  const SearchState.initial().copyWith(
    status: SearchStatus.failure,
    query: const SearchQuery(term: 'invoice'),
    failure: const Failure.storage(),
  ),
);

/// A search narrowed by a folder.
@Preview(name: 'Search — filtered', group: 'Search', theme: appPreviewTheme)
Widget searchFiltered() => _screen(
  const SearchState.initial().copyWith(
    status: SearchStatus.results,
    query: const SearchQuery(term: 'invoice', folderId: FolderId('f2')),
    results: _results(count: 2),
  ),
);

/// A long result list, where scrolling and truncation both matter.
@Preview(name: 'Search — long content', group: 'Search', theme: appPreviewTheme)
Widget searchLongContent() => _screen(
  const SearchState.initial().copyWith(
    status: SearchStatus.results,
    query: const SearchQuery(term: 'invoice'),
    results: _results(count: 40),
  ),
);

/// The screen on a phone, light.
@Preview(
  name: 'Search — phone, light',
  group: 'Search',
  size: PreviewSize.phone,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget searchPhoneLight() => _screen(
  const SearchState.initial().copyWith(
    status: SearchStatus.results,
    query: const SearchQuery(term: 'invoice'),
    results: _results(),
  ),
);

/// The screen on a phone, dark.
@Preview(
  name: 'Search — phone, dark',
  group: 'Search',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget searchPhoneDark() => _screen(
  const SearchState.initial().copyWith(
    status: SearchStatus.results,
    query: const SearchQuery(term: 'invoice'),
    results: _results(),
  ),
);

/// The screen on a tablet, light.
@Preview(
  name: 'Search — tablet, light',
  group: 'Search',
  size: PreviewSize.tablet,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget searchTabletLight() => _screen(
  const SearchState.initial().copyWith(
    status: SearchStatus.results,
    query: const SearchQuery(term: 'invoice'),
    results: _results(count: 8),
  ),
);

/// The screen on a tablet, dark.
@Preview(
  name: 'Search — tablet, dark',
  group: 'Search',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget searchTabletDark() => _screen(
  const SearchState.initial().copyWith(
    status: SearchStatus.results,
    query: const SearchQuery(term: 'invoice'),
    results: _results(count: 8),
  ),
);

// ---------------------------------------------------------------------------
// Result row
// ---------------------------------------------------------------------------

/// A row whose title matched.
@Preview(
  name: 'SearchResultRow — default',
  group: 'Search',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget resultRowDefault() => SearchResultRow(
  result: SearchResult(
    document: _document('preview-0', 'Invoice 2026'),
    source: MatchSource.title,
  ),
  onTap: () {},
);

/// A row whose recognised text matched, showing its snippet.
@Preview(
  name: 'SearchResultRow — text match',
  group: 'Search',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget resultRowTextMatch() => SearchResultRow(
  result: SearchResult(
    document: _document('preview-1', 'Scan 2026-03-14'),
    source: MatchSource.recognisedText,
    snippet: '…Acme Limited issued this invoice on the fourteenth of March…',
  ),
  onTap: () {},
);

/// A row with a title and snippet long enough to truncate.
@Preview(
  name: 'SearchResultRow — long content',
  group: 'Search',
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget resultRowLongContent() => SearchResultRow(
  result: SearchResult(
    document: _document(
      'preview-2',
      'Quarterly consulting invoice for services rendered to Acme Limited',
    ),
    source: MatchSource.recognisedText,
    snippet:
        '…the quick brown fox jumps over the lazy dog, twice, and then once '
        'more for good measure before the sentence finally ends…',
  ),
  onTap: () {},
);

/// A row with no handler, as it appears while a search is running.
@Preview(
  name: 'SearchResultRow — disabled',
  group: 'Search',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget resultRowDisabled() => SearchResultRow(
  result: SearchResult(
    document: _document('preview-3', 'Receipt'),
    source: MatchSource.title,
  ),
);
