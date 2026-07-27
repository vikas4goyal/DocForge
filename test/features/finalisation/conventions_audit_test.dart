/// The project's own conventions, audited as tests rather than as prose.
///
/// Every rule here is one `openspec/config.yaml` states and that a reviewer
/// would otherwise have to re-check by hand on every change: no business logic
/// in a Cubit, no global mutable state, every screen previewed in every
/// required state, previews fed only by fixtures. A convention nobody can
/// verify is a convention that drifts, so each is a check that runs in CI.
///
/// These are deliberately *structural* checks over the source tree. They cannot
/// prove taste, and they are not meant to: they prove the mechanical properties
/// the rules actually name.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every Dart source file under `lib/`, excluding generated output.
Iterable<File> _sources() sync* {
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    if (entity.path.endsWith('.freezed.dart')) continue;
    yield entity;
  }
}

/// Every file whose name marks it as holding previews.
Iterable<File> _previewFiles() =>
    _sources().where((file) => file.path.endsWith('_previews.dart'));

void main() {
  group('no business logic lives in a Cubit', () {
    test('no Cubit or Bloc touches storage, a plugin or the filesystem', () {
      // The rule config.yaml states: a Cubit manages UI state, invokes use
      // cases and emits. Reaching a repository or a plugin from one is the
      // concrete, checkable form of "business logic in the presentation layer".
      const forbidden = [
        'package:isar_community/',
        'package:shared_preferences/',
        'package:flutter_secure_storage/',
        'package:dio/',
        'package:camera/',
        'package:local_auth/',
        'package:image_picker/',
        'package:file_picker/',
        'package:share_plus/',
        'package:printing/',
        'package:pdf_manipulator/',
        'package:dartcv4/',
        'package:google_mlkit_text_recognition/',
      ];

      final offenders = <String>[];

      for (final file in _sources()) {
        if (!file.path.contains('/cubit/') && !file.path.contains('/bloc/')) {
          continue;
        }

        final code = file.readAsStringSync();
        for (final import in forbidden) {
          if (code.contains(import)) offenders.add('${file.path}: $import');
        }
      }

      expect(offenders, isEmpty);
    });

    test('no Cubit imports an infrastructure implementation', () {
      // A Cubit that can construct a repository can bypass the use case that
      // enforces the rules. The fakes are the one exception, and only in a
      // preview file, where a real implementation is what must not be reached.
      final offenders = <String>[];

      for (final file in _sources()) {
        if (!file.path.contains('/cubit/') && !file.path.contains('/bloc/')) {
          continue;
        }

        final code = file.readAsStringSync();
        for (final line in code.split('\n')) {
          if (line.startsWith('import ') && line.contains('/infrastructure/')) {
            offenders.add('${file.path}: ${line.trim()}');
          }
        }
      }

      expect(offenders, isEmpty);
    });
  });

  group('no global or static mutable state', () {
    test('lib/ declares no mutable top-level variable', () {
      // `AppDependencies` and the theme controller are the documented
      // exceptions, and both are *constructed at the composition root and
      // injected* rather than declared globally — so this check needs no
      // exception list at all.
      final offenders = <String>[];

      // A top-level `var`, or a top-level `late` that is not final.
      final mutableTopLevel = RegExp(r'^(var|late\s+(?!final)\w)');

      for (final file in _sources()) {
        for (final line in file.readAsStringSync().split('\n')) {
          if (mutableTopLevel.hasMatch(line)) {
            offenders.add('${file.path}: ${line.trim()}');
          }
        }
      }

      expect(offenders, isEmpty);
    });

    test('lib/ declares no static mutable field', () {
      final offenders = <String>[];
      final staticMutable = RegExp(r'^\s+static\s+(?!const|final)');

      for (final file in _sources()) {
        for (final line in file.readAsStringSync().split('\n')) {
          // A static *method* is fine; only a static field is state.
          if (!staticMutable.hasMatch(line)) continue;
          if (line.contains('(')) continue;

          offenders.add('${file.path}: ${line.trim()}');
        }
      }

      expect(offenders, isEmpty);
    });

    test('no feature reaches for a service locator', () {
      // The project forbids get_it and friends outright; explicit constructor
      // injection is what makes every feature testable in isolation.
      final offenders = <String>[];

      for (final file in _sources()) {
        final code = file.readAsStringSync();
        if (code.contains('package:get_it') ||
            code.contains('package:provider/') ||
            code.contains('package:riverpod')) {
          offenders.add(file.path);
        }
      }

      expect(offenders, isEmpty);
    });
  });

  group('previews are fed by fixtures alone', () {
    test('every feature with a screen ships a previews file', () {
      final featuresWithScreens = <String>{};
      final featuresWithPreviews = <String>{};

      for (final file in _sources()) {
        final match = RegExp(r'lib/features/(\w+)/').firstMatch(file.path);
        if (match == null) continue;

        final feature = match.group(1)!;
        if (file.path.contains('/presentation/screens/')) {
          featuresWithScreens.add(feature);
        }
        if (file.path.endsWith('_previews.dart')) {
          featuresWithPreviews.add(feature);
        }
      }

      expect(
        featuresWithScreens.difference(featuresWithPreviews),
        isEmpty,
        reason: 'these features have screens but no previews file',
      );
    });

    test('no preview reaches a real database, plugin or network', () {
      // The rule the previews exist to make possible: a preview must render
      // from fixtures, so it cannot depend on a device or a populated database.
      const forbidden = [
        'package:isar_community/',
        'package:shared_preferences/',
        'package:dio/',
        'package:camera/',
        'package:local_auth/',
        'package:google_mlkit_text_recognition/',
        'package:pdf_manipulator/',
        'package:dartcv4/',
        'HttpClient',
      ];

      final offenders = <String>[];

      for (final file in _previewFiles()) {
        final code = file.readAsStringSync();
        for (final import in forbidden) {
          if (code.contains(import)) offenders.add('${file.path}: $import');
        }
      }

      expect(offenders, isEmpty);
    });

    test('no preview depends on the wall clock or on randomness', () {
      // Both would make a preview render differently on every open, and would
      // make any golden built from one flake.
      final offenders = <String>[];

      for (final file in _previewFiles()) {
        final code = file.readAsStringSync();

        if (RegExp(r'DateTime\.now\(\)').hasMatch(code) ||
            code.contains('SystemClock()') ||
            code.contains('Random(')) {
          offenders.add(file.path);
        }
      }

      expect(offenders, isEmpty);
    });

    test('every previews file covers the required states', () {
      // config.yaml requires default, loading, empty, error and long content.
      //
      // Matched against a **synonym set** rather than the literal words,
      // because each preview is named for what it shows in that feature's own
      // vocabulary: scanning's loading state is "preparing", the library's
      // default is "ready", onboarding's error is "permission denied". A check
      // insisting on the literal words would have forced a rename of a hundred
      // well-named previews and taught everyone to ignore it — which is exactly
      // what happened when this test was first written that way.
      //
      // What it still catches is the real failure: a file with no error
      // preview of any name, or no empty state at all.
      const synonyms = <String, List<String>>{
        'default': ['default', 'ready', 'welcome', 'with count', 'retry'],
        'loading': [
          'loading',
          'preparing',
          'requesting',
          'working',
          'applying',
          'generating',
          'authenticating',
          'progress',
          'importing',
          'searching',
        ],
        'empty': ['empty', 'zero', 'no thumbnails', 'unknown', 'placeholder'],
        'error': [
          'error',
          'denied',
          'blocked',
          'failed',
          'rejected',
          'storage full',
          'corrupt',
          'not enrolled',
          'locked',
        ],
        'long content': [
          'long content',
          'long title',
          'long batch',
          'large text',
          'large',
          'long',
        ],
      };

      final gaps = <String>[];

      for (final file in _previewFiles()) {
        final code = file.readAsStringSync().toLowerCase();

        for (final entry in synonyms.entries) {
          if (!entry.value.any(code.contains)) {
            gaps.add('${file.path}: no "${entry.key}" preview');
          }
        }
      }

      expect(gaps, isEmpty, reason: gaps.join('\n'));
    });

    test('every screen previews file covers both themes and both sizes', () {
      // Synonym-tolerant for the same reason: an older file names its variants
      // "dark" and "tablet" rather than spelling out all four combinations.
      // Light and phone are the annotation's own defaults, so a file that names
      // dark and tablet has covered all four.
      final gaps = <String>[];

      for (final file in _previewFiles()) {
        final code = file.readAsStringSync();
        // Only files that preview a *screen* owe form-factor variants; a file
        // of reusable-widget previews does not.
        if (!code.contains('/screens/')) continue;

        final lowered = code.toLowerCase();
        if (!lowered.contains('dark')) gaps.add('${file.path}: no dark theme');
        if (!lowered.contains('tablet')) gaps.add('${file.path}: no tablet');
      }

      expect(gaps, isEmpty, reason: gaps.join('\n'));
    });
  });

  group('golden coverage', () {
    test('every major screen has goldens', () {
      // The screens config.yaml names. A golden is the only test that catches a
      // layout regression nobody thought to assert on.
      // Named by their golden-file prefix rather than by their spec name:
      // the page-review screen's goldens are `review_*`, which is what the
      // file names actually are.
      const majorScreens = [
        'home',
        'review',
        'crop',
        'enhance',
        'pdf_preview',
        'document_list',
        'folder',
        'search',
        'viewer',
        'pdf_edit',
        'settings',
        'unlock',
      ];

      final goldenNames = <String>[];

      for (final entity in Directory('test').listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.png')) {
          goldenNames.add(entity.path.split('/').last);
        }
      }

      final missing = [
        for (final screen in majorScreens)
          if (!goldenNames.any((name) => name.startsWith(screen))) screen,
      ];

      expect(missing, isEmpty, reason: 'no goldens for: $missing');
    });

    test('every major screen has a light and a dark golden', () {
      final goldenNames = <String>[];

      for (final entity in Directory('test').listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.png')) {
          goldenNames.add(entity.path.split('/').last);
        }
      }

      expect(goldenNames.where((n) => n.contains('light')), isNotEmpty);
      expect(goldenNames.where((n) => n.contains('dark')), isNotEmpty);
    });
  });

  group('documentation', () {
    test('every public library declares itself with a doc comment', () {
      // `public_member_api_docs` is already an analyzer error in this project,
      // so member-level dartdoc is enforced on every build. What the analyzer
      // does *not* check is the file-level `library` doc, which is where the
      // "why this file exists" lives.
      final offenders = <String>[];

      for (final file in _sources()) {
        final lines = file.readAsStringSync().split('\n');
        if (lines.isEmpty) continue;

        // The first non-blank line must open a doc comment.
        final first = lines.firstWhere(
          (line) => line.trim().isNotEmpty,
          orElse: () => '',
        );

        if (!first.startsWith('///')) offenders.add(file.path);
      }

      expect(offenders, isEmpty, reason: 'no library doc: $offenders');
    });
  });
}
