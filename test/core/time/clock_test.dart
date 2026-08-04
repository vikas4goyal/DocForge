import 'package:doc_scanly/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SystemClock', () {
    test('reports a time close to the real one', () {
      const clock = SystemClock();
      final before = DateTime.now();

      final reading = clock.now();

      expect(
        reading.difference(before).abs(),
        lessThan(const Duration(seconds: 5)),
      );
    });

    test('reports UTC', () {
      // Isar returns every DateTime in local time, so the domain has to have
      // one canonical representation or a stored value and a freshly-read one
      // describe the same instant yet compare unequal.
      expect(const SystemClock().now().isUtc, isTrue);
    });
  });

  group('FixedClock', () {
    test('always returns the same instant', () {
      final instant = DateTime.utc(2026, 7, 26, 12);
      final clock = FixedClock(instant);

      expect(clock.now(), instant);
      expect(clock.now(), instant);
      expect(clock.now(), instant);
    });

    test('two clocks with the same instant agree', () {
      final instant = DateTime.utc(2026);

      expect(FixedClock(instant).now(), FixedClock(instant).now());
    });
  });

  group('SteppingClock', () {
    test('advances by the configured step on each read', () {
      final clock = SteppingClock(
        start: DateTime.utc(2026),
        step: const Duration(minutes: 30),
      );

      expect(clock.now(), DateTime.utc(2026));
      expect(clock.now(), DateTime.utc(2026, 1, 1, 0, 30));
      expect(clock.now(), DateTime.utc(2026, 1, 1, 1));
    });

    test('defaults to a one-hour step', () {
      final clock = SteppingClock(start: DateTime.utc(2026));

      final first = clock.now();
      final second = clock.now();

      expect(second.difference(first), const Duration(hours: 1));
    });

    test('produces a strictly increasing sequence', () {
      final clock = SteppingClock(start: DateTime.utc(2026));

      final readings = List.generate(10, (_) => clock.now());

      for (var i = 1; i < readings.length; i++) {
        expect(readings[i].isAfter(readings[i - 1]), isTrue);
      }
    });

    test('is reproducible across two identically configured clocks', () {
      List<DateTime> readAll() {
        final clock = SteppingClock(start: DateTime.utc(2026));
        return List.generate(5, (_) => clock.now());
      }

      expect(readAll(), readAll());
    });
  });

  group('UuidGenerator', () {
    test('produces well-formed UUID v4 values', () {
      final generator = UuidGenerator();

      final id = generator.generate();

      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('produces distinct values', () {
      final generator = UuidGenerator();

      final ids = List.generate(100, (_) => generator.generate());

      expect(ids.toSet(), hasLength(100));
    });
  });

  group('SequentialIdGenerator', () {
    test('produces predictable identifiers', () {
      final generator = SequentialIdGenerator();

      expect(generator.generate(), 'id-1');
      expect(generator.generate(), 'id-2');
      expect(generator.generate(), 'id-3');
    });

    test('honours a custom prefix', () {
      final generator = SequentialIdGenerator(prefix: 'doc');

      expect(generator.generate(), 'doc-1');
    });

    test('is reproducible across two fresh generators', () {
      List<String> readAll() {
        final generator = SequentialIdGenerator();
        return List.generate(5, (_) => generator.generate());
      }

      expect(readAll(), readAll());
    });

    test('produces distinct values', () {
      final generator = SequentialIdGenerator();

      final ids = List.generate(50, (_) => generator.generate());

      expect(ids.toSet(), hasLength(50));
    });
  });
}
