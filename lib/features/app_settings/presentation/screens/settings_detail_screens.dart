/// Pushed screens opened from the Settings destination.
library;

import 'dart:async';

import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/core/formatting/display_formatting.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:doc_scanly/features/app_settings/presentation/cubit/settings_cubit.dart';
import 'package:doc_scanly/features/app_settings/presentation/settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Selects a directory through the current platform's document picker.
///
/// Returns the selected path, or null when the user cancels. Platform failures
/// may be thrown and are converted to visible feedback by the calling screen.
typedef DirectoryPicker = Future<String?> Function();

/// Creates typed routes for every pushed Settings detail screen.
abstract final class SettingsDetailRoutes {
  /// Creates the recognition-language route for [value].
  ///
  /// [onSelected] persists a selection before the route pops.
  static Route<void> recognitionLanguage({
    required OcrScript value,
    required Future<void> Function(OcrScript script) onSelected,
  }) => MaterialPageRoute<void>(
    builder: (_) =>
        RecognitionLanguageScreen(value: value, onSelected: onSelected),
  );

  /// Creates the default-save-location route for [currentPath].
  ///
  /// [pickDirectory] supplies the platform edge and [onSelected] persists an
  /// accepted choice. Picker cancellation returns null and causes no write.
  static Route<void> saveLocation({
    required String? currentPath,
    required DirectoryPicker pickDirectory,
    required Future<void> Function(String? path) onSelected,
  }) => MaterialPageRoute<void>(
    builder: (_) => DefaultSaveLocationScreen(
      currentPath: currentPath,
      pickDirectory: pickDirectory,
      onSelected: onSelected,
    ),
  );

  /// Creates storage details backed by [settings].
  ///
  /// [onManageLocation] is absent on platforms without cloud library storage.
  static Route<void> storage({
    required SettingsCubit settings,
    VoidCallback? onManageLocation,
  }) => MaterialPageRoute<void>(
    builder: (_) => BlocProvider<SettingsCubit>.value(
      value: settings,
      child: StorageDetailsScreen(onManageLocation: onManageLocation),
    ),
  );
}

/// Shows every OCR script in a pushed, vertically scrollable route.
class RecognitionLanguageScreen extends StatelessWidget {
  /// Creates the recognition-language screen.
  ///
  /// [value] is the selected script and [onSelected] persists a new selection.
  const RecognitionLanguageScreen({
    required this.value,
    required this.onSelected,
    super.key,
  });

  /// The current recognition script.
  final OcrScript value;

  /// Persists the selected script.
  final Future<void> Function(OcrScript script) onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: SettingsKeys.ocrLanguageScreen,
      appBar: AppBar(title: const Text('Recognition language')),
      body: _SettingsDetailWidth(
        child: RadioGroup<OcrScript>(
          groupValue: value,
          onChanged: (script) {
            if (script != null) unawaited(_select(context, script));
          },
          child: ListView.builder(
            key: SettingsKeys.ocrLanguageList,
            itemCount: OcrScript.values.length,
            itemBuilder: (context, index) {
              final script = OcrScript.values[index];
              return Semantics(
                label: SettingsSemantics.ocrLanguageOption(script.label),
                selected: script == value,
                excludeSemantics: true,
                child: RadioListTile<OcrScript>(
                  key: SettingsKeys.ocrLanguageOption(script.name),
                  value: script,
                  title: Text(script.label),
                  subtitle: Text(SettingsCopy.ocrScriptDescription(script)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _select(BuildContext context, OcrScript script) async {
    await onSelected(script);
    if (context.mounted) Navigator.of(context).pop();
  }
}

/// Chooses whether exports ask each time or start in a preferred folder.
class DefaultSaveLocationScreen extends StatelessWidget {
  /// Creates the default-save-location screen.
  ///
  /// [currentPath] is null for “Ask each time”; [pickDirectory] is an injected
  /// platform edge and [onSelected] persists an accepted value.
  const DefaultSaveLocationScreen({
    required this.currentPath,
    required this.pickDirectory,
    required this.onSelected,
    super.key,
  });

  /// The selected directory, or null when every export asks.
  final String? currentPath;

  /// Opens the platform directory picker.
  final DirectoryPicker pickDirectory;

  /// Persists a path, or null for “Ask each time.”
  final Future<void> Function(String? path) onSelected;

  @override
  Widget build(BuildContext context) {
    final asksEachTime = currentPath == null;

    return Scaffold(
      key: SettingsKeys.saveLocationScreen,
      appBar: AppBar(title: const Text('Default save location')),
      body: _SettingsDetailWidth(
        child: ListView(
          children: [
            Semantics(
              label: SettingsSemantics.askEachTime(selected: asksEachTime),
              button: true,
              selected: asksEachTime,
              excludeSemantics: true,
              child: ListTile(
                key: SettingsKeys.saveLocationAskEachTime,
                title: const Text(SettingsCopy.systemSaveLocation),
                subtitle: const Text(
                  'Choose a destination whenever you export',
                ),
                trailing: asksEachTime ? const Icon(Icons.check) : null,
                onTap: () => unawaited(_askEachTime(context)),
              ),
            ),
            Semantics(
              label: SettingsSemantics.chooseFolder,
              button: true,
              excludeSemantics: true,
              child: ListTile(
                key: SettingsKeys.saveLocationChooseFolder,
                title: const Text('Choose a folder…'),
                subtitle: currentPath == null ? null : Text(currentPath!),
                trailing: currentPath == null
                    ? const Icon(Icons.chevron_right)
                    : const Icon(Icons.check),
                onTap: () => unawaited(_chooseFolder(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _askEachTime(BuildContext context) async {
    await onSelected(null);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _chooseFolder(BuildContext context) async {
    try {
      final path = await pickDirectory();
      // Cancellation is deliberately a no-op: null is also the persisted
      // meaning of “Ask each time,” but cancelling is not selecting it.
      if (path == null || path.isEmpty) return;
      await onSelected(path);
      if (context.mounted) Navigator.of(context).pop();
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The folder picker could not be opened.')),
      );
    }
  }
}

/// Displays current document storage usage and its management actions.
class StorageDetailsScreen extends StatefulWidget {
  /// Creates storage details backed by the nearest [SettingsCubit].
  ///
  /// [onManageLocation] is supplied only where iCloud library storage exists.
  const StorageDetailsScreen({super.key, this.onManageLocation});

  /// Opens the platform's library storage-location screen.
  final VoidCallback? onManageLocation;

  @override
  State<StorageDetailsScreen> createState() => _StorageDetailsScreenState();
}

class _StorageDetailsScreenState extends State<StorageDetailsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<SettingsCubit>().refreshStorage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: SettingsKeys.storageScreen,
      appBar: AppBar(
        title: const Text('Storage'),
        actions: [
          IconButton(
            key: SettingsKeys.storageRefresh,
            tooltip: SettingsSemantics.refreshStorage,
            onPressed: context.read<SettingsCubit>().refreshStorage,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final storage = state.storage;
          return _SettingsDetailWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                if (state.isRefreshingStorage) const LinearProgressIndicator(),
                if (state.storageFailure != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.storageFailure!.presentation.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  storage == null
                      ? '—'
                      : DisplayFormatting.fileSize(storage.totalBytes),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  storage == null
                      ? 'Storage usage is not available yet'
                      : '${storage.documentCount} '
                            '${storage.documentCount == 1 ? 'document' : 'documents'}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (widget.onManageLocation != null) ...[
                  const SizedBox(height: 32),
                  ListTile(
                    key: SettingsKeys.storageManageLocation,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_outlined),
                    title: const Text('Manage storage location'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: widget.onManageLocation,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingsDetailWidth extends StatelessWidget {
  const _SettingsDetailWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: child,
    ),
  );
}
