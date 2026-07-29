/// A list of documents.
///
/// One screen serves all documents, favourites, the archive and a folder's
/// contents: they differ only in the filter their Cubit was constructed with
/// and in the wording of the empty state. Four near-identical screens would
/// drift apart, and the spec requires the same loading, empty and error
/// behaviour from each.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:doc_forge/features/document_library/presentation/library_keys.dart';
import 'package:doc_forge/features/document_library/presentation/widgets/document_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows the documents held by a [DocumentListCubit].
class DocumentListScreen extends StatefulWidget {
  /// Creates a document list.
  ///
  /// [onOpenDocument] is a callback rather than direct navigation so the screen
  /// can be widget-tested and previewed without a router.
  const DocumentListScreen({
    required this.title,
    required this.onOpenDocument,
    super.key,
    this.emptyTitle,
    this.emptyMessage,
    this.onScan,
    this.actions,
  });

  /// Title shown in the app bar.
  final String title;

  /// Called when a document row is activated.
  final void Function(DocumentId id) onOpenDocument;

  /// Heading of the empty state. Defaults to wording for a general list.
  final String? emptyTitle;

  /// Guidance shown in the empty state.
  final String? emptyMessage;

  /// Called when the empty state's call to action is used.
  ///
  /// When null no action is offered — appropriate for the archive, where
  /// "scan a document" is not what an empty list should suggest.
  final VoidCallback? onScan;

  /// Extra app-bar actions supplied by the host route.
  final List<Widget>? actions;

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Loading here rather than in the Cubit's constructor: a Cubit that starts
    // work on construction cannot be built in a test without also running it.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DocumentListCubit>().load(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Requests the next page as the list approaches its end.
  ///
  /// Triggers a screen's height before the bottom so the next page is usually
  /// present by the time the user reaches it, rather than after a visible stall.
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >=
        position.maxScrollExtent - position.viewportDimension) {
      context.read<DocumentListCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: LibraryKeys.documentListScreen,
      appBar: AppBar(title: Text(widget.title), actions: widget.actions),
      body: BlocBuilder<DocumentListCubit, DocumentListState>(
        builder: (context, state) => switch (state.status) {
          LoadStatus.initial || LoadStatus.loading => const AppLoadingIndicator(
            key: LibraryKeys.documentListLoading,
          ),
          LoadStatus.empty => AppEmptyState(
            key: LibraryKeys.documentListEmptyState,
            icon: Icons.folder_open_outlined,
            title: widget.emptyTitle ?? 'No documents yet',
            message: widget.emptyMessage,
            actionLabel: widget.onScan == null ? null : 'Scan a document',
            onAction: widget.onScan,
          ),
          LoadStatus.failure => AppErrorView(
            key: LibraryKeys.documentListErrorView,
            // The failure the load actually produced, so the recovery offered
            // matches the cause rather than always being a bare retry.
            failure: state.failure ?? const Failure.unexpected(),
            retryKey: LibraryKeys.documentListRetryButton,
            onRetry: () => context.read<DocumentListCubit>().load(),
          ),
          LoadStatus.ready => _DocumentList(
            state: state,
            controller: _scrollController,
            onOpenDocument: widget.onOpenDocument,
          ),
        },
      ),
    );
  }
}

/// The populated list.
class _DocumentList extends StatelessWidget {
  const _DocumentList({
    required this.state,
    required this.controller,
    required this.onOpenDocument,
  });

  final DocumentListState state;
  final ScrollController controller;
  final void Function(DocumentId id) onOpenDocument;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<DocumentListCubit>().load,
      child: ResponsiveLayout(
        compact: (context) => _buildList(context, columns: 1),
        medium: (context) => _buildList(context, columns: 2),
        expanded: (context) => _buildList(context, columns: 3),
      ),
    );
  }

  /// Builds the list, laying rows out in [columns] columns.
  ///
  /// A grid rather than a wider single column on a tablet: a full-width row for
  /// a two-line document summary wastes most of the screen.
  Widget _buildList(BuildContext context, {required int columns}) {
    // The trailing footer slot holds the "loading more" indicator, so it must
    // be counted even when nothing is loading or the scroll extent jumps as it
    // appears.
    final itemCount = state.documents.length + (state.hasMore ? 1 : 0);

    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        // Tall enough for two lines of title at a large text scale.
        mainAxisExtent: 88,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= state.documents.length) {
          return const Center(
            key: LibraryKeys.documentListLoadMore,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: AppTheme.minimumTouchTarget,
                height: AppTheme.minimumTouchTarget,
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
            ),
          );
        }

        final document = state.documents[index];
        return DocumentCard(
          document: document,
          onTap: () => onOpenDocument(document.id),
          onToggleFavourite: () =>
              context.read<DocumentListCubit>().toggleFavourite(document.id),
        );
      },
    );
  }
}
