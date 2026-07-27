// Guards the native PDF engine's runtime contract.
//
// On iOS the engine binary is produced by relinking upstream's published
// static archive into a dylib — see third_party/pdf_manipulator/LOCAL_PATCH.md.
// A linkable binary is not necessarily a working one, so this asserts the
// engine actually loads and answers, rather than merely building.
//
// The engine cannot load in the host test VM (see PdfManipulatorEditor's
// library comment), so this has to run on a real device:
//
//   flutter test integration_test/pdf_engine_smoke_test.dart -d <device-id>
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf_manipulator/io.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

/// Builds a valid single-page PDF, computing the xref offsets rather than
/// hard-coding them — a hand-written table would be wrong the moment any
/// object body changed, and we would be testing the parser's error recovery
/// instead of the engine.
Uint8List minimalPdf() {
  const objects = <String>[
    '<</Type/Catalog/Pages 2 0 R>>',
    '<</Type/Pages/Kids[3 0 R]/Count 1>>',
    '<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R>>',
  ];

  final buffer = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(buffer.length);
    buffer.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }

  final xrefStart = buffer.length;
  buffer
    ..write('xref\n0 ${objects.length + 1}\n')
    ..write('0000000000 65535 f \n');
  for (final offset in offsets) {
    buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  buffer.write(
    'trailer\n<</Size ${objects.length + 1}/Root 1 0 R>>\n'
    'startxref\n$xrefStart\n%%EOF\n',
  );

  return Uint8List.fromList(buffer.toString().codeUnits);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('engine loads and initializes', () async {
    final pdf = Pdf();
    addTearDown(pdf.dispose);

    // Resolves the dylib and starts the engine worker. If the relinked
    // binary were malformed, it would fail here.
    final mode = await pdf.ensureInitialized();
    // ignore: avoid_print
    print('PDF ENGINE IO MODE: $mode');
    expect(mode, isNotNull);
  });

  test('engine parses a real PDF through FFI', () async {
    final pdf = Pdf();
    addTearDown(pdf.dispose);

    final file = File(
      '${Directory.systemTemp.path}/relink_probe.pdf',
    )..writeAsBytesSync(minimalPdf());
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final document = await pdf.open(FileSource(file));
    addTearDown(document.dispose);

    // ignore: avoid_print
    print('PDF PAGE COUNT: ${document.pageCount}');
    expect(document.pageCount, 1);
  });
}
