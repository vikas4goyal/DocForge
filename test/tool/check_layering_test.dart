import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_layering.dart';

void main() {
  group('featureOf', () {
    test('extracts the feature name from a feature path', () {
      expect(
        featureOf(
          'lib/features/document_library/domain/entities/document.dart',
        ),
        'document_library',
      );
    });

    test('returns null for core and app paths', () {
      expect(featureOf('lib/core/failures/failure.dart'), isNull);
      expect(featureOf('lib/app/router/app_router.dart'), isNull);
    });

    test('handles absolute paths', () {
      expect(
        featureOf('/Users/x/doc_forge/lib/features/ocr/domain/thing.dart'),
        'ocr',
      );
    });
  });

  group('importedFeatureOf', () {
    test('extracts the feature name from a package URI', () {
      expect(
        importedFeatureOf('package:doc_forge/features/ocr/domain/thing.dart'),
        'ocr',
      );
    });

    test('returns null for non-feature imports', () {
      expect(
        importedFeatureOf('package:doc_forge/core/contracts/x.dart'),
        isNull,
      );
      expect(importedFeatureOf('package:flutter/material.dart'), isNull);
      expect(importedFeatureOf('dart:io'), isNull);
    });
  });

  group('rule 1: domain must not import Flutter', () {
    test('flags a Flutter import in domain', () {
      final violations = checkFile(
        'lib/features/ocr/domain/entities/recognised_text.dart',
        "import 'package:flutter/material.dart';",
      );

      expect(violations, hasLength(1));
      expect(violations.single.rule, contains('must not import Flutter'));
      expect(violations.single.line, 1);
    });

    test('flags a flutter_bloc import in domain', () {
      final violations = checkFile(
        'lib/features/ocr/domain/entities/recognised_text.dart',
        "import 'package:flutter_bloc/flutter_bloc.dart';",
      );

      expect(violations, hasLength(1));
    });

    test('allows a Flutter import outside domain', () {
      final violations = checkFile(
        'lib/features/ocr/presentation/screens/ocr_screen.dart',
        "import 'package:flutter/material.dart';",
      );

      expect(violations, isEmpty);
    });
  });

  group('rule 2: application must not import infrastructure', () {
    test('flags an infrastructure import in application', () {
      final violations = checkFile(
        'lib/features/ocr/application/usecases/recognise_text.dart',
        "import 'package:doc_forge/features/ocr/infrastructure/repositories/ocr_repository_impl.dart';",
      );

      expect(violations, isNotEmpty);
      expect(
        violations.map((v) => v.rule),
        contains(contains('must not import infrastructure/')),
      );
    });

    test('allows a domain import in application', () {
      final violations = checkFile(
        'lib/features/ocr/application/usecases/recognise_text.dart',
        "import 'package:doc_forge/features/ocr/domain/repositories/ocr_repository.dart';",
      );

      expect(violations, isEmpty);
    });
  });

  group('rule 3: no cross-feature imports', () {
    test('flags an import of another feature', () {
      final violations = checkFile(
        'lib/features/document_search/application/usecases/search_documents.dart',
        "import 'package:doc_forge/features/ocr/domain/entities/recognised_text.dart';",
      );

      expect(violations, hasLength(1));
      expect(violations.single.rule, contains('must not import feature "ocr"'));
    });

    test('allows an import within the same feature', () {
      final violations = checkFile(
        'lib/features/ocr/application/usecases/recognise_text.dart',
        "import 'package:doc_forge/features/ocr/domain/entities/recognised_text.dart';",
      );

      expect(violations, isEmpty);
    });

    test('allows an import of core contracts', () {
      final violations = checkFile(
        'lib/features/document_search/application/usecases/search_documents.dart',
        "import 'package:doc_forge/core/contracts/ocr_text_source.dart';",
      );

      expect(violations, isEmpty);
    });

    test('does not flag cross-feature imports from core', () {
      final violations = checkFile(
        'lib/app/composition_root.dart',
        "import 'package:doc_forge/features/ocr/infrastructure/repositories/ocr_repository_impl.dart';",
      );

      expect(violations, isEmpty);
    });
  });

  group('exports are checked as well as imports', () {
    test('flags a cross-feature export', () {
      final violations = checkFile(
        'lib/features/document_search/domain/entities/result.dart',
        "export 'package:doc_forge/features/ocr/domain/entities/recognised_text.dart';",
      );

      expect(violations, hasLength(1));
    });
  });

  group('generated files are skipped', () {
    test('ignores .g.dart', () {
      final violations = checkFile(
        'lib/features/ocr/domain/entities/thing.g.dart',
        "import 'package:flutter/material.dart';",
      );

      expect(violations, isEmpty);
    });

    test('ignores .freezed.dart', () {
      final violations = checkFile(
        'lib/features/ocr/domain/entities/thing.freezed.dart',
        "import 'package:flutter/material.dart';",
      );

      expect(violations, isEmpty);
    });
  });

  group('passing case', () {
    test('a clean file produces no violations', () {
      const content = '''
import 'dart:io';
import 'package:doc_forge/core/contracts/document_reader.dart';
import 'package:doc_forge/features/ocr/domain/repositories/ocr_repository.dart';

class RecogniseText {}
''';

      expect(
        checkFile(
          'lib/features/ocr/application/usecases/recognise_text.dart',
          content,
        ),
        isEmpty,
      );
    });
  });

  group('multiple violations', () {
    test('reports every violation in a file, not just the first', () {
      const content = '''
import 'package:flutter/material.dart';
import 'package:doc_forge/features/other/domain/thing.dart';
''';

      final violations = checkFile(
        'lib/features/ocr/domain/entities/thing.dart',
        content,
      );

      expect(violations, hasLength(2));
      expect(violations.map((v) => v.line), [1, 2]);
    });
  });
}
