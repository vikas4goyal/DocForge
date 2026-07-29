/// The document viewer screen.
library;

import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:doc_forge/features/document_viewer/domain/repositories/pdf_renderer.dart';
import 'package:doc_forge/features/document_viewer/presentation/cubit/viewer_cubit.dart';
import 'package:doc_forge/features/document_viewer/presentation/cubit/viewer_state.dart';
import 'package:doc_forge/features/document_viewer/presentation/viewer_keys.dart';
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

/// Displays a document and offers the actions that act on it.
class ViewerScreen extends StatelessWidget {
  /// Creates the viewer screen.
  const ViewerScreen({
    required this.surfaceBuilder,
    required this.onBack,
    required this.onShare,
    required this.onPrint,
    required this.onEdit,
    super.key,
  });

  /// Builds the page-rendering surface.
  final PageSurfaceBuilder surfaceBuilder;

  /// Called when the user leaves the viewer.
  final VoidCallback onBack;

  /// Called when the user shares the document.
  final VoidCallback onShare;

  /// Called when the user prints the document.
  final VoidCallback onPrint;

  /// Called when the user opens the editing tools.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewerCubit, ViewerState>(
      builder: (context, state) {
        final cubit = context.read<ViewerCubit>();

        return Scaffold(
          key: ViewerKeys.screen,
          appBar: AppBar(
            title: Text(state.title),
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
                IconButton(
                  key: ViewerKeys.printButton,
                  onPressed: onPrint,
                  icon: const Icon(
                    Icons.print_outlined,
                    semanticLabel: 'Print document',
                  ),
                  tooltip: 'Print document',
                ),
                IconButton(
                  key: ViewerKeys.editButton,
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    semanticLabel: 'Edit document',
                  ),
                  tooltip: 'Edit document',
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

/// The page indicator and the jump-to-page control.
class _PageBar extends StatefulWidget {
  const _PageBar({required this.state, required this.cubit});

  final ViewerState state;
  final ViewerCubit cubit;

  @override
  State<_PageBar> createState() => _PageBarState();
}

class _PageBarState extends State<_PageBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jump() {
    final page = ViewerRules.parsePage(_controller.text);
    // A non-numeric entry is ignored rather than treated as page one: silently
    // jumping somewhere arbitrary is worse than doing nothing visible.
    if (page == null) return;

    widget.cubit.goToPage(page);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        children: [
          Semantics(
            liveRegion: true,
            label: ViewerSemantics.pageIndicator(widget.state.pageLabel),
            child: ExcludeSemantics(
              child: Text(
                widget.state.pageLabel,
                key: ViewerKeys.pageIndicator,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 120,
            child: TextField(
              key: ViewerKeys.jumpToPageField,
              controller: _controller,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _jump(),
              decoration: const InputDecoration(
                labelText: 'Go to page',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
