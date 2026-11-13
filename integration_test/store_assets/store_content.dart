/// Sample content for the App Store screenshot run.
///
/// Everything here is invented: the companies, people, amounts and addresses
/// are fictional, so a screenshot can never leak anything real. PDFs are drawn
/// with `package:pdf`; "camera photos" of paper documents are drawn with
/// `dart:ui`, so the run needs no checked-in binaries.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Writes every sample PDF into [directory] and returns their paths.
///
/// The file name becomes the document title in the library. [scans] are PNG
/// photos placed one per page, giving one image-heavy document that
/// compression can visibly shrink.
Future<List<String>> writeSamplePdfs(
  Directory directory, {
  List<Uint8List> scans = const [],
}) async {
  final documents = <String, pw.Document>{
    if (scans.isNotEmpty) 'Scanned Paperwork': _scanned(scans),
    'Invoice INV-2048': _invoice(),
    'Apartment Lease Agreement': _lease(),
    'Lisbon Trip Itinerary': _itinerary(),
    'Q3 Project Report': _report(),
    'Home Insurance Policy': _policy(),
    'Electricity Bill October': _bill(),
    'Team Offsite Notes': _notes(),
    'Car Service Receipt': _serviceReceipt(),
  };

  final paths = <String>[];
  for (final entry in documents.entries) {
    final file = File('${directory.path}/${entry.key}.pdf');
    await file.writeAsBytes(await entry.value.save(), flush: true);
    paths.add(file.path);
  }
  return paths;
}

pw.Document _scanned(List<Uint8List> scans) {
  final document = pw.Document();
  for (final scan in scans) {
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(pw.MemoryImage(scan), fit: pw.BoxFit.cover),
      ),
    );
  }
  return document;
}

const _ink = PdfColor.fromInt(0xFF1F2937);
const _muted = PdfColor.fromInt(0xFF6B7280);
const _rule = PdfColor.fromInt(0xFFE5E7EB);

pw.Widget _header(String title, String subtitle, PdfColor accent) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Container(height: 6, color: accent),
    pw.SizedBox(height: 18),
    pw.Text(
      title,
      style: const pw.TextStyle(
        fontSize: 26,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    ),
    pw.SizedBox(height: 4),
    pw.Text(subtitle, style: const pw.TextStyle(fontSize: 11, color: _muted)),
    pw.SizedBox(height: 18),
  ],
);

pw.Widget _paragraph(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 10),
  child: pw.Text(
    text,
    style: const pw.TextStyle(fontSize: 11, color: _ink, lineSpacing: 3),
  ),
);

pw.Widget _section(String title, PdfColor accent) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 8, bottom: 8),
  child: pw.Text(
    title.toUpperCase(),
    style: pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: accent,
      letterSpacing: 1.2,
    ),
  ),
);

pw.Widget _table(
  List<String> headers,
  List<List<String>> rows,
  PdfColor accent,
) => pw.TableHelper.fromTextArray(
  headers: headers,
  data: rows,
  border: null,
  headerStyle: const pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.white,
  ),
  headerDecoration: pw.BoxDecoration(color: accent),
  cellStyle: const pw.TextStyle(fontSize: 10, color: _ink),
  rowDecoration: const pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: _rule)),
  ),
  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
  cellAlignments: {
    for (var i = 1; i < headers.length; i++) i: pw.Alignment.centerRight,
  },
  headerAlignments: {
    for (var i = 1; i < headers.length; i++) i: pw.Alignment.centerRight,
  },
);

pw.Document _single(List<pw.Widget> Function() body, {int pages = 1}) {
  final document = pw.Document();
  for (var page = 0; page < pages; page++) {
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(42),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: body(),
        ),
      ),
    );
  }
  return document;
}

pw.Document _invoice() {
  const accent = PdfColor.fromInt(0xFF2563EB);
  return _single(
    () => [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE',
                style: const pw.TextStyle(
                  fontSize: 30,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'No. INV-2048  |  Issued 3 Nov 2026',
                style: const pw.TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
          pw.Container(
            width: 54,
            height: 54,
            decoration: const pw.BoxDecoration(
              color: accent,
              shape: pw.BoxShape.circle,
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'NS',
              style: const pw.TextStyle(
                color: PdfColors.white,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 28),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _section('From', accent),
                _paragraph(
                  'Northwind Studio\n18 Harbour Lane\nPortsmouth PO1 2AB',
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _section('Bill to', accent),
                _paragraph(
                  'Brightleaf Café Ltd\n4 Market Street\nBristol BS1 4DJ',
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      _table(
        ['Description', 'Qty', 'Rate', 'Amount'],
        [
          ['Brand identity refresh', '1', '£1,800.00', '£1,800.00'],
          ['Menu design (4 pages)', '4', '£145.00', '£580.00'],
          ['Window signage artwork', '2', '£220.00', '£440.00'],
          ['Photography - half day', '1', '£650.00', '£650.00'],
          ['Social media templates', '12', '£35.00', '£420.00'],
        ],
        accent,
      ),
      pw.SizedBox(height: 16),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.SizedBox(
          width: 220,
          child: pw.Column(
            children: [
              _totalRow('Subtotal', '£3,890.00'),
              _totalRow('VAT (20%)', '£778.00'),
              pw.Divider(color: _rule),
              _totalRow('Total due', '£4,668.00', bold: true, color: accent),
            ],
          ),
        ),
      ),
      pw.Spacer(),
      _section('Payment', accent),
      _paragraph(
        'Please pay within 14 days by bank transfer to Northwind Studio, '
        'sort code 00-00-00, account 12345678. Thank you for your business!',
      ),
    ],
  );
}

pw.Widget _totalRow(
  String label,
  String value, {
  bool bold = false,
  PdfColor color = _ink,
}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 3),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: bold ? 13 : 11,
          fontWeight: bold ? pw.FontWeight.bold : null,
          color: color,
        ),
      ),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: bold ? 13 : 11,
          fontWeight: bold ? pw.FontWeight.bold : null,
          color: color,
        ),
      ),
    ],
  ),
);

const _lorem = [
  'The Tenant agrees to rent the Property for a fixed term of twelve months '
      'beginning on the start date, and to pay the monthly rent on or before '
      'the first day of each month.',
  'The Landlord shall keep the structure and exterior of the Property in good '
      'repair and maintain the installations for the supply of water, gas, '
      'electricity and heating.',
  'The Tenant shall keep the interior of the Property clean and in good '
      'condition, and shall not make alterations without written consent.',
  'Either party may end this agreement at the end of the fixed term by giving '
      'at least two months written notice to the other party.',
];

pw.Document _lease() {
  const accent = PdfColor.fromInt(0xFF0F766E);
  return _single(
    pages: 4,
    () => [
      _header(
        'Residential Lease Agreement',
        'Flat 3, 27 Cedar Gardens  |  Term: 1 Dec 2026 - 30 Nov 2027',
        accent,
      ),
      _section('1. Parties', accent),
      _paragraph(
        'This agreement is made between Harper Properties ("the Landlord") '
        'and Alex Morgan ("the Tenant").',
      ),
      _section('2. Rent and deposit', accent),
      _table(
        ['Item', 'Amount'],
        [
          ['Monthly rent', '£1,450.00'],
          ['Security deposit', '£1,673.00'],
          ['Holding deposit (paid)', '£330.00'],
        ],
        accent,
      ),
      pw.SizedBox(height: 10),
      _section('3. Obligations', accent),
      for (final text in _lorem) _paragraph(text),
    ],
  );
}

pw.Document _itinerary() {
  const accent = PdfColor.fromInt(0xFFEA580C);
  return _single(
    pages: 2,
    () => [
      _header('Lisbon Weekend', 'Fri 14 - Mon 17 November 2026', accent),
      _table(
        ['Day', 'Plan', 'Time'],
        [
          ['Friday', 'Flight TP1337 LHR - LIS', '07:40'],
          ['Friday', 'Check in - Casa Alfama', '14:00'],
          ['Saturday', 'Tram 28 & Castelo de São Jorge', '10:00'],
          ['Saturday', 'Dinner - Time Out Market', '19:30'],
          ['Sunday', 'Day trip to Sintra', '09:15'],
          ['Monday', 'Belém & pastéis de nata', '10:00'],
          ['Monday', 'Flight TP1336 LIS - LHR', '18:20'],
        ],
        accent,
      ),
      pw.SizedBox(height: 16),
      _section('Booking references', accent),
      _paragraph(
        'Flights: QX7R2P  |  Hotel: 88341207  |  Sintra tickets: ST-5521',
      ),
    ],
  );
}

pw.Document _report() {
  const accent = PdfColor.fromInt(0xFF7C3AED);
  return _single(
    pages: 6,
    () => [
      _header(
        'Q3 Project Report',
        'Platform team  |  July - September 2026',
        accent,
      ),
      _section('Highlights', accent),
      _paragraph(
        'Shipped offline sync to all users, reduced cold start time by 38% and '
        'closed 142 issues. Customer satisfaction rose to 4.7 out of 5.',
      ),
      _section('Milestones', accent),
      _table(
        ['Milestone', 'Owner', 'Status'],
        [
          ['Offline sync GA', 'Priya', 'Done'],
          ['Accessibility audit', 'Sam', 'Done'],
          ['New onboarding', 'Jordan', 'In review'],
          ['Tablet layouts', 'Lee', 'In progress'],
        ],
        accent,
      ),
      pw.SizedBox(height: 16),
      _section('Quarterly velocity', accent),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          for (final value in [42, 55, 61, 58, 70, 76, 83])
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 14),
              child: pw.Container(
                width: 34,
                height: value * 1.6,
                color: accent,
              ),
            ),
        ],
      ),
    ],
  );
}

pw.Document _policy() {
  const accent = PdfColor.fromInt(0xFF0369A1);
  return _single(
    pages: 3,
    () => [
      _header(
        'Home Insurance Policy',
        'Policy HX-88213-04  |  Renewal 2026/27',
        accent,
      ),
      _table(
        ['Cover', 'Limit'],
        [
          ['Buildings', '£450,000'],
          ['Contents', '£75,000'],
          ['Personal belongings', '£5,000'],
          ['Legal expenses', '£100,000'],
        ],
        accent,
      ),
      pw.SizedBox(height: 12),
      _section('Summary of cover', accent),
      for (final text in _lorem.take(3)) _paragraph(text),
    ],
  );
}

pw.Document _bill() {
  const accent = PdfColor.fromInt(0xFF16A34A);
  return _single(
    () => [
      _header('Electricity Bill', 'Account 5512 0098  |  October 2026', accent),
      _table(
        ['Charge', 'Usage', 'Cost'],
        [
          ['Day rate', '212 kWh', '£52.13'],
          ['Night rate', '96 kWh', '£12.48'],
          ['Standing charge', '31 days', '£16.43'],
        ],
        accent,
      ),
      pw.SizedBox(height: 12),
      _totalRow('Amount due 21 Nov', '£81.04', bold: true, color: accent),
    ],
  );
}

pw.Document _notes() {
  const accent = PdfColor.fromInt(0xFFDB2777);
  return _single(
    pages: 2,
    () => [
      _header('Team Offsite Notes', 'Lake District  |  9 October 2026', accent),
      _section('Decisions', accent),
      _paragraph(
        '- Move weekly planning to Tuesdays\n- Adopt the new design system\n- Quarterly hack day',
      ),
      _section('Actions', accent),
      _paragraph(
        '- Sam - draft roadmap\n- Priya - book next venue\n- Lee - share retro board',
      ),
    ],
  );
}

pw.Document _serviceReceipt() {
  const accent = PdfColor.fromInt(0xFFB45309);
  return _single(
    () => [
      _header('Service Receipt', 'Riverside Motors  |  28 Oct 2026', accent),
      _table(
        ['Work', 'Cost'],
        [
          ['Annual service', '£189.00'],
          ['Brake pads (front)', '£96.50'],
          ['Wiper blades', '£24.00'],
        ],
        accent,
      ),
      pw.SizedBox(height: 12),
      _totalRow('Paid by card', '£309.50', bold: true, color: accent),
    ],
  );
}

/// A sheet of paper, photographed on a desk.
class PaperPhoto {
  /// Describes one photo.
  const PaperPhoto({
    required this.title,
    required this.subtitle,
    required this.lines,
    required this.accent,
    this.angle = -0.035,
    this.total,
  });

  /// Heading printed on the paper.
  final String title;

  /// Line under the heading.
  final String subtitle;

  /// Body rows: label and value.
  final List<(String, String)> lines;

  /// Colour of the heading band.
  final Color accent;

  /// Rotation of the paper on the desk, in radians.
  final double angle;

  /// Optional emphasised total row.
  final (String, String)? total;
}

/// The photos the scan screenshots use.
const samplePhotos = [
  PaperPhoto(
    title: 'GREEN LEAF GROCER',
    subtitle: '12 Orchard Road  |  11/11/2026 09:42',
    accent: Color(0xFF15803D),
    lines: [
      ('Sourdough loaf', '3.20'),
      ('Free range eggs x12', '3.85'),
      ('Oat milk 1L', '1.95'),
      ('Avocados x3', '2.70'),
      ('Coffee beans 250g', '6.50'),
      ('Blueberries', '2.40'),
      ('Greek yoghurt', '2.15'),
      ('Cherry tomatoes', '1.80'),
    ],
    total: ('TOTAL', '£24.55'),
  ),
  PaperPhoto(
    title: 'Meeting Notes',
    subtitle: 'Product sync | 10 Nov 2026',
    accent: Color(0xFF2563EB),
    angle: 0.025,
    lines: [
      ('Launch date', '1 Dec'),
      ('Beta testers', '250'),
      ('Open issues', '14'),
      ('Design review', 'Thu'),
      ('Owner', 'Priya'),
      ('Next sync', '17 Nov'),
    ],
  ),
  PaperPhoto(
    title: 'Warranty Card',
    subtitle: 'Espresso machine | Model EM-400',
    accent: Color(0xFF9333EA),
    angle: -0.02,
    lines: [
      ('Purchased', '02/09/2026'),
      ('Serial no.', 'EM4-77120'),
      ('Coverage', '2 years'),
      ('Retailer', 'Kitchen & Co'),
    ],
  ),
  PaperPhoto(
    title: 'CITY PHARMACY',
    subtitle: '88 High Street | 08/11/2026',
    accent: Color(0xFFDC2626),
    angle: 0.03,
    lines: [
      ('Vitamin D 1000IU', '4.99'),
      ('Plasters x40', '2.49'),
      ('Hand cream', '3.75'),
      ('Sun cream SPF50', '8.00'),
    ],
    total: ('TOTAL', '£19.23'),
  ),
  PaperPhoto(
    title: 'Parking Permit',
    subtitle: 'Zone C residents | 2026/27',
    accent: Color(0xFF0891B2),
    angle: -0.028,
    lines: [
      ('Permit no.', 'C-40917'),
      ('Vehicle', 'AB12 CDE'),
      ('Valid from', '01/10/2026'),
      ('Valid to', '30/09/2027'),
      ('Fee paid', '£95.00'),
    ],
  ),
];

const _photoWidth = 1500.0;
const _photoHeight = 2000.0;
const _paperWidth = 1100.0;
const _paperHeight = 1560.0;

/// The paper's corners in [photo], clockwise from top-left, as fractions of
/// the image size.
List<Offset> paperCorners(PaperPhoto photo) {
  final cos = math.cos(photo.angle);
  final sin = math.sin(photo.angle);
  return [
    const Offset(-_paperWidth / 2, -_paperHeight / 2),
    const Offset(_paperWidth / 2, -_paperHeight / 2),
    const Offset(_paperWidth / 2, _paperHeight / 2),
    const Offset(-_paperWidth / 2, _paperHeight / 2),
  ].map((p) {
    final x = p.dx * cos - p.dy * sin + _photoWidth / 2;
    final y = p.dx * sin + p.dy * cos + _photoHeight / 2;
    return Offset(x / _photoWidth, y / _photoHeight);
  }).toList();
}

/// Renders [photo] as PNG bytes.
///
/// Must run inside `tester.runAsync`, because rasterising waits on the engine.
Future<Uint8List> renderPaperPhoto(PaperPhoto photo) async {
  const width = _photoWidth;
  const height = _photoHeight;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Desk: warm wood-ish gradient with soft grain.
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(width, height),
        const [Color(0xFF6B4F3A), Color(0xFF4A3527), Color(0xFF5C4331)],
        const [0, 0.55, 1],
      ),
  );
  final grain = Paint()..strokeWidth = 2;
  final random = math.Random(7);
  for (var i = 0; i < 160; i++) {
    final y = random.nextDouble() * height;
    grain.color = Color.fromARGB(18 + random.nextInt(20), 20, 10, 0);
    canvas.drawLine(
      Offset(0, y),
      Offset(width, y + random.nextDouble() * 40 - 20),
      grain,
    );
  }

  const paperWidth = _paperWidth;
  const paperHeight = _paperHeight;
  canvas
    ..save()
    ..translate(width / 2, height / 2)
    ..rotate(photo.angle);
  const paper = Rect.fromLTWH(
    -paperWidth / 2,
    -paperHeight / 2,
    paperWidth,
    paperHeight,
  );
  canvas
    ..drawRect(
      paper.shift(const Offset(18, 26)),
      Paint()
        ..color = const Color(0x77000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    )
    ..drawRect(
      paper,
      Paint()
        ..shader = ui.Gradient.linear(paper.topLeft, paper.bottomRight, const [
          Color(0xFFFFFFFF),
          Color(0xFFF3F1EC),
        ]),
    )
    ..drawRect(
      Rect.fromLTWH(paper.left, paper.top, paperWidth, 26),
      Paint()..color = photo.accent,
    );

  var y = paper.top + 110;
  void text(
    String value,
    double x,
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = const Color(0xFF1F2937),
    TextAlign align = TextAlign.left,
    double maxWidth = paperWidth - 180,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color,
          fontFamily: 'Courier',
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: maxWidth, maxWidth: maxWidth);
    painter.paint(canvas, Offset(x, y));
  }

  const left = -paperWidth / 2 + 90;
  text(photo.title, left, 64, weight: FontWeight.w700, color: photo.accent);
  y += 96;
  text(photo.subtitle, left, 34, color: const Color(0xFF6B7280));
  y += 90;

  final dash = Paint()
    ..color = const Color(0xFFB8B8B8)
    ..strokeWidth = 3;
  for (var x = left; x < -left; x += 28) {
    canvas.drawLine(Offset(x, y), Offset(x + 14, y), dash);
  }
  y += 50;

  for (final (label, value) in photo.lines) {
    text(label, left, 40);
    text(value, left, 40, align: TextAlign.right);
    y += 82;
  }

  final total = photo.total;
  if (total != null) {
    y += 10;
    for (var x = left; x < -left; x += 28) {
      canvas.drawLine(Offset(x, y), Offset(x + 14, y), dash);
    }
    y += 40;
    text(total.$1, left, 52, weight: FontWeight.w700);
    text(total.$2, left, 52, weight: FontWeight.w700, align: TextAlign.right);
    y += 120;
    text(
      'THANK YOU FOR SHOPPING LOCAL',
      left,
      30,
      color: const Color(0xFF6B7280),
      align: TextAlign.center,
    );
    y += 70;
    // A barcode, because receipts have them.
    final bar = Paint()..color = const Color(0xFF1F2937);
    var x = left + 170;
    final barcode = math.Random(3);
    while (x < -left - 170) {
      final w = 4.0 + barcode.nextInt(9);
      canvas.drawRect(Rect.fromLTWH(x, y, w, 110), bar);
      x += w + 4 + barcode.nextInt(8);
    }
  } else {
    y += 40;
    final scribble = Paint()
      ..color = photo.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(left + 20, y + 60);
    for (var i = 0; i < 8; i++) {
      path.relativeQuadraticBezierTo(30, -70, 60, 0);
    }
    canvas.drawPath(path, scribble);
  }

  canvas.restore();

  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}
