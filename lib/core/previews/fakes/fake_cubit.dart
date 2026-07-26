/// Fake Cubits for previews and widget tests.
///
/// A widget bound to a Cubit cannot be previewed by construction alone — it
/// needs a Cubit in the tree. Supplying a *real* one would drag in a use case,
/// a repository and ultimately Isar or a camera, which the preview rules
/// forbid outright.
///
/// `FakeCubit` gives a Cubit that emits exactly the states you hand it and
/// touches nothing else, so a preview can show any state — loading, empty,
/// error, long content — deterministically.
///
/// Usage in a preview:
///
/// ```dart
/// @Preview(name: 'HomeScreen — empty', theme: appPreviewTheme)
/// Widget homeEmpty() => BlocProvider<HomeCubit>.value(
///   value: FakeCubit<HomeState>(HomeState.empty()) as HomeCubit,
///   child: const HomeScreen(),
/// );
/// ```
///
/// In practice each feature declares its own `FakeHomeCubit extends HomeCubit`
/// using `SeededCubit`, because `BlocProvider` resolves by concrete type.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

/// A Cubit that holds a fixed state and never performs work.
///
/// Deterministic by construction: it has no dependencies, reads no clock and
/// makes no calls, so a preview or golden built on it renders identically every
/// time.
class FakeCubit<S> extends Cubit<S> {
  /// Creates a fake Cubit seeded with [initialState].
  FakeCubit(super.initialState);

  /// Replays [states] in order, so a preview can show a transition.
  ///
  /// Emits synchronously, which is what makes a widget test able to assert on
  /// the final state without pumping timers.
  void replay(Iterable<S> states) => states.forEach(emit);

  /// Moves the fake to [state].
  ///
  /// Exposed publicly — unlike `emit`, which is protected — so a test can drive
  /// a fake without subclassing it.
  void setState(S state) => emit(state);
}

/// Mixin that turns a real Cubit subclass into a preview-safe fake.
///
/// `BlocProvider` and `BlocBuilder` resolve by concrete Cubit type, so a
/// preview needs something that *is* the feature's Cubit type but does none of
/// its work. A feature declares:
///
/// ```dart
/// class FakeHomeCubit extends HomeCubit with SeededCubit<HomeState> {
///   FakeHomeCubit(HomeState state) : super.forPreview() { seed(state); }
/// }
/// ```
///
/// The mixin only exposes seeding; it deliberately provides no way to trigger
/// the real Cubit's behaviour.
mixin SeededCubit<S> on Cubit<S> {
  /// Emits [state] without invoking any use case.
  void seed(S state) => emit(state);
}
