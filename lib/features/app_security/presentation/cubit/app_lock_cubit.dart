/// The Cubit driving the unlock screen, and its state.
///
/// Every method is emit / await a use case / emit. What each authentication
/// outcome means, what it says and whether it can be retried are rules in the
/// domain layer and are unit-tested there.
library;

import 'package:doc_scanly/features/app_security/application/usecases/app_lock_usecases.dart';
import 'package:doc_scanly/features/app_security/domain/app_lock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immutable state of the application lock.
class AppLockState extends Equatable {
  const AppLockState._({required this.status, this.lastOutcome});

  /// Before the stored configuration has been read.
  ///
  /// Deliberately not "unlocked": guessing that way would render a document
  /// list for a frame behind an enabled lock.
  const AppLockState.initial() : this._(status: AppLockStatus.unknown);

  /// Where the lock stands.
  final AppLockStatus status;

  /// What the last authentication attempt reported, once there has been one.
  final AuthOutcome? lastOutcome;

  /// Whether content must stay hidden.
  bool get hidesContent => AppLockRules.hidesContent(status);

  /// Whether the system prompt is currently up.
  bool get isAuthenticating => status == AppLockStatus.authenticating;

  /// The message to show, or null when there is nothing to say.
  String? get message =>
      lastOutcome == null ? null : AppLockRules.messageFor(lastOutcome!);

  /// Whether the user can try again here.
  bool get canRetry =>
      lastOutcome == null || AppLockRules.canRetry(lastOutcome!);

  /// Whether the user must change something in the system settings first.
  bool get needsDeviceSetup =>
      lastOutcome != null && AppLockRules.needsDeviceSetup(lastOutcome!);

  /// Returns a copy with the given fields replaced.
  ///
  /// [lastOutcome] is cleared unless supplied, so a message from a previous
  /// attempt cannot survive the next one starting.
  AppLockState copyWith({AppLockStatus? status, AuthOutcome? lastOutcome}) =>
      AppLockState._(status: status ?? this.status, lastOutcome: lastOutcome);

  @override
  List<Object?> get props => [status, lastOutcome];
}

/// Drives the unlock screen.
class AppLockCubit extends Cubit<AppLockState> {
  /// Creates the Cubit over its use cases and the gate it reports to.
  ///
  /// [onUnlocked] tells the router's gate that this session has authenticated.
  /// Injected rather than reached for, because the gate is constructed at the
  /// composition root and the unlock screen is below the router.
  AppLockCubit(this._authenticate, this._isEnabled, {required this.onUnlocked})
    : super(const AppLockState.initial());

  final AuthenticateAppLock _authenticate;
  final IsAppLockEnabled _isEnabled;

  /// Called once the session has authenticated.
  final VoidCallback onUnlocked;

  /// Reads the stored configuration and settles the initial status.
  Future<void> load() async {
    final enabled = await _isEnabled();
    if (isClosed) return;

    emit(
      state.copyWith(
        status: enabled ? AppLockStatus.locked : AppLockStatus.unlocked,
      ),
    );

    // A disabled lock is already unlocked, and telling the gate is what lets
    // the router move on without the user tapping anything.
    if (!enabled) onUnlocked();
  }

  /// Prompts for authentication.
  Future<void> authenticate() async {
    emit(state.copyWith(status: AppLockStatus.authenticating));

    final outcome = await _authenticate();
    if (isClosed) return;

    switch (outcome) {
      case AuthOutcome.succeeded:
        emit(state.copyWith(status: AppLockStatus.unlocked));
        onUnlocked();
      case AuthOutcome.rejected:
      case AuthOutcome.notEnrolled:
      case AuthOutcome.error:
        // Every non-success returns to *locked*, not to an error state. The
        // application stays locked whatever went wrong, which is the property
        // the spec states for both a rejection and a mechanism failure.
        emit(
          state.copyWith(status: AppLockStatus.locked, lastOutcome: outcome),
        );
    }
  }
}

/// A callback taking no arguments and returning nothing.
///
/// Declared here rather than imported from Flutter: this Cubit is presentation
/// but has no widgets in it, and the alias keeps the signature readable.
typedef VoidCallback = void Function();
