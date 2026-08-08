library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/isolates/cancellation.dart';
import 'package:doc_scanly/core/jobs/pdf_jobs.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/core/storage/public_storage/public_file_store.dart';
import 'package:doc_scanly/core/time/clock.dart';
import 'package:doc_scanly/features/pdf_editing/application/usecases/compression_workflow.dart';
import 'package:doc_scanly/features/pdf_editing/domain/compression_candidate.dart';
import 'package:doc_scanly/features/pdf_editing/domain/pdf_edit_rules.dart';
import 'package:doc_scanly/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporary;
  late Directory working;
  late _TestStore store;
  late _Candidates candidates;
  late CompressionCandidateCache cache;
  late _Writer writer;
  late InMemorySecureStore secrets;
  late Map<DocumentId, Document> records;
  late List<DocumentId> rolledBackCopies;
  late List<Document> restoredMetadata;
  late Failure? restoreFailure;

  const sourceId = DocumentId('source');

  setUp(() async {
    temporary = Directory.systemTemp.createTempSync('compression_workflow');
    working = Directory('${temporary.path}/working')..createSync();
    store = _TestStore(temporary);
    await store.initialise();
    candidates = _Candidates(working);
    cache = CompressionCandidateCache();
    writer = _Writer();
    secrets = InMemorySecureStore();
    records = <DocumentId, Document>{};
    rolledBackCopies = <DocumentId>[];
    restoredMetadata = <Document>[];
    restoreFailure = null;
  });

  tearDown(() {
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  });

  Document source({bool protected = false}) => Document(
    id: sourceId,
    title: 'Invoice',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026, 2),
    pageCount: 2,
    sizeInBytes: 100,
    libraryPath: LibraryPath.parse('Invoice.pdf'),
    isProtected: protected,
  );

  List<DocumentPage> pages() => const <DocumentPage>[
    DocumentPage(
      id: PageId('page-1'),
      documentId: sourceId,
      order: 0,
      imagePath: 'one.jpg',
    ),
    DocumentPage(
      id: PageId('page-2'),
      documentId: sourceId,
      order: 1,
      imagePath: 'two.jpg',
    ),
  ];

  CompressionWorkflowRequest request({
    CompressionDestination? destination = CompressionDestination.copy,
    List<int> qualities = const <int>[80, 80],
    bool protected = false,
  }) {
    final document = source(protected: protected);
    final plan = PageQualityPlan(
      documentQuality: PdfQualityPercent(value: qualities.first),
      pageOverrides: <String, PdfQualityPercent>{
        for (var index = 0; index < qualities.length; index++)
          if (qualities[index] != qualities.first)
            '$index': PdfQualityPercent(value: qualities[index]),
      },
    );
    return CompressionWorkflowRequest(
      source: document,
      sourcePages: pages(),
      draft: CompressionDraft(
        sourceDocumentId: sourceId.value,
        pageCount: 2,
        originalBytes: 100,
        qualityPlan: plan,
        destination: destination,
      ),
      candidateRequest: CompressionCandidateRequest(
        sourcePath: '${store.rootDirectory.path}/Invoice.pdf',
        pageCount: 2,
        qualityPlan: plan,
        fingerprint: PdfCandidateFingerprint(
          sourceIdentity: 'source-bytes',
          configurationIdentity: qualities.join(','),
          orderedPageQualities: qualities,
          isProtected: protected,
        ),
        password: protected ? 'secret' : null,
      ),
    );
  }

  Future<void> seedSource([String contents = 'original']) async {
    final seed = File('${temporary.path}/seed.pdf')
      ..writeAsStringSync(contents);
    await store.writeFile(LibraryPath.parse('Invoice.pdf'), seed.path);
    records[sourceId] = source();
  }

  SaveCompressedPdf save() => SaveCompressedPdf(
    repository: candidates,
    cache: cache,
    documents: writer,
    rollbackCopy: (id) async {
      rolledBackCopies.add(id);
      records.remove(id);
      return const Result<void>.success(null);
    },
    restoreMetadata: (document) async {
      restoredMetadata.add(document);
      records[document.id] = document;
      final failure = restoreFailure;
      if (failure != null) return Result<void>.failure(failure);
      return const Result<void>.success(null);
    },
    store: store,
    secrets: secrets,
    clock: FixedClock(DateTime.utc(2026, 8, 8, 12)),
    ids: SequentialIdGenerator(prefix: 'compression'),
    workingDirectory: working,
  );

  test('calculation cancellation during debounce builds nothing', () async {
    final token = CancellationToken();
    final pending = CalculateCompressedSize(
      candidates,
      cache,
      debounce: const Duration(seconds: 1),
    )(request(), token: token, onProgress: (_) {});

    token.cancel();

    expect((await pending).failureOrNull, const Failure.cancelled());
    expect(candidates.builds, 0);
  });

  test('preview reuses a verified exact calculation', () async {
    final value = request(qualities: const <int>[80, 100]);
    await CalculateCompressedSize(candidates, cache, debounce: Duration.zero)(
      value,
      token: CancellationToken(),
      onProgress: (_) {},
    );

    final preview = await PrepareCompressionPreview(candidates, cache)(
      value,
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(preview, isA<Success<PdfCandidate>>());
    expect(candidates.builds, 1);
    expect(candidates.verifications, 1);
  });

  test('request validates source agreement and complete page rows', () {
    final valid = request();

    expect(
      () => CompressionWorkflowRequest(
        source: source().copyWith(sizeInBytes: 101),
        sourcePages: pages(),
        draft: valid.draft,
        candidateRequest: valid.candidateRequest,
      ),
      throwsArgumentError,
    );
    expect(
      () => CompressionWorkflowRequest(
        source: source(),
        sourcePages: <DocumentPage>[pages().first],
        draft: valid.draft,
        candidateRequest: valid.candidateRequest,
      ),
      throwsArgumentError,
    );
  });

  test('candidate cache exposes and disposes its retained candidate', () async {
    await CalculateCompressedSize(candidates, cache, debounce: Duration.zero)(
      request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(cache.candidate, isNotNull);
    await cache.dispose(candidates);
    expect(cache.candidate, isNull);
    expect(candidates.discards, 1);
  });

  test('stale cached candidate is discarded and rebuilt', () async {
    final value = request();
    await CalculateCompressedSize(candidates, cache, debounce: Duration.zero)(
      value,
      token: CancellationToken(),
      onProgress: (_) {},
    );
    candidates.verifyFailure = const Failure.pdf();

    final result = await PrepareCompressionPreview(candidates, cache)(
      value,
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result, isA<Success<PdfCandidate>>());
    expect(candidates.builds, 2);
    expect(candidates.discards, 1);
  });

  test('candidate build failure is returned without promotion', () async {
    candidates.buildFailure = const Failure.pdf();

    final result = await save()(
      request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.pdf());
    expect(candidates.promotions, 0);
  });

  test('destination must be selected before candidate work', () async {
    final result = await save()(
      request(destination: null),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(candidates.builds, 0);
  });

  test('cancellation after candidate creation discards it', () async {
    final token = CancellationToken();
    candidates.onBuild = token.cancel;

    final result = await save()(request(), token: token, onProgress: (_) {});

    expect(result.failureOrNull, const Failure.cancelled());
    expect(candidates.discards, 1);
    expect(candidates.promotions, 0);
  });

  test('Save starts immediately while calculation is debounced', () async {
    await seedSource();
    final value = request();
    final calculationToken = CancellationToken();
    final pending = CalculateCompressedSize(
      candidates,
      cache,
      debounce: const Duration(seconds: 1),
    )(value, token: calculationToken, onProgress: (_) {});

    final result = await save()(
      value,
      token: CancellationToken(),
      onProgress: (_) {},
    );
    calculationToken.cancel();

    expect(result, isA<Success<CompressionCommitResult>>());
    expect(candidates.builds, 1);
    expect((await pending).failureOrNull, const Failure.cancelled());
  });

  test('copy uses a collision-safe name and preserves source bytes', () async {
    await seedSource();
    final collision = File('${temporary.path}/collision.pdf')
      ..writeAsStringSync('existing');
    await store.writeFile(
      LibraryPath.parse('Invoice (compressed).pdf'),
      collision.path,
    );

    final result = await save()(
      request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.valueOrNull?.destination, CompressionDestination.copy);
    expect(
      File('${store.rootDirectory.path}/Invoice.pdf').readAsStringSync(),
      'original',
    );
    expect(
      File(
        '${store.rootDirectory.path}/Invoice (compressed) (2).pdf',
      ).existsSync(),
      isTrue,
    );
    expect(writer.saved.single.pages.map((page) => page.documentId).toSet(), {
      writer.saved.single.document.id,
    });
  });

  test('copy returns library listing failure', () async {
    await seedSource();
    store.listFailure = const Failure.storage();

    final result = await save()(
      request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.storage());
  });

  test('copy returns publish failure without creating a record', () async {
    await seedSource();
    store.failWriteAt = store.writeCalls + 1;

    final result = await save()(
      request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.storageFull());
    expect(writer.saved, isEmpty);
  });

  test('copy cancellation after publish removes its bytes', () async {
    await seedSource();
    final token = CancellationToken();
    store.onWrite = token.cancel;

    final result = await save()(request(), token: token, onProgress: (_) {});

    expect(result.failureOrNull, const Failure.cancelled());
    expect(writer.saved, isEmpty);
    expect(
      File('${store.rootDirectory.path}/Invoice (compressed).pdf').existsSync(),
      isFalse,
    );
  });

  test('copy record failure removes published bytes', () async {
    await seedSource();
    writer.saveFailure = const Failure.storage();

    final result = await save()(
      request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.storage());
    expect(
      File('${store.rootDirectory.path}/Invoice (compressed).pdf').existsSync(),
      isFalse,
    );
  });

  test(
    'protected copy stores its credential only after record commit',
    () async {
      await seedSource();

      final result = await save()(
        request(protected: true),
        token: CancellationToken(),
        onProgress: (_) {},
      );

      expect(result, isA<Success<CompressionCommitResult>>());
      expect(secrets.values.values, contains('secret'));
    },
  );

  test('secure storage failure rolls back copy record and bytes', () async {
    await seedSource();
    secrets.failNextOperation = true;

    final result = await save()(
      request(protected: true),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.secureStorageUnavailable());
    expect(rolledBackCopies, hasLength(1));
    expect(
      File('${store.rootDirectory.path}/Invoice (compressed).pdf').existsSync(),
      isFalse,
    );
  });

  test('overwrite verifies bytes and refreshes source metadata', () async {
    await seedSource();

    final result = await save()(
      request(destination: CompressionDestination.overwrite),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.valueOrNull?.documentId, sourceId.value);
    expect(File('${store.rootDirectory.path}/Invoice.pdf').lengthSync(), 60);
    expect(writer.updated.single.id, sourceId);
    expect(writer.updated.single.sizeInBytes, 60);
  });

  test('overwrite returns initial materialisation failure', () async {
    await seedSource();
    store.failMaterialiseAt = store.materialiseCalls + 1;

    final result = await save()(
      request(destination: CompressionDestination.overwrite),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.notFound());
    expect(writer.updated, isEmpty);
  });

  test('overwrite returns publish failure and preserves source', () async {
    await seedSource();
    store.failWriteAt = store.writeCalls + 1;

    final result = await save()(
      request(destination: CompressionDestination.overwrite),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.storageFull());
    expect(
      File('${store.rootDirectory.path}/Invoice.pdf').readAsStringSync(),
      'original',
    );
  });

  test('overwrite cancellation after publish rolls back bytes', () async {
    await seedSource();
    final token = CancellationToken();
    store.onWrite = token.cancel;

    final result = await save()(
      request(destination: CompressionDestination.overwrite),
      token: token,
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.cancelled());
    expect(
      File('${store.rootDirectory.path}/Invoice.pdf').readAsStringSync(),
      'original',
    );
  });

  test('overwrite read-back failure rolls back bytes', () async {
    await seedSource();
    store.failMaterialiseAt = store.materialiseCalls + 2;

    final result = await save()(
      request(destination: CompressionDestination.overwrite),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.notFound());
    expect(
      File('${store.rootDirectory.path}/Invoice.pdf').readAsStringSync(),
      'original',
    );
  });

  test('overwrite verification failure rolls back bytes', () async {
    await seedSource();
    candidates.verifyFailure = const Failure.pdf();

    final result = await save()(
      request(destination: CompressionDestination.overwrite),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.pdf());
    expect(
      File('${store.rootDirectory.path}/Invoice.pdf').readAsStringSync(),
      'original',
    );
  });

  test(
    'metadata failure restores overwrite bytes and original record',
    () async {
      await seedSource();
      writer.updateFailure = const Failure.storage();

      final result = await save()(
        request(destination: CompressionDestination.overwrite),
        token: CancellationToken(),
        onProgress: (_) {},
      );

      expect(result.failureOrNull, const Failure.storage());
      expect(
        File('${store.rootDirectory.path}/Invoice.pdf').readAsStringSync(),
        'original',
      );
      expect(restoredMetadata, <Document>[source()]);
    },
  );

  test('rollback reports byte restoration failure first', () async {
    await seedSource();
    writer.updateFailure = const Failure.pdf();
    store.failWriteAt = store.writeCalls + 2;

    final result = await save()(
      request(destination: CompressionDestination.overwrite),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.storageFull());
    expect(restoredMetadata, <Document>[source()]);
  });

  test('rollback reports metadata restoration failure', () async {
    await seedSource();
    writer.updateFailure = const Failure.pdf();
    restoreFailure = const Failure.unexpected();

    final result = await save()(
      request(destination: CompressionDestination.overwrite),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.unexpected());
  });

  test('filesystem backup exception is mapped to storage failure', () async {
    await seedSource();
    store.directoryMaterialiseAt = store.materialiseCalls + 1;

    final result = await save()(
      request(destination: CompressionDestination.overwrite),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, isA<StorageFailure>());
  });

  test('no-benefit candidate requires review and can then continue', () async {
    await seedSource();
    candidates.resultBytes = 120;
    final operation = save();

    final blocked = await operation(
      request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );
    final continued = await operation(
      request(),
      token: CancellationToken(),
      onProgress: (_) {},
      allowNoBenefit: true,
    );

    expect(blocked.failureOrNull, isA<ValidationFailure>());
    expect(continued.valueOrNull?.hasNoBenefit, isTrue);
    expect(candidates.builds, 1);
  });

  test(
    'cancellation during promotion preserves source and permits retry',
    () async {
      await seedSource();
      final operation = save();
      final token = CancellationToken();
      candidates.onPromote = token.cancel;

      final cancelled = await operation(
        request(destination: CompressionDestination.overwrite),
        token: token,
        onProgress: (_) {},
      );
      candidates.onPromote = null;
      final retried = await operation(
        request(destination: CompressionDestination.overwrite),
        token: CancellationToken(),
        onProgress: (_) {},
      );

      expect(cancelled.failureOrNull, const Failure.cancelled());
      expect(retried, isA<Success<CompressionCommitResult>>());
      expect(candidates.builds, 2);
    },
  );

  test('promotion storage failure preserves source', () async {
    await seedSource();
    candidates.promoteFailure = const Failure.storageFull();

    final result = await save()(
      request(destination: CompressionDestination.overwrite),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(result.failureOrNull, const Failure.storageFull());
    expect(
      File('${store.rootDirectory.path}/Invoice.pdf').readAsStringSync(),
      'original',
    );
    expect(writer.updated, isEmpty);
  });

  test('successful commit is one-shot', () async {
    await seedSource();
    final operation = save();

    final first = await operation(
      request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );
    final second = await operation(
      request(),
      token: CancellationToken(),
      onProgress: (_) {},
    );

    expect(second.valueOrNull, first.valueOrNull);
    expect(candidates.builds, 1);
    expect(writer.saved, hasLength(1));
  });
}

class _SavedDocument {
  const _SavedDocument(this.document, this.pages);

  final Document document;
  final List<DocumentPage> pages;
}

class _Writer implements DocumentWriter {
  final List<_SavedDocument> saved = <_SavedDocument>[];
  final List<Document> updated = <Document>[];
  Failure? saveFailure;
  Failure? updateFailure;

  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async {
    final failure = saveFailure;
    if (failure != null) return Result<Document>.failure(failure);
    saved.add(_SavedDocument(document, pages));
    return Result<Document>.success(document);
  }

  @override
  Future<Result<Document>> updateMetadata(Document document) async {
    final failure = updateFailure;
    if (failure != null) return Result<Document>.failure(failure);
    updated.add(document);
    return Result<Document>.success(document);
  }
}

class _Candidates implements CompressionCandidateRepository {
  _Candidates(this.workingDirectory);

  final Directory workingDirectory;
  int resultBytes = 60;
  int builds = 0;
  int verifications = 0;
  int promotions = 0;
  int discards = 0;
  PdfCandidate? owned;
  Failure? promoteFailure;
  Failure? buildFailure;
  Failure? verifyFailure;
  void Function()? onPromote;
  void Function()? onBuild;

  @override
  Future<Result<PdfCandidate>> buildCandidate(
    CompressionCandidateRequest request, {
    required CancellationToken token,
    required CompressionCandidateProgress onProgress,
  }) async {
    if (token.isCancelled) {
      return const Result<PdfCandidate>.failure(Failure.cancelled());
    }
    builds++;
    final failure = buildFailure;
    if (failure != null) return Result<PdfCandidate>.failure(failure);
    final file = File('${workingDirectory.path}/candidate-$builds.pdf')
      ..writeAsBytesSync(List<int>.filled(resultBytes, builds));
    onProgress(JobProgress(percent: 100));
    onBuild?.call();
    owned = PdfCandidate(
      handle: file.path,
      exactBytes: resultBytes,
      pageCount: request.pageCount,
      fingerprint: request.fingerprint,
    );
    return Result<PdfCandidate>.success(owned!);
  }

  @override
  Future<void> discard(PdfCandidate candidate) async {
    discards++;
    if (File(candidate.handle).existsSync()) {
      File(candidate.handle).deleteSync();
    }
    if (owned == candidate) owned = null;
  }

  @override
  Future<Result<EditedPdf>> promote(
    PdfCandidate candidate, {
    required String destinationPath,
    required CancellationToken token,
  }) async {
    promotions++;
    final failure = promoteFailure;
    if (failure != null) return Result<EditedPdf>.failure(failure);
    File(candidate.handle).copySync(destinationPath);
    File(candidate.handle).deleteSync();
    owned = null;
    onPromote?.call();
    return Result<EditedPdf>.success(
      EditedPdf(
        filePath: destinationPath,
        pageCount: candidate.pageCount,
        sizeInBytes: candidate.exactBytes,
      ),
    );
  }

  @override
  Future<Result<PdfCandidate>> verifyCandidate(
    PdfCandidate candidate, {
    String? password,
  }) async {
    verifications++;
    final failure = verifyFailure;
    if (failure != null) {
      verifyFailure = null;
      return Result<PdfCandidate>.failure(failure);
    }
    final file = File(candidate.handle);
    return file.existsSync() && file.lengthSync() == candidate.exactBytes
        ? Result<PdfCandidate>.success(candidate)
        : const Result<PdfCandidate>.failure(Failure.pdf());
  }
}

class _TestStore extends FilesystemPublicFileStore {
  _TestStore(super.containerDirectory);

  Failure? listFailure;
  int writeCalls = 0;
  int materialiseCalls = 0;
  int? failWriteAt;
  int? failMaterialiseAt;
  int? directoryMaterialiseAt;
  void Function()? onWrite;

  @override
  Future<Result<List<PublicEntry>>> list(List<String> folders) async {
    final failure = listFailure;
    if (failure != null) return Result<List<PublicEntry>>.failure(failure);
    return super.list(folders);
  }

  @override
  Future<Result<String>> writeFile(LibraryPath path, String sourcePath) async {
    writeCalls++;
    if (writeCalls == failWriteAt) {
      return const Result<String>.failure(Failure.storageFull());
    }
    final result = await super.writeFile(path, sourcePath);
    if (result case Success()) onWrite?.call();
    return result;
  }

  @override
  Future<Result<String>> materialise(LibraryPath path) async {
    materialiseCalls++;
    if (materialiseCalls == failMaterialiseAt) {
      return const Result<String>.failure(Failure.notFound());
    }
    if (materialiseCalls == directoryMaterialiseAt) {
      return Result<String>.success(rootDirectory.path);
    }
    return super.materialise(path);
  }
}
