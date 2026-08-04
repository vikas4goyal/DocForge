import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_library_marker.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/models/cloud_library_marker_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes only schema and non-PII library identity', () {
    final json = CloudLibraryMarkerDto.fromDomain(
      const CloudLibraryMarker(),
    ).toJson();

    expect(json, {
      'schemaVersion': 1,
      'libraryIdentifier': 'docscanly-library',
    });
    expect(json.keys, hasLength(2));
  });

  test('round-trips a supported marker', () {
    final marker = CloudLibraryMarkerDto.fromJson({
      'schemaVersion': 1,
      'libraryIdentifier': 'docscanly-library',
    }).toDomain();

    expect(marker, const CloudLibraryMarker());
    expect(marker.isSupported, isTrue);
  });

  test('preserves a future version so domain policy can reject it', () {
    final marker = CloudLibraryMarkerDto.fromJson({
      'schemaVersion': 9,
      'libraryIdentifier': 'docscanly-library',
    }).toDomain();

    expect(marker.schemaVersion, 9);
    expect(marker.isSupported, isFalse);
  });
}
