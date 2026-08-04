/// Golden tests for the dashboard.
///
/// Tagged `golden` and run on one canonical configuration in CI: rendering the
/// same widget on two platforms produces font-antialiasing diffs that are noise
/// rather than regressions.
@Tags(['golden'])
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_state.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

const _phone = Size(390, 844);
const _tablet = Size(1024, 1366);

/// Fixed values, so the golden is byte-stable on every machine.
Document _document(String title) => Document(
  id: DocumentId(title),
  title: title,
  createdAt: DateTime.utc(2026, 3, 14),
  updatedAt: DateTime.utc(2026, 3, 14),
  pageCount: 4,
  sizeInBytes: 482_310,
  libraryPath: LibraryPath.parse('$title.pdf'),
);

void main() {
  Widget host(DashboardState state, Brightness brightness) {
    final cubit = _SeededCubit(state);
    addTearDown(cubit.close);

    return MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      home: BlocProvider<DashboardCubit>.value(
        value: cubit,
        child: DashboardScreen(
          actions: DashboardActions(
            onOpenDocument: (_) {},
            onCreateFolder: (_) {},
            onImportPdf: () {},
          ),
        ),
      ),
    );
  }

  Future<void> pumpAt(WidgetTester tester, Widget widget, Size size) async {
    tester.view.physicalSize = size;
    // One logical pixel per physical pixel, so the golden's dimensions are the
    // viewport's rather than whatever the host machine reports.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(widget);
    // Downloading cloud rows contain an intentionally indeterminate progress
    // indicator, so settling can never complete. Two fixed frames render the
    // same deterministic animation position for every golden run.
    await tester.pump();
    await tester.pump();
  }

  final base = const DashboardState.initial().copyWith(
    status: DashboardStatus.ready,
    folders: const [
      DashboardFolder(name: 'Invoices', documentCount: 12),
      DashboardFolder(name: 'Receipts', documentCount: 3),
    ],
    documents: [_document('Statement'), _document('Contract')],
    recents: [
      _document('Statement'),
      _document('Contract'),
      _document('Receipt'),
    ],
    storageBytes: 4 * 1024 * 1024,
  );

  group('dashboard goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpAt(tester, host(base, Brightness.light), _phone);

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('dashboard_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpAt(tester, host(base, Brightness.dark), _phone);

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('dashboard_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpAt(tester, host(base, Brightness.light), _tablet);

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('dashboard_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpAt(tester, host(base, Brightness.dark), _tablet);

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('dashboard_tablet_dark.png'),
      );
    });

    testWidgets('empty, light', (tester) async {
      await pumpAt(
        tester,
        host(
          const DashboardState.initial().copyWith(
            status: DashboardStatus.ready,
          ),
          Brightness.light,
        ),
        _phone,
      );

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('dashboard_empty_light.png'),
      );
    });

    testWidgets('iCloud availability states', (tester) async {
      final values = [
        DocumentContentAvailability.remote,
        DocumentContentAvailability.downloading,
        DocumentContentAvailability.available,
        DocumentContentAvailability.failed,
      ];
      final cloud = const DashboardState.initial().copyWith(
        status: DashboardStatus.ready,
        documents: [
          for (var index = 0; index < values.length; index++)
            _document('Cloud ${index + 1}').copyWith(
              cloudResourceIdentifier: 'resource-$index',
              contentAvailability: values[index],
            ),
        ],
        recents: [
          _document('Cloud 1').copyWith(
            cloudResourceIdentifier: 'resource-0',
            contentAvailability: DocumentContentAvailability.remote,
          ),
        ],
      );
      await pumpAt(tester, host(cloud, Brightness.light), _phone);

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('dashboard_icloud_statuses.png'),
      );
    });
  });
}

/// A Cubit frozen at a chosen state, so a golden never depends on a load.
class _SeededCubit extends DashboardCubit {
  _SeededCubit(this._seeded)
    : super(store: InMemoryPublicFileStore(), index: FakeDocumentRepository());

  final DashboardState _seeded;

  @override
  DashboardState get state => _seeded;
}
