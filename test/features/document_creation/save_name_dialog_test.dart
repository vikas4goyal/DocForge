/// Widget tests for the save dialog.
library;

import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/theme/app_theme.dart';
import 'package:doc_scanly/features/document_creation/presentation/creation_keys.dart';
import 'package:doc_scanly/features/document_creation/presentation/cubit/save_document_state.dart';
import 'package:doc_scanly/features/document_creation/presentation/screens/save_name_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int cancels;
  late int saves;
  late List<String> names;
  late List<bool> passwordToggles;

  setUp(() {
    cancels = 0;
    saves = 0;
    names = [];
    passwordToggles = [];
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    SaveDocumentState? state,
  }) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SaveNameDialog(
            state: state ?? const SaveDocumentState.initial(name: 'Invoice'),
            onNameChanged: names.add,
            onPasswordChanged: (_) {},
            onConfirmationChanged: (_) {},
            onPasswordEnabledChanged: passwordToggles.add,
            onCancel: () => cancels++,
            onSave: () => saves++,
          ),
        ),
      ),
    );
    // Two pumps rather than pumpAndSettle: the saving state shows a progress
    // bar that animates indefinitely, which is the point of it.
    await tester.pump();
    await tester.pump();
  }

  group('composition', () {
    testWidgets('shows a name field, cancel and save', (tester) async {
      await pumpDialog(tester);

      expect(find.byKey(CreationKeys.saveNameField), findsOneWidget);
      expect(find.byKey(CreationKeys.saveCancelButton), findsOneWidget);
      expect(find.byKey(CreationKeys.saveConfirmButton), findsOneWidget);
    });

    testWidgets('prefills the name', (tester) async {
      await pumpDialog(tester);

      expect(find.text('Invoice'), findsOneWidget);
    });

    testWidgets('offers password protection, off by default', (tester) async {
      await pumpDialog(tester);

      final toggle = tester.widget<SwitchListTile>(
        find.byKey(CreationKeys.savePasswordToggle),
      );
      expect(toggle.value, isFalse);
      expect(find.byKey(CreationKeys.savePasswordField), findsNothing);
    });
  });

  group('cancel', () {
    testWidgets('dismisses without writing anything', (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.byKey(CreationKeys.saveCancelButton));
      await tester.pumpAndSettle();

      expect(cancels, 1);
      expect(saves, 0);
    });

    testWidgets('stays available while saving', (tester) async {
      await pumpDialog(
        tester,
        state: const SaveDocumentState.initial(
          name: 'Invoice',
        ).copyWith(status: SaveStatus.saving),
      );

      // A dialog with no way out during a slow write is a trap.
      final cancel = tester.widget<TextButton>(
        find.byKey(CreationKeys.saveCancelButton),
      );
      expect(cancel.onPressed, isNotNull);
    });
  });

  group('save', () {
    testWidgets('is enabled for a valid name', (tester) async {
      await pumpDialog(tester);

      final save = tester.widget<FilledButton>(
        find.byKey(CreationKeys.saveConfirmButton),
      );
      expect(save.onPressed, isNotNull);
    });

    testWidgets('is disabled for an empty name', (tester) async {
      await pumpDialog(tester, state: const SaveDocumentState.initial());

      final save = tester.widget<FilledButton>(
        find.byKey(CreationKeys.saveConfirmButton),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('shows why an empty name is refused', (tester) async {
      await pumpDialog(tester, state: const SaveDocumentState.initial());

      expect(find.text('Enter a name.'), findsOneWidget);
    });

    testWidgets('shows why an illegal name is refused', (tester) async {
      await pumpDialog(
        tester,
        state: const SaveDocumentState.initial(name: 'Q1/Q2'),
      );

      expect(find.textContaining('cannot be used'), findsOneWidget);
    });

    testWidgets('reports what the user typed', (tester) async {
      await pumpDialog(tester);

      await tester.enterText(
        find.byKey(CreationKeys.saveNameField),
        'Statement',
      );
      await tester.pumpAndSettle();

      expect(names.last, 'Statement');
    });
  });

  group('password protection', () {
    SaveDocumentState withPassword({
      String password = '',
      String confirmation = '',
    }) => const SaveDocumentState.initial(name: 'Invoice').copyWith(
      passwordEnabled: true,
      password: password,
      confirmation: confirmation,
    );

    testWidgets('turning it on reveals two obscured fields', (tester) async {
      await pumpDialog(tester, state: withPassword());

      expect(find.byKey(CreationKeys.savePasswordField), findsOneWidget);
      expect(find.byKey(CreationKeys.savePasswordConfirmField), findsOneWidget);

      // Obscured: a password typed in the open is one a shoulder can read.
      for (final key in [
        CreationKeys.savePasswordField,
        CreationKeys.savePasswordConfirmField,
      ]) {
        final field = tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(EditableText),
          ),
        );
        expect(field.obscureText, isTrue);
      }
    });

    testWidgets('an empty password blocks saving', (tester) async {
      await pumpDialog(tester, state: withPassword());

      final save = tester.widget<FilledButton>(
        find.byKey(CreationKeys.saveConfirmButton),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('a mismatch blocks saving and says so', (tester) async {
      await pumpDialog(
        tester,
        state: withPassword(password: 'hunter2', confirmation: 'hunter3'),
      );

      final save = tester.widget<FilledButton>(
        find.byKey(CreationKeys.saveConfirmButton),
      );
      expect(save.onPressed, isNull);
      expect(find.text('The passwords do not match.'), findsOneWidget);
    });

    testWidgets('a matching pair allows saving', (tester) async {
      await pumpDialog(
        tester,
        state: withPassword(password: 'hunter2', confirmation: 'hunter2'),
      );

      final save = tester.widget<FilledButton>(
        find.byKey(CreationKeys.saveConfirmButton),
      );
      expect(save.onPressed, isNotNull);
    });

    testWidgets('the toggle reports being turned on', (tester) async {
      await pumpDialog(tester);

      await tester.tap(find.byKey(CreationKeys.savePasswordToggle));
      await tester.pumpAndSettle();

      expect(passwordToggles, [true]);
    });
  });

  group('while saving', () {
    testWidgets('shows progress and disables the controls', (tester) async {
      await pumpDialog(
        tester,
        state: const SaveDocumentState.initial(
          name: 'Invoice',
        ).copyWith(status: SaveStatus.saving),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final save = tester.widget<FilledButton>(
        find.byKey(CreationKeys.saveConfirmButton),
      );
      expect(save.onPressed, isNull);
    });
  });

  group('failure', () {
    testWidgets('shows the reason and stays open', (tester) async {
      await pumpDialog(
        tester,
        state: const SaveDocumentState.initial(name: 'Invoice').copyWith(
          status: SaveStatus.failure,
          failure: const Failure.storageFull(),
        ),
      );

      expect(find.byKey(CreationKeys.saveDialog), findsOneWidget);
      // The pages are intact, so retrying is offered rather than a dead end.
      final save = tester.widget<FilledButton>(
        find.byKey(CreationKeys.saveConfirmButton),
      );
      expect(save.onPressed, isNotNull);
    });
  });
}
