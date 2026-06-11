import 'package:flutter_test/flutter_test.dart';
import 'package:tongoy_app/features/mis_cursos/domain/entities/curso_usuario_entity.dart';

CursoUsuarioEntity _curso({
  int id = 1,
  String nombre = 'Algoritmos',
  String codigo = 'ALG-100',
  String seccion = '1',
  String rol = 'E',
  String extra = 'A',
  int pid = 0,
  Set<int>? extraIds,
}) =>
    CursoUsuarioEntity(
      id: id,
      nombre: nombre,
      codigo: codigo,
      seccion: seccion,
      rol: rol,
      extra: extra,
      pid: pid,
      extraIds: extraIds,
    );

void main() {
  group('CursoUsuarioEntity — rol', () {
    test('esProfesor es false para rol E (estudiante)', () {
      final c = _curso(rol: 'E');
      expect(c.esProfesor, isFalse);
    });

    test('esProfesor es true para rol P (profesor)', () {
      final c = _curso(rol: 'P');
      expect(c.esProfesor, isTrue);
    });

    test('rol desconocido no es profesor', () {
      final c = _curso(rol: 'X');
      expect(c.esProfesor, isFalse);
    });
  });

  group('CursoUsuarioEntity — extra', () {
    test('tieneAsistencia es true cuando extra=A', () {
      final c = _curso(extra: 'A');
      expect(c.tieneAsistencia, isTrue);
      expect(c.tieneNotas, isFalse);
    });

    test('tieneNotas es true cuando extra=N', () {
      final c = _curso(extra: 'N');
      expect(c.tieneNotas, isTrue);
      expect(c.tieneAsistencia, isFalse);
    });

    test('ninguno de los dos cuando extra es vacío', () {
      final c = _curso(extra: '');
      expect(c.tieneAsistencia, isFalse);
      expect(c.tieneNotas, isFalse);
    });
  });

  group('CursoUsuarioEntity — todosLosIds', () {
    test('todosLosIds contiene el id principal cuando no hay extraIds', () {
      final c = _curso(id: 10);
      expect(c.todosLosIds, contains(10));
      expect(c.todosLosIds, hasLength(1));
    });

    test('todosLosIds incluye id principal y extraIds sin duplicados', () {
      final c = _curso(id: 10, extraIds: {20, 30});
      expect(c.todosLosIds, containsAll([10, 20, 30]));
      expect(c.todosLosIds, hasLength(3));
    });

    test('todosLosIds deduplica si id ya está en extraIds', () {
      final c = _curso(id: 10, extraIds: {10, 20});
      expect(c.todosLosIds, containsAll([10, 20]));
      expect(c.todosLosIds, hasLength(2));
    });

    test('extraIds null equivale a conjunto vacío', () {
      final c = _curso(id: 5, extraIds: null);
      expect(c.todosLosIds, {5});
    });
  });

  group('CursoUsuarioEntity — escenarios reales de la API', () {
    test('curso con doble entrada A+N combina correctamente los IDs', () {
      // La API devuelve el mismo curso dos veces: id=100 (extra=A), id=101 (extra=N)
      // El repositorio elige extra=A como principal y guarda ambos en extraIds
      const cursoEstudiante = CursoUsuarioEntity(
        id: 100,
        nombre: 'Algoritmos (ALG-100)',
        codigo: 'ALG-100',
        seccion: '1',
        rol: 'E',
        extra: 'A',
        extraIds: {100, 101},
      );

      expect(cursoEstudiante.tieneAsistencia, isTrue);
      expect(cursoEstudiante.todosLosIds, containsAll([100, 101]));
    });

    test('curso de ayudante tiene rol P y puede tener ambos tipos de extra', () {
      const cursoProfesor = CursoUsuarioEntity(
        id: 200,
        nombre: 'Redes (RED-200)',
        codigo: 'RED-200',
        seccion: '2',
        rol: 'P',
        extra: 'A',
        extraIds: {200, 201},
      );

      expect(cursoProfesor.esProfesor, isTrue);
      expect(cursoProfesor.todosLosIds, {200, 201});
    });

    test('curso con pid=0 es el valor por defecto', () {
      final c = _curso(pid: 0);
      expect(c.pid, 0);
    });

    test('pid del estudiante se guarda correctamente', () {
      final c = _curso(pid: 9586127);
      expect(c.pid, 9586127);
    });
  });

  group('CursoUsuarioEntity — construcción completa', () {
    test('todos los campos se asignan correctamente', () {
      const c = CursoUsuarioEntity(
        id: 42,
        nombre: 'Base de Datos (BDD-300)',
        codigo: 'BDD-300',
        seccion: '3',
        rol: 'E',
        extra: 'N',
        pid: 12345678,
        extraIds: {42, 43},
      );

      expect(c.id, 42);
      expect(c.nombre, 'Base de Datos (BDD-300)');
      expect(c.codigo, 'BDD-300');
      expect(c.seccion, '3');
      expect(c.rol, 'E');
      expect(c.extra, 'N');
      expect(c.pid, 12345678);
      expect(c.extraIds, {42, 43});
    });
  });
}