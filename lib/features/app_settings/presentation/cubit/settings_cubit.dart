/// The Cubit driving the settings screen, and its state.
///
/// Every method is emit / await a use case / emit. What the defaults are, what
/// each choice means and what a naming pattern expands to are rules in the
/// domain layer and are unit-tested there.
library;

import 'package:doc_scanly/core/contracts/models/document.dart';
import 'package:doc_scanly/core/failures/failure.dart';
import 'package:doc_scanly/core/failures/failure_messages.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/app_settings/application/usecases/settings_usecases.dart';
import 'package:doc_scanly/features/app_settings/domain/app_settings.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Where the settings screen is in its lifecycle.
enum SettingsStatus {
  /// Settings are being read.
  loading,

  /// Settings are on screen.
  ready,

  /// A setting could not be saved.
  failure,
}

/// Immutable state of the settings screen.
class SettingsState extends Equatable {
  const SettingsState._({
    required this.status,
    required this.settings,
    this.storage,
    this.namingPreview = '',
    this.failure,
    this.isRefreshingStorage = false,
    this.storageFailure,
  });

  /// Before settings have been read.
  const SettingsState.initial()
    : this._(status: SettingsStatus.loading, settings: AppSettings.defaults);

  /// Where the screen has got to.
  final SettingsStatus status;

  /// The settings currently in effect.
  ///
  /// Never null and never absent: a screen that cannot read a preference shows
  /// the documented default rather than an empty row.
  final AppSettings settings;

  /// How much storage the library occupies, once it has been read.
  final StorageSummary? storage;

  /// An example of what the chosen naming pattern produces.
  final String namingPreview;

  /// What went wrong, when a save did.
  final Failure? failure;

  /// Whether storage usage is being re-read for the details screen.
  final bool isRefreshingStorage;

  /// A failure limited to reading storage usage.
  final Failure? storageFailure;

  /// The user-facing message for [failure].
  ///
  /// The domain's own wording is used rather than the generic failure message:
  /// the point the user needs is that their *previous* value still applies.
  String? get message =>
      failure == null ? null : SettingsCopy.writeFailureMessage;

  /// The technical message behind [failure], for diagnosis.
  String? get failureDetail => failure?.presentation.message;

  /// How the save location is described.
  String get saveLocationLabel =>
      settings.saveLocation ?? SettingsCopy.systemSaveLocation;

  @override
  List<Object?> get props => [
    status,
    settings,
    storage,
    namingPreview,
    failure,
    isRefreshingStorage,
    storageFailure,
  ];

  /// Returns a copy with the given fields replaced.
  ///
  /// [failure] is cleared unless supplied, so a resolved error cannot outlive
  /// its cause.
  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? settings,
    StorageSummary? storage,
    String? namingPreview,
    Failure? failure,
    bool? isRefreshingStorage,
    Failure? storageFailure,
    bool clearStorageFailure = false,
  }) => SettingsState._(
    status: status ?? this.status,
    settings: settings ?? this.settings,
    storage: storage ?? this.storage,
    namingPreview: namingPreview ?? this.namingPreview,
    failure: failure,
    isRefreshingStorage: isRefreshingStorage ?? this.isRefreshingStorage,
    storageFailure: clearStorageFailure
        ? null
        : (storageFailure ?? this.storageFailure),
  );
}

/// Drives the settings screen.
class SettingsCubit extends Cubit<SettingsState> {
  /// Creates the Cubit over its use cases.
  ///
  /// [onThemeChanged] publishes an accepted theme change to whatever renders
  /// the application. Injected rather than reached for, because the settings
  /// screen is several routes below the root and rebuilding the root is not
  /// something a leaf screen can do (`design.md` §14).
  SettingsCubit(
    this._load,
    this._update,
    this._previewName,
    this._storage, {
    required this.onThemeChanged,
  }) : super(const SettingsState.initial());

  final LoadSettings _load;
  final UpdateSetting _update;
  final PreviewDocumentName _previewName;
  final LoadStorageSummary _storage;

  /// Called with a theme that has been persisted successfully.
  final void Function(AppThemeChoice theme) onThemeChanged;

  /// Reads every setting and the storage summary.
  Future<void> load() async {
    emit(state.copyWith(status: SettingsStatus.loading));

    final settings = await _load();
    if (isClosed) return;

    emit(
      state.copyWith(
        status: SettingsStatus.ready,
        settings: settings,
        namingPreview: _previewName(settings.namingPattern),
      ),
    );

    // Read after the settings are on screen rather than before. Storage is one
    // row of many, and making the whole screen wait for a directory walk would
    // make settings feel slow for no benefit.
    final storage = await _storage();
    if (isClosed) return;

    final summary = storage.valueOrNull;
    if (summary != null) emit(state.copyWith(storage: summary));
  }

  /// Re-reads the storage summary.
  ///
  /// Called when the storage row is opened, which is what makes the figure fall
  /// after documents have been permanently removed.
  Future<void> refreshStorage() async {
    if (isClosed) return;
    emit(state.copyWith(isRefreshingStorage: true, clearStorageFailure: true));
    final storage = await _storage();
    if (isClosed) return;

    switch (storage) {
      case Success(:final value):
        emit(state.copyWith(storage: value, isRefreshingStorage: false));
      case Failed(:final failure):
        emit(
          state.copyWith(isRefreshingStorage: false, storageFailure: failure),
        );
    }
  }

  /// Applies a theme choice.
  Future<void> setTheme(AppThemeChoice theme) async {
    final result = await _update.theme(state.settings, theme);
    if (isClosed) return;

    _settle(result);

    // Published only after the write succeeded. Applying a theme that did not
    // persist would leave the app looking one way and restarting another.
    if (result case Success(:final value)) onThemeChanged(value.theme);
  }

  /// Applies a PDF quality preset.
  Future<void> setPdfQuality(PdfQuality quality) async =>
      _settle(await _update.pdfQuality(state.settings, quality));

  /// Applies an image quality preset.
  Future<void> setImageQuality(ImageQuality quality) async =>
      _settle(await _update.imageQuality(state.settings, quality));

  /// Applies a naming pattern and refreshes its preview.
  Future<void> setNamingPattern(NamingPattern pattern) async {
    final result = await _update.namingPattern(state.settings, pattern);
    if (isClosed) return;

    _settle(result, namingPreview: _previewName(pattern));
  }

  /// Applies a default save location, or clears it when [path] is null.
  Future<void> setSaveLocation(String? path) async =>
      _settle(await _update.saveLocation(state.settings, path));

  /// Dismisses a save failure.
  void dismissError() => emit(state.copyWith(status: SettingsStatus.ready));

  /// Emits the outcome of a save.
  void _settle(Result<AppSettings> result, {String? namingPreview}) {
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: SettingsStatus.ready,
            settings: value,
            namingPreview: namingPreview,
          ),
        );
      case Failed(:final failure):
        // `settings` is deliberately not touched: the previous value stays in
        // effect, which is exactly what the spec requires of a failed write.
        emit(state.copyWith(status: SettingsStatus.failure, failure: failure));
    }
  }
}
