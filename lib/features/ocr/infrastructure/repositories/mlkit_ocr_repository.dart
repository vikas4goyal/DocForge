/// On-device text recognition, backed by ML Kit.
///
/// Everything here runs locally. No page image and no recognised text leaves
/// the device, which is a security requirement rather than a performance one —
/// see `specs/ocr/spec.md` and the local-only storage rule in the proposal.
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as mlkit;
import 'package:image/image.dart' as img;

/// Recognises page text using ML Kit's on-device recognisers.
///
/// Holds one native recogniser per script, created on first use and kept for
/// the session. Creating one per page is measurably slower — the recogniser
/// loads its model on construction — and the pattern the platform expects is a
/// long-lived instance closed when the owner is disposed.
class MlKitOcrRepository implements OcrRepository {
  /// Creates the repository over a [_clock].
  MlKitOcrRepository(this._clock);

  final Clock _clock;
  final _recognisers = <OcrScript, mlkit.TextRecognizer>{};

  @override
  Future<Result<RecognisedText>> recognise({
    required PageId pageId,
    required String imagePath,
    required OcrScript script,
  }) async {
    try {
      // Dimensions are read from the file rather than taken from the caller,
      // because the bounding boxes ML Kit returns are in pixels and have to be
      // normalised against the image they were actually measured on. A caller
      // describing the image wrongly would put the PDF text layer in the wrong
      // place, which is invisible until someone selects text in a reader.
      final size = await _dimensionsOf(imagePath);
      if (size == null) {
        return const Result<RecognisedText>.failure(
          Failure.unexpected(debugDetail: 'the page image could not be read'),
        );
      }

      final recogniser = _recogniserFor(script);
      final result = await recogniser.processImage(
        mlkit.InputImage.fromFilePath(imagePath),
      );

      return Result<RecognisedText>.success(
        RecognisedText(
          pageId: pageId,
          blocks: _blocksFrom(result, width: size.width, height: size.height),
          languageTag: script.languageTag,
          recognisedAt: _clock.now().toUtc(),
        ),
      );
    } on Object catch (error) {
      return Result<RecognisedText>.failure(Failure.ocr(debugDetail: '$error'));
    }
  }

  @override
  Future<void> dispose() async {
    for (final recogniser in _recognisers.values) {
      await recogniser.close();
    }
    _recognisers.clear();
  }

  /// Returns the recogniser for [script], creating it on first use.
  mlkit.TextRecognizer _recogniserFor(OcrScript script) =>
      _recognisers.putIfAbsent(
        script,
        () => mlkit.TextRecognizer(script: _scriptFor(script)),
      );

  /// Maps our script enum onto ML Kit's.
  mlkit.TextRecognitionScript _scriptFor(OcrScript script) => switch (script) {
    OcrScript.latin => mlkit.TextRecognitionScript.latin,
    OcrScript.chinese => mlkit.TextRecognitionScript.chinese,
    OcrScript.devanagari => mlkit.TextRecognitionScript.devanagiri,
    OcrScript.japanese => mlkit.TextRecognitionScript.japanese,
    OcrScript.korean => mlkit.TextRecognitionScript.korean,
  };

  /// Reads the pixel dimensions of the image at [path].
  ///
  /// Decodes only far enough to learn the size; the pixels themselves are never
  /// needed here and holding a decoded page would cost megabytes per call.
  Future<({int width, int height})?> _dimensionsOf(String path) async {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);

    return decoded == null
        ? null
        : (width: decoded.width, height: decoded.height);
  }
}

/// Converts an ML Kit result into normalised [TextBlock]s.
///
/// Exposed for testing: the mapping from pixel rectangles to normalised ones is
/// where the PDF text layer's alignment is decided, and getting it wrong is
/// invisible until someone selects text in a reader.
///
/// Blocks are taken at *line* granularity rather than at ML Kit's block
/// granularity. A "block" is a paragraph, whose bounding box spans several
/// lines of differing length — placing invisible text across that box makes
/// selection in a PDF reader grab the wrong words. A line's box is a tight fit
/// around the text it contains.
List<TextBlock> _blocksFrom(
  mlkit.RecognizedText result, {
  required int width,
  required int height,
}) {
  if (width <= 0 || height <= 0) return const [];

  return [
    for (final block in result.blocks)
      for (final line in block.lines)
        if (line.text.trim().isNotEmpty)
          TextBlock(
            text: line.text,
            bounds: NormalisedRect(
              left: (line.boundingBox.left / width).clamp(0.0, 1.0),
              top: (line.boundingBox.top / height).clamp(0.0, 1.0),
              right: (line.boundingBox.right / width).clamp(0.0, 1.0),
              bottom: (line.boundingBox.bottom / height).clamp(0.0, 1.0),
            ),
          ),
  ];
}

/// Reports which recognition scripts this build can use.
///
/// Only the Latin recogniser is bundled. The others are separate ML Kit
/// dependencies that are not compiled into this build, so they are reported as
/// unavailable rather than offered and then failing at the point of use.
///
/// This is the honest shape of the "language packs" decision: ML Kit's
/// non-Latin recognisers are chosen at build time, not downloaded at runtime,
/// so a first-use download flow cannot be built over them without also shipping
/// the models. Modelling availability behind a contract means adding a script
/// later is a build configuration change plus one line here, and the settings
/// UI already handles a script being unavailable. See `design.md` §23.
class BundledOcrLanguagePacks implements OcrLanguagePacks {
  /// Creates the reporter.
  const BundledOcrLanguagePacks();

  @override
  Future<Result<Set<OcrScript>>> available() async =>
      Result<Set<OcrScript>>.success({
        for (final script in OcrScript.values)
          if (script.bundled) script,
      });

  @override
  Future<Result<void>> install(OcrScript script) async {
    // A bundled script needs no installation, so asking for it succeeds.
    if (script.bundled) return const Result<void>.success(null);

    return const Result<void>.failure(
      Failure.ocr(
        debugDetail: 'the recogniser for this script is not in this build',
      ),
    );
  }
}
