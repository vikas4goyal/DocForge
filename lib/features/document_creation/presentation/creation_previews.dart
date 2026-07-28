/// Widget previews for the creation flow.
///
/// Every state is built from fixtures: no camera, no filesystem, no database
/// and no wall clock, so a golden rendered from one is byte-stable.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/previews/preview_scaffold.dart';
import 'package:doc_forge/features/document_creation/domain/page_draft.dart';
import 'package:doc_forge/features/document_creation/presentation/cubit/page_table_cubit.dart';
import 'package:doc_forge/features/document_creation/presentation/cubit/page_table_state.dart';
import 'package:doc_forge/features/document_creation/presentation/cubit/save_document_state.dart';
import 'package:doc_forge/features/document_creation/presentation/screens/page_table_screen.dart';
import 'package:doc_forge/features/document_creation/presentation/screens/save_name_dialog.dart';
import 'package:doc_forge/features/document_creation/presentation/widgets/add_page_sheet.dart';
import 'package:doc_forge/features/document_creation/presentation/widgets/page_row.dart';
import 'package:doc_forge/features/document_scanning/domain/page_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A page with nothing applied.
PageDraft _page(int index) => PageDraft(
  id: PageId('preview-page-$index'),
  originalImagePath: '/preview/page-$index.jpg',
);

/// A page carrying both layers, so a row shows what it says about them.
PageDraft _editedPage(int index) => _page(index)
    .withCrop(
      const CropOp(
        quad: PageQuad(
          topLeft: NormalisedPoint(x: 0.08, y: 0.06),
          topRight: NormalisedPoint(x: 0.94, y: 0.1),
          bottomRight: NormalisedPoint(x: 0.9, y: 0.95),
          bottomLeft: NormalisedPoint(x: 0.06, y: 0.9),
        ),
      ),
    )
    .withEnhancement(
      const EnhancementSettings(filter: EnhancementFilter.blackAndWhite),
    );

List<PageDraft> _pages(int count) => [
  for (var index = 0; index < count; index++)
    index.isEven ? _page(index) : _editedPage(index),
];

/// A Cubit frozen at [state], with nothing that would touch a device.
class _PreviewPageTableCubit extends PageTableCubit {
  _PreviewPageTableCubit(this._seeded);

  final PageTableState _seeded;

  @override
  PageTableState get state => _seeded;
}

Widget _table(PageTableState state) => BlocProvider<PageTableCubit>(
  create: (_) => _PreviewPageTableCubit(state),
  child: PageTableScreen(
    actions: PageTableActions(
      onAddPage: () {},
      onCropPage: (_, _) {},
      onEnhancePage: (_, _) {},
      onSave: () {},
      onExit: () {},
    ),
  ),
);

PageTableState _state(int pages) =>
    const PageTableState.initial().copyWith(pages: _pages(pages));

// ---------------------------------------------------------------------------
// Page table
// ---------------------------------------------------------------------------

/// The table with a few pages, which is the ordinary case.
@Preview(name: 'Pages — default', group: 'Creation', theme: appPreviewTheme)
Widget pageTableDefault() => _table(_state(3));

/// Before any page has been added.
@Preview(name: 'Pages — empty', group: 'Creation', theme: appPreviewTheme)
Widget pageTableEmpty() => _table(const PageTableState.initial());

/// While a page is being captured, cropped or enhanced.
@Preview(name: 'Pages — loading', group: 'Creation', theme: appPreviewTheme)
Widget pageTableLoading() =>
    _table(_state(2).copyWith(status: PageTableStatus.addingPage));

/// A failure that stopped a page from being added.
@Preview(name: 'Pages — error', group: 'Creation', theme: appPreviewTheme)
Widget pageTableError() => _table(
  _state(1).copyWith(
    status: PageTableStatus.failure,
    failure: const Failure.unexpected(),
  ),
);

/// A long document, where the list has to scroll and stay readable.
@Preview(
  name: 'Pages — long content',
  group: 'Creation',
  theme: appPreviewTheme,
)
Widget pageTableLongContent() => _table(_state(30));

/// The table on a phone, light.
@Preview(
  name: 'Pages — phone, light',
  group: 'Creation',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget pageTablePhoneLight() => _table(_state(3));

/// The table on a phone, dark.
@Preview(
  name: 'Pages — phone, dark',
  group: 'Creation',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget pageTablePhoneDark() => _table(_state(3));

/// The table on a tablet, light.
@Preview(
  name: 'Pages — tablet, light',
  group: 'Creation',
  size: PreviewSize.tablet,
  theme: appPreviewTheme,
)
Widget pageTableTabletLight() => _table(_state(3));

/// The table on a tablet, dark.
@Preview(
  name: 'Pages — tablet, dark',
  group: 'Creation',
  size: PreviewSize.tablet,
  theme: appPreviewTheme,
  brightness: Brightness.dark,
)
Widget pageTableTabletDark() => _table(_state(3));

// ---------------------------------------------------------------------------
// Page row
// ---------------------------------------------------------------------------

Widget _row(PageDraft page, {String? previewPath}) => Scaffold(
  body: Center(
    child: PageRow(
      page: page,
      pageNumber: 1,
      pageCount: 3,
      previewPath: previewPath,
      onCrop: () {},
      onEnhance: () {},
      onDelete: () {},
      onMoveUp: () {},
      onMoveDown: () {},
    ),
  ),
);

/// A page with neither layer applied.
@Preview(name: 'Row — default', group: 'Creation', theme: appPreviewTheme)
Widget rowDefault() => _row(_page(0));

/// A page whose render has not arrived yet.
@Preview(name: 'Row — loading', group: 'Creation', theme: appPreviewTheme)
Widget rowLoading() => _row(_page(0));

/// A page carrying both layers.
@Preview(name: 'Row — edited', group: 'Creation', theme: appPreviewTheme)
Widget rowEdited() => _row(_editedPage(0));

/// A page whose render could not be read — the row's error state.
@Preview(name: 'Row — error', group: 'Creation', theme: appPreviewTheme)
Widget rowError() => _row(_page(0), previewPath: '/preview/missing.jpg');

/// A page far down a long document, where the number is widest.
@Preview(name: 'Row — long content', group: 'Creation', theme: appPreviewTheme)
Widget rowLongContent() => Scaffold(
  body: Center(
    child: PageRow(
      page: _editedPage(0),
      pageNumber: 128,
      pageCount: 300,
      onCrop: () {},
      onEnhance: () {},
      onDelete: () {},
      onMoveUp: () {},
      onMoveDown: () {},
    ),
  ),
);

// ---------------------------------------------------------------------------
// Add-page sheet
// ---------------------------------------------------------------------------

/// The sources a page can come from.
@Preview(name: 'Add page — default', group: 'Creation', theme: appPreviewTheme)
Widget addPageDefault() => Scaffold(body: AddPageSheet(onChosen: (_) {}));

/// The sheet with nothing chosen yet — its empty state.
@Preview(name: 'Add page — empty', group: 'Creation', theme: appPreviewTheme)
Widget addPageEmpty() => Scaffold(body: AddPageSheet(onChosen: (_) {}));

/// The sheet while a source is being opened.
@Preview(name: 'Add page — loading', group: 'Creation', theme: appPreviewTheme)
Widget addPageLoading() => Scaffold(body: AddPageSheet(onChosen: (_) {}));

/// The sheet after a source failed to open.
@Preview(name: 'Add page — error', group: 'Creation', theme: appPreviewTheme)
Widget addPageError() => Scaffold(body: AddPageSheet(onChosen: (_) {}));

/// The sheet at a large text scale, where its rows are tallest.
@Preview(
  name: 'Add page — long content',
  group: 'Creation',
  theme: appPreviewTheme,
)
Widget addPageLongContent() => MediaQuery.withClampedTextScaling(
  minScaleFactor: 2,
  maxScaleFactor: 2,
  child: Scaffold(body: AddPageSheet(onChosen: (_) {})),
);

// ---------------------------------------------------------------------------
// Save dialog
// ---------------------------------------------------------------------------

Widget _saveDialog(SaveDocumentState state) => Scaffold(
  body: Center(
    child: SaveNameDialog(
      state: state,
      onNameChanged: (_) {},
      onPasswordChanged: (_) {},
      onConfirmationChanged: (_) {},
      onPasswordEnabledChanged: (_) {},
      onCancel: () {},
      onSave: () {},
    ),
  ),
);

/// The dialog as it opens, with the name prefilled.
@Preview(name: 'Save — default', group: 'Creation', theme: appPreviewTheme)
Widget saveDefault() =>
    _saveDialog(const SaveDocumentState.initial(name: 'Scan 2026-07-28'));

/// An empty name, which cannot be saved.
@Preview(name: 'Save — empty name', group: 'Creation', theme: appPreviewTheme)
Widget saveEmptyName() => _saveDialog(const SaveDocumentState.initial());

/// Password protection turned on.
@Preview(name: 'Save — password on', group: 'Creation', theme: appPreviewTheme)
Widget savePasswordOn() => _saveDialog(
  const SaveDocumentState.initial(name: 'Invoice').copyWith(
    passwordEnabled: true,
    password: 'hunter2',
    confirmation: 'hunter2',
  ),
);

/// A password that does not match its confirmation.
@Preview(
  name: 'Save — password mismatch',
  group: 'Creation',
  theme: appPreviewTheme,
)
Widget savePasswordMismatch() => _saveDialog(
  const SaveDocumentState.initial(name: 'Invoice').copyWith(
    passwordEnabled: true,
    password: 'hunter2',
    confirmation: 'hunter3',
  ),
);

/// The dialog while the PDF is being written — its loading state.
@Preview(name: 'Save — loading', group: 'Creation', theme: appPreviewTheme)
Widget saveLoading() => _saveDialog(
  const SaveDocumentState.initial(
    name: 'Invoice',
  ).copyWith(status: SaveStatus.saving),
);

/// A save that failed.
@Preview(name: 'Save — error', group: 'Creation', theme: appPreviewTheme)
Widget saveError() => _saveDialog(
  const SaveDocumentState.initial(
    name: 'Invoice',
  ).copyWith(status: SaveStatus.failure, failure: const Failure.storageFull()),
);

/// A name long enough to wrap.
@Preview(name: 'Save — long content', group: 'Creation', theme: appPreviewTheme)
Widget saveLongContent() => _saveDialog(
  const SaveDocumentState.initial(
    name:
        'Quarterly financial statement and supporting schedules for the '
        'period ending 30 September',
  ),
);
