/// How library metadata is rendered as text.
///
/// Kept out of the widgets so the strings a screen reader announces and the
/// strings shown on screen are produced by the same tested functions, and so a
/// change to date or size formatting happens in one place.
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:intl/intl.dart';

/// Formats document and folder metadata for display.
abstract final class LibraryFormatting {
  /// Formats [bytes] as a short human-readable size.
  ///
  /// Uses binary units, which is what a device's own storage screen reports —
  /// showing a different number for the same file is worse than either
  /// convention alone.
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';

    const units = ['KB', 'MB', 'GB', 'TB'];
    var value = bytes / 1024;
    var unit = 0;

    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }

    // One decimal below 10 so "1.4 MB" and "1.9 MB" stay distinguishable, none
    // above it where the extra digit is noise.
    final digits = value < 10 ? 1 : 0;
    return '${value.toStringAsFixed(digits)} ${units[unit]}';
  }

  /// Formats [count] as a page count, singular or plural.
  static String pageCount(int count) => count == 1 ? '1 page' : '$count pages';

  /// Formats [count] as a document count, singular or plural.
  static String documentCount(int count) =>
      count == 1 ? '1 document' : '$count documents';

  /// Formats [timestamp] as a date for display.
  ///
  /// Converts to local time first: timestamps are stored in UTC throughout, and
  /// showing a user a date that is a day out because it was rendered in UTC is
  /// the exact bug the UTC-everywhere rule exists to make visible here.
  static String date(DateTime timestamp) =>
      DateFormat.yMMMd().format(timestamp.toLocal());

  /// Formats [timestamp] as a date and time for display.
  static String dateTime(DateTime timestamp) =>
      DateFormat.yMMMd().add_jm().format(timestamp.toLocal());

  /// The secondary line of a document row.
  static String documentSubtitle(Document document) =>
      '${pageCount(document.pageCount)} · ${fileSize(document.sizeInBytes)} · '
      '${date(document.updatedAt)}';

  /// What a screen reader announces for a document row.
  ///
  /// The spec requires the title, page count, modified date and favourite
  /// status; protection is included because a locked document behaves
  /// differently when opened and the user should know before tapping.
  static String documentSemanticsLabel(Document document) {
    final parts = [
      document.title,
      pageCount(document.pageCount),
      'modified ${date(document.updatedAt)}',
      if (document.isFavourite) 'favourite',
      if (document.isProtected) 'password protected',
      if (document.isArchived) 'archived',
    ];

    return parts.join(', ');
  }

  /// What a screen reader announces for a folder row.
  static String folderSemanticsLabel(Folder folder) =>
      '${folder.name}, ${documentCount(folder.documentCount)}';
}
