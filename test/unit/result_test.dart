import 'package:flutter_test/flutter_test.dart';
import 'package:hawaii_app/core/errors/app_error.dart';
import 'package:hawaii_app/core/errors/result.dart';

void main() {
  group('Result<T>', () {
    // ── Success ──────────────────────────────────────────────────────────────

    group('Success', () {
      test('isSuccess es true, isFailure es false', () {
        const result = Success(42);
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('dataOrNull retorna el valor', () {
        const result = Success('hola');
        expect(result.dataOrNull, 'hola');
      });

      test('errorOrNull retorna null', () {
        const result = Success(99);
        expect(result.errorOrNull, isNull);
      });

      test('when() invoca success con el dato correcto', () {
        const result = Success('hola');
        final output = result.when(
          success: (data) => 'ok: $data',
          failure: (e) => 'error',
        );
        expect(output, 'ok: hola');
      });

      test('when() NO invoca failure', () {
        const result = Success(1);
        var failureCalled = false;
        result.when(
          success: (_) {},
          failure: (_) => failureCalled = true,
        );
        expect(failureCalled, isFalse);
      });

      test('funciona con tipos complejos (List)', () {
        const result = Success([1, 2, 3]);
        expect(result.dataOrNull, [1, 2, 3]);
      });

      test('funciona con null como valor (Success<void>)', () {
        const result = Success<void>(null);
        expect(result.isSuccess, isTrue);
      });
    });

    // ── Failure ──────────────────────────────────────────────────────────────

    group('Failure', () {
      test('isFailure es true, isSuccess es false', () {
        const result = Failure<int>(NetworkError());
        expect(result.isFailure, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('dataOrNull retorna null', () {
        const result = Failure<String>(AuthError());
        expect(result.dataOrNull, isNull);
      });

      test('errorOrNull retorna el error', () {
        const result = Failure<int>(NetworkError());
        expect(result.errorOrNull, isA<NetworkError>());
      });

      test('when() invoca failure con el error correcto', () {
        const result = Failure<String>(ServerError('algo salió mal'));
        final output = result.when(
          success: (data) => 'ok',
          failure: (e) => 'error: ${e.message}',
        );
        expect(output, 'error: algo salió mal');
      });

      test('when() NO invoca success', () {
        const result = Failure<int>(UnknownError());
        var successCalled = false;
        result.when(
          success: (_) => successCalled = true,
          failure: (_) {},
        );
        expect(successCalled, isFalse);
      });
    });
  });

  // ── AppError ─────────────────────────────────────────────────────────────

  group('AppError', () {
    test('NetworkError usa mensaje por defecto', () {
      const error = NetworkError();
      expect(error.message, isNotEmpty);
      expect(error.message, 'Sin conexión a internet');
    });

    test('NetworkError acepta mensaje personalizado', () {
      const error = NetworkError('La conexión tardó demasiado');
      expect(error.message, 'La conexión tardó demasiado');
    });

    test('ServerError guarda statusCode y mensaje', () {
      const error = ServerError('Not Found', statusCode: 404);
      expect(error.statusCode, 404);
      expect(error.message, 'Not Found');
    });

    test('ServerError puede tener statusCode null', () {
      const error = ServerError('Error interno');
      expect(error.statusCode, isNull);
    });

    test('AuthError usa mensaje por defecto', () {
      const error = AuthError();
      expect(error.message, 'Usuario o contraseña incorrectos');
    });

    test('AuthError acepta mensaje personalizado', () {
      const error = AuthError('Sin sesión activa');
      expect(error.message, 'Sin sesión activa');
    });

    test('UnknownError usa mensaje por defecto', () {
      const error = UnknownError();
      expect(error.message, 'Error inesperado');
    });

    test('UnknownError acepta mensaje personalizado', () {
      const error = UnknownError('Fallo inesperado al parsear JSON');
      expect(error.message, 'Fallo inesperado al parsear JSON');
    });

    test('Los distintos tipos de error son instancias de AppError', () {
      const List<AppError> errors = [
        NetworkError(),
        ServerError('x'),
        AuthError(),
        UnknownError(),
      ];
      for (final e in errors) {
        expect(e, isA<AppError>());
      }
    });
  });
}