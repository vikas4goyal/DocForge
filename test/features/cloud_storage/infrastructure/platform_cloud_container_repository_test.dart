import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_library_marker.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every stable availability status', () async {
    for (final status in CloudAvailabilityStatus.values) {
      final platform = ScriptedICloudPlatform(availabilityValue: status.name);
      final repository = PlatformCloudContainerRepository(platform);

      expect((await repository.availability()).valueOrNull?.status, status);
      await platform.dispose();
    }
  });

  test('empty marker is not an established library', () async {
    final platform = ScriptedICloudPlatform();
    final repository = PlatformCloudContainerRepository(platform);

    expect((await repository.readMarker()).valueOrNull, isNull);
    await platform.dispose();
  });

  test('reads and writes an established marker', () async {
    final platform = ScriptedICloudPlatform();
    final repository = PlatformCloudContainerRepository(platform);

    await repository.writeMarker(const CloudLibraryMarker());

    expect(
      (await repository.readMarker()).valueOrNull,
      const CloudLibraryMarker(),
    );
    await platform.dispose();
  });

  test('rejects an unsupported marker version', () async {
    final platform = ScriptedICloudPlatform(
      marker: const {
        'schemaVersion': 99,
        'libraryIdentifier': 'docscanly-library',
      },
    );
    final repository = PlatformCloudContainerRepository(platform);

    expect(
      (await repository.readMarker()).failureOrNull,
      isA<CorruptFileFailure>(),
    );
    await platform.dispose();
  });

  test('maps remote item metadata without downloading it', () async {
    final platform = ScriptedICloudPlatform(
      items: const [
        ScriptedICloudItem(
          relativePath: 'Receipts/a.pdf',
          availability: 'remote',
          resourceIdentifier: 'resource-1',
          sizeBytes: 42,
          modifiedMilliseconds: 1000,
        ),
      ],
    );
    final repository = PlatformCloudContainerRepository(platform);

    final item = (await repository.listItems()).valueOrNull!.single;

    expect(item.availability, CloudContentAvailability.remote);
    expect(item.resourceIdentifier, 'resource-1');
    expect(platform.downloadRequests, isEmpty);
    await platform.dispose();
  });

  test('maps failed download to a stable storage failure', () async {
    final platform = ScriptedICloudPlatform()
      ..nextDownloadFailure = PlatformException(code: 'offline');
    final repository = PlatformCloudContainerRepository(platform);

    final result = await repository.ensureDownloaded('a.pdf');

    expect(result.failureOrNull, isA<StorageFailure>());
    expect((result.failureOrNull as StorageFailure).debugDetail, 'offline');
    await platform.dispose();
  });

  test('forwards bounded download progress', () async {
    final platform = ScriptedICloudPlatform();
    final repository = PlatformCloudContainerRepository(platform);
    final progress = <double>[];

    await repository.ensureDownloaded('a.pdf', onProgress: progress.add);

    expect(progress, [0, 1]);
    await platform.dispose();
  });

  test('forwards instance-owned iCloud identity changes', () async {
    final platform = ScriptedICloudPlatform();
    final repository = PlatformCloudContainerRepository(platform);
    var changes = 0;
    final subscription = repository.identityChanges.listen((_) => changes++);

    platform.emitIdentityChange();
    await Future<void>.delayed(Duration.zero);

    expect(changes, 1);
    await subscription.cancel();
    await platform.dispose();
  });

  test(
    'preserves the stable native conflict code for recovery policy',
    () async {
      final platform = ScriptedICloudPlatform()
        ..nextDownloadFailure = PlatformException(code: 'conflict');
      final repository = PlatformCloudContainerRepository(platform);

      final result = await repository.ensureDownloaded('a.pdf');

      expect(result.failureOrNull, isA<StorageFailure>());
      expect((result.failureOrNull as StorageFailure).debugDetail, 'conflict');
      await platform.dispose();
    },
  );
}
