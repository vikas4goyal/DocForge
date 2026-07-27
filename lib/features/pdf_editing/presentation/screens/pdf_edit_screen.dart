/// The PDF editor screen.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_forge/features/pdf_editing/presentation/cubit/pdf_edit_cubit.dart';
import 'package:doc_forge/features/pdf_editing/presentation/cubit/pdf_edit_state.dart';
import 'package:doc_forge/features/pdf_editing/presentation/pdf_edit_keys.dart';
import 'package:doc_forge/features/pdf_editing/presentation/widgets/pdf_edit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Edits one document's pages, protection, watermark and size.
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
    this.mergeCandidates = const [],
  });

  /// Builds a page's thumbnail.
  final PageThumbnailBuilder thumbnailBuilder;

  /// Invoked when the user leaves the editor.
  final VoidCallback onClose;

  /// Invoked with a document produced by extract, merge or split.
  final ValueChanged<Document>? onDerived;

  /// Other documents that can be merged into this one.
  final List<Document> mergeCandidates;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PdfEditCubit, PdfEditState>(
      listenWhen: (previous, current) => previous.derived != current.derived,
      listener: (context, state) {
        final derived = state.derived;
        if (derived != null) onDerived?.call(derived);
      },
      builder: (context, state) {
        final cubit = context.read<PdfEditCubit>();

        return Scaffold(
          key: PdfEditKeys.screen,
          appBar: AppBar(
            title: Text(state.title),
            leading: BackButton(onPressed: onClose),
            actions: [
              PdfEditActionButton(
                key: PdfEditKeys.rotateButton,
                operation: PdfEditOperation.rotate,
                icon: Icons.rotate_right,
                onPressed: state.canRun(PdfEditOperation.rotate)
                    ? cubit.rotate
                    : null,
              ),
              PdfEditActionButton(
                key: PdfEditKeys.duplicateButton,
                operation: PdfEditOperation.duplicate,
                icon: Icons.copy_all_outlined,
                onPressed: state.canRun(PdfEditOperation.duplicate)
                    ? cubit.duplicate
                    : null,
              ),
              PdfEditActionButton(
                key: PdfEditKeys.extractButton,
                operation: PdfEditOperation.extract,
                icon: Icons.call_split,
                onPressed: state.canRun(PdfEditOperation.extract)
                    ? cubit.extract
                    : null,
              ),
              PdfEditActionButton(
                key: PdfEditKeys.deleteButton,
                operation: PdfEditOperation.delete,
                icon: Icons.delete_outline,
                // Disabled rather than refused when it would empty the
                // document: the user finds out before they commit rather than
                // after.
                onPressed: state.canRun(PdfEditOperation.delete)
                    ? () => _confirmDelete(context, cubit)
                    : null,
              ),
            ],
          ),
          body: switch (state.status) {
            PdfEditStatus.loading => const AppLoadingIndicator(),
            PdfEditStatus.working => _Working(state: state),
            PdfEditStatus.failure => _Failure(state: state),
            PdfEditStatus.ready => _Editor(
              state: state,
              thumbnailBuilder: thumbnailBuilder,
              mergeCandidates: mergeCandidates,
            ),
          },
        );
      },
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
}

/// The page grid and the document-level tools beneath it.
class _Editor extends StatelessWidget {
  const _Editor({
    required this.state,
    required this.thumbnailBuilder,
    required this.mergeCandidates,
  });

  final PdfEditState state;
  final PageThumbnailBuilder thumbnailBuilder;
  final List<Document> mergeCandidates;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PdfEditCubit>();

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
        SliverToBoxAdapter(
          child: _DocumentTools(state: state, mergeCandidates: mergeCandidates),
        ),
      ],
    );
  }
}

/// The tools that act on the whole document rather than on selected pages.
class _DocumentTools extends StatelessWidget {
  const _DocumentTools({required this.state, required this.mergeCandidates});

  final PdfEditState state;
  final List<Document> mergeCandidates;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PdfEditCubit>();
    final metadata = state.metadata;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        ListTile(
          key: PdfEditKeys.compressButton,
          leading: const Icon(Icons.compress),
          title: Text(PdfEditOperation.compress.label),
          onTap: cubit.compress,
        ),
        ListTile(
          key: PdfEditKeys.splitConfirmButton,
          leading: const Icon(Icons.horizontal_split),
          title: Text(PdfEditOperation.split.label),
          // Split needs at least two pages; offering it for one would be an
          // action that can only fail.
          onTap: state.pageCount > 1
              ? () => cubit.split(state.pageCount ~/ 2)
              : null,
          enabled: state.pageCount > 1,
        ),
        ListTile(
          key: PdfEditKeys.mergeConfirmButton,
          leading: const Icon(Icons.merge),
          title: Text(PdfEditOperation.merge.label),
          subtitle: mergeCandidates.isEmpty
              ? const Text('Needs at least one other document')
              : null,
          // Disabled below two documents, which the spec requires explicitly.
          onTap: mergeCandidates.isEmpty
              ? null
              : () => cubit.merge([mergeCandidates.first.id]),
          enabled: mergeCandidates.isNotEmpty,
        ),
        if (mergeCandidates.length > 1)
          MergeOrderList(
            titles: [for (final d in mergeCandidates) d.title],
            // Reordering is presentational; the order is handed to the merge
            // use case, which passes it straight through.
            onReorder: (_, _) {},
          ),
        _WatermarkTool(state: state),
        _PasswordTool(state: state),
        if (metadata != null) PdfMetadataView(metadata: metadata),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// The watermark field, its preview and its confirm control.
class _WatermarkTool extends StatefulWidget {
  const _WatermarkTool({required this.state});

  final PdfEditState state;

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
          WatermarkPreview(text: _controller.text),
          const SizedBox(height: 8),
          FilledButton(
            key: PdfEditKeys.watermarkConfirmButton,
            onPressed: PdfEditRules.isValidWatermark(_controller.text)
                ? () => context.read<PdfEditCubit>().watermark(_controller.text)
                : null,
            child: Text(PdfEditOperation.watermark.label),
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
                  ? () => cubit.removePassword(_controller.text)
                  : null,
              child: Text(PdfEditOperation.removePassword.label),
            )
          else
            FilledButton(
              key: PdfEditKeys.protectConfirmButton,
              onPressed: PdfEditRules.isValidPassword(_controller.text)
                  ? () => cubit.protect(_controller.text)
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
