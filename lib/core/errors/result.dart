import 'app_error.dart';

/// Tipo resultado para operaciones que pueden tener éxito o fallar.
/// Evita usar excepciones para flujo de control normal.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

extension ResultExtensions<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        final Success<T> s => s.data,
        _ => null,
      };

  AppError? get errorOrNull => switch (this) {
        final Failure<T> f => f.error,
        _ => null,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) =>
      switch (this) {
        final Success<T> s => success(s.data),
        final Failure<T> f => failure(f.error),
      };
}
