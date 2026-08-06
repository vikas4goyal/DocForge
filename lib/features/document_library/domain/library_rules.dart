/// The business rules of the document library.
///
/// These are the rules that would otherwise leak into a Cubit or get re-decided
/// per screen. They live here as pure functions over domain types: no Flutter,
/// no storage, no clock, so each one is directly unit-testable.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';

/// Why a proposed library operation was rejected.
enum LibraryRuleViolation {
  /// A title or folder name was empty or only whitespace.
  emptyName,

  /// A folder with the same name already exists.
  duplicateFolderName,

  /// The operation would leave a document with no pages.
  documentWouldHaveNoPages,
}

/// Validation rules for names.
abstract final class NameRules {
  /// Maximum length of a document title or folder name.
  ///
  /// Long enough for a descriptive title, short enough that a list row and a
  /// generated file name stay manageable.
  static const maxLength = 120;

  /// Returns [name] trimmed, or null when it is not a usable name.
  ///
  /// Trimming here rather than at each call site means "  " and "" are rejected
  /// identically, and a name is stored without incidental whitespace.
  static String? normalise(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length > maxLength
        ? trimmed.substring(0, maxLength)
        : trimmed;
  }

  /// Whether [name] is a usable document title or folder name.
  static bool isValid(String name) => normalise(name) != null;
}

/// Rules governing documents.
abstract final class DocumentRules {
  /// Minimum number of pages a document may have.
  ///
  /// A document with no pages has nothing to render, so the library refuses to
  /// create or reduce one to that state.
  static const minimumPages = 1;

  /// Whether a document may be reduced to [pageCount] pages.
  static bool canHavePageCount(int pageCount) => pageCount >= minimumPages;

  /// Whether [document] should appear in the given [filter]'s results.
  ///
  /// The single definition of "visible", shared by recents, lists and search,
  /// so the three cannot drift apart.
  static bool matchesFilter(
    Document document,
    DocumentFilter filter, {
    FolderMatcher? folderMatcher,
  }) {
    return switch (filter) {
      DocumentFilter.all => document.isVisibleInLibrary,
      DocumentFilter.favourites =>
        document.isVisibleInLibrary && document.isFavourite,
      DocumentFilter.archived =>
        document.trashId == null && document.isArchived,
      DocumentFilter.folder =>
        document.isVisibleInLibrary && (folderMatcher?.call(document) ?? false),
    };
  }

  /// Orders [documents] according to [sort].
  ///
  /// Returns a new list; the input is never mutated, so a caller holding the
  /// original ordering keeps it.
  static List<Document> sorted(List<Document> documents, DocumentSort sort) {
    final ordered = [...documents]
      ..sort(switch (sort) {
        DocumentSort.modifiedDescending => (a, b) => b.updatedAt.compareTo(
          a.updatedAt,
        ),
        DocumentSort.modifiedAscending => (a, b) => a.updatedAt.compareTo(
          b.updatedAt,
        ),
        DocumentSort.createdDescending => (a, b) => b.createdAt.compareTo(
          a.createdAt,
        ),
        DocumentSort.titleAscending =>
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      });

    return ordered;
  }

  /// Returns a title distinguishing a duplicate of [original].
  ///
  /// Appends a copy marker rather than reusing the title, so two documents are
  /// never indistinguishable in a list.
  static String duplicateTitle(String original) => '$original (copy)';
}

/// Tests whether a document belongs to the folder being queried.
typedef FolderMatcher = bool Function(Document document);

/// What happens to a folder's documents when the folder is deleted.
enum FolderDeletionStrategy {
  /// Move the documents out of the folder, leaving them unfiled.
  ///
  /// The safe default: no document is lost as a side effect of tidying folders.
  moveDocumentsOut,

  /// Delete the documents along with the folder.
  deleteDocuments,
}
