/// Camera-resolution preferences and concrete active-camera capabilities.
///
/// A desired tier is intentionally separate from concrete dimensions: camera
/// sensors differ, and switching cameras can make yesterday's exact dimensions
/// unavailable. The preference stays stable while resolution happens against
/// the active camera's current capability list.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'camera_resolution.freezed.dart';
part 'camera_resolution.g.dart';

/// A canonical, user-facing still-image resolution tier.
@freezed
@JsonSerializable()
class CameraResolutionTier
    with _$CameraResolutionTier
    implements Comparable<CameraResolutionTier> {
  /// Creates a validated tier.
  CameraResolutionTier({
    required this.id,
    required this.label,
    required int shortEdge,
    required int longEdge,
    required int rank,
  }) : shortEdge = _positive(shortEdge, 'shortEdge'),
       longEdge = _positive(longEdge, 'longEdge'),
       rank = _nonNegative(rank);

  /// Creates a tier from JSON.
  factory CameraResolutionTier.fromJson(Map<String, dynamic> json) =>
      _$CameraResolutionTierFromJson(json);

  /// Stable identifier persisted as the desired tier.
  @override
  final String id;

  /// Friendly name displayed before exact active-camera dimensions.
  @override
  final String label;

  /// Minimum short edge needed to honestly advertise this tier.
  @override
  final int shortEdge;

  /// Minimum long edge needed to honestly advertise this tier.
  @override
  final int longEdge;

  /// Ascending fidelity order used for deterministic fallback.
  @override
  final int rank;

  /// Converts this tier to generated JSON.
  Map<String, dynamic> toJson() => _$CameraResolutionTierToJson(this);

  /// Whether [width] × [height] can satisfy this tier in either orientation.
  bool isSatisfiedBy({required int width, required int height}) {
    final actualShort = width < height ? width : height;
    final actualLong = width > height ? width : height;
    return actualShort >= shortEdge && actualLong >= longEdge;
  }

  @override
  int compareTo(CameraResolutionTier other) => rank.compareTo(other.rank);

  /// 1280 × 720 or better.
  static final hd720 = CameraResolutionTier(
    id: '720p',
    label: '720p',
    shortEdge: 720,
    longEdge: 1280,
    rank: 0,
  );

  /// 1920 × 1080 or better.
  static final fullHd1080 = CameraResolutionTier(
    id: '1080p',
    label: '1080p',
    shortEdge: 1080,
    longEdge: 1920,
    rank: 1,
  );

  /// 2560 × 1440 or better.
  static final qhd2k = CameraResolutionTier(
    id: '2k',
    label: '2K',
    shortEdge: 1440,
    longEdge: 2560,
    rank: 2,
  );

  /// 3840 × 2160 or better.
  static final ultraHd4k = CameraResolutionTier(
    id: '4k',
    label: '4K',
    shortEdge: 2160,
    longEdge: 3840,
    rank: 3,
  );

  /// Canonical tiers in ascending resolution order.
  static final canonical = List<CameraResolutionTier>.unmodifiable([
    hd720,
    fullHd1080,
    qhd2k,
    ultraHd4k,
  ]);

  /// Returns the canonical tier with [id], or null when it is unknown.
  static CameraResolutionTier? fromId(String? id) {
    for (final tier in canonical) {
      if (tier.id == id) return tier;
    }
    return null;
  }

  static int _positive(int value, String name) {
    if (value <= 0) {
      throw RangeError.value(value, name, 'must be positive');
    }
    return value;
  }

  static int _nonNegative(int value) {
    if (value < 0) {
      throw RangeError.value(value, 'rank', 'must not be negative');
    }
    return value;
  }
}

/// One concrete still-image resolution supported by the active camera.
@freezed
@JsonSerializable()
class SupportedCameraResolution with _$SupportedCameraResolution {
  /// Creates a supported tier and exact dimension pair.
  SupportedCameraResolution({
    required this.tier,
    required int width,
    required int height,
  }) : width = _positive(width, 'width'),
       height = _positive(height, 'height') {
    if (!tier.isSatisfiedBy(width: width, height: height)) {
      throw ArgumentError.value(
        '$width × $height',
        'dimensions',
        'do not satisfy ${tier.label}',
      );
    }
  }

  /// Creates a supported resolution from JSON.
  factory SupportedCameraResolution.fromJson(Map<String, dynamic> json) =>
      _$SupportedCameraResolutionFromJson(json);

  /// Friendly tier this exact resolution can satisfy.
  @override
  final CameraResolutionTier tier;

  /// Actual landscape-or-portrait width reported by the camera boundary.
  @override
  final int width;

  /// Actual landscape-or-portrait height reported by the camera boundary.
  @override
  final int height;

  /// Pixel count used to choose the active camera's maximum deterministically.
  int get pixelCount => width * height;

  /// Friendly tier and exact dimensions shown together in Settings.
  String get displayLabel => '${tier.label} • $width × $height';

  /// Converts this resolution to generated JSON.
  Map<String, dynamic> toJson() => _$SupportedCameraResolutionToJson(this);

  static int _positive(int value, String name) {
    if (value <= 0) {
      throw RangeError.value(value, name, 'must be positive');
    }
    return value;
  }
}

/// The user's stable desired camera resolution.
///
/// [DesiredCameraResolution.fullResolution] is both the missing-preference
/// state and the explicit request for the active camera's maximum. A tier does
/// not persist concrete dimensions because those change across cameras.
@freezed
sealed class DesiredCameraResolution with _$DesiredCameraResolution {
  /// Requests the active camera's highest full supported resolution.
  const factory DesiredCameraResolution.fullResolution() = FullCameraResolution;

  /// Requests [value], falling back deterministically when unsupported.
  const factory DesiredCameraResolution.tier(CameraResolutionTier value) =
      TierCameraResolution;

  /// Creates a desired resolution from JSON.
  factory DesiredCameraResolution.fromJson(Map<String, dynamic> json) =>
      _$DesiredCameraResolutionFromJson(json);

  const DesiredCameraResolution._();

  /// Maps the removed image-quality preference to a desired capture tier.
  ///
  /// Missing, high, and unrecognised values all mean Full resolution. The
  /// resolved hardware dimensions are selected only after capabilities load.
  factory DesiredCameraResolution.fromLegacyImageQuality(String? legacy) =>
      switch (legacy) {
        'low' => DesiredCameraResolution.tier(CameraResolutionTier.hd720),
        'balanced' => DesiredCameraResolution.tier(
          CameraResolutionTier.fullHd1080,
        ),
        _ => const DesiredCameraResolution.fullResolution(),
      };

  /// Resolves this preference against [supported].
  ///
  /// An exact tier wins. Otherwise the highest lower tier wins; when none is
  /// lower, or Full resolution is desired, the active camera maximum wins.
  /// Null means capability enumeration supplied no concrete choices and the
  /// caller must request the camera plugin's maximum preset.
  SupportedCameraResolution? resolve(
    Iterable<SupportedCameraResolution> supported,
  ) {
    final ordered = supported.toList()..sort(_compareSupportedDescending);
    if (ordered.isEmpty) return null;

    return when(
      fullResolution: () => ordered.first,
      tier: (desiredTier) {
        for (final resolution in ordered) {
          if (resolution.tier == desiredTier) return resolution;
        }
        for (final resolution in ordered) {
          if (resolution.tier.rank < desiredTier.rank) return resolution;
        }
        return ordered.first;
      },
    );
  }

  static int _compareSupportedDescending(
    SupportedCameraResolution left,
    SupportedCameraResolution right,
  ) {
    final byTier = right.tier.rank.compareTo(left.tier.rank);
    if (byTier != 0) return byTier;
    final byPixels = right.pixelCount.compareTo(left.pixelCount);
    if (byPixels != 0) return byPixels;
    final byWidth = right.width.compareTo(left.width);
    if (byWidth != 0) return byWidth;
    return right.height.compareTo(left.height);
  }
}
