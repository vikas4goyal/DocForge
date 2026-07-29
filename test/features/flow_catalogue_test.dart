/// Tier 1 — the flow catalogue and the flow files agree.
///
/// `openspec/config.yaml` names the journeys every change is expected to keep
/// covered, and an agent planning a change reads that list to decide which
/// flows it has to update. The list is only worth reading if it is true.
///
/// Checked in both directions deliberately. A catalogued journey with no file
/// is a coverage claim nothing backs; a file with no catalogue entry is a flow
/// nobody planning a change will know to update, which is how a suite starts
/// rotting.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Turns a catalogue entry into the flow file name it implies.
///
/// Purely mechanical: drop the parenthetical gloss the catalogue writes for a
/// human — "organise (rename/favourite/move/archive/delete)" — lower-case the
/// rest and join the words with underscores.
///
/// Deliberately has no special cases. A mapping that knew "settings and app
/// lock" really meant `settings_and_lock` would be a second place the two can
/// disagree, and the whole point here is that they cannot. When a name does not
/// line up, the fix is to rename the file, not to teach this function about it.
String fileNameFor(String entry) {
  final words = entry
      .replaceAll(RegExp(r'\(.*?\)'), ' ')
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((word) => word.isNotEmpty);

  return '${words.join('_')}_test.dart';
}

/// The journeys named in the project context's catalogue.
List<String> catalogueEntries() {
  final config = File('openspec/config.yaml').readAsStringSync();
  final start = config.indexOf('Catalogue:');
  expect(start, isNot(-1), reason: 'config.yaml has no flow catalogue');

  // The entry runs to the blank line that ends the paragraph.
  final end = config.indexOf('\n\n', start);
  final block = config.substring(start + 'Catalogue:'.length, end);

  return block
      .replaceAll('\n', ' ')
      .split(';')
      .map((entry) => entry.replaceAll('.', '').trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
}

/// The flow files that actually exist.
List<String> flowFileNames() =>
    (Directory('integration_test/flows')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name.endsWith('_test.dart'))
          .toList())
      ..sort();

void main() {
  test('the catalogue names something', () {
    // Guards the two tests below: a parse that silently returned nothing would
    // make both of them vacuously pass.
    expect(catalogueEntries(), hasLength(greaterThan(5)));
    expect(flowFileNames(), hasLength(greaterThan(5)));
  });

  test('every catalogued journey has a flow file', () {
    final files = flowFileNames().toSet();

    final missing = [
      for (final entry in catalogueEntries())
        if (!files.contains(fileNameFor(entry)))
          '$entry  →  expected integration_test/flows/${fileNameFor(entry)}',
    ];

    expect(
      missing,
      isEmpty,
      reason:
          'These journeys are catalogued as covered and have no flow. The '
          'catalogue is what an agent reads to decide what to update, so an '
          'entry with nothing behind it is a coverage claim nothing '
          'backs:\n${missing.join('\n')}',
    );
  });

  test('every flow file is a catalogued journey', () {
    final expected = catalogueEntries().map(fileNameFor).toSet();

    final uncatalogued = flowFileNames()
        .where((name) => !expected.contains(name))
        .toList();

    expect(
      uncatalogued,
      isEmpty,
      reason:
          'These flows exist and are not catalogued, so nobody planning a '
          'change will know to update them — which is how a suite starts '
          'rotting:\n${uncatalogued.join('\n')}',
    );
  });
}
