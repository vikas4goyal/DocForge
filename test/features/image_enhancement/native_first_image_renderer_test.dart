import 'dart:async';
import 'dart:io';

import 'package:doc_scanly/core/contracts/image_processing/image_processing.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/telemetry/app_telemetry.dart';
import 'package:doc_scanly/features/image_enhancement/infrastructure/repositories/native_first_image_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late _ScriptedBackend native;
  late _ScriptedBackend cpu;
  late _RecordingTelemetry telemetry;

  setUp(() {
    root = Directory.systemTemp.createTempSync('native_first_renderer');
    native = _ScriptedBackend(
      capabilityValue: const ImageProcessingCapability(
        backend: ImageProcessingBackendKind.androidOpenGl,
        isSupported: true,
        maximumTextureSize: 8192,
        supportsTiling: true,
      ),
      response: _success(
        backend: ImageProcessingBackendKind.androidOpenGl,
        destinationPath: '${root.path}/output.jpg',
      ),
    );
    cpu = _ScriptedBackend(
      capabilityValue: const ImageProcessingCapability(
        backend: ImageProcessingBackendKind.cpuFallback,
        isSupported: true,
        maximumTextureSize: 0x7fffffff,
        supportsTiling: false,
      ),
      response: _success(
        backend: ImageProcessingBackendKind.cpuFallback,
        destinationPath: '${root.path}/output.jpg',
      ),
    );
    telemetry = _RecordingTelemetry();
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  ImageRenderRequest request({String id = 'request-1'}) => ImageRenderRequest(
    requestId: id,
    sourcePath: '${root.path}/source.jpg',
    destinationPath: '${root.path}/output.jpg',
    scale: ImageRenderScale.preview,
    enhancement: const EnhancementSettings(),
    jpegQuality: 82,
    maximumPreviewDimension: 1400,
  );

  NativeFirstImageRenderer renderer() =>
      NativeFirstImageRenderer(native: native, cpu: cpu, telemetry: telemetry);

  test(
    'selects native on a compatible capability and caches the probe',
    () async {
      final api = renderer();

      final first = await api.render(request());
      final second = await api.render(request(id: 'request-2'));

      expect(
        (first as ImageProcessingBackendSuccess).result.backend,
        ImageProcessingBackendKind.androidOpenGl,
      );
      expect(second, isA<ImageProcessingBackendSuccess>());
      expect(native.capabilityCalls, 1);
      expect(native.renderCalls, 2);
      expect(cpu.renderCalls, 0);
    },
  );

  test('selects CPU without attempting native when unsupported', () async {
    native.capabilityValue = native.capabilityValue.copyWith(
      isSupported: false,
      maximumTextureSize: 0,
    );

    final output = await renderer().render(request());

    expect(
      (output as ImageProcessingBackendSuccess).result.backend,
      ImageProcessingBackendKind.cpuFallback,
    );
    expect(native.renderCalls, 0);
    expect(cpu.renderCalls, 1);
    expect(telemetry.events.single['fallback_reason'], 'unsupported');
  });

  for (final kind in ImageProcessingFailureKind.values.where(
    (value) => value.allowsCpuFallback,
  )) {
    test('falls back exactly once after ${kind.name}', () async {
      native.response = ImageProcessingBackendResponse.failure(kind: kind);

      final output = await renderer().render(request());

      expect(output, isA<ImageProcessingBackendSuccess>());
      expect(native.renderCalls, 1);
      expect(cpu.renderCalls, 1);
      expect(telemetry.events.single['fallback_reason'], kind.name);
    });
  }

  for (final kind in ImageProcessingFailureKind.values.where(
    (value) => !value.allowsCpuFallback,
  )) {
    test('does not hide non-recoverable ${kind.name}', () async {
      native.response = ImageProcessingBackendResponse.failure(kind: kind);

      final output = await renderer().render(request());

      expect((output as ImageProcessingBackendFailure).kind, kind);
      expect(cpu.renderCalls, 0);
    });
  }

  test('removes a new partial before CPU fallback', () async {
    native.response = const ImageProcessingBackendResponse.failure(
      kind: ImageProcessingFailureKind.contextLost,
    );
    native.onRender = (request) {
      File(request.destinationPath).writeAsStringSync('partial');
    };
    cpu.onRender = (request) {
      expect(File(request.destinationPath).existsSync(), isFalse);
    };

    await renderer().render(request());
  });

  test(
    'preserves a pre-existing destination until fallback publishes',
    () async {
      final existing = File('${root.path}/output.jpg')
        ..writeAsStringSync('old');
      native.response = const ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.shader,
      );
      cpu.onRender = (_) {
        expect(existing.readAsStringSync(), 'old');
      };

      await renderer().render(request());
    },
  );

  test(
    'cancellation during native work never falls back or publishes',
    () async {
      final gate = Completer<void>();
      native.renderGate = gate;
      native.response = const ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.contextLost,
      );
      final api = renderer();

      final pending = api.render(request(id: 'cancel-me'));
      await Future<void>.delayed(Duration.zero);
      await api.cancel('cancel-me');
      gate.complete();
      final output = await pending;

      expect(
        (output as ImageProcessingBackendFailure).kind,
        ImageProcessingFailureKind.cancelled,
      );
      expect(native.cancelled, contains('cancel-me'));
      expect(cpu.cancelled, contains('cancel-me'));
      expect(cpu.renderCalls, 0);
    },
  );

  test('disposes both backends once', () async {
    final api = renderer();
    await api.dispose();
    await api.dispose();

    expect(native.disposeCalls, 1);
    expect(cpu.disposeCalls, 1);
  });

  test(
    'telemetry records only bounded operational fields and timings',
    () async {
      await renderer().render(request());

      final event = telemetry.events.single;
      expect(event, {
        'backend': 'androidOpenGl',
        'render_kind': 'preview',
        'megapixel_bucket': '10_to_20mp',
        'outcome': 'success',
        'fallback_reason': 'none',
      });
      final serialized = event.toString();
      expect(serialized, isNot(contains(root.path)));
      expect(serialized, isNot(contains('source.jpg')));
      expect(serialized, isNot(contains('output.jpg')));
      expect(serialized, isNot(contains('filter')));
      expect(serialized, isNot(contains('pixels')));

      final trace = telemetry.traces.single;
      expect(trace.metrics, {
        'decode_us': 10,
        'transform_us': 20,
        'encode_us': 30,
        'total_us': 60,
      });
      expect(trace.stopped, isTrue);
    },
  );

  test(
    'telemetry records typed failure without sensitive request data',
    () async {
      native.response = const ImageProcessingBackendResponse.failure(
        kind: ImageProcessingFailureKind.invalidPath,
        debugDetail: '/private/secret.jpg',
      );

      await renderer().render(request());

      expect(telemetry.events.single['outcome'], 'invalidPath');
      expect(telemetry.events.single.toString(), isNot(contains('/private')));
      expect(telemetry.traces.single.stopped, isTrue);
    },
  );
}

ImageProcessingBackendResponse _success({
  required ImageProcessingBackendKind backend,
  required String destinationPath,
}) => ImageProcessingBackendResponse.success(
  ImageProcessingResult(
    destinationPath: destinationPath,
    sourceWidth: 4000,
    sourceHeight: 3000,
    outputWidth: 1400,
    outputHeight: 1050,
    backend: backend,
    timings: const ImageProcessingTimings(
      decodeMicroseconds: 10,
      transformMicroseconds: 20,
      encodeMicroseconds: 30,
      totalMicroseconds: 60,
    ),
  ),
);

class _ScriptedBackend implements ImageProcessingBackend {
  _ScriptedBackend({required this.capabilityValue, required this.response});

  ImageProcessingCapability capabilityValue;
  ImageProcessingBackendResponse response;
  Completer<void>? renderGate;
  void Function(ImageRenderRequest request)? onRender;
  int capabilityCalls = 0;
  int renderCalls = 0;
  int disposeCalls = 0;
  final cancelled = <String>[];

  @override
  Future<ImageProcessingCapability> capability() async {
    capabilityCalls++;
    return capabilityValue;
  }

  @override
  Future<ImageProcessingBackendResponse> render(
    ImageRenderRequest request,
  ) async {
    renderCalls++;
    onRender?.call(request);
    await renderGate?.future;
    return response;
  }

  @override
  Future<void> cancel(String requestId) async => cancelled.add(requestId);

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}

class _RecordingTelemetry implements AppTelemetry {
  final traces = <_RecordingTrace>[];
  final events = <Map<String, Object>>[];

  @override
  Future<AppTrace> startTrace(String name) async {
    final trace = _RecordingTrace(name);
    traces.add(trace);
    return trace;
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add(Map<String, Object>.from(parameters ?? const {}));
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) async {}
}

class _RecordingTrace implements AppTrace {
  _RecordingTrace(this.name);

  final String name;
  final attributes = <String, String>{};
  final metrics = <String, int>{};
  bool stopped = false;

  @override
  void putAttribute(String name, String value) => attributes[name] = value;

  @override
  void setMetric(String name, int value) => metrics[name] = value;

  @override
  Future<void> stop() async {
    stopped = true;
  }
}
