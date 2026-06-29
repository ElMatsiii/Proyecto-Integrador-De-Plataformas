import 'package:flutter_test/flutter_test.dart';
import 'package:hawaii_app/features/asistencia/domain/qr_asistencia_validator.dart';

void main() {
  const validator = QrAsistenciaValidator();

  Uri uri(String s) => Uri.parse(s);

  // ── URLs válidas ───────────────────────────────────────────────────────────

  group('QrAsistenciaValidator — URLs válidas', () {
    test('acepta el endpoint de desarrollo (hawaii)', () {
      expect(
        validator.esValido(
          uri('https://losvilos.ucn.cl/hawaii/asist_marcar6.php'),
        ),
        isTrue,
      );
    });

    test('acepta el endpoint real de QR de hawaii', () {
      expect(
        validator.esValido(
          uri('https://losvilos.ucn.cl/hawaii/asist.php?c=BDNPUU'),
        ),
        isTrue,
      );
    });

    test('acepta el endpoint de producción (tongoy)', () {
      expect(
        validator.esValido(
          uri('https://losvilos.ucn.cl/tongoy/asist_marcar6.php'),
        ),
        isTrue,
      );
    });

    test('acepta una URL con query params (op, curso, token)', () {
      expect(
        validator.esValido(
          uri(
            'https://losvilos.ucn.cl/hawaii/asist_marcar6.php?op=s&c=123&token=abc',
          ),
        ),
        isTrue,
      );
    });

    test('el host es case-insensitive (Uri lo normaliza a minúsculas)', () {
      expect(
        validator.esValido(
          uri('HTTPS://LOSVILOS.UCN.CL/hawaii/asist_marcar6.php'),
        ),
        isTrue,
      );
    });

    test('acepta con puerto explícito sobre el host permitido', () {
      // El puerto no se valida; el host sigue siendo el dominio correcto.
      expect(
        validator.esValido(
          uri('https://losvilos.ucn.cl:443/tongoy/asist_marcar6.php'),
        ),
        isTrue,
      );
    });
  });

  // ── Rechazo por esquema o dominio ──────────────────────────────────────────

  group('QrAsistenciaValidator — rechaza esquema/dominio', () {
    test('rechaza http (sin TLS)', () {
      expect(
        validator.esValido(
          uri('http://losvilos.ucn.cl/hawaii/asist_marcar6.php'),
        ),
        isFalse,
      );
    });

    test('rechaza un dominio completamente distinto', () {
      expect(
        validator.esValido(
          uri('https://malicioso.com/hawaii/asist_marcar6.php'),
        ),
        isFalse,
      );
    });

    test('rechaza un subdominio del dominio permitido', () {
      expect(
        validator.esValido(
          uri('https://fake.losvilos.ucn.cl/hawaii/asist_marcar6.php'),
        ),
        isFalse,
      );
    });

    test('rechaza el dominio permitido usado como prefijo de otro', () {
      expect(
        validator.esValido(
          uri('https://losvilos.ucn.cl.malicioso.com/hawaii/asist_marcar6.php'),
        ),
        isFalse,
      );
    });

    test('rechaza el spoofing con userinfo (el host real va después de @)', () {
      final u =
          uri('https://losvilos.ucn.cl@malicioso.com/hawaii/asist_marcar6.php');
      // Confirma cómo Uri parsea esto: el host efectivo NO es el permitido.
      expect(u.host, 'malicioso.com');
      expect(validator.esValido(u), isFalse);
    });
  });

  // ── Rechazo por ruta ───────────────────────────────────────────────────────

  group('QrAsistenciaValidator — rechaza rutas no permitidas', () {
    test('rechaza otra ruta del mismo dominio', () {
      expect(
        validator.esValido(uri('https://losvilos.ucn.cl/mi.php')),
        isFalse,
      );
    });

    test('rechaza un endpoint parecido pero distinto', () {
      expect(
        validator.esValido(
          uri('https://losvilos.ucn.cl/hawaii/asist_marcar5.php'),
        ),
        isFalse,
      );
    });

    test('rechaza la ruta correcta con slash final', () {
      expect(
        validator.esValido(
          uri('https://losvilos.ucn.cl/hawaii/asist_marcar6.php/'),
        ),
        isFalse,
      );
    });

    test('rechaza la raíz del dominio', () {
      expect(validator.esValido(uri('https://losvilos.ucn.cl/')), isFalse);
    });

    test('la ruta es case-sensitive (HAWAII no es hawaii)', () {
      expect(
        validator.esValido(
          uri('https://losvilos.ucn.cl/HAWAII/asist_marcar6.php'),
        ),
        isFalse,
      );
    });
  });

  // ── esTextoValido (texto crudo del QR) ──────────────────────────────────────

  group('QrAsistenciaValidator.esTextoValido — texto crudo del QR', () {
    test('acepta el texto de una URL válida', () {
      expect(
        validator.esTextoValido(
          'https://losvilos.ucn.cl/tongoy/asist_marcar6.php?op=s',
        ),
        isTrue,
      );
    });

    test('rechaza texto vacío', () {
      expect(validator.esTextoValido(''), isFalse);
    });

    test('rechaza texto que no es una URL', () {
      expect(validator.esTextoValido('esto no es una url'), isFalse);
    });

    test('rechaza un deep link de otra app', () {
      expect(validator.esTextoValido('tongoy://asistencia/marcar'), isFalse);
    });
  });
}
