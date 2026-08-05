/// Builds Home: the tab shell, the dashboard inside it, and the import paths
/// that start from there.
library;

import 'dart:async';

import 'package:doc_scanly/app/creation_module.dart';
import 'package:doc_scanly/app/import_module.dart';
import 'package:doc_scanly/app/library_module.dart';
import 'package:doc_scanly/app/router/app_router.dart';
import 'package:doc_scanly/app/router/app_routes.dart';
import 'package:doc_scanly/app/screens/home_refresh.dart';
import 'package:doc_scanly/app/screens/screen_support.dart';
import 'package:doc_scanly/core/contracts/models/page_draft.dart';
import 'package:doc_scanly/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/permissions/permission_service.dart';
import 'package:doc_scanly/features/app_shell/presentation/screens/app_tab_scaffold.dart';
import 'package:doc_scanly/features/document_import/presentation/cubit/import_cubit.dart';
import 'package:doc_scanly/features/document_import/presentation/import_keys.dart';
import 'package:doc_scanly/features/document_import/presentation/screens/import_options_sheet.dart';
import 'package:doc_scanly/features/document_import/presentation/widgets/shared_content_watcher.dart';
import 'package:doc_scanly/features/document_library/application/usecases/bulk_document_lifecycle.dart';
import 'package:doc_scanly/features/document_library/application/usecases/library_folder_usecases.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Builds Home — the tab shell holding the dashboard and settings.
///
/// [library] backs the dashboard's contents and its folder creation.
/// [importing] supplies both import paths: the sheet the user opens deliberately
/// and the content another application shares into DocScanly. [creationFlow] is
/// where imported images land, so cropping and enhancement are available to them
/// — which the gallery scenario requires explicitly. [permissions] backs the
/// sheet's "open settings" escape hatch when access was refused.
///
/// [settings] is the already-built settings screen rather than another copy of
/// it, so the tab and the `/settings` route are the same screen.
///
/// [routeObserver] is how the dashboard learns that a route pushed over it has
/// popped. Without it, a document saved from the creation flow is written to
/// disk and never appears, because Home is built once and nothing rebuilds it.
ScreenBuilder buildHomeScreen({
  required LibraryModule library,
  required ImportModule importing,
  required CreationModule creationFlow,
  required PermissionService permissions,
  required ScreenBuilder settings,
  required HomeRefreshObserver routeObserver,
  Future<void> Function()? onLibraryRefresh,
  Key? libraryRefreshKey,
}) {
  return (context) => _TabShell(
    onCreate: () => context.push(AppRoutes.scan),
    // The provider is outermost so both import paths — the sheet the user
    // opens and the content another application shares in — sit inside it and
    // can reload the dashboard when they finish. The watcher still wraps the
    // dashboard rather than a route that comes and goes, so a share arriving
    // while the user is deep in another flow is not dropped.
    // The provider is outermost so both import paths — the sheet the user
    // opens and the content another application shares in — sit inside it and
    // can reload the dashboard when they finish. The watcher still wraps the
    // dashboard rather than a route that comes and goes, so a share arriving
    // while the user is deep in another flow is not dropped.
    dashboard: BlocProvider(
      create: (_) => DashboardCubit(
        store: library.publicStore,
        index: library.documents,
        inspectTrashCandidate: library.inspectTrashCandidate,
        moveFolderTreeToTrash: library.moveFolderTreeToTrash,
        restoreTrashEntry: library.restoreTrashEntry,
        renameLibraryFolder: library.renameLibraryFolder,
        loadTrash: library.loadTrash,
        bulkArchiveDocuments: BulkArchiveDocuments(
          library.archiveDocument.call,
        ),
        bulkTrashDocuments: BulkTrashDocuments(
          library.moveDocumentToTrash.call,
        ),
      )..load(),
      child: Builder(
        builder: (dashboardContext) => HomeRefreshListener(
          observer: routeObserver,
          // Saving a scan and reviewing imported pages both leave a route above
          // Home and both can change what the library holds. Home is built once
          // and kept alive, so without this the document is written and never
          // appears.
          onRefresh: () => unawaited(reloadDashboard(dashboardContext)),
          child: SharedContentWatcher(
            key: ImportKeys.sharedContentWatcher,
            takePending: importing.takePending,
            watchShared: importing.watchShared,
            onContent: (paths) =>
                importShared(dashboardContext, paths, importing, creationFlow),
            child: DashboardScreen(
              loadThumbnail: library.loadDocumentPageThumbnail.call,
              onLibraryRefresh: onLibraryRefresh,
              libraryRefreshKey: libraryRefreshKey,
              actions: DashboardActions(
                onOpenDocument: (document) =>
                    context.push(AppRoutes.documentDetail(document.id)),
                onCreateFolder: (name) => createFolder(
                  dashboardContext,
                  library.createLibraryFolder,
                  name,
                ),
                // Opened from the dashboard's own context rather than the
                // route's, because a completed import has to reload the
                // dashboard and only a descendant of its provider can reach it.
                onImportPdf: () => openImportSheet(
                  dashboardContext,
                  importing,
                  creationFlow,
                  permissions,
                ),
                onOpenFavourites: () => context.push(AppRoutes.favourites),
                onOpenArchive: () => context.push(AppRoutes.archive),
                onOpenTrash: () => context.push(AppRoutes.trash),
              ),
            ),
          ),
        ),
      ),
    ),
    settings: settings(context),
  );
}

/// The tab shell, holding whichever destination is selected.
///
/// Selection lives here rather than in the router because Create is an action
/// rather than a place: it pushes the page table above the shell, and the
/// destination the user was on stays selected underneath (`design.md` D10).
class _TabShell extends StatefulWidget {
  const _TabShell({
    required this.dashboard,
    required this.settings,
    required this.onCreate,
  });

  final Widget dashboard;
  final Widget settings;
  final VoidCallback onCreate;

  @override
  State<_TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<_TabShell> {
  AppTab _tab = AppTab.dashboard;

  @override
  Widget build(BuildContext context) {
    return AppTabScaffold(
      tab: _tab,
      onTabSelected: (tab) => setState(() => _tab = tab),
      onCreate: widget.onCreate,
      // Both destinations stay built, so switching away and back returns the
      // user to the folder they were in rather than to the library root.
      child: IndexedStack(
        index: _tab.index,
        children: [widget.dashboard, widget.settings],
      ),
    );
  }
}

/// Imports [paths] handed to DocScanly by another application.
///
/// Goes straight to importing rather than showing the sources: the user already
/// chose what to send and where to send it, and asking them again would be a
/// question with one answer.
Future<void> importShared(
  BuildContext context,
  List<String> paths,
  ImportModule importing,
  CreationModule creationFlow,
) async {
  final cubit = ImportCubit(
    importing.gallery,
    importing.files,
    importing.importFiles,
  );

  try {
    await cubit.fromShareSheet(paths);
    if (!context.mounted) return;

    final state = cubit.state;
    final bundle = state.bundle;

    if (bundle != null) {
      await reviewImportedPages(context, bundle, creationFlow);
    } else if (state.imported.isNotEmpty) {
      report(context, state.outcomeMessage);
      // Same reason as the import sheet: the dashboard is kept alive by the
      // tab shell and nothing else would rebuild it, so a document shared in
      // from another application would arrive invisibly.
      await reloadDashboard(context);
    } else if (state.message != null) {
      report(context, state.message!);
    }
  } finally {
    await cubit.close();
  }
}

/// Opens the import sources as a modal bottom sheet.
///
/// Images that come back are handed to the scanning flow's *review* step rather
/// than saved directly, which is what makes cropping and enhancement available
/// to them — the requirement the gallery scenario states explicitly.
Future<void> openImportSheet(
  BuildContext context,
  ImportModule importing,
  CreationModule creationFlow,
  PermissionService permissions,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => ImportCubit(
        importing.gallery,
        importing.files,
        importing.importFiles,
      ),
      child: ImportOptionsSheet(
        onScan: () => Navigator.of(sheetContext).pop(),
        onOpenSettings: permissions.openSettings,
        onReadyForReview: (bundle) {
          Navigator.of(sheetContext).pop();
          unawaited(reviewImportedPages(context, bundle, creationFlow));
        },
        onImported: (state) {
          Navigator.of(sheetContext).pop();
          report(context, state.outcomeMessage);
          // The dashboard is built once and kept alive by the tab shell's
          // IndexedStack, so nothing rebuilds it when the sheet closes over
          // it. Without this the user is told "1 document imported" while
          // looking at a library that still appears empty, and it stays that
          // way until the application is relaunched.
          unawaited(reloadDashboard(context));
        },
      ),
    ),
  );
}

/// Opens the scanning flow at its review step, over [bundle].
///
/// A nested navigator route rather than a top-level one: the flow is transient
/// and carries state the router has no place holding, which is the same reason
/// the crop screen is pushed this way.
Future<void> reviewImportedPages(
  BuildContext context,
  ScannedPageBundle bundle,
  CreationModule creationFlow,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (routeContext) => CreationFlow(
      module: creationFlow,
      // Imported images arrive as pages with neither layer applied: they are
      // already whatever the user chose to photograph or save, and the crop
      // screen is there if they want one.
      initialPages: [
        for (final page in bundle.pages)
          PageDraft(id: page.id, originalImagePath: page.imagePath),
      ],
      onExit: () => Navigator.of(routeContext).pop(),
      onSaved: (_) => Navigator.of(routeContext).pop(),
    ),
  ),
);

/// Reloads the dashboard so it shows what was just written.
///
/// The dashboard is created once, inside the tab shell's IndexedStack, and both
/// destinations stay built — which is what returns the user to the folder they
/// were in rather than to the library root. The cost of that is that nothing
/// rebuilds it when a sheet closes over it, so anything that adds a document
/// from outside the dashboard has to say so.
///
/// Safe to call from a context that has no [DashboardCubit] above it: an import
/// can also be started from a route where there is no dashboard to reload, and
/// that is not a failure.
Future<void> reloadDashboard(BuildContext context) async {
  final cubit = context.mounted
      ? context.findAncestorWidgetOfExactType<BlocProvider<DashboardCubit>>()
      : null;
  if (cubit == null || !context.mounted) return;

  await context.read<DashboardCubit>().load();
}

/// Creates a folder, reporting a refusal where the user can see it.
///
/// Validation lives in the use case rather than the dialog: a name the
/// filesystem will refuse has to be refused the same way wherever it is
/// entered.
Future<void> createFolder(
  BuildContext context,
  CreateLibraryFolder create,
  String name,
) async {
  final created = await create(
    name,
    parent: context.read<DashboardCubit>().state.path,
  );
  if (!context.mounted) return;

  switch (created) {
    case Success():
      await context.read<DashboardCubit>().load();
    case Failed(:final failure):
      report(context, failure.presentation.message);
  }
}
