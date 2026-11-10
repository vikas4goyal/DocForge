import 'dart:io';

import 'package:doc_scanly/app/cloud_storage_module.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/core/storage/public_storage/filesystem_public_file_store.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_decision.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cloud_storage_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CloudStorageModule', () {
    late Directory scratch;
    late ScriptedICloudPlatform platform;

    setUp(() async {
      scratch = await Directory.systemTemp.createTemp('docscanly_module_');
      platform = ScriptedICloudPlatform(rootPath: '${scratch.path}/cloud');
      Directory('${scratch.path}/cloud').createSync();
    });

    tearDown(() async {
      await platform.dispose();
      await scratch.delete(recursive: true);
    });

    Future<CloudStorageModule> build(
      InMemoryPreferenceStore preferences, {
      bool continueLocal = false,
    }) async => (await buildCloudStorageModule(
      preferences: preferences,
      documentsDirectory: Directory('${scratch.path}/documents'),
      platform: platform,
      continueLocalThisSession: continueLocal,
    )).valueOrNull!;

    test('an iCloud session summarises and resolves the iCloud root', () async {
      final module = await build(InMemoryPreferenceStore());

      expect(
        module.decision,
        const StorageDecision.useICloud(writeMarker: true),
      );
      expect(module.authority, StorageLocation.iCloud);
      expect(module.summary, 'iCloud Drive');
      final store = (await module.authoritativeStore()).valueOrNull!;
      expect(
        (store as FilesystemPublicFileStore).rootDirectory.path,
        '${scratch.path}/cloud',
      );
    });

    test('a device session summarises and resolves the device root', () async {
      platform.availabilityValue = 'signedOut';
      final module = await build(InMemoryPreferenceStore());

      expect(module.authority, StorageLocation.local);
      expect(module.summary, 'On this device');
      expect(
        (await module.authoritativeStore()).valueOrNull,
        same(module.localStore),
      );
    });

    test('the session override is passed to the startup policy', () async {
      final module = await build(
        InMemoryPreferenceStore({'settings.storage.location.v1': 'local'}),
        continueLocal: true,
      );
      expect(module.authority, StorageLocation.local);
    });

    test('migration refuses to start while iCloud is unavailable', () async {
      final module = await build(InMemoryPreferenceStore());
      platform.availabilityValue = 'disabled';

      final result = await module.migrate(
        source: StorageLocation.local,
        destination: StorageLocation.iCloud,
      );

      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('a missing container root is reported, never replaced', () async {
      final module = await build(
        InMemoryPreferenceStore({'settings.storage.location.v1': 'icloud'}),
      );
      platform.rootPath = null;

      expect(
        (await module.authoritativeStore()).failureOrNull,
        isA<StorageFailure>(),
      );
      expect(
        (await module.migrate(
          source: StorageLocation.local,
          destination: StorageLocation.iCloud,
        )).failureOrNull,
        isA<StorageFailure>(),
      );
    });
  });

  group('CloudLibraryUnavailableApp', () {
    Future<void> pump(
      WidgetTester tester, {
      required Future<Widget> Function() onRetry,
      Future<Widget> Function()? onUseDevice,
    }) async {
      await tester.pumpWidget(
        CloudLibraryUnavailableApp(onRetry: onRetry, onUseDevice: onUseDevice),
      );
    }

    testWidgets('announces the unavailable library and retries', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, onRetry: () async => _stand('recomposed'));

      expect(
        find.bySemanticsLabel(CloudStorageSemantics.unavailable),
        findsOneWidget,
      );
      expect(find.byKey(CloudStorageKeys.useDevice), findsNothing);

      await tester.tap(find.byKey(CloudStorageKeys.retry));
      await tester.pump();
      expect(find.text('recomposed'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the device escape runs only after confirmation', (
      tester,
    ) async {
      var adopted = 0;
      await pump(
        tester,
        onRetry: () async => _stand('retried'),
        onUseDevice: () async {
          adopted++;
          return _stand('device library');
        },
      );

      await tester.tap(find.byKey(CloudStorageKeys.useDevice));
      await tester.pumpAndSettle();
      expect(find.byKey(CloudStorageKeys.useDeviceConfirm), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(adopted, 0);

      await tester.tap(find.byKey(CloudStorageKeys.useDevice));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CloudStorageKeys.useDeviceConfirm));
      await tester.pumpAndSettle();

      expect(adopted, 1);
      expect(find.text('device library'), findsOneWidget);
    });
  });
}

/// A recomposed-app stand-in; it replaces the whole app, so it brings its own
/// text direction.
Widget _stand(String label) =>
    Directionality(textDirection: TextDirection.ltr, child: Text(label));
