import 'package:flutter_test/flutter_test.dart';
import 'package:hawaii_app/features/horario/domain/entities/horario_entity.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

HorarioItemEntity _item({
  int id = 1,
  String dia = 'Lunes',
  String bloque = 'A',
  String sala = 'X-101',
  String curso = 'Algoritmos (ALG-100)',
  int idCurso = 10,
  String nrc = '00001',
  String profesor = 'García Mario',
  String area = 'Ingeniería',
  String comentario = '',
  List<CarreraEnHorario> carreras = const [],
}) =>
    HorarioItemEntity(
      id: id,
      dia: dia,
      bloque: bloque,
      sala: sala,
      curso: curso,
      idCurso: idCurso,
      nrc: nrc,
      profesor: profesor,
      area: area,
      comentario: comentario,
      carreras: carreras,
    );

List<HorarioItemEntity> _aplicarFiltrosLocales(
  List<HorarioItemEntity> items,
  HorarioFiltro filtro,
  String search,
) {
  var resultado = items;

  if (filtro.dia.isNotEmpty) {
    resultado = resultado.where((i) => i.dia == filtro.dia).toList();
  }

  if (filtro.carreraId != -1) {
    resultado = resultado
        .where((i) => i.carreras.any((c) => c.id == filtro.carreraId))
        .toList();
  }

  if (search.isNotEmpty) {
    final query = search.toLowerCase();
    resultado = resultado.where((item) {
      return item.curso.toLowerCase().contains(query) ||
          item.profesor.toLowerCase().contains(query) ||
          item.sala.toLowerCase().contains(query) ||
          item.area.toLowerCase().contains(query);
    }).toList();
  }

  return resultado;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── HorarioFiltro ────────────────────────────────────────────────────────

  group('HorarioFiltro', () {
    test('valores por defecto son -1 / vacío', () {
      const filtro = HorarioFiltro();
      expect(filtro.sala, -1);
      expect(filtro.curso, -1);
      expect(filtro.profesor, -1);
      expect(filtro.semestre, -1);
      expect(filtro.semestreC, -1);
      expect(filtro.carrera, -1);
      expect(filtro.area, -1);
      expect(filtro.dia, '');
      expect(filtro.carreraId, -1);
    });

    test('tieneFiltroPorsAplicados es false con solo semestre activo', () {
      const filtro = HorarioFiltro(semestre: 6);
      expect(filtro.tieneFiltroPorsAplicados, isFalse);
    });

    test('tieneFiltroPorsAplicados es true si hay filtro de sala', () {
      const filtro = HorarioFiltro(sala: 5);
      expect(filtro.tieneFiltroPorsAplicados, isTrue);
    });

    test('tieneFiltroPorsAplicados es true si hay filtro de día', () {
      const filtro = HorarioFiltro(dia: 'Lunes');
      expect(filtro.tieneFiltroPorsAplicados, isTrue);
    });

    test('tieneFiltroPorsAplicados es true si hay filtro de carreraId', () {
      const filtro = HorarioFiltro(carreraId: 3);
      expect(filtro.tieneFiltroPorsAplicados, isTrue);
    });

    test('tieneFiltroPorsAplicados es true con múltiples filtros activos', () {
      const filtro = HorarioFiltro(area: 2, semestreC: 3);
      expect(filtro.tieneFiltroPorsAplicados, isTrue);
    });

    group('copyWith', () {
      test('copia con semestre distinto mantiene otros valores', () {
        const original = HorarioFiltro(semestre: 6, area: 12, sala: 3);
        final copia = original.copyWith(semestre: 7);

        expect(copia.semestre, 7);
        expect(copia.area, 12);
        expect(copia.sala, 3);
      });

      test('copia con dia mantiene campos no tocados', () {
        const original = HorarioFiltro(semestre: 6, carrera: 1);
        final copia = original.copyWith(dia: 'Martes');

        expect(copia.dia, 'Martes');
        expect(copia.semestre, 6);
        expect(copia.carrera, 1);
        expect(copia.sala, -1);
      });

      test('copia reseteando un campo a -1 funciona', () {
        const original = HorarioFiltro(area: 5);
        final copia = original.copyWith(area: -1);

        expect(copia.area, -1);
        expect(copia.tieneFiltroPorsAplicados, isFalse);
      });

      test('copia múltiples campos al mismo tiempo', () {
        const original = HorarioFiltro();
        final copia = original.copyWith(
          semestre: 6,
          area: 2,
          profesor: 10,
          dia: 'Viernes',
          semestreC: 4,
        );

        expect(copia.semestre, 6);
        expect(copia.area, 2);
        expect(copia.profesor, 10);
        expect(copia.dia, 'Viernes');
        expect(copia.semestreC, 4);
        expect(copia.sala, -1); // no modificado
      });
    });
  });

  // ── Filtros locales ───────────────────────────────────────────────────────

  group('Filtros locales _aplicarFiltrosLocales', () {
    final items = [
      _item(id: 1, dia: 'Lunes', profesor: 'García Mario', sala: 'X-101',
          curso: 'Algoritmos (ALG-100)', area: 'Ingeniería',
          carreras: [const CarreraEnHorario(id: 1, nombre: 'Informática', semestre: 3)],),
      _item(id: 2, dia: 'Martes', profesor: 'López Ana', sala: 'Y-202',
          curso: 'Cálculo (MAT-100)', area: 'Matemáticas',
          carreras: [const CarreraEnHorario(id: 2, nombre: 'Civil', semestre: 1)],),
      _item(id: 3, dia: 'Lunes', profesor: 'Martínez Paz', sala: 'X-101',
          curso: 'Física I (FIS-100)', area: 'Ciencias',
          carreras: [const CarreraEnHorario(id: 1, nombre: 'Informática', semestre: 2)],),
      _item(id: 4, dia: 'Jueves', profesor: 'García Mario', sala: 'Z-303',
          curso: 'Redes (RED-200)', area: 'Ingeniería',),
    ];

    test('sin filtros retorna todos los items', () {
      final result = _aplicarFiltrosLocales(items, const HorarioFiltro(), '');
      expect(result, hasLength(4));
    });

    group('filtro por día', () {
      test('filtra correctamente por Lunes', () {
        final result = _aplicarFiltrosLocales(
            items, const HorarioFiltro(dia: 'Lunes'), '',);
        expect(result, hasLength(2));
        expect(result.every((i) => i.dia == 'Lunes'), isTrue);
      });

      test('filtra correctamente por Martes', () {
        final result = _aplicarFiltrosLocales(
            items, const HorarioFiltro(dia: 'Martes'), '',);
        expect(result, hasLength(1));
        expect(result.first.id, 2);
      });

      test('retorna vacío si no hay clases ese día', () {
        final result = _aplicarFiltrosLocales(
            items, const HorarioFiltro(dia: 'Sabado'), '',);
        expect(result, isEmpty);
      });
    });

    group('filtro por carreraId', () {
      test('filtra por carrera id=1', () {
        final result = _aplicarFiltrosLocales(
            items, const HorarioFiltro(carreraId: 1), '',);
        expect(result, hasLength(2));
        expect(result.every((i) => i.carreras.any((c) => c.id == 1)), isTrue);
      });

      test('filtra por carrera id=2', () {
        final result = _aplicarFiltrosLocales(
            items, const HorarioFiltro(carreraId: 2), '',);
        expect(result, hasLength(1));
        expect(result.first.id, 2);
      });

      test('retorna vacío si ningún item tiene esa carrera', () {
        final result = _aplicarFiltrosLocales(
            items, const HorarioFiltro(carreraId: 99), '',);
        expect(result, isEmpty);
      });

      test('items sin carreras son excluidos', () {
        final result = _aplicarFiltrosLocales(
            items, const HorarioFiltro(carreraId: 1), '',);
        // Item 4 no tiene carreras → no debe aparecer
        expect(result.any((i) => i.id == 4), isFalse);
      });
    });

    group('búsqueda por texto', () {
      test('busca por nombre de curso', () {
        final result = _aplicarFiltrosLocales(items, const HorarioFiltro(), 'algoritmos');
        expect(result, hasLength(1));
        expect(result.first.id, 1);
      });

      test('búsqueda es case-insensitive', () {
        final result = _aplicarFiltrosLocales(items, const HorarioFiltro(), 'CÁLCULO');
        expect(result, hasLength(1));
        expect(result.first.id, 2);
      });

      test('busca por nombre de profesor', () {
        final result = _aplicarFiltrosLocales(items, const HorarioFiltro(), 'garcía');
        expect(result, hasLength(2));
        expect(result.map((i) => i.id).toSet(), {1, 4});
      });

      test('busca por sala', () {
        final result = _aplicarFiltrosLocales(items, const HorarioFiltro(), 'x-101');
        expect(result, hasLength(2));
      });

      test('busca por área', () {
        final result = _aplicarFiltrosLocales(items, const HorarioFiltro(), 'matemáticas');
        expect(result, hasLength(1));
        expect(result.first.id, 2);
      });

      test('retorna vacío si no hay coincidencias', () {
        final result = _aplicarFiltrosLocales(items, const HorarioFiltro(), 'xyz_inexistente');
        expect(result, isEmpty);
      });

      test('búsqueda vacía no filtra nada', () {
        final result = _aplicarFiltrosLocales(items, const HorarioFiltro(), '');
        expect(result, hasLength(4));
      });
    });

    group('combinación de filtros', () {
      test('día + búsqueda se aplican juntos', () {
        // Lunes: items 1 y 3. De esos, buscar 'garcía' → solo item 1
        final result = _aplicarFiltrosLocales(
            items, const HorarioFiltro(dia: 'Lunes'), 'garcía',);
        expect(result, hasLength(1));
        expect(result.first.id, 1);
      });

      test('carreraId + día se aplican juntos', () {
        // Carrera 1: items 1 y 3. Día Lunes: items 1 y 3. Intersección: 1 y 3
        final result = _aplicarFiltrosLocales(
            items, const HorarioFiltro(dia: 'Lunes', carreraId: 1), '',);
        expect(result, hasLength(2));
      });

      test('filtros múltiples con resultado vacío', () {
        final result = _aplicarFiltrosLocales(
            items, const HorarioFiltro(dia: 'Jueves', carreraId: 1), '',);
        expect(result, isEmpty);
      });
    });
  });

  // ── Entidades del dominio ─────────────────────────────────────────────────

  group('HorarioItemEntity', () {
    test('se construye correctamente con todos los campos', () {
      const item = HorarioItemEntity(
        id: 42,
        dia: 'Miercoles',
        bloque: 'C',
        sala: 'A-100',
        curso: 'Base de Datos',
        idCurso: 200,
        nrc: '99999',
        profesor: 'Pérez Juan',
        area: 'Informática',
        comentario: 'Laboratorio',
        carreras: [],
      );

      expect(item.id, 42);
      expect(item.dia, 'Miercoles');
      expect(item.bloque, 'C');
      expect(item.sala, 'A-100');
      expect(item.nrc, '99999');
      expect(item.comentario, 'Laboratorio');
    });
  });

  group('BloqueEntity', () {
    test('horario puede ser null', () {
      const bloque = BloqueEntity(id: 1, nombre: 'A');
      expect(bloque.horario, isNull);
    });

    test('horario puede tener valor', () {
      const bloque = BloqueEntity(id: 2, nombre: 'B', horario: '08:10 - 09:40');
      expect(bloque.horario, '08:10 - 09:40');
    });
  });

  group('SemestreEntity', () {
    test('esActual por defecto es false', () {
      final semestre = SemestreEntity(
        id: 1,
        nombre: '2024-1',
        primerLunes: DateTime(2024, 3, 11),
        ultimoDomingo: DateTime(2024, 7, 7),
      );
      expect(semestre.esActual, isFalse);
    });

    test('esActual puede ser true', () {
      final semestre = SemestreEntity(
        id: 2,
        nombre: '2025-1',
        primerLunes: DateTime(2025, 3, 10),
        ultimoDomingo: DateTime(2025, 7, 6),
        esActual: true,
      );
      expect(semestre.esActual, isTrue);
    });
  });
}