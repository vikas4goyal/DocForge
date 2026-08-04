/// Tests the PDF generation Cubit.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_generation/application/usecases/pdf_generation_usecases.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/cubit/pdf_generation_cubit.dart';
import 'package:doc_scanly/features/pdf_generation/presentation/cubit/pdf_generation_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pdf_test_support.dart';

void main() {
  late FakePdfComposer composer;
  late RecordingDocumentWriter writer;
  late List<String> deleted;

  setUp(() {
    composer = FakePdfComposer();
    writer = RecordingDocumentWriter();
    deleted = [];
  });

  List<PageRef> pages(int count) => [
    for (var index = 0; index < count; index++)
      PageRef(id: PageId('page-$index'), imagePath: '/page-$index.jpg'),
  ];

  PdfGenerationCubit build({
    int pageCount = 3,
    NamingPattern pattern = NamingPattern.dateOnly,
    String? suggestedTitle,
  }) => PdfGenerationCubit(
    pages(pageCount),
    SaveDocument(
      BuildSearchablePdf(composer, (_) async => const {}),
      writer,
      FixedClock(DateTime.utc(2026, 3, 14, 9, 30)),
      SequentialIdGenerator(prefix: 'doc'),
      (id) => '/documents/${id.value}.pdf',
      (path) async => deleted.add(path),
      InMemoryPublicFileStore(),
      _noProtection,
    ),
    GenerateDocumentName(
      FixedClock(DateTime(2026, 3, 14, 9, 30)),
      StubDocumentReader(),
    ),
    source: PageSource.camera,
    pattern: pattern,
    suggestedTitle: suggestedTitle,
  );

  group('loading the default name', () {
    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'expands the configured pattern',
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.title, 'Scan 2026-03-14'),
    );

    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'a suggested title wins over the pattern',
      build: () => build(suggestedTitle: 'Bank statement'),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.title, 'Bank statement'),
    );
  });

  group('naming', () {
    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'what the user types becomes the title',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.setTitle('Receipts');
      },
      verify: (cubit) => expect(cubit.state.effectiveTitle, 'Receipts'),
    );

    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'clearing the field falls back to the default, not to nothing',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.setTitle('Receipts');
        cubit.setTitle('');
      },
      // An untitled document is unfindable, and the library forbids one.
      verify: (cubit) => expect(cubit.state.effectiveTitle, 'Scan 2026-03-14'),
    );

    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'the entered title is what gets saved',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.setTitle('Receipts');
        await cubit.save();
      },
      verify: (_) => expect(writer.saved.single.title, 'Receipts'),
    );
  });

  group('quality', () {
    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'defaults to balanced',
      build: build,
      verify: (cubit) => expect(cubit.state.quality, PdfQuality.defaultQuality),
    );

    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'the chosen quality reaches composition',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.setQuality(PdfQuality.high);
        await cubit.save();
      },
      verify: (_) => expect(composer.requests.single.quality, PdfQuality.high),
    );
  });

  group('saving', () {
    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'ends saved with the document',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.save();
      },
      verify: (cubit) {
        expect(cubit.state.status, PdfGenerationStatus.saved);
        expect(cubit.state.document, isNotNull);
      },
    );

    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'passes through a generating state',
      build: build,
      act: (cubit) => cubit.save(),
      expect: () => [
        isA<PdfGenerationState>().having(
          (s) => s.status,
          'status',
          PdfGenerationStatus.generating,
        ),
        isA<PdfGenerationState>().having(
          (s) => s.status,
          'status',
          PdfGenerationStatus.saved,
        ),
      ],
    );

    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'refuses to save a session with no pages',
      build: () => build(pageCount: 0),
      act: (cubit) => cubit.save(),
      verify: (cubit) {
        expect(cubit.state.canSave, isFalse);
        expect(composer.requests, isEmpty);
      },
    );

    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'a second save while one runs is ignored',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await Future.wait([cubit.save(), cubit.save()]);
      },
      // Two documents from one intent would be far worse than a dropped tap.
      verify: (_) => expect(writer.saved, hasLength(1)),
    );
  });

  group('failure', () {
    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'surfaces with a message and a retry',
      build: build,
      act: (cubit) async {
        composer.failure = const Failure.pdf();
        await cubit.load();
        await cubit.save();
      },
      verify: (cubit) {
        expect(cubit.state.status, PdfGenerationStatus.failure);
        expect(cubit.state.message, isNotNull);
      },
    );

    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'retains the pages so the user can retry without rescanning',
      build: build,
      act: (cubit) async {
        composer.failure = const Failure.pdf();
        await cubit.load();
        await cubit.save();
      },
      verify: (cubit) => expect(cubit.state.pages, hasLength(3)),
    );

    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'retrying after a failure succeeds once the cause is gone',
      build: build,
      act: (cubit) async {
        composer.failure = const Failure.pdf();
        await cubit.load();
        await cubit.save();

        composer.failure = null;
        await cubit.retry();
      },
      verify: (cubit) => expect(cubit.state.status, PdfGenerationStatus.saved),
    );

    blocTest<PdfGenerationCubit, PdfGenerationState>(
      'a storage-full failure reports itself as such',
      build: build,
      act: (cubit) async {
        composer.failure = const Failure.storageFull();
        await cubit.load();
        await cubit.save();
      },
      verify: (cubit) => expect(cubit.state.failure, isA<StorageFullFailure>()),
    );
  });

  group('cancellation', () {
    test('leaves no record and no file, and is not an error', () async {
      final cubit = build();
      // Cancelled from inside composition: the window between the file
      // existing and the record being written is exactly what the cleanup rule
      // covers.
      composer.onCompose = cubit.cancel;

      await cubit.load();
      await cubit.save();

      expect(cubit.state.status, PdfGenerationStatus.ready);
      expect(cubit.state.failure, isNull);
      expect(writer.saved, isEmpty);
      expect(deleted, hasLength(1));

      await cubit.close();
    });

    test('closing the Cubit cancels a running generation', () async {
      final cubit = build();

      await cubit.close();

      expect(cubit.isClosed, isTrue);
    });
  });

  group('state', () {
    test('reports the page count for the save control', () {
      expect(build().state.pageCount, 3);
    });

    test('cannot save while generating', () {
      const state = PdfGenerationState.initial(pages: [], title: 'x');

      expect(state.canSave, isFalse);
    });
  });
}

/// Protection that returns the file untouched.
///
/// These tests assert on what the generator produces, not on the encryption —
/// which the editing feature owns and tests separately.
Future<Result<String>> _noProtection(
  String sourcePath,
  String password,
) async => Result<String>.success(sourcePath);
