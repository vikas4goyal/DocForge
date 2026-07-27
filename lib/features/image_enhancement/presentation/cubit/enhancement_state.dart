/// State for the enhancement screen.
library;

import 'package:doc_forge/core/contracts/models/page.dart';
import 'package:doc_forge/core/failures/failure.dart';
import 'package:doc_forge/core/failures/failure_messages.dart';
import 'package:doc_forge/core/isolates/cancellation.dart';
import 'package:doc_forge/features/image_enhancement/domain/enhancement_rules.dart';
import 'package:equatable/equatable.dart';

/// Where the enhancement screen is in its lifecycle.
enum EnhancementStatus {
  /// The page is shown and the controls are live.
  ready,

  /// A preview is being rendered for the current settings.
  previewing,

  /// The settings are being applied to every page of the session.
  applyingToAll,

  /// An enhancement failed.
  failure,
}

/// Immutable state of the enhancement screen.
class EnhancementState extends Equatable {
  const EnhancementState._({
    required this.status,
    required this.pages,
    required this.index,
    required this.settings,
    this.history = const [],
    this.previewPath,
    this.progress,
    this.failure,
  });

  /// Starts on [pages] at [index], seeded with that page's stored settings.
  ///
  /// Seeding from the page rather than from the defaults is what makes leaving
  /// and re-entering the screen show the user the settings they last chose,
  /// instead of silently discarding them.
  EnhancementState.initial(List<PageRef> pages, {int index = 0})
    : this._(
        status: EnhancementStatus.ready,
        pages: List.unmodifiable(pages),
        index: index.clamp(0, pages.isEmpty ? 0 : pages.length - 1),
        settings: pages.isEmpty
            ? EnhancementSettings.none
            : pages[index.clamp(0, pages.length - 1)].enhancement,
      );

  /// Where the screen is in its lifecycle.
  final EnhancementStatus status;

  /// Every page of the session, carrying its own settings.
  final List<PageRef> pages;

  /// Which page is being enhanced.
  final int index;

  /// The settings as the user has them now.
  ///
  /// Held separately from the page's stored settings so leaving the screen
  /// without saving leaves the page untouched, which the spec requires.
  final EnhancementSettings settings;

  /// Settings as they were before each adjustment, oldest first.
  ///
  /// One entry per adjustment the user would think of as a step: choosing a
  /// filter, or moving a slider until they move on to something else. A drag
  /// contributes a single entry rather than one per frame, because undo has to
  /// step back through decisions, not through pixels.
  ///
  /// Distinct from reset, which returns to the defaults in one go and is itself
  /// recorded here, so it can be undone like anything else.
  final List<EnhancementSettings> history;

  /// Whether there is an adjustment to step back through.
  bool get canUndo => history.isNotEmpty;

  /// Path to the rendered preview, once one exists.
  ///
  /// Null before the first preview has been produced, when the unmodified page
  /// is shown instead.
  final String? previewPath;

  /// How far a bulk enhancement has progressed.
  final Progress? progress;

  /// What went wrong, when something did.
  final Failure? failure;

  /// The user-facing message for [failure].
  String? get message => failure?.presentation.message;

  /// The page currently being enhanced, or null when the session is empty.
  PageRef? get page => index < pages.length ? pages[index] : null;

  /// The image the preview should display.
  ///
  /// Falls back to the unmodified page while the first preview is still being
  /// rendered, so the screen never shows an empty frame.
  String? get displayedImagePath => previewPath ?? page?.imagePath;

  /// Whether the current settings differ from the defaults.
  ///
  /// Drives whether the reset control does anything.
  bool get hasChanges => !EnhancementRules.clamp(settings).isIdentity;

  /// Whether a bulk enhancement is running.
  bool get isApplyingToAll => status == EnhancementStatus.applyingToAll;

  /// Whether a preview is being rendered.
  bool get isPreviewing => status == EnhancementStatus.previewing;

  /// Whether the session has more than one page.
  ///
  /// "Apply to all" is meaningless for a single page, so the control is hidden
  /// rather than offered and then doing nothing visible.
  bool get canApplyToAll => pages.length > 1;

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] and [progress] are cleared unless supplied, so a resolved error
  /// and a finished batch cannot outlive the conditions that produced them.
  EnhancementState copyWith({
    EnhancementStatus? status,
    List<PageRef>? pages,
    int? index,
    EnhancementSettings? settings,
    List<EnhancementSettings>? history,
    String? previewPath,
    Progress? progress,
    Failure? failure,
  }) => EnhancementState._(
    status: status ?? this.status,
    pages: pages ?? this.pages,
    index: index ?? this.index,
    settings: settings ?? this.settings,
    history: history ?? this.history,
    previewPath: previewPath ?? this.previewPath,
    progress: progress,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    pages,
    index,
    settings,
    history,
    previewPath,
    progress,
    failure,
  ];
}
