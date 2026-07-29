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
/// 4. Nothing reachable from production `main.dart` may name a `Fake*` platform
///    implementation, or import anything outside `lib/`. The fakes deliberately
///    live in `lib/` because the widget previews need them there, so this rule
///    is the only thing standing between that convenience and shipping a fake
///    to a user (`design.md` D8).
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

/// Converts a `package:doc_forge/...` URI to its path under `lib/`.
///
/// Returns null for a URI that leaves the package — `dart:`, another package,
/// or a relative import — because those are not part of the graph this rule
/// walks.
String? libPathOf(String importPath) {
  const prefix = 'package:doc_forge/';
  if (!importPath.startsWith(prefix)) return null;
  return 'lib/${importPath.substring(prefix.length)}';
}

/// Strips comments from [content] so a rule reads code and not prose.
///
/// Required rather than cosmetic: the composition root documents which fake a
/// test substitutes, and a rule that matched on the doc comment would report
/// the explanation of the rule as a breach of it.
String withoutComments(String content) {
  final withoutBlocks = content.replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );

  return withoutBlocks
      .split('\n')
      .map((line) {
        // Only a comment that starts the line, so a `//` inside a string
        // literal — a URL, most often — does not truncate real code.
        final trimmed = line.trimLeft();
        return trimmed.startsWith('//') ? '' : line;
      })
      .join('\n');
}

/// Returns every file reachable from [entrypoint] by following imports.
///
/// [sources] maps a path under `lib/` to its content. Only intra-package
/// imports are followed; a URI pointing outside the package ends that branch,
/// and an import naming a file absent from [sources] is skipped rather than
/// failing, so the walk describes the graph it can see.
Set<String> reachableFrom(String entrypoint, Map<String, String> sources) {
  final seen = <String>{};
  final pending = <String>[entrypoint];

  while (pending.isNotEmpty) {
    final path = pending.removeLast();
    if (!seen.add(path)) continue;

    final content = sources[path];
    if (content == null) continue;

    for (final line in content.split('\n')) {
      final match = _directive.firstMatch(line);
      if (match == null) continue;
      final target = libPathOf(match.group(1)!);
      if (target != null && !seen.contains(target)) pending.add(target);
    }
  }

  return seen;
}

/// Matches a reference to a fake implementation.
///
/// Anchored on a word boundary so `buildFakeAppDependencies` — a builder whose
/// name merely contains the word — is not mistaken for a fake type.
final RegExp _fakeReference = RegExp(r'\bFake[A-Z]\w*');

/// Checks that production [entrypoint] cannot reach a fake.
///
/// Walks the import graph from [entrypoint] through [sources] and reports two
/// things: a file that names a `Fake*` type it does not itself declare, and an
/// import that leaves `lib/` — which is how a test-only entrypoint would get
/// into a release build.
///
/// A file that declares a fake may name it: that is the declaration, and the
/// fakes have to live somewhere. What the rule forbids is production code
/// *using* one, which is the mistake that would actually reach a user.
List<LayeringViolation> checkProductionEntrypoint({
  required String entrypoint,
  required Map<String, String> sources,
}) {
  final violations = <LayeringViolation>[];

  for (final path in reachableFrom(entrypoint, sources).toList()..sort()) {
    final content = sources[path];
    if (content == null) continue;

    final code = withoutComments(content);
    final declared = RegExp(
      r'\bclass\s+(Fake[A-Z]\w*)',
    ).allMatches(code).map((match) => match.group(1)!).toSet();

    final lines = code.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final directive = _directive.firstMatch(lines[i]);
      if (directive != null) {
        final target = directive.group(1)!;
        if (target.startsWith('package:doc_forge/') ||
            target.startsWith('dart:') ||
            target.startsWith('package:')) {
          continue;
        }

        violations.add(
          LayeringViolation(
            file: path,
            line: i + 1,
            importPath: target,
            rule:
                'production main.dart must not reach outside lib/ — '
                'a test-only entrypoint cannot be in a release build',
          ),
        );
        continue;
      }

      for (final match in _fakeReference.allMatches(lines[i])) {
        final name = match.group(0)!;
        if (declared.contains(name)) continue;

        violations.add(
          LayeringViolation(
            file: path,
            line: i + 1,
            importPath: name,
            rule:
                'production main.dart must not reach $name — '
                'fakes live in lib/ for the previews and must not ship',
          ),
        );
      }
    }
  }

  return violations;
}

/// Reads every Dart file under [root] into a path-to-content map.
Map<String, String> readSources(Directory root) {
  final sources = <String, String>{};
  if (!root.existsSync()) return sources;

  for (final file in root.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    // Normalised to a repository-relative path, because that is what an import
    // resolves to and what a violation should name.
    final index = file.path.indexOf('lib/');
    final path = index == -1 ? file.path : file.path.substring(index);
    sources[path] = file.readAsStringSync();
  }

  return sources;
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
  final violations = [
    ...checkDirectory(Directory('lib')),
    ...checkProductionEntrypoint(
      entrypoint: 'lib/main.dart',
      sources: readSources(Directory('lib')),
    ),
  ];

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
