import 'package:doc_scanly/core/contracts/image_processing/image_processing.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/features/image_enhancement/infrastructure/datasource/native_image_processing_data_source.dart';
import 'package:doc_scanly/features/image_enhancement/infrastructure/models/native_image_processing_dto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test.docscanly/image_processing');
  final calls = <MethodCall>[];
  Object? Function(MethodCall call)? responseFor;

  const request = ImageRenderRequest(
    requestId: 'preview-1',
    sourcePath: '/app/private/source.jpg',
    destinationPath: '/app/cache/output.jpg',
    scale: ImageRenderScale.preview,
    enhancement: EnhancementSettings(
      filter: EnhancementFilter.grayscale,
      brightness: 0.1,
    ),
    jpegQuality: 82,
    maximumPreviewDimension: 1400,
  );

  setUp(() {
    calls.clear();
    responseFor = (call) => switch (call.method) {
      'capability' => <String, Object?>{
        'schemaVersion': nativeImageProcessingSchemaVersion,
        'backend': 'android_open_gl',
        'isSupported': true,
        'maximumTextureSize': 8192,
        'supportsTiling': true,
      },
      'render' => <String, Object?>{
        'schemaVersion': nativeImageProcessingSchemaVersion,
        'result': <String, Object?>{
          'destinationPath': '/app/cache/output.jpg',
          'sourceWidth': 4000,
          'sourceHeight': 3000,
          'outputWidth': 1050,
          'outputHeight': 1400,
          'backend': 'android_open_gl',
          'timings': <String, Object?>{
            'decodeMicroseconds': 100,
            'transformMicroseconds': 200,
            'encodeMicroseconds': 300,
            'totalMicroseconds': 600,
          },
        },
      },
      'cancel' || 'dispose' => null,
      _ => throw MissingPluginException(),
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return responseFor?.call(call);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  NativeImageProcessingDataSource source() => NativeImageProcessingDataSource(
    backend: ImageProcessingBackendKind.androidOpenGl,
    channel: channel,
  );

  test('channel name remains identical to both native contracts', () {
    expect(
      NativeImageProcessingDataSource.channelName,
      'com.bruxkey.docscanly/image_processing_v1',
    );
  });

  test('reads a typed compatible capability', () async {
    final capability = await source().capability();

    expect(capability.isSupported, isTrue);
    expect(capability.backend, ImageProcessingBackendKind.androidOpenGl);
    expect(capability.maximumTextureSize, 8192);
    expect(calls.single.arguments, {
      'schemaVersion': nativeImageProcessingSchemaVersion,
    });
  });

  test('fails capability closed on wrong backend or channel error', () async {
    responseFor = (_) => <String, Object?>{
      'schemaVersion': nativeImageProcessingSchemaVersion,
      'backend': 'ios_core_image',
      'isSupported': true,
      'maximumTextureSize': 8192,
      'supportsTiling': true,
    };
    expect((await source().capability()).isSupported, isFalse);

    responseFor = (_) => throw PlatformException(code: 'initialization');
    expect((await source().capability()).isSupported, isFalse);
  });

  test(
    'sends only schema, paths, geometry/settings, and render controls',
    () async {
      final response = await source().render(request);

      expect(response, isA<ImageProcessingBackendSuccess>());
      final arguments = Map<String, Object?>.from(
        calls.single.arguments as Map<Object?, Object?>,
      );
      expect(arguments['requestId'], 'preview-1');
      expect(arguments['sourcePath'], '/app/private/source.jpg');
      expect(arguments['destinationPath'], '/app/cache/output.jpg');
      expect(arguments['scale'], 'preview');
      expect(arguments['maximumPreviewDimension'], 1400);
      expect(arguments, isNot(contains('pixels')));
      expect(arguments, isNot(contains('documentId')));
      expect(arguments, isNot(contains('ocrText')));
      expect(arguments, isNot(contains('metadata')));
    },
  );

  test(
    'maps every stable native error without retaining message or details',
    () async {
      final cases = <String, ImageProcessingFailureKind>{
        'unsupported': ImageProcessingFailureKind.unsupported,
        'initialization': ImageProcessingFailureKind.initialization,
        'context_lost': ImageProcessingFailureKind.contextLost,
        'allocation': ImageProcessingFailureKind.allocation,
        'shader': ImageProcessingFailureKind.shader,
        'codec': ImageProcessingFailureKind.codec,
        'corrupt_input': ImageProcessingFailureKind.corruptInput,
        'invalid_request': ImageProcessingFailureKind.invalidRequest,
        'invalid_path': ImageProcessingFailureKind.invalidPath,
        'storage_full': ImageProcessingFailureKind.storageFull,
        'storage': ImageProcessingFailureKind.storage,
        'cancelled': ImageProcessingFailureKind.cancelled,
        'unknown': ImageProcessingFailureKind.unexpected,
      };

      for (final MapEntry(:key, :value) in cases.entries) {
        responseFor = (_) => throw PlatformException(
          code: key,
          message: '/private/sensitive/page.jpg',
          details: <String, Object?>{'pixels': 'secret'},
        );
        final response = await source().render(request);
        final failure = response as ImageProcessingBackendFailure;

        expect(failure.kind, value);
        expect(failure.debugDetail, isNot(contains('/private')));
        expect(failure.debugDetail, isNot(contains('secret')));
      }
    },
  );

  test('maps missing, malformed, and null native responses', () async {
    responseFor = (_) => throw MissingPluginException();
    expect(
      (await source().render(request) as ImageProcessingBackendFailure).kind,
      ImageProcessingFailureKind.unsupported,
    );

    responseFor = (_) => <String, Object?>{
      'schemaVersion': 999,
      'failureKind': 'shader',
    };
    expect(
      (await source().render(request) as ImageProcessingBackendFailure).kind,
      ImageProcessingFailureKind.invalidRequest,
    );

    responseFor = (_) => null;
    expect(
      (await source().render(request) as ImageProcessingBackendFailure).kind,
      ImageProcessingFailureKind.unexpected,
    );
  });

  test('sends cancellation and makes disposal idempotent', () async {
    final api = source();

    await api.cancel('preview-1');
    await api.cancel('');
    await api.dispose();
    await api.dispose();
    await api.cancel('preview-2');

    expect(calls.map((call) => call.method), ['cancel', 'dispose']);
    expect(calls.first.arguments, {
      'schemaVersion': nativeImageProcessingSchemaVersion,
      'requestId': 'preview-1',
    });
  });

  test(
    'returns unsupported after disposal without another channel call',
    () async {
      final api = source();
      await api.dispose();
      calls.clear();

      expect((await api.capability()).isSupported, isFalse);
      expect(
        (await api.render(request) as ImageProcessingBackendFailure).kind,
        ImageProcessingFailureKind.unsupported,
      );
      expect(calls, isEmpty);
    },
  );
}
