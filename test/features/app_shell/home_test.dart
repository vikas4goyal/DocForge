import 'package:bloc_test/bloc_test.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/core/previews/fixtures/fixtures.dart';
import 'package:doc_forge/features/app_shell/application/usecases/load_home_data.dart';
import 'package:doc_forge/features/app_shell/presentation/cubit/home_cubit.dart';
import 'package:doc_forge/features/app_shell/presentation/cubit/home_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const _storageFailure = Failure.storage();
final _storageMessage = _storageFailure.presentation.message;

void main() {
  late FakeDocumentReader documents;
  late FakeFolderReader folders;
  late FakeStorageSummaryReader storage;

  setUp(() {
    documents = FakeDocumentReader();
    folders = FakeFolderReader();
    storage = FakeStorageSummaryReader();
  });

  LoadHomeData buildUseCase() => LoadHomeData(documents, folders, storage);
  HomeCubit buildCubit() => HomeCubit(buildUseCase());

  group('LoadHomeData', () {
    test('orders recent documents by modified date descending', () async {
      documents.documents.addAll(sampleDocuments(4)..shuffle());

      final result = await buildUseCase()();

      final recents = result.valueOrNull!.recentDocuments;
      for (var i = 1; i < recents.length; i++) {
        expect(
          recents[i - 1].updatedAt.isAfter(recents[i].updatedAt),
          isTrue,
          reason: 'recents are not newest-first at index $i',
        );
      }
    });

    test('excludes archived documents from recents', () async {
      documents.documents.addAll([sampleDocument, archivedDocument]);

      final result = await buildUseCase()();

      expect(result.valueOrNull!.recentDocuments.map((d) => d.id), [
        sampleDocument.id,
      ]);
    });

    test('asks for only a handful of recents, not the whole library', () async {
      documents.documents.addAll(sampleDocuments(50));

      final result = await buildUseCase()();

      expect(
        result.valueOrNull!.recentDocuments,
        hasLength(LoadHomeData.recentLimit),
      );
      // Home must not pay for a full library read on every launch.
      expect(documents.queries.first.limit, LoadHomeData.recentLimit);
    });

    test('counts favourites excluding archived ones', () async {
      documents.documents.addAll([
        sampleDocument,
        favouriteDocument,
        favouriteDocument.copyWith(
          id: const DocumentId('doc-fav-archived'),
          isArchived: true,
        ),
      ]);

      final result = await buildUseCase()();

      expect(result.valueOrNull!.favouriteCount, 1);
    });

    test('counts archived documents', () async {
      documents.documents.addAll([sampleDocument, archivedDocument]);

      final result = await buildUseCase()();

      expect(result.valueOrNull!.archivedCount, 1);
    });

    test('reports the storage summary', () async {
      storage.value = const StorageSummary(
        totalBytes: 5 * 1024 * 1024,
        documentCount: 7,
      );

      final result = await buildUseCase()();

      expect(result.valueOrNull!.storage.totalBytes, 5 * 1024 * 1024);
      expect(result.valueOrNull!.storage.documentCount, 7);
    });

    test('a failed document query fails the whole load', () async {
      documents.failure = _storageFailure;

      final result = await buildUseCase()();

      // Recents are the one section Home cannot be assembled without.
      expect(result.isFailure, isTrue);
    });

    test(
      'a failed folder read degrades rather than losing the screen',
      () async {
        documents.documents.add(sampleDocument);
        folders.failure = _storageFailure;

        final result = await buildUseCase()();

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull!.folders, isEmpty);
        // Everything else the user came for is still there.
        expect(result.valueOrNull!.recentDocuments, hasLength(1));
      },
    );

    test('a failed storage read degrades to a zero summary', () async {
      documents.documents.add(sampleDocument);
      storage.failure = _storageFailure;

      final result = await buildUseCase()();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.storage, StorageSummary.empty);
    });

    test('a library of only archived documents is not empty', () async {
      documents.documents.add(archivedDocument);
      storage.value = const StorageSummary(totalBytes: 1024, documentCount: 1);

      final result = await buildUseCase()();

      // Telling this user to scan their first document would be wrong: they
      // have one, they archived it.
      expect(result.valueOrNull!.isEmpty, isFalse);
      expect(result.valueOrNull!.recentDocuments, isEmpty);
    });

    test('a library with nothing in it is empty', () async {
      final result = await buildUseCase()();

      expect(result.valueOrNull!.isEmpty, isTrue);
    });

    test('completes with no network connection', () async {
      documents.documents.add(sampleDocument);

      // Nothing here can reach a network: every collaborator is an in-memory
      // fake, and the real implementations are local storage only.
      final result = await buildUseCase()();

      expect(result.isSuccess, isTrue);
    });
  });

  group('HomeCubit', () {
    test('starts in the initial status', () {
      expect(buildCubit().state.status, HomeStatus.initial);
    });

    blocTest<HomeCubit, HomeState>(
      'loads through loading into ready',
      setUp: () {
        documents.documents.add(sampleDocument);
        storage.value = const StorageSummary(
          totalBytes: 1024,
          documentCount: 1,
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<HomeState>().having((s) => s.status, 'status', HomeStatus.loading),
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.ready)
            .having((s) => s.recentDocuments, 'recents', hasLength(1))
            .having((s) => s.showsRecentDocuments, 'showsRecents', isTrue),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'reports empty when the library holds nothing',
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<HomeState>().having((s) => s.status, 'status', HomeStatus.loading),
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.empty)
            // The spec requires the recents list not to render at all here.
            .having((s) => s.showsRecentDocuments, 'showsRecents', isFalse),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'surfaces a load failure with a message',
      setUp: () => documents.failure = _storageFailure,
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<HomeState>().having((s) => s.status, 'status', HomeStatus.loading),
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.failure)
            .having((s) => s.message, 'message', _storageMessage),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'a retry after a failure replaces the error with content',
      setUp: () {
        documents.failure = _storageFailure;
        documents.documents.add(sampleDocument);
        storage.value = const StorageSummary(
          totalBytes: 1024,
          documentCount: 1,
        );
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        documents.failure = null;
        await cubit.load();
      },
      skip: 2,
      expect: () => [
        isA<HomeState>().having((s) => s.status, 'status', HomeStatus.loading),
        isA<HomeState>()
            .having((s) => s.status, 'status', HomeStatus.ready)
            .having((s) => s.failure, 'failure', isNull),
      ],
    );

    test('a document saved elsewhere appears on the next load', () async {
      storage.value = const StorageSummary(totalBytes: 1, documentCount: 1);
      final cubit = buildCubit();
      await cubit.load();
      expect(cubit.state.recentDocuments, isEmpty);

      documents.documents.add(sampleDocument);
      await cubit.load();

      // No app restart, no cache to invalidate: Home reloads when it is shown.
      expect(cubit.state.recentDocuments.first.id, sampleDocument.id);
      await cubit.close();
    });

    test('the storage summary shrinks after a document is removed', () async {
      documents.documents.add(sampleDocument);
      storage.value = const StorageSummary(totalBytes: 4096, documentCount: 1);
      final cubit = buildCubit();
      await cubit.load();
      expect(cubit.state.storage.totalBytes, 4096);

      documents.documents.clear();
      storage.value = StorageSummary.empty;
      await cubit.load();

      expect(cubit.state.storage.totalBytes, 0);
      await cubit.close();
    });
  });
}
