/// Fixture-driven previews for the iOS-only storage-location status screen.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/previews/preview_scaffold.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_status.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_state.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/storage_location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A status Cubit fixed to one fixture state; it never reads iCloud.
class _PreviewStorageLocationCubit extends StorageLocationCubit {
  _PreviewStorageLocationCubit(StorageLocationState seeded)
    : super(
        loadStatus: LoadStorageStatus(
          authority: StorageLocation.local,
          cloud: PlatformCloudContainerRepository(ScriptedICloudPlatform()),
        ),
      ) {
    emit(seeded);
  }

  @override
  Future<void> load() async {}
}

Widget _storage(StorageLocationState state) =>
    BlocProvider<StorageLocationCubit>(
      create: (_) => _PreviewStorageLocationCubit(state),
      child: StorageLocationScreen(onBack: () {}, onImportFolder: () async {}),
    );

StorageLocationState _local(CloudAvailabilityStatus reason) =>
    StorageLocationState(
      status: StorageLocationStatus.localFallback,
      location: StorageLocation.local,
      cloudAvailability: CloudAvailability(reason),
    );

const _iCloud = StorageLocationState(
  status: StorageLocationStatus.iCloudActive,
  location: StorageLocation.iCloud,
  cloudAvailability: CloudAvailability(CloudAvailabilityStatus.available),
);

const _unavailable = StorageLocationState(
  status: StorageLocationStatus.unavailable,
  location: StorageLocation.iCloud,
  cloudAvailability: CloudAvailability(CloudAvailabilityStatus.signedOut),
);

const _failure = StorageLocationState(
  status: StorageLocationStatus.failure,
  failure: Failure.storage(debugDetail: 'offline'),
);

/// iCloud is the authority.
@Preview(
  name: 'Storage location — iCloud active',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget storageLocationICloud() => _storage(_iCloud);

/// iCloud is the authority, in dark mode.
@Preview(
  name: 'Storage location — iCloud active, dark',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget storageLocationICloudDark() => _storage(_iCloud);

/// iCloud is the authority on a tablet.
@Preview(
  name: 'Storage location — iCloud active, tablet',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  theme: appPreviewTheme,
)
Widget storageLocationICloudTablet() => _storage(_iCloud);

/// Device fallback because no Apple Account is signed in.
@Preview(
  name: 'Storage location — device, signed out',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget storageLocationSignedOut() =>
    _storage(_local(CloudAvailabilityStatus.signedOut));

/// Device fallback because iCloud Drive is off for DocScanly.
@Preview(
  name: 'Storage location — device, iCloud Drive off',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget storageLocationDisabled() =>
    _storage(_local(CloudAvailabilityStatus.disabled));

/// Device fallback because iCloud is restricted.
@Preview(
  name: 'Storage location — device, restricted',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  theme: appPreviewTheme,
)
Widget storageLocationRestricted() =>
    _storage(_local(CloudAvailabilityStatus.restricted));

/// Device fallback while iCloud is temporarily unavailable.
@Preview(
  name: 'Storage location — device, temporarily unavailable',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget storageLocationTemporarilyUnavailable() =>
    _storage(_local(CloudAvailabilityStatus.unavailable));

/// iCloud appeared during the session, so the library can move now.
@Preview(
  name: 'Storage location — device, move now',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget storageLocationMoveNow() =>
    _storage(_local(CloudAvailabilityStatus.available));

/// Move-now on a tablet in dark mode.
@Preview(
  name: 'Storage location — device, move now, tablet dark',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget storageLocationMoveNowTabletDark() =>
    _storage(_local(CloudAvailabilityStatus.available));

/// Status is loading.
@Preview(
  name: 'Storage location — loading',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget storageLocationLoading() => _storage(const StorageLocationState());

/// Status is loading on a tablet in dark mode.
@Preview(
  name: 'Storage location — loading, tablet dark',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget storageLocationLoadingDark() => _storage(const StorageLocationState());

/// A fresh install with nothing to move and iCloud active.
@Preview(
  name: 'Storage location — empty library',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget storageLocationEmpty() => _storage(_iCloud);

/// The iCloud library is unavailable and cannot fall back silently.
@Preview(
  name: 'Storage location — unavailable',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget storageLocationUnavailable() => _storage(_unavailable);

/// The unavailable state on a tablet in dark mode.
@Preview(
  name: 'Storage location — unavailable, tablet dark',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget storageLocationUnavailableTabletDark() => _storage(_unavailable);

/// The status could not be read.
@Preview(
  name: 'Storage location — error',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget storageLocationError() => _storage(_failure);

/// The error state on a tablet in dark mode.
@Preview(
  name: 'Storage location — error, tablet dark',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget storageLocationErrorTabletDark() => _storage(_failure);

/// Fallback copy at a large accessibility text scale.
@Preview(
  name: 'Storage location — long content',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  textScaleFactor: 2,
  theme: appPreviewTheme,
)
Widget storageLocationLongContent() =>
    _storage(_local(CloudAvailabilityStatus.disabled));

/// Fallback copy at a large text scale on a tablet in dark mode.
@Preview(
  name: 'Storage location — long content, tablet dark',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  textScaleFactor: 2,
  theme: appPreviewTheme,
)
Widget storageLocationLongContentTabletDark() =>
    _storage(_local(CloudAvailabilityStatus.disabled));

/// The default state: a library that lives in iCloud Drive.
@Preview(
  name: 'Storage location — default',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget storageLocationDefault() => _storage(_iCloud);
