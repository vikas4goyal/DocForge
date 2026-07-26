/// Permission handling, abstracted away from the plugin.
///
/// Permissions are requested just in time — when the user chooses the action
/// that needs them — and every denial must lead somewhere. The distinction that
/// matters is *denied* versus *permanently denied*: the first can be re-asked
/// in-app, the second can only be resolved in system settings, and offering a
/// retry for the second produces a button that silently does nothing.
///
/// Wrapping the plugin keeps that decision in one tested place and lets tests
/// and previews run without a platform binding.
library;

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// The outcome of a permission request or query.
enum PermissionState {
  /// Access is available.
  granted,

  /// Refused, but the user can be asked again in-app.
  denied,

  /// Refused with "don't ask again". Only system settings can resolve it.
  permanentlyDenied,

  /// Unavailable on this device — no camera, for instance.
  restricted,
}

/// Queries and requests the permissions DocForge needs.
abstract interface class PermissionService {
  /// Returns the current state of [kind] without prompting.
  Future<PermissionState> status(PermissionKind kind);

  /// Requests [kind], prompting the user if the system allows it.
  Future<PermissionState> request(PermissionKind kind);

  /// Opens the system settings page for this application.
  ///
  /// Returns whether the settings screen was opened.
  Future<bool> openSettings();
}

/// Convenience helpers shared by every caller.
extension PermissionServiceX on PermissionService {
  /// Requests [kind] and converts a refusal into a [Failure].
  ///
  /// Saves every call site from re-deriving which failure a given state maps
  /// to, and ensures `permanentlyDenied` always reaches the UI as such so the
  /// error view offers settings rather than a useless retry.
  Future<Result<void>> require(PermissionKind kind) async {
    final state = await request(kind);

    return switch (state) {
      PermissionState.granted => const Result<void>.success(null),
      PermissionState.denied => Result<void>.failure(
        Failure.permission(kind: kind),
      ),
      PermissionState.permanentlyDenied => Result<void>.failure(
        Failure.permission(kind: kind, permanentlyDenied: true),
      ),
      // Restricted is reported as permanently denied: from the user's point of
      // view neither a retry nor a prompt will ever help.
      PermissionState.restricted => Result<void>.failure(
        Failure.permission(kind: kind, permanentlyDenied: true),
      ),
    };
  }
}

/// A [PermissionService] backed by permission_handler.
class PluginPermissionService implements PermissionService {
  /// Creates a service over the platform permission plugin.
  const PluginPermissionService();

  @override
  Future<PermissionState> status(PermissionKind kind) async =>
      _map(await _permissionFor(kind).status);

  @override
  Future<PermissionState> request(PermissionKind kind) async =>
      _map(await _permissionFor(kind).request());

  @override
  Future<bool> openSettings() => ph.openAppSettings();

  /// Maps a domain permission to the plugin's equivalent.
  ph.Permission _permissionFor(PermissionKind kind) => switch (kind) {
    PermissionKind.camera => ph.Permission.camera,
    // Android 13+ and iOS 14+ expose the modern photo permission; the plugin
    // resolves the right underlying permission per platform version.
    PermissionKind.photos => ph.Permission.photos,
    PermissionKind.files => ph.Permission.storage,
  };

  /// Maps a plugin status onto the four states the app distinguishes.
  PermissionState _map(ph.PermissionStatus status) => switch (status) {
    ph.PermissionStatus.granted ||
    // "Limited" means the user picked specific photos. Access exists, so
    // treating it as denied would block an import the user just authorised.
    ph.PermissionStatus.limited ||
    ph.PermissionStatus.provisional => PermissionState.granted,
    ph.PermissionStatus.denied => PermissionState.denied,
    ph.PermissionStatus.permanentlyDenied => PermissionState.permanentlyDenied,
    ph.PermissionStatus.restricted => PermissionState.restricted,
  };
}

/// A [PermissionService] with scripted answers, for tests and previews.
class FakePermissionService implements PermissionService {
  /// Creates a fake answering [defaultState] for every kind not in [states].
  FakePermissionService({
    this.defaultState = PermissionState.granted,
    Map<PermissionKind, PermissionState>? states,
    this.grantOnRequest = false,
  }) : _states = <PermissionKind, PermissionState>{...?states};

  /// State reported for any permission with no explicit entry.
  final PermissionState defaultState;

  final Map<PermissionKind, PermissionState> _states;

  /// When true, a request upgrades a denied permission to granted.
  ///
  /// Models the user accepting the system prompt.
  final bool grantOnRequest;

  /// Number of times [openSettings] was called, for assertions.
  int openSettingsCallCount = 0;

  /// Number of times [request] was called, for asserting just-in-time prompts.
  int requestCallCount = 0;

  @override
  Future<PermissionState> status(PermissionKind kind) async =>
      _states[kind] ?? defaultState;

  @override
  Future<PermissionState> request(PermissionKind kind) async {
    requestCallCount++;
    final current = _states[kind] ?? defaultState;

    // A permanently denied permission cannot be re-prompted, so a request must
    // not silently "succeed" in the fake either.
    if (grantOnRequest && current == PermissionState.denied) {
      _states[kind] = PermissionState.granted;
      return PermissionState.granted;
    }
    return current;
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCallCount++;
    return true;
  }
}
