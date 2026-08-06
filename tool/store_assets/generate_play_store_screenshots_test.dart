/// Generates representative Google Play screenshots from the real app UI.
///
/// Run with:
///
/// ```sh
/// flutter test --update-goldens \
///   tool/store_assets/generate_play_store_screenshots_test.dart
/// ```
library;

import 'dart:io';

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/contracts/models/library_path.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_cubit.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/dashboard_state.dart';
import 'package:doc_scanly/features/document_library/presentation/screens/dashboard_screen.dart';
import 'package:doc_scanly/features/document_scanning/domain/scan_session.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/page_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/features/document_library/fakes.dart';

const _phone = _StoreDevice(
  name: 'phone',
  physicalSize: Size(1080, 1920),
  devicePixelRatio: 3,
);
const _tablet7 = _StoreDevice(
  name: 'tablet-7-inch',
  physicalSize: Size(1080, 1920),
  devicePixelRatio: 1.5,
);
const _tablet10 = _StoreDevice(
  name: 'tablet-10-inch',
  physicalSize: Size(2560, 1440),
  devicePixelRatio: 2,
);

const _devices = [_phone, _tablet7, _tablet10];

Future<ByteData> _readFont(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

Future<void> _loadAndroidFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    throw StateError('FLUTTER_ROOT must be set when generating store assets.');
  }
  final fonts = '$flutterRoot/bin/cache/artifacts/material_fonts';

  final roboto = FontLoader('Roboto')
    ..addFont(_readFont('$fonts/Roboto-Regular.ttf'))
    ..addFont(_readFont('$fonts/Roboto-Medium.ttf'))
    ..addFont(_readFont('$fonts/Roboto-Bold.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(_readFont('$fonts/MaterialIcons-Regular.otf'));
  await Future.wait([roboto.load(), icons.load()]);
}

Document _document(String title, int pages) => Document(
  id: DocumentId(title),
  title: title,
  createdAt: DateTime.utc(2026, 8, 6),
  updatedAt: DateTime.utc(2026, 8, 6),
  pageCount: pages,
  sizeInBytes: 482310,
  libraryPath: LibraryPath.parse('$title.pdf'),
);

DashboardState get _dashboardState => const DashboardState.initial().copyWith(
  status: DashboardStatus.ready,
  folders: const [
    DashboardFolder(name: 'Receipts', documentCount: 12),
    DashboardFolder(name: 'Work', documentCount: 8),
    DashboardFolder(name: 'Personal', documentCount: 5),
  ],
  documents: [
    _document('Travel receipts', 6),
    _document('Rental agreement', 12),
    _document('Project notes', 4),
    _document('Insurance policy', 9),
  ],
  recents: [
    _document('Travel receipts', 6),
    _document('Rental agreement', 12),
    _document('Project notes', 4),
  ],
  storageBytes: 18 * 1024 * 1024,
);

List<CapturedPage> get _capturedPages => List.generate(
  6,
  (index) => CapturedPage(
    id: PageId('store-page-$index'),
    imagePath: '/store/page-$index.jpg',
    quad: PageQuad.full,
    rotation: index.isOdd ? PageRotation.quarter : PageRotation.none,
  ),
);

ThemeData get _storeTheme {
  final base = AppTheme.light;
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
  );
}

Widget _dashboard() {
  final cubit = _SeededDashboardCubit(_dashboardState);
  addTearDown(cubit.close);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: _storeTheme,
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

Widget _review() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: _storeTheme,
  home: BlocProvider(
    create: (_) => PageReviewCubit(_capturedPages),
    child: PageReviewScreen(
      onSave: () {},
      onAddPages: () {},
      onExit: () {},
      onCropPage: (_, _) {},
      onEnhancePage: (_, _) {},
    ),
  ),
);

Future<void> _pumpForDevice(
  WidgetTester tester,
  Widget widget,
  _StoreDevice device,
) async {
  tester.view
    ..physicalSize = device.physicalSize
    ..devicePixelRatio = device.devicePixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(_loadAndroidFonts);

  for (final device in _devices) {
    testWidgets('${device.name} dashboard', (tester) async {
      await _pumpForDevice(tester, _dashboard(), device);
      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile(
          '../../assets/store/google-play/screenshots/${device.name}/01-dashboard.png',
        ),
      );
    });

    testWidgets('${device.name} scan review', (tester) async {
      await _pumpForDevice(tester, _review(), device);
      await expectLater(
        find.byType(PageReviewScreen),
        matchesGoldenFile(
          '../../assets/store/google-play/screenshots/${device.name}/02-scan-review.png',
        ),
      );
    });
  }
}

final class _StoreDevice {
  const _StoreDevice({
    required this.name,
    required this.physicalSize,
    required this.devicePixelRatio,
  });

  final String name;
  final Size physicalSize;
  final double devicePixelRatio;
}

final class _SeededDashboardCubit extends DashboardCubit {
  _SeededDashboardCubit(this._seeded)
    : super(store: InMemoryPublicFileStore(), index: FakeDocumentRepository());

  final DashboardState _seeded;

  @override
  DashboardState get state => _seeded;
}
