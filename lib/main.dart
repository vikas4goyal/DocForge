/// Entry point for the DocForge application.
///
/// Keeps startup deliberately thin: it builds the dependency graph once via the
/// composition root and hands the result to the widget tree. No feature logic,
/// no service lookup and no mutable global state lives here.
library;

import 'package:flutter/material.dart';

/// Boots the application.
///
/// Wiring is added in task 2.20 (composition root) and task 2.22 (router); this
/// placeholder exists so the project builds and analyses cleanly in between.
void main() {
  runApp(const DocForgeApp());
}

/// Root widget of the DocForge application.
///
/// Replaced in task 2.22 by the `MaterialApp.router` configuration that owns the
/// GoRouter route table and the Material 3 light and dark themes.
class DocForgeApp extends StatelessWidget {
  /// Creates the root application widget.
  const DocForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'DocForge',
      home: Scaffold(body: SizedBox.shrink()),
    );
  }
}
