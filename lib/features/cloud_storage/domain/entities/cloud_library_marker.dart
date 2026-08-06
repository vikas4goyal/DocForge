/// Marker identifying an established app-owned iCloud library.
library;

/// Current marker schema understood by this release.
const cloudLibraryMarkerSchemaVersion = 1;

/// Stable identity written even when an established library is empty.
class CloudLibraryMarker {
  /// Creates a marker.
  const CloudLibraryMarker({
    this.schemaVersion = cloudLibraryMarkerSchemaVersion,
    this.libraryIdentifier = defaultLibraryIdentifier,
  });

  /// Stable identifier for DocScanly's one library namespace.
  static const defaultLibraryIdentifier = 'docscanly-library';

  /// Marker schema version.
  final int schemaVersion;

  /// Non-PII library namespace identifier.
  final String libraryIdentifier;

  /// Whether this release can safely use the marker.
  bool get isSupported =>
      schemaVersion == cloudLibraryMarkerSchemaVersion &&
      libraryIdentifier == defaultLibraryIdentifier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloudLibraryMarker &&
          other.schemaVersion == schemaVersion &&
          other.libraryIdentifier == libraryIdentifier;

  @override
  int get hashCode => Object.hash(schemaVersion, libraryIdentifier);
}
