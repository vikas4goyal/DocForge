/// The document viewer screen.
library;

import 'package:doc_scanly/core/widgets/app_state_views.dart';
import 'package:doc_scanly/features/document_viewer/domain/repositories/pdf_renderer.dart';
import 'package:doc_scanly/features/document_viewer/presentation/cubit/viewer_cubit.dart';
import 'package:doc_scanly/features/document_viewer/presentation/cubit/viewer_state.dart';
import 'package:doc_scanly/features/document_viewer/presentation/viewer_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Builds the surface that renders the document's pages.
///
/// Injected from the composition root because rendering is a plugin-backed
/// widget that cannot exist in a test or a preview — the same reason the camera
/// preview is injected into the scanning screen. The screen itself stays
/// testable, previewable and themeable.
typedef PageSurfaceBuilder =
    Widget Function(
      BuildContext context, {
      required String filePath,
      required String? password,
      required int page,
      required ValueChanged<int> onPageChanged,
    });

/// Document-level operations reached directly from the viewer's overflow menu.
enum ViewerDocumentAction {
  /// Opens the system print dialog.
  print,

  /// Opens the focused compression workflow.
  compress,

  /// Opens the focused split and naming workflow.
  split,

  /// Opens the focused watermark workflow.
  watermark,

  /// Opens the focused set/remove password workflow.
  protection,
}

/// Displays a document and offers the actions that act on it.
class ViewerScreen extends StatelessWidget {
  /// Creates the viewer screen.
  const ViewerScreen({
    required this.surfaceBuilder,
    required this.onBack,
    required this.onShare,
    required this.onAction,
    super.key,
  });

  /// Builds the page-rendering surface.
  final PageSurfaceBuilder surfaceBuilder;

  /// Called when the user leaves the viewer.
  final VoidCallback onBack;

  /// Called when the user shares the document.
  final VoidCallback onShare;

  /// Called with the focused operation selected from the overflow menu.
  final ValueChanged<ViewerDocumentAction> onAction;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewerCubit, ViewerState>(
      builder: (context, state) {
        final cubit = context.read<ViewerCubit>();

        return Scaffold(
          key: ViewerKeys.screen,
          appBar: AppBar(
            title: Semantics(
              label: state.title,
              child: Text(
                state.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            leading: BackButton(onPressed: onBack),
            actions: [
              // Offered only once the document is open: sharing a document that
              // could not be read would produce a file the recipient cannot
              // open either.
              if (state.isReady) ...[
                IconButton(
                  key: ViewerKeys.shareButton,
                  onPressed: onShare,
                  icon: const Icon(
                    Icons.ios_share_outlined,
                    semanticLabel: 'Share document',
                  ),
                  tooltip: 'Share document',
                ),
                Semantics(
                  label: 'More document actions',
                  button: true,
                  child: PopupMenuButton<ViewerDocumentAction>(
                    key: ViewerKeys.actionsMenu,
                    tooltip: 'More document actions',
                    onSelected: onAction,
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        key: ViewerKeys.printButton,
                        value: ViewerDocumentAction.print,
                        child: ListTile(
                          leading: Icon(Icons.print_outlined),
                          title: Text('Print'),
                        ),
                      ),
                      const PopupMenuItem(
                        key: ViewerKeys.compressButton,
                        value: ViewerDocumentAction.compress,
                        child: ListTile(
                          leading: Icon(Icons.compress),
                          title: Text('Compress'),
                        ),
                      ),
                      const PopupMenuItem(
                        key: ViewerKeys.splitButton,
                        value: ViewerDocumentAction.split,
                        child: ListTile(
                          leading: Icon(Icons.horizontal_split),
                          title: Text('Split'),
                        ),
                      ),
                      const PopupMenuItem(
                        key: ViewerKeys.watermarkButton,
                        value: ViewerDocumentAction.watermark,
                        child: ListTile(
                          leading: Icon(Icons.branding_watermark_outlined),
                          title: Text('Add watermark'),
                        ),
                      ),
                      PopupMenuItem(
                        key: ViewerKeys.passwordButton,
                        value: ViewerDocumentAction.protection,
                        child: ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: Text(
                            state.document?.isProtected ?? false
                                ? 'Remove password'
                                : 'Set password',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: switch (state.status) {
              ViewerStatus.loading => const AppLoadingIndicator(
                key: ViewerKeys.loadingIndicator,
                semanticsLabel: 'Opening document',
              ),
              ViewerStatus.locked => _PasswordPrompt(
                state: state,
                cubit: cubit,
              ),
              ViewerStatus.failure when state.failure != null => AppErrorView(
                key: ViewerKeys.errorView,
                failure: state.failure!,
                retryKey: ViewerKeys.errorBackButton,
                onRetry: cubit.retry,
                onGoBack: onBack,
              ),
              _ => _Document(
                state: state,
                cubit: cubit,
                surfaceBuilder: surfaceBuilder,
              ),
            },
          ),
          bottomNavigationBar: state.isReady
              ? _PageBar(state: state, cubit: cubit)
              : null,
        );
      },
    );
  }
}

/// The password prompt for a protected document.
///
/// Renders no page and no title content: the spec requires that nothing of a
/// locked document is shown before it is unlocked.
class _PasswordPrompt extends StatefulWidget {
  const _PasswordPrompt({required this.state, required this.cubit});

  final ViewerState state;
  final ViewerCubit cubit;

  @override
  State<_PasswordPrompt> createState() => _PasswordPromptState();
}

class _PasswordPromptState extends State<_PasswordPrompt> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    // Cleared as well as disposed: the controller holds the typed password, and
    // it should not outlive the screen in memory any longer than it must.
    _controller
      ..clear()
      ..dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.isEmpty) return;
    widget.cubit.unlock(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.lock_outline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This document is protected',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter its password to open it.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              key: ViewerKeys.passwordField,
              controller: _controller,
              obscureText: true,
              autofocus: true,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                errorText: widget.state.passwordRejected
                    ? 'That password did not work'
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: ViewerKeys.unlockButton,
                onPressed: _submit,
                child: const Text('Open'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The document itself, with its text panel on wide viewports.
class _Document extends StatelessWidget {
  const _Document({
    required this.state,
    required this.cubit,
    required this.surfaceBuilder,
  });

  final ViewerState state;
  final ViewerCubit cubit;
  final PageSurfaceBuilder surfaceBuilder;

  @override
  Widget build(BuildContext context) {
    final document = state.document;
    if (document == null) {
      return const AppLoadingIndicator(semanticsLabel: 'Opening document');
    }

    final surface = surfaceBuilder(
      context,
      filePath: state.filePath ?? '',
      password: state.password,
      page: state.page,
      onPageChanged: cubit.pageChanged,
    );

    return ResponsiveLayout(
      compact: (context) => surface,
      // The extra width on a tablet goes to a text panel beside the page rather
      // than to a wider page: a page scaled past its own resolution shows no
      // more detail, while the recognised text is genuinely useful and has
      // nowhere to live on a phone.
      expanded: (context) => Row(
        children: [
          Expanded(flex: 2, child: surface),
          if (state.hasText)
            SizedBox(width: 340, child: _TextPanel(text: state.recognisedText)),
        ],
      ),
    );
  }
}

/// The recognised-text panel shown beside the page on wide viewports.
class _TextPanel extends StatelessWidget {
  const _TextPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          key: ViewerKeys.textPanel,
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            text,
            style: theme.textTheme.bodySmall,
            semanticsLabel: 'Recognised text. $text',
          ),
        ),
      ),
    );
  }
}

/// The page indicator and intentional jump-to-page control.
class _PageBar extends StatelessWidget {
  const _PageBar({required this.state, required this.cubit});

  final ViewerState state;
  final ViewerCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Center(
        child: Semantics(
          button: true,
          liveRegion: true,
          label: 'Page ${state.page} of ${state.pageCount}, jump to page',
          child: ExcludeSemantics(
            child: TextButton.icon(
              key: ViewerKeys.pageJumpButton,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _PageJumpDialog(state: state, cubit: cubit),
              ),
              icon: const Icon(Icons.find_in_page_outlined),
              label: Text(
                state.pageLabel,
                key: ViewerKeys.pageIndicator,
                maxLines: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageJumpDialog extends StatefulWidget {
  const _PageJumpDialog({required this.state, required this.cubit});

  final ViewerState state;
  final ViewerCubit cubit;

  @override
  State<_PageJumpDialog> createState() => _PageJumpDialogState();
}

class _PageJumpDialogState extends State<_PageJumpDialog> {
  final controller = TextEditingController();
  String? errorText;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    final page = ViewerRules.parsePage(controller.text);
    if (page == null ||
        !ViewerRules.isValidPage(page, pageCount: widget.state.pageCount)) {
      setState(
        () => errorText = 'Enter a page from 1 to ${widget.state.pageCount}.',
      );
      return;
    }
    widget.cubit.goToPage(page);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: ViewerKeys.pageJumpDialog,
      title: Text('Jump to page (1–${widget.state.pageCount})'),
      content: TextField(
        key: ViewerKeys.pageJumpField,
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        onSubmitted: (_) => submit(),
        decoration: InputDecoration(
          labelText: 'Page number',
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          key: ViewerKeys.pageJumpCancel,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: ViewerKeys.pageJumpConfirm,
          onPressed: submit,
          child: const Text('Go'),
        ),
      ],
    );
  }
}
