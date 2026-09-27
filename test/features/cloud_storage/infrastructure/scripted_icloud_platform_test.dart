import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'repeated reads are deterministic and returned collections are copies',
    () async {
      final platform = ScriptedICloudPlatform(
        marker: const {
          'schemaVersion': 1,
          'libraryIdentifier': 'docscanly-library',
        },
        items: const [ScriptedICloudItem(relativePath: 'a.pdf', sizeBytes: 7)],
      );

      final first = await platform.listItems();
      final second = await platform.listItems();

      expect(first.single.values, second.single.values);
      expect(await platform.readMarker(), await platform.readMarker());
      await platform.dispose();
    },
  );

  test('records download and scoped-access cleanup in order', () async {
    final platform = ScriptedICloudPlatform(pickedPaths: const ['/fixture/a']);

    await platform.ensureDownloaded('a.pdf');
    final paths = await platform.pickImportFolder();
    await platform.releaseImportFolder(paths);

    expect(platform.downloadRequests, ['a.pdf']);
    expect(platform.releasedPaths, ['/fixture/a']);
    await platform.dispose();
  });

  test('identity events are instance-owned and repeatable', () async {
    final platform = ScriptedICloudPlatform();
    var count = 0;
    final subscription = platform.identityChanges.listen((_) => count++);

    platform.emitIdentityChange();
    platform.emitIdentityChange();
    await Future<void>.delayed(Duration.zero);

    expect(count, 2);
    await subscription.cancel();
    await platform.dispose();
  });

  test('a scheduled outage begins after a fixed number of checks', () async {
    final platform = ScriptedICloudPlatform()
      ..scheduleOutage(afterChecks: 2, value: 'signedOut');

    expect(
      [
        await platform.availability(),
        await platform.availability(),
        await platform.availability(),
        await platform.availability(),
      ],
      ['available', 'available', 'signedOut', 'signedOut'],
    );

    platform.availabilityValue = 'available';
    expect(await platform.availability(), 'available');
    await platform.dispose();
  });

  for (final status in ['disabled', 'restricted', 'signedOut']) {
    test('scripted $status availability maps to its domain status', () async {
      final platform = ScriptedICloudPlatform(availabilityValue: status);
      final availability = await PlatformCloudContainerRepository(
        platform,
      ).availability();
      expect(availability.valueOrNull!.status.name, status);
      await platform.dispose();
    });
  }

  test('an established library with content is scriptable', () async {
    final platform = ScriptedICloudPlatform(
      marker: const {
        'schemaVersion': 1,
        'libraryIdentifier': 'docscanly-library',
      },
      items: const [ScriptedICloudItem(relativePath: 'Scan.pdf')],
    );
    final cloud = PlatformCloudContainerRepository(platform);

    expect((await cloud.readMarker()).valueOrNull!.isSupported, isTrue);
    expect(
      (await cloud.listItems()).valueOrNull!.single.relativePath,
      'Scan.pdf',
    );
    await platform.dispose();
  });
}
