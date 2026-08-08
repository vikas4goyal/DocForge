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
  /// Opens metadata and lifecycle controls for the document.
  details,

  /// Renames the open document.
  rename,

  /// Moves the open document to another folder.
  move,

  /// Creates a reviewed independent copy.
  duplicate,

  /// Archives the open document.
  archive,

  /// Restores the open archived document.
  restore,

  /// Moves the open document to recoverable Trash.
  moveToTrash,

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

  /// Deletes the explicitly saved automatic-unlock password.
  forgetPassword,

  /// Opens contextual page selection and page-derived actions.
  pageManagement,
}

/// Displays a document and offers the actions that act on it.
class ViewerScreen extends StatelessWidget {
  /// Creates the viewer screen.
  const ViewerScreen({
    required this.surfaceBuilder,
    required this.onBack,
    required this.onShare,
    required this.onShowDetails,
    required this.onAction,
    super.key,
  });

  /// Builds the page-rendering surface.
  final PageSurfaceBuilder surfaceBuilder;

  /// Called when the user leaves the viewer.
  final VoidCallback onBack;

  /// Called when the user shares the document.
  final VoidCallback onShare;

  /// Opens metadata and lifecycle controls, then returns to Viewer.
  final Future<void> Function() onShowDetails;

  /// Called with the focused operation selected from the overflow menu.
  final ValueChanged<ViewerDocumentAction> onAction;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ViewerCubit, ViewerState>(
      listenWhen: (previous, current) =>
          previous.actionFailure != current.actionFailure ||
          (!previous.isUnavailable && current.isUnavailable),
      listener: (context, state) {
        if (state.isUnavailable) {
          onBack();
          return;
        }
        final message = state.actionMessage;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.page != current.page ||
          previous.document?.title != current.document?.title ||
          previous.filePath != current.filePath ||
          previous.pageCount != current.pageCount ||
          previous.password != current.password ||
          previous.passwordRemembered != current.passwordRemembered ||
          previous.failure != current.failure ||
          previous.passwordRejected != current.passwordRejected ||
          previous.isUnavailable != current.isUnavailable,
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
                const _FavouriteAction(),
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
                    onSelected: (action) {
                      if (action == ViewerDocumentAction.details) {
                        onShowDetails();
                      } else {
                        onAction(action);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        key: ViewerKeys.documentDetailsButton,
                        value: ViewerDocumentAction.details,
                        child: Semantics(
                          label: ViewerSemantics.documentDetails,
                          button: true,
                          child: const ExcludeSemantics(
                            child: ListTile(
                              leading: Icon(Icons.info_outline),
                              title: Text('Document details'),
                            ),
                          ),
                        ),
                      ),
                      if (state.passwordRemembered)
                        const PopupMenuItem(
                          key: ViewerKeys.forgetPasswordButton,
                          value: ViewerDocumentAction.forgetPassword,
                          child: ListTile(
                            leading: Icon(Icons.lock_reset_outlined),
                            title: Text('Forget saved password'),
                          ),
                        ),
                      const PopupMenuItem(
                        key: ViewerKeys.renameButton,
                        value: ViewerDocumentAction.rename,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Rename'),
                        ),
                      ),
                      const PopupMenuItem(
                        key: ViewerKeys.moveButton,
                        value: ViewerDocumentAction.move,
                        child: ListTile(
                          leading: Icon(Icons.drive_file_move_outline),
                          title: Text('Move to folder'),
                        ),
                      ),
                      const PopupMenuItem(
                        key: ViewerKeys.duplicateButton,
                        value: ViewerDocumentAction.duplicate,
                        child: ListTile(
                          leading: Icon(Icons.copy_outlined),
                          title: Text('Duplicate'),
                        ),
                      ),
                      if (state.document?.isArchived ?? false)
                        const PopupMenuItem(
                          key: ViewerKeys.restoreButton,
                          value: ViewerDocumentAction.restore,
                          child: ListTile(
                            leading: Icon(Icons.unarchive_outlined),
                            title: Text('Restore'),
                          ),
                        )
                      else
                        const PopupMenuItem(
                          key: ViewerKeys.archiveButton,
                          value: ViewerDocumentAction.archive,
                          child: ListTile(
                            leading: Icon(Icons.archive_outlined),
                            title: Text('Archive'),
                          ),
                        ),
                      const PopupMenuItem(
                        key: ViewerKeys.moveToTrashButton,
                        value: ViewerDocumentAction.moveToTrash,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Move to Trash'),
                        ),
                      ),
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
                      const PopupMenuItem(
                        key: ViewerKeys.managePagesButton,
                        value: ViewerDocumentAction.pageManagement,
                        child: ListTile(
                          leading: Icon(Icons.view_module_outlined),
                          title: Text('Manage pages'),
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

/// Toggles favourite state while rebuilding only Viewer chrome.
class _FavouriteAction extends StatelessWidget {
  const _FavouriteAction();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      ViewerCubit,
      ViewerState,
      ({String title, bool isFavourite, bool isWorking})
    >(
      selector: (state) => (
        title: state.document?.title ?? '',
        isFavourite: state.document?.isFavourite ?? false,
        isWorking: state.isFavouriteWorking,
      ),
      builder: (context, value) {
        final label = ViewerSemantics.favourite(
          value.title,
          isFavourite: value.isFavourite,
        );
        return Semantics(
          button: true,
          toggled: value.isFavourite,
          label: label,
          child: ExcludeSemantics(
            child: IconButton(
              key: ViewerKeys.favouriteButton,
              onPressed: value.isWorking
                  ? null
                  : context.read<ViewerCubit>().toggleFavourite,
              tooltip: label,
              icon: Icon(value.isFavourite ? Icons.star : Icons.star_border),
            ),
          ),
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
  var _remember = false;

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
    widget.cubit.unlock(_controller.text, remember: _remember);
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
            CheckboxListTile(
              key: ViewerKeys.rememberPasswordCheckbox,
              value: _remember,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Save password in DocScanly'),
              subtitle: const Text(
                'This PDF will open automatically on this device. You can forget it from the PDF menu.',
              ),
              onChanged: (value) => setState(() => _remember = value ?? false),
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

/// The document itself.
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
      expanded: (context) => surface,
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
