/// The value objects shared between settings and the features they configure.
///
/// These live in `core/contracts/` rather than with the feature that acts on
/// them because *two* features need each one, and a feature may not import
/// another feature (`design.md` §2). PDF quality is chosen in settings and
/// applied by PDF generation; the naming pattern is chosen in settings and
/// expanded by PDF generation and import; the recognition script is chosen in
/// settings and used by the features that act on them.
///
/// Pure Dart: no Flutter, no plugins, no storage.
library;

/// How much fidelity a generated PDF keeps.
///
/// A single setting rather than separate resolution and compression knobs: the
/// two only make sense together, and offering both invites combinations that
/// are strictly worse than one of the presets.
enum PdfQuality {
  /// Smallest file. Readable, but visibly soft on fine print.
  low(imageQuality: 55, maxDimension: 1240, label: 'Small file'),

  /// The default. Indistinguishable from the capture at reading distance.
  balanced(imageQuality: 80, maxDimension: 2000, label: 'Balanced'),

  /// Largest file. Preserves detail for reprinting or archiving.
  high(imageQuality: 95, maxDimension: 3500, label: 'Best quality');

  const PdfQuality({
    required this.imageQuality,
    required this.maxDimension,
    required this.label,
  });

  /// JPEG quality each page image is encoded at.
  final int imageQuality;

  /// Longest edge, in pixels, a page image is scaled to.
  ///
  /// Bounded even at the highest setting: a modern camera produces more pixels
  /// than any printer resolves from a sheet of paper, and carrying them makes a
  /// fifty-page scan unshareable.
  final int maxDimension;

  /// The name shown in settings.
  final String label;

  /// The quality used when the user has chosen nothing.
  static const defaultQuality = PdfQuality.balanced;

  /// The quality named [name], or the default when none matches.
  ///
  /// Falls back rather than throwing so a settings value written by an older
  /// release degrades to a working default instead of an error.
  static PdfQuality fromName(String? name) => values.firstWhere(
    (quality) => quality.name == name,
    orElse: () => defaultQuality,
  );
}

/// A pattern for naming a new document.
enum NamingPattern {
  /// `Scan 2026-03-14 09.30`.
  dateAndTime('dateAndTime', 'Date and time'),

  /// `Scan 2026-03-14`.
  dateOnly('dateOnly', 'Date only'),

  /// `Scan 1`, `Scan 2`, … counting from the documents already stored.
  sequential('sequential', 'Sequential number'),

  /// `Document` every time, leaving the user to rename.
  plain('plain', 'Just "Document"');

  const NamingPattern(this.id, this.label);

  /// Stable identifier written to settings.
  ///
  /// Separate from [name] so renaming the enum constant does not silently
  /// invalidate every user's stored preference.
  final String id;

  /// The name shown in settings.
  final String label;

  /// The pattern used when the user has chosen nothing.
  static const defaultPattern = NamingPattern.dateAndTime;

  /// The pattern with [id], or the default when none matches.
  static NamingPattern fromId(String? id) => values.firstWhere(
    (pattern) => pattern.id == id,
    orElse: () => defaultPattern,
  );
}

/// Rules for naming a document.
abstract final class DocumentNaming {
  /// The prefix every generated name starts with.
  static const prefix = 'Scan';

  /// The name a document with no title falls back to.
  static const fallback = 'Document';

  /// Expands [pattern] for a document created at [now].
  ///
  /// [existingCount] is how many documents the library already holds, used only
  /// by [NamingPattern.sequential].
  ///
  /// [now] is passed in rather than read from a clock here because this is a
  /// pure function: the same inputs must always give the same name, which is
  /// what makes the expansion testable and every golden stable.
  ///
  /// The date is formatted manually rather than through `intl` because the
  /// result is a *file name*, not a display string. A locale-dependent name
  /// would sort differently on different devices and could contain a slash.
  static String expand(
    NamingPattern pattern, {
    required DateTime now,
    int existingCount = 0,
  }) {
    final local = now.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';

    return switch (pattern) {
      // Dots rather than colons between hours and minutes: a colon is illegal
      // in a file name on several platforms and confusing in a share sheet.
      NamingPattern.dateAndTime =>
        '$prefix $date '
            '${local.hour.toString().padLeft(2, '0')}.'
            '${local.minute.toString().padLeft(2, '0')}',
      NamingPattern.dateOnly => '$prefix $date',
      NamingPattern.sequential => '$prefix ${existingCount + 1}',
      NamingPattern.plain => fallback,
    };
  }

  /// Returns the title to store, given what the user typed.
  ///
  /// A blank field means "use the default", not "a document with no name": an
  /// untitled document is unfindable, and the library forbids an empty title.
  static String resolve(String? entered, String generated) {
    final trimmed = entered?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    return generated.trim().isEmpty ? fallback : generated.trim();
  }

  /// Returns the file name for a document titled [title].
  ///
  /// Derived from the title so the file a user shares is recognisable, with
  /// characters a filesystem would reject replaced rather than dropped — two
  /// titles differing only in punctuation must not collide.
  static String fileNameFor(String title) {
    final safe = title
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final hasContent = RegExp('[a-zA-Z0-9]').hasMatch(safe);
    return '${hasContent ? safe : fallback}.pdf';
  }
}
