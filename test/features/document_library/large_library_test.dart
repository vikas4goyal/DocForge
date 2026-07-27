/// Verifies the library behaves correctly with several thousand documents.
///
/// The spec requires a large library to load incrementally, scroll smoothly and
/// never load full-resolution page images for list rows. Each of those is
/// asserted here as an observable fact — how many rows were requested, how many
/// widgets exist — rather than as a wall-clock timing, which would be flaky on
/// shared CI hardware and would not say *why* it got slow.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_lifecycle.dart';
import 'package:doc_forge/features/document_library/application/usecases/document_queries.dart';
import 'package:doc_forge/features/document_library/presentation/cubit/document_list_cubit.dart';
import 'package:doc_forge/features/document_library/presentation/screens/document_list_screen.dart';
import 'package:doc_forge/features/document_library/presentation/widgets/document_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// The size the spec calls "several thousand".
const _libraryOfSeveralThousand = 5000;

final _now = DateTime.utc(2026, 8);

void main() {
  late FakeDocumentRepository documents;
  late Clock clock;

  setUp(() {
    documents = FakeDocumentRepository(_largeLibrary());
    clock = FixedClock(_now);
  });

  DocumentListCubit buildCubit() => DocumentListCubit(
    LoadDocuments(documents),
    ToggleFavourite(documents, clock),
    ArchiveDocument(documents, clock),
    RestoreDocument(documents, clock),
  );

  group('a library of $_libraryOfSeveralThousand documents', () {
    test('the first load fetches one page, not the whole library', () async {
      final cubit = buildCubit();

      await cubit.load();

      expect(cubit.state.documents, hasLength(LoadDocuments.pageSize));
      expect(cubit.state.hasMore, isTrue);
      await cubit.close();
    });

    test('each further page costs one query of the same size', () async {
      final cubit = buildCubit();
      await cubit.load();

      await cubit.loadMore();
      await cubit.loadMore();

      expect(cubit.state.documents, hasLength(LoadDocuments.pageSize * 3));
      expect(cubit.state.hasMore, isTrue);
      await cubit.close();
    });

    test('paging never repeats or skips a document', () async {
      final cubit = buildCubit();
      await cubit.load();
      for (var page = 0; page < 5; page++) {
        await cubit.loadMore();
      }

      final ids = cubit.state.documents.map((d) => d.id).toList();

      // A duplicated row means an offset was mis-computed; a gap means one was
      // over-advanced. Both are invisible until a user scrolls far enough.
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, hasLength(LoadDocuments.pageSize * 6));
      await cubit.close();
    });

    test('paging terminates exactly at the end of the library', () async {
      final cubit = buildCubit();
      await cubit.load();

      // Deliberately asks for more pages than exist: the last one must report
      // hasMore false, and further requests must be no-ops rather than looping.
      while (cubit.state.hasMore) {
        await cubit.loadMore();
      }
      final atEnd = cubit.state.documents.length;
      await cubit.loadMore();

      expect(atEnd, _libraryOfSeveralThousand);
      expect(cubit.state.documents, hasLength(atEnd));
      await cubit.close();
    });

    testWidgets('the list builds only the rows on screen', (tester) async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider.value(
            value: cubit,
            child: DocumentListScreen(
              title: 'Documents',
              onOpenDocument: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A builder-based list is what keeps a large library scrollable; a list
      // that materialised every loaded row would already be building 30 cards
      // in a viewport that fits a handful.
      expect(find.byType(DocumentCard), findsAtLeastNWidgets(1));
      expect(
        tester.widgetList(find.byType(DocumentCard)).length,
        lessThan(LoadDocuments.pageSize),
      );
    });

    testWidgets('no list row reads a page image', (tester) async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider.value(
            value: cubit,
            child: DocumentListScreen(
              title: 'Documents',
              onOpenDocument: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Decoding a full-resolution scan per row is the single most likely way
      // to make a large library unusable, so the rows contain no image widget
      // at all — the affordance simply does not exist.
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scrolling to the end of a page requests the next one', (
      tester,
    ) async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider.value(
            value: cubit,
            child: DocumentListScreen(
              title: 'Documents',
              onOpenDocument: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(cubit.state.documents, hasLength(LoadDocuments.pageSize));

      await tester.fling(find.byType(GridView), const Offset(0, -3000), 3000);
      await tester.pumpAndSettle();

      expect(cubit.state.documents.length, greaterThan(LoadDocuments.pageSize));
    });
  });
}

/// Builds a library of [_libraryOfSeveralThousand] distinct documents.
///
/// Generated rather than loaded from a fixture file: the point is the count,
/// and a five-thousand-record fixture would be unreadable in review.
List<Document> _largeLibrary() => List.generate(
  _libraryOfSeveralThousand,
  (index) => Document(
    id: DocumentId('doc-$index'),
    title: 'Document ${index + 1}',
    createdAt: _now.subtract(Duration(minutes: index + 1)),
    updatedAt: _now.subtract(Duration(minutes: index + 1)),
    pageCount: (index % 9) + 1,
    sizeInBytes: (index + 1) * 1024,
    libraryPath: LibraryPath.parse('document.pdf'),
  ),
);
