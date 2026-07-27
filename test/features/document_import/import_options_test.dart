/// Widget tests for the import options sheet.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/contracts/models/document.dart';
import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/scanned_page_bundle.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/isolates/background_worker.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/core/storage/public_storage/in_memory_public_file_store.dart';
import 'package:doc_forge/core/theme/app_theme.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_import/application/usecases/import_usecases.dart';
import 'package:doc_forge/features/document_import/domain/import_rules.dart';
import 'package:doc_forge/features/document_import/infrastructure/repositories/fake_import_sources.dart';
import 'package:doc_forge/features/document_import/presentation/cubit/import_cubit.dart';
import 'package:doc_forge/features/document_import/presentation/cubit/import_state.dart';
import 'package:doc_forge/features/document_import/presentation/import_keys.dart';
import 'package:doc_forge/features/document_import/presentation/screens/import_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Cubit frozen at a chosen state that records what was asked of it.
///
/// The sheet's job is to show the right view for a state and route a tap to the
/// right method; whether that method then works is the Cubit test's business.
class _StubCubit extends ImportCubit {
  _StubCubit()
    : super(
        FakeGalleryPicker(),
        FakeFileBrowser(),
        ImportFiles(
          ImportImages(
            const InlineBackgroundWorker(),
            _neverStaged,
            SequentialIdGenerator(),
            _neverCopied,
          ),
          ImportPdf(
            FakePdfInspector(),
            _NeverWrites(),
            (id) => '/never/${id.value}.pdf',
            InMemoryPublicFileStore(),
            FixedClock(DateTime.utc(2026)),
            SequentialIdGenerator(),
          ),
        ),
      );

  final List<String> calls = [];

  /// Moves to [seeded], so the sheet observes a real transition.
  ///
  /// Seeded through `emit` rather than by overriding `state`, because the
  /// sheet's listener fires on a *change* of status — and a state that was
  /// always there is not a change. Overriding the getter would have made the
  /// review and done callbacks untestable.
  void seed(ImportState seeded) => emit(seeded);

  @override
  Future<void> fromGallery() async => calls.add('gallery');

  @override
  Future<void> fromFiles() async => calls.add('files');

  @override
  Future<void> submitPassword(String password) async =>
      calls.add('password:$password');

  @override
  void cancelPassword() => calls.add('cancelPassword');

  @override
  void cancel() => calls.add('cancel');

  @override
  void dismissError() => calls.add('dismiss');
}

void main() {
  Future<_StubCubit> pump(
    WidgetTester tester,
    ImportState state, {
    Brightness brightness = Brightness.light,
    Size viewport = const Size(600, 1200),
    VoidCallback? onScan,
    VoidCallback? onOpenSettings,
    ValueChanged<ScannedPageBundle>? onReadyForReview,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = _StubCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: BlocProvider<ImportCubit>.value(
            value: cubit,
            child: ImportOptionsSheet(
              onScan: onScan ?? () {},
              onOpenSettings: onOpenSettings ?? () {},
              onReadyForReview: onReadyForReview,
            ),
          ),
        ),
      ),
    );

    cubit.seed(state);
    // Two bounded pumps: a Cubit delivers its state on a microtask, so one pump
    // would still be rendering the previous one.
    await tester.pump();
    await tester.pump();

    return cubit;
  }

  const idle = ImportState.initial();

  group('sources', () {
    testWidgets('offers camera, gallery and files', (tester) async {
      await pump(tester, idle);

      expect(find.byKey(ImportKeys.sheet), findsOneWidget);
      expect(find.byKey(ImportKeys.sourceCamera), findsOneWidget);
      expect(find.byKey(ImportKeys.sourceGallery), findsOneWidget);
      expect(find.byKey(ImportKeys.sourceFiles), findsOneWidget);
    });

    testWidgets('the camera source is handled by the caller', (tester) async {
      // Scanning is a whole flow with its own route; the sheet only says which
      // source was chosen.
      var scanned = 0;
      await pump(tester, idle, onScan: () => scanned++);

      await tester.tap(find.byKey(ImportKeys.sourceCamera));
      await tester.pump();

      expect(scanned, 1);
    });

    testWidgets('the gallery and files sources route to the Cubit', (
      tester,
    ) async {
      final cubit = await pump(tester, idle);

      await tester.tap(find.byKey(ImportKeys.sourceGallery));
      await tester.pump();
      await tester.tap(find.byKey(ImportKeys.sourceFiles));
      await tester.pump();

      expect(cubit.calls, ['gallery', 'files']);
    });
  });

  group('importing', () {
    testWidgets('shows progress with the file being imported', (tester) async {
      await pump(
        tester,
        idle.copyWith(
          status: ImportStatus.importing,
          progress: const Progress(completed: 1, total: 4),
        ),
      );

      expect(find.byKey(ImportKeys.progressIndicator), findsOneWidget);
      expect(find.textContaining('Importing file 1 of 4'), findsOneWidget);
    });

    testWidgets('offers cancellation while files are copied', (tester) async {
      final cubit = await pump(
        tester,
        idle.copyWith(
          status: ImportStatus.importing,
          progress: const Progress(completed: 1, total: 4),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cubit.calls, ['cancel']);
    });

    testWidgets('reports a review bundle to the caller', (tester) async {
      final bundles = <ScannedPageBundle>[];
      const bundle = ScannedPageBundle(
        pages: [PageRef(id: PageId('p0'), imagePath: '/staged/p0.jpg')],
        source: PageSource.gallery,
      );

      await pump(
        tester,
        idle.copyWith(status: ImportStatus.readyForReview, bundle: bundle),
        onReadyForReview: bundles.add,
      );

      expect(bundles, hasLength(1));
    });
  });

  group('protected PDFs', () {
    testWidgets('prompts for a password', (tester) async {
      await pump(
        tester,
        idle.copyWith(
          status: ImportStatus.awaitingPassword,
          protectedFilePath: '/a/locked.pdf',
        ),
      );

      expect(find.byKey(ImportKeys.passwordField), findsOneWidget);
      expect(find.byKey(ImportKeys.passwordSubmitButton), findsOneWidget);
    });

    testWidgets('submits what was typed', (tester) async {
      final cubit = await pump(
        tester,
        idle.copyWith(
          status: ImportStatus.awaitingPassword,
          protectedFilePath: '/a/locked.pdf',
        ),
      );

      await tester.enterText(find.byKey(ImportKeys.passwordField), 'hunter2');
      await tester.tap(find.byKey(ImportKeys.passwordSubmitButton));
      await tester.pump();

      expect(cubit.calls, ['password:hunter2']);
    });

    testWidgets('offers a way to abandon the import', (tester) async {
      // Without one the user is stranded on a file they cannot open.
      final cubit = await pump(
        tester,
        idle.copyWith(
          status: ImportStatus.awaitingPassword,
          protectedFilePath: '/a/locked.pdf',
        ),
      );

      await tester.tap(find.byKey(ImportKeys.passwordCancelButton));
      await tester.pump();

      expect(cubit.calls, ['cancelPassword']);
    });

    testWidgets('says so when the previous attempt was rejected', (
      tester,
    ) async {
      await pump(
        tester,
        idle.copyWith(
          status: ImportStatus.awaitingPassword,
          protectedFilePath: '/a/locked.pdf',
          passwordRejected: true,
        ),
      );

      expect(find.textContaining('did not open'), findsOneWidget);
    });
  });

  group('permission denied', () {
    testWidgets('shows the permission view with a route to settings', (
      tester,
    ) async {
      var settings = 0;
      await pump(
        tester,
        idle.copyWith(
          status: ImportStatus.permissionDenied,
          failure: const Failure.permission(
            kind: PermissionKind.photos,
            permanentlyDenied: true,
          ),
        ),
        onOpenSettings: () => settings++,
      );

      expect(find.byKey(ImportKeys.permissionDeniedView), findsOneWidget);

      await tester.tap(find.byKey(ImportKeys.openSettingsButton));
      await tester.pump();

      expect(settings, 1);
    });

    testWidgets('leaves the other sources reachable', (tester) async {
      // The spec requires the remaining sources to stay usable, which a
      // permanent replacement of the sheet would not.
      final cubit = await pump(
        tester,
        idle.copyWith(
          status: ImportStatus.permissionDenied,
          failure: const Failure.permission(kind: PermissionKind.photos),
        ),
      );

      await tester.tap(find.text('Choose another source'));
      await tester.pump();

      expect(cubit.calls, contains('dismiss'));
    });
  });

  group('failures', () {
    testWidgets('shows the error view with a recovery control', (tester) async {
      await pump(
        tester,
        idle.copyWith(
          status: ImportStatus.failure,
          failure: const Failure.corruptFile(),
        ),
      );

      expect(find.byKey(ImportKeys.errorView), findsOneWidget);
      expect(find.byKey(ImportKeys.errorRetryButton), findsOneWidget);
    });

    testWidgets('a full device still offers a way forward', (tester) async {
      await pump(
        tester,
        idle.copyWith(
          status: ImportStatus.failure,
          failure: const Failure.storageFull(),
        ),
      );

      expect(find.byKey(ImportKeys.errorRetryButton), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('each source describes where content comes from', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, idle);

      for (final source in [
        ImportSource.camera,
        ImportSource.gallery,
        ImportSource.files,
      ]) {
        expect(
          find.bySemanticsLabel(source.semanticsLabel),
          findsOneWidget,
          reason: '${source.name} should describe its content source',
        );
      }

      handle.dispose();
    });

    testWidgets('every control meets the minimum touch target', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, idle);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('passes the contrast guideline in dark mode', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, idle, brightness: Brightness.dark);

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });

    testWidgets('survives a tablet viewport at double text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 1366);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cubit = _StubCubit();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child!,
          ),
          home: Scaffold(
            body: BlocProvider<ImportCubit>.value(
              value: cubit,
              child: ImportOptionsSheet(onScan: () {}, onOpenSettings: () {}),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

/// A staging directory no test reaches, because the stub never copies.
Directory _neverStaged() => throw StateError('the stub Cubit never stages');

String _neverCopied(CopyImportRequest request) =>
    throw StateError('the stub Cubit never copies');

/// A writer no test reaches.
class _NeverWrites implements DocumentWriter {
  @override
  Future<Result<Document>> save(
    Document document,
    List<DocumentPage> pages,
  ) async => throw StateError('the stub Cubit never writes');

  @override
  Future<Result<Document>> updateMetadata(Document document) async =>
      throw StateError('the stub Cubit never writes');
}
