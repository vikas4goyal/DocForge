/// State for the document preview and save screen.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/contracts/models/page.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/features/pdf_generation/domain/pdf_composition.dart';
import 'package:equatable/equatable.dart';

/// Where the preview screen is in its lifecycle.
enum PdfGenerationStatus {
  /// The user is reviewing the document and its name.
  ready,

  /// The PDF is being composed and the record written.
  generating,

  /// The document has been saved.
  saved,

  /// Generation or saving failed.
  failure,
}

/// Immutable state of the document preview and save screen.
class PdfGenerationState extends Equatable {
  const PdfGenerationState._({
    required this.status,
    required this.pages,
    required this.title,
    required this.quality,
    this.enteredTitle,
    this.document,
    this.failure,
  });

  /// Starts with [pages] under the generated [title].
  const PdfGenerationState.initial({
    required List<PageRef> pages,
    required String title,
    PdfQuality quality = PdfQuality.defaultQuality,
  }) : this._(
         status: PdfGenerationStatus.ready,
         pages: pages,
         title: title,
         quality: quality,
       );

  /// Where the screen is in its lifecycle.
  final PdfGenerationStatus status;

  /// The pages, in the order they will appear in the PDF.
  final List<PageRef> pages;

  /// The name generated from the configured pattern.
  ///
  /// Kept alongside [enteredTitle] rather than being overwritten by it, so
  /// clearing the field falls back to the default rather than to nothing.
  final String title;

  /// How much fidelity the PDF will keep.
  final PdfQuality quality;

  /// What the user typed, when they have typed anything.
  final String? enteredTitle;

  /// The saved document, once it exists.
  final Document? document;

  /// What went wrong, when something did.
  final Failure? failure;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// The title the document will actually be given.
  String get effectiveTitle => DocumentNaming.resolve(enteredTitle, title);

  /// Whether generation is running.
  bool get isGenerating => status == PdfGenerationStatus.generating;

  /// Whether the document has been saved.
  bool get isSaved => status == PdfGenerationStatus.saved;

  /// Whether there is anything to save.
  ///
  /// A document with no pages is not creatable, which the library forbids and
  /// the save control reflects rather than discovering on submission.
  bool get canSave => pages.isNotEmpty && !isGenerating;

  /// How many pages the document will have.
  int get pageCount => pages.length;

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] is cleared unless supplied, so a resolved error cannot outlive
  /// the condition that caused it.
  PdfGenerationState copyWith({
    PdfGenerationStatus? status,
    List<PageRef>? pages,
    String? title,
    PdfQuality? quality,
    String? enteredTitle,
    Document? document,
    Failure? failure,
  }) => PdfGenerationState._(
    status: status ?? this.status,
    pages: pages ?? this.pages,
    title: title ?? this.title,
    quality: quality ?? this.quality,
    enteredTitle: enteredTitle ?? this.enteredTitle,
    document: document ?? this.document,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    pages,
    title,
    quality,
    enteredTitle,
    document,
    failure,
  ];
}
