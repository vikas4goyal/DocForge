/// The contracts behind text recognition.
library;

import 'package:doc_forge/core/contracts/models/ids.dart';
import 'package:doc_forge/core/contracts/models/recognised_text.dart';
import 'package:doc_forge/core/failures/result.dart';

/// A language recognition can run in.
///
/// ML Kit groups languages by *script* rather than by language: one recogniser
/// reads every Latin-script language, another every Chinese one, and so on. The
/// enum follows that grouping because it is what the engine actually offers —
/// modelling individual languages would promise a distinction the recogniser
/// cannot make.
enum OcrScript {
  /// Latin script: English, Spanish, French, German, Portuguese and around
  /// fifty more.
  ///
  /// Bundled into the application binary, so it works with no network and no
  /// first-use download.
  latin('la', 'Latin', bundled: true),

  /// Chinese script.
  chinese('zh', 'Chinese', bundled: false),

  /// Devanagari script: Hindi, Marathi, Nepali and others.
  devanagari('hi', 'Devanagari', bundled: false),

  /// Japanese script.
  japanese('ja', 'Japanese', bundled: false),

  /// Korean script.
  korean('ko', 'Korean', bundled: false);

  const OcrScript(this.languageTag, this.label, {required this.bundled});

  /// BCP-47 tag recorded against a recognition result.
  final String languageTag;

  /// The name shown to the user.
  final String label;

  /// Whether the recogniser ships inside the application.
  ///
  /// Only [latin] does. The others are separate ML Kit recognisers that have to
  /// be installed before they can be used, which is why availability is a
  /// question the UI has to be able to ask — see [OcrLanguagePacks].
  final bool bundled;

  /// The script recognition uses when the user has chosen nothing.
  static const defaultScript = OcrScript.latin;

  /// The script with [languageTag], or the default when none matches.
  ///
  /// Falls back rather than throwing so a settings value written by an older
  /// release, or by a build that shipped a script this one does not, degrades
  /// to working recognition instead of an error.
  static OcrScript fromTag(String? languageTag) => values.firstWhere(
    (script) => script.languageTag == languageTag,
    orElse: () => defaultScript,
  );
}

/// Reports which recognition scripts can actually be used on this device.
///
/// A separate contract from [OcrRepository] because "can I recognise Japanese"
/// is a question about the installation, not about a page. Settings needs to
/// answer it without running recognition, and the answer changes when a pack is
/// installed.
abstract interface class OcrLanguagePacks {
  /// The scripts recognition can run in right now.
  ///
  /// Always contains [OcrScript.latin], which is bundled.
  Future<Result<Set<OcrScript>>> available();

  /// Installs the recogniser for [script].
  ///
  /// Fails when the script is not offered by this build. Installing a bundled
  /// script succeeds immediately without doing anything.
  Future<Result<void>> install(OcrScript script);
}

/// Recognises text on a page image.
///
/// Runs entirely on the device: no page image, and no recognised text, is ever
/// sent anywhere. That is a security requirement rather than a performance one.
abstract interface class OcrRepository {
  /// Recognises the text in the image at [imagePath] for [pageId].
  ///
  /// Returns an empty [RecognisedText] for a page with nothing legible on it —
  /// that is a valid outcome, not a failure, and the spec requires it to be
  /// stored rather than reported as an error.
  ///
  /// Fails when the image cannot be read or the recogniser is unavailable.
  Future<Result<RecognisedText>> recognise({
    required PageId pageId,
    required String imagePath,
    required OcrScript script,
  });

  /// Releases the recogniser's native resources.
  ///
  /// ML Kit holds a native recogniser per script; leaving them open across a
  /// long session leaks memory that the Dart heap cannot account for.
  Future<void> dispose();
}

/// Stores and retrieves recognition results.
///
/// Separate from [OcrRepository] because recognising and remembering are
/// different concerns with different failure modes, and because the "a page is
/// recognised at most once" rule needs to be enforceable without touching the
/// recogniser at all.
abstract interface class OcrTextStore {
  /// Returns the stored result for [pageId], or null when there is none.
  ///
  /// Absence is a successful null rather than a failure: a page that has never
  /// been recognised is a normal state.
  Future<Result<RecognisedText?>> find(PageId pageId);

  /// Returns the stored results for [pageIds], in the order requested.
  ///
  /// Pages with no stored result are omitted. Batched because deciding what a
  /// document still needs recognising is one question, and asking it page by
  /// page turns a fifty-page document into fifty round trips.
  Future<Result<Map<PageId, RecognisedText>>> findAll(List<PageId> pageIds);

  /// Stores [text] against [documentId], replacing any previous result for the
  /// same page.
  ///
  /// The owning document is taken here rather than looked up, because
  /// permanently removing a document has to be able to delete its recognised
  /// text after its pages are already gone — so the link cannot be derived from
  /// the page at that point, and has to have been recorded at write time.
  Future<Result<void>> save(RecognisedText text, DocumentId documentId);

  /// Removes the stored result for [pageId].
  Future<Result<void>> remove(PageId pageId);

  /// Removes the stored results for every page of [pageIds].
  Future<Result<void>> removeAll(List<PageId> pageIds);

  /// Removes every stored result belonging to [documentId].
  ///
  /// Called when a document is permanently removed: recognised text is document
  /// content, and leaving it behind would keep readable text for a document the
  /// user believes they deleted.
  Future<Result<void>> removeForDocument(DocumentId documentId);
}
