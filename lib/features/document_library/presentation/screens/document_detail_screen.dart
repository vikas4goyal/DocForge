/// A single document's detail screen.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/formatting/display_formatting.dart';
import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_detail_state.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_list_state.dart';
import 'package:doc_scanly/features/document_library/presentation/library_keys.dart';
import 'package:doc_scanly/features/document_library/presentation/widgets/library_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows a document's metadata and lifecycle actions.
class DocumentDetailScreen extends StatefulWidget {
  /// Creates a detail screen.
  ///
  /// Navigation is delegated to callbacks so the screen builds without a
  /// router, which is what makes it previewable and widget-testable.
  const DocumentDetailScreen({
    required this.onClose,
    super.key,
    this.folders = const [],
    this.onOpenDocument,
  });

  /// Called when the document is gone and the screen must leave.
  final VoidCallback onClose;

  /// Folders offered by the move picker.
  final List<Folder> folders;

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
          title: Semantics(
            label: state.document?.title ?? 'Document',
            child: Text(
              state.document?.title ?? 'Document',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
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
          LoadStatus.ready || LoadStatus.empty => _Body(state: state),
        },
      ),
    );
  }
}

/// Lifecycle operations that Viewer can host beside its reading actions.
enum DocumentLifecycleAction {
  /// Changes the document title.
  rename,

  /// Moves the document to another library folder.
  move,

  /// Creates an independently named copy.
  duplicate,

  /// Removes the document from active library lists.
  archive,

  /// Returns an archived document to active lists.
  restore,

  /// Moves the document to recoverable Trash.
  moveToTrash,
}

/// Result of a lifecycle operation hosted by Viewer.
@immutable
class DocumentLifecycleActionResult {
  /// Creates an operation result.
  const DocumentLifecycleActionResult({
    this.changed = false,
    this.unavailable = false,
    this.openedDocument,
  });

  /// Whether persisted metadata changed.
  final bool changed;

  /// Whether the source document can no longer remain open in Viewer.
  final bool unavailable;

  /// A duplicate that should replace the source Viewer, when one was created.
  final Document? openedDocument;
}

/// Runs one document lifecycle action using the existing reviewed dialogs.
///
/// The application layer calls this from Viewer's overflow menu. Keeping the
/// dialogs here preserves the feature boundary while allowing Detail itself to
/// remain a metadata-only screen without a second action menu.
Future<DocumentLifecycleActionResult> runDocumentLifecycleAction(
  BuildContext context, {
  required DocumentDetailCubit cubit,
  required Document document,
  required DocumentLifecycleAction action,
}) async {
  // PopupMenuButton reports its selection while its route is closing. Waiting
  // one frame prevents a dialog opened by that selection from being removed
  // together with the menu on slower devices.
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return const DocumentLifecycleActionResult();

  switch (action) {
    case DocumentLifecycleAction.rename:
      final name = await showNameDialog(
        context,
        title: 'Rename document',
        confirmLabel: 'Rename',
        initialValue: document.title,
      );
      if (name == null) return const DocumentLifecycleActionResult();
      await cubit.rename(name);
      return DocumentLifecycleActionResult(
        changed: cubit.state.failure == null,
      );
    case DocumentLifecycleAction.move:
      final moved = await showDialog<bool>(
        context: context,
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: _MovePickerDialog(currentFolderId: document.folderId),
        ),
      );
      return DocumentLifecycleActionResult(changed: moved ?? false);
    case DocumentLifecycleAction.duplicate:
      await Future.wait([cubit.beginDuplicate(), cubit.loadMoveOptions()]);
      if (!context.mounted || cubit.state.duplicateRequest == null) {
        return const DocumentLifecycleActionResult();
      }
      final copy = await showDialog<Document>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: _DuplicateDialog(source: document),
        ),
      );
      if (copy != null && context.mounted) {
        await SemanticsService.sendAnnouncement(
          View.of(context),
          'Created ${copy.title}',
          TextDirection.ltr,
        );
      }
      return DocumentLifecycleActionResult(
        changed: copy != null,
        openedDocument: copy,
      );
    case DocumentLifecycleAction.archive:
      await cubit.archive();
      return DocumentLifecycleActionResult(
        changed: cubit.state.failure == null,
      );
    case DocumentLifecycleAction.restore:
      await cubit.restore();
      return DocumentLifecycleActionResult(
        changed: cubit.state.failure == null,
      );
    case DocumentLifecycleAction.moveToTrash:
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
      if (!(confirmed ?? false)) {
        return const DocumentLifecycleActionResult();
      }
      await cubit.delete();
      return DocumentLifecycleActionResult(
        changed: cubit.state.isDeleted,
        unavailable: cubit.state.isDeleted,
      );
  }
}

/// The metadata block and favourite control.
class _Body extends StatelessWidget {
  const _Body({required this.state});

  final DocumentDetailState state;

  @override
  Widget build(BuildContext context) {
    final document = state.document;
    if (document == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.isWorking) const LinearProgressIndicator(),
        Semantics(
          header: true,
          label: document.title,
          child: Text(
            document.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
        ),
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
        if (document.contentAvailability != DocumentContentAvailability.local)
          _MetadataRow(
            key: LibraryKeys.documentCloudStatus(document.id.value),
            label: 'iCloud',
            value: switch (document.contentAvailability) {
              DocumentContentAvailability.remote =>
                'Stored in iCloud — downloads when opened',
              DocumentContentAvailability.downloading => 'Downloading…',
              DocumentContentAvailability.available =>
                'Available on this device',
              DocumentContentAvailability.failed =>
                'Download failed — open to retry',
              DocumentContentAvailability.local => 'Not used',
            },
          ),
        if (document.contentAvailability ==
            DocumentContentAvailability.downloading)
          Semantics(
            label: 'Downloading ${document.title} from iCloud',
            child: LinearProgressIndicator(
              key: LibraryKeys.documentCloudDownload(document.id.value),
            ),
          ),
        const SizedBox(height: 8),
        _FavouriteRow(isFavourite: document.isFavourite),
      ],
    );
  }
}

/// One labelled metadata line.
class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value, super.key});

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

class _MovePickerDialog extends StatefulWidget {
  const _MovePickerDialog({required this.currentFolderId});

  final FolderId? currentFolderId;

  @override
  State<_MovePickerDialog> createState() => _MovePickerDialogState();
}

class _MovePickerDialogState extends State<_MovePickerDialog> {
  String? selectedToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DocumentDetailCubit>().loadMoveOptions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentDetailCubit, DocumentDetailState>(
      builder: (context, state) {
        final cubit = context.read<DocumentDetailCubit>();
        final canMove = selectedToken != null;
        return AlertDialog(
          key: LibraryKeys.documentMovePicker,
          title: const Text('Move document'),
          content: SizedBox(
            width: 420,
            child: switch (state.folderOptionsStatus) {
              FolderOptionsStatus.idle ||
              FolderOptionsStatus.loading => const Center(
                child: CircularProgressIndicator(
                  key: LibraryKeys.documentMoveLoading,
                ),
              ),
              FolderOptionsStatus.failure => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message ?? 'Folders could not be loaded.'),
                  TextButton(
                    key: LibraryKeys.documentMoveRetry,
                    onPressed: cubit.loadMoveOptions,
                    child: const Text('Retry'),
                  ),
                ],
              ),
              FolderOptionsStatus.ready ||
              FolderOptionsStatus.empty => RadioGroup<String>(
                groupValue: selectedToken,
                onChanged: (value) => setState(() => selectedToken = value),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (widget.currentFolderId != null)
                        Semantics(
                          key: LibraryKeys.documentMoveRoot,
                          label: 'Move to Root',
                          child: const RadioListTile<String>(
                            value: '_root',
                            title: Text('Root'),
                            subtitle: Text('DocScanly'),
                          ),
                        ),
                      for (final folder in state.folderOptions)
                        Semantics(
                          key: LibraryKeys.documentMoveFolder(folder.id.value),
                          label:
                              'Move to ${folder.relativePath.isEmpty ? folder.name : folder.relativePath}',
                          child: RadioListTile<String>(
                            value: folder.id.value,
                            title: Text(folder.name),
                            subtitle: Text(
                              folder.relativePath.isEmpty
                                  ? folder.name
                                  : folder.relativePath,
                            ),
                          ),
                        ),
                      if (state.folderOptions.isEmpty &&
                          widget.currentFolderId == null)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('There is no other folder to move to.'),
                        ),
                    ],
                  ),
                ),
              ),
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: LibraryKeys.documentMoveConfirm,
              onPressed: !canMove || state.isWorking
                  ? null
                  : () async {
                      await cubit.move(
                        selectedToken == '_root'
                            ? null
                            : FolderId(selectedToken!),
                      );
                      if (context.mounted && cubit.state.failure == null) {
                        Navigator.pop(context, true);
                      }
                    },
              child: const Text('Move'),
            ),
          ],
        );
      },
    );
  }
}

class _DuplicateDialog extends StatefulWidget {
  const _DuplicateDialog({required this.source});

  final Document source;

  @override
  State<_DuplicateDialog> createState() => _DuplicateDialogState();
}

class _DuplicateDialogState extends State<_DuplicateDialog> {
  late final TextEditingController controller = TextEditingController(
    text: context.read<DocumentDetailCubit>().state.duplicateRequest?.title,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentDetailCubit, DocumentDetailState>(
      builder: (context, state) {
        final cubit = context.read<DocumentDetailCubit>();
        final request = state.duplicateRequest!;
        final submitting = state.duplicateStatus == DuplicateStatus.submitting;
        final currentToken = request.destinationFolderId?.value ?? '_root';
        return AlertDialog(
          key: LibraryKeys.documentDuplicateDialog,
          title: const Text('Duplicate document'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Source: ${widget.source.title}'),
                const SizedBox(height: 12),
                TextField(
                  key: LibraryKeys.documentDuplicateName,
                  controller: controller,
                  enabled: !submitting,
                  decoration: const InputDecoration(labelText: 'Copy name'),
                  onChanged: cubit.updateDuplicateTitle,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: LibraryKeys.documentDuplicateFolder,
                  initialValue: currentToken,
                  decoration: const InputDecoration(labelText: 'Destination'),
                  items: [
                    DropdownMenuItem(
                      key: LibraryKeys.documentDuplicateFolderOption('_root'),
                      value: '_root',
                      child: const Text('Root'),
                    ),
                    if (request.destinationFolderId != null &&
                        !state.folderOptions.any(
                          (folder) => folder.id == request.destinationFolderId,
                        ))
                      DropdownMenuItem(
                        key: LibraryKeys.documentDuplicateFolderOption(
                          request.destinationFolderId!.value,
                        ),
                        value: request.destinationFolderId!.value,
                        child: Text(
                          request.destinationFolders.isEmpty
                              ? 'Current folder'
                              : request.destinationFolders.join('/'),
                        ),
                      ),
                    for (final folder in state.folderOptions)
                      DropdownMenuItem(
                        key: LibraryKeys.documentDuplicateFolderOption(
                          folder.id.value,
                        ),
                        value: folder.id.value,
                        child: Text(
                          folder.relativePath.isEmpty
                              ? folder.name
                              : folder.relativePath,
                        ),
                      ),
                  ],
                  onChanged: submitting
                      ? null
                      : (value) {
                          final folder = state.folderOptions
                              .where((item) => item.id.value == value)
                              .firstOrNull;
                          cubit.updateDuplicateDestination(folder);
                        },
                ),
                if (state.duplicateStatus == DuplicateStatus.failure) ...[
                  const SizedBox(height: 8),
                  Text(state.message ?? 'The copy could not be created.'),
                ],
                if (submitting) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              key: LibraryKeys.documentDuplicateCancel,
              onPressed: submitting
                  ? null
                  : () {
                      cubit.cancelDuplicate();
                      Navigator.pop(context);
                    },
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: LibraryKeys.documentDuplicateConfirm,
              onPressed: submitting || controller.text.trim().isEmpty
                  ? null
                  : () async {
                      final copy = await cubit.confirmDuplicate();
                      if (copy != null && context.mounted) {
                        Navigator.pop(context, copy);
                      }
                    },
              child: Text(submitting ? 'Creating…' : 'Create copy'),
            ),
          ],
        );
      },
    );
  }
}
