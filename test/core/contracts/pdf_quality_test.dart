import 'dart:convert';

import 'package:doc_scanly/core/contracts/models/pdf_quality.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';

void main() {
  group('PdfQualityPercent', () {
    test('accepts the inclusive 30 through 100 range', () {
      expect(PdfQualityPercent(value: 30).value, 30);
      expect(PdfQualityPercent(value: 100).value, 100);
    });

    test('rejects values outside the supported range', () {
      expect(() => PdfQualityPercent(value: 29), throwsRangeError);
      expect(() => PdfQualityPercent(value: 101), throwsRangeError);
    });

    test('rounds dimensions and never upscales', () {
      expect(PdfQualityPercent(value: 30).scaleDimension(5), 2);
      expect(PdfQualityPercent(value: 50).scaleDimension(1), 1);
      expect(PdfQualityPercent(value: 100).scaleDimension(4096), 4096);
      expect(
        () => PdfQualityPercent(value: 70).scaleDimension(0),
        throwsRangeError,
      );
    });

    test('has value equality and generated JSON round trips', () {
      final quality = PdfQualityPercent(value: 70);
      final json = jsonDecode(jsonEncode(quality.toJson()));

      expect(quality, PdfQualityPercent(value: 70));
      expect(PdfQualityPercent.fromJson(json as Map<String, dynamic>), quality);
    });

    test('validates generated JSON input', () {
      expect(
        () => PdfQualityPercent.fromJson(<String, dynamic>{'value': 20}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });

  group('PageQualityPlan', () {
    test('uses explicit overrides before the document default', () {
      final plan = PageQualityPlan(
        documentQuality: PdfQualityPercent(value: 70),
      ).withOverride('page-2', PdfQualityPercent(value: 40));

      expect(plan.effectiveFor('page-1'), PdfQualityPercent(value: 70));
      expect(plan.effectiveFor('page-2'), PdfQualityPercent(value: 40));
    });

    test('removes one override and resets every override', () {
      final plan =
          PageQualityPlan(documentQuality: PdfQualityPercent(value: 80))
              .withOverride('page-1', PdfQualityPercent(value: 30))
              .withOverride('page-2', PdfQualityPercent(value: 50));

      final oneRemoved = plan.withoutOverride('page-1');
      expect(oneRemoved.effectiveFor('page-1'), PdfQualityPercent(value: 80));
      expect(oneRemoved.effectiveFor('page-2'), PdfQualityPercent(value: 50));
      expect(oneRemoved.resetOverrides().pageOverrides, isEmpty);
      expect(
        oneRemoved.resetOverrides().documentQuality,
        PdfQualityPercent(value: 80),
      );
    });

    test('keeps earlier values immutable', () {
      final original = PageQualityPlan(
        documentQuality: PdfQualityPercent(value: 70),
        pageOverrides: {'page-1': PdfQualityPercent(value: 40)},
      );
      final changed = original.withOverride(
        'page-2',
        PdfQualityPercent(value: 50),
      );

      expect(original.pageOverrides.keys, ['page-1']);
      expect(changed.pageOverrides.keys, ['page-1', 'page-2']);
      expect(
        () => original.pageOverrides['page-3'] = PdfQualityPercent(value: 60),
        throwsUnsupportedError,
      );
    });

    test('has value equality and generated JSON round trips', () {
      final plan = PageQualityPlan(
        documentQuality: PdfQualityPercent(value: 70),
        pageOverrides: {
          'page-1': PdfQualityPercent(value: 30),
          'page-3': PdfQualityPercent(value: 100),
        },
      );
      final json = jsonDecode(jsonEncode(plan.toJson()));

      expect(PageQualityPlan.fromJson(json as Map<String, dynamic>), plan);
    });

    test('rejects an empty page identity for mutations', () {
      final plan = PageQualityPlan(
        documentQuality: PdfQualityPercent(value: 70),
      );
      expect(
        () => plan.withOverride('', PdfQualityPercent(value: 40)),
        throwsArgumentError,
      );
      expect(() => plan.withoutOverride(''), throwsArgumentError);
    });
  });
}
