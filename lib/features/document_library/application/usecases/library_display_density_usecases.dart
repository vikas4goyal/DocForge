/// Application operations for the library display-density preference.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_library/domain/library_display_density.dart';

/// Loads the persisted Dashboard display density.
class LoadLibraryDisplayDensity {
  /// Creates the use case over [repository].
  const LoadLibraryDisplayDensity(this.repository);

  /// Preference persistence boundary.
  final LibraryDisplayDensityRepository repository;

  /// Returns the selected density.
  Future<Result<LibraryDisplayDensity>> call() => repository.load();
}

/// Saves the selected Dashboard display density.
class SaveLibraryDisplayDensity {
  /// Creates the use case over [repository].
  const SaveLibraryDisplayDensity(this.repository);

  /// Preference persistence boundary.
  final LibraryDisplayDensityRepository repository;

  /// Persists [density].
  Future<Result<void>> call(LibraryDisplayDensity density) =>
      repository.save(density);
}
