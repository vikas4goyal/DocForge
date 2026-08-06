/// State coordination for recoverable Trash.
library;

import 'package:doc_scanly/core/contracts/models/ids.dart';
import 'package:doc_scanly/core/failures/result.dart';
import 'package:doc_scanly/features/document_library/application/usecases/trash_usecases.dart';
import 'package:doc_scanly/features/document_library/presentation/cubit/trash_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates Trash use cases without owning deletion rules.
class TrashCubit extends Cubit<TrashState> {
  /// Creates the Cubit.
  TrashCubit({
    required this.loadTrash,
    required this.restoreTrash,
    required this.purgeTrash,
    required this.emptyTrash,
  }) : super(const TrashState());

  /// Read use case.
  final LoadTrash loadTrash;

  /// Restore use case.
  final RestoreTrashEntry restoreTrash;

  /// Permanent-delete use case.
  final PurgeTrashEntry purgeTrash;

  /// Empty-all use case.
  final EmptyTrash emptyTrash;

  /// Loads or retries Trash.
  Future<void> load() async {
    emit(state.copyWith(status: TrashStatus.loading));
    final result = await loadTrash();
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        emit(state.copyWith(status: TrashStatus.ready, entries: value));
      case Failed(:final failure):
        emit(state.copyWith(status: TrashStatus.failure, failure: failure));
    }
  }

  /// Restores [id].
  Future<void> restore(TrashId id) => _mutate(
    id,
    () => restoreTrash(id),
    successMessage: 'Restored from Trash',
  );

  /// Permanently removes [id].
  Future<void> purge(TrashId id) =>
      _mutate(id, () => purgeTrash(id), successMessage: 'Permanently deleted');

  /// Permanently removes every entry.
  Future<void> empty() async {
    emit(
      state.copyWith(mutating: state.entries.map((entry) => entry.id).toSet()),
    );
    final result = await emptyTrash();
    if (isClosed) return;
    if (result case Failed(:final failure)) {
      emit(state.copyWith(mutating: const {}, failure: failure));
      return;
    }
    emit(
      state.copyWith(
        status: TrashStatus.ready,
        entries: const [],
        mutating: const {},
        message: 'Trash emptied',
      ),
    );
  }

  Future<void> _mutate(
    TrashId id,
    Future<Result<Object?>> Function() operation, {
    required String successMessage,
  }) async {
    emit(state.copyWith(mutating: {...state.mutating, id}));
    final result = await operation();
    if (isClosed) return;
    if (result case Failed(:final failure)) {
      emit(
        state.copyWith(
          mutating: {...state.mutating}..remove(id),
          failure: failure,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: TrashStatus.ready,
        entries: state.entries.where((entry) => entry.id != id).toList(),
        mutating: {...state.mutating}..remove(id),
        message: successMessage,
      ),
    );
  }
}
