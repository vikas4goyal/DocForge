/// The verification gate.
///
/// Runs the three-tier pyramid in order and reports which stage broke. This is
/// the command an agent runs after implementing a change, and the one CI runs;
/// its output has to be actionable without anyone reading raw device logs.
///
/// Order matters and is fail-fast: format and analysis are seconds, the unit
/// and component tiers are a minute, and the flow suite needs a device and
/// takes minutes. Running them in that order means a misplaced brace is
/// reported in five seconds rather than after a full device run.
///
/// The single most important behaviour here is the one at the end: **with no
/// device attached, Tier 3 is SKIPPED and the overall result is INCOMPLETE,
/// never PASSED.** Reporting a device-less run as green is the one way this
/// gate could lull an agent into shipping exactly the kind of broken flow it
/// exists to catch (`design.md` D7).
///
/// Run with `dart run tool/verify.dart`. Exits 0 only on a complete pass.
library;

import 'dart:convert';
import 'dart:io';

/// What a stage did.
enum StageResult {
  /// The stage ran and succeeded.
  passed,

  /// The stage ran and failed.
  failed,

  /// The stage could not run, and its absence is reported rather than hidden.
  skipped,
}

/// One stage of the pyramid, and how it went.
class StageReport {
  /// Creates a report.
  const StageReport({
    required this.name,
    required this.result,
    required this.duration,
    this.detail,
  });

  /// What the stage is called in the summary.
  final String name;

  /// Whether it passed, failed or could not run.
  final StageResult result;

  /// How long it took.
  ///
  /// Reported per stage so a stage that gets slower is visible rather than
  /// absorbed into a total that only ever creeps upward.
  final Duration duration;

  /// Why it was skipped, or what failed.
  final String? detail;

  /// The summary line for this stage.
  String get line {
    final mark = switch (result) {
      StageResult.passed => 'PASS',
      StageResult.failed => 'FAIL',
      StageResult.skipped => 'SKIP',
    };
    final seconds = (duration.inMilliseconds / 1000).toStringAsFixed(1);
    final suffix = detail == null ? '' : '  — $detail';

    return '  $mark  ${name.padRight(28)} ${seconds.padLeft(7)}s$suffix';
  }
}

/// A command to run as one stage.
class Stage {
  /// Creates a stage running [executable] with [arguments].
  const Stage({
    required this.name,
    required this.executable,
    required this.arguments,
  });

  /// What the stage is called in the summary.
  final String name;

  /// The program to run.
  final String executable;

  /// Its arguments.
  final List<String> arguments;
}

/// The stages that need no device, in the order they run.
///
/// Cheapest first, so the fastest possible failure is the most likely one.
const hostStages = <Stage>[
  Stage(
    name: 'format',
    executable: 'dart',
    arguments: [
      'format',
      '--set-exit-if-changed',
      'lib',
      'test',
      'tool',
      'integration_test',
    ],
  ),
  Stage(name: 'analyze', executable: 'flutter', arguments: ['analyze']),
  Stage(
    name: 'layering',
    executable: 'dart',
    arguments: ['run', 'tool/check_layering.dart'],
  ),
  Stage(
    name: 'platforms',
    executable: 'dart',
    arguments: ['run', 'tool/check_platforms.dart'],
  ),
  Stage(
    name: 'branding',
    executable: 'dart',
    arguments: ['run', 'tool/check_branding.dart'],
  ),
  // Tier 1 and Tier 2 run together: both live under `test/`, both are host
  // tests, and splitting the invocation would double the compile.
  Stage(
    name: 'tier 1 + tier 2',
    executable: 'flutter',
    arguments: ['test', '--coverage'],
  ),
  Stage(
    name: 'coverage',
    executable: 'dart',
    arguments: ['run', 'tool/check_coverage.dart'],
  ),
];

/// Returns the id of a device the flow suite can run on, or null.
///
/// Prefers Android, then an iOS Simulator, and excludes physical iOS devices.
///
/// Returns null rather than throwing when neither supported gate is available,
/// because a device-less run is legitimate — it is simply incomplete.
Future<String?> findDevice() async {
  final result = await Process.run('flutter', [
    'devices',
    '--machine',
  ], runInShell: true);

  if (result.exitCode != 0) return null;

  try {
    final devices = jsonDecode(result.stdout as String) as List<dynamic>;
    String? iosSimulator;
    for (final entry in devices.cast<Map<String, dynamic>>()) {
      final platform = entry['targetPlatform'] as String? ?? '';
      if (platform.startsWith('android')) {
        return entry['id'] as String?;
      }
      if (platform.startsWith('ios') && entry['emulator'] == true) {
        iosSimulator ??= entry['id'] as String?;
      }
    }
    return iosSimulator;
  } on FormatException {
    return null;
  }
}

/// Every flow file, in a stable order.
List<File> flowFiles() {
  final directory = Directory('integration_test/flows');
  if (!directory.existsSync()) return [];

  return directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('_test.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// Runs [stage], streaming its output so a failure can be read as it happens.
Future<StageReport> runStage(Stage stage) async {
  stdout.writeln('▸ ${stage.name}');
  final started = DateTime.now();

  final process = await Process.start(
    stage.executable,
    stage.arguments,
    mode: ProcessStartMode.inheritStdio,
    runInShell: true,
  );
  final code = await process.exitCode;
  final duration = DateTime.now().difference(started);

  return StageReport(
    name: stage.name,
    result: code == 0 ? StageResult.passed : StageResult.failed,
    duration: duration,
    detail: code == 0 ? null : 'exit code $code',
  );
}

/// Runs every flow file on [deviceId], one per stage so the summary names the
/// failing flow rather than only "the flow suite".
Future<List<StageReport>> runFlows(String deviceId) async {
  final reports = <StageReport>[];

  for (final file in flowFiles()) {
    final name =
        'flow: ${file.uri.pathSegments.last.replaceAll('_test.dart', '')}';
    reports.add(
      await runStage(
        Stage(
          name: name,
          executable: 'flutter',
          arguments: ['test', file.path, '-d', deviceId],
        ),
      ),
    );

    // Fail fast within the suite too: a device run is minutes per flow, and
    // whoever is reading this wants the first failure, not all of them.
    if (reports.last.result == StageResult.failed) break;
  }

  return reports;
}

/// Prints the per-stage summary and returns the process exit code.
///
/// Three outcomes, deliberately distinct:
///
/// - **PASSED** — every stage ran and succeeded, including Tier 3.
/// - **FAILED** — a stage failed.
/// - **INCOMPLETE** — everything that ran succeeded, but Tier 3 did not run.
///   Exits non-zero, because a change is not verified until a flow has been
///   driven on a device.
int report(List<StageReport> reports) {
  stdout
    ..writeln()
    ..writeln('─' * 72)
    ..writeln('Verification summary');
  for (final report in reports) {
    stdout.writeln(report.line);
  }

  final total = reports.fold(Duration.zero, (sum, r) => sum + r.duration);
  stdout
    ..writeln('─' * 72)
    ..writeln('  total ${(total.inMilliseconds / 1000).toStringAsFixed(1)}s');

  final failed = reports.where((r) => r.result == StageResult.failed).toList();
  if (failed.isNotEmpty) {
    stdout
      ..writeln()
      ..writeln('RESULT: FAILED — ${failed.first.name}');
    return 1;
  }

  if (reports.any((r) => r.result == StageResult.skipped)) {
    stdout
      ..writeln()
      ..writeln('RESULT: INCOMPLETE — the flow suite did not run.')
      ..writeln(
        '  Every host stage passed, but nothing drove the application on a '
        'device.',
      )
      ..writeln(
        '  This is NOT a pass. Attach a device or start a simulator and run '
        'again',
      )
      ..writeln('  before reporting the change as working.');
    return 2;
  }

  stdout
    ..writeln()
    ..writeln('RESULT: PASSED — all three tiers are green.');
  return 0;
}

/// Runs the pyramid and exits with the summary's code.
Future<void> main(List<String> arguments) async {
  final skipDevice = arguments.contains('--no-device');
  final reports = <StageReport>[];

  for (final stage in hostStages) {
    final result = await runStage(stage);
    reports.add(result);

    // Fail fast: every later stage is more expensive, and a repository that
    // does not analyse has nothing useful to say about its flows.
    if (result.result == StageResult.failed) {
      exit(report(reports));
    }
  }

  final deviceId = skipDevice ? null : await findDevice();
  if (deviceId == null) {
    reports.add(
      StageReport(
        name: 'tier 3 (flows)',
        result: StageResult.skipped,
        duration: Duration.zero,
        detail: skipDevice
            ? 'skipped by --no-device'
            : 'no Android device or iOS simulator attached',
      ),
    );
    exit(report(reports));
  }

  stdout.writeln('▸ tier 3 on $deviceId');
  reports.addAll(await runFlows(deviceId));
  exit(report(reports));
}
