/// Drives the Home screen.
library;

import 'package:doc_forge/core/failures/result.dart';
import 'package:doc_forge/features/app_shell/application/usecases/load_home_data.dart';
import 'package:doc_forge/features/app_shell/presentation/cubit/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the Home screen's state.
///
/// Emit, await the use case, emit. Which documents count as recent, what makes
/// the library empty and how storage is totalled are all decided in the
/// application layer and unit-tested there.
class HomeCubit extends Cubit<HomeState> {
  /// Creates the Cubit over its use case.
  HomeCubit(this._loadHomeData) : super(const HomeState.initial());

  final LoadHomeData _loadHomeData;

  /// Loads everything Home shows.
  ///
  /// Also serves retry and refresh-on-return: a document saved elsewhere must
  /// appear in recents without an app restart, which means Home reloads when it
  /// becomes visible rather than caching its first result.
  Future<void> load() async {
    emit(const HomeState.loading());

    final result = await _loadHomeData();

    emit(switch (result) {
      Success(:final value) => HomeState.loaded(value),
      Failed(:final failure) => HomeState.failed(failure),
    });
  }
}
