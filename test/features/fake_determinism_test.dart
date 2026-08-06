/// Tier 1 — the determinism rule the flow suite depends on.
///
/// A Tier-3 flow is only worth running if it produces the same result twice.
/// The boot helper proves that for a whole boot on a device; this proves the
/// precondition, in CI, without one: no substituted platform edge may read the
/// wall clock, generate randomness, or open a socket.
///
/// It is a source check rather than a behavioural one deliberately. A
/// behavioural test can only observe that two runs happened to agree, which a
/// clock read that changes once a day would pass all but once. Reading the
/// source catches the capability rather than one of its symptoms.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The fakes the Tier-3 suite substitutes, by the file that declares them.
///
/// Listed explicitly rather than globbed on `Fake*`: this is the set the flow
/// suite actually relies on, and a glob would silently stop covering one that
/// moved.
const _substitutedPlatformFiles = <String>[
  'lib/features/document_scanning/infrastructure/camera_scanner_repository.dart',
  'lib/features/document_scanning/domain/repositories/scanner_repository.dart',
  'lib/features/ocr/infrastructure/repositories/fake_ocr_repository.dart',
  'lib/features/app_security/infrastructure/repositories/local_auth_authenticator.dart',
  'lib/features/document_viewer/infrastructure/repositories/pdfrx_renderer.dart',
  'lib/features/document_sharing/infrastructure/repositories/fake_share_repositories.dart',
  'lib/features/document_import/infrastructure/repositories/fake_import_sources.dart',
  'lib/app/fake_dependencies.dart',
  'integration_test/support/fake_platform.dart',
  'integration_test/support/app_boot.dart',
];

/// Sources of nondeterminism, and why each one is barred.
const _forbidden = <String, String>{
  'DateTime.now':
      'reads the wall clock, so a document created in one run is not '
      'comparable with the next',
  'Random(': 'generates randomness, so two runs diverge',
  'Random.secure': 'generates randomness, so two runs diverge',
  'HttpClient':
      'opens a socket, so the suite depends on a network it should not need',
  'Timer.periodic':
      'schedules against real time, so a slow device changes how many times it '
      'fires',
};

/// Strips comments, so a rule reads code rather than prose.
///
/// The fakes document *why* they avoid the wall clock, and a check that matched
/// those sentences would report the explanation of the rule as a breach of it.
String withoutComments(String content) {
  final withoutBlocks = content.replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );

  return withoutBlocks
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

void main() {
  test('the listed files all exist', () {
    // Guards the test below: a path that stopped resolving would make it
    // vacuously pass and remove the rule without anything saying so.
    for (final path in _substitutedPlatformFiles) {
      expect(
        File(path).existsSync(),
        isTrue,
        reason: '$path is listed as a substituted platform edge but is missing',
      );
    }
  });

  test('no substituted platform edge can vary between runs', () {
    final breaches = <String>[];

    for (final path in _substitutedPlatformFiles) {
      final file = File(path);
      if (!file.existsSync()) continue;

      final lines = withoutComments(file.readAsStringSync()).split('\n');
      for (var i = 0; i < lines.length; i++) {
        for (final entry in _forbidden.entries) {
          if (lines[i].contains(entry.key)) {
            breaches.add('$path:${i + 1}  ${entry.key} — ${entry.value}');
          }
        }
      }
    }

    expect(
      breaches,
      isEmpty,
      reason:
          'A substituted platform edge can vary between runs. The flow suite '
          'assumes it cannot, so the symptom of this is not a failure here but '
          'flows that fail one run in twenty:\n${breaches.join('\n')}',
    );
  });

  test('the fixture assets are checked in', () {
    // The flows feed the application these four files. They are generated
    // shapes and text — no photograph, no scan of anything real — and they are
    // in the repository so a run does not depend on anything being produced
    // first.
    for (final name in [
      'page_one.png',
      'page_two.png',
      'source_document.pdf',
      'importable.pdf',
    ]) {
      final file = File('integration_test/fixtures/$name');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'fixture $name is missing; the flows that feed it will fail',
      );
      expect(
        file.lengthSync(),
        greaterThan(0),
        reason: 'fixture $name is empty',
      );
    }
  });

  test('the fixtures are registered as assets', () {
    // Checked in is not enough: a Tier-3 flow runs on a device, where the asset
    // bundle is the only way to reach a file the repository owns.
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('integration_test/fixtures/'),
      reason:
          'The fixtures are not bundled, so every flow that loads one will '
          'fail on a device with a missing-asset error.',
    );
  });
}
