import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/core/widgets/app_state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in the minimum app scaffolding a widget test needs.
Widget wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppLoadingIndicator', () {
    testWidgets('renders a progress indicator', (tester) async {
      await tester.pumpWidget(wrap(const AppLoadingIndicator()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('announces itself to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const AppLoadingIndicator()));

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('accepts a custom semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(const AppLoadingIndicator(semanticsLabel: 'Recognising text')),
      );

      expect(find.bySemanticsLabel('Recognising text'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('honours a caller-supplied key', (tester) async {
      await tester.pumpWidget(
        wrap(const AppLoadingIndicator(key: Key('home_loading_indicator'))),
      );

      expect(find.byKey(const Key('home_loading_indicator')), findsOneWidget);
    });
  });

  group('AppProgressIndicator', () {
    testWidgets('shows completed out of total', (tester) async {
      await tester.pumpWidget(
        wrap(const AppProgressIndicator(completed: 2, total: 5)),
      );

      expect(find.text('2 of 5'), findsOneWidget);
    });

    testWidgets('includes the label when given', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppProgressIndicator(
            completed: 1,
            total: 3,
            label: 'Recognising text',
          ),
        ),
      );

      expect(find.text('Recognising text — 1 of 3'), findsOneWidget);
    });

    testWidgets('renders indeterminate when the total is unknown', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const AppProgressIndicator(completed: 0, total: 0)),
      );

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      expect(indicator.value, isNull);
      expect(find.text('Working'), findsOneWidget);
    });

    testWidgets('shows no cancel control when none is offered', (tester) async {
      await tester.pumpWidget(
        wrap(const AppProgressIndicator(completed: 1, total: 2)),
      );

      expect(find.byKey(const Key('app_progress_cancel_button')), findsNothing);
    });

    testWidgets('invokes the cancel callback', (tester) async {
      var cancelled = false;
      await tester.pumpWidget(
        wrap(
          AppProgressIndicator(
            completed: 1,
            total: 2,
            onCancel: () => cancelled = true,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('app_progress_cancel_button')));

      expect(cancelled, isTrue);
    });

    testWidgets('announces its progress to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(const AppProgressIndicator(completed: 3, total: 4)),
      );

      expect(find.bySemanticsLabel('3 of 4'), findsWidgets);

      handle.dispose();
    });
  });

  group('AppEmptyState', () {
    testWidgets('shows its title', (tester) async {
      await tester.pumpWidget(
        wrap(const AppEmptyState(title: 'No documents yet')),
      );

      expect(find.text('No documents yet'), findsOneWidget);
    });

    testWidgets('shows an optional message', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppEmptyState(
            title: 'No documents yet',
            message: 'Scan your first document to get started.',
          ),
        ),
      );

      expect(
        find.text('Scan your first document to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('shows no action when none is offered', (tester) async {
      await tester.pumpWidget(wrap(const AppEmptyState(title: 'Nothing here')));

      expect(
        find.byKey(const Key('app_empty_state_action_button')),
        findsNothing,
      );
    });

    testWidgets('invokes the call to action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          AppEmptyState(
            title: 'No documents yet',
            actionLabel: 'Scan document',
            onAction: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('app_empty_state_action_button')));

      expect(tapped, isTrue);
      expect(find.text('Scan document'), findsOneWidget);
    });

    testWidgets('excludes its decorative icon from semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(const AppEmptyState(title: 'Empty', icon: Icons.folder_outlined)),
      );

      // A screen reader must not announce a meaningless icon name. Scoped to
      // the icon itself, since Material's own internals also use
      // ExcludeSemantics elsewhere in the tree.
      expect(
        find.ancestor(
          of: find.byIcon(Icons.folder_outlined),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('rejects an action label with no callback', (tester) async {
      expect(
        () => AppEmptyState(title: 'x', actionLabel: 'Do it'),
        throwsAssertionError,
      );
    });

    testWidgets('remains usable at the maximum text scale', (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(3)),
            child: Scaffold(
              body: AppEmptyState(
                title: 'No documents yet',
                message: 'Scan your first document to get started.',
                actionLabel: 'Scan',
                onAction: _noop,
              ),
            ),
          ),
        ),
      );

      // Content scrolls rather than overflowing.
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('AppErrorView', () {
    testWidgets('shows the message mapped from the failure', (tester) async {
      await tester.pumpWidget(
        wrap(const AppErrorView(failure: Failure.notFound())),
      );

      expect(find.text('That item no longer exists.'), findsOneWidget);
    });

    testWidgets('offers a retry for a retryable failure', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        wrap(
          AppErrorView(
            failure: const Failure.pdf(),
            onRetry: () => retried = true,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('app_error_view_action_button')));

      expect(retried, isTrue);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('offers system settings for a permanently denied permission', (
      tester,
    ) async {
      var opened = false;
      await tester.pumpWidget(
        wrap(
          AppErrorView(
            failure: const Failure.permission(
              kind: PermissionKind.camera,
              permanentlyDenied: true,
            ),
            onOpenSettings: () => opened = true,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('app_error_view_action_button')));

      expect(opened, isTrue);
      expect(find.text('Open settings'), findsOneWidget);
    });

    testWidgets('offers a way back for a corrupt file', (tester) async {
      var wentBack = false;
      await tester.pumpWidget(
        wrap(
          AppErrorView(
            failure: const Failure.corruptFile(),
            onGoBack: () => wentBack = true,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('app_error_view_action_button')));

      expect(wentBack, isTrue);
      expect(find.text('Go back'), findsOneWidget);
    });

    testWidgets('offers export instead when nothing can receive a share', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          AppErrorView(
            failure: const Failure.export(noReceivingApp: true),
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Save to device'), findsOneWidget);
    });

    testWidgets('shows no inert button when no handler is supplied', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const AppErrorView(failure: Failure.pdf())));

      // A button that does nothing when tapped is worse than no button.
      expect(
        find.byKey(const Key('app_error_view_action_button')),
        findsNothing,
      );
    });

    testWidgets('honours a feature-specific retry key', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppErrorView(
            failure: const Failure.pdf(),
            retryKey: const Key('home_error_retry_button'),
            onRetry: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('home_error_retry_button')), findsOneWidget);
    });

    testWidgets('shows nothing actionable for a cancellation', (tester) async {
      await tester.pumpWidget(
        wrap(AppErrorView(failure: const Failure.cancelled(), onRetry: () {})),
      );

      // Cancellation is a user decision, not an error to recover from.
      expect(
        find.byKey(const Key('app_error_view_action_button')),
        findsNothing,
      );
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppErrorView(failure: Failure.notFound()),
          brightness: Brightness.dark,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('That item no longer exists.'), findsOneWidget);
    });
  });

  group('ResponsiveLayout', () {
    /// Renders [child] at a viewport [width].
    ///
    /// The surface itself is resized rather than wrapping in a SizedBox: a
    /// child cannot exceed the test surface, so a 1000px SizedBox inside the
    /// default 800px surface would silently measure 800 and never reach the
    /// expanded breakpoint.
    Future<void> pumpAtWidth(
      WidgetTester tester,
      double width,
      Widget child,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    }

    Widget threeWayLayout() => ResponsiveLayout(
      compact: (_) => const Text('compact'),
      medium: (_) => const Text('medium'),
      expanded: (_) => const Text('expanded'),
    );

    testWidgets('uses the compact layout on a phone width', (tester) async {
      await pumpAtWidth(tester, 400, threeWayLayout());

      expect(find.text('compact'), findsOneWidget);
    });

    testWidgets('uses the medium layout between breakpoints', (tester) async {
      await pumpAtWidth(tester, 700, threeWayLayout());

      expect(find.text('medium'), findsOneWidget);
    });

    testWidgets('uses the expanded layout on a tablet width', (tester) async {
      await pumpAtWidth(tester, 1000, threeWayLayout());

      expect(find.text('expanded'), findsOneWidget);
    });

    testWidgets('falls back to compact when no variants are given', (
      tester,
    ) async {
      await pumpAtWidth(
        tester,
        1000,
        ResponsiveLayout(compact: (_) => const Text('only')),
      );

      expect(find.text('only'), findsOneWidget);
    });

    testWidgets('falls back to medium when no expanded variant is given', (
      tester,
    ) async {
      await pumpAtWidth(
        tester,
        1000,
        ResponsiveLayout(
          compact: (_) => const Text('compact'),
          medium: (_) => const Text('medium'),
        ),
      );

      expect(find.text('medium'), findsOneWidget);
    });
  });

  group('Breakpoints', () {
    test('classifies widths', () {
      expect(Breakpoints.isCompact(599), isTrue);
      expect(Breakpoints.isCompact(600), isFalse);
      expect(Breakpoints.isExpanded(839), isFalse);
      expect(Breakpoints.isExpanded(840), isTrue);
    });

    test('chooses grid columns by width', () {
      expect(Breakpoints.gridColumnsFor(400), 1);
      expect(Breakpoints.gridColumnsFor(700), 2);
      expect(Breakpoints.gridColumnsFor(1000), 3);
    });
  });

  group('AppTheme', () {
    test('builds Material 3 light and dark schemes', () {
      expect(AppTheme.light.useMaterial3, isTrue);
      expect(AppTheme.dark.useMaterial3, isTrue);
      expect(AppTheme.light.colorScheme.brightness, Brightness.light);
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
    });

    test('is deterministic, so goldens stay stable', () {
      expect(AppTheme.light.colorScheme, AppTheme.light.colorScheme);
    });

    test('enforces the 48dp minimum touch target', () {
      expect(AppTheme.minimumTouchTarget, 48.0);
      expect(
        AppTheme.light.materialTapTargetSize,
        MaterialTapTargetSize.padded,
      );
    });
  });
}

/// A no-op callback for tests that only need an action to exist.
void _noop() {}
