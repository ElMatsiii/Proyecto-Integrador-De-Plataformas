import 'package:flutter_test/flutter_test.dart';
import 'package:tongoy_app/core/errors/app_error.dart';
import 'package:tongoy_app/core/errors/result.dart';

void main() {
  group('Result<T>', () {
    test('Success.isSuccess es true', () {
      const result = Success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 42);
    });

    test('Failure.isFailure es true', () {
      const result = Failure<int>(NetworkError());
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.dataOrNull, isNull);
      expect(result.errorOrNull, isA<NetworkError>());
    });

    test('when() llama el callback correcto en éxito', () {
      const result = Success('hola');
      final output = result.when(
        success: (data) => 'ok: $data',
        failure: (e) => 'error: ${e.message}',
      );
      expect(output, 'ok: hola');
    });

    test('when() llama el callback correcto en fallo', () {
      const result = Failure<String>(ServerError('algo salió mal'));
      final output = result.when(
        success: (data) => 'ok',
        failure: (e) => 'error: ${e.message}',
      );
      expect(output, 'error: algo salió mal');
    });
  });

  group('AppError', () {
    test('NetworkError tiene mensaje por defecto', () {
      const error = NetworkError();
      expect(error.message, isNotEmpty);
    });

    test('ServerError guarda el statusCode', () {
      const error = ServerError('Not Found', statusCode: 404);
      expect(error.statusCode, 404);
      expect(error.message, 'Not Found');
    });
  });
}
