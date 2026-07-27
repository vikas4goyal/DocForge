/// Proves that preparing content to share makes no network request.
///
/// The privacy promise is that content leaves the device only through the share
/// sheet the user opened — never over the wire on the way there. Two
/// independent checks, because either alone can be defeated: a runtime check
/// catches a request made through `dart:io`, and a source check catches a
/// networking dependency added to the feature that a test happens not to
/// exercise.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/library_path.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/previews/fakes/fake_document_file_resolver.dart';
import 'package:doc_forge/features/document_sharing/application/usecases/sharing_usecases.dart';
import 'package:doc_forge/features/document_sharing/infrastructure/repositories/fake_share_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails the test the moment anything opens an HTTP client.
class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      fail('the sharing feature opened an HTTP client');
}

class _Reader implements DocumentReader {
  _Reader(this.document, this.pages);

  final Document document;
  final List<DocumentPage> pages;

  @override
  Future<Result<Document>> findById(DocumentId id) async =>
      Result<Document>.success(document);

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
      Result<List<DocumentPage>>.success(pages);
}

/// Resolves every test document to a fixed path.
///
/// These tests drive the sheet and the Cubit, not the bytes: what matters is
/// that print and export are reached, which a resolver that cannot fail keeps
/// from being obscured by storage setup.
const testFiles = FakeDocumentFileResolver();

void main() {
  late Directory temporary;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('share_offline');
    HttpOverrides.global = _NoNetwork();
  });

  tearDown(() {
    HttpOverrides.global = null;
    if (temporary.existsSync()) temporary.deleteSync(recursive: true);
  });

  test('preparing a PDF and page images opens no network connection', () async {
    const id = DocumentId('a');
    File('${temporary.path}/a.pdf').writeAsStringSync('%PDF');

    final document = Document(
      id: id,
      title: 'Invoice',
      createdAt: DateTime.utc(2026, 3, 14),
      updatedAt: DateTime.utc(2026, 3, 14),
      pageCount: 1,
      sizeInBytes: 4,
      libraryPath: LibraryPath.parse('a.pdf'),
    );

    final reader = _Reader(document, [
      DocumentPage(
        id: const PageId('p0'),
        documentId: id,
        order: 0,
        imagePath: '${temporary.path}/p0.jpg',
      ),
    ]);
    final share = FakeShareRepository();

    await ShareDocumentPdf(reader, share, testFiles)(id);

    await SharePageImages(
      reader,
      share,
      const InlineBackgroundWorker(),
      () {
        return temporary;
      },
      (request) {
        File(request.destinationPath).writeAsStringSync('image');
        return request.destinationPath;
      },
    )(id).toList();

    // Reached only if no HTTP client was ever created, because creating one
    // fails the test from inside the override above.
    expect(share.shared, hasLength(2));
  });

  test('the feature declares no networking dependency', () {
    // Guards the case a runtime test cannot: a request on a path this suite
    // happens not to walk. Dio is the project's only HTTP client, and
    // `HttpClient` is the only way to reach the network without it.
    final offenders = <String>[];

    for (final entity in Directory(
      'lib/features/document_sharing',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final source = entity.readAsStringSync();
      if (source.contains('package:dio') ||
          source.contains('HttpClient') ||
          source.contains('package:http/')) {
        offenders.add(entity.path);
      }
    }

    expect(offenders, isEmpty);
  });
}
