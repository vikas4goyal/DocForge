import 'package:bloc_test/bloc_test.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/document_creation/domain/page_draft.dart';
import 'package:doc_forge/features/document_creation/presentation/cubit/save_document_cubit.dart';
import 'package:doc_forge/features/document_creation/presentation/cubit/save_document_state.dart';
import 'package:flutter_test/flutter_test.dart';

PageDraft page(String id) =>
    PageDraft(id: PageId(id), originalImagePath: '/staging/$id.jpg');

Document saved(String title) => Document(
  id: const DocumentId('doc-1'),
  title: title,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  pageCount: 1,
  sizeInBytes: 1024,
  libraryPath: LibraryPath.parse('$title.pdf'),
);

void main() {
  late List<({String title, List<String> folders, String? password})> requests;
  late Failure? saveFailure;

  setUp(() {
    requests = [];
    saveFailure = null;
  });

  SaveDocumentCubit build({
    String suggestedName = 'Scan 2026-07-28',
    List<PageDraft> pages = const [],
    List<String> folders = const [],
  }) => SaveDocumentCubit(
    pages: pages.isEmpty ? [page('p0')] : pages,
    folders: folders,
    suggestedName: suggestedName,
    save:
        (pages, {required title, required folders, password, folderId}) async {
          requests.add((title: title, folders: folders, password: password));
          final configured = saveFailure;
          return configured == null
              ? Result<Document>.success(saved(title))
              : Result<Document>.failure(configured);
        },
  );

  group('initial state', () {
    test('opens with the suggested name prefilled', () {
      expect(build().state.name, 'Scan 2026-07-28');
    });

    test('can be saved straight away', () {
      expect(build().state.canSave, isTrue);
    });

    test('password protection is off by default', () {
      expect(build().state.passwordEnabled, isFalse);
    });

    test('an empty session cannot be saved', () {
      final cubit = SaveDocumentCubit(
        pages: const [],
        folders: const [],
        suggestedName: 'Invoice',
        save:
            (
              pages, {
              required title,
              required folders,
              password,
              folderId,
            }) async => Result<Document>.success(saved(title)),
      );

      expect(cubit.state.canSave, isFalse);
    });
  });

  group('naming', () {
    blocTest<SaveDocumentCubit, SaveDocumentState>(
      'an empty name cannot be saved',
      build: build,
      act: (cubit) => cubit.nameChanged('   '),
      verify: (cubit) {
        expect(cubit.state.canSave, isFalse);
        expect(cubit.state.nameProblem, ValidationIssue.emptyName);
      },
    );

    blocTest<SaveDocumentCubit, SaveDocumentState>(
      'a name that is illegal on disk cannot be saved',
      build: build,
      act: (cubit) => cubit.nameChanged('Q1/Q2'),
      verify: (cubit) {
        // The name becomes a file in a folder the user can also reach from
        // their file browser.
        expect(cubit.state.canSave, isFalse);
        expect(cubit.state.nameProblem, ValidationIssue.illegalName);
      },
    );

    blocTest<SaveDocumentCubit, SaveDocumentState>(
      'the entered name is what gets saved',
      build: build,
      act: (cubit) async {
        cubit.nameChanged('  Invoice 2026  ');
        await cubit.submit();
      },
      verify: (cubit) => expect(requests.single.title, 'Invoice 2026'),
    );
  });

  group('password protection', () {
    blocTest<SaveDocumentCubit, SaveDocumentState>(
      'a mismatch blocks saving',
      build: build,
      act: (cubit) => cubit
        ..passwordEnabledChanged(enabled: true)
        ..passwordChanged('hunter2')
        ..confirmationChanged('hunter3'),
      verify: (cubit) {
        expect(cubit.state.canSave, isFalse);
        expect(cubit.state.passwordProblem, ValidationIssue.passwordMismatch);
      },
    );

    blocTest<SaveDocumentCubit, SaveDocumentState>(
      'an empty password blocks saving',
      build: build,
      act: (cubit) => cubit.passwordEnabledChanged(enabled: true),
      verify: (cubit) => expect(cubit.state.canSave, isFalse),
    );

    blocTest<SaveDocumentCubit, SaveDocumentState>(
      'a matching pair is applied',
      build: build,
      act: (cubit) async {
        cubit
          ..passwordEnabledChanged(enabled: true)
          ..passwordChanged('hunter2')
          ..confirmationChanged('hunter2');
        await cubit.submit();
      },
      verify: (cubit) => expect(requests.single.password, 'hunter2'),
    );

    blocTest<SaveDocumentCubit, SaveDocumentState>(
      'no password is applied when protection is off',
      build: build,
      act: (cubit) async {
        cubit
          ..passwordEnabledChanged(enabled: true)
          ..passwordChanged('hunter2')
          ..confirmationChanged('hunter2')
          ..passwordEnabledChanged(enabled: false);
        await cubit.submit();
      },
      verify: (cubit) {
        // A password the user decided against must not be applied because they
        // toggled the switch twice.
        expect(requests.single.password, isNull);
        expect(cubit.state.password, isEmpty);
      },
    );
  });

  group('saving', () {
    blocTest<SaveDocumentCubit, SaveDocumentState>(
      'writes into the open folder',
      build: () => build(folders: ['Invoices', '2026']),
      act: (cubit) => cubit.submit(),
      verify: (cubit) => expect(requests.single.folders, ['Invoices', '2026']),
    );

    test('returns the saved record', () async {
      final cubit = build();

      final document = await cubit.submit();

      expect(document, isNotNull);
      expect(document!.title, 'Scan 2026-07-28');
    });

    blocTest<SaveDocumentCubit, SaveDocumentState>(
      'a failure keeps the dialog open with the pages intact',
      build: build,
      act: (cubit) async {
        saveFailure = const Failure.storageFull();
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, SaveStatus.failure);
        expect(cubit.state.failure, isA<StorageFullFailure>());
        // Nothing was written, so the user can change the name and try again.
        expect(cubit.state.canSave, isTrue);
      },
    );

    test('a failure returns null rather than a record', () async {
      saveFailure = const Failure.storageFull();

      expect(await build().submit(), isNull);
    });

    blocTest<SaveDocumentCubit, SaveDocumentState>(
      'a retry after a failure clears the error',
      build: build,
      act: (cubit) async {
        saveFailure = const Failure.storageFull();
        await cubit.submit();
        saveFailure = null;
        await cubit.submit();
      },
      verify: (cubit) => expect(cubit.state.failure, isNull),
    );

    test('an invalid form does not reach the write', () async {
      final cubit = build()..nameChanged('');

      await cubit.submit();

      expect(requests, isEmpty);
    });
  });
}
