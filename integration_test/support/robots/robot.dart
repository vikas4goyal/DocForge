/// What every robot is built out of.
///
/// A robot exposes *intent* — `openDocument(id)`, `captureTwoPages()` — and
/// hides every tap, wait and settle behind it. Flow files then read as the user
/// journey and nothing else, which is what makes them reviewable against the
/// spec rather than against the widget tree.
///
/// The reason this matters more than usual here is maintenance. A screen that
/// gains a step should break one robot, not nine flows. Robots are the single
/// point where the suite couples to the UI, exactly as the key registries are
/// the single point where it couples to the keys (`design.md` D4).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump.dart';

/// The shared behaviour of every screen robot.
///
/// Holds the tester and offers the four things every robot does: wait for its
/// own screen, tap something, type something, and check whether something is
/// present. A robot subclass adds only the vocabulary of its screen.
abstract class Robot {
  /// Creates a robot driving [tester].
  const Robot(this.tester);

  /// The tester every action runs through.
  final WidgetTester tester;

  /// The key identifying this robot's screen.
  ///
  /// Every robot has one, because every action a robot performs is only
  /// meaningful once its screen is on screen — which is what [waitUntilVisible]
  /// enforces.
  Key get screenKey;

  /// Waits until this robot's screen is on screen.
  ///
  /// Called at the start of a robot's first action rather than left to the
  /// flow: a flow that forgot it would fail on a missing control, which reads
  /// as "the button is broken" when the truth is "the screen never arrived".
  Future<void> waitUntilVisible({Duration timeout = defaultTimeout}) =>
      pumpUntilFound(tester, screenKey, timeout: timeout);

  /// Whether this robot's screen is currently on screen.
  ///
  /// A question, not a wait: for a flow deciding between two legitimate states,
  /// never as a substitute for waiting for the state it expects.
  bool get isVisible => find.byKey(screenKey).evaluate().isNotEmpty;

  /// Taps the control carrying [key], waiting for it first.
  @protected
  Future<void> tap(Key key, {Duration timeout = defaultTimeout}) =>
      tapKey(tester, key, timeout: timeout);

  /// Types [text] into the field carrying [key], waiting for it first.
  @protected
  Future<void> type(Key key, String text) => enterTextInto(tester, key, text);

  /// Waits for [key] to appear.
  @protected
  Future<void> waitFor(Key key, {Duration timeout = defaultTimeout}) =>
      pumpUntilFound(tester, key, timeout: timeout);

  /// Waits for [key] to disappear.
  @protected
  Future<void> waitUntilGone(Key key, {Duration timeout = defaultTimeout}) =>
      pumpUntilGone(tester, key, timeout: timeout);

  /// Whether anything carrying [key] is present.
  @protected
  bool has(Key key) => find.byKey(key).evaluate().isNotEmpty;

  /// Asserts that [key] is present, naming the screen when it is not.
  ///
  /// Preferred to a bare `expect(find.byKey(...), findsOneWidget)` in a flow,
  /// because the failure says which screen was being examined.
  void expectPresent(Key key, {String? because}) {
    expect(
      find.byKey(key),
      findsWidgets,
      reason: because ?? 'expected $key on $runtimeType',
    );
  }

  /// Asserts that nothing carries [key].
  void expectAbsent(Key key, {String? because}) {
    expect(
      find.byKey(key),
      findsNothing,
      reason: because ?? 'expected no $key on $runtimeType',
    );
  }
}
