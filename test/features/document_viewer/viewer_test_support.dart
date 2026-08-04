/// Shared fakes for the viewer tests.
library;

import 'package:doc_scanly/core/contracts/contracts.dart';
import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/recognised_text.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/fakes/fake_document_file_resolver.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/features/document_viewer/application/usecases/viewer_usecases.dart';
import 'package:doc_scanly/features/document_viewer/infrastructure/repositories/pdfrx_renderer.dart';
import 'package:doc_scanly/features/document_viewer/presentation/cubit/viewer_cubit.dart';

/// The document every viewer test opens.
Document harnessDocument() => Document(
  id: const DocumentId('doc-1'),
  title: 'Invoice 2026',
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 3, 14),
  pageCount: 3,
  sizeInBytes: 40960,
  libraryPath: LibraryPath.parse('doc-1.pdf'),
);

/// A secure store held in memory.
class InMemorySecureStore implements SecureStore {
  /// Creates a store whose operations fail with [failure] when set.
  InMemorySecureStore({this.failure});

  /// When set, every read fails with this.
  final Failure? failure;

  /// What has been written.
  final values = <String, String>{};

  @override
  Future<Result<String?>> read(String key) async {
    final configured = failure;
    if (configured != null) return Result<String?>.failure(configured);
    return Result<String?>.success(values[key]);
  }

  @override
  Future<Result<void>> write(String key, String value) async {
    values[key] = value;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    values.remove(key);
    return const Result<void>.success(null);
  }
}

/// A preference store held in memory.
///
/// Exists so a test can assert that *nothing* reached it — the password rule is
/// "secure storage only", and the only way to check that is to have somewhere
/// else to look.
class InMemoryPreferences implements PreferenceStore {
  /// What has been written.
  final values = <String, Object?>{};

  @override
  Future<Result<bool?>> readBool(String key) async =>
      Result<bool?>.success(values[key] as bool?);

  @override
  Future<Result<String?>> readString(String key) async =>
      Result<String?>.success(values[key] as String?);

  @override
  Future<Result<int?>> readInt(String key) async =>
      Result<int?>.success(values[key] as int?);

  @override
  // ignore: avoid_positional_boolean_parameters
  Future<Result<void>> writeBool(String key, bool value) async {
    values[key] = value;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> writeString(String key, String value) async {
    values[key] = value;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> writeInt(String key, int value) async {
    values[key] = value;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> remove(String key) async {
    values.remove(key);
    return const Result<void>.success(null);
  }
}

/// A document reader returning one fixed document.
class StubViewerDocuments implements DocumentReader {
  /// Creates a reader that finds the fixture unless [found] is false.
  StubViewerDocuments({this.found = true});

  /// Whether the document exists.
  final bool found;

  @override
  Future<Result<Document>> findById(DocumentId id) async => found
      ? Result<Document>.success(harnessDocument())
      : const Result<Document>.failure(Failure.notFound());

  @override
  Future<Result<List<Document>>> query({
    DocumentFilter filter = DocumentFilter.all,
    DocumentSort sort = DocumentSort.modifiedDescending,
    FolderId? folderId,
    int? limit,
    int offset = 0,
  }) async => Result<List<Document>>.success([harnessDocument()]);

  @override
  Future<Result<List<DocumentPage>>> pagesOf(DocumentId id) async =>
      const Result<List<DocumentPage>>.success([]);
}

/// An OCR text source returning fixed text.
class StubOcrTextSource implements OcrTextSource {
  /// Creates a source returning [text], or failing with [failure].
  StubOcrTextSource({this.text = '', this.failure});

  /// The text every document has.
  final String text;

  /// When set, every lookup fails with this.
  final Failure? failure;

  @override
  Future<Result<RecognisedText?>> textForPage(PageId pageId) async =>
      const Result<RecognisedText?>.success(null);

  @override
  Future<Result<String>> textForDocument(DocumentId documentId) async {
    final configured = failure;
    if (configured != null) return Result<String>.failure(configured);
    return Result<String>.success(text);
  }
}

/// Builds viewer Cubits over in-memory collaborators.
class ViewerHarness {
  /// Creates a harness.
  ViewerHarness({
    FakePdfRenderer? renderer,
    bool documentFound = true,
    String recognisedText = '',
    Failure? secretsFailure,
    Failure? textFailure,
  }) : renderer = renderer ?? FakePdfRenderer(),
       documents = StubViewerDocuments(found: documentFound),
       secrets = InMemorySecureStore(failure: secretsFailure),
       textSource = StubOcrTextSource(
         text: recognisedText,
         failure: textFailure,
       );

  /// The renderer under the viewer.
  final FakePdfRenderer renderer;

  /// The document source.
  final StubViewerDocuments documents;

  /// The secure store passwords go to.
  final InMemorySecureStore secrets;

  /// The preference store nothing should ever reach.
  final preferences = InMemoryPreferences();

  /// The recognised-text source.
  final StubOcrTextSource textSource;

  /// The open use case over this harness.
  OpenDocumentForViewing get openUseCase => OpenDocumentForViewing(
    documents,
    renderer,
    secrets,
    const FakeDocumentFileResolver(),
  );

  /// Opens [id] through the use case.
  Future<Result<ViewableDocument>> open(DocumentId id, {String? password}) =>
      openUseCase(id, password: password);

  /// Builds a Cubit over this harness.
  ViewerCubit cubit() => ViewerCubit(
    const DocumentId('doc-1'),
    openUseCase,
    RememberDocumentPassword(secrets),
    LoadViewerText(textSource),
  );
}
