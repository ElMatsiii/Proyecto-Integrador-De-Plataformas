import 'package:flutter_test/flutter_test.dart';
import 'package:tongoy_app/features/horario/data/models/horario_dto.dart';

void main() {
  // ── BloqueDto ─────────────────────────────────────────────────────────────

  group('BloqueDto.fromJson', () {
    test('parsea un bloque con horario', () {
      final json = {'id': 1, 'nombre': 'A', 'horario': '08:10 - 09:40'};
      final dto = BloqueDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.nombre, 'A');
      expect(dto.horario, '08:10 - 09:40');
    });

    test('parsea un bloque sin horario (null)', () {
      final json = {'id': 2, 'nombre': 'B', 'horario': null};
      final dto = BloqueDto.fromJson(json);

      expect(dto.horario, isNull);
    });

    test('toEntity() convierte correctamente', () {
      final dto = BloqueDto.fromJson({'id': 3, 'nombre': 'C', 'horario': '10:00 - 11:30'});
      final entity = dto.toEntity();

      expect(entity.id, 3);
      expect(entity.nombre, 'C');
      expect(entity.horario, '10:00 - 11:30');
    });
  });

  // ── DiaDto ────────────────────────────────────────────────────────────────

  group('DiaDto.fromJson', () {
    test('parsea un día correctamente', () {
      final json = {'id': 1, 'nombre': 'Lunes', 'dotw': 1};
      final dto = DiaDto.fromJson(json);

      expect(dto.id, 1);
      expect(dto.nombre, 'Lunes');
      expect(dto.dotw, 1);
    });

    test('toEntity() convierte correctamente', () {
      final dto = DiaDto.fromJson({'id': 6, 'nombre': 'Sabado', 'dotw': 6});
      final entity = dto.toEntity();

      expect(entity.dotw, 6);
      expect(entity.nombre, 'Sabado');
    });
  });

  // ── SalaDto ───────────────────────────────────────────────────────────────

  group('SalaDto.fromJson', () {
    test('parsea sala con capacidad', () {
      final json = {'id': 10, 'nombre': 'X-101', 'sector': 'X', 'capacidad': 40};
      final dto = SalaDto.fromJson(json);

      expect(dto.capacidad, 40);
      expect(dto.sector, 'X');
    });

    test('parsea sala sin capacidad (null)', () {
      final json = {'id': 11, 'nombre': 'Y-202', 'sector': 'Y', 'capacidad': null};
      final dto = SalaDto.fromJson(json);

      expect(dto.capacidad, isNull);
    });

    test('sector vacío cuando la clave no viene', () {
      final json = {'id': 12, 'nombre': 'Z-303'};
      final dto = SalaDto.fromJson(json);

      expect(dto.sector, '');
    });

    test('toEntity() convierte correctamente', () {
      final json = {'id': 10, 'nombre': 'X-101', 'sector': 'X', 'capacidad': 30};
      final entity = SalaDto.fromJson(json).toEntity();

      expect(entity.capacidad, 30);
      expect(entity.nombre, 'X-101');
    });
  });

  // ── SemestreDto ───────────────────────────────────────────────────────────

  group('SemestreDto.fromJson', () {
    test('parsea semestre con es_actual=1', () {
      final json = {
        'id': 6,
        'nombre': '2025-1',
        'primer_lunes': '2025-03-10',
        'ultimo_domingo': '2025-07-06',
        'es_actual': 1,
      };
      final dto = SemestreDto.fromJson(json);

      expect(dto.esActual, isTrue);
      expect(dto.nombre, '2025-1');
    });

    test('parsea semestre con es_actual=0', () {
      final json = {
        'id': 5,
        'nombre': '2024-2',
        'primer_lunes': '2024-08-05',
        'ultimo_domingo': '2024-12-01',
        'es_actual': 0,
      };
      final dto = SemestreDto.fromJson(json);

      expect(dto.esActual, isFalse);
    });

    test('es_actual ausente se trata como false', () {
      final json = {
        'id': 4,
        'nombre': '2024-1',
        'primer_lunes': '2024-03-11',
        'ultimo_domingo': '2024-07-07',
      };
      final dto = SemestreDto.fromJson(json);

      expect(dto.esActual, isFalse);
    });

    test('toEntity() parsea las fechas como DateTime', () {
      final json = {
        'id': 6,
        'nombre': '2025-1',
        'primer_lunes': '2025-03-10',
        'ultimo_domingo': '2025-07-06',
        'es_actual': 1,
      };
      final entity = SemestreDto.fromJson(json).toEntity();

      expect(entity.primerLunes, DateTime(2025, 3, 10));
      expect(entity.ultimoDomingo, DateTime(2025, 7, 6));
      expect(entity.esActual, isTrue);
    });
  });

  // ── HorarioItemDto ────────────────────────────────────────────────────────

  group('HorarioItemDto.fromJson', () {
    Map<String, dynamic> itemJson({
      int id = 1,
      String dia = 'Lunes',
      String bloque = 'A',
      String sala = 'X-101',
      String curso = 'Algoritmos (ALG-100)',
      int idcurso = 100,
      String nrc = '12345',
      String profesor = 'García Mario',
      String area = 'Ingeniería',
      String comentario = '',
      List<dynamic> carreras = const [],
    }) =>
        {
          'id': id,
          'dia': dia,
          'bloque': bloque,
          'sala': sala,
          'curso': curso,
          'idcurso': idcurso,
          'nrc': nrc,
          'profesor': profesor,
          'area': area,
          'comentario': comentario,
          'carreras': carreras,
        };

    test('parsea un item completo correctamente', () {
      final dto = HorarioItemDto.fromJson(itemJson());

      expect(dto.id, 1);
      expect(dto.dia, 'Lunes');
      expect(dto.bloque, 'A');
      expect(dto.sala, 'X-101');
      expect(dto.idCurso, 100);
      expect(dto.nrc, '12345');
      expect(dto.profesor, 'García Mario');
    });

    test('campos null usan valores vacíos por defecto', () {
      final dto = HorarioItemDto.fromJson({
        'id': 2,
        'dia': null,
        'bloque': null,
        'sala': null,
        'curso': null,
        'idcurso': null,
        'nrc': null,
        'profesor': null,
        'area': null,
        'comentario': null,
        'carreras': null,
      });

      expect(dto.dia, '');
      expect(dto.bloque, '');
      expect(dto.sala, '');
      expect(dto.curso, '');
      expect(dto.idCurso, 0);
      expect(dto.nrc, '');
      expect(dto.profesor, '');
      expect(dto.area, '');
      expect(dto.comentario, '');
      expect(dto.carreras, isEmpty);
    });

    test('parsea carreras anidadas correctamente', () {
      final dto = HorarioItemDto.fromJson(itemJson(
        carreras: [
          {'id': 1, 'nombre': 'Informática', 'semestre': 3},
          {'id': 2, 'nombre': 'Civil', 'semestre': 1},
        ],
      ),);

      expect(dto.carreras, hasLength(2));
      expect(dto.carreras.first.nombre, 'Informática');
      expect(dto.carreras.first.semestre, 3);
    });

    test('toEntity() convierte correctamente incluyendo carreras', () {
      final dto = HorarioItemDto.fromJson(itemJson(
        carreras: [{'id': 5, 'nombre': 'Ingeniería Civil', 'semestre': 2}],
      ),);
      final entity = dto.toEntity();

      expect(entity.id, 1);
      expect(entity.idCurso, 100);
      expect(entity.carreras, hasLength(1));
      expect(entity.carreras.first.id, 5);
      expect(entity.carreras.first.nombre, 'Ingeniería Civil');
    });
  });

  // ── MasterDto ─────────────────────────────────────────────────────────────

  group('MasterDto.fromJson', () {
    test('parsea un master completo con todas las listas', () {
      final json = {
        'areas': [{'id': 1, 'nombre': 'Ingeniería'}],
        'dias': [{'id': 1, 'nombre': 'Lunes', 'dotw': 1}],
        'bloques': [{'id': 1, 'nombre': 'A', 'horario': '08:10 - 09:40'}],
        'salas': [{'id': 1, 'nombre': 'X-101', 'sector': 'X'}],
        'cursos': [{'id': 10, 'nombre': 'Algoritmos'}],
        'profesores': [{'id': 5, 'nombre': 'García'}],
        'semestres': [
          {
            'id': 6, 'nombre': '2025-1',
            'primer_lunes': '2025-03-10',
            'ultimo_domingo': '2025-07-06',
            'es_actual': 1,
          },
        ],
      };

      final dto = MasterDto.fromJson(json);

      expect(dto.areas, hasLength(1));
      expect(dto.dias, hasLength(1));
      expect(dto.bloques, hasLength(1));
      expect(dto.salas, hasLength(1));
      expect(dto.cursos, hasLength(1));
      expect(dto.profesores, hasLength(1));
      expect(dto.semestres, hasLength(1));
    });

    test('listas ausentes producen listas vacías (no excepción)', () {
      final dto = MasterDto.fromJson({});

      expect(dto.areas, isEmpty);
      expect(dto.dias, isEmpty);
      expect(dto.bloques, isEmpty);
      expect(dto.salas, isEmpty);
      expect(dto.cursos, isEmpty);
      expect(dto.profesores, isEmpty);
      expect(dto.semestres, isEmpty);
    });

    test('toEntity() convierte toda la estructura', () {
      final json = {
        'areas': [{'id': 1, 'nombre': 'Ingeniería'}],
        'dias': [{'id': 1, 'nombre': 'Lunes', 'dotw': 1}],
        'bloques': [{'id': 1, 'nombre': 'A', 'horario': '08:10 - 09:40'}],
        'salas': [{'id': 1, 'nombre': 'X-101', 'sector': 'X'}],
        'cursos': [{'id': 10, 'nombre': 'Algoritmos'}],
        'profesores': [{'id': 5, 'nombre': 'García'}],
        'semestres': [
          {
            'id': 6, 'nombre': '2025-1',
            'primer_lunes': '2025-03-10',
            'ultimo_domingo': '2025-07-06',
            'es_actual': 1,
          },
        ],
      };

      final entity = MasterDto.fromJson(json).toEntity();

      expect(entity.areas.first.nombre, 'Ingeniería');
      expect(entity.dias.first.dotw, 1);
      expect(entity.semestres.first.esActual, isTrue);
    });
  });
}