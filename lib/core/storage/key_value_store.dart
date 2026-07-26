/// Interfaces over the two key–value stores, plus in-memory fakes.
///
/// Wrapping SharedPreferences and flutter_secure_storage behind interfaces buys
/// three things the project needs: repositories become testable without a
/// platform binding, previews can be fed fixed values, and the secure store is
/// a *different type* from the plain one — so a secret cannot be written to
/// preferences by mistake, it simply will not compile.
///
/// Every method returns a [Result]; a failed read or write is a normal outcome
/// the caller must handle, not an exception to be caught somewhere upstream.
library;

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive key–value storage.
///
/// Backed by SharedPreferences in production. Never used for secrets — see
/// [SecureStore].
abstract interface class PreferenceStore {
  /// Returns the string stored at [key], or null when absent.
  Future<Result<String?>> readString(String key);

  /// Stores [value] at [key].
  Future<Result<void>> writeString(String key, String value);

  /// Returns the boolean stored at [key], or null when absent.
  Future<Result<bool?>> readBool(String key);

  /// Stores [value] at [key].
  ///
  // The positional bool is deliberate: `writeBool(key, value)` reads
  // unambiguously and stays symmetrical with writeString and writeInt. Making
  // this one method take a named argument would make the store API
  // inconsistent for no gain in clarity.
  // ignore: avoid_positional_boolean_parameters
  Future<Result<void>> writeBool(String key, bool value);

  /// Returns the integer stored at [key], or null when absent.
  Future<Result<int?>> readInt(String key);

  /// Stores [value] at [key].
  Future<Result<void>> writeInt(String key, int value);

  /// Removes any value stored at [key].
  Future<Result<void>> remove(String key);
}

/// Storage for secrets.
///
/// Backed by the iOS Keychain and Android EncryptedSharedPreferences. Values
/// read from here are held in memory only for the duration of the operation
/// that needs them and are never logged.
abstract interface class SecureStore {
  /// Returns the secret stored at [key], or null when absent.
  Future<Result<String?>> read(String key);

  /// Stores [value] at [key].
  Future<Result<void>> write(String key, String value);

  /// Removes the secret stored at [key].
  ///
  /// Called when a document is permanently removed, so a password never
  /// outlives the document it protected.
  Future<Result<void>> delete(String key);
}

/// A [PreferenceStore] backed by SharedPreferences.
class SharedPreferencesStore implements PreferenceStore {
  /// Creates a store over an already-obtained SharedPreferences instance.
  ///
  /// The instance is resolved once by the composition root rather than looked
  /// up per call, so no ambient lookup happens inside a repository.
  const SharedPreferencesStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<Result<String?>> readString(String key) async =>
      _read(() => _preferences.getString(key));

  @override
  Future<Result<void>> writeString(String key, String value) async =>
      _write(() => _preferences.setString(key, value));

  @override
  Future<Result<bool?>> readBool(String key) async =>
      _read(() => _preferences.getBool(key));

  @override
  Future<Result<void>> writeBool(String key, bool value) async =>
      _write(() => _preferences.setBool(key, value));

  @override
  Future<Result<int?>> readInt(String key) async =>
      _read(() => _preferences.getInt(key));

  @override
  Future<Result<void>> writeInt(String key, int value) async =>
      _write(() => _preferences.setInt(key, value));

  @override
  Future<Result<void>> remove(String key) async =>
      _write(() => _preferences.remove(key));

  Result<T?> _read<T>(T? Function() read) {
    try {
      return Result<T?>.success(read());
    } on Object catch (error) {
      return Result<T?>.failure(Failure.storage(debugDetail: '$error'));
    }
  }

  Future<Result<void>> _write(Future<bool> Function() write) async {
    try {
      final succeeded = await write();
      // SharedPreferences reports failure by returning false rather than
      // throwing, so an unchecked call would silently lose the write.
      return succeeded
          ? const Result<void>.success(null)
          : const Result<void>.failure(
              Failure.storage(debugDetail: 'write returned false'),
            );
    } on Object catch (error) {
      return Result<void>.failure(Failure.storage(debugDetail: '$error'));
    }
  }
}

/// A [SecureStore] backed by flutter_secure_storage.
class FlutterSecureStore implements SecureStore {
  /// Creates a store over a FlutterSecureStorage instance.
  const FlutterSecureStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<Result<String?>> read(String key) async {
    try {
      return Result<String?>.success(await _storage.read(key: key));
    } on Object catch (error) {
      // Deliberately does not include the value or key contents in the detail.
      return Result<String?>.failure(
        Failure.secureStorageUnavailable(debugDetail: '$error'),
      );
    }
  }

  @override
  Future<Result<void>> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(
        Failure.secureStorageUnavailable(debugDetail: '$error'),
      );
    }
  }

  @override
  Future<Result<void>> delete(String key) async {
    try {
      await _storage.delete(key: key);
      return const Result<void>.success(null);
    } on Object catch (error) {
      return Result<void>.failure(
        Failure.secureStorageUnavailable(debugDetail: '$error'),
      );
    }
  }
}

/// An in-memory [PreferenceStore] for tests and previews.
///
/// Set [failNextWrite] to exercise the write-failure recovery paths the
/// settings spec requires.
class InMemoryPreferenceStore implements PreferenceStore {
  /// Creates a store optionally seeded with [initial] values.
  InMemoryPreferenceStore([Map<String, Object>? initial])
    : _values = {...?initial};

  final Map<String, Object> _values;

  /// When true, the next write fails and the flag resets.
  bool failNextWrite = false;

  /// The current contents, for assertions.
  Map<String, Object> get values => Map.unmodifiable(_values);

  @override
  Future<Result<String?>> readString(String key) async =>
      Result<String?>.success(_values[key] as String?);

  @override
  Future<Result<void>> writeString(String key, String value) async =>
      _write(key, value);

  @override
  Future<Result<bool?>> readBool(String key) async =>
      Result<bool?>.success(_values[key] as bool?);

  @override
  Future<Result<void>> writeBool(String key, bool value) async =>
      _write(key, value);

  @override
  Future<Result<int?>> readInt(String key) async =>
      Result<int?>.success(_values[key] as int?);

  @override
  Future<Result<void>> writeInt(String key, int value) async =>
      _write(key, value);

  @override
  Future<Result<void>> remove(String key) async {
    _values.remove(key);
    return const Result<void>.success(null);
  }

  Future<Result<void>> _write(String key, Object value) async {
    if (failNextWrite) {
      failNextWrite = false;
      return const Result<void>.failure(
        Failure.storage(debugDetail: 'simulated write failure'),
      );
    }
    _values[key] = value;
    return const Result<void>.success(null);
  }
}

/// An in-memory [SecureStore] for tests and previews.
///
/// Set [failNextOperation] to exercise the secure-storage-unavailable path.
class InMemorySecureStore implements SecureStore {
  /// Creates a store optionally seeded with [initial] secrets.
  InMemorySecureStore([Map<String, String>? initial]) : _values = {...?initial};

  final Map<String, String> _values;

  /// When true, the next operation fails and the flag resets.
  bool failNextOperation = false;

  /// The current contents, for assertions.
  Map<String, String> get values => Map.unmodifiable(_values);

  @override
  Future<Result<String?>> read(String key) async {
    if (_consumeFailure()) {
      return const Result<String?>.failure(Failure.secureStorageUnavailable());
    }
    return Result<String?>.success(_values[key]);
  }

  @override
  Future<Result<void>> write(String key, String value) async {
    if (_consumeFailure()) {
      return const Result<void>.failure(Failure.secureStorageUnavailable());
    }
    _values[key] = value;
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> delete(String key) async {
    if (_consumeFailure()) {
      return const Result<void>.failure(Failure.secureStorageUnavailable());
    }
    _values.remove(key);
    return const Result<void>.success(null);
  }

  bool _consumeFailure() {
    if (!failNextOperation) return false;
    failNextOperation = false;
    return true;
  }
}
