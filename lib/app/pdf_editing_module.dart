/// Constructs the PDF-editing object graph.
///
/// Everything here is infrastructure construction, which the composition root
/// is the only place allowed to do (`design.md` §5).
library;

import 'dart:io';

import 'package:doc_forge/core/contracts/contracts.dart';
import 'package:doc_forge/core/storage/key_value_store.dart';
import 'package:doc_forge/core/time/clock.dart';
import 'package:doc_forge/features/pdf_editing/application/atomic_pdf_write.dart';
import 'package:doc_forge/features/pdf_editing/application/usecases/pdf_edit_usecases.dart';
import 'package:doc_forge/features/pdf_editing/domain/repositories/pdf_editor_repository.dart';
import 'package:doc_forge/features/pdf_editing/infrastructure/repositories/pdf_manipulator_editor.dart';
import 'package:doc_forge/features/pdf_editing/presentation/cubit/pdf_edit_cubit.dart';

/// Everything PDF editing exposes to the rest of the application.
class PdfEditingModule {
  /// Creates the module over an already-built object graph.
  const PdfEditingModule({required this.useCases, required this.editor});

  /// The use cases the editor's Cubit drives.
  final PdfEditUseCases useCases;

  /// The underlying editor, held so it can be disposed at shutdown.
  ///
  /// The engine keeps a worker alive per handle; leaving it running after the
  /// application is finished with it would keep a process around for nothing.
  final PdfEditorRepository editor;
}

/// Builds the PDF-editing module.
PdfEditingModule buildPdfEditingModule({
  required DocumentReader documentReader,
  required DocumentWriter documentWriter,
  required SecureStore secureStorage,
  required Directory documentsDirectory,
  required Clock clock,
  required IdGenerator ids,
  PdfEditorRepository? editor,
}) {
  final active = editor ?? PdfManipulatorEditor();

  final context = PdfEditContext(
    documents: documentReader,
    writer: documentWriter,
    editor: active,
    atomic: AtomicPdfWrite(
      (path, password) => active.pageCountOf(path, password: password),
    ),
    secrets: secureStorage,
    destination: (id) => '${documentsDirectory.path}/${id.value}.pdf',
    clock: clock,
    ids: ids,
  );

  return PdfEditingModule(
    editor: active,
    useCases: PdfEditUseCases(
      rotate: RotatePage(context),
      delete: DeletePages(context),
      duplicate: DuplicatePage(context),
      extract: ExtractPages(context),
      merge: MergeDocuments(context),
      split: SplitDocument(context),
      compress: CompressDocument(context),
      watermark: WatermarkDocument(context),
      protect: ProtectDocument(context),
      removePassword: RemoveDocumentPassword(context),
      metadata: ReadPdfMetadata(context),
    ),
  );
}
