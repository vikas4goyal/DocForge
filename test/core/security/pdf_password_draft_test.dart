import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/security/pdf_password_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PdfPasswordDraft draft;

  setUp(() {
    draft = PdfPasswordDraft();
  });

  tearDown(() {
    draft.dispose();
  });

  test('exposes only a matching non-empty value for an operation', () {
    expect(draft.replace(password: 'alpha'), ValidationIssue.emptyName);
    expect(draft.readForOperation(), isNull);
    expect(
      draft.replace(confirmation: 'different'),
      ValidationIssue.passwordMismatch,
    );
    expect(draft.readForOperation(), isNull);

    expect(draft.replace(confirmation: 'alpha'), isNull);
    expect(draft.hasConfirmedValue, isTrue);
    expect(draft.readForOperation(), 'alpha');
  });

  test('replace and clear drop a prior confirmed value', () {
    draft.replace(password: 'alpha', confirmation: 'alpha');

    expect(draft.replace(password: 'beta'), ValidationIssue.passwordMismatch);
    expect(draft.readForOperation(), isNull);

    draft.clear();
    expect(draft.hasConfirmedValue, isFalse);
    expect(draft.readForOperation(), isNull);
  });

  test(
    'dispose clears the route-scoped value and diagnostics are redacted',
    () {
      draft.replace(password: 'alpha', confirmation: 'alpha');

      expect(draft.toString(), isNot(contains('alpha')));
      draft.dispose();
      expect(draft.readForOperation(), isNull);
    },
  );
}
