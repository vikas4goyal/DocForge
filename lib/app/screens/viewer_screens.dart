/// Builds the viewer and the screens it opens over itself: the PDF editor and
/// the share sheet.
///
/// They are built together because every one of them is reached from the
/// viewer's app bar and returns to it, so they share the same document reader,
/// renderer and file resolver.
library;

import 'package:doc_forge/app/document_creation_module.dart';
import 'package:doc_forge/app/library_module.dart';
import 'package:doc_forge/app/pdf_editing_module.dart';
import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/screens/screen_support.dart';
import 'package:doc_forge/app/sharing_module.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/storage/public_storage/document_file_resolver.dart';
import 'package:doc_forge/features/document_sharing/domain/share_content.dart';
import 'package:doc_forge/features/document_sharing/presentation/cubit/share_cubit.dart';
import 'package:doc_forge/features/document_sharing/presentation/cubit/share_state.dart';
import 'package:doc_forge/features/document_sharing/presentation/screens/share_options_sheet.dart';
import 'package:doc_forge/features/document_viewer/application/usecases/viewer_usecases.dart';
import 'package:doc_forge/features/document_viewer/domain/repositories/pdf_renderer.dart';
import 'package:doc_forge/features/document_viewer/presentation/cubit/viewer_cubit.dart';
import 'package:doc_forge/features/document_viewer/presentation/screens/viewer_screen.dart';
import 'package:doc_forge/features/pdf_editing/presentation/cubit/pdf_edit_cubit.dart';
import 'package:doc_forge/features/pdf_editing/presentation/screens/pdf_edit_screen.dart';
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
/// [library] supplies the document reader, [creation] the recognised text the
/// viewer can search and share, [documentFiles] the path a document's bytes
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
  required DocumentCreationModule creation,
  required SharingModule sharing,
  required PdfEditingModule editing,
  required DocumentFileResolver documentFiles,
  required SecureStore secureStorage,
  required PdfRenderer renderer,
}) {
  return ViewerScreens(
    viewer: (context, id) => BlocProvider(
      create: (_) => ViewerCubit(
        id,
        OpenDocumentForViewing(
          library.documentReader,
          renderer,
          secureStorage,
          documentFiles,
        ),
        RememberDocumentPassword(secureStorage),
        LoadViewerText(creation.ocrTextSource),
      )..load(),
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
            }) => PdfViewer.file(
              filePath,
              passwordProvider: () => password,
              params: PdfViewerParams(
                onPageChanged: (page) => onPageChanged(page ?? 1),
              ),
            ),
        onBack: () => context.pop(),
        onShare: () => openShareSheet(context, sharing, id),
        // Printing goes straight to the system dialogue rather than through the
        // sheet: the viewer's print control names the action exactly, and an
        // intermediate sheet asking "print?" would be a step with one option.
        onPrint: () => printDocument(context, sharing, id),
        onEdit: () => openEditor(context, editing, documentFiles, id),
      ),
    ),
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
  DocumentId id,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (routeContext) => BlocProvider(
      create: (_) => PdfEditCubit(id, editing.useCases, documentFiles)..load(),
      child: Builder(
        builder: (screenContext) {
          final path = screenContext.watch<PdfEditCubit>().state.filePath;

          return PdfEditScreen(
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
          );
        },
      ),
    ),
  ),
);

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

  final text = await sharing.ocrTextSource.textForDocument(id);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => ShareCubit(
        id,
        sharing.sharePdf,
        sharing.shareImages,
        sharing.shareText,
        sharing.printDocument,
        sharing.export,
        initial: ShareState.initial(
          title: document.title,
          pageCount: document.pageCount,
          canShareText: ShareRules.canShareText(
            document,
            text.valueOrNull ?? '',
          ),
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
