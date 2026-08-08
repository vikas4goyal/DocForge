import 'dart:convert';

import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hd = SupportedCameraResolution(
    tier: CameraResolutionTier.hd720,
    width: 1280,
    height: 720,
  );
  final fullHd = SupportedCameraResolution(
    tier: CameraResolutionTier.fullHd1080,
    width: 1920,
    height: 1080,
  );
  final ultraHd = SupportedCameraResolution(
    tier: CameraResolutionTier.ultraHd4k,
    width: 4032,
    height: 3024,
  );

  group('CameraResolutionTier', () {
    test('canonical tiers have ascending fidelity order', () {
      expect(CameraResolutionTier.canonical, [
        CameraResolutionTier.hd720,
        CameraResolutionTier.fullHd1080,
        CameraResolutionTier.qhd2k,
        CameraResolutionTier.ultraHd4k,
      ]);
      expect(
        CameraResolutionTier.hd720.compareTo(CameraResolutionTier.fullHd1080),
        isNegative,
      );
    });

    test('checks dimensions in either orientation', () {
      expect(
        CameraResolutionTier.fullHd1080.isSatisfiedBy(
          width: 1080,
          height: 1920,
        ),
        isTrue,
      );
      expect(
        CameraResolutionTier.fullHd1080.isSatisfiedBy(width: 1280, height: 720),
        isFalse,
      );
    });
  });

  group('SupportedCameraResolution', () {
    test('combines the friendly tier with exact dimensions', () {
      expect(ultraHd.displayLabel, '4K • 4032 × 3024');
    });

    test('rejects dimensions that overstate the tier', () {
      expect(
        () => SupportedCameraResolution(
          tier: CameraResolutionTier.ultraHd4k,
          width: 1920,
          height: 1080,
        ),
        throwsArgumentError,
      );
    });

    test('tier and supported values round trip through generated JSON', () {
      final decoded = jsonDecode(jsonEncode(ultraHd.toJson()));
      expect(
        SupportedCameraResolution.fromJson(decoded as Map<String, dynamic>),
        ultraHd,
      );
    });
  });

  group('DesiredCameraResolution', () {
    test('missing preference means Full resolution', () {
      expect(
        DesiredCameraResolution.fromLegacyImageQuality(null),
        const DesiredCameraResolution.fullResolution(),
      );
    });

    test('maps old image quality deterministically', () {
      expect(
        DesiredCameraResolution.fromLegacyImageQuality('low'),
        DesiredCameraResolution.tier(CameraResolutionTier.hd720),
      );
      expect(
        DesiredCameraResolution.fromLegacyImageQuality('balanced'),
        DesiredCameraResolution.tier(CameraResolutionTier.fullHd1080),
      );
      expect(
        DesiredCameraResolution.fromLegacyImageQuality('high'),
        const DesiredCameraResolution.fullResolution(),
      );
    });

    test('resolves exact, nearest lower, and no-lower fallback', () {
      final supported = [fullHd, hd, ultraHd];

      expect(
        DesiredCameraResolution.tier(
          CameraResolutionTier.fullHd1080,
        ).resolve(supported),
        fullHd,
      );
      expect(
        DesiredCameraResolution.tier(
          CameraResolutionTier.qhd2k,
        ).resolve(supported),
        fullHd,
      );
      expect(
        DesiredCameraResolution.tier(
          CameraResolutionTier(
            id: 'tiny',
            label: 'Tiny',
            shortEdge: 1,
            longEdge: 1,
            rank: 0,
          ),
        ).resolve(supported),
        ultraHd,
      );
    });

    test('Full selects maximum and unavailable probing returns null', () {
      expect(
        (const DesiredCameraResolution.fullResolution()).resolve([
          hd,
          ultraHd,
          fullHd,
        ]),
        ultraHd,
      );
      expect(
        const DesiredCameraResolution.fullResolution().resolve(const []),
        isNull,
      );
    });

    test('desired values round trip through generated JSON', () {
      final desired = DesiredCameraResolution.tier(
        CameraResolutionTier.fullHd1080,
      );
      final decoded = jsonDecode(jsonEncode(desired.toJson()));
      expect(
        DesiredCameraResolution.fromJson(decoded as Map<String, dynamic>),
        desired,
      );
    });
  });
}
