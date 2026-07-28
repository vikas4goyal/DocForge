/// State for the enhancement screen.
library;

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/contracts/models/page_draft.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:equatable/equatable.dart';

/// Where the enhancement screen is in its lifecycle.
enum EnhancementStatus {
  /// The page is shown and the controls are live.
  ready,

  /// A preview is being rendered for the current settings.
  previewing,

  /// A render failed.
  failure,
}

/// Immutable state of the enhancement screen.
///
/// Holds exactly one page. Enhancement is per page — the flow adds pages one at
/// a time, so at the moment a page is enhanced there is no session of siblings
/// to apply the settings to, and pages of one document are often shot under
/// different light anyway (`design.md` D7a).
class EnhancementState extends Equatable {
  const EnhancementState._({
    required this.status,
    required this.page,
    required this.settings,
    this.history = const [],
    this.previewPath,
    this.failure,
  });

  /// Starts on [page], seeded with the settings it already carries.
  ///
  /// Seeding from the page rather than from the defaults is what makes leaving
  /// and re-entering the screen show the user the settings they last chose,
  /// instead of silently discarding them.
  EnhancementState.initial(PageDraft page)
    : this._(
        status: EnhancementStatus.ready,
        page: page,
        settings: page.enhancement,
      );

  /// Where the screen is in its lifecycle.
  final EnhancementStatus status;

  /// The page being enhanced, carrying its original and both layers.
  final PageDraft page;

  /// The settings as the user has them now.
  ///
  /// Held separately from the page's stored settings so leaving the screen
  /// without finishing leaves the page untouched.
  final EnhancementSettings settings;

  /// Settings as they were before each adjustment, oldest first.
  ///
  /// One entry per adjustment the user would think of as a step: choosing a
  /// filter, or moving a slider until they move on to something else. A drag
  /// contributes a single entry rather than one per frame, because undo has to
  /// step back through decisions, not through pixels.
  ///
  /// Distinct from reverting, which returns to the defaults in one go and is
  /// itself recorded here, so it can be undone like anything else.
  final List<EnhancementSettings> history;

  /// Whether there is an adjustment to step back through.
  bool get canUndo => history.isNotEmpty;

  /// Path to the rendered preview, once one exists.
  ///
  /// Null before the first render, when the page's original is shown instead.
  final String? previewPath;

  /// What went wrong, when something did.
  final Failure? failure;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// The image the preview should display.
  ///
  /// Falls back to the original while the first render is still running, so
  /// the screen never shows an empty frame.
  String get displayedImagePath => previewPath ?? page.originalImagePath;

  /// Whether the current settings differ from the defaults.
  ///
  /// Drives whether the revert control does anything. Named for the layer it
  /// affects: the geometry is not this screen's business.
  bool get hasChanges => !EnhancementRules.clamp(settings).isIdentity;

  /// Whether a preview is being rendered.
  bool get isPreviewing => status == EnhancementStatus.previewing;

  /// The page carrying the settings as they now stand.
  ///
  /// What the screen hands back when the user finishes.
  PageDraft get edited => page.withEnhancement(settings);

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] is cleared unless supplied, so a resolved error cannot outlive
  /// the condition that produced it.
  EnhancementState copyWith({
    EnhancementStatus? status,
    PageDraft? page,
    EnhancementSettings? settings,
    List<EnhancementSettings>? history,
    String? previewPath,
    Failure? failure,
  }) => EnhancementState._(
    status: status ?? this.status,
    page: page ?? this.page,
    settings: settings ?? this.settings,
    history: history ?? this.history,
    previewPath: previewPath ?? this.previewPath,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    page,
    settings,
    history,
    previewPath,
    failure,
  ];
}
