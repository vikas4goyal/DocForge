import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
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
}
