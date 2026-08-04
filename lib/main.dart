/// Entry point for the DocScanly application.
///
/// Deliberately thin: ensure the binding, build the application, run it. Every
/// wiring decision lives in [buildDocScanly], which is public and parameterised
/// so the end-to-end suite boots this same application rather than a second
/// wiring of its own. No feature logic, no service lookup and no mutable global
/// state lives here.
library;

import 'package:doc_scanly/app/doc_scanly.dart';
import 'package:flutter/material.dart';

/// Boots the application.
Future<void> main() async {
  // Required before any plugin is touched — SharedPreferences, secure storage
  // and the Isar directory lookup are all resolved while the application is
  // built.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(await buildDocScanly());
}
