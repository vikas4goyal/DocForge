import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/public_storage/document_file_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remote document is ensured before its path is exposed', () async {
    final delegate = _RecordingResolver();
    final calls = <String>[];
    final progress = <double>[];
    final resolver = DownloadAwareDocumentFileResolver(
      delegate: delegate,
      ensureReadable: (document, {onProgress}) async {
        calls.add(document.relativePath);
        onProgress?.call(.5);
        return const Result<void>.success(null);
      },
      onProgress: (_, value) => progress.add(value),
    );

    final result = await resolver.pathFor(_document(remote: true));

    expect(result.valueOrNull, '/readable/A.pdf');
    expect(calls, ['A.pdf']);
    expect(progress, [.5]);
    expect(delegate.pathRequests, 1);
  });

  test('local Android-style document bypasses the cloud gate', () async {
    final delegate = _RecordingResolver();
    var ensureCalls = 0;
    final resolver = DownloadAwareDocumentFileResolver(
      delegate: delegate,
      ensureReadable: (_, {onProgress}) async {
        ensureCalls++;
        return const Result<void>.success(null);
      },
    );

    await resolver.pathFor(_document());

    expect(ensureCalls, 0);
    expect(delegate.pathRequests, 1);
  });

  test('download failure prevents byte access and remains retryable', () async {
    final delegate = _RecordingResolver();
    final resolver = DownloadAwareDocumentFileResolver(
      delegate: delegate,
      ensureReadable: (_, {onProgress}) async =>
          const Result<void>.failure(Failure.storage(debugDetail: 'offline')),
    );

    final result = await resolver.pathFor(_document(remote: true));

    expect(result.isFailure, isTrue);
    expect(delegate.pathRequests, 0);
  });
}

Document _document({bool remote = false}) => Document(
  id: const DocumentId('doc-1'),
  title: 'A',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  pageCount: 1,
  sizeInBytes: 1,
  libraryPath: LibraryPath.parse('A.pdf'),
  contentAvailability: remote
      ? DocumentContentAvailability.remote
      : DocumentContentAvailability.local,
);

class _RecordingResolver implements DocumentFileResolver {
  int pathRequests = 0;

  @override
  Future<Result<String>> pathFor(Document document) async {
    pathRequests++;
    return Result<String>.success('/readable/${document.fileName}');
  }

  @override
  Future<Result<void>> release(Document document) async =>
      const Result<void>.success(null);
}
