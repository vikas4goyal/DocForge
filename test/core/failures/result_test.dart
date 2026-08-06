import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const failure = Failure.notFound();

  group('construction and predicates', () {
    test('a success reports isSuccess', () {
      const result = Result<int>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('a failure reports isFailure', () {
      const result = Result<int>.failure(failure);

      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
    });
  });

  group('accessors', () {
    test('valueOrNull returns the value on success', () {
      expect(const Result<int>.success(42).valueOrNull, 42);
    });

    test('valueOrNull returns null on failure', () {
      expect(const Result<int>.failure(failure).valueOrNull, isNull);
    });

    test('failureOrNull returns the failure on failure', () {
      expect(const Result<int>.failure(failure).failureOrNull, failure);
    });

    test('failureOrNull returns null on success', () {
      expect(const Result<int>.success(42).failureOrNull, isNull);
    });

    test('a successful null value is distinguishable from a failure', () {
      // valueOrNull cannot tell these apart, which is exactly why isSuccess
      // exists — callers holding nullable payloads must use it.
      const success = Result<int?>.success(null);
      const failed = Result<int?>.failure(failure);

      expect(success.valueOrNull, isNull);
      expect(failed.valueOrNull, isNull);
      expect(success.isSuccess, isTrue);
      expect(failed.isSuccess, isFalse);
    });
  });

  group('map', () {
    test('transforms a successful value', () {
      final result = const Result<int>.success(21).map((v) => v * 2);

      expect(result.valueOrNull, 42);
    });

    test('preserves the failure without invoking the transform', () {
      var invoked = false;
      final result = const Result<int>.failure(failure).map((v) {
        invoked = true;
        return v * 2;
      });

      expect(invoked, isFalse);
      expect(result.failureOrNull, failure);
    });

    test('can change the value type', () {
      final result = const Result<int>.success(42).map((v) => v.toString());

      expect(result.valueOrNull, '42');
    });
  });

  group('flatMap', () {
    test('chains a second successful operation', () {
      final result = const Result<int>.success(
        21,
      ).flatMap((v) => Result<String>.success('${v * 2}'));

      expect(result.valueOrNull, '42');
    });

    test('propagates a failure from the second operation', () {
      final result = const Result<int>.success(
        21,
      ).flatMap((v) => const Result<String>.failure(failure));

      expect(result.failureOrNull, failure);
    });

    test('short-circuits when the first operation failed', () {
      var invoked = false;
      final result = const Result<int>.failure(failure).flatMap((v) {
        invoked = true;
        return const Result<String>.success('unreachable');
      });

      expect(invoked, isFalse);
      expect(result.failureOrNull, failure);
    });
  });

  group('getOrElse', () {
    test('returns the value on success', () {
      expect(const Result<int>.success(42).getOrElse(0), 42);
    });

    test('returns the fallback on failure', () {
      expect(const Result<int>.failure(failure).getOrElse(0), 0);
    });
  });

  group('equality', () {
    test('successes with the same value are equal', () {
      expect(const Result<int>.success(42), const Result<int>.success(42));
    });

    test('failures with the same failure are equal', () {
      expect(
        const Result<int>.failure(failure),
        const Result<int>.failure(failure),
      );
    });

    test('a success and a failure are never equal', () {
      expect(
        const Result<int>.success(42),
        isNot(const Result<int>.failure(failure)),
      );
    });
  });

  group('exhaustive pattern matching', () {
    test('switch over the sealed union covers both cases', () {
      String describe(Result<int> result) => switch (result) {
        Success<int>(:final value) => 'ok:$value',
        Failed<int>(:final failure) => 'err:${failure.runtimeType}',
      };

      expect(describe(const Result<int>.success(1)), 'ok:1');
      expect(describe(const Result<int>.failure(failure)), startsWith('err:'));
    });
  });
}
