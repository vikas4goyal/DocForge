/// Constructs the creation object graph and hosts the creation flow.
///
/// The flow is one screen with a loop behind it: pick or capture, crop,
/// enhance, done, row. Everything else the user does — reordering, deleting,
/// re-editing — happens on the table itself (`design.md` D9).
library;

import 'dart:async';

import 'package:doc_scanly/app/scanning_module.dart';
import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/contracts/models/page_render_plan.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/capture_staging.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/features/document_creation/application/usecases/add_page.dart';
import 'package:doc_scanly/features/document_creation/application/usecases/render_page.dart';
import 'package:doc_scanly/features/document_creation/presentation/creation_keys.dart';
import 'package:doc_scanly/features/document_creation/presentation/cubit/page_table_cubit.dart';
import 'package:doc_scanly/features/document_creation/presentation/cubit/save_document_cubit.dart';
import 'package:doc_scanly/features/document_creation/presentation/cubit/save_document_state.dart';
import 'package:doc_scanly/features/document_creation/presentation/screens/page_table_screen.dart';
import 'package:doc_scanly/features/document_creation/presentation/screens/save_name_dialog.dart';
import 'package:doc_scanly/features/document_creation/presentation/widgets/add_page_sheet.dart';
import 'package:doc_scanly/features/document_scanning/domain/scan_session.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/scan_capture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Route-stable inputs handed from the page table to the Save PDF flow.
class CreationSaveSession {
  /// Creates an immutable snapshot of the pages and destination being saved.
  CreationSaveSession({
    required this.sessionId,
    required List<PageDraft> pages,
    required this.suggestedName,
    required List<String> folders,
    this.folderId,
  }) : pages = List<PageDraft>.unmodifiable(pages),
       folders = List<String>.unmodifiable(folders);

  /// Private capture-staging session identifier.
  final String sessionId;

  /// Pages in their final table order.
  final List<PageDraft> pages;

  /// Naming-pattern suggestion shown on first load.
  final String suggestedName;

  /// Public-library destination folders.
  final List<String> folders;

  /// Managed folder identity, when present.
  final FolderId? folderId;
}

/// Opens the typed Save PDF route for one creation-session snapshot.
typedef OpenCreationSavePdf =
    Future<Document?> Function(
      BuildContext context,
      CreationSaveSession session,
    );

/// Everything the creation flow needs, built once.
class CreationModule {
  /// Creates the module.
  const CreationModule({
    required this.staging,
    required this.renderPage,
    required this.stagePage,
    required this.addFromGallery,
    required this.discardSession,
    required this.scanning,
    required this.save,
    required this.suggestName,
    required this.store,
    required this.desiredCameraResolution,
    this.openSavePdf,
  });

  /// Where a session's working files live.
  final CaptureStaging staging;

  /// Renders a page from its original and its layers.
  final RenderPage renderPage;

  /// Copies a captured page into this creation session.
  final StagePageImage stagePage;

  /// Picks pages from the photo library and stages them.
  final AddPagesFromGallery addFromGallery;

  /// Removes everything a session wrote.
  final DiscardCreationSession discardSession;

  /// The camera and the crop and enhance editors.
  final ScanningModule scanning;

  /// Writes the document.
  final SaveDocumentRequest save;

  /// The name the save dialog opens with.
  final Future<String> Function() suggestName;

  /// The library folder, so a duplicate name can be spotted before writing.
  final PublicFileStore store;

  /// Reads the current camera preference before each capture.
  final DesiredCameraResolution Function() desiredCameraResolution;

  /// Typed Save PDF route launcher supplied by the composition root.
  ///
  /// Null retains the legacy dialog only for isolated component tests whose
  /// router intentionally does not install the new route.
  final OpenCreationSavePdf? openSavePdf;
}

/// Hosts the whole creation flow behind one route.
///
/// The table and its editors share one session: the pages on the table are what
/// crop and enhancement edit, and the originals they were built from live in
/// one staging directory that is deleted when the session ends. Modelling the
/// steps as sibling routes would mean lifting that session above the router
/// into ambient state, which the architecture forbids.
class CreationFlow extends StatefulWidget {
  /// Creates the flow.
  const CreationFlow({
    required this.module,
    required this.onExit,
    required this.onSaved,
    super.key,
    this.initialPages = const [],
    this.folders = const [],
    this.folderId,
  });

  /// The creation object graph.
  final CreationModule module;

  /// Called when the flow ends without a document.
  final VoidCallback onExit;

  /// Called with the document once it has been saved.
  final void Function(Document document) onSaved;

  /// Pages the flow starts with, when they came from a share or a file import.
  final List<PageDraft> initialPages;

  /// The folder the document is written into, relative to the library root.
  final List<String> folders;

  /// The folder record the document belongs to, when it is in one.
  final FolderId? folderId;

  @override
  State<CreationFlow> createState() => _CreationFlowState();
}

class _CreationFlowState extends State<CreationFlow> {
  /// Identifies this session's staging directory.
  ///
  /// Derived from the table's identity rather than the clock, so nothing here
  /// depends on wall time and two sessions cannot collide.
  late final String _sessionId = identityHashCode(this).toRadixString(16);

  late final PageTableCubit _table = PageTableCubit(
    initialPages: widget.initialPages,
  );

  /// Rendered previews by page, so a row shows the page as it now is.
  ///
  /// Keyed by the plan rather than the page: a page whose layers have not
  /// changed keeps its render, and one whose layers have changed cannot show
  /// the previous version.
  final Map<String, String> _previews = {};

  @override
  void initState() {
    super.initState();
    for (final page in widget.initialPages) {
      unawaited(_refreshPreview(page));
    }
  }

  @override
  void dispose() {
    _table.close();
    super.dispose();
  }

  /// Renders [page] and records the result against its plan.
  Future<void> _refreshPreview(PageDraft page) async {
    final plan = PageRenderPlan.of(page);
    if (_previews.containsKey(plan.cacheKey)) return;

    final rendered = await widget.module.renderPage(plan);
    if (!mounted) return;

    if (rendered case Success(:final value)) {
      setState(() => _previews[plan.cacheKey] = value);
    }
  }

  /// The rendered image for [page], when one is ready.
  String? _previewFor(PageDraft page) {
    final plan = PageRenderPlan.of(page);
    final cached = _previews[plan.cacheKey];
    if (cached == null) unawaited(_refreshPreview(page));
    return cached;
  }

  /// Offers the sources and runs the loop for whichever is chosen.
  Future<void> _addPage() async {
    final choice = await showModalBottomSheet<PageSourceChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => AddPageSheet(
        onChosen: (choice) => Navigator.of(sheetContext).pop(choice),
      ),
    );
    if (choice == null || !mounted) return;

    _table.beginAddingPage();

    final staged = switch (choice) {
      PageSourceChoice.camera => await _captureOne(),
      PageSourceChoice.gallery => await _pickMany(),
    };

    if (!mounted) return;
    if (staged.isEmpty) {
      _table.cancelAddingPage();
      return;
    }

    // Each image goes through the same loop, in the order the user chose them.
    for (final page in staged) {
      final finished = await _editNewPage(page);
      if (!mounted) return;

      if (finished == null) {
        // Abandoned at crop or enhancement: nothing is added, and the staged
        // original goes rather than being left to occupy space.
        continue;
      }
      _table.addPage(finished);
      unawaited(_refreshPreview(finished));
    }

    if (mounted) _table.cancelAddingPage();
  }

  Future<List<PageDraft>> _captureOne() async {
    CapturedPage? captured;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => BlocProvider(
          create: (_) => ScanCaptureCubit(
            widget.module.scanning.scanner,
            widget.module.scanning.capturePage,
            widget.module.scanning.discardSession,
            desiredResolution: widget.module.desiredCameraResolution,
          ),
          child: ScanCaptureScreen(
            previewBuilder: widget.module.scanning.buildPreview,
            onPageCaptured: (_, page) async => captured = page,
            onFinished: () => Navigator.of(routeContext).pop(),
            onCancelled: () => Navigator.of(routeContext).pop(),
            onOpenSettings: () =>
                unawaited(widget.module.scanning.openSettings()),
            onImportInstead: () => Navigator.of(routeContext).pop(),
          ),
        ),
      ),
    );
    if (!mounted || captured == null) return const [];
    final staged = await widget.module.stagePage(
      captured!.imagePath,
      sessionId: _sessionId,
      moveSource: true,
    );
    return switch (staged) {
      Success(:final value) => [value],
      Failed() => const [],
    };
  }

  Future<List<PageDraft>> _pickMany() async {
    final picked = await widget.module.addFromGallery(sessionId: _sessionId);
    return picked.valueOrNull ?? const [];
  }

  /// Takes a freshly staged page through crop, then enhancement.
  ///
  /// Returns null when the user left either screen without continuing, which
  /// callers must treat as "add nothing" rather than as a failure.
  Future<PageDraft?> _editNewPage(PageDraft page) async {
    return editNewPageReversibly(
      page,
      openCrop: (working) => mounted
          ? openPageCrop(context, module: widget.module.scanning, page: working)
          : Future<PageDraft?>.value(),
      openEnhance: (cropped) => mounted
          ? openPageEnhance(
              context,
              module: widget.module.scanning,
              page: cropped,
            )
          : Future<PageDraft?>.value(),
    );
  }

  /// Opens crop for a row, from the page's current state.
  Future<void> _cropPage(int index, PageDraft page) async {
    final edited = await openPageCrop(
      context,
      module: widget.module.scanning,
      page: page,
    );
    if (edited == null || !mounted) return;

    _table.replace(index, edited);
    unawaited(_refreshPreview(edited));
  }

  /// Opens enhancement for a row, from the page's current crop.
  Future<void> _enhancePage(int index, PageDraft page) async {
    final edited = await openPageEnhance(
      context,
      module: widget.module.scanning,
      page: page,
    );
    if (edited == null || !mounted) return;

    _table.replace(index, edited);
    unawaited(_refreshPreview(edited));
  }

  /// Asks for a name, then writes the document.
  Future<void> _save() async {
    final suggested = await widget.module.suggestName();
    if (!mounted) return;

    final openSavePdf = widget.module.openSavePdf;
    if (openSavePdf != null) {
      final saved = await openSavePdf(
        context,
        CreationSaveSession(
          sessionId: _sessionId,
          pages: _table.state.pages,
          suggestedName: suggested,
          folders: widget.folders,
          folderId: widget.folderId,
        ),
      );
      if (saved != null && mounted) widget.onSaved(saved);
      return;
    }

    final cubit = SaveDocumentCubit(
      pages: _table.state.pages,
      save: widget.module.save,
      folders: widget.folders,
      folderId: widget.folderId,
      suggestedName: suggested,
      isNameTaken: (fileName, folders) async {
        final listed = await widget.module.store.list(folders);
        return (listed.valueOrNull ?? const <PublicEntry>[]).any(
          (entry) => !entry.isFolder && entry.name == fileName,
        );
      },
      confirmReplace: _confirmReplace,
    );

    final saved = await showDialog<Document>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocBuilder<SaveDocumentCubit, SaveDocumentState>(
        bloc: cubit,
        builder: (builderContext, state) => SaveNameDialog(
          state: state,
          onNameChanged: cubit.nameChanged,
          onPasswordChanged: cubit.passwordChanged,
          onConfirmationChanged: cubit.confirmationChanged,
          onPasswordEnabledChanged: (enabled) =>
              cubit.passwordEnabledChanged(enabled: enabled),
          onCancel: () => Navigator.of(dialogContext).pop(),
          onSave: () async {
            final document = await cubit.submit();
            // Only dismissed on success: a failed write leaves the dialog up
            // with the reason, and the pages are still on the table behind it.
            if (document != null && dialogContext.mounted) {
              Navigator.of(dialogContext).pop(document);
            }
          },
        ),
      ),
    );

    await cubit.close();
    if (saved == null || !mounted) return;

    // The PDF is written, so nothing the session produced is worth keeping.
    await widget.module.discardSession(_sessionId);
    if (!mounted) return;

    widget.onSaved(saved);
  }

  /// Asks whether to replace a document of the same name.
  ///
  /// Overwriting silently would destroy a document the user still has, and
  /// suffixing silently would give them a name they did not choose.
  Future<bool> _confirmReplace(String fileName) async {
    if (!mounted) return false;

    final replace = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: CreationKeys.replacePrompt,
        title: const Text('Replace this document?'),
        content: Text(
          '"$fileName" is already in this folder. Replacing it cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Choose another name'),
          ),
          FilledButton(
            key: CreationKeys.replaceConfirmButton,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );

    return replace ?? false;
  }

  /// Leaves the flow, asking first when there is something to lose.
  Future<void> _exit() async {
    if (!_table.state.needsDiscardConfirmation) {
      await widget.module.discardSession(_sessionId);
      if (mounted) widget.onExit();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: CreationKeys.discardPrompt,
        title: const Text('Discard these pages?'),
        content: Text(
          'The ${_table.state.pageCount} page(s) you have added will be '
          'deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            key: CreationKeys.discardCancelButton,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            key: CreationKeys.discardConfirmButton,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (discard != true || !mounted) return;

    await widget.module.discardSession(_sessionId);
    if (mounted) widget.onExit();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PageTableCubit>.value(
      value: _table,
      child: PopScope(
        // Intercepted so a system back gesture asks the same question the close
        // control does, rather than silently abandoning the pages.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_exit());
        },
        child: PageTableScreen(
          actions: PageTableActions(
            onAddPage: _addPage,
            onCropPage: _cropPage,
            onEnhancePage: _enhancePage,
            onSave: _save,
            onExit: _exit,
            previewPathFor: _previewFor,
          ),
        ),
      ),
    );
  }
}

/// Runs Crop then Enhance while making Enhance Back return to Crop.
///
/// A null Crop result abandons the page. A null Enhance result means the user
/// navigated back to revise geometry, so the last cropped page is reopened.
Future<PageDraft?> editNewPageReversibly(
  PageDraft page, {
  required Future<PageDraft?> Function(PageDraft page) openCrop,
  required Future<PageDraft?> Function(PageDraft page) openEnhance,
}) async {
  var working = page;
  while (true) {
    final cropped = await openCrop(working);
    if (cropped == null) return null;
    final enhanced = await openEnhance(cropped);
    if (enhanced != null) return enhanced;
    working = cropped;
  }
}
