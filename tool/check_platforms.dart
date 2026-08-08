/// Fails the build if web or desktop support leaks into the project.
///
/// DocScanly targets Android and iOS only. That constraint is easy to violate by
/// accident — `flutter create .` regenerates every platform folder, and a
/// well-meaning dependency addition can pull in a desktop-only plugin — so it is
/// asserted in CI rather than trusted to reviewer memory.
///
/// Two things are checked:
///
/// 1. No `web/`, `macos/`, `windows/` or `linux/` platform folder exists.
/// 2. No dependency in `pubspec.yaml` is a known web-or-desktop-only package.
///
/// Transitive desktop packages (`win32` arrives under `share_plus`, for example)
/// are deliberately NOT flagged: they are unavoidable in plugin federations and
/// are simply never compiled into an Android or iOS binary. Only direct
/// dependencies are the project's own choice, so only those are policed.
///
/// Run with `dart run tool/check_platforms.dart`. Exits 0 when clean, 1 on any
/// violation.
library;

import 'dart:io';

/// Platform folders that must never exist in this repository.
const forbiddenPlatformDirs = <String>['web', 'macos', 'windows', 'linux'];

/// Direct dependencies that would indicate web or desktop support creeping in.
const forbiddenPackages = <String>[
  'flutter_web_plugins',
  'universal_html',
  'window_manager',
  'bitsdojo_window',
  'desktop_window',
  'tray_manager',
  'macos_ui',
  'fluent_ui',
  'yaru',
];

/// Files and fragments that define the DocScanly platform identity.
const requiredIdentityFragments = <String, List<String>>{
  'android/app/build.gradle': [
    'namespace = "com.bruxkey.docscanly"',
    'applicationId = "com.bruxkey.docscanly"',
  ],
  'android/app/src/main/AndroidManifest.xml': ['android:label="DocScanly"'],
  'ios/Runner.xcodeproj/project.pbxproj': [
    'PRODUCT_BUNDLE_IDENTIFIER = com.bruxkey.docscanly;',
    'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;',
  ],
  'ios/Runner/Info.plist': [
    '<string>DocScanly</string>',
    '<key>iCloud.com.bruxkey.docscanly</key>',
  ],
  'ios/Runner/Runner.entitlements': [
    '<string>iCloud.com.bruxkey.docscanly</string>',
    '<string>CloudDocuments</string>',
  ],
};

/// Returns the names of forbidden platform folders present under [root].
List<String> findForbiddenDirs(Directory root) {
  return forbiddenPlatformDirs
      .where((name) => Directory('${root.path}/$name').existsSync())
      .toList();
}

/// Returns the forbidden direct dependencies declared in [pubspecContent].
///
/// Parses only the `dependencies:` and `dev_dependencies:` blocks so a package
/// merely mentioned in a comment or in `dependency_overrides` is not reported.
List<String> findForbiddenPackages(String pubspecContent) {
  final found = <String>[];
  var inDependencyBlock = false;

  for (final line in pubspecContent.split('\n')) {
    final trimmed = line.trimRight();
    if (trimmed.isEmpty) continue;

    // A non-indented, non-comment line starts a new top-level block.
    if (!trimmed.startsWith(' ') && !trimmed.startsWith('#')) {
      inDependencyBlock =
          trimmed.startsWith('dependencies:') ||
          trimmed.startsWith('dev_dependencies:');
      continue;
    }

    if (!inDependencyBlock) continue;

    final match = RegExp(r'^\s{2}([a-z0-9_]+)\s*:').firstMatch(trimmed);
    if (match == null) continue;

    final name = match.group(1)!;
    if (forbiddenPackages.contains(name)) found.add(name);
  }

  return found;
}

/// Returns missing or forbidden DocScanly platform-identity configuration.
List<String> findIdentityViolations(Directory root) {
  final violations = <String>[];
  for (final entry in requiredIdentityFragments.entries) {
    final file = File('${root.path}/${entry.key}');
    if (!file.existsSync()) {
      violations.add('${entry.key} is missing');
      continue;
    }
    final content = file.readAsStringSync();
    for (final fragment in entry.value) {
      if (!content.contains(fragment)) {
        violations.add('${entry.key} lacks $fragment');
      }
    }
  }

  final entitlements = File('${root.path}/ios/Runner/Runner.entitlements');
  if (entitlements.existsSync()) {
    final content = entitlements.readAsStringSync();
    for (final forbidden in [
      'CloudKit',
      'com.apple.developer.icloud-extended-share-access',
    ]) {
      if (content.contains(forbidden)) {
        violations.add('Runner.entitlements must not enable $forbidden');
      }
    }
  }
  return violations;
}

/// Runs the platform check and exits non-zero on any violation.
void main() {
  final violations = <String>[];

  for (final dir in findForbiddenDirs(Directory('.'))) {
    violations.add(
      'Platform folder "$dir/" exists. DocScanly targets Android and iOS only.',
    );
  }

  final pubspec = File('pubspec.yaml');
  if (pubspec.existsSync()) {
    for (final package in findForbiddenPackages(pubspec.readAsStringSync())) {
      violations.add(
        'Direct dependency "$package" is web/desktop only and must be removed.',
      );
    }
  }

  violations.addAll(findIdentityViolations(Directory('.')));

  if (violations.isEmpty) {
    stdout.writeln('Platform check passed: Android and iOS only.');
    return;
  }

  stderr.writeln(
    'Platform check FAILED — ${violations.length} violation(s):\n',
  );
  for (final violation in violations) {
    stderr.writeln('  - $violation');
  }
  exit(1);
}
