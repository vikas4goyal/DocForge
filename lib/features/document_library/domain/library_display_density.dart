/// User-selected density for Dashboard and open-folder grids.
library;

import 'package:doc_scanly/core/failures/result.dart';

/// The two supported library thumbnail sizes.
enum LibraryDisplayDensity {
  /// The original, prominent two-column compact layout.
  large,

  /// A denser three-column compact layout.
  small;

  /// Parses a persisted value and safely falls back to [large].
  static LibraryDisplayDensity fromName(String? value) =>
      values.where((density) => density.name == value).firstOrNull ?? large;
}

/// Persists the non-sensitive library display preference.
abstract interface class LibraryDisplayDensityRepository {
  /// Loads the selected density, defaulting to Large when none was saved.
  Future<Result<LibraryDisplayDensity>> load();

  /// Stores [density] for later application launches.
  Future<Result<void>> save(LibraryDisplayDensity density);
}
