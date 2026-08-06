/// SharedPreferences-backed library display density.
library;

import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/storage_keys.dart';
import 'package:doc_scanly/features/document_library/domain/library_display_density.dart';

/// Stores the non-sensitive thumbnail-size choice in app preferences.
class PreferenceLibraryDisplayDensityRepository
    implements LibraryDisplayDensityRepository {
  /// Creates the repository over [preferences].
  const PreferenceLibraryDisplayDensityRepository(this.preferences);

  /// App preference boundary.
  final PreferenceStore preferences;

  @override
  Future<Result<LibraryDisplayDensity>> load() async {
    final stored = await preferences.readString(
      PreferenceKeys.libraryDisplayDensity,
    );
    return stored.map(LibraryDisplayDensity.fromName);
  }

  @override
  Future<Result<void>> save(LibraryDisplayDensity density) => preferences
      .writeString(PreferenceKeys.libraryDisplayDensity, density.name);
}
