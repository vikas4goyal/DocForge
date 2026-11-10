/// Fixed sample data for widget previews, goldens and tests.
///
/// Every value here is deterministic: fixed timestamps, fixed identifiers, no
/// randomness and no wall-clock reads. That is what makes `@Preview()` entries
/// and golden images byte-stable between runs and between machines — a fixture
/// built from `DateTime.now()` would produce a new golden every day.
///
/// Nothing in this file touches a repository, a camera, the
/// network or Isar. A preview that needs data gets it from here.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/contracts/models/scanned_page_bundle.dart';

/// The instant every fixture is anchored to.
///
/// A single fixed point keeps relative dates ("2 days ago") stable in previews
/// and goldens.
final fixtureNow = DateTime.utc(2026, 7, 26, 10, 30);

/// A representative document.
final sampleDocument = Document(
  id: const DocumentId('doc-1'),
  title: 'Invoice — Acme Ltd',
  createdAt: fixtureNow.subtract(const Duration(days: 2)),
  updatedAt: fixtureNow.subtract(const Duration(hours: 3)),
  pageCount: 3,
  sizeInBytes: 482 * 1024,
  libraryPath: LibraryPath.parse('Invoice — Acme Ltd.pdf'),
);

/// A document with a title long enough to exercise truncation and wrapping.
///
/// Every reusable widget needs a long-content preview; this is what feeds it.
final longTitleDocument = sampleDocument.copyWith(
  id: const DocumentId('doc-long'),
  title:
      'Quarterly financial statement and supporting schedules for the '
      'period ending 30 September, including appendices A through F',
);

/// A favourited, foldered document.
final favouriteDocument = sampleDocument.copyWith(
  id: const DocumentId('doc-fav'),
  title: 'Passport scan',
  isFavourite: true,
  folderId: const FolderId('folder-1'),
  pageCount: 1,
  sizeInBytes: 96 * 1024,
);

/// An archived document.
final archivedDocument = sampleDocument.copyWith(
  id: const DocumentId('doc-archived'),
  title: 'Old lease agreement',
  isArchived: true,
);

/// A password-protected document.
final protectedDocument = sampleDocument.copyWith(
  id: const DocumentId('doc-protected'),
  title: 'Bank statement',
  isProtected: true,
);

/// Returns [count] distinct documents with stable ids, titles and dates.
///
/// Used for list, grid and pagination previews. Timestamps step backwards by a
/// fixed interval so ordering is well-defined without touching the clock.
List<Document> sampleDocuments(int count) => List.generate(
  count,
  (index) => sampleDocument.copyWith(
    id: DocumentId('doc-$index'),
    title: 'Document ${index + 1}',
    createdAt: fixtureNow.subtract(Duration(days: index + 1)),
    updatedAt: fixtureNow.subtract(Duration(hours: index + 1)),
    pageCount: (index % 5) + 1,
    sizeInBytes: (index + 1) * 64 * 1024,
  ),
);

/// A representative folder.
final sampleFolder = Folder(
  id: const FolderId('folder-1'),
  name: 'Receipts',
  createdAt: fixtureNow.subtract(const Duration(days: 30)),
  documentCount: 12,
);

/// A folder containing nothing, for empty-state previews.
final emptyFolder = Folder(
  id: const FolderId('folder-empty'),
  name: 'Travel',
  createdAt: fixtureNow.subtract(const Duration(days: 5)),
);

/// Returns [count] distinct folders with stable ids and names.
List<Folder> sampleFolders(int count) => List.generate(
  count,
  (index) => Folder(
    id: FolderId('folder-$index'),
    name: 'Folder ${index + 1}',
    createdAt: fixtureNow.subtract(Duration(days: index + 1)),
    documentCount: index * 3,
  ),
);

/// A representative page.
const samplePage = DocumentPage(
  id: PageId('page-1'),
  documentId: DocumentId('doc-1'),
  order: 0,
  imagePath: '/documents/doc-1/page-1.jpg',
);

/// Returns [count] pages of `doc-1`, in order.
List<DocumentPage> samplePages(int count) => List.generate(
  count,
  (index) => DocumentPage(
    id: PageId('page-$index'),
    documentId: const DocumentId('doc-1'),
    order: index,
    imagePath: '/documents/doc-1/page-$index.jpg',
  ),
);

/// A page reference suitable for crossing an isolate boundary.
const samplePageRef = PageRef(
  id: PageId('page-1'),
  imagePath: '/documents/doc-1/page-1.jpg',
);

/// A captured bundle awaiting document creation.
const sampleBundle = ScannedPageBundle(
  pages: [
    PageRef(id: PageId('page-0'), imagePath: '/tmp/scan/page-0.jpg'),
    PageRef(id: PageId('page-1'), imagePath: '/tmp/scan/page-1.jpg'),
    PageRef(id: PageId('page-2'), imagePath: '/tmp/scan/page-2.jpg'),
  ],
  source: PageSource.camera,
);

/// A representative storage summary.
const sampleStorageSummary = StorageSummary(
  totalBytes: 148 * 1024 * 1024,
  documentCount: 37,
);
