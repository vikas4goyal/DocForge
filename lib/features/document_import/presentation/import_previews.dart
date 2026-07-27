/// Widget previews for importing.
///
/// Every preview is fed by fixtures through a Cubit frozen at a chosen state,
/// so nothing here opens a photo picker or a file browser (`design.md` §15).
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/core/previews/preview_scaffold.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_import/application/usecases/import_usecases.dart';
import 'package:doc_forge/features/document_import/domain/import_rules.dart';
import 'package:doc_forge/features/document_import/infrastructure/repositories/fake_import_sources.dart';
import 'package:doc_forge/features/document_import/presentation/cubit/import_cubit.dart';
import 'package:doc_forge/features/document_import/presentation/cubit/import_state.dart';
import 'package:doc_forge/features/document_import/presentation/screens/import_options_sheet.dart';
import 'package:doc_forge/features/document_import/presentation/widgets/import_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A writer no preview reaches.
class _PreviewWriter implements DocumentWriter {
  const _PreviewWriter();

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async => Result<Document>.success(document);

  @override
  Future<Result<Document>> updateMetadata(Document document) async =>
      Result<Document>.success(document);
}

Directory _neverStaged() => Directory.systemTemp;

String _neverCopied(CopyImportRequest request) =>
    throw StateError('a preview never copies a file');

/// A Cubit frozen at [_seeded].
///
/// Every action is overridden to do nothing: a preview that opened the real
/// photo picker would do so while the developer was looking at a widget.
class _PreviewImportCubit extends ImportCubit {
  _PreviewImportCubit(this._seeded)
    : super(
        FakeGalleryPicker(),
        FakeFileBrowser(),
        ImportFiles(
          ImportImages(
            const InlineBackgroundWorker(),
            _neverStaged,
            SequentialIdGenerator(),
            _neverCopied,
          ),
          ImportPdf(
            FakePdfInspector(),
            const _PreviewWriter(),
            (id) => '/preview/${id.value}.pdf',
            FixedClock(DateTime.utc(2026, 3, 14)),
            SequentialIdGenerator(),
          ),
        ),
      );

  final ImportState _seeded;

  @override
  ImportState get state => _seeded;

  @override
  Future<void> fromGallery() async {}

  @override
  Future<void> fromFiles() async {}

  @override
  Future<void> submitPassword(String password) async {}

  @override
  void cancelPassword() {}

  @override
  void cancel() {}

  @override
  void dismissError() {}
}

Widget _sheet(ImportState state) => BlocProvider<ImportCubit>(
  create: (_) => _PreviewImportCubit(state),
  child: ImportOptionsSheet(onScan: () {}, onOpenSettings: () {}),
);

const _idle = ImportState.initial();

// ---------------------------------------------------------------------------
// Import options sheet
// ---------------------------------------------------------------------------

/// Every source available.
@Preview(name: 'Import — default', group: 'Import', theme: appPreviewTheme)
Widget importDefault() => _sheet(_idle);

/// Files being copied.
@Preview(name: 'Import — loading', group: 'Import', theme: appPreviewTheme)
Widget importLoading() => _sheet(
  _idle.copyWith(
    status: ImportStatus.importing,
    source: ImportSource.gallery,
    progress: const Progress(completed: 3, total: 8),
  ),
);

/// A selection that produced nothing — this sheet's empty state.
@Preview(name: 'Import — empty', group: 'Import', theme: appPreviewTheme)
Widget importEmpty() => _sheet(
  _idle.copyWith(
    status: ImportStatus.failure,
    failure: const Failure.import(unsupportedType: true),
  ),
);

/// An import that failed.
@Preview(name: 'Import — error', group: 'Import', theme: appPreviewTheme)
Widget importError() => _sheet(
  _idle.copyWith(
    status: ImportStatus.failure,
    failure: const Failure.corruptFile(),
  ),
);

/// Photo access refused, with its route to the system settings.
@Preview(
  name: 'Import — permission denied',
  group: 'Import',
  theme: appPreviewTheme,
)
Widget importPermissionDenied() => _sheet(
  _idle.copyWith(
    status: ImportStatus.permissionDenied,
    failure: const Failure.permission(
      kind: PermissionKind.photos,
      permanentlyDenied: true,
    ),
  ),
);

/// A protected PDF waiting for its password.
@Preview(name: 'Import — password', group: 'Import', theme: appPreviewTheme)
Widget importPassword() => _sheet(
  _idle.copyWith(
    status: ImportStatus.awaitingPassword,
    protectedFilePath: '/shared/Statement.pdf',
  ),
);

/// A large batch, where the progress figures grow long.
@Preview(name: 'Import — long content', group: 'Import', theme: appPreviewTheme)
Widget importLongContent() => _sheet(
  _idle.copyWith(
    status: ImportStatus.importing,
    source: ImportSource.files,
    progress: const Progress(completed: 128, total: 256),
  ),
);

/// The sheet on a phone, light.
@Preview(
  name: 'Import — phone, light',
  group: 'Import',
  size: PreviewSize.phone,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget importPhoneLight() => _sheet(_idle);

/// The sheet on a phone, dark.
@Preview(
  name: 'Import — phone, dark',
  group: 'Import',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget importPhoneDark() => _sheet(_idle);

/// The sheet on a tablet, light.
@Preview(
  name: 'Import — tablet, light',
  group: 'Import',
  size: PreviewSize.tablet,
  brightness: Brightness.light,
  theme: appPreviewTheme,
)
Widget importTabletLight() => _sheet(_idle);

/// The sheet on a tablet, dark.
@Preview(
  name: 'Import — tablet, dark',
  group: 'Import',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget importTabletDark() => _sheet(_idle);

// ---------------------------------------------------------------------------
// Import source tile
// ---------------------------------------------------------------------------

/// An enabled source.
@Preview(
  name: 'ImportSourceTile — default',
  group: 'Import',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget sourceTileDefault() =>
    ImportSourceTile(source: ImportSource.gallery, onTap: () {});

/// A disabled source.
@Preview(
  name: 'ImportSourceTile — disabled',
  group: 'Import',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget sourceTileDisabled() =>
    const ImportSourceTile(source: ImportSource.files);

/// A source whose label has to wrap in a narrow column.
@Preview(
  name: 'ImportSourceTile — long content',
  group: 'Import',
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget sourceTileLongContent() =>
    ImportSourceTile(source: ImportSource.shareSheet, onTap: () {});

// ---------------------------------------------------------------------------
// Password prompt
// ---------------------------------------------------------------------------

/// The prompt as first shown.
@Preview(
  name: 'ImportPasswordPrompt — default',
  group: 'Import',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget passwordPromptDefault() =>
    ImportPasswordPrompt(onSubmit: (_) {}, onCancel: () {});

/// The prompt after a rejected attempt — its error state.
@Preview(
  name: 'ImportPasswordPrompt — error',
  group: 'Import',
  theme: appPreviewTheme,
  wrapper: previewSurface,
)
Widget passwordPromptRejected() =>
    ImportPasswordPrompt(onSubmit: (_) {}, onCancel: () {}, wasRejected: true);

/// The prompt in a narrow column.
@Preview(
  name: 'ImportPasswordPrompt — long content',
  group: 'Import',
  theme: appPreviewTheme,
  wrapper: previewNarrow,
)
Widget passwordPromptNarrow() =>
    ImportPasswordPrompt(onSubmit: (_) {}, onCancel: () {}, wasRejected: true);
