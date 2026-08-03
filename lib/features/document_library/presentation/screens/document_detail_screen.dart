/// A single document's detail screen.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/formatting/display_formatting.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_detail_state.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:doc_forge/features/document_library/presentation/library_keys.dart';
import 'package:doc_forge/features/document_library/presentation/widgets/library_dialogs.dart';
import 'package:doc_forge/features/document_library/presentation/widgets/page_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows a document's metadata, pages and lifecycle actions.
class DocumentDetailScreen extends StatefulWidget {
  /// Creates a detail screen.
  ///
  /// Navigation is delegated to callbacks so the screen builds without a
  /// router, which is what makes it previewable and widget-testable.
  const DocumentDetailScreen({
    required this.onClose,
    super.key,
    this.folders = const [],
    this.onOpenViewer,
    this.onOpenDocument,
  });

  /// Called when the document is gone and the screen must leave.
  final VoidCallback onClose;

  /// Folders offered by the move picker.
  final List<Folder> folders;

  /// Called when the user opens the document in the viewer.
  final VoidCallback? onOpenViewer;

  /// Called with a newly created duplicate, so the caller can navigate to it.
  final void Function(Document document)? onOpenDocument;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DocumentDetailCubit>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentDetailCubit, DocumentDetailState>(
      listenWhen: (previous, current) =>
          (!previous.isDeleted && current.isDeleted) ||
          (previous.failure != current.failure && current.failure != null),
      listener: (context, state) {
        if (state.isDeleted) {
          widget.onClose();
          return;
        }

        // A failed *action* is a transient message, not a screen state: the
        // document is still there and still readable.
        final message = state.message;
        if (message != null && state.status != LoadStatus.failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) => Scaffold(
        key: LibraryKeys.documentDetailScreen,
        appBar: AppBar(
          title: Text(state.document?.title ?? 'Document'),
          actions: state.document == null
              ? null
              : [_ActionMenu(document: state.document!, host: widget)],
        ),
        body: switch (state.status) {
          LoadStatus.initial ||
          LoadStatus.loading => const AppLoadingIndicator(),
          LoadStatus.failure => AppErrorView(
            failure: state.failure ?? const Failure.unexpected(),
            onRetry: () => context.read<DocumentDetailCubit>().load(),
            onGoBack: widget.onClose,
          ),
          // A document always has at least one page, so there is no empty state
          // to reach here; a document that lost its record is a failure.
          LoadStatus.ready || LoadStatus.empty => _Body(
            state: state,
            onOpenViewer: widget.onOpenViewer,
          ),
        },
      ),
    );
  }
}

/// The metadata block, favourite control and page strip.
class _Body extends StatelessWidget {
  const _Body({required this.state, required this.onOpenViewer});

  final DocumentDetailState state;
  final VoidCallback? onOpenViewer;

  @override
  Widget build(BuildContext context) {
    final document = state.document;
    if (document == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.isWorking) const LinearProgressIndicator(),
        Text(document.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        _MetadataRow(
          label: 'Pages',
          value: DisplayFormatting.pageCount(document.pageCount),
        ),
        _MetadataRow(
          label: 'Size',
          value: DisplayFormatting.fileSize(document.sizeInBytes),
        ),
        _MetadataRow(
          label: 'Created',
          value: DisplayFormatting.dateTime(document.createdAt),
        ),
        _MetadataRow(
          label: 'Modified',
          value: DisplayFormatting.dateTime(document.updatedAt),
        ),
        if (document.isArchived)
          const _MetadataRow(label: 'Status', value: 'Archived'),
        const SizedBox(height: 8),
        _FavouriteRow(isFavourite: document.isFavourite),
        if (onOpenViewer != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            key: LibraryKeys.documentOpenButton,
            onPressed: onOpenViewer,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Open'),
          ),
        ],
        const SizedBox(height: 24),
        Text('Pages', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: state.pages.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Page previews are not available.',
                    style: theme.textTheme.bodySmall,
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.pages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      PageThumbnail(page: state.pages[index]),
                ),
        ),
      ],
    );
  }
}

/// One labelled metadata line.
class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      // Merged so a screen reader announces "Pages, 3" as one item rather than
      // two disconnected fragments.
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

/// The favourite toggle on the detail screen.
class _FavouriteRow extends StatelessWidget {
  const _FavouriteRow({required this.isFavourite});

  final bool isFavourite;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        toggled: isFavourite,
        label: isFavourite ? 'Remove from favourites' : 'Add to favourites',
        child: ExcludeSemantics(
          child: TextButton.icon(
            key: LibraryKeys.documentFavouriteToggle,
            onPressed: context.read<DocumentDetailCubit>().toggleFavourite,
            icon: Icon(isFavourite ? Icons.star : Icons.star_border),
            label: Text(isFavourite ? 'Favourite' : 'Add to favourites'),
          ),
        ),
      ),
    );
  }
}

/// The lifecycle action menu.
class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.document, required this.host});

  final Document document;
  final DocumentDetailScreen host;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocumentDetailCubit>();

    return PopupMenuButton<void>(
      key: LibraryKeys.documentDetailMenu,
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          key: LibraryKeys.documentRenameButton,
          onTap: () => _rename(context, cubit),
          child: const Text('Rename'),
        ),
        PopupMenuItem<void>(
          key: LibraryKeys.documentMoveButton,
          onTap: () => _move(context, cubit),
          child: const Text('Move to folder'),
        ),
        PopupMenuItem<void>(
          key: LibraryKeys.documentDuplicateButton,
          onTap: () => _duplicate(cubit),
          child: const Text('Duplicate'),
        ),
        if (document.isArchived)
          PopupMenuItem<void>(
            key: LibraryKeys.documentRestoreButton,
            onTap: cubit.restore,
            child: const Text('Restore'),
          )
        else
          PopupMenuItem<void>(
            key: LibraryKeys.documentArchiveButton,
            onTap: cubit.archive,
            child: const Text('Archive'),
          ),
        PopupMenuItem<void>(
          key: LibraryKeys.documentDeleteButton,
          onTap: () => _delete(context, cubit),
          child: const Text('Move to Trash'),
        ),
      ],
    );
  }

  /// Asks for a new title, then applies it.
  ///
  /// `onTap` fires as the menu closes, so the dialog is opened on the next
  /// frame — showing it while the menu route is still popping loses it.
  void _rename(BuildContext context, DocumentDetailCubit cubit) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final name = await showNameDialog(
        context,
        title: 'Rename document',
        confirmLabel: 'Rename',
        initialValue: document.title,
      );

      if (name != null) await cubit.rename(name);
    });
  }

  void _move(BuildContext context, DocumentDetailCubit cubit) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final choice = await showFolderPicker(context, folders: host.folders);

      switch (choice) {
        case null:
          return;
        case NoFolderChosen():
          await cubit.move(null);
        case FolderChosen(:final folder):
          await cubit.move(folder.id);
      }
    });
  }

  void _duplicate(DocumentDetailCubit cubit) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final copy = await cubit.duplicate();
      if (copy != null) host.onOpenDocument?.call(copy);
    });
  }

  /// Confirms, then moves the document to recoverable Trash.
  ///
  /// The confirmation is mandatory and lives here rather than in the Cubit:
  /// asking is a UI concern, and a Cubit that showed a dialog could not be
  /// unit-tested.
  void _delete(BuildContext context, DocumentDetailCubit cubit) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          key: LibraryKeys.documentDeleteConfirmDialog,
          title: Text('Move ${document.title} to Trash?'),
          content: const Text(
            'You can restore this document for 30 days. After that it will be permanently deleted.',
          ),
          actions: [
            TextButton(
              key: LibraryKeys.documentDeleteCancelButton,
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: LibraryKeys.documentDeleteConfirmButton,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Move to Trash'),
            ),
          ],
        ),
      );

      if (confirmed ?? false) await cubit.delete();
    });
  }
}
