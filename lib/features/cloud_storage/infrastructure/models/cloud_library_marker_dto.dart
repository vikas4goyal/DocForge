/// Serialized form of the non-sensitive iCloud library marker.
library;

import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_library_marker.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cloud_library_marker_dto.freezed.dart';
part 'cloud_library_marker_dto.g.dart';

/// JSON representation written to `.docscanly-library.json`.
@freezed
abstract class CloudLibraryMarkerDto with _$CloudLibraryMarkerDto {
  /// Creates a marker DTO.
  const factory CloudLibraryMarkerDto({
    required int schemaVersion,
    required String libraryIdentifier,
  }) = _CloudLibraryMarkerDto;

  /// Decodes a marker DTO.
  factory CloudLibraryMarkerDto.fromJson(Map<String, dynamic> json) =>
      _$CloudLibraryMarkerDtoFromJson(json);

  /// Creates a DTO from [marker].
  factory CloudLibraryMarkerDto.fromDomain(CloudLibraryMarker marker) =>
      CloudLibraryMarkerDto(
        schemaVersion: marker.schemaVersion,
        libraryIdentifier: marker.libraryIdentifier,
      );

  const CloudLibraryMarkerDto._();

  /// Converts this DTO to a validated domain value.
  CloudLibraryMarker toDomain() => CloudLibraryMarker(
    schemaVersion: schemaVersion,
    libraryIdentifier: libraryIdentifier,
  );
}
