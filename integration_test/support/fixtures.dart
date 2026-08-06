/// The files a flow feeds the application.
///
/// Every fixture is checked in under `integration_test/fixtures/` and bundled
/// as an asset, because a Tier-3 flow runs on a device where the asset bundle
/// is the only way to reach a file the repository owns. They are a few hundred
/// bytes each of generated shapes and text: no photograph, no scan of anything
/// real, no personal data.
///
/// A flow never reads an asset directly. It asks for a *path*, because that is
/// what every boundary in the application takes — the scanner returns a path,
/// the importer is handed a path, the composer writes to one. [Fixtures] copies
/// the bundled bytes into the flow's own temporary directory and returns where
/// it put them, so a flow that mutates a fixture cannot affect the next one.
library;

import 'dart:io';

import 'package:flutter/services.dart';

/// Where the fixture assets live inside the bundle.
const _assetRoot = 'integration_test/fixtures';

/// The checked-in files, materialised into a directory a flow owns.
class Fixtures {
  /// Creates a fixture set writing into [directory].
  ///
  /// [directory] is the flow's own temporary directory, created and deleted by
  /// the boot helper's teardown, so nothing here outlives the flow that asked
  /// for it.
  Fixtures(this.directory);

  /// Where materialised fixtures are written.
  final Directory directory;

  final _written = <String, String>{};

  /// The first page image, as a path on disk.
  ///
  /// A light page with a dark band across it, so a crop or an enhancement has
  /// something whose effect is actually visible rather than a flat colour that
  /// looks identical however it is processed.
  Future<String> pageOne() => _materialise('page_one.png');

  /// The second page image, visibly different from [pageOne].
  ///
  /// Different so a flow asserting on page order is asserting on something: two
  /// identical pages would let a reorder bug pass.
  Future<String> pageTwo() => _materialise('page_two.png');

  /// A two-page PDF, as a path on disk.
  ///
  /// Two pages rather than one so a flow can tell "the document opened" from
  /// "the document opened at the right page".
  Future<String> sourceDocument() => _materialise('source_document.pdf');

  /// A one-page PDF for the import flow.
  ///
  /// Separate from [sourceDocument] so an import flow's assertions cannot be
  /// satisfied by a document some earlier step already put in the library.
  Future<String> importable() => _materialise('importable.pdf');

  /// Copies [name] out of the bundle and returns its path.
  ///
  /// Cached per name: a flow that asks for the same fixture twice gets the same
  /// file, which is what makes "the page I captured" and "the page in the
  /// document" comparable.
  Future<String> _materialise(String name) async {
    final existing = _written[name];
    if (existing != null) return existing;

    final bytes = await rootBundle.load('$_assetRoot/$name');
    final file = File('${directory.path}/$name');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

    return _written[name] = file.path;
  }
}
