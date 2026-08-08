/// The PDF editor screen.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_operation_workflow.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/pdf_edit_cubit.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/pdf_edit_state.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/pdf_edit_keys.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/widgets/pdf_edit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Manages one document's pages or hosts one focused document operation.
///
/// Keys: [PdfEditKeys.screen] on the root, and one key per control. The keys
/// are normative and come from `specs/pdf-editing/spec.md`.
class PdfEditScreen extends StatelessWidget {
  /// Creates the editor.
  const PdfEditScreen({
    required this.thumbnailBuilder,
    required this.onClose,
    super.key,
    this.onDerived,
    this.onDone,
    this.mergeCandidates = const [],
    this.initialOperation,
  });

  /// Builds a page's thumbnail.
  final PageThumbnailBuilder thumbnailBuilder;

  /// Invoked when the user leaves the editor.
  final VoidCallback onClose;

  /// Invoked with a document produced by extract, merge or split.
  final ValueChanged<Document>? onDerived;

  /// Returns to Dashboard after the user reviews completed outputs.
  final VoidCallback? onDone;

  /// Other documents that can be merged into this one.
  final List<Document> mergeCandidates;

  /// Opens a single document-level workflow without showing the editor hub.
  final PdfEditOperation? initialOperation;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PdfEditCubit, PdfEditState>(
      listenWhen: (previous, current) =>
          previous.result != current.result && current.result != null,
      listener: (context, state) {
        _showResult(context, state.result!);
      },
      builder: (context, state) {
        final cubit = context.read<PdfEditCubit>();

        if (initialOperation == PdfEditOperation.split &&
            state.status == PdfEditStatus.ready) {
          return _FocusedSplit(state: state, onClose: onClose);
        }

        if (initialOperation == null) {
          return _ManagePagesScreen(
            state: state,
            thumbnailBuilder: thumbnailBuilder,
            onClose: onClose,
          );
        }

        return Scaffold(
          key: PdfEditKeys.screen,
          appBar: AppBar(
            title: Semantics(
              label: initialOperation?.label ?? state.title,
              child: Text(
                initialOperation?.label ?? state.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            leading: CloseButton(onPressed: onClose),
            actions: [
              if (initialOperation == null && state.hasSelection)
                if (MediaQuery.sizeOf(context).width < 600)
                  PopupMenuButton<PdfEditOperation>(
                    key: PdfEditKeys.actionsMenu,
                    tooltip: 'Selected page actions',
                    onSelected: (operation) async {
                      switch (operation) {
                        case PdfEditOperation.rotate:
                          await _runPageOperation(context, cubit, operation);
                        case PdfEditOperation.duplicate:
                          await _runPageOperation(context, cubit, operation);
                        case PdfEditOperation.extract:
                          await _runPageOperation(context, cubit, operation);
                        case PdfEditOperation.delete:
                          await _confirmDelete(context, cubit);
                        default:
                          return;
                      }
                    },
                    itemBuilder: (_) => [
                      if (state.hasSinglePageSelected)
                        const PopupMenuItem(
                          key: PdfEditKeys.rotateButton,
                          value: PdfEditOperation.rotate,
                          child: Text('Rotate page'),
                        ),
                      if (state.hasSinglePageSelected)
                        const PopupMenuItem(
                          key: PdfEditKeys.duplicateButton,
                          value: PdfEditOperation.duplicate,
                          child: Text('Duplicate page'),
                        ),
                      const PopupMenuItem(
                        key: PdfEditKeys.extractButton,
                        value: PdfEditOperation.extract,
                        child: Text('Extract pages'),
                      ),
                      if (state.canDelete)
                        const PopupMenuItem(
                          key: PdfEditKeys.deleteButton,
                          value: PdfEditOperation.delete,
                          child: Text('Delete pages'),
                        ),
                    ],
                  )
                else ...[
                  if (state.hasSinglePageSelected)
                    PdfEditActionButton(
                      key: PdfEditKeys.rotateButton,
                      operation: PdfEditOperation.rotate,
                      icon: Icons.rotate_right,
                      onPressed: () => _runPageOperation(
                        context,
                        cubit,
                        PdfEditOperation.rotate,
                      ),
                    ),
                  if (state.hasSinglePageSelected)
                    PdfEditActionButton(
                      key: PdfEditKeys.duplicateButton,
                      operation: PdfEditOperation.duplicate,
                      icon: Icons.copy_all_outlined,
                      onPressed: () => _runPageOperation(
                        context,
                        cubit,
                        PdfEditOperation.duplicate,
                      ),
                    ),
                  PdfEditActionButton(
                    key: PdfEditKeys.extractButton,
                    operation: PdfEditOperation.extract,
                    icon: Icons.call_split,
                    onPressed: () => _runPageOperation(
                      context,
                      cubit,
                      PdfEditOperation.extract,
                    ),
                  ),
                  if (state.canDelete)
                    PdfEditActionButton(
                      key: PdfEditKeys.deleteButton,
                      operation: PdfEditOperation.delete,
                      icon: Icons.delete_outline,
                      onPressed: () => _confirmDelete(context, cubit),
                    ),
                ],
            ],
          ),
          body: switch (state.status) {
            PdfEditStatus.loading => const AppLoadingIndicator(),
            PdfEditStatus.working => _Working(state: state),
            PdfEditStatus.failure => _Failure(state: state),
            PdfEditStatus.ready => _Editor(
              state: state,
              thumbnailBuilder: thumbnailBuilder,
              initialOperation: initialOperation,
            ),
          },
        );
      },
    );
  }

  Future<void> _showResult(
    BuildContext context,
    PdfOperationResult result,
  ) async {
    final documents = switch (result) {
      PdfInPlaceOperationResult(:final document) => [document],
      PdfDerivedOperationResult(:final documents) => documents,
    };
    final isInPlace = result is PdfInPlaceOperationResult;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: PdfEditKeys.result,
        title: Text(
          isInPlace
              ? 'PDF updated'
              : documents.length == 1
              ? 'Document created'
              : '${documents.length} documents created',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result case PdfInPlaceOperationResult(:final message?))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(message),
              ),
            for (final document in documents)
              ListTile(
                title: Text(document.title),
                subtitle: Text('${document.pageCount} pages'),
                trailing: isInPlace || onDerived == null
                    ? null
                    : TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          onDerived?.call(document);
                        },
                        child: const Text('Open'),
                      ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            key: PdfEditKeys.resultDone,
            onPressed: () {
              Navigator.pop(dialogContext);
              (onDone ?? onClose)();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  /// Asks before deleting, because deletion is the one page operation with no
  /// undo — every other one leaves the pages where they were.
  Future<void> _confirmDelete(BuildContext context, PdfEditCubit cubit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete pages?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: PdfEditKeys.deleteConfirmButton,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await cubit.delete();
  }

  Future<void> _runPageOperation(
    BuildContext context,
    PdfEditCubit cubit,
    PdfEditOperation operation,
  ) async {
    final summary = switch (operation) {
      PdfEditOperation.rotate =>
        'The selected page will rotate clockwise in the current PDF.',
      PdfEditOperation.duplicate =>
        'A copy of the selected page will be inserted in the current PDF.',
      PdfEditOperation.extract =>
        '${cubit.state.selection.length} selected pages will become a new PDF. The source stays unchanged.',
      _ => null,
    };
    if (summary == null) return;
    final confirmed = await _reviewOperation(
      context,
      draft: PdfOperationDraft.pages(
        operation: operation,
        pageIndices: PdfEditRules.orderedSelection(cubit.state.selection),
        sourceEffect: operation.producesNewDocument
            ? PdfSourceEffect.preserve
            : PdfSourceEffect.replace,
      ),
      title: '${operation.label}?',
      summary: summary,
      confirmLabel: operation.label,
    );
    if (!confirmed) return;
    switch (operation) {
      case PdfEditOperation.rotate:
        await cubit.rotate();
      case PdfEditOperation.duplicate:
        await cubit.duplicate();
      case PdfEditOperation.extract:
        await cubit.extract();
      default:
        return;
    }
  }
}

/// Thumbnail rows with a deliberate normal/edit mode boundary.
class _ManagePagesScreen extends StatefulWidget {
  const _ManagePagesScreen({
    required this.state,
    required this.thumbnailBuilder,
    required this.onClose,
  });

  final PdfEditState state;
  final PageThumbnailBuilder thumbnailBuilder;
  final VoidCallback onClose;

  @override
  State<_ManagePagesScreen> createState() => _ManagePagesScreenState();
}

class _ManagePagesScreenState extends State<_ManagePagesScreen> {
  late List<int> _pageOrder;
  var _editing = false;

  @override
  void initState() {
    super.initState();
    _resetOrder();
  }

  @override
  void didUpdateWidget(covariant _ManagePagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.pageCount != widget.state.pageCount) {
      _resetOrder();
    }
  }

  void _resetOrder() {
    _pageOrder = List<int>.generate(widget.state.pageCount, (index) => index);
  }

  bool get _orderChanged {
    if (_pageOrder.length != widget.state.pageCount) return true;
    for (var index = 0; index < _pageOrder.length; index++) {
      if (_pageOrder[index] != index) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: PdfEditKeys.screen,
      appBar: AppBar(
        leading: BackButton(onPressed: widget.onClose),
        title: const Text('Manage pages'),
        actions: [
          if (_editing) ...[
            TextButton(
              key: PdfEditKeys.cancelPageEditingButton,
              onPressed: widget.state.isWorking
                  ? null
                  : () => setState(() {
                      _editing = false;
                      _resetOrder();
                    }),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: PdfEditKeys.savePageOrderButton,
              onPressed: widget.state.isWorking ? null : _saveOrder,
              child: const Text('Save'),
            ),
          ] else
            TextButton(
              key: PdfEditKeys.editPagesButton,
              onPressed: widget.state.isWorking
                  ? null
                  : () => setState(() => _editing = true),
              child: const Text('Edit'),
            ),
        ],
      ),
      body: switch (widget.state.status) {
        PdfEditStatus.loading => const AppLoadingIndicator(),
        PdfEditStatus.working => _Working(state: widget.state),
        PdfEditStatus.failure => _Failure(state: widget.state),
        PdfEditStatus.ready => _pageList(context),
      },
    );
  }

  Widget _pageList(BuildContext context) {
    if (_editing) {
      return ReorderableListView.builder(
        key: PdfEditKeys.pageList,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _pageOrder.length,
        onReorderItem: (oldIndex, newIndex) => setState(() {
          final page = _pageOrder.removeAt(oldIndex);
          _pageOrder.insert(newIndex, page);
        }),
        itemBuilder: (context, position) => _pageRow(
          context,
          position: position,
          pageIndex: _pageOrder[position],
        ),
      );
    }

    return ListView.builder(
      key: PdfEditKeys.pageList,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: widget.state.pageCount,
      itemBuilder: (context, index) =>
          _pageRow(context, position: index, pageIndex: index),
    );
  }

  Widget _pageRow(
    BuildContext context, {
    required int position,
    required int pageIndex,
  }) {
    return Semantics(
      key: ValueKey('managed-page-$pageIndex'),
      label: 'Page ${position + 1} of ${widget.state.pageCount}',
      container: true,
      explicitChildNodes: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          key: PdfEditKeys.page(pageIndex),
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          leading: SizedBox(
            width: 56,
            height: 76,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: widget.thumbnailBuilder(context, pageIndex),
            ),
          ),
          title: Text('Page ${position + 1}'),
          subtitle: _editing ? const Text('Drag to rearrange') : null,
          trailing: _editing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: 'Rotate page',
                      button: true,
                      excludeSemantics: true,
                      child: IconButton(
                        key: PdfEditKeys.pageRotate(pageIndex),
                        tooltip: 'Rotate page',
                        onPressed: () =>
                            _runPageAction(pageIndex, PdfEditOperation.rotate),
                        icon: const Icon(Icons.rotate_right),
                      ),
                    ),
                    Semantics(
                      label: 'Duplicate page',
                      button: true,
                      excludeSemantics: true,
                      child: IconButton(
                        key: PdfEditKeys.pageDuplicate(pageIndex),
                        tooltip: 'Duplicate page',
                        onPressed: () => _runPageAction(
                          pageIndex,
                          PdfEditOperation.duplicate,
                        ),
                        icon: const Icon(Icons.copy_outlined),
                      ),
                    ),
                    Semantics(
                      label: 'Delete page',
                      button: true,
                      excludeSemantics: true,
                      child: IconButton(
                        key: PdfEditKeys.pageDelete(pageIndex),
                        tooltip: 'Delete page',
                        onPressed: widget.state.pageCount > 1
                            ? () => _deletePage(pageIndex)
                            : null,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                    ReorderableDragStartListener(
                      key: PdfEditKeys.pageDragHandle(pageIndex),
                      index: position,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  ],
                )
              : Semantics(
                  label: 'Extract page as new PDF',
                  button: true,
                  excludeSemantics: true,
                  child: IconButton(
                    key: PdfEditKeys.pageExtract(pageIndex),
                    tooltip: 'Extract page as new PDF',
                    onPressed: () =>
                        _runPageAction(pageIndex, PdfEditOperation.extract),
                    icon: const Icon(Icons.call_split),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _runPageAction(int pageIndex, PdfEditOperation operation) async {
    final cubit = context.read<PdfEditCubit>()..selectOnly(pageIndex);
    final summary = switch (operation) {
      PdfEditOperation.rotate =>
        'Page ${pageIndex + 1} will rotate clockwise in the current PDF.',
      PdfEditOperation.duplicate =>
        'A copy of page ${pageIndex + 1} will be inserted after it.',
      PdfEditOperation.extract =>
        'Page ${pageIndex + 1} will become a new PDF. The source stays unchanged.',
      _ => null,
    };
    if (summary == null) return;
    final confirmed = await _reviewOperation(
      context,
      draft: PdfOperationDraft.pages(
        operation: operation,
        pageIndices: [pageIndex],
        sourceEffect: operation.producesNewDocument
            ? PdfSourceEffect.preserve
            : PdfSourceEffect.replace,
      ),
      title: '${operation.label} page?',
      summary: summary,
      confirmLabel: operation.label,
    );
    if (!confirmed || !mounted) return;
    switch (operation) {
      case PdfEditOperation.rotate:
        await cubit.rotate();
      case PdfEditOperation.duplicate:
        await cubit.duplicate();
      case PdfEditOperation.extract:
        await cubit.extract();
      default:
        return;
    }
  }

  Future<void> _deletePage(int pageIndex) async {
    final cubit = context.read<PdfEditCubit>()..selectOnly(pageIndex);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete page ${pageIndex + 1}?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: PdfEditKeys.deleteConfirmButton,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) await cubit.delete();
  }

  Future<void> _saveOrder() async {
    if (!_orderChanged) {
      setState(() => _editing = false);
      return;
    }
    final confirmed = await _reviewOperation(
      context,
      draft: PdfOperationDraft.pages(
        operation: PdfEditOperation.reorder,
        pageIndices: [..._pageOrder],
        sourceEffect: PdfSourceEffect.replace,
      ),
      title: 'Save page order?',
      summary: 'The PDF pages will be replaced with this reviewed order.',
      confirmLabel: 'Save order',
    );
    if (!confirmed || !mounted) return;
    await context.read<PdfEditCubit>().reorderPages([..._pageOrder]);
    if (mounted) {
      setState(() {
        _editing = false;
        // The saved PDF now uses the reviewed order as its natural 0..n order.
        _resetOrder();
      });
    }
  }
}

/// The page grid, or one document-level workflow opened from Viewer.
class _Editor extends StatelessWidget {
  const _Editor({
    required this.state,
    required this.thumbnailBuilder,
    required this.initialOperation,
  });

  final PdfEditState state;
  final PageThumbnailBuilder thumbnailBuilder;
  final PdfEditOperation? initialOperation;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PdfEditCubit>();

    if (initialOperation case final operation?) {
      return switch (operation) {
        PdfEditOperation.compress => _FocusedCompress(state: state),
        PdfEditOperation.split => const SizedBox.shrink(),
        PdfEditOperation.watermark => _WatermarkTool(
          state: state,
          thumbnailBuilder: thumbnailBuilder,
        ),
        PdfEditOperation.protect ||
        PdfEditOperation.removePassword => _PasswordTool(state: state),
        _ => const SizedBox.shrink(),
      };
    }

    return ResponsiveLayout(
      compact: (context) => _content(context, cubit, columns: 3),
      // More columns rather than a second pane: a page grid is the same idea at
      // any width, and splitting it would put the tools somewhere the user has
      // to look for them.
      expanded: (context) => _content(context, cubit, columns: 6),
    );
  }

  Widget _content(
    BuildContext context,
    PdfEditCubit cubit, {
    required int columns,
  }) {
    return CustomScrollView(
      slivers: [
        if (state.compression != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(state.compression!.message),
            ),
          ),
        if (state.passwordRejected)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'That password did not work.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid.builder(
            key: PdfEditKeys.pageGrid,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 0.72,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: state.pageCount,
            itemBuilder: (context, index) => PdfPageTile(
              key: PdfEditKeys.page(index),
              index: index,
              pageCount: state.pageCount,
              isSelected: state.selection.contains(index),
              thumbnailBuilder: thumbnailBuilder,
              onTap: () => cubit.toggleSelection(index),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// A focused compression workflow reached directly from the viewer menu.
class _FocusedCompress extends StatelessWidget {
  const _FocusedCompress({required this.state});

  final PdfEditState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Make this PDF smaller',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'DocScanly will create a smaller version when compression helps. '
          'Choose whether to keep the original or replace it.',
        ),
        if (state.compression case final compression?) ...[
          const SizedBox(height: 16),
          Text(compression.message),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          key: PdfEditKeys.compressCopyButton,
          icon: const Icon(Icons.compress),
          label: const Text('Save compressed copy'),
          onPressed: () async {
            final confirmed = await _reviewOperation(
              context,
              draft: const PdfOperationDraft.compress(
                sourceEffect: PdfSourceEffect.preserve,
              ),
              title: 'Save a compressed copy?',
              summary:
                  'A new compressed PDF will be created. The original stays unchanged.',
              confirmLabel: 'Save copy',
            );
            if (confirmed && context.mounted) {
              await context.read<PdfEditCubit>().compress(saveAsCopy: true);
            }
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: PdfEditKeys.compressButton,
          icon: const Icon(Icons.find_replace_outlined),
          label: const Text('Replace original'),
          onPressed: () async {
            final confirmed = await _reviewOperation(
              context,
              draft: const PdfOperationDraft.compress(),
              title: 'Replace with compressed PDF?',
              summary:
                  'The current PDF will be replaced only when compression makes it smaller.',
              confirmLabel: 'Replace original',
            );
            if (confirmed && context.mounted) {
              await context.read<PdfEditCubit>().compress();
            }
          },
        ),
      ],
    );
  }
}

/// A dedicated split form with both output names visible before confirmation.
class _FocusedSplit extends StatefulWidget {
  const _FocusedSplit({required this.state, required this.onClose});

  final PdfEditState state;
  final VoidCallback onClose;

  @override
  State<_FocusedSplit> createState() => _FocusedSplitState();
}

class _FocusedSplitState extends State<_FocusedSplit> {
  late final TextEditingController _boundary;
  late final TextEditingController _first;
  late final TextEditingController _second;
  String? _error;

  @override
  void initState() {
    super.initState();
    final proposed = PdfEditRules.splitTitles(widget.state.title);
    _boundary = TextEditingController(text: '${widget.state.pageCount ~/ 2}');
    _first = TextEditingController(text: proposed.first);
    _second = TextEditingController(text: proposed.second);
  }

  @override
  void dispose() {
    _boundary.dispose();
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = widget.state.pageCount;
    final boundary = int.tryParse(_boundary.text) ?? 0;
    final validBoundary = PdfEditRules.canSplit(boundary, pageCount: pageCount);

    return Scaffold(
      key: PdfEditKeys.pageNamingScreen,
      appBar: AppBar(
        leading: CloseButton(onPressed: widget.onClose),
        title: Text(
          'Split PDF',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          IconButton(
            key: PdfEditKeys.splitConfirmButton,
            tooltip: 'Review and create',
            onPressed: pageCount > 1 ? _review : null,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Choose where to split and name both PDFs.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            key: PdfEditKeys.splitBoundaryField,
            controller: _boundary,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Split after page',
              helperText: pageCount > 1 ? 'Choose 1 to ${pageCount - 1}' : null,
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 20),
          Text(
            validBoundary ? 'PDF 1 · Pages 1–$boundary' : 'PDF 1',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            key: PdfEditKeys.splitFirstNameField,
            controller: _first,
            decoration: const InputDecoration(hintText: 'Enter a name'),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 20),
          Text(
            validBoundary
                ? 'PDF 2 · Pages ${boundary + 1}–$pageCount'
                : 'PDF 2',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            key: PdfEditKeys.splitSecondNameField,
            controller: _second,
            decoration: const InputDecoration(hintText: 'Enter a name'),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_error case final message?) ...[
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Future<void> _review() async {
    final draft = PdfOperationDraft.split(
      boundary: int.tryParse(_boundary.text) ?? 0,
      firstTitle: _first.text.trim(),
      secondTitle: _second.text.trim(),
    );
    final message = PdfOperationValidation.messageFor(
      draft,
      pageCount: widget.state.pageCount,
    );
    if (message != null) {
      setState(() => _error = message);
      return;
    }

    final split = draft as PdfSplitDraft;
    final confirmed = await _reviewOperation(
      context,
      draft: split,
      title: 'Create these two PDFs?',
      summary:
          'Pages 1–${split.boundary} become “${split.firstTitle}”; pages ${split.boundary + 1}–${widget.state.pageCount} become “${split.secondTitle}”. The source stays unchanged.',
      confirmLabel: 'Create two PDFs',
    );
    if (!confirmed || !mounted) return;

    await context.read<PdfEditCubit>().split(
      split.boundary,
      outputTitles: (first: split.firstTitle, second: split.secondTitle),
    );
  }
}

/// The watermark field, its preview and its confirm control.
class _WatermarkTool extends StatefulWidget {
  const _WatermarkTool({required this.state, required this.thumbnailBuilder});

  final PdfEditState state;
  final PageThumbnailBuilder thumbnailBuilder;

  @override
  State<_WatermarkTool> createState() => _WatermarkToolState();
}

class _WatermarkToolState extends State<_WatermarkTool> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: PdfEditKeys.watermarkTextField,
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Watermark text'),
            // Rebuilt on every keystroke so the preview tracks what is typed,
            // which is what makes it a preview rather than a sample.
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          WatermarkPreview(
            text: _controller.text,
            page: widget.thumbnailBuilder(context, 0),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: PdfEditKeys.watermarkCopyButton,
            onPressed: PdfEditRules.isValidWatermark(_controller.text)
                ? () async {
                    final confirmed = await _reviewOperation(
                      context,
                      draft: PdfOperationDraft.watermark(
                        text: _controller.text.trim(),
                      ),
                      title: 'Save a watermarked copy?',
                      summary:
                          '“${_controller.text.trim()}” will be placed on every page of a new PDF. The original stays unchanged.',
                      confirmLabel: 'Save copy',
                    );
                    if (confirmed && context.mounted) {
                      await context.read<PdfEditCubit>().watermark(
                        _controller.text,
                        saveAsCopy: true,
                      );
                    }
                  }
                : null,
            child: const Text('Save watermarked copy'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: PdfEditKeys.watermarkConfirmButton,
            onPressed: PdfEditRules.isValidWatermark(_controller.text)
                ? () async {
                    final confirmed = await _reviewOperation(
                      context,
                      draft: PdfOperationDraft.watermark(
                        text: _controller.text.trim(),
                      ),
                      title: 'Replace original with watermark?',
                      summary:
                          '“${_controller.text.trim()}” will be placed on every page and replace the current PDF.',
                      confirmLabel: 'Replace original',
                    );
                    if (confirmed && context.mounted) {
                      await context.read<PdfEditCubit>().watermark(
                        _controller.text,
                      );
                    }
                  }
                : null,
            child: const Text('Replace original'),
          ),
        ],
      ),
    );
  }
}

/// The password field and the protect / remove controls.
class _PasswordTool extends StatefulWidget {
  const _PasswordTool({required this.state});

  final PdfEditState state;

  @override
  State<_PasswordTool> createState() => _PasswordToolState();
}

class _PasswordToolState extends State<_PasswordTool> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    // Cleared as well as disposed: a password lives in memory only for as long
    // as the operation that needs it.
    _controller
      ..clear()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PdfEditCubit>();
    final isProtected = widget.state.document?.isProtected ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: PdfEditKeys.protectPasswordField,
            controller: _controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: isProtected ? 'Current password' : 'New password',
              errorText: widget.state.passwordRejected
                  ? 'That password did not work.'
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          if (isProtected)
            FilledButton(
              key: PdfEditKeys.removePasswordButton,
              onPressed: PdfEditRules.isValidPassword(_controller.text)
                  ? () async {
                      final confirmed = await _reviewOperation(
                        context,
                        draft: const PdfOperationDraft.protection(remove: true),
                        title: 'Remove PDF protection?',
                        summary:
                            'The current PDF will be replaced and will no longer require a password.',
                        confirmLabel: 'Remove protection',
                      );
                      if (confirmed) {
                        await cubit.removePassword(_controller.text);
                      }
                    }
                  : null,
              child: Text(PdfEditOperation.removePassword.label),
            )
          else
            FilledButton(
              key: PdfEditKeys.protectConfirmButton,
              onPressed: PdfEditRules.isValidPassword(_controller.text)
                  ? () async {
                      final confirmed = await _reviewOperation(
                        context,
                        draft: const PdfOperationDraft.protection(
                          remove: false,
                        ),
                        title: 'Protect this PDF?',
                        summary:
                            'The current PDF will be replaced with a password-protected version. Keep the password somewhere safe.',
                        confirmLabel: 'Protect PDF',
                      );
                      if (confirmed) await cubit.protect(_controller.text);
                    }
                  : null,
              child: Text(PdfEditOperation.protect.label),
            ),
        ],
      ),
    );
  }
}

/// The progress view shown while an operation runs.
class _Working extends StatelessWidget {
  const _Working({required this.state});

  final PdfEditState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: PdfEditKeys.progress,
      padding: const EdgeInsets.all(8),
      child: AppProgressIndicator(
        completed: 0,
        total: 0,
        label: state.operation?.label ?? 'Working',
      ),
    );
  }
}

/// The error view shown when an operation could not be completed.
class _Failure extends StatelessWidget {
  const _Failure({required this.state});

  final PdfEditState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PdfEditCubit>();

    return Padding(
      key: PdfEditKeys.errorView,
      padding: const EdgeInsets.all(8),
      child: AppErrorView(
        failure: state.failure!,
        // Every recovery returns to the editor, whichever one the failure calls
        // for. The document is unchanged in all of them, which is what makes
        // returning safe rather than a guess.
        onRetry: cubit.dismissError,
        onGoBack: cubit.dismissError,
        onOpenSettings: cubit.dismissError,
        retryKey: PdfEditKeys.errorRetryButton,
      ),
    );
  }
}

// Retained for the merge/split dialog components exercised by previews.
// ignore: unused_element
Future<PdfSplitDraft?> _collectSplitDraft(
  BuildContext context,
  PdfEditState state,
) async {
  final proposed = PdfEditRules.splitTitles(state.title);
  final boundary = TextEditingController(text: '${state.pageCount ~/ 2}');
  final first = TextEditingController(text: proposed.first);
  final second = TextEditingController(text: proposed.second);
  String? error;

  final draft = await showDialog<PdfSplitDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        key: PdfEditKeys.operationSheet,
        title: const Text('Split PDF'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: PdfEditKeys.splitBoundaryField,
                controller: boundary,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Split after page',
                  helperText: 'Choose 1 to ${state.pageCount - 1}',
                ),
              ),
              TextField(
                key: PdfEditKeys.splitFirstNameField,
                controller: first,
                decoration: const InputDecoration(labelText: 'First PDF name'),
              ),
              TextField(
                key: PdfEditKeys.splitSecondNameField,
                controller: second,
                decoration: const InputDecoration(labelText: 'Second PDF name'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: PdfEditKeys.cancel,
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: PdfEditKeys.inputContinue,
            onPressed: () {
              final candidate = PdfOperationDraft.split(
                boundary: int.tryParse(boundary.text) ?? 0,
                firstTitle: first.text.trim(),
                secondTitle: second.text.trim(),
              );
              final message = PdfOperationValidation.messageFor(
                candidate,
                pageCount: state.pageCount,
              );
              if (message != null) {
                setState(() => error = message);
                return;
              }
              Navigator.pop(dialogContext, candidate as PdfSplitDraft);
            },
            child: const Text('Review'),
          ),
        ],
      ),
    ),
  );

  boundary.dispose();
  first.dispose();
  second.dispose();
  return draft;
}

// ignore: unused_element
Future<PdfMergeDraft?> _collectMergeDraft(
  BuildContext context,
  Document source,
  List<Document> candidates,
) async {
  final ordered = <Document>[
    source,
    ...candidates.where((document) => document.id != source.id),
  ];
  final selected = <DocumentId>{for (final document in ordered) document.id};
  final output = TextEditingController(text: PdfEditRules.mergedTitle(ordered));
  String? error;

  final draft = await showDialog<PdfMergeDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        key: PdfEditKeys.operationSheet,
        title: const Text('Merge PDFs'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableListView.builder(
                  key: PdfEditKeys.mergeOrderList,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ordered.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final item = ordered.removeAt(oldIndex);
                      ordered.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final document = ordered[index];
                    final isSource = document.id == source.id;
                    return CheckboxListTile(
                      key: ValueKey('pdf_merge_document_${document.id.value}'),
                      value: selected.contains(document.id),
                      onChanged: isSource
                          ? null
                          : (value) => setState(() {
                              if (value ?? false) {
                                selected.add(document.id);
                              } else {
                                selected.remove(document.id);
                              }
                            }),
                      title: Text(document.title),
                      subtitle: Text(
                        isSource
                            ? 'Current document'
                            : '${document.pageCount} pages',
                      ),
                      secondary: const Icon(Icons.drag_handle),
                    );
                  },
                ),
                TextField(
                  key: PdfEditKeys.mergeOutputNameField,
                  controller: output,
                  decoration: const InputDecoration(
                    labelText: 'Merged PDF name',
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            key: PdfEditKeys.cancel,
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: PdfEditKeys.inputContinue,
            onPressed: () {
              final candidate = PdfOperationDraft.merge(
                documentIds: [
                  for (final document in ordered)
                    if (selected.contains(document.id)) document.id,
                ],
                outputTitle: output.text.trim(),
              );
              final message = PdfOperationValidation.messageFor(
                candidate,
                pageCount: source.pageCount,
              );
              if (message != null) {
                setState(() => error = message);
                return;
              }
              Navigator.pop(dialogContext, candidate as PdfMergeDraft);
            },
            child: const Text('Review'),
          ),
        ],
      ),
    ),
  );

  output.dispose();
  return draft;
}

Future<bool> _reviewOperation(
  BuildContext context, {
  required PdfOperationDraft draft,
  required String title,
  required String summary,
  required String confirmLabel,
}) async {
  final cubit = context.read<PdfEditCubit>();
  final review = PdfOperationReview(
    draft: draft,
    title: title,
    summary: summary,
    confirmLabel: confirmLabel,
  );
  cubit.reviewOperation(review);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: PdfEditKeys.operationSheet,
      title: Text(title),
      content: Semantics(
        label: summary,
        child: Text(summary, key: PdfEditKeys.review),
      ),
      actions: [
        TextButton(
          key: PdfEditKeys.cancel,
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: PdfEditKeys.confirm,
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  if (!(confirmed ?? false)) cubit.cancelReview();
  return confirmed ?? false;
}
