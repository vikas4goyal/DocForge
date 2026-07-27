/// The shared loading, empty, error and progress views.
///
/// Every capability's spec requires the same four states with the same
/// affordances — a retry on every error, a call to action on every empty state,
/// a semantics label on every control. Building them once here means a feature
/// cannot accidentally ship an error view with no way forward, and it gives the
/// widget tests a single place to verify the contract.
///
/// Each widget takes its key from the caller so the feature-specific keys the
/// specs mandate (`home_error_view`, `search_empty_state`, …) are preserved.
library;

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A centred loading indicator.
///
/// Announces itself to screen readers so a blind user is told the screen is
/// working rather than being met with silence.
class AppLoadingIndicator extends StatelessWidget {
  /// Creates a loading indicator.
  const AppLoadingIndicator({super.key, this.semanticsLabel = 'Loading'});

  /// Text announced by a screen reader while this indicator is shown.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: semanticsLabel,
        liveRegion: true,
        child: const CircularProgressIndicator.adaptive(),
      ),
    );
  }
}

/// A determinate progress indicator for a long-running operation.
///
/// Shows completed-out-of-total rather than only a bar, because that is what
/// the OCR, enhancement, PDF and import specs require the user to see, and it
/// is what a screen reader can announce meaningfully.
class AppProgressIndicator extends StatelessWidget {
  /// Creates a progress indicator for [completed] of [total] units.
  const AppProgressIndicator({
    required this.completed,
    required this.total,
    super.key,
    this.label,
    this.onCancel,
  });

  /// Units finished so far.
  final int completed;

  /// Total units of work.
  final int total;

  /// Optional description of what is in progress.
  final String? label;

  /// Called when the user cancels. When null, no cancel control is shown.
  final VoidCallback? onCancel;

  /// Completion as a fraction, or null when the total is unknown.
  double? get _fraction => total <= 0 ? null : completed / total;

  @override
  Widget build(BuildContext context) {
    final progressText = total > 0 ? '$completed of $total' : 'Working';
    final description = label == null ? progressText : '$label — $progressText';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: description,
              liveRegion: true,
              child: LinearProgressIndicator(value: _fraction),
            ),
            const SizedBox(height: 12),
            Text(description, textAlign: TextAlign.center),
            if (onCancel != null) ...[
              const SizedBox(height: 16),
              TextButton(
                key: const Key('app_progress_cancel_button'),
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An empty state with a message and an optional call to action.
class AppEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const AppEmptyState({
    required this.title,
    super.key,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'an action needs both a label and a callback',
       );

  /// Short heading describing what is missing.
  final String title;

  /// Optional longer explanation or guidance.
  final String? message;

  /// Optional illustrative icon. Excluded from semantics as decoration.
  final IconData? icon;

  /// Label for the call to action.
  final String? actionLabel;

  /// Called when the call to action is activated.
  final VoidCallback? onAction;

  /// Key applied to the call to action, so feature tests can target it.
  ///
  /// Mirrors [AppErrorView.retryKey]: an empty state's action is named by the
  /// feature's spec, and a shared default key would make every feature's test
  /// match every other feature's button.
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        // Scrollable so the content stays reachable at the maximum system text
        // scale instead of overflowing.
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              // Decorative: excluded from the semantics tree so a screen reader
              // does not announce a meaningless icon name.
              ExcludeSemantics(
                child: Icon(icon, size: 48, color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                key: actionKey ?? const Key('app_empty_state_action_button'),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An error view showing a human-readable message and a recovery action.
///
/// Built from a [Failure] rather than a raw string so the message and the
/// offered recovery always match the failure that occurred — the mapping lives
/// in one tested place instead of being re-decided per screen.
class AppErrorView extends StatelessWidget {
  /// Creates an error view for [failure].
  const AppErrorView({
    required this.failure,
    super.key,
    this.onRetry,
    this.onOpenSettings,
    this.onGoBack,
    this.retryKey,
  });

  /// The failure to explain.
  final Failure failure;

  /// Called when the user retries.
  final VoidCallback? onRetry;

  /// Called when the user opens the system settings.
  final VoidCallback? onOpenSettings;

  /// Called when the user returns to the previous screen.
  final VoidCallback? onGoBack;

  /// Key applied to the recovery control, so feature tests can target it.
  final Key? retryKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentation = failure.presentation;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              presentation.message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            ...?_recoveryAction(presentation.action),
          ],
        ),
      ),
    );
  }

  /// Builds the control matching [action], or nothing when none applies.
  ///
  /// Returning null rather than an empty widget keeps a bare message on screen
  /// when the caller has supplied no handler, instead of an inert button that
  /// does nothing when tapped.
  List<Widget>? _recoveryAction(RecoveryAction action) {
    final (callback, label) = switch (action) {
      RecoveryAction.retry => (onRetry, 'Try again'),
      RecoveryAction.openSettings => (onOpenSettings, 'Open settings'),
      RecoveryAction.freeStorage => (onGoBack, 'Manage storage'),
      RecoveryAction.exportInstead => (onRetry, 'Save to device'),
      RecoveryAction.goBack => (onGoBack, 'Go back'),
      RecoveryAction.none => (null, ''),
    };

    if (callback == null) return null;

    return [
      const SizedBox(height: 24),
      FilledButton(
        key: retryKey ?? const Key('app_error_view_action_button'),
        onPressed: callback,
        child: Text(label),
      ),
    ];
  }
}

/// Chooses a layout based on the available width.
///
/// Every screen has to adapt across phone and tablet; routing that decision
/// through one widget keeps the breakpoints consistent and makes the tablet
/// variant straightforward to preview and golden-test.
class ResponsiveLayout extends StatelessWidget {
  /// Creates a responsive layout.
  const ResponsiveLayout({
    required this.compact,
    super.key,
    this.medium,
    this.expanded,
  });

  /// Layout used on phone-width viewports.
  final WidgetBuilder compact;

  /// Layout used on medium viewports. Falls back to [compact].
  final WidgetBuilder? medium;

  /// Layout used on tablet-width viewports. Falls back to [medium].
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (Breakpoints.isExpanded(width)) {
          return (expanded ?? medium ?? compact)(context);
        }
        if (!Breakpoints.isCompact(width)) {
          return (medium ?? compact)(context);
        }
        return compact(context);
      },
    );
  }
}
