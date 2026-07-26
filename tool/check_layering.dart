/// Enforces the feature-first clean architecture import rules in CI.
///
/// The architecture in `design.md` §1 is only real if something checks it, so
/// this script walks the source tree and fails the build on any violation of
/// the three rules the layering depends on:
///
/// 1. `domain/` must not import Flutter — the domain layer is pure Dart and
///    depends on nothing, which is what keeps it testable without a binding.
/// 2. `application/` must not import `infrastructure/` — use cases depend on
///    domain interfaces, never on the implementations behind them.
/// 3. No file under `features/<a>/` may import `features/<b>/` — cross-feature
///    cooperation goes through `core/contracts/` (see `design.md` §2).
///
/// Run with `dart run tool/check_layering.dart`. Exits 0 when clean and 1 when
/// any violation is found, printing every violation rather than only the first
/// so a single run tells the whole story.
library;

import 'dart:io';

/// A single import-rule violation found in the source tree.
class LayeringViolation {
  /// Creates a violation describing [rule] broken at [file] line [line].
  const LayeringViolation({
    required this.file,
    required this.line,
    required this.importPath,
    required this.rule,
  });

  /// Path of the offending file, relative to the package root.
  final String file;

  /// 1-indexed line number of the offending import directive.
  final int line;

  /// The imported URI that broke the rule.
  final String importPath;

  /// Human-readable description of the rule that was broken.
  final String rule;

  @override
  String toString() => '$file:$line  $rule\n    import \'$importPath\'';
}

/// Matches a Dart `import` or `export` directive and captures its URI.
///
/// Both are checked: an `export` leaks a dependency just as effectively as an
/// `import`, and exporting across a layer boundary is the easier mistake to
/// miss in review.
final RegExp _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
);

/// Extracts the feature name from a path under `lib/features/`.
///
/// Returns `null` when [path] does not live inside a feature, which is the
/// normal case for `lib/core/` and `lib/app/` files.
String? featureOf(String path) {
  final match = RegExp(r'(?:^|/)lib/features/([^/]+)/').firstMatch(path);
  return match?.group(1);
}

/// Extracts the feature name from a `package:doc_forge/features/<name>/...` URI.
///
/// Returns `null` for any URI that does not target a feature.
String? importedFeatureOf(String importPath) {
  final match = RegExp(
    r'^package:doc_forge/features/([^/]+)/',
  ).firstMatch(importPath);
  return match?.group(1);
}

/// Checks a single file's [content] against the three layering rules.
///
/// [path] is used both to report the violation and to determine which layer and
/// feature the file belongs to. Returns every violation found in the file.
List<LayeringViolation> checkFile(String path, String content) {
  final violations = <LayeringViolation>[];

  // Generated files reproduce whatever their source annotations imply and are
  // not hand-maintained, so holding them to the import rules would produce
  // noise no one can act on.
  if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
    return violations;
  }

  final inDomain = path.contains('/domain/');
  final inApplication = path.contains('/application/');
  final ownFeature = featureOf(path);

  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final match = _directive.firstMatch(lines[i]);
    if (match == null) continue;
    final importPath = match.group(1)!;
    final lineNumber = i + 1;

    if (inDomain &&
        (importPath.startsWith('package:flutter/') ||
            importPath.startsWith('package:flutter_bloc/'))) {
      violations.add(
        LayeringViolation(
          file: path,
          line: lineNumber,
          importPath: importPath,
          rule: 'domain/ must not import Flutter',
        ),
      );
    }

    if (inApplication && importPath.contains('/infrastructure/')) {
      violations.add(
        LayeringViolation(
          file: path,
          line: lineNumber,
          importPath: importPath,
          rule: 'application/ must not import infrastructure/',
        ),
      );
    }

    final importedFeature = importedFeatureOf(importPath);
    if (ownFeature != null &&
        importedFeature != null &&
        importedFeature != ownFeature) {
      violations.add(
        LayeringViolation(
          file: path,
          line: lineNumber,
          importPath: importPath,
          rule:
              'feature "$ownFeature" must not import feature '
              '"$importedFeature" — use core/contracts/',
        ),
      );
    }
  }

  return violations;
}

/// Walks [root] and returns every layering violation in its Dart sources.
List<LayeringViolation> checkDirectory(Directory root) {
  final violations = <LayeringViolation>[];
  if (!root.existsSync()) return violations;

  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        // Sort so CI output is stable between runs and diffable.
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    violations.addAll(checkFile(file.path, file.readAsStringSync()));
  }
  return violations;
}

/// Runs the layering check over `lib/` and exits non-zero on any violation.
void main() {
  final violations = checkDirectory(Directory('lib'));

  if (violations.isEmpty) {
    stdout.writeln('Layering check passed: no violations found.');
    return;
  }

  stderr.writeln(
    'Layering check FAILED — ${violations.length} violation(s):\n',
  );
  for (final violation in violations) {
    stderr.writeln('$violation\n');
  }
  exit(1);
}
