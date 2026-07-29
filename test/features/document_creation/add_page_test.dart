/// Tier 1 — bringing an image into a creation session.
///
/// Both sources end in the same place: a draft over an untouched original,
/// copied into a directory the session owns. Two rules matter enough to pin
/// down, and neither is visible from the screen:
///
/// * A picked image is *copied* before it becomes a page. The photo library
///   puts files where the application may not keep a handle on them, so a page
///   built over the original would be a page that can vanish underneath it.
/// * One unreadable image out of twenty does not cost the other nineteen.
library;

import 'dart:io';

import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/storage/capture_staging.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/document_creation/application/usecases/add_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late CaptureStaging staging;
  late StagePageImage stage;

  const sessionId = 'session-1';

  setUp(() async {
    root = await Directory.systemTemp.createTemp('docforge_add_page_');
    staging = CaptureStaging(root);
    stage = StagePageImage(staging, SequentialIdGenerator(prefix: 'page'));
    staging.directoryFor(sessionId).createSync(recursive: true);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  /// Writes a source image the picker could plausibly have returned.
  Future<String> sourceImage(String name) async {
    final file = File('${root.path}/$name')
      ..writeAsBytesSync(const [1, 2, 3, 4]);
    return file.path;
  }

  group('StagePageImage', () {
    test(
      'copies the image into the session rather than referencing it',
      () async {
        final source = await sourceImage('picked.jpg');

        final staged = await stage(source, sessionId: sessionId);

        final draft = staged.valueOrNull;
        expect(draft, isNotNull);
        expect(
          draft!.originalImagePath,
          isNot(source),
          reason:
              'A page must be built over a copy the session owns; the original '
              'lives where the photo library put it and can disappear.',
        );
        expect(File(draft.originalImagePath).existsSync(), isTrue);
        expect(
          File(source).existsSync(),
          isTrue,
          reason: 'Staging copies; it must not move the user\'s own file.',
        );
      },
    );

    test('the copy lives inside the session directory', () async {
      final staged = await stage(
        await sourceImage('picked.jpg'),
        sessionId: sessionId,
      );

      // Which is what makes discarding the session enough to clean up: a page
      // written elsewhere would outlive the session that made it.
      expect(
        staged.valueOrNull!.originalImagePath,
        startsWith(staging.directoryFor(sessionId).path),
      );
    });

    test('a draft starts with neither layer applied', () async {
      final staged = await stage(
        await sourceImage('picked.jpg'),
        sessionId: sessionId,
      );

      // An imported or captured image is already whatever the user chose to
      // photograph; the crop and enhance screens are offered, not applied.
      expect(staged.valueOrNull!.hasGeometry, isFalse);
      expect(staged.valueOrNull!.hasEnhancement, isFalse);
    });

    test('a missing source is not found, not a storage failure', () async {
      final staged = await stage(
        '${root.path}/absent.jpg',
        sessionId: sessionId,
      );

      // The two lead to different recovery: a file that is gone cannot be
      // retried, where a storage failure can.
      expect(staged.isSuccess, isFalse);
      expect(staged, isA<Failed<dynamic>>());
    });
  });

  group('AddPageFromCamera', () {
    test('stages what the camera captured', () async {
      final source = await sourceImage('capture.jpg');
      final add = AddPageFromCamera(
        () async => Result<String>.success(source),
        stage,
      );

      final added = await add(sessionId: sessionId);

      expect(added.valueOrNull, isNotNull);
      expect(File(added.valueOrNull!.originalImagePath).existsSync(), isTrue);
    });

    test('a failed capture is reported, not staged', () async {
      final add = AddPageFromCamera(
        () async => const Result<String>.failure(Failure.camera()),
        stage,
      );

      final added = await add(sessionId: sessionId);

      expect(added, isA<Failed<dynamic>>());
      expect(
        staging.directoryFor(sessionId).listSync(),
        isEmpty,
        reason: 'A capture that failed must leave nothing behind.',
      );
    });
  });

  group('AddPagesFromGallery', () {
    test('stages every picked image, in the order they were chosen', () async {
      final first = await sourceImage('one.jpg');
      final second = await sourceImage('two.jpg');
      final add = AddPagesFromGallery(
        () async => Result<List<String>>.success([first, second]),
        stage,
      );

      final added = await add(sessionId: sessionId);

      // Order is the user's decision: the pages become rows in this order.
      expect(added.valueOrNull, hasLength(2));
      expect(added.valueOrNull!.map((draft) => draft.id.value).toList(), [
        'page-1',
        'page-2',
      ]);
    });

    test('an empty selection is a cancellation, not a failure', () async {
      final add = AddPagesFromGallery(
        () async => const Result<List<String>>.success([]),
        stage,
      );

      final added = await add(sessionId: sessionId);

      expect(added.isSuccess, isTrue);
      expect(added.valueOrNull, isEmpty);
    });

    test('one unreadable image does not cost the others', () async {
      final good = await sourceImage('good.jpg');
      final add = AddPagesFromGallery(
        () async =>
            Result<List<String>>.success(['${root.path}/absent.jpg', good]),
        stage,
      );

      final added = await add(sessionId: sessionId);

      // Skipped rather than fatal: one bad file out of twenty should not make
      // the user pick the other nineteen again.
      expect(added.valueOrNull, hasLength(1));
    });

    test('a failed picker is reported', () async {
      final add = AddPagesFromGallery(
        () async => const Result<List<String>>.failure(
          Failure.permission(kind: PermissionKind.photos),
        ),
        stage,
      );

      expect(await add(sessionId: sessionId), isA<Failed<dynamic>>());
    });
  });

  group('DiscardCreationSession', () {
    test('removes everything the session wrote', () async {
      await stage(await sourceImage('picked.jpg'), sessionId: sessionId);
      expect(staging.directoryFor(sessionId).listSync(), isNotEmpty);

      await DiscardCreationSession(staging)(sessionId);

      // After a save the PDF is the only representation that survives, and
      // after an abandonment there is nothing worth keeping at all.
      final directory = staging.directoryFor(sessionId);
      expect(
        !directory.existsSync() || directory.listSync().isEmpty,
        isTrue,
        reason: 'A discarded session must leave no originals behind.',
      );
    });
  });
}
