/// Injectable sources of "now" and of new identifiers.
///
/// The AI implementation guidelines require deterministic behaviour, and the
/// preview and golden-test requirements require byte-stable rendering. Neither
/// is achievable while business logic calls `DateTime.now()` or generates a
/// random UUID directly, so both are interfaces that the composition root
/// supplies and that tests, previews and fixtures replace with fixed values.
library;

import 'package:uuid/uuid.dart';

/// Supplies the current time.
abstract interface class Clock {
  /// Returns the current instant.
  DateTime now();
}

/// A [Clock] backed by the real system time.
///
/// Reports **UTC**, not local time. Timestamps are stored, compared and sorted
/// throughout the app, and Isar returns every `DateTime` in local time — so
/// without one canonical representation a stored value and a freshly-read one
/// describe the same instant yet compare unequal. UTC is also what a future
/// sync layer needs when reconciling devices in different timezones. Convert to
/// local only when formatting for display.
///
/// Used in production only. Anything that renders or asserts on a timestamp
/// must be given a [FixedClock] instead.
class SystemClock implements Clock {
  /// Creates a clock reading the device's current time.
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

/// A [Clock] that always reports the same instant.
///
/// Makes tests, previews and goldens reproducible.
class FixedClock implements Clock {
  /// Creates a clock permanently reporting [instant].
  const FixedClock(this.instant);

  /// The instant this clock always returns.
  final DateTime instant;

  @override
  DateTime now() => instant;
}

/// A [Clock] that advances by a fixed step on each read.
///
/// Useful where a test needs distinct but predictable timestamps — ordering
/// documents by modified date, for example — without reintroducing real time.
class SteppingClock implements Clock {
  /// Creates a clock starting at [start] and advancing by [step] per call.
  SteppingClock({required DateTime start, this.step = const Duration(hours: 1)})
    : _current = start;

  /// How far the clock advances after each [now] call.
  final Duration step;

  DateTime _current;

  @override
  DateTime now() {
    final value = _current;
    _current = _current.add(step);
    return value;
  }
}

/// Supplies new unique identifiers for entities.
abstract interface class IdGenerator {
  /// Returns a new identifier.
  String generate();
}

/// An [IdGenerator] producing random UUID v4 values.
///
/// UUIDs rather than auto-increment keys: a future cloud-sync layer has to
/// reconcile records created independently on more than one device, and
/// database-assigned integers collide the moment that happens.
class UuidGenerator implements IdGenerator {
  /// Creates a generator backed by UUID v4.
  UuidGenerator() : _uuid = const Uuid();

  final Uuid _uuid;

  @override
  String generate() => _uuid.v4();
}

/// An [IdGenerator] producing predictable sequential identifiers.
///
/// Yields `<prefix>-1`, `<prefix>-2`, and so on, so a test or preview can
/// assert on an exact identifier.
class SequentialIdGenerator implements IdGenerator {
  /// Creates a generator whose values start at `<prefix>-1`.
  SequentialIdGenerator({this.prefix = 'id'});

  /// Text placed before the sequence number.
  final String prefix;

  int _next = 0;

  @override
  String generate() {
    _next++;
    return '$prefix-$_next';
  }
}
