/// Builds the viewer and the screens it opens over itself: the PDF editor and
/// the share sheet.
///
/// They are built together because every one of them is reached from the
/// viewer's app bar and returns to it, so they share the same document reader,
/// renderer and file resolver.
library;

import 'package:doc_scanly/app/library_module.dart';
import 'package:doc_scanly/app/pdf_editing_module.dart';
import 'package:doc_scanly/app/router/app_router.dart';
import 'package:doc_scanly/app/router/app_routes.dart';
import 'package:doc_scanly/app/screens/screen_support.dart';
import 'package:doc_scanly/app/sharing_module.dart';
import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/document_detail_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/document_detail_screen.dart';
import 'package:doc_scanly/features/document_sharing/presentation/cubit/share_cubit.dart';
import 'package:doc_scanly/features/document_sharing/presentation/cubit/share_state.dart';
import 'package:doc_scanly/features/document_sharing/presentation/screens/share_options_sheet.dart';
import 'package:doc_scanly/features/document_viewer/application/usecases/viewer_usecases.dart';
import 'package:doc_scanly/features/document_viewer/domain/repositories/pdf_renderer.dart';
import 'package:doc_scanly/features/document_viewer/presentation/cubit/viewer_cubit.dart';
import 'package:doc_scanly/features/document_viewer/presentation/screens/viewer_screen.dart';
import 'package:doc_scanly/features/document_viewer/presentation/viewer_keys.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/pdf_edit_cubit.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/screens/pdf_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

/// The viewer and the route that stands in for a document's editing tools.
class ViewerScreens {
  /// Creates the group.
  const ViewerScreens({required this.viewer, required this.documentEdit});

  /// Reads one document.
  final DocumentScreenBuilder viewer;

  /// A document's editing tools, as a route.
  ///
  /// A placeholder: the editor is pushed imperatively from the viewer, because
  /// it carries selection state the router has no place holding.
  final DocumentScreenBuilder documentEdit;
}

/// Builds the viewer over the modules that supply what it shows and what it can
/// do with it.
///
/// [library] supplies the document reader and [documentFiles] the path a document's bytes
/// live at, and [secureStorage] the remembered password for a protected file —
/// secure storage rather than preferences, because an unprotected file can be
/// edited on a rooted device.
///
/// [sharing] and [editing] back the app-bar actions.
///
/// [renderer] is a parameter because opening a PDF is a platform edge: pdfrx
/// binds a native library that exists on Android and iOS but not in the host
/// test VM, so tests substitute `FakePdfRenderer`. The composition root
/// defaults it to the real renderer.
ViewerScreens buildViewerScreens({
  required LibraryModule library,
  required SharingModule sharing,
  required PdfEditingModule editing,
  required DocumentFileResolver documentFiles,
  required SecureStore secureStorage,
  required PdfRenderer renderer,
}) {
  return ViewerScreens(
    viewer: (context, id) {
      final viewerCubit = ViewerCubit(
        id,
        OpenDocumentForViewing(
          library.documentReader,
          renderer,
          secureStorage,
          documentFiles,
        ),
        RememberDocumentPassword(secureStorage),
        ForgetDocumentPassword(secureStorage),
        (documentId) async {
          final found = await library.documentReader.findById(documentId);
          // Trash keeps the record for recovery, but it is no longer available
          // to the reading stack. Report that as not-found so returning from
          // Details closes this one Viewer route without disturbing its origin.
          return found.flatMap(
            (document) => document.trashId == null
                ? Result<Document>.success(document)
                : const Result<Document>.failure(Failure.notFound()),
          );
        },
        library.toggleFavourite.call,
      );
      final lifecycleCubit = DocumentDetailCubit(
        id,
        library.loadDocumentDetail,
        library.renameDocument,
        library.moveDocument,
        library.toggleFavourite,
        library.archiveDocument,
        library.restoreDocument,
        library.duplicateDocument,
        library.purgeDocument,
        moveToTrash: library.moveDocumentToTrash,
        loadFolderOptions: library.loadFolderOptions,
      );

      Future<void> runLifecycle(DocumentLifecycleAction action) async {
        final document = viewerCubit.state.document;
        if (document == null) return;

        final result = await runDocumentLifecycleAction(
          context,
          cubit: lifecycleCubit,
          document: document,
          action: action,
        );
        if (!context.mounted) return;

        final opened = result.openedDocument;
        if (opened != null) {
          context.pushReplacement(AppRoutes.documentView(opened.id));
          return;
        }
        if (result.unavailable) {
          context.pop();
          return;
        }
        if (result.changed) await viewerCubit.refreshMetadata();
      }

      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => viewerCubit..load()),
          BlocProvider(create: (_) => lifecycleCubit..load()),
        ],
        child: ViewerScreen(
          // The rendering surface comes from here rather than from the screen:
          // it is a plugin-backed widget, and a screen that built its own could
          // be neither previewed nor tested.
          surfaceBuilder:
              (
                context, {
                required filePath,
                required password,
                required page,
                required onPageChanged,
              }) => KeyedSubtree(
                key: ViewerKeys.pageView,
                child: PdfViewer.file(
                  filePath,
                  passwordProvider: () => password,
                  params: PdfViewerParams(
                    onPageChanged: (page) => onPageChanged(page ?? 1),
                  ),
                ),
              ),
          onBack: () => context.pop(),
          onShare: () => openShareSheet(context, sharing, id),
          onShowDetails: () async {
            final recordUnavailable = await context.push<bool>(
              AppRoutes.documentDetail(id),
            );
            if (!context.mounted) return;

            // Detail owns the mutation and reports an unavailable record
            // explicitly. Close this Viewer from that result instead of also
            // waiting for a metadata emission: combining both signals creates
            // two competing navigation paths on slower devices.
            if (recordUnavailable == true) {
              context.pop();
              return;
            }

            await viewerCubit.refreshMetadata();
          },
          // Printing goes straight to the system dialogue rather than through the
          // sheet: the viewer's print control names the action exactly, and an
          // intermediate sheet asking "print?" would be a step with one option.
          onAction: (action) {
            switch (action) {
              case ViewerDocumentAction.details:
                // Handled by [onShowDetails] so Viewer can refresh afterwards.
                break;
              case ViewerDocumentAction.rename:
                runLifecycle(DocumentLifecycleAction.rename);
              case ViewerDocumentAction.move:
                runLifecycle(DocumentLifecycleAction.move);
              case ViewerDocumentAction.duplicate:
                runLifecycle(DocumentLifecycleAction.duplicate);
              case ViewerDocumentAction.archive:
                runLifecycle(DocumentLifecycleAction.archive);
              case ViewerDocumentAction.restore:
                runLifecycle(DocumentLifecycleAction.restore);
              case ViewerDocumentAction.moveToTrash:
                runLifecycle(DocumentLifecycleAction.moveToTrash);
              case ViewerDocumentAction.print:
                printDocument(context, sharing, id);
              case ViewerDocumentAction.compress:
                openEditor(
                  context,
                  editing,
                  documentFiles,
                  id,
                  documentReader: library.documentReader,
                  initialOperation: PdfEditOperation.compress,
                );
              case ViewerDocumentAction.split:
                openEditor(
                  context,
                  editing,
                  documentFiles,
                  id,
                  documentReader: library.documentReader,
                  initialOperation: PdfEditOperation.split,
                );
              case ViewerDocumentAction.watermark:
                openEditor(
                  context,
                  editing,
                  documentFiles,
                  id,
                  documentReader: library.documentReader,
                  initialOperation: PdfEditOperation.watermark,
                );
              case ViewerDocumentAction.protection:
                openEditor(
                  context,
                  editing,
                  documentFiles,
                  id,
                  documentReader: library.documentReader,
                  initialOperation: PdfEditOperation.protect,
                );
              case ViewerDocumentAction.forgetPassword:
                viewerCubit.forgetPassword();
              case ViewerDocumentAction.pageManagement:
                openEditor(
                  context,
                  editing,
                  documentFiles,
                  id,
                  documentReader: library.documentReader,
                );
            }
          },
        ),
      );
    },
    documentEdit: (_, id) => PlaceholderScreen('Edit ${id.value}'),
  );
}

/// Opens the PDF editor for [id].
///
/// A nested navigator route, like the imported-page review: the editor carries
/// selection state the router has no place holding, and it returns to the
/// viewer the user opened it from.
Future<void> openEditor(
  BuildContext context,
  PdfEditingModule editing,
  DocumentFileResolver documentFiles,
  DocumentId id, {
  required DocumentReader documentReader,
  PdfEditOperation? initialOperation,
}) async {
  final available = await documentReader.query();
  if (!context.mounted) return;
  final mergeCandidates = [
    for (final document in available.valueOrNull ?? const <Document>[])
      if (document.id != id && !document.isArchived) document,
  ];

  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (routeContext) => BlocProvider(
        create: (_) =>
            PdfEditCubit(id, editing.useCases, documentFiles)..load(),
        child: Builder(
          builder: (screenContext) {
            final path = screenContext.watch<PdfEditCubit>().state.filePath;

            return PdfEditScreen(
              initialOperation: initialOperation,
              mergeCandidates: mergeCandidates,
              // The real thumbnail is a rendered PDF page. Supplied here rather
              // than by the screen, because rendering is plugin-backed and a
              // screen that built its own could be neither previewed nor tested.
              thumbnailBuilder: (context, index) => path == null
                  ? const ColoredBox(color: Color(0xFFE0E0E0))
                  : PdfDocumentViewBuilder.file(
                      path,
                      builder: (context, document) => document == null
                          ? const ColoredBox(color: Color(0xFFE0E0E0))
                          : PdfPageView(
                              document: document,
                              pageNumber: index + 1,
                            ),
                    ),
              onClose: () => Navigator.of(routeContext).pop(),
              onDone: () {
                Navigator.of(routeContext).pop();
                context.go(AppRoutes.home);
              },
              onDerived: (document) {
                Navigator.of(routeContext).pop();
                context.pushReplacement(AppRoutes.documentView(document.id));
              },
            );
          },
        ),
      ),
    ),
  );
}

/// Opens the share options for [id] as a modal bottom sheet.
///
/// The document is read first so the sheet can say what it is about to share
/// and disable the text option when there is nothing to share — both of which
/// are decisions the sheet renders rather than makes.
Future<void> openShareSheet(
  BuildContext context,
  SharingModule sharing,
  DocumentId id,
) async {
  final found = await sharing.documentReader.findById(id);
  if (!context.mounted) return;

  final document = found.valueOrNull;
  if (document == null) {
    report(context, 'That document could not be opened.');
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => ShareCubit(
        id,
        sharing.sharePdf,
        sharing.shareImages,
        sharing.printDocument,
        sharing.export,
        initial: ShareState.initial(
          title: document.title,
          pageCount: document.pageCount,
        ),
      ),
      child: ShareOptionsSheet(
        // Dismissed once the system has the content: leaving the sheet up
        // behind the share sheet would leave the user looking at options for
        // something they have already sent.
        onDone: (state) {
          Navigator.of(sheetContext).pop();
          final confirmation = state.exportConfirmation;
          if (confirmation != null) report(context, confirmation);
        },
      ),
    ),
  );
}

/// Prints [id], reporting a failure rather than swallowing it.
Future<void> printDocument(
  BuildContext context,
  SharingModule sharing,
  DocumentId id,
) async {
  final result = await sharing.printDocument(id);
  if (!context.mounted) return;

  if (result case Failed(:final failure)) {
    report(context, failure.presentation.message);
  }
}
