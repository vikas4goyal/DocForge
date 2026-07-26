/// The return type for every fallible operation in DocForge.
///
/// Use cases and repositories return `Result<T>` rather than throwing, so a
/// caller cannot forget that an operation can fail — the value is unreachable
/// without handling the failure case first.
library;

import 'package:doc_forge/core/failures/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

/// Either a successful value of type [T] or a [Failure].
@freezed
sealed class Result<T> with _$Result<T> {
  /// The operation succeeded and produced [value].
  const factory Result.success(T value) = Success<T>;

  /// The operation failed with [failure].
  const factory Result.failure(Failure failure) = Failed<T>;

  const Result._();

  /// Whether this result holds a value.
  bool get isSuccess => this is Success<T>;

  /// Whether this result holds a failure.
  bool get isFailure => this is Failed<T>;

  /// The value when successful, otherwise `null`.
  ///
  /// Prefer pattern matching where the failure must be handled; this is for the
  /// cases where absence is genuinely equivalent to failure.
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Failed<T>() => null,
  };

  /// The failure when unsuccessful, otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Failed<T>(:final failure) => failure,
  };

  /// Transforms a successful value with [transform], preserving any failure.
  ///
  /// Lets a use case adapt a repository's result without unwrapping and
  /// rewrapping it, which is where failures tend to get accidentally dropped.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success<T>(:final value) => Result<R>.success(transform(value)),
    Failed<T>(:final failure) => Result<R>.failure(failure),
  };

  /// Chains another fallible operation onto a successful result.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Success<T>(:final value) => transform(value),
    Failed<T>(:final failure) => Result<R>.failure(failure),
  };

  /// Chains an asynchronous fallible operation onto a successful result.
  ///
  /// The common shape in a use case: read a record, then write it back. Without
  /// this each call site would unwrap and rewrap the result by hand, which is
  /// exactly where a failure tends to get silently dropped.
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T value) transform,
  ) async => switch (this) {
    Success<T>(:final value) => await transform(value),
    Failed<T>(:final failure) => Result<R>.failure(failure),
  };

  /// Returns the value when successful, or [fallback] when not.
  T getOrElse(T fallback) => valueOrNull ?? fallback;
}
