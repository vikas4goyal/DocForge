/// Entry point and visible asynchronous bootstrap for DocScanly.
///
/// Feature wiring remains in [buildDocScanly]. This file only initializes
/// telemetry, shows progress while composition runs, and exposes a retry state
/// instead of leaving a blank launch screen when composition fails.
library;

import 'dart:ui';

import 'package:doc_scanly/app/doc_scanly.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

const _deploymentEnvironment = String.fromEnvironment(
  'ENVIRONMENT',
  defaultValue: 'development',
);

/// Boots the application.
Future<void> main() async {
  // Required before any plugin is touched — SharedPreferences, secure storage
  // and the Isar directory lookup are all resolved while the application is
  // built.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late Future<Widget> _application = _buildApplication();

  Future<Widget> _buildApplication() async {
    final stopwatch = Stopwatch()..start();
    try {
      await Firebase.initializeApp();
      try {
        await FirebaseCrashlytics.instance.setCustomKey(
          'deployment_environment',
          _deploymentEnvironment,
        );
      } on Object {
        // Observability must never prevent the application from starting.
      }

      // Flutter framework failures and uncaught asynchronous failures travel
      // through different error channels, so both must be connected.
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
        return true;
      };

      try {
        await FirebaseCrashlytics.instance.log('startup: composition_started');
      } on Object {
        // Observability must never prevent the application from starting.
      }
      final application = await buildDocScanly();
      final elapsed = stopwatch.elapsedMilliseconds;
      try {
        await FirebaseCrashlytics.instance.log(
          'startup: composition_ready elapsedMs=$elapsed',
        );
      } on Object {
        // Observability must never prevent the application from starting.
      }
      return application;
    } on Object catch (error, stackTrace) {
      final elapsed = stopwatch.elapsedMilliseconds;
      final firstFrame = stackTrace.toString().split('\n').first;
      final message =
          'phase=bootstrap outcome=error elapsedMs=$elapsed '
          'errorType=${error.runtimeType} firstFrame=$firstFrame';
      debugPrint('[DocScanly.startup] $message');
      if (Firebase.apps.isNotEmpty) {
        try {
          await FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            reason: 'Startup failed after ${elapsed}ms',
          );
        } on Object {
          // Reporting failure must not replace the original startup failure.
        }
      }
      rethrow;
    }
  }

  void _retry() {
    setState(() => _application = _buildApplication());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _application,
      builder: (context, snapshot) {
        if (snapshot.hasData) return snapshot.requireData;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('DocScanly couldn\'t finish starting.'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _retry,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Opening DocScanly…'),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
