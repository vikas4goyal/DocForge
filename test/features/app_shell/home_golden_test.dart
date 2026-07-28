/// Golden tests for Home.
///
/// Tagged `golden` and run on one canonical configuration in CI: rendering the
/// same widget on two platforms produces font-antialiasing diffs that are noise,
/// not regressions.
///
/// Every input is a fixture and the Cubit is seeded rather than loaded, so a
/// golden here changes only when the layout does.
@Tags(['golden'])
library;

import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/previews/fixtures/fixtures.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/features/app_shell/application/usecases/load_home_data.dart';
import 'package:doc_forge/features/app_shell/presentation/cubit/home_cubit.dart';
import 'package:doc_forge/features/app_shell/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// A phone viewport, in logical pixels at a device pixel ratio of one.
const _phone = Size(390, 844);

/// A tablet viewport wide enough to cross the expanded breakpoint.
const _tablet = Size(1024, 1366);

void main() {
  late FakeDocumentReader documents;
  late FakeFolderReader folders;
  late FakeStorageSummaryReader storage;

  setUp(() {
    documents = FakeDocumentReader(sampleDocuments(4));
    folders = FakeFolderReader(sampleFolders(3));
    storage = FakeStorageSummaryReader(
      const StorageSummary(totalBytes: 42 * 1024 * 1024, documentCount: 18),
    );
  });

  Widget build(Brightness brightness) => MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: BlocProvider(
      create: (_) => HomeCubit(LoadHomeData(documents, folders, storage)),
      child: HomeScreen(
        actions: HomeActions(
          onScan: () {},
          onImport: () {},
          onSearch: () {},
          onOpenDocument: (_) {},
          onOpenFolder: (_) {},
          onAllDocuments: () {},
          onFolders: () {},
          onFavourites: () {},
          onArchive: () {},
          onStorage: () {},
        ),
      ),
    ),
  );

  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    Brightness brightness,
  ) async {
    tester.view.physicalSize = size;
    // One logical pixel per physical pixel, so the golden's dimensions are the
    // viewport's and do not shift with whatever the host machine reports.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(build(brightness));
    await tester.pumpAndSettle();
  }

  group('Home goldens', () {
    testWidgets('phone, light', (tester) async {
      await pumpAt(tester, _phone, Brightness.light);

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_phone_light.png'),
      );
    });

    testWidgets('phone, dark', (tester) async {
      await pumpAt(tester, _phone, Brightness.dark);

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_phone_dark.png'),
      );
    });

    testWidgets('tablet, light', (tester) async {
      await pumpAt(tester, _tablet, Brightness.light);

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_tablet_light.png'),
      );
    });

    testWidgets('tablet, dark', (tester) async {
      await pumpAt(tester, _tablet, Brightness.dark);

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_tablet_dark.png'),
      );
    });

    testWidgets('empty, light', (tester) async {
      documents.documents.clear();
      folders.folders.clear();
      storage.value = StorageSummary.empty;

      await pumpAt(tester, _phone, Brightness.light);

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_empty_light.png'),
      );
    });

    testWidgets('error, light', (tester) async {
      documents.failure = const Failure.storage();

      await pumpAt(tester, _phone, Brightness.light);

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_error_light.png'),
      );
    });
  });
}
