/// Enforces the project's two coverage thresholds against `coverage/lcov.info`.
///
/// The project context requires >= 80% overall and >= 90% for business logic.
/// `flutter test --coverage` reports only a single overall figure, so the
/// business-logic gate is computed here by filtering the LCOV records down to
/// `application/` and `domain/` paths — the two layers where the business rules
/// actually live.
///
/// Generated sources are excluded. They are machine-written, frequently large,
/// and counting them would let a big Freezed model silently lift the percentage
/// past a gate that real code had not earned.
///
/// Run with `dart run tool/check_coverage.dart`. Exits 0 when both thresholds
/// are met, 1 otherwise.
library;

import 'dart:io';

/// Minimum acceptable overall line coverage, as a percentage.
const overallThreshold = 80.0;

/// Minimum acceptable line coverage for `application/` and `domain/`.
const businessLogicThreshold = 90.0;

/// Line-coverage totals for a set of source files.
class Coverage {
  /// Creates a coverage total from [hit] covered lines out of [found].
  const Coverage({required this.found, required this.hit});

  /// Total number of instrumented lines.
  final int found;

  /// Number of instrumented lines executed at least once.
  final int hit;

  /// Coverage as a percentage, or 100 when there is nothing to cover.
  ///
  /// An empty set counts as fully covered so that a project which has not yet
  /// written any business logic does not fail the gate before it starts.
  double get percentage => found == 0 ? 100.0 : (hit / found) * 100;

  @override
  String toString() => '${percentage.toStringAsFixed(2)}% ($hit/$found lines)';
}

/// Returns true when [path] is a generated source that must not be counted.
bool isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.mocks.dart');

/// Returns true when [path] belongs to the business-logic layers.
bool isBusinessLogic(String path) =>
    path.contains('/application/') || path.contains('/domain/');

/// Parses [lcov] and returns totals for all files matching [include].
///
/// LCOV records are delimited by `end_of_record`; within a record `SF:` names
/// the source file and `LF:`/`LH:` give its found and hit line counts.
Coverage parseLcov(String lcov, {required bool Function(String) include}) {
  var found = 0;
  var hit = 0;

  var currentFile = '';
  var fileFound = 0;
  var fileHit = 0;

  void flush() {
    if (currentFile.isNotEmpty &&
        !isGenerated(currentFile) &&
        include(currentFile)) {
      found += fileFound;
      hit += fileHit;
    }
    currentFile = '';
    fileFound = 0;
    fileHit = 0;
  }

  for (final line in lcov.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('SF:')) {
      currentFile = trimmed.substring(3);
    } else if (trimmed.startsWith('LF:')) {
      fileFound = int.tryParse(trimmed.substring(3)) ?? 0;
    } else if (trimmed.startsWith('LH:')) {
      fileHit = int.tryParse(trimmed.substring(3)) ?? 0;
    } else if (trimmed == 'end_of_record') {
      flush();
    }
  }
  // Tolerate a final record with no trailing end_of_record marker.
  flush();

  return Coverage(found: found, hit: hit);
}

/// Checks both thresholds and exits non-zero when either is unmet.
void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln(
      'Coverage check FAILED: coverage/lcov.info not found. '
      'Run `flutter test --coverage` first.',
    );
    exit(1);
  }

  final lcov = file.readAsStringSync();
  final overall = parseLcov(lcov, include: (_) => true);
  final business = parseLcov(lcov, include: isBusinessLogic);

  stdout
    ..writeln('Overall coverage:        $overall')
    ..writeln('Business-logic coverage: $business');

  final failures = <String>[];
  if (overall.percentage < overallThreshold) {
    failures.add(
      'Overall coverage ${overall.percentage.toStringAsFixed(2)}% '
      'is below the required $overallThreshold%.',
    );
  }
  if (business.percentage < businessLogicThreshold) {
    failures.add(
      'Business-logic coverage ${business.percentage.toStringAsFixed(2)}% '
      'is below the required $businessLogicThreshold%.',
    );
  }

  if (failures.isEmpty) {
    stdout.writeln('Coverage check passed.');
    return;
  }

  stderr.writeln('\nCoverage check FAILED:');
  for (final failure in failures) {
    stderr.writeln('  - $failure');
  }
  exit(1);
}
