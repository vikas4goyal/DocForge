/// Fixture-driven previews for the startup migration gate.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/core/previews/preview_scaffold.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/cloud_migration_gate_cubit.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/cubit/cloud_migration_gate_state.dart';
import 'package:doc_scanly/features/cloud_storage/presentation/screens/cloud_migration_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A gate Cubit fixed to one fixture state; it never runs a migration.
class _PreviewGateCubit extends CloudMigrationGateCubit {
  _PreviewGateCubit(CloudMigrationGateState seeded)
    : super(
        runMigration:
            ({
              required source,
              required destination,
              onProgress,
              shouldCancel,
            }) async => const Result<void>.success(null),
      ) {
    emit(seeded);
  }

  @override
  Future<void> start() async {}
}

Widget _gate(CloudMigrationGateState state) =>
    BlocProvider<CloudMigrationGateCubit>(
      create: (_) => _PreviewGateCubit(state),
      child: CloudMigrationGateScreen(
        onFinished: () {},
        onContinueLocal: () {},
      ),
    );

/// Migration gate, preparing, on a phone in light mode.
@Preview(
  name: 'Migration gate — preparing, phone light',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget migrationGatePreparing() => _gate(const CloudMigrationGateState());

/// Migration gate, preparing, on a tablet in dark mode.
@Preview(
  name: 'Migration gate — preparing, tablet dark',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget migrationGatePreparingTabletDark() =>
    _gate(const CloudMigrationGateState());

/// Migration gate, copying 3 of 12, on a phone in light mode.
@Preview(
  name: 'Migration gate — copying 3 of 12, phone light',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget migrationGateCopying() => _gate(
  const CloudMigrationGateState(
    status: CloudMigrationGateStatus.copying,
    completedFiles: 3,
    totalFiles: 12,
  ),
);

/// Migration gate, copying 3 of 12, on a tablet in dark mode.
@Preview(
  name: 'Migration gate — copying 3 of 12, tablet dark',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget migrationGateCopyingTabletDark() => _gate(
  const CloudMigrationGateState(
    status: CloudMigrationGateStatus.copying,
    completedFiles: 3,
    totalFiles: 12,
  ),
);

/// Migration gate, verifying, on a phone in light mode.
@Preview(
  name: 'Migration gate — verifying, phone light',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget migrationGateVerifying() => _gate(
  const CloudMigrationGateState(
    status: CloudMigrationGateStatus.verifying,
    completedFiles: 11,
    totalFiles: 12,
  ),
);

/// Migration gate, verifying, on a tablet in dark mode.
@Preview(
  name: 'Migration gate — verifying, tablet dark',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget migrationGateVerifyingTabletDark() => _gate(
  const CloudMigrationGateState(
    status: CloudMigrationGateStatus.verifying,
    completedFiles: 11,
    totalFiles: 12,
  ),
);

/// Migration gate, completed, on a phone in light mode.
@Preview(
  name: 'Migration gate — completed, phone light',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget migrationGateCompleted() => _gate(
  const CloudMigrationGateState(
    status: CloudMigrationGateStatus.completed,
    completedFiles: 12,
    totalFiles: 12,
  ),
);

/// Migration gate, completed, on a tablet in dark mode.
@Preview(
  name: 'Migration gate — completed, tablet dark',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget migrationGateCompletedTabletDark() => _gate(
  const CloudMigrationGateState(
    status: CloudMigrationGateStatus.completed,
    completedFiles: 12,
    totalFiles: 12,
  ),
);

/// Migration gate, failed, iCloud full, on a phone in light mode.
@Preview(
  name: 'Migration gate — failed, iCloud full, phone light',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget migrationGateFailed() => _gate(
  const CloudMigrationGateState(
    status: CloudMigrationGateStatus.failed,
    completedFiles: 5,
    totalFiles: 12,
    failure: Failure.storageFull(debugDetail: 'quota'),
  ),
);

/// Migration gate, failed, iCloud full, on a tablet in dark mode.
@Preview(
  name: 'Migration gate — failed, iCloud full, tablet dark',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget migrationGateFailedTabletDark() => _gate(
  const CloudMigrationGateState(
    status: CloudMigrationGateStatus.failed,
    completedFiles: 5,
    totalFiles: 12,
    failure: Failure.storageFull(debugDetail: 'quota'),
  ),
);

/// Copying on a phone in dark mode.
@Preview(
  name: 'Migration gate — copying, phone dark',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget migrationGateCopyingDark() => migrationGateCopying();

/// Completion on a tablet in light mode.
@Preview(
  name: 'Migration gate — completed, tablet light',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  theme: appPreviewTheme,
)
Widget migrationGateCompletedTablet() => migrationGateCompleted();

/// Failure text at a large accessibility text scale on a phone.
@Preview(
  name: 'Migration gate — long failure text',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  textScaleFactor: 2,
  theme: appPreviewTheme,
)
Widget migrationGateLongContent() => migrationGateFailed();

/// Failure text at a large text scale on a tablet in dark mode.
@Preview(
  name: 'Migration gate — long failure text, tablet dark',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  textScaleFactor: 2,
  theme: appPreviewTheme,
)
Widget migrationGateLongContentTabletDark() => migrationGateFailed();

/// The default state: the move is copying documents.
@Preview(
  name: 'Migration gate — default',
  group: 'Cloud storage',
  size: PreviewSize.phone,
  theme: appPreviewTheme,
)
Widget migrationGateDefault() => migrationGateCopying();

/// An empty move: a resumed run that only had cleanup left, with zero files.
@Preview(
  name: 'Migration gate — empty, nothing left to copy',
  group: 'Cloud storage',
  size: PreviewSize.tablet,
  brightness: Brightness.dark,
  theme: appPreviewTheme,
)
Widget migrationGateEmpty() => _gate(
  const CloudMigrationGateState(status: CloudMigrationGateStatus.completed),
);
