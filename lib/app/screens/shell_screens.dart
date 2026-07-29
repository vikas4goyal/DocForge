/// Builds Home: the tab shell, the dashboard inside it, and the import paths
/// that start from there.
library;

import 'dart:async';

import 'package:doc_forge/app/creation_module.dart';
import 'package:doc_forge/app/import_module.dart';
import 'package:doc_forge/app/library_module.dart';
import 'package:doc_forge/app/router/app_router.dart';
import 'package:doc_forge/app/router/app_routes.dart';
import 'package:doc_forge/app/screens/screen_support.dart';
import 'package:doc_forge/core/contracts/models/page_draft.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/permissions/permission_service.dart';
import 'package:doc_forge/features/app_shell/presentation/screens/app_tab_scaffold.dart';
import 'package:doc_forge/features/document_import/presentation/cubit/import_cubit.dart';
import 'package:doc_forge/features/document_import/presentation/screens/import_options_sheet.dart';
import 'package:doc_forge/features/document_import/presentation/widgets/shared_content_watcher.dart';
import 'package:doc_forge/features/document_library/application/usecases/library_folder_usecases.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/dashboard_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Builds Home — the tab shell holding the dashboard and settings.
///
/// [library] backs the dashboard's contents and its folder creation.
/// [importing] supplies both import paths: the sheet the user opens deliberately
/// and the content another application shares into DocForge. [creationFlow] is
/// where imported images land, so cropping and enhancement are available to them
/// — which the gallery scenario requires explicitly. [permissions] backs the
/// sheet's "open settings" escape hatch when access was refused.
///
/// [settings] is the already-built settings screen rather than another copy of
/// it, so the tab and the `/settings` route are the same screen.
ScreenBuilder buildHomeScreen({
  required LibraryModule library,
  required ImportModule importing,
  required CreationModule creationFlow,
  required PermissionService permissions,
  required ScreenBuilder settings,
}) {
  return (context) => _TabShell(
    onCreate: () => context.push(AppRoutes.scan),
    dashboard: SharedContentWatcher(
      takePending: importing.takePending,
      watchShared: importing.watchShared,
      // Wrapped around the dashboard rather than around a route that comes
      // and goes: a share arriving while the user is deep in another flow
      // would otherwise be dropped.
      onContent: (paths) =>
          importShared(context, paths, importing, creationFlow),
      child: BlocProvider(
        create: (_) =>
            DashboardCubit(store: library.publicStore, index: library.documents)
              ..load(),
        child: Builder(
          builder: (dashboardContext) => DashboardScreen(
            actions: DashboardActions(
              onOpenDocument: (document) =>
                  context.push(AppRoutes.documentDetail(document.id)),
              onCreateFolder: (name) => createFolder(
                dashboardContext,
                library.createLibraryFolder,
                name,
              ),
              onImportPdf: () => openImportSheet(
                context,
                importing,
                creationFlow,
                permissions,
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

/// Imports [paths] handed to DocForge by another application.
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
