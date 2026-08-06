/// Production iCloud repository over the first-party platform channel.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_library_marker.dart';
import 'package:doc_scanly/features/cloud_storage/domain/repositories/cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/ios_icloud_channel.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/models/cloud_library_marker_dto.dart';
import 'package:flutter/services.dart';

/// Maps stable native values into cloud-storage domain values.
class PlatformCloudContainerRepository implements CloudContainerRepository {
  /// Creates the repository over [platform].
  const PlatformCloudContainerRepository(this.platform);

  /// The substitutable iOS edge.
  final ICloudPlatformApi platform;

  @override
  Future<Result<CloudAvailability>> availability() => _guard(() async {
    final value = await platform.availability();
    final status = CloudAvailabilityStatus.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => CloudAvailabilityStatus.unavailable,
    );
    return CloudAvailability(status);
  });

  @override
  Future<Result<String?>> documentRootPath() =>
      _guard(platform.documentRootPath);

  @override
  Future<Result<CloudLibraryMarker?>> readMarker() => _guard(() async {
    final values = await platform.readMarker();
    if (values == null) return null;
    final marker = CloudLibraryMarkerDto.fromJson(values).toDomain();
    if (!marker.isSupported) throw const FormatException('unsupported marker');
    return marker;
  });

  @override
  Future<Result<void>> writeMarker(CloudLibraryMarker marker) => _guard(
    () =>
        platform.writeMarker(CloudLibraryMarkerDto.fromDomain(marker).toJson()),
  );

  @override
  Future<Result<void>> deleteMarker() => _guard(platform.deleteMarker);

  @override
  Future<Result<List<CloudItem>>> listItems() => _guard(() async {
    final values = await platform.listItems();
    return values
        .map((data) {
          final value = data.values;
          final stateName = value['availability'] as String? ?? 'remote';
          final state = CloudContentAvailability.values.firstWhere(
            (candidate) => candidate.name == stateName,
            orElse: () => CloudContentAvailability.remote,
          );
          final modifiedMilliseconds = value['modifiedMilliseconds'] as int?;
          return CloudItem(
            relativePath: value['relativePath'] as String,
            isDirectory: value['isDirectory'] as bool? ?? false,
            availability: state,
            resourceIdentifier: value['resourceIdentifier'] as String?,
            sizeBytes: value['sizeBytes'] as int? ?? 0,
            modifiedAt: modifiedMilliseconds == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    modifiedMilliseconds,
                    isUtc: true,
                  ),
          );
        })
        .toList(growable: false);
  });

  @override
  Future<Result<void>> ensureDownloaded(
    String relativePath, {
    CloudDownloadProgress? onProgress,
  }) => _guard(() async {
    onProgress?.call(0);
    await platform.ensureDownloaded(relativePath);
    onProgress?.call(1);
  });

  @override
  Future<Result<List<String>>> pickImportFolder() =>
      _guard(platform.pickImportFolder);

  @override
  Future<Result<void>> releaseImportFolder(List<String> paths) =>
      _guard(() => platform.releaseImportFolder(paths));

  @override
  Stream<void> get identityChanges => platform.identityChanges;

  Future<Result<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Result<T>.success(await operation());
    } on MissingPluginException catch (error) {
      return Result<T>.failure(Failure.storage(debugDetail: error.message));
    } on PlatformException catch (error) {
      return Result<T>.failure(Failure.storage(debugDetail: error.code));
    } on FormatException catch (error) {
      return Result<T>.failure(Failure.corruptFile(debugDetail: '$error'));
    } on Object catch (error) {
      return Result<T>.failure(
        Failure.storage(debugDetail: '${error.runtimeType}'),
      );
    }
  }
}
