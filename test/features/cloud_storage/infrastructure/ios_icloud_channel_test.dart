import 'dart:async';

import 'package:doc_scanly/features/cloud_storage/infrastructure/datasource/ios_icloud_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methods = MethodChannel('test.docscanly/icloud');
  const events = EventChannel('test.docscanly/identity');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methods, (call) async {
          calls.add(call);
          return switch (call.method) {
            'availability' => 'available',
            'documentRootPath' => '/fixture/Documents',
            'readMarker' => <String, Object?>{
              'schemaVersion': 1,
              'libraryIdentifier': 'docscanly-library',
            },
            'listItems' => <Object?>[
              <String, Object?>{
                'relativePath': 'a.pdf',
                'isDirectory': false,
                'availability': 'remote',
                'sizeBytes': 7,
              },
            ],
            'pickImportFolder' => <String>['/fixture/import'],
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methods, null);
  });

  IosICloudChannel channel() =>
      const IosICloudChannel(methods: methods, events: events);

  test('channel names remain identical to Swift contract', () {
    expect(IosICloudChannel.methodChannelName, 'com.bruxkey.docscanly/icloud');
    expect(
      IosICloudChannel.eventChannelName,
      'com.bruxkey.docscanly/icloud_identity',
    );
  });

  test('reads availability, root, marker, and metadata shapes', () async {
    final api = channel();

    expect(await api.availability(), 'available');
    expect(await api.documentRootPath(), '/fixture/Documents');
    expect((await api.readMarker())?['schemaVersion'], 1);
    expect((await api.listItems()).single.values['relativePath'], 'a.pdf');
  });

  test('sends stable write, delete, and download arguments', () async {
    final api = channel();

    await api.writeMarker(const {
      'schemaVersion': 1,
      'libraryIdentifier': 'docscanly-library',
    });
    await api.ensureDownloaded('Folder/a.pdf');
    await api.deleteMarker();

    expect(calls.map((call) => call.method), [
      'writeMarker',
      'ensureDownloaded',
      'deleteMarker',
    ]);
    expect(calls[1].arguments, {'relativePath': 'Folder/a.pdf'});
  });

  test('scoped folder paths are released through the same contract', () async {
    final api = channel();
    final paths = await api.pickImportFolder();

    await api.releaseImportFolder(paths);

    expect(paths, ['/fixture/import']);
    expect(calls.last.method, 'releaseImportFolder');
    expect(calls.last.arguments, {'paths': paths});
  });

  test('startup reads fall back when native iCloud does not respond', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methods, (_) => Completer<Object?>().future);
    const api = IosICloudChannel(
      methods: methods,
      events: events,
      invocationTimeout: Duration(milliseconds: 10),
    );

    expect(await api.availability(), 'unavailable');
    expect(await api.documentRootPath(), isNull);
    expect(await api.readMarker(), isNull);
  });

  test(
    'interactive and mutating calls are not limited by startup timeout',
    () async {
      final response = Completer<Object?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methods, (_) => response.future);
      const api = IosICloudChannel(
        methods: methods,
        events: events,
        invocationTimeout: Duration(milliseconds: 10),
      );

      final deletion = api.deleteMarker();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      response.complete();
      await deletion;
    },
  );
}
