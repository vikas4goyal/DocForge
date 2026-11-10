/// Tier 2 — exporting from the share sheet over the REAL Cubit and REAL
/// export use case. Only the platform picker (the repository boundary) is
/// faked, and it records where it was asked to start.
///
/// This is the seam that used to drop the setting: the viewer built the sheet
/// without the configured folder, so the picker never heard about it.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/background_worker.dart';
import 'package:doc_scanly/core/previews/fakes/fake_document_file_resolver.dart';
import 'package:doc_scanly/features/document_sharing/application/usecases/sharing_usecases.dart';
import 'package:doc_scanly/features/document_sharing/infrastructure/repositories/fake_share_repositories.dart';
import 'package:doc_scanly/features/document_sharing/presentation/cubit/share_cubit.dart';
import 'package:doc_scanly/features/document_sharing/presentation/cubit/share_state.dart';
import 'package:doc_scanly/features/document_sharing/presentation/screens/share_options_sheet.dart';
import 'package:doc_scanly/features/document_sharing/presentation/share_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _id = DocumentId('doc-1');

final _document = Document(
  id: _id,
  title: 'Invoice',
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 3, 14),
  pageCount: 1,
  sizeInBytes: 3,
  libraryPath: LibraryPath.parse('Invoice.pdf'),
);

/// A reader holding exactly one document.
class _Reader implements DocumentReader {
  @override
  Future<Result<Document>> findById(DocumentId id) async => id == _id
      ? Result<Document>.success(_document)
      : const Result<Document>.failure(Failure.notFound());

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async => Result<List<Document>>.success([_document]);

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      const Result<List<DocumentPage>>.success([]);
}

void main() {
  late Directory workspace;
  late File source;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('share_export_component');
    source = File('${workspace.path}/Invoice.pdf')..writeAsStringSync('pdf');
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  Future<FakeExportDestinationPicker> exportFromSheet(
    WidgetTester tester, {
    required String? Function() configured,
  }) async {
    final picker = FakeExportDestinationPicker(
      destination: '${workspace.path}/exported.pdf',
    );
    final reader = _Reader();
    final files = FakeDocumentFileResolver(path: source.path);
    final share = FakeShareRepository();
    final cubit = ShareCubit(
      _id,
      ShareDocumentPdf(reader, share, files),
      SharePageImages(
        reader,
        share,
        const InlineBackgroundWorker(),
        () => workspace,
        (request) => request.destinationPath,
      ),
      PrintDocument(reader, FakePrintRepository(), files),
      // The real use case, wired exactly as the composition root wires it.
      ExportDocument(reader, picker, files, defaultLocation: configured),
      initial: const ShareState.initial(title: 'Invoice', pageCount: 1),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<ShareCubit>.value(
            value: cubit,
            child: const ShareOptionsSheet(),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(ShareKeys.exportButton));
    // The fake picker copies real bytes, which needs a real event loop.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    return picker;
  }

  testWidgets('a configured location is where the picker starts', (
    tester,
  ) async {
    final picker = await exportFromSheet(
      tester,
      configured: () => '/storage/emulated/0/Download',
    );

    expect(picker.startLocations, ['/storage/emulated/0/Download']);
    expect(find.byKey(ShareKeys.exportDone), findsOneWidget);
  });

  testWidgets('Ask each time requests no starting location', (tester) async {
    final picker = await exportFromSheet(tester, configured: () => null);

    expect(picker.startLocations, [null]);
    expect(find.byKey(ShareKeys.exportDone), findsOneWidget);
  });
}
