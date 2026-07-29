/// Waiting, and saying what was being waited for.
///
/// A Tier-3 flow drives an application doing real work — rendering pages,
/// composing a PDF, writing to the library folder — so `pumpAndSettle` is the
/// wrong tool twice over. It either hangs, because something is genuinely still
/// running, or it races, because it returned during a gap between two pieces of
/// work. And when it does fail it says only "pumpAndSettle timed out", which
/// tells whoever reads the CI log nothing about where the flow was.
///
/// Everything here is built around the opposite property: a timeout names the
/// key it was waiting for and the step that was running, so the failure is
/// actionable without re-running anything (`design.md` D4).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// How long a wait runs before it gives up.
///
/// Generous, because the alternative on a slow device is a flake, and a flow
/// that is merely slow still passes. A step that is genuinely stuck fails at
/// the same point every time, which is what distinguishes the two.
const defaultTimeout = Duration(seconds: 30);

/// The step a flow is currently performing.
///
/// Set by [step] and read only when a wait fails. Kept as a plain field rather
/// than passed through every call because it exists solely to improve a failure
/// message, and threading it through would put test scaffolding into the
/// signature of every robot method.
String? _currentStep;

/// The name of the step currently running, for a failure message.
String get currentStep => _currentStep ?? 'no step';

/// Runs [body] as a named step.
///
/// The name appears in any timeout raised inside [body], which is what turns
/// "waited for creation_page_table_screen" into "waited for
/// creation_page_table_screen while generating the PDF". Restores the previous
/// name afterwards, so nested steps read as the innermost one.
Future<T> step<T>(String name, Future<T> Function() body) async {
  final previous = _currentStep;
  _currentStep = name;
  try {
    return await body();
  } finally {
    _currentStep = previous;
  }
}

/// Pumps until [finder] matches, or fails naming what it waited for.
///
/// Pumps one frame at a time rather than settling: the application is doing
/// real work throughout a flow, and the question being asked is "is it on
/// screen yet", not "has everything everywhere stopped".
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  String? describe,
  Duration timeout = defaultTimeout,
  Duration interval = const Duration(milliseconds: 50),
}) async {
  final deadline = tester.binding.clock.now().add(timeout);

  while (tester.binding.clock.now().isBefore(deadline)) {
    await tester.pump(interval);
    if (finder.evaluate().isNotEmpty) return;
  }

  fail(
    'Timed out after ${timeout.inSeconds}s waiting for '
    '${describe ?? finder.describeMatch(Plurality.many)} during: $currentStep.\n'
    'The widget never appeared. Either the step before it did not complete, '
    'or the key moved and the registry was not updated with it.',
  );
}

/// Pumps until any of [keys] is on screen.
///
/// For a step with more than one legitimate outcome — a list that may load
/// content or may legitimately be empty. A flow that waited only for content
/// would hang on a fresh install, and one that waited only for the empty state
/// would hang everywhere else.
Future<void> pumpUntilAnyOf(
  WidgetTester tester,
  List<Key> keys, {
  Duration timeout = defaultTimeout,
  Duration interval = const Duration(milliseconds: 50),
}) async {
  final deadline = tester.binding.clock.now().add(timeout);

  while (tester.binding.clock.now().isBefore(deadline)) {
    await tester.pump(interval);
    if (keys.any((key) => find.byKey(key).evaluate().isNotEmpty)) return;
  }

  fail(
    'Timed out after ${timeout.inSeconds}s waiting for any of '
    '${keys.join(', ')} during: $currentStep.',
  );
}

/// Pumps until the widget carrying [key] is on screen.
///
/// The flow suite's primary wait. Flows locate elements by key and never by
/// text, because text moves and localises, and a suite that matched on it would
/// break everywhere at once the first time a word changed (`design.md` D3).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Key key, {
  Duration timeout = defaultTimeout,
}) =>
    pumpUntil(tester, find.byKey(key), describe: 'key $key', timeout: timeout);

/// Pumps until nothing carries [key] any more.
///
/// The counterpart to [pumpUntilFound], for a step that ends by something going
/// away: a progress indicator finishing, a sheet closing. Asserting on the
/// *arrival* of the next screen is usually better, but a dismissal that leads
/// back to a screen the flow was already on has nothing new to wait for.
Future<void> pumpUntilGone(
  WidgetTester tester,
  Key key, {
  Duration timeout = defaultTimeout,
  Duration interval = const Duration(milliseconds: 50),
}) async {
  final deadline = tester.binding.clock.now().add(timeout);

  while (tester.binding.clock.now().isBefore(deadline)) {
    await tester.pump(interval);
    if (find.byKey(key).evaluate().isEmpty) return;
  }

  fail(
    'Timed out after ${timeout.inSeconds}s waiting for key $key to disappear '
    'during: $currentStep.',
  );
}

/// Taps the widget carrying [key], waiting for it first.
///
/// Waiting is not optional and not the caller's business to remember: a tap on
/// a widget that has not arrived yet fails with "found 0 widgets", which says
/// nothing about which of the preceding steps did not finish.
Future<void> tapKey(
  WidgetTester tester,
  Key key, {
  Duration timeout = defaultTimeout,
}) async {
  await pumpUntilFound(tester, key, timeout: timeout);
  await tester.tap(find.byKey(key));
  await tester.pump();
}

/// Enters [text] into the field carrying [key], waiting for it first.
Future<void> enterTextInto(
  WidgetTester tester,
  Key key,
  String text, {
  Duration timeout = defaultTimeout,
}) async {
  await pumpUntilFound(tester, key, timeout: timeout);
  await tester.enterText(find.byKey(key), text);
  await tester.pump();
}

/// Scrolls [scrollable] until the widget carrying [key] is visible, then taps.
///
/// Needed wherever a list can grow past the viewport: a flow that only ever
/// acted on visible rows would pass on a tablet and fail on a phone.
Future<void> scrollToAndTap(
  WidgetTester tester,
  Key key, {
  required Finder scrollable,
  double delta = 120,
}) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    delta,
    scrollable: scrollable,
  );
  await tester.pump();
  await tester.tap(find.byKey(key));
  await tester.pump();
}
