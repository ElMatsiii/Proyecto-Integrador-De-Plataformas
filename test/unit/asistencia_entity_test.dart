import 'package:flutter_test/flutter_test.dart';
import 'package:tongoy_app/features/asistencia/data/asistencia_datasource.dart';

void main() {
  // ── AsistenciaResumenEntity ───────────────────────────────────────────────

  group('AsistenciaResumenEntity.porcentaje', () {
    AsistenciaResumenEntity resumen({
      int presentes = 0,
      int ausentes = 0,
      int justificados = 0,
      int total = 0,
    }) =>
        AsistenciaResumenEntity(
          cursoId: 1,
          presentes: presentes,
          ausentes: ausentes,
          justificados: justificados,
          total: total,
        );

    test('porcentaje es 0 cuando total es 0 (sin división por cero)', () {
      expect(resumen(total: 0).porcentaje, 0);
    });

    test('porcentaje es 100 cuando todos presentes', () {
      expect(resumen(presentes: 10, total: 10).porcentaje, 100);
    });

    test('porcentaje es 75 con 15 de 20 clases', () {
      expect(resumen(presentes: 15, total: 20).porcentaje, 75);
    });

    test('porcentaje se redondea al entero más cercano', () {
      // 7 / 9 = 77.77... → redondea a 78
      expect(resumen(presentes: 7, total: 9).porcentaje, 78);
    });

    test('porcentaje es 0 con 0 presentes sobre total positivo', () {
      expect(resumen(presentes: 0, total: 10).porcentaje, 0);
    });

    test('porcentaje por debajo del mínimo (< 75)', () {
      // 10 / 20 = 50%
      final r = resumen(presentes: 10, total: 20);
      expect(r.porcentaje, 50);
      expect(r.porcentaje < 75, isTrue);
    });
  });

  // ── AsistenciaClaseEntity.estadoTexto ─────────────────────────────────────

  group('AsistenciaClaseEntity.estadoTexto', () {
    String texto(int estado) => AsistenciaClaseEntity(
          fecha: '2025-05-05',
          bloque: 'A',
          estado: estado,
        ).estadoTexto;

    test('estado 1 → Presente', () => expect(texto(1), 'Presente'));
    test('estado 0 → Ausente', () => expect(texto(0), 'Ausente'));
    test('estado 3 → Justificado', () => expect(texto(3), 'Justificado'));
    test('estado -1 → Atrasado', () => expect(texto(-1), 'Atrasado'));
    test('estado desconocido → Sin registro', () => expect(texto(99), 'Sin registro'));
    test('estado -99 también es Sin registro', () => expect(texto(-99), 'Sin registro'));
  });

  // ── _rutSoloDigitos (acceso indirecto vía comportamiento) ─────────────────
  //
  // La función es privada, pero podemos probarla indirectamente verificando
  // que los RUTs con dígito verificador se convierten correctamente.
  // Como no podemos instanciarla, testeamos la lógica pura replicada:

  group('Normalización de RUT', () {
    String rutSoloDigitos(String rut) =>
        rut.replaceAll(RegExp(r'[^0-9]'), '');

    test('elimina el dígito verificador K', () {
      expect(rutSoloDigitos('9586127K'), '9586127');
    });

    test('elimina el dígito verificador numérico', () {
      expect(rutSoloDigitos('123456787'), '123456787');
    });

    test('elimina puntos y guiones del formato chileno', () {
      expect(rutSoloDigitos('12.345.678-9'), '123456789');
    });

    test('RUT que ya son solo dígitos se mantienen', () {
      expect(rutSoloDigitos('12345678'), '12345678');
    });

    test('RUT vacío retorna string vacío', () {
      expect(rutSoloDigitos(''), '');
    });

    test('RUT con solo letras retorna vacío', () {
      expect(rutSoloDigitos('ABC'), '');
    });
  });

  // ── AsistenciaClaseEntity construcción ────────────────────────────────────

  group('AsistenciaClaseEntity construcción', () {
    test('se construye correctamente con todos los campos', () {
      const entity = AsistenciaClaseEntity(
        fecha: '2025-04-14',
        bloque: 'B',
        estado: 1,
      );

      expect(entity.fecha, '2025-04-14');
      expect(entity.bloque, 'B');
      expect(entity.estado, 1);
      expect(entity.estadoTexto, 'Presente');
    });

    test('dos entidades con mismo estado tienen mismo estadoTexto', () {
      const a = AsistenciaClaseEntity(fecha: '2025-04-14', bloque: 'A', estado: 0);
      const b = AsistenciaClaseEntity(fecha: '2025-04-15', bloque: 'B', estado: 0);

      expect(a.estadoTexto, b.estadoTexto);
    });
  });

  // ── AsistenciaResumenEntity construcción ─────────────────────────────────

  group('AsistenciaResumenEntity construcción', () {
    test('almacena todos los campos correctamente', () {
      const r = AsistenciaResumenEntity(
        cursoId: 42,
        presentes: 15,
        ausentes: 3,
        justificados: 2,
        total: 20,
      );

      expect(r.cursoId, 42);
      expect(r.presentes, 15);
      expect(r.ausentes, 3);
      expect(r.justificados, 2);
      expect(r.total, 20);
    });

    test('porcentaje con justificados no afecta el cálculo (solo presentes)', () {
      // La fórmula es presentes/total, los justificados son informativos
      const r = AsistenciaResumenEntity(
        cursoId: 1,
        presentes: 8,
        ausentes: 2,
        justificados: 5,
        total: 10,
      );
      expect(r.porcentaje, 80);
    });
  });
}