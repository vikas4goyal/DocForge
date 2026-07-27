/// Golden tests for the PDF editor.
///
/// Tagged `golden` and run on one canonical configuration in CI: rendering the
/// same widget on two platforms produces font-antialiasing diffs that are noise
/// rather than regressions.
@Tags(['golden'])
library;

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/pdf_editing/application/atomic_pdf_write.dart';
import 'package:doc_forge/features/pdf_editing/application/usecases/pdf_edit_usecases.dart';
import 'package:doc_forge/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_forge/features/pdf_editing/infrastructure/repositories/fake_pdf_editor.dart';
import 'package:doc_forge/features/pdf_editing/presentation/cubit/pdf_edit_cubit.dart';
import 'package:doc_forge/features/pdf_editing/presentation/cubit/pdf_edit_state.dart';
import 'package:doc_forge/features/pdf_editing/presentation/screens/pdf_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone viewport, in logical pixels at a device pixel ratio of one.
const _phone = Size(390, 844);

/// A tablet viewport.
const _tablet = Size(1024, 1366);

class _Inert implements DocumentReader, DocumentWriter {
  const _Inert();

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

/// A Cubit frozen at a chosen state.
class _SeededCubit extends PdfEditCubit {
  _SeededCubit(this._seeded) : super(const DocumentId('golden'), _useCases());

  static PdfEditUseCases _useCases() {
    final editor = FakePdfEditor();
    const library = _Inert();
    final context = PdfEditContext(
      documents: library,
      writer: library,
      editor: editor,
      atomic: AtomicPdfWrite(
        (path, password) => editor.pageCountOf(path, password: password),
      ),
      secrets: InMemorySecureStore(),
      destination: (id) => '/golden/${id.value}.pdf',
      clock: FixedClock(DateTime.utc(2026, 3, 14)),
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

  final PdfEditState _seeded;

  @override
  PdfEditState get state => _seeded;
}

Document _document({int pageCount = 6}) => Document(
  id: const DocumentId('golden'),
  title: 'Invoice 2026',
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 4),
  pageCount: pageCount,
  sizeInBytes: 1_884_160,
  filePath: '/golden/a.pdf',
);

PdfMetadata _metadata({int pageCount = 6}) => PdfMetadata(
  title: 'Invoice 2026',
  pageCount: pageCount,
  sizeInBytes: 1_884_160,
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 4),
  isProtected: false,
);

Widget _thumbnail(BuildContext context, int index) => ColoredBox(
  // Fixed colours rather than theme-derived, so the two brightness goldens
  // differ only in the chrome around the pages.
  color: index.isEven ? const Color(0xFFE3E3E6) : const Color(0xFFD2D2D8),
);

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    PdfEditState state, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    // One logical pixel per physical pixel, so the golden's dimensions are the
    // viewport's rather than whatever the host machine reports.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = _SeededCubit(state);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: BlocProvider<PdfEditCubit>.value(
          value: cubit,
          child: PdfEditScreen(thumbnailBuilder: _thumbnail, onClose: () {}),
        ),
      ),
    );

    // Bounded rather than `pumpAndSettle`: the working state shows an
    // indefinite progress indicator, which never settles.
    await tester.pump();
    await tester.pump();
  }

  final ready = const PdfEditState.initial().copyWith(
    status: PdfEditStatus.ready,
    document: _document(),
    metadata: _metadata(),
  );

  group('PDF editor goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpAt(tester, _phone, ready);

      await expectLater(
        find.byType(PdfEditScreen),
        matchesGoldenFile('pdf_edit_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpAt(tester, _phone, ready, brightness: Brightness.dark);

      await expectLater(
        find.byType(PdfEditScreen),
        matchesGoldenFile('pdf_edit_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpAt(tester, _tablet, ready);

      await expectLater(
        find.byType(PdfEditScreen),
        matchesGoldenFile('pdf_edit_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpAt(tester, _tablet, ready, brightness: Brightness.dark);

      await expectLater(
        find.byType(PdfEditScreen),
        matchesGoldenFile('pdf_edit_tablet_dark.png'),
      );
    });

    testWidgets('with a selection, light', (tester) async {
      await pumpAt(tester, _phone, ready.copyWith(selection: {0, 2}));

      await expectLater(
        find.byType(PdfEditScreen),
        matchesGoldenFile('pdf_edit_selected_light.png'),
      );
    });

    testWidgets('error, dark', (tester) async {
      await pumpAt(
        tester,
        _phone,
        ready.copyWith(
          status: PdfEditStatus.failure,
          failure: const Failure.storageFull(),
        ),
        brightness: Brightness.dark,
      );

      await expectLater(
        find.byType(PdfEditScreen),
        matchesGoldenFile('pdf_edit_error_dark.png'),
      );
    });

    testWidgets('working, light', (tester) async {
      await pumpAt(
        tester,
        _phone,
        ready.copyWith(
          status: PdfEditStatus.working,
          operation: PdfEditOperation.compress,
        ),
      );

      await expectLater(
        find.byType(PdfEditScreen),
        matchesGoldenFile('pdf_edit_working_light.png'),
      );
    });
  });
}
