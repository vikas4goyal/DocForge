// Tier 1 — the default-save-location → picker-hint normaliser. A bare path is
// ignored by both platform pickers, so this table is what makes the setting do
// anything at all.
import 'package:doc_scanly/features/document_sharing/infrastructure/export_start_location.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? android(String? stored) => exportStartLocation(
    stored,
    platform: TargetPlatform.android,
    directoryExists: (_) => fail('Android must not probe the filesystem'),
  );

  String? ios(String? stored, {bool exists = true}) => exportStartLocation(
    stored,
    platform: TargetPlatform.iOS,
    directoryExists: (_) => exists,
  );

  group('Android', () {
    const provider =
        'content://com.android.externalstorage.documents/document/';

    for (final (stored, expected) in [
      ('/storage/emulated/0/Download', '${provider}primary%3ADownload'),
      (
        '/storage/emulated/0/Documents/Scans/2026',
        '${provider}primary%3ADocuments%2FScans%2F2026',
      ),
      ('/storage/emulated/0/Download/', '${provider}primary%3ADownload'),
      ('/storage/emulated/0', '${provider}primary%3A'),
      (
        '/storage/emulated/0/My Files/Tax & Bills',
        '${provider}primary%3AMy%20Files%2FTax%20%26%20Bills',
      ),
      ('/storage/1A2B-3C4D/Scans', '${provider}1A2B-3C4D%3AScans'),
      (
        'content://com.android.externalstorage.documents/tree/primary%3AX',
        'content://com.android.externalstorage.documents/tree/primary%3AX',
      ),
    ]) {
      test('$stored → $expected', () => expect(android(stored), expected));
    }

    for (final stored in [
      null,
      '',
      '   ',
      '/storage/emulated/10/Download',
      '/storage/self/primary/Download',
      '/data/user/0/app/files',
      'Download',
    ]) {
      test(
        '${stored ?? 'null'} → no hint',
        () => expect(android(stored), isNull),
      );
    }
  });

  group('iOS', () {
    test('an existing absolute folder becomes a file URL', () {
      expect(
        ios('/private/var/mobile/Containers/Shared/AppGroup/X/File Provider'),
        'file:///private/var/mobile/Containers/Shared/AppGroup/X/File%20Provider/',
      );
    });

    test('a file URL passes through', () {
      expect(ios('file:///var/mobile/Docs/'), 'file:///var/mobile/Docs/');
    });

    test('a folder that no longer exists gives no hint', () {
      expect(ios('/var/mobile/Gone', exists: false), isNull);
    });

    test('a relative path gives no hint', () {
      expect(ios('Documents/Scans'), isNull);
    });
  });

  test('other platforms never get a hint', () {
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    ]) {
      expect(
        exportStartLocation(
          '/Users/x/Documents',
          platform: platform,
          directoryExists: (_) => true,
        ),
        isNull,
      );
    }
  });
}
