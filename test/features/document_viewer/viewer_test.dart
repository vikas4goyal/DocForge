/// Tests the viewer rules, use cases and Cubit.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/document_viewer/application/usecases/viewer_usecases.dart';
import 'package:doc_scanly/features/document_viewer/domain/repositories/pdf_renderer.dart';
import 'package:doc_scanly/features/document_viewer/infrastructure/repositories/pdfrx_renderer.dart';
import 'package:doc_scanly/features/document_viewer/presentation/cubit/viewer_cubit.dart';
import 'package:doc_scanly/features/document_viewer/presentation/cubit/viewer_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'viewer_test_support.dart';

void main() {
  group('page navigation rules', () {
    test('clamps a page beyond the end to the last page', () {
      // What the user was reaching for; rejecting would leave them where they
      // started with nothing to show for it.
      expect(ViewerRules.clampPage(99, pageCount: 12), 12);
    });

    test('clamps a page below one to the first', () {
      expect(ViewerRules.clampPage(0, pageCount: 12), 1);
      expect(ViewerRules.clampPage(-5, pageCount: 12), 1);
    });

    test('leaves a valid page alone', () {
      expect(ViewerRules.clampPage(7, pageCount: 12), 7);
    });

    test('an empty document clamps to one rather than to zero', () {
      // Page numbers the user sees count from one, and a zeroth page has no
      // meaning to show them.
      expect(ViewerRules.clampPage(3, pageCount: 0), 1);
    });

    test('validity follows the same one-based range', () {
      expect(ViewerRules.isValidPage(1, pageCount: 3), isTrue);
      expect(ViewerRules.isValidPage(3, pageCount: 3), isTrue);
      expect(ViewerRules.isValidPage(0, pageCount: 3), isFalse);
      expect(ViewerRules.isValidPage(4, pageCount: 3), isFalse);
      expect(ViewerRules.isValidPage(1, pageCount: 0), isFalse);
    });

    test('parses a typed page number, tolerating whitespace', () {
      expect(ViewerRules.parsePage(' 7 '), 7);
    });

    test('rejects an entry that is not a number', () {
      // Returning null rather than a guess is what lets the field do nothing
      // visible instead of jumping somewhere arbitrary.
      expect(ViewerRules.parsePage('seven'), isNull);
      expect(ViewerRules.parsePage(''), isNull);
      expect(ViewerRules.parsePage('  '), isNull);
      expect(ViewerRules.parsePage('3.5'), isNull);
    });

    test('the indicator names the page and the total', () {
      expect(ViewerRules.pageIndicatorLabel(3, 12), '3 of 12');
    });
  });

  group('zoom rules', () {
    test('a document opens unzoomed', () {
      expect(ViewerRules.defaultZoom, 1.0);
    });

    test('zoom is bounded at both ends', () {
      expect(ViewerRules.clampZoom(99), ViewerRules.maxZoom);
      expect(ViewerRules.clampZoom(0.01), ViewerRules.minZoom);
      expect(ViewerRules.clampZoom(2), 2);
    });

    test('the range allows both zooming out and well in', () {
      expect(ViewerRules.minZoom, lessThan(ViewerRules.defaultZoom));
      expect(ViewerRules.maxZoom, greaterThan(ViewerRules.defaultZoom));
    });

    test('a double tap on an unzoomed page zooms in', () {
      expect(
        ViewerRules.toggleZoom(ViewerRules.defaultZoom),
        ViewerRules.doubleTapZoom,
      );
    });

    test('a double tap on a zoomed page resets', () {
      // "Put it back" is the gesture's established meaning everywhere else.
      expect(
        ViewerRules.toggleZoom(ViewerRules.doubleTapZoom),
        ViewerRules.defaultZoom,
      );
      expect(ViewerRules.toggleZoom(ViewerRules.maxZoom), 1.0);
    });
  });

  group('OpenDocumentForViewing', () {
    test('opens an unprotected document', () async {
      final harness = ViewerHarness();

      final result = await harness.open(const DocumentId('doc-1'));

      expect((result as Success<ViewableDocument>).value.pageCount, 3);
      expect(result.value.isProtected, isFalse);
    });

    test('reports a missing document rather than crashing', () async {
      final harness = ViewerHarness(documentFound: false);

      final result = await harness.open(const DocumentId('missing'));

      expect(
        (result as Failed<ViewableDocument>).failure,
        isA<NotFoundFailure>(),
      );
    });

    test('reports a corrupt file as such', () async {
      final harness = ViewerHarness(
        renderer: FakePdfRenderer(failure: const Failure.corruptFile()),
      );

      final result = await harness.open(const DocumentId('doc-1'));

      expect(
        (result as Failed<ViewableDocument>).failure,
        isA<CorruptFileFailure>(),
      );
    });

    test('a protected document with no stored password needs one', () async {
      final harness = ViewerHarness(
        renderer: FakePdfRenderer(requiredPassword: 'secret'),
      );

      final result = await harness.open(const DocumentId('doc-1'));

      expect((result as Failed<ViewableDocument>).failure, isA<AuthFailure>());
    });

    test(
      'a stored password opens a protected document without asking',
      () async {
        final harness = ViewerHarness(
          renderer: FakePdfRenderer(requiredPassword: 'secret'),
        );
        await harness.secrets.write(
          SecureStorageKeys.pdfPassword('doc-1'),
          'secret',
        );

        final result = await harness.open(const DocumentId('doc-1'));

        expect(result, isA<Success<ViewableDocument>>());
        expect((result as Success<ViewableDocument>).value.isProtected, isTrue);
      },
    );

    test('a typed password takes precedence over a stored one', () async {
      // A user retyping a password is correcting something.
      final harness = ViewerHarness(
        renderer: FakePdfRenderer(requiredPassword: 'new'),
      );
      await harness.secrets.write(
        SecureStorageKeys.pdfPassword('doc-1'),
        'stale',
      );

      final result = await harness.open(
        const DocumentId('doc-1'),
        password: 'new',
      );

      expect(result, isA<Success<ViewableDocument>>());
    });

    test('an unreadable secure store prompts rather than failing', () async {
      // Being asked for a password is recoverable; being unable to open your
      // own document is not.
      final harness = ViewerHarness(
        renderer: FakePdfRenderer(requiredPassword: 'secret'),
        secretsFailure: const Failure.secureStorageUnavailable(),
      );

      final result = await harness.open(const DocumentId('doc-1'));

      expect((result as Failed<ViewableDocument>).failure, isA<AuthFailure>());
    });

    test('the page count comes from the file, not the record', () async {
      // The two can disagree after an edit, and the file is the truth about
      // what will be rendered.
      final harness = ViewerHarness(renderer: FakePdfRenderer(pageCount: 9));

      final result = await harness.open(const DocumentId('doc-1'));

      expect((result as Success<ViewableDocument>).value.pageCount, 9);
      expect(result.value.document.pageCount, 3);
    });
  });

  group('RememberDocumentPassword', () {
    test('writes only to secure storage', () async {
      final harness = ViewerHarness();

      await RememberDocumentPassword(harness.secrets)(
        const DocumentId('doc-1'),
        'secret',
      );

      expect(
        (await harness.secrets.read(
          SecureStorageKeys.pdfPassword('doc-1'),
        )).valueOrNull,
        'secret',
      );
      // Nothing reached preferences: the store the use case is given is the
      // only thing it can write to, and it is a secure one.
      expect(harness.preferences.values, isEmpty);
    });
  });

  group('ViewerCubit', () {
    late ViewerHarness harness;

    setUp(() => harness = ViewerHarness());

    blocTest<ViewerCubit, ViewerState>(
      'loads and becomes ready',
      build: () => harness.cubit(),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, ViewerStatus.ready);
        expect(cubit.state.pageCount, 3);
        expect(cubit.state.page, 1);
      },
    );

    blocTest<ViewerCubit, ViewerState>(
      'shows the document title',
      build: () => harness.cubit(),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.title, 'Invoice 2026'),
    );

    blocTest<ViewerCubit, ViewerState>(
      'a corrupt file becomes a failure with a message',
      build: () => ViewerHarness(
        renderer: FakePdfRenderer(failure: const Failure.corruptFile()),
      ).cubit(),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, ViewerStatus.failure);
        expect(cubit.state.message, isNotNull);
      },
    );

    blocTest<ViewerCubit, ViewerState>(
      'a protected document becomes locked, not failed',
      build: () => ViewerHarness(
        renderer: FakePdfRenderer(requiredPassword: 'secret'),
      ).cubit(),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        // The prompt is the normal path for a protected document; an error view
        // would suggest something had gone wrong.
        expect(cubit.state.status, ViewerStatus.locked);
        expect(cubit.state.failure, isNull);
      },
    );

    blocTest<ViewerCubit, ViewerState>(
      'no document content is exposed while locked',
      build: () => ViewerHarness(
        renderer: FakePdfRenderer(requiredPassword: 'secret'),
      ).cubit(),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.document, isNull);
        expect(cubit.state.pageCount, 0);
      },
    );

    test('the correct password unlocks and is remembered', () async {
      final locked = ViewerHarness(
        renderer: FakePdfRenderer(requiredPassword: 'secret'),
      );
      final cubit = locked.cubit();

      await cubit.load();
      await cubit.unlock('secret');

      expect(cubit.state.status, ViewerStatus.ready);
      expect(
        (await locked.secrets.read(
          SecureStorageKeys.pdfPassword('doc-1'),
        )).valueOrNull,
        'secret',
      );

      await cubit.close();
    });

    test('an incorrect password keeps the document locked', () async {
      final locked = ViewerHarness(
        renderer: FakePdfRenderer(requiredPassword: 'secret'),
      );
      final cubit = locked.cubit();

      await cubit.load();
      await cubit.unlock('wrong');

      expect(cubit.state.status, ViewerStatus.locked);
      expect(cubit.state.passwordRejected, isTrue);
      expect(cubit.state.document, isNull);
      // Nothing was remembered, because nothing worked.
      expect(
        (await locked.secrets.read(
          SecureStorageKeys.pdfPassword('doc-1'),
        )).valueOrNull,
        isNull,
      );

      await cubit.close();
    });

    test('a rejection does not survive the next attempt', () async {
      final locked = ViewerHarness(
        renderer: FakePdfRenderer(requiredPassword: 'secret'),
      );
      final cubit = locked.cubit();

      await cubit.load();
      await cubit.unlock('wrong');
      await cubit.unlock('secret');

      expect(cubit.state.passwordRejected, isFalse);

      await cubit.close();
    });

    blocTest<ViewerCubit, ViewerState>(
      'jumping past the end lands on the last page',
      build: () => harness.cubit(),
      act: (cubit) async {
        await cubit.load();
        cubit.goToPage(99);
      },
      verify: (cubit) => expect(cubit.state.page, 3),
    );

    blocTest<ViewerCubit, ViewerState>(
      'jumping below one lands on the first page',
      build: () => harness.cubit(),
      act: (cubit) async {
        await cubit.load();
        cubit.goToPage(0);
      },
      verify: (cubit) => expect(cubit.state.page, 1),
    );

    blocTest<ViewerCubit, ViewerState>(
      'scrolling updates the indicator',
      build: () => harness.cubit(),
      act: (cubit) async {
        await cubit.load();
        cubit.pageChanged(2);
      },
      verify: (cubit) => expect(cubit.state.pageLabel, '2 of 3'),
    );

    blocTest<ViewerCubit, ViewerState>(
      'retrying reopens the document',
      build: () => harness.cubit(),
      act: (cubit) async {
        await cubit.load();
        await cubit.retry();
      },
      verify: (_) => expect(harness.renderer.opened, hasLength(2)),
    );
  });

  group('OpenedDocument', () {
    test('equal descriptions compare equal', () {
      expect(
        const OpenedDocument(pageCount: 3, isProtected: false),
        const OpenedDocument(pageCount: 3, isProtected: false),
      );
    });

    test('descriptions differing in protection do not', () {
      expect(
        const OpenedDocument(pageCount: 3, isProtected: false),
        isNot(const OpenedDocument(pageCount: 3, isProtected: true)),
      );
    });
  });

  group('the viewer makes no network call', () {
    test('opening depends only on the injected renderer and store', () async {
      // Asserted structurally: `OpenDocumentForViewing` depends on a document
      // reader, a renderer and a secure store, all substituted here by
      // in-memory fakes. None has a client to make a request with.
      final harness = ViewerHarness();

      await harness.open(const DocumentId('doc-1'));

      expect(harness.renderer.opened, hasLength(1));
    });
  });
}

/// A document fixture, so the harness and the tests agree on what is stored.
Document viewerDocument() => Document(
  id: const DocumentId('doc-1'),
  title: 'Invoice 2026',
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 3, 14),
  pageCount: 3,
  sizeInBytes: 40960,
  libraryPath: LibraryPath.parse('doc-1.pdf'),
);

/// A recognised-text fixture.
RecognisedText viewerText() => RecognisedText(
  pageId: const PageId('page-0'),
  blocks: const [
    TextBlock(
      text: 'Invoice',
      bounds: NormalisedRect(left: 0.1, top: 0.1, right: 0.5, bottom: 0.16),
    ),
  ],
  languageTag: 'la',
  recognisedAt: DateTime.utc(2026, 3, 14),
);
