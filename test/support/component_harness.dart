/// Tier 2 — mounting one screen over its real state machine.
///
/// The gap this tier exists to close: the repository's existing widget tests
/// stub the Cubit, so they prove a screen renders a state correctly and prove
/// nothing at all about whether the screen, its Cubit and its use cases agree.
/// A Cubit that emitted the wrong state for an action, or a use case whose
/// result the Cubit mapped wrongly, passes every one of them.
///
/// So a component test builds the **real** Cubit over the **real** use cases,
/// and substitutes only at the repository boundary. It stops short of the
/// router and the composition root — that is Tier 3's job, on a device — which
/// is what keeps this tier fast enough to run on every save.
///
/// Where to put one: `test/features/<feature>/component/`. The tier is
/// derivable from the path, which is what lets `tool/verify.dart` and a reader
/// tell at a glance what a test is claiming.
library;

import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/single_child_widget.dart';

/// Mounts [screen] with everything a real screen expects above it.
///
/// Supplies the Material ancestors, the project's own theme and a Navigator, so
/// a screen that pushes a dialog or a sheet behaves as it does in the
/// application. Deliberately *not* the router: a component test that needed the
/// router would be asserting on navigation, which is Tier 1's job in
/// `test/app/router/` and Tier 3's on a device.
///
/// [providers] carry the screen's real Cubits. Pass them here rather than
/// wrapping [screen] yourself so every component test has the same shape and a
/// reader can see what the screen was given without reading the tree.
///
/// [size] defaults to a phone. Pass a tablet size to exercise the expanded
/// layout, which several screens branch on.
Future<void> pumpComponent(
  WidgetTester tester,
  Widget screen, {
  // Typed as the provider package's own base rather than `BlocProvider<...>`:
  // a list element type of `BlocProvider<dynamic>` makes Dart infer
  // `BlocProvider.value(value: cubit)` as `BlocProvider<dynamic>`, which
  // provides `dynamic` and leaves the screen unable to find its Cubit.
  List<SingleChildWidget> providers = const [],
  ThemeData? theme,
  Size size = const Size(390, 844),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: providers.isEmpty
          ? screen
          : MultiBlocProvider(providers: providers, child: screen),
    ),
  );
  await tester.pump();
}

/// Pumps a bounded number of frames.
///
/// Not `pumpAndSettle`: a component test drives real use cases over faked
/// repositories, and a screen showing a progress indicator never settles. A
/// fixed number of frames is enough for a Cubit to emit and the screen to
/// rebuild, which is what these tests assert on.
Future<void> settleComponent(
  WidgetTester tester, {
  int frames = 8,
  Duration interval = const Duration(milliseconds: 16),
}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(interval);
  }
}

/// Asserts that the widget carrying [key] is on screen.
///
/// A thin wrapper, for the reason the robots have one: the failure names what
/// was expected rather than reporting "expected 1, found 0".
void expectVisible(Key key, {String? because}) => expect(
  find.byKey(key),
  findsWidgets,
  reason: because ?? 'expected $key to be on screen',
);

/// Asserts that nothing on screen carries [key].
void expectNotVisible(Key key, {String? because}) => expect(
  find.byKey(key),
  findsNothing,
  reason: because ?? 'expected $key not to be on screen',
);
