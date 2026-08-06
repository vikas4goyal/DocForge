/// Fails when the retired DocForge identity leaks into active project files.
///
/// Legacy spelling remains necessary in the migration that discovers existing
/// installations and in archived OpenSpec history. Everything else must use
/// DocScanly so UI, diagnostics, package imports, and platform identities agree.
library;

import 'dart:io';

/// Spellings that belong only to the retired product identity.
const retiredBrandTokens = <String>['DocForge', 'Doc Forge', 'doc_forge'];

/// Paths intentionally excluded from active-brand enforcement.
const excludedBrandPathPrefixes = <String>[
  '.dart_tool/',
  '.git/',
  '.idea/',
  'android/.idea/',
  'build/',
  'ios/Flutter/flutter_export_environment.sh',
  'ios/fastlane/README.md',
  'openspec/changes/archive/',
  'openspec/changes/add-icloud-library-sync/',
  'openspec/specs/',
];

/// Files allowed to name the retired product solely for data migration.
const legacyBrandFiles = <String>{
  'lib/features/document_library/infrastructure/library_storage_migration.dart',
  'test/features/document_library/library_storage_migration_test.dart',
  'lib/core/storage/legacy_public_library_migration.dart',
  'test/core/storage/legacy_public_library_migration_test.dart',
  'android/app/src/main/kotlin/com/bruxkey/docscanly/LegacyMediaStoreMigration.kt',
  // The checker and its tests must spell the tokens they reject.
  'tool/check_branding.dart',
  'test/tool/check_branding_test.dart',
};

/// Text extensions inspected by [findRetiredBrandOccurrences].
const checkedBrandExtensions = <String>{
  '.dart',
  '.gradle',
  '.kts',
  '.kt',
  '.md',
  '.plist',
  '.storyboard',
  '.swift',
  '.xml',
  '.yaml',
  '.yml',
  '.json',
  '.rb',
  '.sh',
};

/// Returns non-allowlisted retired-brand occurrences below [root].
List<String> findRetiredBrandOccurrences(Directory root) {
  final violations = <String>[];
  if (!root.existsSync()) return violations;

  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = entity.path
        .substring(root.path.length)
        .replaceFirst(RegExp(r'^[/\\]+'), '')
        .replaceAll('\\', '/');
    if (excludedBrandPathPrefixes.any(relative.startsWith) ||
        legacyBrandFiles.contains(relative) ||
        !_hasCheckedExtension(relative)) {
      continue;
    }

    final lines = entity.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      if (retiredBrandTokens.any(lines[index].contains)) {
        violations.add('$relative:${index + 1}');
      }
    }
  }
  return violations..sort();
}

bool _hasCheckedExtension(String path) =>
    checkedBrandExtensions.any(path.endsWith);

/// Runs the active-brand check and exits non-zero on any violation.
void main() {
  final violations = findRetiredBrandOccurrences(Directory('.'));
  if (violations.isEmpty) {
    stdout.writeln('Brand check passed: active files use DocScanly.');
    return;
  }

  stderr.writeln('Brand check FAILED — retired identity found:');
  for (final violation in violations) {
    stderr.writeln('  - $violation');
  }
  exitCode = 1;
}
