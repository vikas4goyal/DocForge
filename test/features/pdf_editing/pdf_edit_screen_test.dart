/// Widget tests for the PDF editor screen.
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/fakes/fake_document_file_resolver.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_editing/application/atomic_pdf_write.dart';
import 'package:doc_scanly/features/pdf_editing/application/usecases/pdf_edit_usecases.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/infrastructure/repositories/fake_pdf_editor.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/pdf_edit_cubit.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/cubit/pdf_edit_state.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/pdf_edit_keys.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/screens/pdf_edit_screen.dart';
import 'package:doc_scanly/features/pdf_editing/presentation/widgets/pdf_edit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// An inert library, because the stub Cubit never reaches it.
class _Inert implements DocumentReader, DocumentWriter {
  @override
  Future<Result<Document>> findById(DocumentId id) async =>
      const Result<Document>.failure(Failure.notFound());

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async => const Result<List<Document>>.success([]);

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      const Result<List<DocumentPage>>.success([]);

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async => Result<Document>.success(document);

  @override
  Future<Result<Document>> updateMetadata(Document document) async =>
      Result<Document>.success(document);
}

/// A Cubit that records what was asked of it and renders a seeded state.
class _StubCubit extends PdfEditCubit {
  _StubCubit()
    : super(
        const DocumentId('a'),
        _useCases(),
        const FakeDocumentFileResolver(),
      );

  static PdfEditUseCases _useCases() {
    final inert = _Inert();
    final editor = FakePdfEditor();
    final context = PdfEditContext(
      documents: inert,
      writer: inert,
      editor: editor,
      atomic: AtomicPdfWrite(
        (path, password) => editor.pageCountOf(path, password: password),
      ),
      secrets: InMemorySecureStore(),
      store: InMemoryPublicFileStore(),
      files: const FakeDocumentFileResolver(),
      workingDirectory: Directory.systemTemp,
      clock: FixedClock(DateTime.utc(2026)),
      ids: SequentialIdGenerator(),
    );

    return PdfEditUseCases(
      rotate: RotatePage(context),
      delete: DeletePages(context),
      duplicate: DuplicatePage(context),
      extract: ExtractPages(context),
      merge: MergeDocuments(context),
      split: SplitDocument(context),
      compress: CompressDocument(context),
      watermark: WatermarkDocument(context),
      protect: ProtectDocument(context),
      removePassword: RemoveDocumentPassword(context),
      metadata: ReadPdfMetadata(context),
    );
  }

  final List<String> calls = [];

  /// Moves to [seeded], so the screen observes a real transition.
  void seed(PdfEditState seeded) => emit(seeded);

  @override
  Future<void> rotate() async => calls.add('rotate');

  @override
  Future<void> delete() async => calls.add('delete');

  @override
  Future<void> duplicate() async => calls.add('duplicate');

  @override
  Future<void> extract() async => calls.add('extract');

  @override
  Future<void> compress() async => calls.add('compress');

  @override
  Future<void> split(int afterPage) async => calls.add('split:$afterPage');

  @override
  Future<void> merge(List<DocumentId> others) async =>
      calls.add('merge:${others.length}');

  @override
  Future<void> watermark(String text) async => calls.add('watermark:$text');

  @override
  Future<void> protect(String password) async => calls.add('protect:$password');

  @override
  Future<void> removePassword(String currentPassword) async =>
      calls.add('removePassword:$currentPassword');

  @override
  void toggleSelection(int page) => calls.add('toggle:$page');

  @override
  void dismissError() => calls.add('dismiss');
}

Document doc({
  String title = 'Invoice',
  int pageCount = 4,
  bool isProtected = false,
}) => Document(
  id: const DocumentId('a'),
  title: title,
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 3, 14),
  pageCount: pageCount,
  sizeInBytes: 184_320,
  libraryPath: LibraryPath.parse('a.pdf'),
  isProtected: isProtected,
);

PdfMetadata metadata({int pageCount = 4, bool isProtected = false}) =>
    PdfMetadata(
      title: 'Invoice',
      pageCount: pageCount,
      sizeInBytes: 184_320,
      createdAt: DateTime.utc(2026, 3, 14),
      updatedAt: DateTime.utc(2026, 4),
      isProtected: isProtected,
    );

/// A stand-in for the plugin-backed page thumbnail.
Widget thumbnail(BuildContext context, int index) =>
    ColoredBox(color: Colors.grey.shade300);

void main() {
  Future<_StubCubit> pump(
    WidgetTester tester,
    PdfEditState state, {
    Brightness brightness = Brightness.light,
    Size viewport = const Size(600, 2400),
    List<Document> mergeCandidates = const [],
    ValueChanged<Document>? onDerived,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = _StubCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<PdfEditCubit>.value(
          value: cubit,
          child: PdfEditScreen(
            thumbnailBuilder: thumbnail,
            onClose: () {},
            onDerived: onDerived,
            mergeCandidates: mergeCandidates,
          ),
        ),
      ),
    );

    cubit.seed(state);
    // Two bounded pumps: a Cubit delivers on a microtask, so one would still be
    // rendering the previous state.
    await tester.pump();
    await tester.pump();

    return cubit;
  }

  final ready = const PdfEditState.initial().copyWith(
    status: PdfEditStatus.ready,
    document: doc(),
    metadata: metadata(),
  );

  group('composition', () {
    testWidgets('shows the page grid and every editing control', (
      tester,
    ) async {
      await pump(tester, ready);

      expect(find.byKey(PdfEditKeys.screen), findsOneWidget);
      expect(find.byKey(PdfEditKeys.pageGrid), findsOneWidget);
      expect(find.byKey(PdfEditKeys.rotateButton), findsOneWidget);
      expect(find.byKey(PdfEditKeys.deleteButton), findsOneWidget);
      expect(find.byKey(PdfEditKeys.extractButton), findsOneWidget);
      expect(find.byKey(PdfEditKeys.duplicateButton), findsOneWidget);
    });

    testWidgets('shows a tile per page', (tester) async {
      await pump(tester, ready);

      expect(find.byType(PdfPageTile), findsNWidgets(4));
    });

    testWidgets('tapping a page toggles its selection', (tester) async {
      final cubit = await pump(tester, ready);

      await tester.tap(find.byKey(PdfEditKeys.page(1)));
      await tester.pump();

      expect(cubit.calls, ['toggle:1']);
    });
  });

  group('page controls', () {
    testWidgets('rotate is disabled with no selection', (tester) async {
      final cubit = await pump(tester, ready);

      await tester.tap(find.byKey(PdfEditKeys.rotateButton));
      await tester.pump();

      expect(cubit.calls, isEmpty);
    });

    testWidgets('rotate runs with exactly one page selected', (tester) async {
      final cubit = await pump(tester, ready.copyWith(selection: {1}));

      await tester.tap(find.byKey(PdfEditKeys.rotateButton));
      await tester.pump();

      expect(cubit.calls, ['rotate']);
    });

    testWidgets('rotate is disabled with several pages selected', (
      tester,
    ) async {
      final cubit = await pump(tester, ready.copyWith(selection: {0, 1}));

      await tester.tap(find.byKey(PdfEditKeys.rotateButton));
      await tester.pump();

      expect(cubit.calls, isEmpty);
    });

    testWidgets('extract runs with any selection', (tester) async {
      final cubit = await pump(tester, ready.copyWith(selection: {0, 2}));

      await tester.tap(find.byKey(PdfEditKeys.extractButton));
      await tester.pump();

      expect(cubit.calls, ['extract']);
    });

    testWidgets('deleting asks first, then runs', (tester) async {
      // Deletion is the one page operation with no undo.
      final cubit = await pump(tester, ready.copyWith(selection: {0}));

      await tester.tap(find.byKey(PdfEditKeys.deleteButton));
      await tester.pumpAndSettle();

      expect(find.text('Delete pages?'), findsOneWidget);

      await tester.tap(find.byKey(PdfEditKeys.deleteConfirmButton));
      await tester.pumpAndSettle();

      expect(cubit.calls, ['delete']);
    });

    testWidgets('cancelling the confirmation deletes nothing', (tester) async {
      final cubit = await pump(tester, ready.copyWith(selection: {0}));

      await tester.tap(find.byKey(PdfEditKeys.deleteButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cubit.calls, isEmpty);
    });

    testWidgets('delete is disabled when it would empty the document', (
      tester,
    ) async {
      final cubit = await pump(
        tester,
        ready.copyWith(
          document: doc(pageCount: 1),
          metadata: metadata(pageCount: 1),
          selection: {0},
        ),
      );

      await tester.tap(find.byKey(PdfEditKeys.deleteButton));
      await tester.pumpAndSettle();

      // Disabled rather than refused: the user finds out before they commit.
      expect(find.text('Delete pages?'), findsNothing);
      expect(cubit.calls, isEmpty);
    });
  });

  group('document tools', () {
    testWidgets('compress runs', (tester) async {
      final cubit = await pump(tester, ready);

      await tester.ensureVisible(find.byKey(PdfEditKeys.compressButton));
      await tester.tap(find.byKey(PdfEditKeys.compressButton));
      await tester.pump();

      expect(cubit.calls, ['compress']);
    });

    testWidgets('merge is disabled with fewer than two documents', (
      tester,
    ) async {
      final cubit = await pump(tester, ready);

      await tester.ensureVisible(find.byKey(PdfEditKeys.mergeConfirmButton));
      await tester.tap(find.byKey(PdfEditKeys.mergeConfirmButton));
      await tester.pump();

      expect(cubit.calls, isEmpty);
      expect(find.textContaining('at least one other'), findsOneWidget);
    });

    testWidgets('merge runs once there is another document', (tester) async {
      final cubit = await pump(
        tester,
        ready,
        mergeCandidates: [doc(title: 'Receipt')],
      );

      await tester.ensureVisible(find.byKey(PdfEditKeys.mergeConfirmButton));
      await tester.tap(find.byKey(PdfEditKeys.mergeConfirmButton));
      await tester.pump();

      expect(cubit.calls, ['merge:1']);
    });

    testWidgets('split is disabled for a single-page document', (tester) async {
      final cubit = await pump(
        tester,
        ready.copyWith(
          document: doc(pageCount: 1),
          metadata: metadata(pageCount: 1),
        ),
      );

      await tester.ensureVisible(find.byKey(PdfEditKeys.splitConfirmButton));
      await tester.tap(find.byKey(PdfEditKeys.splitConfirmButton));
      await tester.pump();

      expect(cubit.calls, isEmpty);
    });
  });

  group('watermark', () {
    testWidgets('the preview tracks what is typed', (tester) async {
      await pump(tester, ready);

      await tester.ensureVisible(find.byKey(PdfEditKeys.watermarkTextField));
      await tester.enterText(
        find.byKey(PdfEditKeys.watermarkTextField),
        'CONFIDENTIAL',
      );
      await tester.pump();

      expect(find.byKey(PdfEditKeys.watermarkPreview), findsOneWidget);
      expect(find.text('CONFIDENTIAL'), findsAtLeastNWidgets(1));
    });

    testWidgets('applying is disabled until there is text', (tester) async {
      final cubit = await pump(tester, ready);

      await tester.ensureVisible(
        find.byKey(PdfEditKeys.watermarkConfirmButton),
      );
      await tester.tap(find.byKey(PdfEditKeys.watermarkConfirmButton));
      await tester.pump();

      expect(cubit.calls, isEmpty);
    });

    testWidgets('applying passes the text through', (tester) async {
      final cubit = await pump(tester, ready);

      await tester.ensureVisible(find.byKey(PdfEditKeys.watermarkTextField));
      await tester.enterText(
        find.byKey(PdfEditKeys.watermarkTextField),
        'DRAFT',
      );
      await tester.pump();
      await tester.tap(find.byKey(PdfEditKeys.watermarkConfirmButton));
      await tester.pump();

      expect(cubit.calls, ['watermark:DRAFT']);
    });
  });

  group('protection', () {
    testWidgets('an unprotected document offers protection', (tester) async {
      final cubit = await pump(tester, ready);

      await tester.ensureVisible(find.byKey(PdfEditKeys.protectPasswordField));
      await tester.enterText(
        find.byKey(PdfEditKeys.protectPasswordField),
        'hunter2',
      );
      await tester.pump();
      await tester.tap(find.byKey(PdfEditKeys.protectConfirmButton));
      await tester.pump();

      expect(cubit.calls, ['protect:hunter2']);
    });

    testWidgets('a protected document offers removal instead', (tester) async {
      final cubit = await pump(
        tester,
        ready.copyWith(
          document: doc(isProtected: true),
          metadata: metadata(isProtected: true),
        ),
      );

      expect(find.byKey(PdfEditKeys.protectConfirmButton), findsNothing);

      await tester.ensureVisible(find.byKey(PdfEditKeys.protectPasswordField));
      await tester.enterText(
        find.byKey(PdfEditKeys.protectPasswordField),
        'hunter2',
      );
      await tester.pump();
      await tester.tap(find.byKey(PdfEditKeys.removePasswordButton));
      await tester.pump();

      expect(cubit.calls, ['removePassword:hunter2']);
    });

    testWidgets('a rejected password is reported without an error view', (
      tester,
    ) async {
      await pump(
        tester,
        ready.copyWith(
          document: doc(isProtected: true),
          metadata: metadata(isProtected: true),
          passwordRejected: true,
        ),
      );

      expect(find.byKey(PdfEditKeys.errorView), findsNothing);
      expect(find.textContaining('did not work'), findsAtLeastNWidgets(1));
    });
  });

  group('metadata', () {
    testWidgets('shows every field the spec names', (tester) async {
      await pump(tester, ready);

      await tester.ensureVisible(find.byKey(PdfEditKeys.metadataView));

      expect(find.byKey(PdfEditKeys.metadataView), findsOneWidget);
      for (final label in [
        'Title',
        'Pages',
        'Size',
        'Created',
        'Modified',
        'Protected',
      ]) {
        expect(find.text(label), findsOneWidget, reason: '$label is missing');
      }
    });
  });

  group('progress and failures', () {
    testWidgets('shows progress while an operation runs', (tester) async {
      await pump(
        tester,
        ready.copyWith(
          status: PdfEditStatus.working,
          operation: PdfEditOperation.compress,
        ),
      );

      expect(find.byKey(PdfEditKeys.progress), findsOneWidget);
    });

    testWidgets('shows the error view with a recovery control', (tester) async {
      await pump(
        tester,
        ready.copyWith(
          status: PdfEditStatus.failure,
          failure: const Failure.corruptFile(),
        ),
      );

      expect(find.byKey(PdfEditKeys.errorView), findsOneWidget);
      expect(find.byKey(PdfEditKeys.errorRetryButton), findsOneWidget);
    });

    testWidgets('a full device still offers a way forward', (tester) async {
      final cubit = await pump(
        tester,
        ready.copyWith(
          status: PdfEditStatus.failure,
          failure: const Failure.storageFull(),
        ),
      );

      await tester.tap(find.byKey(PdfEditKeys.errorRetryButton));
      await tester.pump();

      expect(cubit.calls, ['dismiss']);
    });

    testWidgets('reports a derived document to the caller', (tester) async {
      final derived = <Document>[];

      await pump(
        tester,
        ready.copyWith(derived: doc(title: 'Invoice (2 pages)')),
        onDerived: derived.add,
      );

      expect(derived, hasLength(1));
    });
  });

  group('accessibility', () {
    testWidgets('each page announces its number and selection state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, ready.copyWith(selection: {1}));

      expect(
        find.bySemanticsLabel('Page 1 of 4, not selected'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Page 2 of 4, selected'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('every editing control has a descriptive label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, ready.copyWith(selection: {0}));

      for (final operation in [
        PdfEditOperation.rotate,
        PdfEditOperation.duplicate,
        PdfEditOperation.extract,
        PdfEditOperation.delete,
      ]) {
        expect(
          find.bySemanticsLabel(operation.semanticsLabel),
          findsAtLeastNWidgets(1),
          reason: '${operation.name} has no semantics label',
        );
      }

      handle.dispose();
    });

    testWidgets('metadata rows announce their name and value together', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, ready);

      expect(find.bySemanticsLabel('Pages, 4'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('every control meets the minimum touch target', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, ready);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('passes the contrast guideline in dark mode', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, ready, brightness: Brightness.dark);

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });

    testWidgets('survives a tablet viewport at double text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cubit = _StubCubit();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child!,
          ),
          home: BlocProvider<PdfEditCubit>.value(
            value: cubit,
            child: PdfEditScreen(thumbnailBuilder: thumbnail, onClose: () {}),
          ),
        ),
      );
      cubit.seed(ready);
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
