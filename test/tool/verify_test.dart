/// Tier 1 — the verification gate's own reporting.
///
/// The gate exists so an agent can act on its output without reading device
/// logs. Two things about it have to be true, and neither is obvious from
/// reading it:
///
/// 1. The stages run cheapest-first and stop at the first failure, so a
///    misplaced brace is reported in seconds rather than after a device run.
/// 2. A run with no device reports INCOMPLETE and exits non-zero — never
///    PASSED. That is the one behaviour that, if it broke, would let an agent
///    ship precisely the kind of failure this whole change exists to catch.
library;

import 'package:flutter_test/flutter_test.dart';

import '../../tool/verify.dart';

/// A stage report with the fields a summary actually reads.
StageReport reportOf(
  String name,
  StageResult result, {
  int seconds = 1,
  String? detail,
}) => StageReport(
  name: name,
  result: result,
  duration: Duration(seconds: seconds),
  detail: detail,
);

void main() {
  group('stage ordering', () {
    test('runs the cheapest checks before the expensive ones', () {
      final names = hostStages.map((stage) => stage.name).toList();

      // Format and analysis are seconds; the test tiers are a minute. Ordering
      // them the other way would mean waiting a minute to be told about a
      // formatting change.
      expect(names.indexOf('format'), lessThan(names.indexOf('analyze')));
      expect(
        names.indexOf('analyze'),
        lessThan(names.indexOf('tier 1 + tier 2')),
      );
      expect(
        names.indexOf('tier 1 + tier 2'),
        lessThan(names.indexOf('coverage')),
      );
    });

    test('checks layering and platforms before running any test', () {
      final names = hostStages.map((stage) => stage.name).toList();

      // Both are structural: a repository that has broken its own layering has
      // nothing useful to say about its behaviour yet.
      expect(
        names.indexOf('layering'),
        lessThan(names.indexOf('tier 1 + tier 2')),
      );
      expect(
        names.indexOf('platforms'),
        lessThan(names.indexOf('tier 1 + tier 2')),
      );
    });

    test('every stage names a command that can actually be run', () {
      for (final stage in hostStages) {
        expect(
          stage.executable,
          isNotEmpty,
          reason: '${stage.name} has no command',
        );
        expect(
          stage.arguments,
          isNotEmpty,
          reason: '${stage.name} has no arguments',
        );
      }
    });
  });

  group('the summary', () {
    test('passes only when every stage ran and succeeded', () {
      final code = report([
        reportOf('analyze', StageResult.passed),
        reportOf('tier 1 + tier 2', StageResult.passed),
        reportOf('flow: import', StageResult.passed),
      ]);

      expect(code, 0);
    });

    test('fails, non-zero, when a stage failed', () {
      final code = report([
        reportOf('analyze', StageResult.passed),
        reportOf('tier 1 + tier 2', StageResult.failed, detail: 'exit code 1'),
      ]);

      expect(code, isNot(0));
    });

    test('a failure outranks a skip', () {
      // Both present: a run that failed *and* could not reach the device is a
      // failure. Reporting it as merely incomplete would bury the real result.
      final code = report([
        reportOf('analyze', StageResult.failed),
        reportOf('tier 3 (flows)', StageResult.skipped, detail: 'no device'),
      ]);

      expect(code, 1);
    });

    test('a device-less run is incomplete, and never a pass', () {
      final code = report([
        reportOf('format', StageResult.passed),
        reportOf('analyze', StageResult.passed),
        reportOf('tier 1 + tier 2', StageResult.passed),
        reportOf('tier 3 (flows)', StageResult.skipped, detail: 'no device'),
      ]);

      // Non-zero even though nothing failed. Every host stage passing is not
      // the same as the change working, and this is the distinction the whole
      // gate exists to preserve.
      expect(
        code,
        isNot(0),
        reason:
            'A run that never drove the application on a device must not exit '
            'zero — that is exactly how a broken flow ships past a green CI.',
      );
      expect(code, 2, reason: 'incomplete is distinct from failed');
    });
  });

  group('stage reporting', () {
    test('a line names the stage, its result and its cost', () {
      final line = reportOf(
        'flow: import',
        StageResult.passed,
        seconds: 12,
      ).line;

      expect(line, contains('PASS'));
      expect(line, contains('flow: import'));
      // Per-stage timing, so a stage that gets slower is visible rather than
      // absorbed into a total that only creeps upward.
      expect(line, contains('12.0'));
    });

    test('a failing line carries the detail explaining it', () {
      final line = reportOf(
        'analyze',
        StageResult.failed,
        detail: 'exit code 1',
      ).line;

      expect(line, contains('FAIL'));
      expect(line, contains('exit code 1'));
    });

    test('a skipped line says why it was skipped', () {
      final line = reportOf(
        'tier 3 (flows)',
        StageResult.skipped,
        detail: 'no Android device or iOS simulator attached',
      ).line;

      expect(line, contains('SKIP'));
      expect(line, contains('no Android device'));
    });
  });

  group('the flow suite', () {
    test('finds a stage per flow file, so a failure names the flow', () {
      final flows = flowFiles();

      expect(
        flows,
        isNotEmpty,
        reason: 'integration_test/flows/ should hold the catalogued journeys',
      );
      for (final file in flows) {
        expect(file.path, endsWith('_test.dart'));
      }
    });
  });
}
