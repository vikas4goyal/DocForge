/// Fixture-driven previews for the iOS-only storage-location interface.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/preview_scaffold.dart';
import 'package:doc_scanly/core/storage/key_value_store.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/choose_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/application/usecases/load_storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/cloud_availability.dart';
import 'package:doc_scanly/features/cloud_storage/domain/entities/storage_location.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/scripted_icloud_platform.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/storage_location_preferences.dart';
import 'package:doc_scanly/features/cloud_storage/infrastructure/repositories/platform_cloud_container_repository.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/storage_location_state.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/storage_location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _PreviewStorageLocationCubit extends StorageLocationCubit {
  _PreviewStorageLocationCubit(this._seeded)
    : super(
        loadLocation: LoadStorageLocation(
          locations: StorageLocationPreferences(InMemoryPreferenceStore()),
          cloud: _previewCloud(),
        ),
        chooseLocation: ChooseStorageLocation(_previewCloud()),
        runMigration:
            ({
              required source,
              required destination,
              onProgress,
              shouldCancel,
            }) async => const Result<void>.success(null),
      );

  final StorageLocationState _seeded;

  @override
  StorageLocationState get state => _seeded;

  @override
  Future<void> load() async {}
}

PlatformCloudContainerRepository _previewCloud() =>
    PlatformCloudContainerRepository(ScriptedICloudPlatform());

Widget _storage(StorageLocationState state) =>
    BlocProvider<StorageLocationCubit>(
      create: (_) => _PreviewStorageLocationCubit(state),
      child: StorageLocationScreen(onBack: () {}, onImportFolder: () async {}),
    );

const _available = CloudAvailability(CloudAvailabilityStatus.available);

/// Local authority on a phone.
@Preview(
  name: 'Storage location — local',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget storageLocationLocal() => _storage(
  const StorageLocationState(
    status: StorageLocationStatus.readyLocal,
    location: StorageLocation.local,
    cloudAvailability: _available,
  ),
);

/// iCloud authority on a phone in dark mode.
@Preview(
  name: 'Storage location — iCloud, dark',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget storageLocationICloudDark() => _storage(
  const StorageLocationState(
    status: StorageLocationStatus.readyICloud,
    location: StorageLocation.iCloud,
    cloudAvailability: _available,
  ),
);

/// Startup loading state.
@Preview(
  name: 'Storage location — loading',
  group: 'Cloud storage',
  theme: appPreviewTheme,
)
Widget storageLocationLoading() => _storage(const StorageLocationState());

/// First-install state with no established cloud library or queued migration.
@Preview(
  name: 'Storage location — empty library',
  group: 'Cloud storage',
  theme: appPreviewTheme,
)
Widget storageLocationEmpty() => storageLocationLocal();

/// Selected iCloud is unavailable and cannot fall back silently.
@Preview(
  name: 'Storage location — unavailable',
  group: 'Cloud storage',
  theme: appPreviewTheme,
)
Widget storageLocationUnavailable() => _storage(
  const StorageLocationState(
    status: StorageLocationStatus.unavailable,
    location: StorageLocation.iCloud,
    cloudAvailability: CloudAvailability(CloudAvailabilityStatus.signedOut),
  ),
);

/// Migration awaits destructive confirmation.
@Preview(
  name: 'Storage location — confirmation',
  group: 'Cloud storage',
  theme: appPreviewTheme,
)
Widget storageLocationConfirmation() => _storage(
  const StorageLocationState(
    status: StorageLocationStatus.confirmationRequired,
    location: StorageLocation.local,
    cloudAvailability: _available,
    pendingChoice: StorageLocationChoice(
      source: StorageLocation.local,
      destination: StorageLocation.iCloud,
    ),
  ),
);

/// Long-running copy progress.
@Preview(
  name: 'Storage location — migration',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  theme: appPreviewTheme,
)
Widget storageLocationMigration() => _storage(
  const StorageLocationState(
    status: StorageLocationStatus.migrating,
    location: StorageLocation.local,
    cloudAvailability: _available,
    progress: .42,
    completedFiles: 420,
    totalFiles: 1000,
    canCancel: true,
  ),
);

/// Verification progress on a tablet in dark mode.
@Preview(
  name: 'Storage location — verifying, tablet dark',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget storageLocationVerifying() => _storage(
  const StorageLocationState(
    status: StorageLocationStatus.verifying,
    location: StorageLocation.local,
    cloudAvailability: _available,
    progress: .9,
    completedFiles: 900,
    totalFiles: 1000,
  ),
);

/// Confirmation copy at a large accessibility text scale.
@Preview(
  name: 'Storage location — long content',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  textScaleFactor: 2,
  theme: appPreviewTheme,
)
Widget storageLocationLongContent() => storageLocationConfirmation();

/// Recoverable migration failure with retry.
@Preview(
  name: 'Storage location — error',
  group: 'Cloud storage',
  theme: appPreviewTheme,
)
Widget storageLocationError() => _storage(
  const StorageLocationState(
    status: StorageLocationStatus.failure,
    location: StorageLocation.local,
    cloudAvailability: _available,
    failure: Failure.storage(debugDetail: 'offline'),
    pendingChoice: StorageLocationChoice(
      source: StorageLocation.local,
      destination: StorageLocation.iCloud,
    ),
    canCancel: true,
  ),
);
