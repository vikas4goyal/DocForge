import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_coverage.dart';

/// Builds a minimal LCOV record for [path] with [found] and [hit] line counts.
String record(String path, int found, int hit) =>
    'SF:$path\nLF:$found\nLH:$hit\nend_of_record\n';

void main() {
  group('Coverage', () {
    test('computes a percentage', () {
      const coverage = Coverage(found: 200, hit: 150);

      expect(coverage.percentage, 75.0);
    });

    test('treats an empty set as fully covered', () {
      const coverage = Coverage(found: 0, hit: 0);

      expect(coverage.percentage, 100.0);
    });
  });

  group('isGenerated', () {
    test('identifies generated sources', () {
      expect(isGenerated('lib/x.g.dart'), isTrue);
      expect(isGenerated('lib/x.freezed.dart'), isTrue);
      expect(isGenerated('lib/x.mocks.dart'), isTrue);
    });

    test('does not flag hand-written sources', () {
      expect(isGenerated('lib/x.dart'), isFalse);
    });
  });

  group('isBusinessLogic', () {
    test('matches application and domain layers', () {
      expect(
        isBusinessLogic('lib/features/ocr/application/usecases/recognise.dart'),
        isTrue,
      );
      expect(
        isBusinessLogic('lib/features/ocr/domain/entities/text.dart'),
        isTrue,
      );
    });

    test('does not match presentation or infrastructure', () {
      expect(
        isBusinessLogic('lib/features/ocr/presentation/screens/s.dart'),
        isFalse,
      );
      expect(
        isBusinessLogic('lib/features/ocr/infrastructure/datasource/d.dart'),
        isFalse,
      );
    });
  });

  group('parseLcov', () {
    test('totals every record when including all files', () {
      final lcov =
          record('lib/a.dart', 100, 80) + record('lib/b.dart', 100, 90);

      final coverage = parseLcov(lcov, include: (_) => true);

      expect(coverage.found, 200);
      expect(coverage.hit, 170);
      expect(coverage.percentage, 85.0);
    });

    test('excludes generated sources from the totals', () {
      final lcov =
          record('lib/a.dart', 100, 80) +
          record('lib/a.freezed.dart', 900, 900) +
          record('lib/a.g.dart', 900, 900);

      final coverage = parseLcov(lcov, include: (_) => true);

      // Without the exclusion the generated files would lift this to ~98%.
      expect(coverage.found, 100);
      expect(coverage.percentage, 80.0);
    });

    test('filters to the business-logic layers', () {
      final lcov =
          record('lib/features/ocr/domain/entities/text.dart', 100, 95) +
          record('lib/features/ocr/application/usecases/run.dart', 100, 95) +
          record('lib/features/ocr/presentation/screens/s.dart', 100, 10);

      final coverage = parseLcov(lcov, include: isBusinessLogic);

      expect(coverage.found, 200);
      expect(coverage.hit, 190);
      expect(coverage.percentage, 95.0);
    });

    test('handles a final record with no trailing end_of_record', () {
      const lcov = 'SF:lib/a.dart\nLF:10\nLH:5\n';

      final coverage = parseLcov(lcov, include: (_) => true);

      expect(coverage.found, 10);
      expect(coverage.hit, 5);
    });

    test('returns an empty total for empty input', () {
      final coverage = parseLcov('', include: (_) => true);

      expect(coverage.found, 0);
      expect(coverage.percentage, 100.0);
    });
  });

  group('thresholds', () {
    test('match the values mandated by the project context', () {
      expect(overallThreshold, 80.0);
      expect(businessLogicThreshold, 90.0);
    });
  });
}
