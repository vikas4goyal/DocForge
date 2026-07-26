/// Assembles everything the Home screen shows.
library;

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/failures/result.dart';

/// Everything the Home screen displays, loaded together.
class HomeData {
  /// Creates the Home data set.
  const HomeData({
    required this.recentDocuments,
    required this.folders,
    required this.favouriteCount,
    required this.archivedCount,
    required this.storage,
  });

  /// The most recently modified documents, newest first.
  final List<Document> recentDocuments;

  /// Every folder with its current document count.
  final List<Folder> folders;

  /// How many non-archived favourites exist.
  final int favouriteCount;

  /// How many archived documents exist.
  final int archivedCount;

  /// Storage consumed by stored documents.
  final StorageSummary storage;

  /// Whether the library holds nothing at all.
  ///
  /// The empty state is driven by the *storage* document count, not by the
  /// recents list: a library consisting entirely of archived documents is not
  /// empty, and telling that user to scan their first document would be wrong.
  bool get isEmpty => storage.documentCount == 0;
}

/// Loads the Home screen's data through the cross-capability contracts.
///
/// Depends on `core/contracts/` interfaces rather than on the library feature,
/// because a feature may not import another feature. That is also what lets
/// this be unit-tested without a database.
class LoadHomeData {
  /// Creates the use case.
  const LoadHomeData(this._documents, this._folders, this._storage);

  final DocumentReader _documents;
  final FolderReader _folders;
  final StorageSummaryReader _storage;

  /// How many recent documents Home shows.
  ///
  /// Home is a launchpad, not a list: a handful of recents plus the shortcuts
  /// fit on one screen, and "All documents" is one tap away for the rest.
  static const recentLimit = 5;

  /// Loads everything Home displays.
  ///
  /// Fails only when the document query fails: recents are the one section the
  /// screen cannot be assembled without. A folder or storage read that fails
  /// degrades to an empty folder list or a zero summary, because losing the
  /// whole screen over a storage figure would be a worse outcome than showing
  /// it without one.
  Future<Result<HomeData>> call() async {
    final recents = await _documents.query(limit: recentLimit);
    if (recents case Failed<List<Document>>(:final failure)) {
      return Result<HomeData>.failure(failure);
    }

    final folders = await _folders.all();
    final storage = await _storage.summary();

    final favourites = await _documents.query(
      filter: DocumentFilter.favourites,
    );
    final archived = await _documents.query(filter: DocumentFilter.archived);

    return Result<HomeData>.success(
      HomeData(
        // Ordering and the exclusion of archived documents are applied by the
        // query itself, so Home cannot disagree with the document list about
        // what "recent" means.
        recentDocuments: recents.valueOrNull!,
        folders: folders.getOrElse(const <Folder>[]),
        favouriteCount: favourites.valueOrNull?.length ?? 0,
        archivedCount: archived.valueOrNull?.length ?? 0,
        storage: storage.getOrElse(StorageSummary.empty),
      ),
    );
  }
}
