/// Tier 1 — the widget-key registries.
///
/// The end-to-end suite drives the application entirely through the keys
/// declared in `lib/**/*_keys.dart`. That makes the registries a contract, and
/// a contract only holds if something checks both halves of it:
///
/// 1. Every key a registry declares is actually applied to a widget. A key that
///    is declared and never used is a flow waiting to time out on something
///    that was never there.
/// 2. No widget is keyed with an inline `Key('...')` literal. A key outside the
///    registry cannot be found by a flow that reads the registry, and it drifts
///    the moment either side is renamed.
///
/// Checked statically rather than by mounting every screen: many keys belong to
/// a loading, empty or error state that a single mounted screen never reaches,
/// so a tree-based check would either miss them or demand every screen be built
/// in every state — which is the component tier's job, not this one's.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A key declared by a registry.
typedef DeclaredKey = ({String registry, String member, String file});

/// Matches a `static const name = Key('value');` declaration.
final _constKey = RegExp(r'static\s+const\s+(\w+)\s*=\s*Key\(');

/// Matches a `static Key name(...)` factory, used for keys carrying an id.
final _keyFactory = RegExp(r'static\s+Key\s+(\w+)\s*\(');

/// Matches the registry class a declaration belongs to.
final _registryClass = RegExp(r'abstract\s+final\s+class\s+(\w+Keys)\s*\{');

/// Matches an inline key literal, which the registries exist to replace.
final _inlineKey = RegExp(r"\bKey\(\s*'([^']*)'");

/// Every `*_keys.dart` registry under `lib/`.
List<File> registryFiles() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_keys.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// Every Dart file under `lib/` that could apply a key.
///
/// Includes `lib/app/`, not only the features: the three application-wide
/// wrappers are keyed by the composition root, which is the only place that
/// builds them.
List<File> sourceFiles() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// Returns every key declared across [files], with the registry that owns it.
List<DeclaredKey> declaredKeys(List<File> files) {
  final declared = <DeclaredKey>[];

  for (final file in files) {
    final content = file.readAsStringSync();
    final classes = _registryClass.allMatches(content).toList();

    // A file can hold more than one registry, so each declaration is attributed
    // to the class it sits inside rather than to the file as a whole.
    for (var i = 0; i < classes.length; i++) {
      final registry = classes[i].group(1)!;
      final start = classes[i].end;
      final end = i + 1 < classes.length
          ? classes[i + 1].start
          : content.length;
      final body = content.substring(start, end);

      for (final match in [
        ..._constKey.allMatches(body),
        ..._keyFactory.allMatches(body),
      ]) {
        declared.add((
          registry: registry,
          member: match.group(1)!,
          file: file.path,
        ));
      }
    }
  }

  return declared;
}

void main() {
  final registries = registryFiles();
  final sources = sourceFiles();

  test('there are key registries to check', () {
    // Guards the two tests below: a glob that stopped matching would make both
    // of them vacuously pass and quietly remove the whole contract.
    expect(registries, isNotEmpty);
    expect(declaredKeys(registries), hasLength(greaterThan(100)));
  });

  test('every declared key is applied to a widget', () {
    final registryPaths = registries.map((file) => file.path).toSet();

    // Two corpora, because a key is applied in two different shapes. Most are
    // referenced from a widget as `Registry.member`. A few are selected from
    // inside their own registry — the enhancement filters are chosen by a
    // switch over the enum — where the reference is the bare member name.
    final applied = sources
        .where((file) => !registryPaths.contains(file.path))
        .map((file) => file.readAsStringSync())
        .join('\n');

    // Declarations are stripped first, so a key that only declares itself does
    // not count as a use of itself.
    final withinRegistries = {
      for (final file in registries)
        file.path: file
            .readAsStringSync()
            .replaceAll(_constKey, '')
            .replaceAll(_keyFactory, ''),
    };

    final unused = <String>[];
    for (final key in declaredKeys(registries)) {
      final qualified = applied.contains('${key.registry}.${key.member}');
      final bare = RegExp(
        r'\b' + key.member + r'\b',
      ).hasMatch(withinRegistries[key.file] ?? '');

      if (!qualified && !bare) {
        unused.add('${key.registry}.${key.member}  (${key.file})');
      }
    }

    expect(
      unused,
      isEmpty,
      reason:
          'These keys are declared but never applied. A flow that waits for '
          'one of them would time out on a widget that was never built:\n'
          '${unused.join('\n')}',
    );
  });

  test('no widget is keyed with an inline literal', () {
    final registryPaths = registries.map((file) => file.path).toSet();
    final offenders = <String>[];

    for (final file in sources) {
      if (registryPaths.contains(file.path)) continue;

      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        // A comment naming a key is documentation, not a key the tree carries.
        if (lines[i].trimLeft().startsWith('//')) continue;

        for (final match in _inlineKey.allMatches(lines[i])) {
          offenders.add("${file.path}:${i + 1}  Key('${match.group(1)}')");
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These keys live outside a registry, so a flow reading the registry '
          'cannot find them and a rename breaks silently:\n'
          '${offenders.join('\n')}',
    );
  });
}
