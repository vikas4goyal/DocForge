/// The single source of truth for every persisted key in DocForge.
///
/// Keys are declared here rather than inline at their call sites for two
/// reasons. A typo in an inline string silently reads back a default instead of
/// the stored value — a bug that looks like data loss and is hard to trace. And
/// renaming a key later requires a read-old / write-new migration step, which
/// is only greppable if every key lives in one place.
///
/// Namespaces:
/// * `app.*`      — application-level flags in SharedPreferences.
/// * `settings.*` — user-configurable settings in SharedPreferences.
/// * `secure.*`   — secrets in flutter_secure_storage. Never SharedPreferences,
///                  never Isar, never a log line.
library;

/// Keys for non-sensitive values stored in SharedPreferences.
///
/// Nothing here may hold a secret. Anything sensitive belongs in
/// [SecureStorageKeys], which is backed by the Keychain and
/// EncryptedSharedPreferences.
abstract final class PreferenceKeys {
  /// Whether the user has completed the first-launch onboarding flow.
  ///
  /// Set once, at the end of onboarding, and read by the router's onboarding
  /// gate on every launch.
  static const onboardingComplete = 'app.onboardingComplete';

  /// Version marker for the on-disk document layout.
  ///
  /// Lets a future release detect and migrate an older `documents/` layout
  /// instead of losing references to already-stored files.
  static const documentLayoutVersion = 'app.documentLayoutVersion';

  /// Theme mode: light, dark or follow the system.
  static const themeMode = 'settings.themeMode';

  /// BCP-47 language tag used for on-device text recognition.
  static const ocrLanguage = 'settings.ocrLanguage';

  /// Quality preset applied when generating a PDF.
  static const pdfQuality = 'settings.pdfQuality';

  /// Quality preset applied to page images.
  static const imageQuality = 'settings.imageQuality';

  /// Pattern used to generate a default document title.
  static const fileNamingPattern = 'settings.fileNamingPattern';

  /// Directory offered first when the user exports a document.
  static const defaultSaveLocation = 'settings.defaultSaveLocation';

  /// Every preference key, for tests that assert uniqueness and namespacing.
  static const all = <String>[
    onboardingComplete,
    documentLayoutVersion,
    themeMode,
    ocrLanguage,
    pdfQuality,
    imageQuality,
    fileNamingPattern,
    defaultSaveLocation,
  ];
}

/// Keys for secrets stored in flutter_secure_storage.
///
/// Backed by the iOS Keychain and Android EncryptedSharedPreferences. Values
/// read from here are held in memory only for the duration of the operation
/// that needs them and are never written to a log.
abstract final class SecureStorageKeys {
  /// Whether the biometric application lock is enabled.
  ///
  /// Stored securely rather than in preferences so the lock cannot be disabled
  /// by editing an unprotected preferences file on a rooted device.
  static const appLockEnabled = 'secure.appLockEnabled';

  /// Prefix for a per-document PDF password.
  ///
  /// Use [pdfPassword] to build the full key; never concatenate this inline.
  static const pdfPasswordPrefix = 'secure.pdfPassword.';

  /// Returns the secure-storage key holding the password for [documentId].
  ///
  /// The entry is deleted when the document is permanently removed, so a
  /// password never outlives the document it protects.
  static String pdfPassword(String documentId) =>
      '$pdfPasswordPrefix$documentId';

  /// Every fixed secure key, for tests that assert uniqueness and namespacing.
  ///
  /// Excludes [pdfPassword], which is parameterised by document.
  static const all = <String>[appLockEnabled];
}
