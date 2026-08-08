import 'dart:io';

import 'package:doc_scanly/core/contracts/models/camera_resolution.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_scanning/application/usecases/scanning_usecases.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/camera_capability_repository.dart';
import 'package:doc_scanly/features/document_scanning/domain/repositories/scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/infrastructure/camera_scanner_repository.dart';
import 'package:doc_scanly/features/document_scanning/presentation/cubit/scan_cubits.dart';
import 'package:doc_scanly/features/document_scanning/presentation/scan_keys.dart';
import 'package:doc_scanly/features/document_scanning/presentation/screens/scan_capture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Capabilities implements CameraCapabilityRepository {
  _Capabilities(this.responses);

  final List<Result<List<SupportedCameraResolution>>> responses;
  int calls = 0;

  @override
  Future<Result<List<SupportedCameraResolution>>>
  loadActiveResolutions() async => responses[calls++];
}

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

  Future<ScanCaptureCubit> pumpCapture(
    WidgetTester tester, {
    required _Capabilities capabilities,
    required DesiredCameraResolution Function() desired,
  }) async {
    final scanner = FakeScannerRepository();
    final load = LoadCameraResolutions(capabilities);
    final capture = CapturePage(
      scanner,
      const FullPageEdgeDetector(),
      resolveCaptureResolution: ResolveCaptureResolution(load),
    );
    final cubit = ScanCaptureCubit(
      scanner,
      capture,
      DiscardScanSession(
        // No staged files are touched by this component suite.
        _NoopStaging(),
        scanner,
      ),
      desiredResolution: desired,
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: ScanCaptureScreen(
            previewBuilder: (_) => const ColoredBox(color: Colors.black),
            onFinished: () {},
            onPageCaptured: (_, _) async {},
            onCancelled: () {},
            onOpenSettings: () {},
            onImportInstead: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('Full resolution shows active-camera maximum dimensions', (
    tester,
  ) async {
    await pumpCapture(
      tester,
      capabilities: _Capabilities([
        Result<List<SupportedCameraResolution>>.success([hd, ultraHd]),
      ]),
      desired: () => const DesiredCameraResolution.fullResolution(),
    );

    expect(find.text('Full resolution • 4032 by 3024'), findsOneWidget);
  });

  testWidgets('supported lower tier is requested and announced', (
    tester,
  ) async {
    await pumpCapture(
      tester,
      capabilities: _Capabilities([
        Result<List<SupportedCameraResolution>>.success([hd, fullHd]),
      ]),
      desired: () => DesiredCameraResolution.tier(CameraResolutionTier.hd720),
    );

    expect(find.text('720p • 1280 by 720'), findsOneWidget);
  });

  testWidgets('unsupported tier visibly announces its lower fallback', (
    tester,
  ) async {
    await pumpCapture(
      tester,
      capabilities: _Capabilities([
        Result<List<SupportedCameraResolution>>.success([hd, fullHd]),
      ]),
      desired: () => DesiredCameraResolution.tier(CameraResolutionTier.qhd2k),
    );

    expect(
      find.text('2K unavailable • using 1080p • 1920 by 1080'),
      findsOneWidget,
    );
  });

  testWidgets('camera switch re-resolves and updates status', (tester) async {
    final capabilities = _Capabilities([
      Result<List<SupportedCameraResolution>>.success([hd, ultraHd]),
      Result<List<SupportedCameraResolution>>.success([hd]),
    ]);
    final cubit = await pumpCapture(
      tester,
      capabilities: capabilities,
      desired: () =>
          DesiredCameraResolution.tier(CameraResolutionTier.ultraHd4k),
    );
    expect(find.text('4K • 4032 by 3024'), findsOneWidget);

    await cubit.release();
    await cubit.start();
    await tester.pumpAndSettle();

    expect(
      find.text('4K unavailable • using 720p • 1280 by 720'),
      findsOneWidget,
    );
    expect(capabilities.calls, 2);
  });

  testWidgets('capability error reaches the recoverable camera state', (
    tester,
  ) async {
    await pumpCapture(
      tester,
      capabilities: _Capabilities([
        const Result<List<SupportedCameraResolution>>.failure(Failure.camera()),
      ]),
      desired: () => const DesiredCameraResolution.fullResolution(),
    );

    expect(find.byKey(ScanKeys.cameraErrorView), findsOneWidget);
    expect(find.byKey(ScanKeys.cameraRetryButton), findsOneWidget);
  });

  testWidgets('offline unavailable probing uses plugin maximum', (
    tester,
  ) async {
    await pumpCapture(
      tester,
      capabilities: _Capabilities([
        const Result<List<SupportedCameraResolution>>.success([]),
      ]),
      desired: () => const DesiredCameraResolution.fullResolution(),
    );

    expect(find.text('Full resolution • camera maximum'), findsOneWidget);
  });
}

class _NoopStaging implements ScanStagingArea {
  @override
  Future<Result<void>> clear() async => const Result<void>.success(null);

  @override
  Future<Result<Directory>> directory() => throw UnimplementedError();
}
